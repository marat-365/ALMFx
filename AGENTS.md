# AGENTS.md — ALMFx

Canonical instructions for every AI coding agent working in this repository (Claude Code, GitHub Copilot, Codex, Cursor, and contributor tooling).
`CLAUDE.md` and `.github/copilot-instructions.md` reference this file as the single source of truth.

## What this repo is

ALMFx is a multi-format toolkit for **SharePoint Framework (SPFx) Application
Lifecycle Management** and **PnP provisioning**. The same domain logic is
delivered in several shapes:

| Shape | Path | Ships as |
|---|---|---|
| PowerShell module | `src/powershell/ALMFx/` | PowerShell Gallery (`ALMFx`) |
| Standalone scripts | `scripts/` | Copy-paste `.ps1`, no install |
| VS Code extensions | `src/vscode/<ext>/` | VS Code Marketplace |
| Agent skills | `plugins/almfx/skills/` | Claude Code plugin marketplace |
| Docs / samples | `docs/`, `samples/` | GitHub Pages (later) |

One repository, several distribution channels. Domain rules live in exactly one
place per concern; the shapes are wrappers over it.

## Golden rules & non-negotiables

1. **Never invent a cmdlet or CLI flag.** PnP.PowerShell, CLI for Microsoft 365,
   and the SPFx toolchain have large, similar-looking surfaces. Verify a
   cmdlet/command exists before using it (`Get-Command -Module PnP.PowerShell`,
   or the vendor docs). See `.claude/skills/pnp-reference/SKILL.md`.
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

| Folder | Audience | Loaded by |
|---|---|---|
| `.claude/skills/` | Agents & contributors working **on** ALMFx | Claude Code / agent harnesses in this repo |
| `plugins/almfx/skills/` | End users doing SPFx ALM **with** ALMFx | `/plugin install almfx@almfx` after `/plugin marketplace add marat-365/ALMFx` |

When asked to "add a skill", determine which audience is meant. Product skills must
not reference this repo's build system, internal paths, or contributor workflow.

## Layout rules

- PowerShell module functions: **one function per file**, `Public/Verb-ALMFxNoun.ps1`
  or `Private/Verb-Noun.ps1`. `ALMFx.psm1` dot-sources them; only `Public/`
  is exported.
- Anything in `scripts/` must run **standalone** (no `Import-Module ALMFx`
  requirement). If a script and a cmdlet share logic, the script may be a thin
  wrapper the build generates — do not hand-maintain two copies of real logic.
- VS Code extensions live in `src/vscode/<extension-name>/`, each with its own
  `package.json`. Shared TypeScript goes in `src/vscode/shared/`.
- Skills shipped to users go in `plugins/almfx/skills/`. Skills for repo
  development go in `.claude/skills/`. Do not mix them.

## Conventions

### PowerShell
- Target **PowerShell 7.4+** (same floor as PnP.PowerShell v3). Do not add
  Windows PowerShell 5.1-only APIs without saying so in the function help.
- Verb must be in `Get-Verb`. Noun is always prefixed `ALMFx` (`Get-ALMFxApp`).
- Every public function requires:
  - `[CmdletBinding()]` (add `SupportsShouldProcess` + `ConfirmImpact='High'` for write/remove)
  - `[OutputType()]`
  - Full comment-based help: `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER` for each parameter, at least one `.EXAMPLE`, `.NOTES`, `.LINK`
  - Optional `-Connection` parameter passed through to PnP calls
- Pipeline-friendly: support `ValueFromPipeline` / `ValueFromPipelineByPropertyName`.
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
- Every `SKILL.md` needs YAML frontmatter with `name` and `description` ("Use when…").
  Keep `SKILL.md` under ~500 lines; push detail into sibling reference files.

## When changing behavior, sweep all shapes

A change to an ALM operation usually needs updates across multiple surfaces:
`PowerShell module cmdlet` → `Standalone script` → `Skill instructions` → `VS Code command` → `Docs` → `CHANGELOG.md`.
Always verify and state which shapes were updated.

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

## Before you say you're done

```powershell
./build/Invoke-Build.ps1 -Task Analyze, Test
```

State honestly what passed and what you skipped.
