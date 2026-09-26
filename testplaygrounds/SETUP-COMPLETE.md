# ALMFx: PowerShell 5.1 & 7+ Compatibility Setup

✅ **Complete** — Multi-version support + test playgrounds ready for both PowerShell 5.1 and 7+

---

## What's Been Set Up

### 1. **Module Configuration (Now Dual-Version)**
- **File:** `src/powershell/ALMFx/ALMFx.psd1`
  - `PowerShellVersion = '5.1'` (minimum)
  - `CompatiblePSEditions = @('Desktop', 'Core')` (both PS5.1 and PS7+)
  - Description updated to mention both versions

- **File:** `src/powershell/ALMFx/ALMFx.psm1`
  - `#Requires -Version 5.1` (instead of 7.4)
  - Loads `Shared/` folder first (version-agnostic code)

### 2. **Shared Code Library** (Prevent Duplication)
- **Folder:** `src/powershell/ALMFx/Shared/`
- **File:** `src/powershell/ALMFx/Shared/Compatibility.ps1`

**Functions for cross-version compatibility:**
```powershell
Get-PSVersionInfo              # Safely detect PS version, edition, platform
Test-PSVersionRequirement      # Check minimum version requirement
Invoke-WithFallback            # Execute code with PS-version fallback
ConvertTo-SafeString           # Handle encoding differences
```

**Usage Example:**
```powershell
$psInfo = Get-PSVersionInfo    # Returns: PSVersion, PSEdition, IsPS5, IsPS7Plus
if (Test-PSVersionRequirement -MinimumVersion '7.0') {
    # PS7+ specific code
}
Invoke-WithFallback -PS7PlusScript { ... } -PS5Fallback { ... }
```

### 3. **Test Playgrounds**
- **Folder:** `testplaygrounds/`

#### `test-module.ps1` — Single-Version Testing
- Works on current PowerShell (5.1 or 7+)
- Tests: module load, manifest validation, function execution, linting, help
- Can test specific function: `Test-ALMFxFunction -FunctionName Get-ALMFxVersion`

```powershell
# On current PowerShell
. .\testplaygrounds\test-module.ps1
Test-ALMFxModule -Verbose
```

#### `run-all-tests.ps1` — Multi-Version Orchestration
- Auto-detects PS 5.1 and PS 7+ installations
- Runs full test suite on both versions
- Generates cross-version comparison report
- Outputs CSV for CI integration

```powershell
# Test on all available versions
.\testplaygrounds\run-all-tests.ps1

# Generate report
.\testplaygrounds\run-all-tests.ps1 -OutputReport results.csv
```

#### `README.md` — Usage Guide
- Quick-start commands for both versions
- Best practices before committing
- Environment setup instructions
- Troubleshooting guide

### 4. **Updated Build Script**
- **File:** `build/Invoke-Build.ps1`
- `#Requires -Version 5.1` (now supports both)
- New `-TestOnPS5` switch for cross-version CI
- Can optionally test on PS 5.1 even from PS 7+

```powershell
# Local: test on current version
./build/Invoke-Build.ps1 -Task Analyze, Test

# Cross-version: test on PS5 too (if available)
./build/Invoke-Build.ps1 -Task Test -TestOnPS5
```

### 5. **AGENTS.md Updated**
- PowerShell section clarified for dual-version support
- PnP.PowerShell version guidance (v2 for PS5, v3 for PS7+)

### 6. **Documentation for Developers**
- **`PS5-PS7-COMPATIBILITY.md`** — Quick reference for writing compatible code
  - Safe APIs vs. incompatible ones
  - Feature gates and fallbacks
  - Testing checklist
  
- **`CODEBASE-STRATEGY.md`** — Architecture rationale
  - Single-source approach now
  - Optional future multi-variant strategy
  
- **`FUTURE-MULTI-VARIANT.md`** — Scaling guide
  - When to split into separate `ALMFx-PS5` / `ALMFx-PS7` builds
  - Implementation checklist
  - Shared code reference

### 7. **GitHub Actions Workflow**
- **File:** `.github/workflows/test-multiversion.yml`
- Parallel test matrix: PS 5.1 + PS 7.2/7.3/7.4/latest
- Auto-comments on PRs with compatibility results

---

## How to Use

### Before Writing Code
1. Read: `testplaygrounds/PS5-PS7-COMPATIBILITY.md`
   - Know which APIs are safe
   - Use feature gates for PS7-only features
   - Reference shared helpers in `Shared/Compatibility.ps1`

