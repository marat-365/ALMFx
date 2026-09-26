#Requires -Version 5.1
<#
.SYNOPSIS
    Run ALMFx tests on all available PowerShell versions

.DESCRIPTION
    Orchestrator script that discovers and tests the module on:
    - PowerShell 5.1 (Windows PowerShell)
    - PowerShell 7+ (Core)
    
    Generates a comparison report of test results across versions.

.PARAMETER OutputReport
    Optional CSV file to write test results to (for CI pipelines).

.PARAMETER SkipPS5
    Skip PowerShell 5.1 tests (e.g., on non-Windows or for faster CI).

.PARAMETER SkipPS7
    Skip PowerShell 7+ tests (testing only on PS 5.1).

.EXAMPLE
    # Test on all available versions
    .\testplaygrounds\run-all-tests.ps1

.EXAMPLE
    # Generate CSV report for CI
    .\testplaygrounds\run-all-tests.ps1 -OutputReport test-results.csv

.EXAMPLE
    # Test only on PS 5.1
    .\testplaygrounds\run-all-tests.ps1 -SkipPS7

.NOTES
    Requires:
    - Windows OS (for PS 5.1 availability)
    - PowerShell 7+ installed (for cross-version testing)
    
    This script itself must run on PS 5.1+ with execution policy bypass.
#>
param(
    [string] $OutputReport,
    [switch] $SkipPS5,
    [switch] $SkipPS7
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$testScript = Join-Path $PSScriptRoot "test-module.ps1"

Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  ALMFx Multi-Version Test Orchestrator                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "Repo: $repoRoot`n" -ForegroundColor Gray

$results = @()
$exitCode = 0

# === DETECT AVAILABLE POWERSHELLS ===
Write-Host "Detecting PowerShell installations..." -ForegroundColor Yellow

$ps5Path = $null
$ps7Path = $null

# PS 5.1 (Windows PowerShell)
if (-not $SkipPS5) {
    if ($PSVersionTable.PSEdition -eq 'Desktop' -or (Test-Path "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe")) {
        $ps5Path = "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe"
        Write-Host "✓ PowerShell 5.1 detected: $ps5Path" -ForegroundColor Green
    }
    else {
        Write-Host "⚠ PowerShell 5.1 not available (Windows only)" -ForegroundColor Yellow
    }
}

# PS 7+
if (-not $SkipPS7) {
    # Try pwsh first, then fallback to Get-Command
    $pwshPath = $null
    if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        $pwshPath = (Get-Command pwsh).Source
        Write-Host "✓ PowerShell 7+ detected: $pwshPath" -ForegroundColor Green
    }
    else {
        Write-Host "⚠ PowerShell 7+ not installed" -ForegroundColor Yellow
    }
    $ps7Path = $pwshPath
}

if (-not $ps5Path -and -not $ps7Path) {
    Write-Host "✗ No PowerShell versions available to test" -ForegroundColor Red
    exit 1
}

# === RUN TESTS ===
Write-Host "`nRunning tests...`n" -ForegroundColor Cyan

$testCount = 0
if ($ps5Path) { $testCount++ }
if ($ps7Path) { $testCount++ }

$currentTest = 0

if ($ps5Path) {
    $currentTest++
    Write-Host "[$currentTest/$testCount] Testing on PowerShell 5.1..." -ForegroundColor Cyan
    Write-Host "─" * 60 -ForegroundColor Gray

    try {
        $output = & $ps5Path -NoProfile -ExecutionPolicy Bypass -Command @"
`$TEST_NO_AUTO_RUN = `$null
. '$testScript'
Test-ALMFxModule
"@
        $success = $LASTEXITCODE -eq 0
        Write-Host $output
        Write-Host "─" * 60 -ForegroundColor Gray
        Write-Host "$(if ($success) { '✓' } else { '✗' }) PowerShell 5.1 completed (exit code: $LASTEXITCODE)" -ForegroundColor $(if ($success) { "Green" } else { "Red" })

        $results += @{
            PowerShellVersion = '5.1 (Desktop)'
            Status            = $(if ($success) { "PASS" } else { "FAIL" })
            ExitCode          = $LASTEXITCODE
            Timestamp         = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

        if (-not $success) { $exitCode = 1 }
    }
    catch {
        Write-Host "✗ Error running PS 5.1 tests: $_" -ForegroundColor Red
        $results += @{
            PowerShellVersion = '5.1 (Desktop)'
            Status            = "ERROR"
            ExitCode          = -1
            Timestamp         = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        $exitCode = 1
    }

    Write-Host ""
}

if ($ps7Path) {
    $currentTest++
    Write-Host "[$currentTest/$testCount] Testing on PowerShell 7+..." -ForegroundColor Cyan
    Write-Host "─" * 60 -ForegroundColor Gray

    try {
        $output = & $ps7Path -NoProfile -ExecutionPolicy Bypass -Command @"
`$TEST_NO_AUTO_RUN = `$null
. '$testScript'
Test-ALMFxModule
"@
        $success = $LASTEXITCODE -eq 0
        Write-Host $output
        Write-Host "─" * 60 -ForegroundColor Gray
        Write-Host "$(if ($success) { '✓' } else { '✗' }) PowerShell 7+ completed (exit code: $LASTEXITCODE)" -ForegroundColor $(if ($success) { "Green" } else { "Red" })

        $results += @{
            PowerShellVersion = '7+ (Core)'
            Status            = $(if ($success) { "PASS" } else { "FAIL" })
            ExitCode          = $LASTEXITCODE
            Timestamp         = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

        if (-not $success) { $exitCode = 1 }
    }
    catch {
        Write-Host "✗ Error running PS 7+ tests: $_" -ForegroundColor Red
        $results += @{
            PowerShellVersion = '7+ (Core)'
            Status            = "ERROR"
            ExitCode          = -1
            Timestamp         = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        $exitCode = 1
    }

    Write-Host ""
}

# === REPORT ===
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Test Results Summary                                 ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

if ($results.Count -gt 0) {
    $results | ForEach-Object {
        $statusColor = switch ($_.Status) {
            "PASS" { "Green" }
            "FAIL" { "Red" }
            default { "Yellow" }
        }
        Write-Host "$($_.PowerShellVersion): $($_.Status)" -ForegroundColor $statusColor
    }
}

# === OUTPUT REPORT ===
if ($OutputReport) {
    Write-Host "`nExporting results to: $OutputReport" -ForegroundColor Gray
    $results | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath $OutputReport -Encoding UTF8 -Force
    Write-Host "✓ Report written" -ForegroundColor Green
}

Write-Host "`nExit code: $exitCode" -ForegroundColor Gray
exit $exitCode
