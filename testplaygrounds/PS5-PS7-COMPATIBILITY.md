# PowerShell 5.1 & 7+ Compatibility Guide

ALMFx supports both **PowerShell 5.1** (Windows PowerShell) and **PowerShell 7+** (Core).
This guide explains how to write code that works on both versions.

## Quick Reference

| Feature | PS 5.1 | PS 7+ | Notes |
|---------|--------|-------|-------|
| `[CmdletBinding()]` | ✓ | ✓ | Always use for public functions |
| `$PSVersionTable.PSEdition` | ✓ | ✓ | Use for version detection |
| `$PSVersionTable.Platform` | ✗ | ✓ | **Not available on PS 5.1** |
| `$PSNativeCommandArgumentPassing` | ✗ | ✓ | PS 7-only; don't use |
| Classes (`class Foo {}`) | ✓ | ✓ | Available on both |
| `PSCustomObject` | ✓ | ✓ | Preferred for output |
| Pipeline parameters | ✓ | ✓ | `ValueFromPipeline` works on both |

---

## Common APIs: Compatible vs. Incompatible

### ✓ COMPATIBLE — Use Freely

```powershell
# Platform detection
$PSVersionTable.PSVersion           # 5.1.19041.1320, 7.3.0, etc.
$PSVersionTable.PSEdition           # "Desktop" or "Core"
$PSVersionTable.OS                  # "Microsoft Windows 10.0.19044"

# Object construction
[PSCustomObject]@{ Name = "Foo" }
[PSCustomObject]([ordered]@{ A = 1; B = 2 })

# Pipeline and parameters
param(
    [Parameter(ValueFromPipeline)]
    [string] $Name
)

# Array/collection operations
$arr | Where-Object { $_.Status -eq 'Active' }
$arr | ForEach-Object { $_.Id }
$arr | Sort-Object -Property Name

# String operations
$str -replace 'old', 'new'
$str -split ','
@($arr).Count  # Works on both (handles single item correctly)

# Try/catch/finally
try {
    Do-Something
}
catch {
    Write-Error $_
}
finally {
    Cleanup
}

# Hashtables and ordered collections
@{ Name = "test"; Id = 1 }
[ordered]@{ A = 1; B = 2 }
```

### ✗ NOT COMPATIBLE — Avoid or Use Feature Gates

```powershell
# ❌ DON'T: PS7-only path variables
$PSNativeCommandArgumentPassing  # PS 7+ only; don't use

# ❌ DON'T: Platform detection (PS 5.1 always returns nothing)
$PSVersionTable.Platform         # Not available on PS 5.1
if ($PSVersionTable.Platform -eq 'Win32NT') { }  # Fails on PS 5.1

# ✓ DO: Safe platform check
$isWindows = $PSVersionTable.OS -like '*Windows*'

# ❌ DON'T: JSON native types (PS 5.1 has limited support)
ConvertFrom-Json -AsHashtable   # Works PS 5.1, but limited

# ✓ DO: Explicit type conversion
$obj = ConvertFrom-Json -InputObject $jsonString
$obj.Property  # Works on both
```

---

## Feature Gates & Conditional Behavior

When a feature **only works on PS7+**, use explicit version checks:

```powershell
# ✓ CORRECT: Version-aware code
if ($PSVersionTable.PSVersion -ge [Version]'7.0') {
    # PS 7+ specific behavior
    $result = Get-ChildItem -File -Recurse | Group-Object -Property Extension
}
else {
    # PS 5.1 fallback
    $result = Get-ChildItem -File -Recurse | Group-Object -Property Extension
}

# Or simpler: Just use compatible APIs
$result = Get-ChildItem -File -Recurse | 
    Group-Object -Property { [System.IO.Path]::GetExtension($_.FullName) }
```

---

## Error Handling

Both versions support try/catch, but error detail varies:

```powershell
try {
    $result = Get-ALMFxApp
}
catch [System.IO.FileNotFoundException] {
    Write-Error "File not found: $($_.Exception.FileName)" -ErrorAction Stop
}
catch {
    Write-Error "Unexpected error: $_" -ErrorAction Stop
}
```

---

## Logging & Output

Both versions support these output methods:

```powershell
# ✓ Always safe
Write-Host "User message"           # Display (don't use for pipeline data)
Write-Error "Error message"          # Error stream
Write-Warning "Warning message"      # Warning stream
Write-Verbose "Diagnostic info"      # Verbose stream (enable with -Verbose)
Write-Progress "..." -Status "..."   # Progress bar
Write-Output $obj                    # Pipeline output (implicit with `return` too)

# ❌ AVOID (not for pipeline)
[Console]::WriteLine("text")         # Bypasses output stream
Write-Host "Value: $value"           # Not suitable for module output
```

---

## Module Manifest Differences

The module manifest supports both editions:

```powershell
@{
    # Both versions
    RootModule = 'ALMFx.psm1'
    ModuleVersion = '0.1.0'
    CompatiblePSEditions = @('Desktop', 'Core')  # ✓ BOTH
    PowerShellVersion = '5.1'  # Minimum required version
}
```

---

## Testing Across Versions

Before committing, test on both versions:

```powershell
# PowerShell 5.1 (Windows PowerShell)
powershell -NoProfile -Command ". .\testplaygrounds\test-module.ps1; Test-ALMFxModule"

# PowerShell 7+ (Core)
pwsh -NoProfile -Command ". .\testplaygrounds\test-module.ps1; Test-ALMFxModule"

# Both versions (orchestrator)
.\testplaygrounds\run-all-tests.ps1
```

---

## Known Limitations

### PowerShell 5.1 Only
- **No `$PSVersionTable.Platform`:** Use `$PSVersionTable.OS` instead
- **Limited JSON handling:** `ConvertFrom-Json` works, but use explicit type casting
- **No UTF-8 by default:** Specify encoding explicitly (`-Encoding UTF8`)

### PnP.PowerShell Versions
- **PS 5.1:** Use PnP.PowerShell v2.x only (v3 requires PS7+)
- **PS 7+:** Use PnP.PowerShell v3.x

Document this in function help:
```powershell
.NOTES
    Requires PnP.PowerShell:
    - PowerShell 5.1: Install PnP.PowerShell v2.x
    - PowerShell 7.4+: Install PnP.PowerShell v3.x
```

---

## Checklist: Before Publishing

- [ ] `#Requires -Version 5.1` (not 7.4)
- [ ] Manifest: `CompatiblePSEditions = @('Desktop', 'Core')`
- [ ] Manifest: `PowerShellVersion = '5.1'`
- [ ] All functions documented with PS version notes in `.NOTES`
- [ ] Tested on both PS 5.1 and PS 7+ via `run-all-tests.ps1`
- [ ] No PS7-only APIs without feature gates
- [ ] PnP.PowerShell version requirements in help

---

## References

- [PowerShell Compatibility Docs](https://learn.microsoft.com/powershell/scripting/whats-new/compatibility)
- [PSVersion Table Reference](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_automatic_variables#psversiontable)
- [PnP.PowerShell Requirements](https://pnp.github.io/powershell/)
