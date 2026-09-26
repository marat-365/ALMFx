#Requires -Version 5.1
<#
.SYNOPSIS
    Build entry point for ALMFx: analyse, test, and stage the PowerShell module.

.DESCRIPTION
    Runs PSScriptAnalyzer over the module and scripts, runs the Pester suite,
    and (with the Stage task) copies the module into ./out for publishing.

    Supports both PowerShell 5.1 and PowerShell 7+.

    CI runs: ./build/Invoke-Build.ps1 -Task Analyze, Test

.PARAMETER Task
    One or more of: Analyze, Test, Stage. Defaults to Analyze + Test.

.PARAMETER TestOnPS5
    Also run tests on PowerShell 5.1 (if available) for cross-version validation.

.EXAMPLE
    ./build/Invoke-Build.ps1 -Task Analyze, Test

.EXAMPLE
    ./build/Invoke-Build.ps1 -Task Stage

.EXAMPLE
    ./build/Invoke-Build.ps1 -Task Analyze, Test -TestOnPS5
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('Analyze', 'Test', 'Stage')]
    [string[]] $Task = @('Analyze', 'Test'),

    [switch] $TestOnPS5
)

$ErrorActionPreference = 'Stop'

# Join-Path only accepts a single -ChildPath in Windows PowerShell 5.1 (the
# multi-segment form is a PowerShell 6+ addition), so multi-segment paths are
# combined via [System.IO.Path]::Combine for 5.1/7+ compatibility.
$repoRoot   = Split-Path -Parent $PSScriptRoot
$modulePath = [System.IO.Path]::Combine($repoRoot, 'src', 'powershell', 'ALMFx')
$outPath    = Join-Path $repoRoot 'out'
$failed     = $false

if ('Analyze' -in $Task) {
    Write-Host '=== Analyze ===' -ForegroundColor Cyan
    Import-Module PSScriptAnalyzer -ErrorAction Stop

    # Invoke-ScriptAnalyzer's -Path parameter is [string], singular, not
    # [string[]] (confirmed against the Microsoft Learn reference) - despite
    # accepting pipeline input, a single call cannot be given a multi-element
    # array. Analyze each root separately and merge the results.
    $analyzePaths = @(
        [System.IO.Path]::Combine($repoRoot, 'src', 'powershell')
        Join-Path $repoRoot 'scripts'
        Join-Path $repoRoot 'build'
    ) | Where-Object { Test-Path -Path $_ }

    $settingsPath = Join-Path $repoRoot 'PSScriptAnalyzerSettings.psd1'
    $results = foreach ($analyzePath in $analyzePaths) {
        Invoke-ScriptAnalyzer -Path $analyzePath -Settings $settingsPath -Recurse
    }

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
    $config.Run.Path       = [System.IO.Path]::Combine($repoRoot, 'tests', 'Pester')
    $config.Run.PassThru   = $true
    $config.Output.Verbosity = 'Detailed'

    $result = Invoke-Pester -Configuration $config
    if ($result.FailedCount -gt 0) { $failed = $true }

    # Optionally test on PowerShell 5.1 (if available and requested)
    if ($TestOnPS5) {
        Write-Host "`n=== Cross-Version Test (PowerShell 5.1) ===" -ForegroundColor Cyan
        $ps5Path = "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe"
        if (Test-Path $ps5Path) {
            Write-Host "Running Pester tests on PowerShell 5.1..." -ForegroundColor Gray
            $ps5Result = & $ps5Path -NoProfile -ExecutionPolicy Bypass -Command @"
`$ErrorActionPreference = 'Stop'
Import-Module Pester -MinimumVersion 5.0.0 -ErrorAction Stop
`$config = New-PesterConfiguration
`$config.Run.Path = '$($config.Run.Path | ConvertTo-Json -Depth 2 | ConvertFrom-Json)'
`$config.Run.PassThru = `$true
`$config.Output.Verbosity = 'Detailed'
`$result = Invoke-Pester -Configuration `$config
exit `$result.FailedCount
"@
            if ($ps5Result -ne 0) {
                Write-Host "✗ PowerShell 5.1 tests failed (exit code: $ps5Result)" -ForegroundColor Red
                $failed = $true
            }
            else {
                Write-Host "✓ PowerShell 5.1 tests passed" -ForegroundColor Green
            }
        }
        else {
            Write-Host "⚠ PowerShell 5.1 not available (Windows only)" -ForegroundColor Yellow
        }
    }
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
