# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Each shipped format (PowerShell module, VS Code extension, skills plugin)
is versioned independently; entries note which one they affect.

## [Unreleased]

### Added
- `New-ALMFxEnvironment` and `Set-ALMFxEnvironment` — build and deploy a
  per-environment copy of an SPFx solution's SharePoint-facing json/xml
  files. `New-ALMFxEnvironment` discovers solution/feature/component identity
  from `config/package-solution.json` and every `src/**/*.manifest.json`,
  scans the whole solution (not a fixed file list — real solutions echo a
  component's GUID in places like `config/serve.json`) for every file that
  references a known id or alias, and copies matches into
  `.<environment>/`, mirroring relative paths. With `-CreateUniqueNames`
  (default `$true` unless `-Environment` is `prod`/`production`) every known
  id becomes a fresh GUID and every alias gets an `_<environment>` suffix,
  rewritten consistently everywhere it's echoed; fixed Microsoft system GUIDs
  (e.g. a web part gallery category id) and GUIDs embedded in generated
  comments are left untouched. Safe to re-run: a persisted map at
  `.almfx/environments/<environment>.map.json` keeps every previously
  assigned id/name stable and only generates one for a newly added
  component; a removed component is pruned from both the map and the
  `.<environment>/` folder. `Set-ALMFxEnvironment` deploys a built
  `.<environment>/` folder's files into the solution. Both are pure
  filesystem/text operations — no PnP dependency, no tenant connection.
- Repository structure, agent instruction files (`AGENTS.md`, `CLAUDE.md`,
  `.github/copilot-instructions.md`, path-scoped Copilot instructions).
- PowerShell module skeleton (`ALMFx`) with build and test harness.
- Unified agent instructions in `AGENTS.md` and added a GitHub PR / Actions
  permissions guide (workflow token scopes, PAT scopes, branch protection).
- PowerShell 5.1 (Desktop) support alongside 7.4+ (Core), deliberately — see
  AGENTS.md's PowerShell conventions and ADR 0001. Shared cross-version helpers
  in `src/powershell/ALMFx/Shared/Compatibility.ps1`. CI matrix
  (`test-multiversion.yml`) runs both.
- `testplaygrounds/` — a real, generator-built, buildable SPFx solution fixture
  (`spfx-sample-app`, one of every component type: web part, three extension
  types, a library, an Adaptive Card Extension) plus a standalone test harness,
  for validating ALM operations offline without a tenant.
- VS Code extension scaffold (`src/vscode/almfx`) — activation, one
  placeholder command (`ALMFx: Show Version`), output channel, settings. No ALM
  functionality yet. CI (`ci-vscode.yml`) compiles, lints, and fails the build
  on a wildcard `activationEvents` entry.
- `docs/reference/spfx-alm/` — SPFx ALM and PnP provisioning domain knowledge as
  the repository's single source of truth (cmdlets, deployment, upgrade,
  inventory, API permissions, troubleshooting, provisioning, CI/CD). Every
  cmdlet checked against the PnP documentation source, dated 2026-09-13.
- `docs/adr/0002-code-signing.md` — open decision, must be settled before the
  first PowerShell Gallery publish. PnP.PowerShell signs every release; ALMFx's
  script-module shape (`.ps1`/`.psm1`/`.psd1`, all Authenticode-checked) is more
  exposed to `AllSigned` execution policy than a binary module would be.
- `tests/Pester/Repository.Tests.ps1` — validates skill frontmatter, plugin
  manifest paths, the cmdlet docs table, the reference doc tree, the VS Code
  extension's activation events, and guards against real tenant URLs or key
  material being committed.
- `.gitattributes` and `.editorconfig`.

### Changed
- `plugins/almfx/skills/` emptied back out. The initial seven skills restated
  general PnP/SPFx knowledge without using anything ALMFx actually does; that
  knowledge moved to `docs/reference/spfx-alm/` instead. Skills ship again once
  ALMFx has cmdlets or extension commands worth writing one around — see
  `plugins/almfx/skills/README.md`.
- Two planned VS Code extensions (`almfx-spfx-alm`, `almfx-provisioning`)
  collapsed into one (`src/vscode/almfx`). Nothing was published, so this cost
  nothing; splitting again later, with an ADR, remains available.
- Consolidated 10 overlapping `testplaygrounds/` docs (`INDEX.md`, `START-HERE.md`,
  `SETUP-COMPLETE.md`, `INTEGRATION-GUIDE.md`, `QUICK-REFERENCE.md`,
  `CODEBASE-STRATEGY.md`, `COMMIT-MESSAGE-TEMPLATE.md`, `FUTURE-MULTI-VARIANT.md`,
  `SETUP-SUMMARY.txt`, `PS5-PS7-COMPATIBILITY.md`) into a single `README.md`.

### Fixed
- `.claude/settings.json` granted read access via a machine-specific absolute
  path that resolved on no contributor's machine.
- Skill descriptions may open with `Use before`/`Use after`, not only
  `Use when`; the previous rule made anticipatory skills read worse.
- `build/Invoke-Build.ps1`'s Analyze task called `Invoke-ScriptAnalyzer -Path`
  with a multi-element array; that parameter is singular `[string]`. Fixed to
  call it once per path and merge results.
- `test-multiversion.yml`'s `cross-version-report` job (a required status
  check) failed on a 403 posting an ancillary PR comment even when its actual
  gate logic passed, because it declared no `permissions:` block. Granted
  `pull-requests: write` and made the comment step non-fatal.
