# Integration Guide: Multi-Version Support Complete ✅

## What's New

The ALMFx module now supports **both PowerShell 5.1 (Desktop) and PowerShell 7+ (Core)** with:
- ✅ Shared codebase (no duplication)
- ✅ Test playgrounds for both versions
- ✅ CI/CD workflow for multi-version validation
- ✅ Developer documentation for cross-version code

---

## For Repository Users

### Installing ALMFx

**PowerShell 5.1 (Windows PowerShell):**
```powershell
Install-Module ALMFx -Scope CurrentUser
Import-Module ALMFx
Get-ALMFxVersion
```

**PowerShell 7+ (Core):**
```pwsh
Install-Module ALMFx -Scope CurrentUser
Import-Module ALMFx
Get-ALMFxVersion
```

**Important:** PnP.PowerShell versions differ:
- PS 5.1 requires: `Install-Module PnP.PowerShell -MinimumVersion 2.0`
- PS 7+ requires: `Install-Module PnP.PowerShell -MinimumVersion 3.0`

See: `testplaygrounds/PS5-PS7-COMPATIBILITY.md`

---

## For Contributors

### Before Making Changes

1. **Understand compatibility rules:**
   ```
   testplaygrounds/PS5-PS7-COMPATIBILITY.md     ← Read this first
   ```

2. **Know the shared helpers:**
   ```powershell
   Get-PSVersionInfo              # Detect version safely
   Test-PSVersionRequirement      # Check minimum PS version
   Invoke-WithFallback            # Version-conditional code
   ```

### When Adding a Function

1. Follow conventions in `AGENTS.md` (PowerShell section)
2. Use shared helpers from `src/powershell/ALMFx/Shared/Compatibility.ps1`
3. Document PS version requirements in `.NOTES`
4. Write tests (mocked, no live tenant)
5. Test locally: `testplaygrounds/run-all-tests.ps1`

### Before Opening a PR

```powershell
cd [repo-root]

# Run full test suite
.\testplaygrounds\run-all-tests.ps1

# Should see:
# [1/2] PowerShell 5.1: PASS (or SKIP if not available)
# [2/2] PowerShell 7+: PASS
```

---

## Files Changed

### Module Core
- `src/powershell/ALMFx/ALMFx.psd1` — Manifest now supports both editions
- `src/powershell/ALMFx/ALMFx.psm1` — Loader now sources `Shared/`
- `src/powershell/ALMFx/Public/Get-ALMFxVersion.ps1` — Refactored to use helpers
- **NEW:** `src/powershell/ALMFx/Shared/Compatibility.ps1` — Shared cross-version code

### Build & Test
- `build/Invoke-Build.ps1` — Now supports both PS versions
- `AGENTS.md` — PowerShell section updated (PS 5.1+, not 7.4+ only)

### Test Playgrounds (NEW)
- `testplaygrounds/README.md` — Usage guide
- `testplaygrounds/test-module.ps1` — Single-version tester
- `testplaygrounds/run-all-tests.ps1` — Multi-version orchestrator
- `testplaygrounds/PS5-PS7-COMPATIBILITY.md` — Developer reference
- `testplaygrounds/CODEBASE-STRATEGY.md` — Architecture rationale
- `testplaygrounds/FUTURE-MULTI-VARIANT.md` — Scaling guide
- `testplaygrounds/SETUP-COMPLETE.md` — This setup summary
- `testplaygrounds/QUICK-REFERENCE.md` — Quick cheat sheet

### CI/CD (NEW)
- `.github/workflows/test-multiversion.yml` — Parallel test matrix

---

## Architecture: Single Source, Scalable

```
src/powershell/ALMFx/
├── Shared/                         ← Version-agnostic helpers
│   └── Compatibility.ps1           ← Get-PSVersionInfo, Test-PSVersionRequirement, etc.
├── Public/                         ← Exported functions
│   └── Get-ALMFxVersion.ps1        ← Uses shared helpers
├── Private/                        ← Internal functions
├── Classes/                        ← Class definitions
├── ALMFx.psm1                      ← Loads Shared/ first, then Classes/Private/Public
└── ALMFx.psd1                      ← PowerShellVersion: 5.1, CompatiblePSEditions: Desktop, Core
```

**Key principle:** If a function needs PS-specific behavior, use feature gates instead of code duplication:

```powershell
# In any Public/ or Private/ function:
if (Test-PSVersionRequirement -MinimumVersion '7.0') {
    # PS 7+ implementation
} else {
    # PS 5.1 fallback (use Shared/ helpers)
}
```

**Future scaling:** If codebase grows to warrant separate builds, create `ALMFx-PS5/` and `ALMFx-PS7/` directories, both referencing `../Shared/`. See: `FUTURE-MULTI-VARIANT.md`

