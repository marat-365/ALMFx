function Get-ALMFxSPArtefactIdentity {
    <#
    .SYNOPSIS
        Discovers the SharePoint/SPFx artefact identities (solution, features,
        components) defined by an SPFx solution folder.

    .DESCRIPTION
        Reads config/package-solution.json and every src/**/*.manifest.json to
        build the authoritative list of GUIDs and names that identify this
        solution's artefacts: the solution itself, each SPFx "feature" listed
        under solution.features, and each component (web part, extension,
        library, Adaptive Card Extension).

        This is deliberately NOT a blind scan for GUID-shaped strings anywhere
        in the tree. A real SPFx solution's json/xml files contain GUIDs that
        are NOT artefact identity - most commonly a fixed Microsoft web-part
        gallery category (preconfiguredEntries[].groupId, e.g. "Advanced" or
        "Dashboard" - the same constant across every SPFx project) or a GUID
        that happens to appear inside a comment/URL string
        (support.office.com article IDs in the generated manifest comments).
        Treating those as artefact identity and regenerating them would break
        the web part gallery grouping and corrupt an unrelated comment.
        Only the following specific fields count as identity:

        - config/package-solution.json: solution.id, solution.name,
          solution.features[].id
        - Every src/**/*.manifest.json: the top-level "id" and "alias" fields

        manifest.json files are generated with `//` line comments, which makes
        them technically JSONC, not JSON. PowerShell 7's ConvertFrom-Json
        happens to tolerate this; Windows PowerShell 5.1's does not (confirmed
        against real files - see the function's own tests). Rather than depend
        on that version difference, or write a comment-stripper that risks
        corrupting a comment or string containing "//" (this project's own
        manifests have both: a "//" comment AND a schema/support URL containing
        "//"), the top-level id/alias are extracted with a targeted regex
        instead of a full JSON parse. package-solution.json has no comments and
        is parsed for real.

    .PARAMETER Path
        Root folder of the SPFx solution (the folder containing
        config/package-solution.json and src/).

    .OUTPUTS
        PSCustomObject with:
          Solution   - @{ OriginalId; OriginalName }, or $null if
                       config/package-solution.json is missing
          Features   - array of @{ OriginalId }
          Components - array of @{ OriginalId; OriginalAlias; SourcePath }

    .EXAMPLE
        Get-ALMFxSPArtefactIdentity -Path ./testplaygrounds/spfx-sample-app
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    process {
        $guidPattern = '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'

        $solution = $null
        $features = @()
        $packageSolutionPath = [System.IO.Path]::Combine($Path, 'config', 'package-solution.json')
        if (Test-Path -LiteralPath $packageSolutionPath) {
            # No comments in this file - a real parse is safe and gives
            # structured access instead of another regex.
            $packageSolution = Get-Content -LiteralPath $packageSolutionPath -Raw | ConvertFrom-Json

            if ($packageSolution.solution) {
                $solution = [PSCustomObject]@{
                    OriginalId   = $packageSolution.solution.id
                    OriginalName = $packageSolution.solution.name
                    SourcePath   = $packageSolutionPath
                }

                foreach ($feature in $packageSolution.solution.features) {
                    if ($feature.id) {
                        $features += [PSCustomObject]@{
                            OriginalId = $feature.id
                            SourcePath = $packageSolutionPath
                        }
                    }
                }
            }
        }
        else {
            Write-Verbose "No config/package-solution.json under '$Path' - solution/feature identity will be empty."
        }

        $components = @()
        # Matched against each file's path *relative to $Path*, not its
        # absolute FullName - an absolute path very commonly contains a
        # "temp"/"Temp" segment above the solution root (most notably the OS
        # temp directory itself, e.g. Windows'
        # C:\Users\<user>\AppData\Local\Temp\...) that has nothing to do with
        # the solution's own temp/ build folder. See the identical note in
        # Copy-ALMFxEnvironmentArtefact.ps1, where matching on FullName
        # silently excluded every candidate file on Windows.
        $manifestFiles = Get-ChildItem -LiteralPath $Path -Filter '*.manifest.json' -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { ($_.FullName.Substring($Path.Length).TrimStart('\', '/')) -notmatch '(^|[\\/])(node_modules|lib|dist|temp|\.git)([\\/]|$)' }

        foreach ($manifestFile in $manifestFiles) {
            $text = Get-Content -LiteralPath $manifestFile.FullName -Raw

            $idMatches = [regex]::Matches($text, "`"id`"\s*:\s*`"($guidPattern)`"")
            $aliasMatches = [regex]::Matches($text, '"alias"\s*:\s*"([^"]+)"')

            if ($idMatches.Count -eq 0) {
                Write-Warning "No top-level 'id' found in '$($manifestFile.FullName)' - skipping. Not a valid SPFx component manifest?"
                continue
            }
            if ($idMatches.Count -gt 1) {
                Write-Warning "Multiple 'id' fields found in '$($manifestFile.FullName)' - using the first ($($idMatches[0].Groups[1].Value)). Verify this manifest is well-formed."
            }
            if ($aliasMatches.Count -eq 0) {
                Write-Warning "No 'alias' found in '$($manifestFile.FullName)' - component will be renamed by id only, not by alias."
            }

            $components += [PSCustomObject]@{
                OriginalId    = $idMatches[0].Groups[1].Value
                OriginalAlias = if ($aliasMatches.Count -gt 0) { $aliasMatches[0].Groups[1].Value } else { $null }
                SourcePath    = $manifestFile.FullName
            }
        }

        [PSCustomObject]@{
            Solution   = $solution
            Features   = $features
            Components = $components
        }
    }
}
