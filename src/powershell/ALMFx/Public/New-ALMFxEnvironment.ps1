function New-ALMFxEnvironment {
    <#
    .SYNOPSIS
        Builds a per-environment copy of an SPFx solution's SharePoint-facing
        json/xml files, optionally isolated with fresh GUIDs and suffixed
        names so it can be deployed side by side with other environments.

    .DESCRIPTION
        Discovers the solution's identity - the solution id, its SPFx
        "feature" id(s), and every component's id and alias (web parts,
        extensions, libraries, Adaptive Card Extensions) - from
        config/package-solution.json and every src/**/*.manifest.json. It
        then scans every .json/.xml file in the solution for occurrences of
        those specific identities (not a blind scan for anything GUID-shaped:
        a real SPFx solution also contains fixed Microsoft system GUIDs, such
        as a web part gallery category id, that must never be touched) and
        copies every file that references at least one of them into
        <Path>/.<Environment>/, mirroring the file's path relative to <Path>.

        With -CreateUniqueNames (the default unless -Environment is "prod" or
        "production", case-insensitive), every occurrence of a known original
        id or alias is rewritten in the copy: each component's id becomes a
        freshly generated GUID and its alias becomes "<alias>_<environment>";
        the solution's id and name are rewritten the same way. This is what
        lets a dev/test/staging build of the solution be deployed to the same
        tenant as production without colliding with it. Without
        -CreateUniqueNames, files are copied verbatim - no rewriting at all -
        which is the right default for prod: production should keep the
        identity that is already live.

        Rewriting is applied consistently everywhere a given id or alias
        appears - a single component's id, for example, is typically echoed
        in its own manifest, in sharepoint/assets/elements.xml and/or
        ClientSideInstance.xml, and in config/serve.json; all are updated to
        the same new value.

        Re-running this function for the same -Environment is safe and
        expected: a persisted identity map at
        <Path>/.almfx/environments/<Environment>.map.json (outside the
        .<Environment> payload, so Set-ALMFxEnvironment never ships it) is
        read first, and every artefact already present there keeps exactly
        the id/alias it was assigned before. Only artefacts not yet in the
        map - a newly added web part, for instance - get a freshly generated
        identity. An artefact that no longer exists in the source (removed
        since the last run) is pruned from both the map and the
        .<Environment> folder, so a later Set-ALMFxEnvironment never
        re-deploys something that was deleted.

        Read-only with respect to the solution's own source files - it only
        ever writes under <Path>/.<Environment>/ and
        <Path>/.almfx/environments/. To actually deploy an environment's
        files into the solution, run Set-ALMFxEnvironment afterwards.

    .PARAMETER Path
        Root folder of the SPFx solution (the folder containing
        config/package-solution.json and src/). Defaults to the current
        directory.

    .PARAMETER Environment
        Environment name, e.g. "dev", "test", "prod". Used as the payload
        folder name (.<Environment>), the persisted map's filename, and (when
        -CreateUniqueNames is in effect) the name suffix. Matched
        case-insensitively against "prod"/"production" to decide the
        -CreateUniqueNames default, and normalized to lowercase wherever it is
        used in a path or a name, so "Dev" and "dev" cannot silently produce
        two different environments on a case-sensitive filesystem.

    .PARAMETER CreateUniqueNames
        Whether components get a freshly generated (or previously-assigned,
        on re-run) GUID and an "_<environment>" name suffix, or keep their
        original identity unchanged. Defaults to $true, unless -Environment is
        "prod" or "production" (case-insensitive), in which case it defaults
        to $false. Pass explicitly to override either way.

    .EXAMPLE
        New-ALMFxEnvironment -Path ./testplaygrounds/spfx-sample-app -Environment dev

        Builds testplaygrounds/spfx-sample-app/.dev/ with fresh GUIDs and
        "_dev"-suffixed names for every component.

    .EXAMPLE
        New-ALMFxEnvironment -Environment prod

        Against the current directory. -CreateUniqueNames defaults to $false
        because the environment is "prod", so .prod/ is a verbatim copy of the
        relevant files - no identity change.

    .EXAMPLE
        New-ALMFxEnvironment -Path ./my-solution -Environment dev -WhatIf

        Reports every file that would be written or removed under
        my-solution/.dev/, without changing anything on disk.

    .OUTPUTS
        System.Management.Automation.PSCustomObject with Environment, Path,
        CreateUniqueNames, DestinationPath, MapPath, and Files (the per-file
        copy result from the underlying engine).

    .NOTES
        Pure filesystem/text operation - makes no PnP or network calls, and
        runs on both PowerShell 5.1 and 7+.

    .LINK
        https://github.com/marat-365/ALMFx
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Path = (Get-Location).Path,

        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_-]*$')]
        [string] $Environment,

        [Parameter()]
        [bool] $CreateUniqueNames = ($Environment -notin @('prod', 'production'))
    )

    process {
        $resolvedPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
        $normalizedEnvironment = $Environment.ToLowerInvariant()

        $packageSolutionPath = [System.IO.Path]::Combine($resolvedPath, 'config', 'package-solution.json')
        if (-not (Test-Path -LiteralPath $packageSolutionPath)) {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.IO.FileNotFoundException]::new("'$resolvedPath' does not look like an SPFx solution root - config/package-solution.json was not found."),
                    'ALMFx.NotAnSPFxSolution',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $resolvedPath
                )
            )
        }

        Write-Verbose "Discovering artefact identity under '$resolvedPath'."
        $identity = Get-ALMFxSPArtefactIdentity -Path $resolvedPath

        $mapDir = [System.IO.Path]::Combine($resolvedPath, '.almfx', 'environments')
        $mapPath = [System.IO.Path]::Combine($mapDir, "$normalizedEnvironment.map.json")

        Write-Verbose "Reconciling against identity map '$mapPath' (CreateUniqueNames=$CreateUniqueNames)."
        $map = Resolve-ALMFxEnvironmentMap -Identity $identity -Environment $normalizedEnvironment -CreateUniqueNames $CreateUniqueNames -MapPath $mapPath

        if ($PSCmdlet.ShouldProcess($mapPath, 'Write environment identity map')) {
            if (-not (Test-Path -LiteralPath $mapDir)) {
                New-Item -Path $mapDir -ItemType Directory -Force | Out-Null
            }
            $map | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $mapPath -NoNewline
        }

        # Forward -WhatIf only ($WhatIfPreference is a genuine boolean).
        # $ConfirmPreference is a ConfirmImpact string ('None'/'Low'/'Medium'/
        # 'High'), not a boolean - passing it to a switch parameter coerces
        # any non-empty string (including the default 'High') to $true,
        # forcing every nested ShouldProcess call to prompt unconditionally.
        # Leaving -Confirm unpassed lets the nested call's own ConfirmImpact
        # and the session's actual $ConfirmPreference decide, same as if it
        # had been invoked directly.
        $files = Copy-ALMFxEnvironmentArtefact -Path $resolvedPath -Environment $normalizedEnvironment -Map $map -WhatIf:$WhatIfPreference

        [PSCustomObject]@{
            Environment       = $normalizedEnvironment
            Path              = $resolvedPath
            CreateUniqueNames = $CreateUniqueNames
            DestinationPath   = [System.IO.Path]::Combine($resolvedPath, ".$normalizedEnvironment")
            MapPath           = $mapPath
            Files             = $files
        }
    }
}
