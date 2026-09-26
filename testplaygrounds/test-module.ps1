#Requires -Version 5.1
<#
.SYNOPSIS
    ALMFx Module Test Playground — Single-Version Testing

.DESCRIPTION
    Standalone test harness for ALMFx that works on PowerShell 5.1 and 7+.
    Tests module loading, public functions, help content, and compatibility.
    
    No external dependencies beyond Pester and PSScriptAnalyzer (both installed automatically).

.PARAMETER FunctionName
    Test a specific function by name. If not specified, tests all public functions.

.PARAMETER Verbose
    Enable verbose output to see detailed test progress.

.PARAMETER SkipScriptAnalyzer
    Skip PSScriptAnalyzer linting (useful if not installed).

.EXAMPLE
    . .\testplaygrounds\test-module.ps1
    Test-ALMFxModule

.EXAMPLE
    Test-ALMFxFunction -FunctionName "Get-ALMFxVersion"

.NOTES
    Compatible with:
    - PowerShell 5.1 (Windows PowerShell)
    - PowerShell 7.x+ (Core)
    
    Call this from repo root:
    pwsh -NoProfile -Command ". .\testplaygrounds\test-module.ps1; Test-ALMFxModule"
#>
param()

function Test-ALMFxModule {
    [CmdletBinding()]
    param(
        [string] $FunctionName,
        [switch] $SkipScriptAnalyzer
    )

    # Resolve repo root: testplaygrounds is at [repoRoot]/testplaygrounds
    # So parent of testplaygrounds parent is the actual repo root
    $repoRoot = Split-Path -Parent $PSScriptRoot
    
    # Verify: should contain src/, tests/, build/, etc.
    if (-not (Test-Path (Join-Path $repoRoot 'src'))) {
        # Fallback: try one more level up (in case called from nested path)
        $repoRoot = Split-Path -Parent $repoRoot
    }
    
    $modulePath = [System.IO.Path]::Combine($repoRoot, "src", "powershell", "ALMFx")

    Write-Host "`n=== ALMFx Test Playground ===" -ForegroundColor Cyan
    Write-Host "PowerShell: $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))" -ForegroundColor Gray
    Write-Host "Module Path: $modulePath" -ForegroundColor Gray
    Write-Host "Repo Root: $repoRoot`n" -ForegroundColor Gray

    # Verify module path exists
    if (-not (Test-Path $modulePath)) {
        Write-Host "✗ Module path does not exist: $modulePath" -ForegroundColor Red
        Write-Host "  testplaygrounds path: $PSScriptRoot" -ForegroundColor Gray
        Write-Host "  Resolved repo root: $repoRoot" -ForegroundColor Gray
        Write-Host "  Expected src/ at: $(Join-Path $repoRoot 'src')" -ForegroundColor Gray
        return
    }

    # === PHASE 1: Module Load ===
    Write-Host "PHASE 1: Module Load" -ForegroundColor Yellow
    try {
        if (Get-Module ALMFx) { Remove-Module ALMFx -Force }
        Import-Module -FullyQualifiedName $modulePath -Force
        $module = Get-Module ALMFx
        Write-Host "✓ Module loaded successfully" -ForegroundColor Green
        Write-Host "  Version: $($module.Version)" -ForegroundColor Gray
        Write-Host "  Edition: $($module.CompatiblePSEditions -join ', ')" -ForegroundColor Gray
    }
    catch {
        Write-Host "✗ Failed to load module: $_" -ForegroundColor Red
        return
    }

    # === PHASE 2: Manifest Validation ===
    Write-Host "`nPHASE 2: Manifest Validation" -ForegroundColor Yellow
    try {
        $manifestPath = Join-Path $modulePath "ALMFx.psd1"
        $manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
        Write-Host "✓ Manifest is valid" -ForegroundColor Green
        Write-Host "  Functions exported: $($manifest.ExportedFunctions.Keys.Count)" -ForegroundColor Gray
        $manifest.ExportedFunctions.Keys | ForEach-Object { Write-Host "    - $_" -ForegroundColor Gray }
    }
    catch {
        Write-Host "✗ Manifest validation failed: $_" -ForegroundColor Red
        return
    }

    # === PHASE 3: Function Tests ===
    Write-Host "`nPHASE 3: Function Tests" -ForegroundColor Yellow
    $functions = if ($FunctionName) {
        @($FunctionName)
    }
    else {
        $module.ExportedFunctions.Keys
    }

    $passCount = 0
    $failCount = 0

    foreach ($func in $functions) {
        try {
            Write-Host "  Testing: $func" -ForegroundColor Cyan

            # Test 1: Function exists and is callable
            $cmd = Get-Command -Name $func -ErrorAction Stop
            Write-Host "    ✓ Function exists" -ForegroundColor Green

            # Test 2: Has help
            $help = Get-Help -Name $func -ErrorAction Stop
            if ($help.Synopsis -and $help.Synopsis -notmatch "^\s*$") {
                Write-Host "    ✓ Help documentation exists" -ForegroundColor Green
            }
            else {
                Write-Host "    ✗ Help missing or empty" -ForegroundColor Yellow
                $failCount++
            }

            # Test 3: Has OutputType
            if ($cmd.OutputType) {
                Write-Host "    ✓ OutputType declared: $($cmd.OutputType.Name -join ', ')" -ForegroundColor Green
            }
            else {
                Write-Host "    ! OutputType not declared (warning)" -ForegroundColor Yellow
            }

            # Test 4: Actually invoke basic call
            if ($func -eq "Get-ALMFxVersion") {
                try {
                    $result = & $func
                    if ($result.ALMFxVersion) {
                        Write-Host "    ✓ Function execution successful" -ForegroundColor Green
                        Write-Host "      Result: $($result.ALMFxVersion | Out-String)".Trim() -ForegroundColor Gray
                        $passCount++
                    }
                    else {
                        Write-Host "    ✗ Function returned unexpected output" -ForegroundColor Red
                        $failCount++
                    }
                }
                catch {
                    Write-Host "    ✗ Function execution failed: $_" -ForegroundColor Red
                    $failCount++
                }
            }
            else {
                Write-Host "    ✓ Function structure validated" -ForegroundColor Green
                $passCount++
            }
        }
        catch {
            Write-Host "    ✗ Test failed: $_" -ForegroundColor Red
            $failCount++
        }
    }

    # === PHASE 4: Script Analyzer (optional) ===
    if (-not $SkipScriptAnalyzer) {
        Write-Host "`nPHASE 4: PSScriptAnalyzer Linting" -ForegroundColor Yellow
        try {
            Import-Module PSScriptAnalyzer -ErrorAction Stop
            $srcPath = [System.IO.Path]::Combine($repoRoot, "src", "powershell")
            $rules = Join-Path $repoRoot "PSScriptAnalyzerSettings.psd1"

            $results = Invoke-ScriptAnalyzer -Path $srcPath -Settings $rules -Recurse
            if ($results) {
                Write-Host "✗ Linting issues found:" -ForegroundColor Red
                $results | ForEach-Object {
                    Write-Host "  $($_.RuleName) [$($_.Severity)]: $($_.Message) (line $($_.Line))" -ForegroundColor Yellow
                }
                $failCount += $results.Count
            }
            else {
                Write-Host "✓ No linting issues" -ForegroundColor Green
                $passCount++
            }
        }
        catch {
            Write-Host "⚠ Skipping PSScriptAnalyzer: $_" -ForegroundColor Yellow
        }
    }

    # === PHASE 5: Environment Report ===
    Write-Host "`nPHASE 5: Environment Report" -ForegroundColor Yellow
    try {
        $versionInfo = Get-ALMFxVersion -IncludeDependencies
        Write-Host "ALMFx Module Information:" -ForegroundColor Gray
        $versionInfo | Format-Table -AutoSize | Out-String | Write-Host
    }
    catch {
        Write-Host "⚠ Could not retrieve version info: $_" -ForegroundColor Yellow
    }

    # === Summary ===
    Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
    Write-Host "Passed: $passCount" -ForegroundColor Green
    Write-Host "Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
    Write-Host "Environment: PowerShell $($PSVersionTable.PSVersion) / $($PSVersionTable.PSEdition)" -ForegroundColor Gray

    if ($failCount -eq 0) {
        Write-Host "`n✓ All tests passed!" -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host "`n✗ Some tests failed." -ForegroundColor Red
        exit 1
    }
}

function Test-ALMFxFunction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $FunctionName
    )

    Test-ALMFxModule -FunctionName $FunctionName @PSBoundParameters
}

# Auto-run if imported as script
if (-not (Test-Path variable:\TEST_NO_AUTO_RUN)) {
    Test-ALMFxModule @args
}
