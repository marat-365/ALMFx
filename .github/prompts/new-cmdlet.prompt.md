---
mode: agent
description: Scaffold a new public ALMFx PowerShell cmdlet with help and tests.
---
Create a new public function in the ALMFx module.

Ask me for the verb, noun, and what it does if I have not said. Then:

1. Create `src/powershell/ALMFx/Public/<Verb>-ALMFx<Noun>.ps1` with
   `[CmdletBinding()]`, `[OutputType()]`, full comment-based help (synopsis,
   description, every parameter, at least one example), and an optional
   `-Connection` parameter passed through to PnP calls.
   Add `SupportsShouldProcess` if it writes to or removes anything.
2. Add the function name to `FunctionsToExport` in `src/powershell/ALMFx/ALMFx.psd1`.
3. Create `tests/Pester/<Verb>-ALMFx<Noun>.Tests.ps1` (Pester 5) covering the
   happy path, a parameter-validation failure, and the `-WhatIf` path if
   applicable. Mock every PnP/network call — the test must not need a tenant.
4. Add a row to the cmdlet table in `docs/powershell/index.md`.
5. Add a `CHANGELOG.md` entry under `## [Unreleased]` → `### Added`.

Do not invent PnP.PowerShell cmdlets. Verify each one you use.
