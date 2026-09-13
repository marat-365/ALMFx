# AGENTS.md — ALMFx

Canonical instructions for every AI coding agent working in this repository.
`CLAUDE.md` imports this file; `.github/copilot-instructions.md` points at it.
**Edit this file first** — the others are thin wrappers.

## What this repo is

ALMFx is a multi-format toolkit for **SharePoint Framework (SPFx) Application
Lifecycle Management** and **PnP provisioning**. The same domain logic is
delivered in several shapes:

| Shape | Path | Ships as | State today |
|---|---|---|---|
| PowerShell module | `src/powershell/ALMFx/` | PowerShell Gallery (`ALMFx`) | Skeleton — loader, manifest, one placeholder function |
| VS Code extension | `src/vscode/almfx/` | VS Code Marketplace | Scaffold — activation and one placeholder command |
| Standalone scripts | `scripts/` | Copy-paste `.ps1`, no install | Nothing yet |
| Agent skills | `plugins/almfx/skills/` | Claude Code plugin marketplace | **Deliberately empty** |
| Docs / samples | `docs/`, `samples/` | GitHub Pages (later) | Reference docs written |

One repository, several distribution channels. Domain rules live in exactly one
place per concern; the shapes are wrappers over it.

**That one place is [`docs/reference/spfx-alm/`](docs/reference/spfx-alm/).**
Before writing any fact about SPFx, PnP, or app catalogs into a function's help,
a skill, extension copy, or a README — check whether it belongs in the reference
instead, and link to it. Cmdlet names, `--ship`, version-bump rules, and the
shared-service-principal problem live in
[`docs/reference/spfx-alm/cmdlets.md`](docs/reference/spfx-alm/cmdlets.md) and
nowhere else.

Nothing ships in `plugins/almfx/skills/` until ALMFx has a surface worth driving.
A skill that only restates general PnP knowledge would ship a plugin that never
mentions the product it is named after — that knowledge belongs in the reference
docs. See `plugins/almfx/skills/README.md`.

## Golden rules

1. **Never invent a cmdlet.** PnP.PowerShell, CLI for Microsoft 365 and the SPFx
   toolchain have large, similar-looking surfaces. Verify a cmdlet/command
   exists before using it (`Get-Command -Module PnP.PowerShell`, or the vendor
   docs). Method and verified list:
   [`docs/reference/spfx-alm/cmdlets.md`](docs/reference/spfx-alm/cmdlets.md).
2. **Never run destructive tenant operations unprompted.** Anything that
   removes, retracts, unpublishes, overwrites a template, or touches a
   production app catalog must be behind `-WhatIf`/`-Confirm` (PowerShell
   `SupportsShouldProcess`) or an explicit confirmation prompt.
3. **No secrets, tenant names, or site URLs in committed code**, including
   tests and sample output. Use placeholders: `contoso`, `https://contoso.sharepoint.com`.
4. **Read-only by default.** New functionality starts as `Get-*` / report /
   dry-run, then gains a write path.
5. **Attribute borrowed code.** If logic comes from PnP or sp-dev samples, note
   it in the file header and in `THIRD-PARTY-NOTICES.md` (both are MIT — see
   `docs/licensing.md`).

## Layout rules

- PowerShell module functions: **one function per file**, `Public/Verb-ALMFxNoun.ps1`
  or `Private/Verb-Noun.ps1`. `ALMFx.psm1` dot-sources them; only `Public/`
  is exported.
- Anything in `scripts/` must run **standalone** (no `Import-Module ALMFx`
  requirement). If a script and a cmdlet share logic, the script may be a thin
  wrapper the build generates — do not hand-maintain two copies of real logic.
- The VS Code extension lives in `src/vscode/almfx/` with its own `package.json`
  and version stream. If a second extension is ever added, shared TypeScript
  goes in `src/vscode/shared/` — see
  [ADR 0001](docs/adr/0001-record-architecture-decisions.md).
- Skills shipped to users go in `plugins/almfx/skills/` (empty today). Skills
  that help agents work **on this repo** go in `.claude/skills/`. Do not mix
  them, and do not put domain knowledge in either — that goes in
  `docs/reference/spfx-alm/`.

## Conventions

### PowerShell
- Target **PowerShell 7.4+** (same floor as PnP.PowerShell v3). Do not add
  Windows PowerShell 5.1-only APIs without saying so in the function help.
- Verb must be in `Get-Verb`. Noun is always prefixed `ALMFx` (`Get-ALMFxApp`).
- Every public function: `[CmdletBinding()]`, comment-based help with
  `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, at least one `.EXAMPLE`, and
  `[OutputType()]`.
- Emit objects, never `Write-Host`. Progress → `Write-Progress`; diagnostics →
  `Write-Verbose`.
- Must pass `PSScriptAnalyzer` with the repo's `PSScriptAnalyzerSettings.psd1`.
- Tests are Pester 5, in `tests/Pester/<FunctionName>.Tests.ps1`. Mock all
  network/PnP calls — **no test may touch a real tenant.**

### TypeScript / VS Code
- Strict mode on. No `any` without a comment justifying it.
- Extension activation must be lazy (`onCommand:`/`onLanguage:`), never `*`.
- Long-running tenant work goes through `withProgress` and must be cancellable.

### Markdown / skills
- Every `SKILL.md` needs YAML frontmatter with `name` and `description`.
  The `description` is what triggers the skill — write it as "Use when…".
- Keep a `SKILL.md` under ~500 lines; push detail into sibling reference files.

## Commits & PRs

- Conventional Commits: `feat(powershell): …`, `fix(vscode): …`,
  `docs(skills): …`, `chore(build): …`.
- Scopes: `powershell`, `scripts`, `vscode`, `skills`, `docs`, `build`, `repo`.
- Update `CHANGELOG.md` (Keep a Changelog format) for anything user-visible.
- Do not bump the module version in a feature PR — releases do that (see
  `.claude/skills/module-release/`).

## Before you say you're done

```powershell
./build/Invoke-Build.ps1 -Task Analyze, Test
```

State honestly what passed and what you skipped.
