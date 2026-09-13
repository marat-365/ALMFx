## What and why

<!-- What changed, and what problem it solves. Link the issue. -->

## Which formats does this touch?

<!-- A change to an ALM operation usually needs more than one. Tick what you did. -->

- [ ] PowerShell module (`src/powershell/ALMFx/`)
- [ ] Standalone script (`scripts/`)
- [ ] VS Code extension (`src/vscode/`)
- [ ] Skill (`plugins/almfx/skills/` or `.claude/skills/`)
- [ ] Docs

If you left one out deliberately, say which and why:

## Tenant safety

- [ ] No new operation mutates a tenant, **or** it supports `-WhatIf`/`-Confirm`
- [ ] No tenant names, site URLs, GUIDs, secrets, or certificates committed
- [ ] Every PnP / CLI for M365 command used was verified to exist

## Checks

- [ ] `./build/Invoke-Build.ps1 -Task Analyze, Test` passes
- [ ] New/changed public functions are in `FunctionsToExport`
- [ ] New/changed public functions have comment-based help with an example
- [ ] Pester tests added, with all network calls mocked
- [ ] `CHANGELOG.md` updated under `## [Unreleased]`
