# testplaygrounds/README.md
# ALMFx Test Playgrounds

Test and validate the ALMFx module on PowerShell 5.1 and PowerShell 7+ before publishing.

## Quick Start

### PowerShell 7+ (Recommended for Development)
```powershell
# Run all tests on PS 7+
pwsh -NoProfile -ExecutionPolicy Bypass -Command ". .\testplaygrounds\test-module.ps1; Test-ALMFxModule"
```

### PowerShell 5.1 (Windows PowerShell)
```powershell
# Run all tests on Windows PowerShell (PS 5.1)
powershell -NoProfile -ExecutionPolicy Bypass -Command ". .\testplaygrounds\test-module.ps1; Test-ALMFxModule"
```

### Both Versions (CI/Pre-Release Validation)
```powershell
# Requires: pwsh (PowerShell 7+) and Windows PowerShell available
.\testplaygrounds\run-all-tests.ps1
```

---

## Environment Setup

### PS 7+ Environment
1. Install PowerShell 7+ from https://github.com/PowerShell/PowerShell/releases
2. Or via Winget: `winget install Microsoft.PowerShell`

### PS 5.1 Environment
- Built-in to Windows (run `powershell.exe`)
- No additional installation needed
- Limited to Windows

---

## Test Playground Features

### `test-module.ps1`
A standalone testing harness that:
- Loads the ALMFx module from local source
- Verifies module structure and manifest
- Tests each public function
- Reports version compatibility
- Checks PSScriptAnalyzer compliance
- Validates help content
- Works on both PS 5.1 and PS 7+

**Usage:**
```powershell
# Test single function
Test-ALMFxFunction -FunctionName "Get-ALMFxVersion"

# Test all functions
Test-ALMFxModule

# Detailed output
Test-ALMFxModule -Verbose
```

### `run-all-tests.ps1`
Orchestrator script that:
- Detects available PowerShell installations
- Runs test suite on both PS 5.1 and PS 7+
- Generates comparison report
- Validates consistency across versions
- Outputs results in both console and CSV

**Usage:**
```powershell
# Run comprehensive test suite
.\testplaygrounds\run-all-tests.ps1

# Generate CSV report
.\testplaygrounds\run-all-tests.ps1 -OutputReport results.csv
```

---

## Best Practices

1. **Before committing code:**
   ```powershell
   # Quick local test on your current PowerShell
   .\testplaygrounds\test-module.ps1
   ```

2. **Before opening a PR:**
   ```powershell
   # Full multi-version validation
   .\testplaygrounds\run-all-tests.ps1
   ```

3. **After adding a new function:**
   - Add a test case to `test-module.ps1` > `Test-ALMFxFunction`
   - Run both PS versions to verify
   - Check help is consistent: `Get-Help Your-Cmdlet -Full`

---

## Known Limitations & Compatibility Notes

### PowerShell 5.1 (Desktop)
- **Supported:** All SOLID code patterns, PSCustomObject, pipeline operations
- **Limited:** Some newer APIs (e.g., `$PSNativeCommandArgumentPassing`)
- **PnP.PowerShell:** Only v2.x; users must not upgrade to v3 on PS5

### PowerShell 7+ (Core)
- **Full compatibility:** All ALMFx features designed for PS 7.4+
- **PnP.PowerShell:** v3.x required
- **Cross-platform:** Linux and macOS supported (for testing)

### Writing Compatible Code

**Avoid (PS7-only):**
```powershell
# ❌ Don't use these on PS 5.1
$PSNativeCommandArgumentPassing
$PSEdition -eq 'Core'  # Platform-specific APIs
```

**Use Instead (Compatible):**
```powershell
# ✅ Compatible with both
$PSVersionTable.PSEdition  # Works on both
$PSVersionTable.Platform   # Works on both
```

---

## Troubleshooting

### Module Won't Load
```powershell
# Check module source path
$modulePath = "A:\...\src\powershell\ALMFx"
Test-Path -Path $modulePath
Import-Module -Path $modulePath -Force -Verbose
```

### Pester Tests Failing
```powershell
# Install/update Pester 5
Install-Module Pester -MinimumVersion 5.0 -Scope CurrentUser -Force
```

### PSScriptAnalyzer Issues
```powershell
# Install latest analyzer
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
```

---

## CI Integration

For GitHub Actions, the test playgrounds enable:
- Parallel PS 5 and PS 7 test matrices
- Pre-publish validation
- Cross-version compatibility reporting
- Automatic regression detection

See `.github/workflows/` for integration examples.

