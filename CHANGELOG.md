# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Each shipped format (PowerShell module, VS Code extensions, skills plugin)
is versioned independently; entries note which one they affect.

## [Unreleased]

### Added
- Repository structure, agent instruction files (`AGENTS.md`, `CLAUDE.md`,
  `.github/copilot-instructions.md`, path-scoped Copilot instructions).
- PowerShell module skeleton (`ALMFx`) with build and test harness.
- Distributable skills plugin scaffold (`plugins/almfx`).
- `tests/Pester/Repository.Tests.ps1` — validates skill frontmatter, plugin
  manifest paths, the cmdlet docs table, and guards against real tenant URLs
  or key material being committed.
- `.gitattributes` and `.editorconfig`.

### Fixed
- `.claude/settings.json` granted read access via a machine-specific absolute
  path that resolved on no contributor's machine.
- Skill descriptions may open with `Use before`/`Use after`, not only
  `Use when`; the previous rule made anticipatory skills read worse.
