function Set-SPFxEnvironment {
    <#
    .SYNOPSIS
        Deploys a previously-built environment's json/xml files into an SPFx
        solution, overwriting the corresponding files at their normal
        locations.

    .DESCRIPTION
        Copies every file under <Path>/.<Environment>/ to the same relative
        path under <Path>, overwriting whatever is already there. This is the
        deploy half of the pair New-SPFxEnvironment builds: run
        New-SPFxEnvironment once to produce the environment-specific files
        (fresh GUIDs and suffixed names, or a verbatim copy for prod), then
        run Set-SPFxEnvironment to put them in place before building/packaging
        the solution.

        Example: .dev/src/webparts/helloWorld/HelloWorldWebPart.manifest.json
        is copied to src/webparts/helloWorld/HelloWorldWebPart.manifest.json,
        overwriting the original.

        Every write is behind ShouldProcess - run with -WhatIf first to see
        exactly which files would be overwritten.

    .PARAMETER Path
        Root folder of the SPFx solution (the same one passed to
        New-SPFxEnvironment). Defaults to the current directory.

    .PARAMETER Environment
        Environment name whose <Path>/.<Environment>/ folder should be
        deployed. Matched case-insensitively against the folder
        New-SPFxEnvironment created (environment names are normalized to
        lowercase).

    .EXAMPLE
        Set-SPFxEnvironment -Path ./testplaygrounds/spfx-sample-app -Environment dev

        Copies every file from .../spfx-sample-app/.dev/ into place under
        .../spfx-sample-app/.

    .EXAMPLE
        Set-SPFxEnvironment -Environment prod -WhatIf

        Against the current directory. Reports which files would be
        overwritten without changing anything.

    .OUTPUTS
        System.Management.Automation.PSCustomObject per file deployed, with
        RelativePath, SourcePath, and DestinationPath.

    .NOTES
        Pure filesystem operation - makes no PnP or network calls, and runs on
        both PowerShell 5.1 and 7+.

    .LINK
        https://github.com/marat-365/ALMFx
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Path = (Get-Location).Path,

        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_-]*$')]
        [string] $Environment
    )

    process {
        $resolvedPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
        $normalizedEnvironment = $Environment.ToLowerInvariant()
        $sourceRoot = [System.IO.Path]::Combine($resolvedPath, ".$normalizedEnvironment")

        if (-not (Test-Path -LiteralPath $sourceRoot)) {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.IO.DirectoryNotFoundException]::new("'$sourceRoot' does not exist. Run New-SPFxEnvironment -Path '$resolvedPath' -Environment '$Environment' first."),
                    'ALMFx.EnvironmentNotBuilt',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $sourceRoot
                )
            )
        }

        # -Force: an environment payload can legitimately include a
        # dot-prefixed file (.yo-rc.json echoes the solution GUID), and that
        # must be enumerated for deployment the same as everything else.
        $sourceFiles = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File -Force

        foreach ($file in $sourceFiles) {
            # Normalized to forward slashes: see the identical note in
            # Copy-ALMFxEnvironmentArtefact.ps1 - RelativePath is a logical,
            # cross-platform identifier, not an OS path.
            $relativePath = ($file.FullName.Substring($sourceRoot.Length).TrimStart('\', '/')) -replace '\\', '/'
            $destinationPath = [System.IO.Path]::Combine($resolvedPath, $relativePath)

            if ($PSCmdlet.ShouldProcess($destinationPath, "Overwrite with .$normalizedEnvironment/$relativePath")) {
                $destinationDir = Split-Path -Path $destinationPath -Parent
                if (-not (Test-Path -LiteralPath $destinationDir)) {
                    New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
                }
                Copy-Item -LiteralPath $file.FullName -Destination $destinationPath -Force

                [PSCustomObject]@{
                    RelativePath    = $relativePath
                    SourcePath      = $file.FullName
                    DestinationPath = $destinationPath
                }
            }
        }
    }
}
