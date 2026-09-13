#Requires -Version 7.4
<#
.SYNOPSIS
    Build entry point for ALMFx: analyse, test, and stage the PowerShell module.

.DESCRIPTION
    Runs PSScriptAnalyzer over the module and scripts, runs the Pester suite,
    and (with the Stage task) copies the module into ./out for publishing.

    CI runs: ./build/Invoke-Build.ps1 -Task Analyze, Test

.PARAMETER Task
    One or more of: Analyze, Test, Stage. Defaults to Analyze + Test.

.EXAMPLE
    ./build/Invoke-Build.ps1 -Task Analyze, Test

.EXAMPLE
    ./build/Invoke-Build.ps1 -Task Stage
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('Analyze', 'Test', 'Stage')]
    [string[]] $Task = @('Analyze', 'Test')
)

$ErrorActionPreference = 'Stop'

$repoRoot   = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path $repoRoot 'src' 'powershell' 'ALMFx'
$outPath    = Join-Path $repoRoot 'out'
$failed     = $false

if ('Analyze' -in $Task) {
    Write-Host '=== Analyze ===' -ForegroundColor Cyan
    Import-Module PSScriptAnalyzer -ErrorAction Stop

    $results = Invoke-ScriptAnalyzer `
        -Path (Join-Path $repoRoot 'src' 'powershell'), (Join-Path $repoRoot 'scripts'), (Join-Path $repoRoot 'build') `
        -Settings (Join-Path $repoRoot 'PSScriptAnalyzerSettings.psd1') `
        -Recurse

    if ($results) {
        $results | Format-Table -AutoSize | Out-String | Write-Host
        $failed = $true
    }
    else {
        Write-Host 'PSScriptAnalyzer: clean.' -ForegroundColor Green
    }
}

if ('Test' -in $Task) {
    Write-Host '=== Test ===' -ForegroundColor Cyan
    Import-Module Pester -MinimumVersion 5.0.0 -ErrorAction Stop

    $config = New-PesterConfiguration
    $config.Run.Path       = Join-Path $repoRoot 'tests' 'Pester'
    $config.Run.PassThru   = $true
    $config.Output.Verbosity = 'Detailed'

    $result = Invoke-Pester -Configuration $config
    if ($result.FailedCount -gt 0) { $failed = $true }
}

if ('Stage' -in $Task) {
    Write-Host '=== Stage ===' -ForegroundColor Cyan
    if (Test-Path $outPath) { Remove-Item $outPath -Recurse -Force }
    $target = Join-Path $outPath 'ALMFx'
    New-Item -Path $target -ItemType Directory -Force | Out-Null

    Copy-Item -Path (Join-Path $modulePath '*') -Destination $target -Recurse -Force
    Get-ChildItem -Path $target -Include '*.gitkeep', '*.txt.template' -Recurse -File | Remove-Item -Force

    Test-ModuleManifest -Path (Join-Path $target 'ALMFx.psd1') | Out-Null
    Write-Host "Staged to $target" -ForegroundColor Green
}

if ($failed) {
    throw 'Build failed.'
}
