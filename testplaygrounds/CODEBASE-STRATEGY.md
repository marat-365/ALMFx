# Architecture: Shared Codebase with Optional PS-Version Variants

## Current Structure (Single Module)
```
src/powershell/ALMFx/           ← Module root (PS 5.1+)
├── Public/                     ← Exported functions (works on both)
├── Private/                    ← Internal helpers (works on both)
├── Classes/                    ← Class definitions (works on both)
├── Shared/                     ← NEW: Common logic (no PS-specific code)
│   ├── Core.ps1               ← Shared helpers, utilities
│   ├── Validation.ps1         ← Input validation
│   └── Formatting.ps1         ← Output formatting
├── ALMFx.psm1                 ← Module loader (detects PS version)
└── ALMFx.psd1                 ← Manifest (CompatiblePSEditions: Desktop, Core)
```

## Strategy: No Duplication

1. **Core Logic:** Lives in `Shared/` (language version-agnostic)
2. **Version Adapters:** If a function needs PS-specific behavior, use feature gates:
   ```powershell
   if ($PSVersionTable.PSVersion -ge [Version]'7.0') {
       # PS7+ implementation
   } else {
       # PS5.1 fallback
   }
   ```
3. **Future Scaling:** If truly separate builds become needed:
   - `src/powershell/ALMFx-PS5/` (Windows PowerShell only)
   - `src/powershell/ALMFx-PS7/` (Core only)
   - Both reference `src/powershell/Shared/` folder
   - Build step selects which variant to publish

## Immediate Implementation

Starting with **single-source** approach (simplest):
- ALMFx.psm1 loader detects PS version at import time
- All logic in Public/, Private/, Shared/
- Feature gates for PS-specific APIs
- This supports the "eventually separate sources" goal without refactoring

