---
name: module-release
description: Use when cutting a release of the ALMFx PowerShell module, a VS Code extension, or the skills plugin. Covers version bump, changelog, manifest validation, tagging, and the PowerShell Gallery / Marketplace publish steps. Trigger on "release", "publish", "version bump", "cut v0.2".
---

# Releasing

Each shipped format versions **independently**. A module release does not bump
the extensions, and vice versa.

## PowerShell module (`ALMFx` on PowerShell Gallery)

1. **Decide the version** — SemVer.
   - Breaking parameter/output change → major
   - New function or parameter → minor
   - Fix only → patch
   - Pre-1.0, still bump minor for breaking changes and say so loudly in the
     changelog.
2. **Changelog** — move `## [Unreleased]` entries under a new
   `## [x.y.z] - YYYY-MM-DD` heading. Keep an empty `## [Unreleased]` on top.
3. **Manifest** — set `ModuleVersion` in `src/powershell/ALMFx/ALMFx.psd1`.
   Confirm `FunctionsToExport` lists exactly the files in `Public/` (no
   wildcards — wildcards slow module discovery for every user).
4. **Validate**
   ```powershell
   ./build/Invoke-Build.ps1 -Task Analyze, Test, Stage
   Test-ModuleManifest ./out/ALMFx/ALMFx.psd1
   ```
5. **Commit and tag**
   ```
   chore(release): ALMFx v0.2.0
   git tag ps-v0.2.0
   ```
   Tag prefixes: `ps-`, `vscode-`, `plugin-`.
6. **Publish** — CI does this on the tag. Manual fallback:
   ```powershell
   Publish-Module -Path ./out/ALMFx -NuGetApiKey $env:PSGALLERY_API_KEY
   ```
   The API key lives in repository secrets as `PSGALLERY_API_KEY`. Never put it
   on a command line in a shared terminal or in a committed file.
7. **GitHub release** — body is the changelog section for that version.

## Gotchas

- PowerShell Gallery publishes are **irreversible**. A bad version can be
  unlisted but never replaced. Run `-WhatIf` on `Publish-Module` first.
- Templates live in `build/templates/`, deliberately outside the module tree:
  on Windows `Get-ChildItem -Filter '*.ps1'` can match `*.ps1.template` through
  8.3 short-name semantics, which would break module loading. Do not move them
  back into `Public/`. Verify with `Get-ChildItem ./out -Recurse` before publishing.
- `RequiredModules` in the manifest forces an install of PnP.PowerShell for every
  user. Only add it once a function genuinely cannot work without it.

## VS Code extensions

Bump `version` in the extension's `package.json`, update its `CHANGELOG.md`,
then `vsce package` / `vsce publish`. Never publish an extension whose
`activationEvents` include `"*"`.

## Skills plugin

Bump `version` in `plugins/almfx/.claude-plugin/plugin.json` and the matching
entry in `.claude-plugin/marketplace.json`. Users pick the change up on
`/plugin marketplace update almfx`.
