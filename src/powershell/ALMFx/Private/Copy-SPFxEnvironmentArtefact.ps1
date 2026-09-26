function Copy-SPFxEnvironmentArtefact {
    <#
    .SYNOPSIS
        Copies every SharePoint-relevant json/xml file in an SPFx solution
        into its per-environment folder, mirroring relative paths, rewriting
        GUIDs and names per the resolved environment map.

    .DESCRIPTION
        "SharePoint-relevant" is decided by content, not by a fixed list of
        filenames: any .json or .xml file under Path (excluding
        node_modules/lib/dist/temp/.git and any existing .<environment>
        payload folder) that textually contains at least one of the map's
        known original GUIDs or names is copied to
        <Path>/.<Environment>/<same relative path>. A real SPFx solution
        echoes a component's GUID in more places than its own manifest - this
        project's config/serve.json is a concrete example - so a fixed
        include-list would silently miss files like it.

        When the map's CreateUniqueNames is $true, every occurrence of a known
        original GUID or name is rewritten to its mapped replacement in the
        copy. GUIDs are matched case-insensitively (tooling is inconsistent
        about GUID casing); names are matched only at token boundaries so that
        one alias being a prefix of another (e.g. "Foo" vs "FooBar") cannot
        clobber the wrong one, and are replaced longest-first for the same
        reason. When CreateUniqueNames is $false, files are copied verbatim -
        relevance is still content-based, but no text is rewritten.

        After copying, any file already present under
        <Path>/.<Environment>/ that no longer corresponds to a currently
        relevant source file is removed. This is what keeps a removed
        component from continuing to ship after it's deleted from the
        solution - see Resolve-SPFxEnvironmentMap for the matching pruning
        of the persisted id/name map.

    .PARAMETER Path
        Root folder of the SPFx solution.

    .PARAMETER Environment
        Environment name; files are written to <Path>/.<Environment>/.

    .PARAMETER Map
        The object returned by Resolve-SPFxEnvironmentMap.

    .OUTPUTS
        PSCustomObject per file copied: @{ RelativePath; SourcePath; DestinationPath }

    .EXAMPLE
        Copy-SPFxEnvironmentArtefact -Path ./testplaygrounds/spfx-sample-app -Environment dev -Map $resolvedMap
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Environment,

        [Parameter(Mandatory)]
        [PSCustomObject] $Map
    )

    process {
        $destinationRoot = [System.IO.Path]::Combine($Path, ".$Environment")
        $excludePattern = '(^|[\\/])(node_modules|lib|dist|temp|\.git|\.[A-Za-z0-9_-]+)([\\/]|$)'
        # The trailing "\.[A-Za-z0-9_-]+" segment excludes every dot-folder
        # (.dev, .test, .prod, ...) so a re-run never treats a previous run's
        # own output, or another environment's, as a source to scan.
        #
        # This MUST be tested against each file's path *relative to $Path*,
        # never its absolute FullName: -notmatch is case-insensitive, and an
        # absolute path very commonly contains a "temp"/"Temp" segment above
        # the solution root that has nothing to do with the solution's own
        # temp/ build folder - most notably the OS temp directory itself
        # (Windows: C:\Users\<user>\AppData\Local\Temp\...; a Pester
        # $TestDrive lives there). Matching on FullName caused every
        # candidate file to be wrongly excluded on Windows, while working by
        # accident on Linux only because /tmp does not contain the substring
        # "temp".

        # --- Build the token table: every known original GUID/name, used to
        # both detect which files are relevant and (when CreateUniqueNames is
        # true) rewrite them. A token is still needed for relevance detection
        # even when Old equals New - which is every token, always, in
        # CreateUniqueNames=$false mode - so this must NOT skip same-value
        # tokens; only null/empty originals are meaningless to search for.
        $tokens = New-Object System.Collections.Generic.List[PSCustomObject]

        function Add-Token {
            param([string] $Old, [string] $New, [bool] $IsGuid)
            if ([string]::IsNullOrEmpty($Old)) { return }
            $tokens.Add([PSCustomObject]@{ Old = $Old; New = $New; IsGuid = $IsGuid })
        }

        if ($Map.Solution) {
            Add-Token -Old $Map.Solution.OriginalId -New $Map.Solution.NewId -IsGuid $true
            Add-Token -Old $Map.Solution.OriginalName -New $Map.Solution.NewName -IsGuid $false
        }
        foreach ($feature in $Map.Features) {
            Add-Token -Old $feature.OriginalId -New $feature.NewId -IsGuid $true
        }
        foreach ($component in $Map.Components) {
            Add-Token -Old $component.OriginalId -New $component.NewId -IsGuid $true
            Add-Token -Old $component.OriginalAlias -New $component.NewAlias -IsGuid $false
        }

        # Longest-first so "Foo" can never clobber "FooBar" before "FooBar" is matched.
        $orderedTokens = $tokens | Sort-Object { $_.Old.Length } -Descending

        if ($orderedTokens.Count -eq 0) {
            Write-Warning "No artefact identity found for '$Path' - nothing to copy. Is this an SPFx solution folder (does it have config/package-solution.json)?"
            return
        }

        # --- Find every candidate file and test it for relevance ---
        # -Force is mandatory: PowerShell treats a leading-dot filename (e.g.
        # .yo-rc.json, which legitimately echoes the solution GUID) as hidden
        # on every platform, not just Windows, and Get-ChildItem skips hidden
        # items without -Force even though `ls` on Linux would show them.
        $candidates = Get-ChildItem -LiteralPath $Path -Include '*.json', '*.xml' -Recurse -File -Force -ErrorAction SilentlyContinue |
            Where-Object { ($_.FullName.Substring($Path.Length).TrimStart('\', '/')) -notmatch $excludePattern }

        $copied = [System.Collections.Generic.List[PSCustomObject]]::new()
        $copiedRelativePaths = [System.Collections.Generic.HashSet[string]]::new()

        foreach ($file in $candidates) {
            $text = Get-Content -LiteralPath $file.FullName -Raw
            $relevantTokens = $orderedTokens | Where-Object { $text.IndexOf($_.Old, [System.StringComparison]::OrdinalIgnoreCase) -ge 0 }
            if (-not $relevantTokens) { continue }

            # Normalized to forward slashes: RelativePath is a logical,
            # cross-platform identifier (compared against literal
            # forward-slash paths by callers and tests), not an OS path -
            # native separators here would make it Windows-only-correct,
            # same class of bug as matching the exclude pattern above
            # against an absolute path.
            $relativePath = ($file.FullName.Substring($Path.Length).TrimStart('\', '/')) -replace '\\', '/'
            $destinationPath = [System.IO.Path]::Combine($destinationRoot, $relativePath)

            if ($PSCmdlet.ShouldProcess($destinationPath, 'Write environment artefact copy')) {
                $newText = $text
                if ($Map.CreateUniqueNames) {
                    foreach ($token in $relevantTokens) {
                        $pattern = if ($token.IsGuid) {
                            [regex]::Escape($token.Old)
                        }
                        else {
                            # Word-boundary-safe: a name is only replaced where
                            # it is not immediately preceded/followed by another
                            # identifier character.
                            "(?<![A-Za-z0-9_])$([regex]::Escape($token.Old))(?![A-Za-z0-9_])"
                        }
                        # No param() block: a MatchEvaluator delegate always
                        # passes one Match argument, but the replacement here
                        # never depends on it, and declaring an unused $m
                        # trips PSScriptAnalyzer's unused-parameter rule.
                        $newText = [regex]::Replace($newText, $pattern, [System.Text.RegularExpressions.MatchEvaluator] { $token.New }, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                    }
                }

                $destinationDir = Split-Path -Path $destinationPath -Parent
                if (-not (Test-Path -LiteralPath $destinationDir)) {
                    New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
                }
                Set-Content -LiteralPath $destinationPath -Value $newText -NoNewline

                [void]$copiedRelativePaths.Add($relativePath)
                $copiedEntry = [PSCustomObject]@{
                    RelativePath    = $relativePath
                    SourcePath      = $file.FullName
                    DestinationPath = $destinationPath
                }
                $copied.Add($copiedEntry)
            }
        }

        # --- Prune stale files: present under .<Environment> but no longer relevant ---
        if (Test-Path -LiteralPath $destinationRoot) {
            # -Force throughout: see the note on the candidate scan above -
            # a previously-copied dot-file (.yo-rc.json) must be visible to
            # pruning too, or it would survive forever after its component
            # was removed from the source.
            $existingFiles = Get-ChildItem -LiteralPath $destinationRoot -Recurse -File -Force -ErrorAction SilentlyContinue
            foreach ($existingFile in $existingFiles) {
                $existingRelative = ($existingFile.FullName.Substring($destinationRoot.Length).TrimStart('\', '/')) -replace '\\', '/'
                if (-not $copiedRelativePaths.Contains($existingRelative)) {
                    if ($PSCmdlet.ShouldProcess($existingFile.FullName, 'Remove stale environment artefact copy')) {
                        Remove-Item -LiteralPath $existingFile.FullName -Force
                    }
                }
            }
            # Clean up any directories left empty by pruning.
            Get-ChildItem -LiteralPath $destinationRoot -Recurse -Directory -Force -ErrorAction SilentlyContinue |
                Sort-Object { $_.FullName.Length } -Descending |
                Where-Object { -not (Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue) } |
                Remove-Item -Force -ErrorAction SilentlyContinue
        }

        $copied
    }
}
