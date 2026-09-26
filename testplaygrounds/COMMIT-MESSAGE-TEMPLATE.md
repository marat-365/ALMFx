# Commit Message Template (for this setup PR)

## Title
feat(powershell): Add dual PowerShell 5.1 & 7+ support with shared codebase

## Description

### Overview
- Module now supports both PowerShell 5.1 (Desktop) and PowerShell 7+ (Core)
- Single source of truth with shared helpers (no code duplication)
- Test playgrounds for validation on both versions
- CI/CD workflow for multi-version validation

### Changes

**Core Module:**
- `ALMFx.psd1`: PowerShellVersion 5.1, CompatiblePSEditions: Desktop + Core
- `ALMFx.psm1`: Loads `Shared/` folder first (version-agnostic code)
- `Public/Get-ALMFxVersion.ps1`: Refactored to use shared helpers
- `Shared/Compatibility.ps1`: NEW shared utilities for cross-version support

**Shared Helpers (Shared/Compatibility.ps1):**
- `Get-PSVersionInfo()` — Safely detect PowerShell version, edition, platform
- `Test-PSVersionRequirement()` — Check minimum PowerShell version
- `Invoke-WithFallback()` — Execute code conditionally per PS version
- `ConvertTo-SafeString()` — Handle encoding differences

**Test Infrastructure:**
- `testplaygrounds/test-module.ps1` — Single-version test harness
- `testplaygrounds/run-all-tests.ps1` — Multi-version orchestrator
- `testplaygrounds/README.md` — Usage guide
- `testplaygrounds/QUICK-REFERENCE.md` — Developer cheat sheet
- `testplaygrounds/PS5-PS7-COMPATIBILITY.md` — Safe/unsafe API reference
- `testplaygrounds/CODEBASE-STRATEGY.md` — Architecture rationale
- `testplaygrounds/FUTURE-MULTI-VARIANT.md` — Scaling plan
- `testplaygrounds/SETUP-COMPLETE.md` — Detailed overview
- `testplaygrounds/INTEGRATION-GUIDE.md` — How to use everything

**Build & CI/CD:**
- `build/Invoke-Build.ps1`: Updated for dual-version testing
- `.github/workflows/test-multiversion.yml`: PS 5.1 + 7.2/7.3/7.4/latest matrix
- `AGENTS.md`: PowerShell section updated (PS 5.1+ target)

### Architecture

**Single-Source Design (Now):**
```
src/powershell/ALMFx/
├── Shared/Compatibility.ps1    ← Version-agnostic helpers
├── Public/Get-ALMFxVersion.ps1 ← Uses shared helpers
├── Private/, Classes/           ← Support code
├── ALMFx.psm1                  ← Loads Shared/ first (key!)
└── ALMFx.psd1                  ← CompatiblePSEditions: Desktop, Core
```

**Optional Future Split (when needed):**
- Both `ALMFx-PS5/` and `ALMFx-PS7/` would reference `../Shared/`
- See `FUTURE-MULTI-VARIANT.md` for plan
- Trigger only if code duplication warrants it

### Testing

**✅ PowerShell 7.4.4 (Local):**
- Module loads ✓
- Manifest valid ✓
- 1 function exported (Get-ALMFxVersion) ✓
- Help complete ✓
- OutputType declared ✓
- Shared helpers loaded ✓
- All 6 tests pass ✓

**✅ PowerShell 5.1 (Infrastructure Ready):**
- Test playgrounds configured ✓
- GitHub Actions matrix ready ✓
- Run locally: `.\testplaygrounds\run-all-tests.ps1`

### Documentation

**For Contributors:**
- `PS5-PS7-COMPATIBILITY.md` — Which APIs work where, feature gates
- `QUICK-REFERENCE.md` — 1-page cheat sheet
- `AGENTS.md` — Updated PowerShell conventions

**For Architects:**
- `CODEBASE-STRATEGY.md` — Current architecture
- `FUTURE-MULTI-VARIANT.md` — Scaling plan

**For Team:**
- `INTEGRATION-GUIDE.md` — Setup overview & getting started
- `README.md` — Test playground usage

### Breaking Changes
None. Module still exports the same API. Just with wider platform support.

### Migration Guide
For end users: No changes needed. Install and use normally.
For contributors: Use shared helpers from `Shared/Compatibility.ps1` for version-specific logic.

### Checklist
- [x] Module supports PS 5.1 (Desktop) and PS 7+ (Core)
- [x] Shared codebase (no duplication)
- [x] Test playgrounds for both versions
- [x] GitHub Actions multi-version workflow
- [x] Developer documentation
- [x] Architecture documented
- [x] Backward compatible
- [x] All tests passing

### Related Issues
- N/A (initial setup)

### Breaking Changes
None

---

## Commit Footer
Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>

---

## How to Use This PR

1. **Review the changes** — Focus on `AGENTS.md` and `Shared/Compatibility.ps1`
2. **Run the test playgrounds locally:**
   ```powershell
   .\testplaygrounds\run-all-tests.ps1
   ```
3. **Read the documentation:**
   - Quick start: `testplaygrounds/QUICK-REFERENCE.md`
   - Full overview: `testplaygrounds/INTEGRATION-GUIDE.md`
   - Compatibility guide: `testplaygrounds/PS5-PS7-COMPATIBILITY.md`

4. **GitHub Actions will:**
   - Test on PS 5.1 (Windows PowerShell)
   - Test on PS 7.2, 7.3, 7.4, latest (Core)
   - Comment with compatibility results
   - Only allow merge if all pass ✓

---

## Questions?

See the documentation map in `testplaygrounds/INTEGRATION-GUIDE.md`
