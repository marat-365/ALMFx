# ALMFx Test Playgrounds

Local, no-install sandbox for trying out the ALMFx module and SPFx ALM workflows
before anything ships. Nothing here is published; it's for contributors.

## What's in here

| Path | Purpose |
|---|---|
| `test-module.ps1` | Single-version test harness — loads the module from `src/powershell/ALMFx`, checks manifest/help/output types, runs each public function. |
| `run-all-tests.ps1` | Orchestrator — runs `test-module.ps1` on every PowerShell install it finds (5.1 and 7+) and reports pass/fail per version. |
| `spfx-sample-app/` | A real, generated multi-component SPFx solution (web part, extensions, library, ACE) used as an offline fixture for packaging/inventory/upgrade ALM experiments. See its own [README](spfx-sample-app/README.md). |

## Quick start

```powershell
# Test on your current PowerShell version
. .\testplaygrounds\test-module.ps1
Test-ALMFxModule -Verbose

# Test a single function
Test-ALMFxFunction -FunctionName "Get-ALMFxVersion"

# Test on every PowerShell install found (5.1 + 7+), with a CSV report
.\testplaygrounds\run-all-tests.ps1 -OutputReport results.csv
```

Run `test-module.ps1` before committing; run `run-all-tests.ps1` before opening a PR.
CI (`.github/workflows/test-multiversion.yml`) runs the same orchestrator on PS 5.1
and PS 7.2/7.3/7.4/latest and comments the results on the PR.

## Writing PS 5.1 + 7+ compatible code

Full conventions live in [`AGENTS.md`](../AGENTS.md#powershell) — this is just the
cheat sheet for what trips people up:

- Use `$PSVersionTable.PSEdition`/`.OS`, not `$PSVersionTable.Platform` (PS 5.1 doesn't have it).
- Don't use `$PSNativeCommandArgumentPassing` or other PS7-only automatic variables.
- Gate anything PS7-only behind `Get-PSVersionInfo` / `Test-PSVersionRequirement` /
  `Invoke-WithFallback` from `src/powershell/ALMFx/Shared/Compatibility.ps1`, instead
  of hand-rolled `$PSVersionTable.PSVersion -ge ...` checks.
- PnP.PowerShell: v2.x on PS 5.1, v3.x on PS 7+. Note this in a function's `.NOTES`.

## Troubleshooting

```powershell
# Module won't load
Import-Module -FullyQualifiedName "<repo>\src\powershell\ALMFx" -Force -Verbose

# Pester / analyzer missing
Install-Module Pester -MinimumVersion 5.0 -Scope CurrentUser -Force
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
```
