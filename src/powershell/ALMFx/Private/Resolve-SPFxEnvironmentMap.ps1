function Resolve-SPFxEnvironmentMap {
    <#
    .SYNOPSIS
        Reconciles discovered SPFx artefact identity against a persisted
        per-environment GUID/name map, reusing existing assignments and only
        generating new ones for artefacts not seen before.

    .DESCRIPTION
        This is what makes New-SPFxEnvironment safe to re-run. Re-running it
        after adding a new web part must keep every existing component's
        environment GUID exactly as it was - a caller may already have
        deployed the previous set under those GUIDs - and only assign a fresh
        GUID to the newly added component. A component (or the solution, or a
        feature) is "the same one as before" if its ORIGINAL id matches an
        entry already in the map; a changed alias on an unchanged id is still
        the same artefact. An artefact whose original id is no longer present
        in the current discovery is pruned from the map, so a later
        Set-SPFxEnvironment never re-deploys something that was removed from
        the source.

        When CreateUniqueNames is $false, no renaming happens at all: the map
        still records the artefact list (so pruning/idempotency tracking
        works uniformly), but NewId/NewAlias are set equal to the originals.

    .PARAMETER Identity
        The object returned by Get-ALMFxSPArtefactIdentity.

    .PARAMETER Environment
        Environment name, e.g. 'dev'.

    .PARAMETER CreateUniqueNames
        Whether new artefacts get a freshly generated GUID and an
        "<alias>_<environment>" name, or keep their original identity
        unchanged.

    .PARAMETER MapPath
        Path to the persisted map file for this environment. Loaded if it
        exists; the returned map is not written back to disk here - the
        caller persists it (via Save-ALMFxEnvironmentMap) after a successful
        copy, so a failed copy never leaves a map recording artefacts that
        were not actually written.

    .OUTPUTS
        PSCustomObject with Environment, CreateUniqueNames, Solution, Features
        (array), Components (array) - each entry carrying OriginalId/NewId
        (and OriginalAlias/NewAlias for the solution and components).

    .EXAMPLE
        $identity = Get-ALMFxSPArtefactIdentity -Path $solutionPath
        Resolve-SPFxEnvironmentMap -Identity $identity -Environment dev -CreateUniqueNames $true -MapPath $mapPath
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject] $Identity,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Environment,

        [Parameter(Mandatory)]
        [bool] $CreateUniqueNames,

        [Parameter(Mandatory)]
        [string] $MapPath
    )

    process {
        $existing = $null
        if (Test-Path -LiteralPath $MapPath) {
            try {
                $existing = Get-Content -LiteralPath $MapPath -Raw | ConvertFrom-Json
            }
            catch {
                Write-Warning "Existing map at '$MapPath' could not be read ($_) - treating as if no map existed. Every artefact will be assigned a fresh identity."
            }
        }

        function Get-ExistingComponentEntry {
            param($OriginalId)
            if (-not $existing) { return $null }
            $existing.Components | Where-Object { $_.OriginalId -eq $OriginalId } | Select-Object -First 1
        }

        # Named Get- (not New-), even though they compute a fresh GUID/name:
        # they have no side effect - nothing is created or persisted here,
        # only a value returned - and PSScriptAnalyzer's
        # PSUseShouldProcessForStateChangingFunctions rule flags any New-*
        # function as needing SupportsShouldProcess regardless of whether it
        # actually changes state.
        function Get-NewName {
            param([string] $OriginalAlias)
            if (-not $CreateUniqueNames -or [string]::IsNullOrEmpty($OriginalAlias)) { return $OriginalAlias }
            "${OriginalAlias}_${Environment}"
        }

        function Get-NewId {
            param([string] $OriginalId)
            if (-not $CreateUniqueNames) { return $OriginalId }
            ([guid]::NewGuid()).ToString()
        }

        # --- Solution ---
        $solutionEntry = $null
        if ($Identity.Solution) {
            $reused = if ($existing -and $existing.Solution -and $existing.Solution.OriginalId -eq $Identity.Solution.OriginalId) {
                $existing.Solution
            } else { $null }

            $solutionEntry = [PSCustomObject]@{
                OriginalId   = $Identity.Solution.OriginalId
                NewId        = if ($reused) { $reused.NewId } else { Get-NewId $Identity.Solution.OriginalId }
                OriginalName = $Identity.Solution.OriginalName
                NewName      = if ($reused) { $reused.NewName } else { Get-NewName $Identity.Solution.OriginalName }
            }
        }

        # --- Features ---
        $featureEntries = @()
        foreach ($feature in $Identity.Features) {
            $reused = if ($existing) {
                $existing.Features | Where-Object { $_.OriginalId -eq $feature.OriginalId } | Select-Object -First 1
            } else { $null }

            $featureEntries += [PSCustomObject]@{
                OriginalId = $feature.OriginalId
                NewId      = if ($reused) { $reused.NewId } else { Get-NewId $feature.OriginalId }
            }
        }

        # --- Components ---
        $componentEntries = @()
        foreach ($component in $Identity.Components) {
            $reused = Get-ExistingComponentEntry -OriginalId $component.OriginalId

            $componentEntries += [PSCustomObject]@{
                OriginalId    = $component.OriginalId
                NewId         = if ($reused) { $reused.NewId } else { Get-NewId $component.OriginalId }
                OriginalAlias = $component.OriginalAlias
                NewAlias      = if ($reused) { $reused.NewAlias } else { Get-NewName $component.OriginalAlias }
            }
        }

        [PSCustomObject]@{
            Environment       = $Environment
            CreateUniqueNames = $CreateUniqueNames
            Solution          = $solutionEntry
            Features          = $featureEntries
            Components        = $componentEntries
        }
    }
}
