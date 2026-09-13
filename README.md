# ALMFx

**Application Lifecycle Management toolkit for SharePoint Framework (SPFx) and
PnP provisioning** — the same operations delivered as PowerShell, VS Code, and
AI agent skills.

> Status: early scaffolding. Nothing is published yet.

## What you can install

| Format | What it is | Status |
|---|---|---|
| **PowerShell module** `ALMFx` | Cmdlets for app catalog, package deployment, app upgrade, tenant inventory | Planned |
| **Standalone scripts** | Single-file `.ps1` for people who cannot install modules | Planned |
| **VS Code extension** | SPFx ALM operations from the editor | Planned |
| **VS Code extension** | PnP provisioning template authoring | Planned (may merge with the above) |
| **Agent skills** | Claude Code plugin that drives the module and knows the domain | Planned |

## Quick start

```powershell
# PowerShell 7.4+
Install-Module ALMFx -Scope CurrentUser      # once published
Import-Module ALMFx
Get-Command -Module ALMFx
```

```
# Claude Code — once published
/plugin marketplace add marat-365/ALMFx
/plugin install almfx@almfx
```

## Repository layout

```
src/powershell/ALMFx/   PowerShell module (one function per file)
src/vscode/             VS Code extensions + shared TypeScript
scripts/                Standalone .ps1 — no install required
plugins/almfx/skills/   Skills shipped to users
.claude/skills/         Skills for agents working ON this repo
tests/Pester/           Pester 5 tests (all network calls mocked)
build/                  Build, analyze, test, publish
docs/                   Documentation
samples/                Example templates and configurations
```

Full detail: [`docs/repo-structure.md`](docs/repo-structure.md).

## Working with AI assistants

This repo is configured for Claude Code, GitHub Copilot, and any agent that
reads `AGENTS.md`:

- [`AGENTS.md`](AGENTS.md) — canonical rules, **edit this one**
- [`CLAUDE.md`](CLAUDE.md) — imports `AGENTS.md`, adds Claude-specific notes
- [`.github/copilot-instructions.md`](.github/copilot-instructions.md) — Copilot Chat & code review
- [`.github/instructions/`](.github/instructions/) — path-scoped rules (`applyTo`)
- [`.github/prompts/`](.github/prompts/) — reusable Copilot prompt files
- [`.claude/skills/`](.claude/skills/) — repo-development skills

## Requirements

- PowerShell 7.4+ (matching PnP.PowerShell v3)
- PnP.PowerShell 3.x
- SharePoint Administrator or site collection App Catalog rights, depending on
  the operation

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Licence

MIT — see [`LICENSE`](LICENSE) and [`docs/licensing.md`](docs/licensing.md) for
why, and how it lines up with PnP and the SPFx community projects.
