# AGENTS.md — ALMFx

Canonical instructions for every AI coding agent working in this repository
(Claude Code, GitHub Copilot, Codex, Cursor, and contributor tooling).
`CLAUDE.md` and `.github/copilot-instructions.md` reference this file as the
single source of truth. **Edit this file first** — the others are thin
wrappers.

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

## Golden rules & non-negotiables

1. **Never invent a cmdlet or CLI flag.** PnP.PowerShell, CLI for Microsoft 365,
   and the SPFx toolchain have large, similar-looking surfaces. Verify a
   cmdlet/command exists before using it (`Get-Command -Module PnP.PowerShell`,
   or the vendor docs). Method and verified list:
   [`docs/reference/spfx-alm/cmdlets.md`](docs/reference/spfx-alm/cmdlets.md)
   (`.claude/skills/pnp-reference/SKILL.md` points at it).
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
6. **No live tenant in CI or sandbox.** Mock all network/PnP calls in tests —
   never write a test or verification step that requires an active tenant.

## Skills in this repo — two distinct audiences

| Folder | Audience | Loaded by | State |
|---|---|---|---|
| `.claude/skills/` | Agents & contributors working **on** ALMFx | Claude Code / agent harnesses in this repo | 5 skills |
| `plugins/almfx/skills/` | End users doing SPFx ALM **with** ALMFx | `/plugin install almfx@almfx` after `/plugin marketplace add marat-365/ALMFx` | **Empty on purpose** |

When asked to "add a skill", determine which audience is meant — and first ask
whether it is a skill at all. A fact about SPFx or PnP (rather than a procedure
for using something) belongs in `docs/reference/spfx-alm/`, not a skill; both
skill folders should link to it. Product skills must not reference this
repo's build system, internal paths, or contributor workflow —
`tests/Pester/Repository.Tests.ps1` enforces that.

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
- Target **PowerShell 5.1+ and 7.4+** (Desktop and Core), deliberately. This is
  a product decision, not an oversight: many SharePoint/M365 admins are on
  Windows PowerShell 5.1 by default and cannot install PS 7 on locked-down
  workstations. `Get-ALMFxVersion` and other non-PnP-dependent functions must
  work there. PnP.PowerShell v3 itself still requires PS 7.4+ — functions that
  call it are unavoidably PS 7-only, and must say so in `.NOTES`. Shared
  cross-version logic goes in `Shared/` (see `Compatibility.ps1`); do not add a
  PS7-only API to a function that is supposed to run on 5.1 without a
  documented fallback or an explicit `.NOTES` limitation.
- Verb must be in `Get-Verb`. Noun is always prefixed `ALMFx` (`Get-ALMFxApp`), with
  one deliberate exception: `New-SPFxEnvironment`/`Set-SPFxEnvironment` are
  prefixed `SPFx`, not `ALMFx` - they operate on a generic SPFx solution's own
  environment concept, not something specific to the ALMFx toolkit, and the
  `SPFx` prefix names that accurately. Do not "fix" this back to
  `ALMFxEnvironment` in review; do not add a third prefix for a future
  function without discussing it first.
- Every public function requires:
  - `[CmdletBinding()]` (add `SupportsShouldProcess` + `ConfirmImpact='High'` for write/remove)
  - `[OutputType()]`
  - Full comment-based help: `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER` for each parameter, at least one `.EXAMPLE`, `.NOTES` (include PS version notes), `.LINK`
  - Optional `-Connection` parameter passed through to PnP calls
- Pipeline-friendly: support `ValueFromPipeline` / `ValueFromPipelineByPropertyName`
  where it makes sense.
- Emit objects (`[PSCustomObject]` or classes), never `Write-Host`. Progress → `Write-Progress`; diagnostics → `Write-Verbose`.
- Must pass `PSScriptAnalyzer` with `./PSScriptAnalyzerSettings.psd1`.
- Tests are Pester 5, in `tests/Pester/<FunctionName>.Tests.ps1`. Mock all network/PnP calls.

### TypeScript / VS Code
- Strict mode on. No `any` without a comment justifying it.
- Extension activation must be lazy (`onCommand:`/`onLanguage:`), never `*`.
- Long-running tenant work goes through `withProgress` and must be cancellable.

### Documentation & Markdown
- Windows-first examples for users (elevated PowerShell 7 syntax), cross-platform scripts.
- Placeholders are always `contoso`: `https://contoso.sharepoint.com`.
- Every code fence is tagged (```powershell, ```json, ```bash, etc.).
- Every `SKILL.md` needs YAML frontmatter with `name` and `description`
  ("Use when…", "Use before…", or "Use after…" — an anticipatory skill has a
  genuinely different trigger shape from a reactive one).
  Keep `SKILL.md` under ~500 lines; push detail into sibling reference files.

## When changing behavior, sweep all shapes

A change to an ALM operation usually needs updates across multiple surfaces:
`PowerShell module cmdlet` → `Standalone script` → `Skill instructions` →
`VS Code command` → `Docs` → `CHANGELOG.md`.
Check each before reporting completion; state explicitly which shapes were
updated and which were deliberately skipped.

## Commits, PRs & GitHub Permissions

### Commits & Changelog
- Conventional Commits: `feat(powershell): …`, `fix(vscode): …`, `docs(skills): …`, `chore(build): …`.
- Scopes: `powershell`, `scripts`, `vscode`, `skills`, `docs`, `build`, `repo`.
- Update `CHANGELOG.md` (Keep a Changelog format) for anything user-visible.
- Do not bump the module version in a feature PR — releases do that (see `.claude/skills/module-release/`).

### Permissions required to create & manage Pull Requests

When creating pull requests via agents, GitHub Actions, or CLI:

1. **GitHub Actions (`GITHUB_TOKEN`)**:
   - Workflow permissions in YAML:
     ```yaml
     permissions:
       contents: write       # Push branch / commits
       pull-requests: write  # Create and update pull requests
     ```
   - Repository setting: **Settings → Actions → General → Workflow permissions**:
     - Enable: *"Read and write permissions"*
     - Check: *"Allow GitHub Actions to create and approve pull requests"*
2. **GitHub CLI / Personal Access Tokens (PAT)**:
   - **Fine-grained PAT**: `Contents: Read and write`, `Pull requests: Read and write`, `Metadata: Read-only` (plus `Workflows: Read and write` if modifying `.github/workflows/`).
   - **Classic PAT**: `repo` scope (or `public_repo` for public repos) plus `workflow` scope if modifying workflow files.
3. **Branch Protection & Rulesets**:
   - Feature branches must not violate branch protection rules on target (`main`).
   - Worktree / Agent sessions push to dedicated feature branches and open PRs targeting `main`.
4. **A job whose result gates a required check must declare its own `permissions:`.**
   A default (often read-only) `GITHUB_TOKEN` causes ancillary steps (e.g.
   posting a PR comment) to fail with `403 Resource not accessible by
   integration`, which fails the whole job — including a passing gate. See
   `.github/workflows/test-multiversion.yml`'s `cross-version-report` job.

## Before you say you're done

```powershell
./build/Invoke-Build.ps1 -Task Analyze, Test
```

State honestly what passed and what you skipped.
