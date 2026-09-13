---
name: new-cmdlet
description: Use when adding, renaming, or removing a public function in the ALMFx PowerShell module. Walks the full checklist - function file, manifest export, Pester test, docs row, changelog - so nothing is half-added. Trigger on "add a cmdlet", "new function", "expose X in the module".
---

# Adding a public ALMFx function

A function is not "added" until all five of these are done. Half-added
functions (exported but untested, or written but not in `FunctionsToExport`)
are the main source of breakage here.

## Checklist

1. **Function file** — `src/powershell/ALMFx/Public/<Verb>-ALMFx<Noun>.ps1`
   - Verb from `Get-Verb`. Noun singular, prefixed `ALMFx`.
   - Start from `build/templates/Function.ps1.txt`.
   - `[CmdletBinding()]`; add `SupportsShouldProcess, ConfirmImpact='High'` if it
     writes to, removes from, or overwrites anything in a tenant.
   - `[OutputType()]`, full comment-based help, at least one `.EXAMPLE`.
   - Optional `-Connection` parameter threaded to every PnP call.
   - Objects out. `Write-Verbose` for diagnostics, never `Write-Host`.
2. **Manifest** — add the name to `FunctionsToExport` in `ALMFx.psd1`.
   The module contract test fails if you forget.
3. **Test** — `tests/Pester/<Verb>-ALMFx<Noun>.Tests.ps1`, Pester 5.
   Cover: happy path, a validation failure, and `-WhatIf` if applicable.
   **Mock every PnP and network call.** CI has no tenant.
4. **Docs** — a row in the cmdlet table in `docs/powershell/index.md`.
5. **Changelog** — `## [Unreleased]` → `### Added`.

## Cross-shape sweep

Ask whether the same operation should also exist as:
- a standalone script in `scripts/` (for people who cannot install the module)
- a VS Code command in `src/vscode/`
- a step in a product skill in `plugins/almfx/skills/`

You do not have to build all of them, but say which ones you skipped.

## Before reporting done

```powershell
./build/Invoke-Build.ps1 -Task Analyze, Test
```

Use `.claude/skills/pnp-reference/` to verify every PnP cmdlet and parameter you
used. Do not guess.
