# Quick Reference: Multi-Version PowerShell Development

## Test Locally (Before Committing)

### Current PowerShell Version
```powershell
cd [repo]
. .\testplaygrounds\test-module.ps1
Test-ALMFxModule -Verbose
```

### All Available Versions
```powershell
.\testplaygrounds\run-all-tests.ps1
```

---

## Write Compatible Code

### ✅ Always Safe
```powershell
$PSVersionTable.PSVersion           # Use for version checks
$PSVersionTable.PSEdition           # "Desktop" or "Core"
[PSCustomObject]@{ Name = "test" }  # Object construction
```

### ❌ Avoid (PS7-only)
```powershell
$PSNativeCommandArgumentPassing     # PS7+ only
$PSVersionTable.Platform            # Not on PS 5.1
```

### 🔧 Use Feature Gates
```powershell
if (Test-PSVersionRequirement -MinimumVersion '7.0') {
    # PS 7+ code
} else {
    # PS 5.1 fallback
}

# Or use helper
Invoke-WithFallback -PS7PlusScript { ... } -PS5Fallback { ... }
```

---

## Add a New Function

1. Create `src/powershell/ALMFx/Public/Verb-ALMFxNoun.ps1`
2. Add `[CmdletBinding()]`, `[OutputType()]`, full help
3. Use shared helpers from `Shared/Compatibility.ps1` for cross-version logic
4. Create test: `tests/Pester/Verb-ALMFxNoun.Tests.ps1`
5. Document PS version requirements in `.NOTES`
6. Run: `.\testplaygrounds\run-all-tests.ps1`

---

## Manifest & Build Config

| File | Config | Value |
|------|--------|-------|
| `ALMFx.psd1` | `PowerShellVersion` | `'5.1'` (minimum) |
| `ALMFx.psd1` | `CompatiblePSEditions` | `@('Desktop', 'Core')` |
| `ALMFx.psm1` | `#Requires` | `-Version 5.1` |
| `Invoke-Build.ps1` | `#Requires` | `-Version 5.1` |

---

## Shared Helpers in Shared/Compatibility.ps1

```powershell
Get-PSVersionInfo              # Returns PSVersion, PSEdition, IsPS5, IsPS7Plus, etc.
Test-PSVersionRequirement      # if (Test-PSVersionRequirement -MinimumVersion '7.0')
Invoke-WithFallback            # Conditional execution based on PS version
ConvertTo-SafeString           # Encoding-safe string conversion
```

All functions work on both PS 5.1 and PS 7+.

---

## CI/CD: GitHub Actions

```yaml
# .github/workflows/test-multiversion.yml runs:
- PowerShell 5.1 (Windows PowerShell)
- PowerShell 7.2, 7.3, 7.4, latest (Core)
```

Auto-comments on PRs with results. No manual action needed.

---

## Debugging

**Module won't load?**
```powershell
Import-Module -FullyQualifiedName "A:\path\to\ALMFx" -Verbose
```

**Function says PS version incompatible?**
```powershell
$PSVersionTable.PSVersion       # Check your version
Get-PSVersionInfo               # Use this for diagnostics
```

**Test failures?**
```powershell
.\testplaygrounds\test-module.ps1 -Verbose
```

---

## Docs

| Doc | Read When |
|-----|-----------|
| `SETUP-COMPLETE.md` | Want full overview |
| `PS5-PS7-COMPATIBILITY.md` | Writing code that works on both versions |
| `CODEBASE-STRATEGY.md` | Want to understand architecture |
| `FUTURE-MULTI-VARIANT.md` | Planning to split into separate modules |
| `README.md` | Setting up test playgrounds |