### Before Committing
```powershell
# Quick test on your current PowerShell
cd [repo]
. .\testplaygrounds\test-module.ps1
Test-ALMFxModule -Verbose
```

### Before Opening a PR
```powershell
# Full cross-version validation
.\testplaygrounds\run-all-tests.ps1

# Or on CI (GitHub Actions runs this automatically)
```

### When Adding a Function
1. Write the function in `Public/Verb-ALMFxNoun.ps1`
2. Use **shared helpers** from `Shared/` for cross-version logic
3. Add feature gates if PS7-specific:
   ```powershell
   if (Test-PSVersionRequirement -MinimumVersion '7.0') {
       # PS7+ code
   }
   else {
       # PS5.1 fallback
   }
   ```
4. Document PowerShell version requirements in `.NOTES`
5. Add test case to `tests/Pester/YourFunction.Tests.ps1`
6. Run tests: `.\testplaygrounds\run-all-tests.ps1`

---

## Current Test Status

### ✅ PowerShell 7.4.4 (Core)
```
Module Load:        ✓ OK (v0.1.0)
Manifest:           ✓ Valid
Functions:          ✓ 1 exported (Get-ALMFxVersion)
Help:               ✓ Present
OutputType:         ✓ Declared
Execution:          ✓ Works
Tests:              ✓ 6/6 passed
```

### 🔄 PowerShell 5.1 (Desktop)
- **Configured & ready** — test playgrounds support it
- Run locally: `powershell .\testplaygrounds\run-all-tests.ps1`
- GitHub Actions matrix will auto-test on Windows

---

## Key Design Decisions

### ✓ Single Source of Truth (For Now)
- One `ALMFx/` module supports both versions
- No code duplication
- Simpler maintenance
- Feature gates via `Shared/Compatibility.ps1`

### ✓ Optional Future Split
- Architecture supports eventual `ALMFx-PS5` / `ALMFx-PS7` split
- See `FUTURE-MULTI-VARIANT.md` for implementation guide
- **No action needed now** — only when codebase warrants it

### ✓ Shared Helpers Pattern
- All cross-version logic in `Shared/` folder
- Public/Private functions use these helpers
- Easy to reason about what works where

---

## Next Steps (Typical Workflow)

1. **Add a new cmdlet:** Use the `new-cmdlet` skill (covers all the checklist)
2. **Verify compatibility:** Run `testplaygrounds\run-all-tests.ps1`
3. **Document version notes:** Add to function `.NOTES`
4. **Commit:** Include `tests/Pester/`, help, docs
5. **PR:** GitHub Actions tests on both versions automatically

---

## Reference Files

| File | Purpose |
|------|---------|
| `src/powershell/ALMFx/Shared/Compatibility.ps1` | Shared cross-version helpers |
| `testplaygrounds/test-module.ps1` | Single-version testing harness |
| `testplaygrounds/run-all-tests.ps1` | Multi-version orchestration |
| `testplaygrounds/README.md` | Playground usage guide |
| `testplaygrounds/PS5-PS7-COMPATIBILITY.md` | Developer quick reference |
| `testplaygrounds/CODEBASE-STRATEGY.md` | Architecture rationale |
| `testplaygrounds/FUTURE-MULTI-VARIANT.md` | Scaling guide |
| `.github/workflows/test-multiversion.yml` | CI test matrix |
| `AGENTS.md` | Updated PowerShell conventions |

---

## Common Questions

**Q: Do I have to write separate code for PS 5 and PS 7?**  
A: No. Use shared helpers and feature gates. Only split if the codebase demands it (unlikely soon).

**Q: How do I test locally without PS 5?**  
A: The test playground gracefully handles missing PowerShell installations. Run what you have.

**Q: What if I only care about PS 7?**  
A: That's fine—just avoid PS7-only APIs without fallbacks. Shared helpers make this automatic.

**Q: When should we split into two modules?**  
A: Only when:
- Significant code duplication exists despite feature gates
- PS7 features genuinely can't be fallback-friendly
- Separate release cadences are needed

See `FUTURE-MULTI-VARIANT.md` for the implementation plan.

---

## Validation Checklist

- [x] Module manifest supports both editions
- [x] Loader sources `Shared/` before `Public/Private`
- [x] Shared helpers created (Compatibility.ps1)
- [x] Sample function (Get-ALMFxVersion) refactored to use helpers
- [x] Test playground for PS 5.1 + PS 7 created
- [x] Build script supports cross-version testing
- [x] GitHub Actions workflow added
- [x] Documentation for developers written
- [x] All PS 7.4 tests passing ✓