---

## Test Playgrounds: How They Work

### `test-module.ps1` (Single Version)
```powershell
# On your current PowerShell
. .\testplaygrounds\test-module.ps1
Test-ALMFxModule -Verbose

# Or test specific function
Test-ALMFxFunction -FunctionName Get-ALMFxVersion
```

**Checks:**
- Module loads
- Manifest is valid
- Functions exist and are callable
- Help is present
- OutputType is declared
- Core functionality works

### `run-all-tests.ps1` (Multi-Version)
```powershell
# Auto-detects PS 5.1 and PS 7+, runs tests on both
.\testplaygrounds\run-all-tests.ps1

# Generate CSV for CI
.\testplaygrounds\run-all-tests.ps1 -OutputReport results.csv
```

**Orchestrates:**
1. Detects available PowerShell installations
2. Runs full test suite on each
3. Reports pass/fail per version
4. Exports results for CI integration

---

## CI/CD: Automated Multi-Version Testing

**File:** `.github/workflows/test-multiversion.yml`

**On every push to `main` and PR:**
1. Matrix runs tests on PS 5.1 (Windows PowerShell)
2. Matrix runs tests on PS 7.2, 7.3, 7.4, latest (Core)
3. All must pass before merge
4. PR auto-commented with compatibility results

**No manual action needed**—GitHub Actions handles it.

---

## Frequently Asked Questions

**Q: Do I have to support both PowerShell versions?**  
A: Yes. The module is now published to support both. Use `Shared/Compatibility.ps1` to make it easy.

**Q: What if I only use PowerShell 7?**  
A: That's fine. Just don't use PS7-only APIs without feature gates. Shared helpers make this automatic.

**Q: Can I split into separate modules later?**  
A: Yes. See `FUTURE-MULTI-VARIANT.md` for the plan. For now, a single source is simpler.

**Q: How do I test if I only have PS 7?**  
A: Run `test-module.ps1` on your current version. GitHub Actions tests PS 5.1 automatically.

**Q: What PnP.PowerShell version do I need?**  
A: Depends:
- PS 5.1: PnP.PowerShell v2.x
- PS 7+: PnP.PowerShell v3.x

See: `testplaygrounds/PS5-PS7-COMPATIBILITY.md`

**Q: Where do I put PS7-specific code?**  
A: Use a feature gate:
```powershell
if (Test-PSVersionRequirement -MinimumVersion '7.0') {
    # PS7+ feature
} else {
    # PS5.1 fallback or error
}
```

---

## Getting Started

**As a user:**
1. Install from PowerShell Gallery (coming soon)
2. `Import-Module ALMFx`
3. `Get-Command -Module ALMFx`

**As a contributor:**
1. Clone the repo
2. Read: `testplaygrounds/QUICK-REFERENCE.md`
3. Add your function following the checklist
4. Run: `.\testplaygrounds\run-all-tests.ps1`
5. Open PR

---

## Documentation Map

| Document | Read When |
|----------|-----------|
| **README.md** (this file) | You just checked everything out |
| `QUICK-REFERENCE.md` | Want a cheat sheet for common tasks |
| `PS5-PS7-COMPATIBILITY.md` | Writing code—need to know which APIs work where |
| `CODEBASE-STRATEGY.md` | Understanding architecture decisions |
| `FUTURE-MULTI-VARIANT.md` | Planning to split into separate modules |
| `SETUP-COMPLETE.md` | Detailed setup overview and validation |
| `testplaygrounds/README.md` | Using test playgrounds |

---

## Next Steps

1. **Verify everything works locally:**
   ```powershell
   .\testplaygrounds\run-all-tests.ps1
   ```

2. **Add your first PS 5.1-compatible function:**
   - Use `new-cmdlet` skill (handles checklist)
   - Reference `PS5-PS7-COMPATIBILITY.md` for safe APIs
   - Test: `testplaygrounds\run-all-tests.ps1`

3. **Push to GitHub:**
   - CI tests on PS 5.1 + 7.2/7.3/7.4/latest
   - PRs auto-commented with results

---

## Questions or Issues?

- Compatibility question? → `PS5-PS7-COMPATIBILITY.md`
- Test playground question? → `testplaygrounds/README.md`
- Architecture question? → `CODEBASE-STRATEGY.md`
- Build/publish question? → `AGENTS.md` (Commits, PRs & GitHub Permissions section)

---

**Setup Date:** 2026-09-26  
**Version:** ALMFx 0.1.0  
**PowerShell Support:** 5.1+ (Desktop), 7.4+ (Core)  
**Status:** ✅ Ready for development
