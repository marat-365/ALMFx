# Contributing to ALMFx

Thanks for helping out. This repo ships one domain — SPFx application lifecycle
management — in several formats, so please read `AGENTS.md` before your first
change: it is the canonical rule set for both humans and AI assistants.

## Layout

See [`docs/repo-structure.md`](docs/repo-structure.md).

## Prerequisites

- PowerShell **7.4+**
- `PnP.PowerShell` 3.x, `Pester` 5.x, `PSScriptAnalyzer` (`./build/Install-Dependencies.ps1`)
- Node.js LTS (only if you touch `src/vscode/`)
- A Microsoft 365 **developer** tenant for manual testing. Never test against
  production, and never commit anything from a real tenant.

## Workflow

```powershell
git checkout -b feat/short-description
# ... change things ...
./build/Invoke-Build.ps1 -Task Analyze, Test
git commit -m "feat(powershell): add Get-ALMFxAppCatalog"
```

- **Conventional Commits.** Scopes: `powershell`, `scripts`, `vscode`, `skills`,
  `docs`, `build`, `repo`.
- Update `CHANGELOG.md` under `## [Unreleased]` for anything user-visible.
- Do not bump versions in a feature PR; releases do that.

## Tests

Pester 5, in `tests/Pester/`. **Every** network and PnP call must be mocked —
CI has no tenant and neither should your test.

## Using AI assistants

Encouraged, and the repo is set up for it (`AGENTS.md`, `CLAUDE.md`,
`.github/copilot-instructions.md`, `.github/instructions/`, `.claude/skills/`).
You are still the author: verify every cmdlet an assistant suggests actually
exists, and never merge tenant-mutating code you have not read.

## Licence

By contributing you agree your contribution is licensed under the MIT Licence
(see [`LICENSE`](LICENSE)).
