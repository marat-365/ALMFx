# Future: Multi-Variant Module Strategy

When the codebase grows, you may want **separate distribution packages** for PS 5.1 and PS 7+ to:
- Optimize for each platform
- Ship PS7-only features in the PS7+ variant
- Reduce binary size for PS5-only deployments
- Have separate CI/test matrices

## Current State (Now)

**Single source of truth:**
- `src/powershell/ALMFx/` — Main module (PS 5.1+)
  - `Shared/` — Version-agnostic code (all functions use this)
  - `Public/`, `Private/`, `Classes/` — Main implementation
  - Feature gates via `Invoke-WithFallback` / `Test-PSVersionRequirement`

**Benefits:**
- One codebase to maintain
- No duplication
- Easier PR reviews
- Common test suite

---

## Future: Two-Variant Architecture (If Needed)

When you decide to split, the structure becomes:

```
src/powershell/
├── Shared/                 ← Shared code (both variants reference this)
│   ├── Compatibility.ps1
│   ├── Core.ps1
│   └── Validation.ps1
│
├── ALMFx-PS5/              ← PowerShell 5.1 variant
│   ├── ALMFx.psd1
│   ├── ALMFx.psm1
│   ├── Public/
│   ├── Private/
│   └── Shared → ../Shared  (symlink or loader reference)
│
└── ALMFx-PS7/              ← PowerShell 7+ variant
    ├── ALMFx.psd1
    ├── ALMFx.psm1
    ├── Public/
    ├── Private/
    └── Shared → ../Shared  (symlink or loader reference)
```

### Build/Publish Strategy

```powershell
# build/Invoke-Build.ps1 detects which variant to build
$variant = if ($env:GITHUB_WORKFLOW -like '*PS5*') {
    'ALMFx-PS5'
} elseif ($env:GITHUB_WORKFLOW -like '*PS7*') {
    'ALMFx-PS7'
} else {
    'ALMFx'  # Default: single-source
}

$modulePath = Join-Path $repoRoot 'src' 'powershell' $variant
```

### CI/CD Changes

```yaml
# .github/workflows/publish.yml
strategy:
  matrix:
    variant: ['PS5', 'PS7']
jobs:
  publish:
    runs-on: windows-latest
    steps:
      - run: ./build/Invoke-Build.ps1 -Variant ${{ matrix.variant }} -Task Stage, Publish
```

### Shared Code Structure

Both variants would load from `../Shared/`:

```powershell
# ALMFx-PS5/ALMFx.psm1
$sharedPath = Join-Path (Split-Path (Split-Path $PSScriptRoot)) 'Shared'
. (Join-Path $sharedPath 'Compatibility.ps1')
. (Join-Path $sharedPath 'Core.ps1')
```

### When to Split

Split only when:
- ✓ PS7+ features can't be feature-gated (e.g., native command argument passing needed everywhere)
- ✓ Significant code duplication exists despite feature gates
- ✓ Separate release cadences are desired
- ✓ Two test matrices are unmanageable in a single run

**Do NOT split just because.**

---

## Implementation Checklist (When Ready)

- [ ] Review `Shared/` folder to ensure no feature-specific code
- [ ] Verify no hard-coded paths that assume `src/powershell/ALMFx`
- [ ] Create `ALMFx-PS5` and `ALMFx-PS7` directories
- [ ] Copy `ALMFx.psm1`/`.psd1` to each variant
- [ ] Update module manifests:
  - `ALMFx-PS5.psd1`: `CompatiblePSEditions = @('Desktop')`; `PowerShellVersion = '5.1'`
  - `ALMFx-PS7.psd1`: `CompatiblePSEditions = @('Core')`; `PowerShellVersion = '7.0'`
- [ ] Create symlinks (or loader references) to `../Shared/`
- [ ] Update build script with variant detection
- [ ] Add GitHub Actions job matrix
- [ ] Test both variants independently
- [ ] Update documentation

---

## Reference: Shared Helpers for Both Variants

Key functions in `Shared/Compatibility.ps1` that support feature gating:

```powershell
# Safely detect version
$psInfo = Get-PSVersionInfo  # Returns: PSVersion, PSEdition, IsPS5, IsPS7Plus, etc.

# Conditional execution
if (Test-PSVersionRequirement -MinimumVersion '7.0') {
    # PS7+ only
}

# Fallback pattern
Invoke-WithFallback `
    -PS7PlusScript { ... } `
    -PS5Fallback { ... }
```

Any new code should use these instead of direct `$PSVersionTable` checks.
