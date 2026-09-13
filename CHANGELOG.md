# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Each shipped format (PowerShell module, VS Code extension, skills plugin)
is versioned independently; entries note which one they affect.

## [Unreleased]

### Added
- Repository structure, agent instruction files (`AGENTS.md`, `CLAUDE.md`,
  `.github/copilot-instructions.md`, path-scoped Copilot instructions).
- PowerShell module skeleton (`ALMFx`) with build and test harness.
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

### Fixed
- `.claude/settings.json` granted read access via a machine-specific absolute
  path that resolved on no contributor's machine.
- Skill descriptions may open with `Use before`/`Use after`, not only
  `Use when`; the previous rule made anticipatory skills read worse.
