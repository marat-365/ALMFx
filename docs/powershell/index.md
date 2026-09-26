# ALMFx PowerShell module

```powershell
Install-Module ALMFx -Scope CurrentUser   # once published
Import-Module ALMFx
Get-Command -Module ALMFx
```

Requires PowerShell 5.1+ (Desktop) or 7.4+ (Core) — see AGENTS.md's PowerShell
conventions for why both are supported. Functions that touch a tenant also
require `PnP.PowerShell` 3.x (itself PowerShell 7.4+ only) and an
authenticated connection:

```powershell
Connect-PnPOnline -Url https://contoso.sharepoint.com -Interactive -ClientId <your-app-id>
```

## Cmdlets

| Cmdlet | Description | Mutates tenant | Mutates local files |
|---|---|---|---|
| `Get-ALMFxVersion` | Version and environment information for bug reports | No | No |
| `New-ALMFxEnvironment` | Builds a per-environment copy of an SPFx solution's SharePoint-facing files under `.<environment>/`, optionally with fresh GUIDs and `_<environment>`-suffixed names so it can be deployed side by side with other environments | No | Yes — writes under `.<environment>/` and `.almfx/environments/` only |
| `Set-ALMFxEnvironment` | Deploys a built `.<environment>/` folder's files into the solution, overwriting the originals | No | Yes — overwrites files at their normal locations |

_Add a row here for every function added to `FunctionsToExport`._

### `New-ALMFxEnvironment` / `Set-ALMFxEnvironment`

Pure filesystem/text operations — no tenant connection, no PnP dependency.
Typical use:

```powershell
# Build an isolated dev identity (fresh GUIDs, "_dev"-suffixed names)
New-ALMFxEnvironment -Path ./my-solution -Environment dev

# ...review ./my-solution/.dev/, then deploy it into the solution
Set-ALMFxEnvironment -Path ./my-solution -Environment dev

# Production keeps the real, already-live identity by default (no renaming)
New-ALMFxEnvironment -Path ./my-solution -Environment prod
Set-ALMFxEnvironment -Path ./my-solution -Environment prod
```

`New-ALMFxEnvironment` is safe to re-run: it reuses every id/name already
assigned to an artefact and only generates a fresh one for something new
since the last run (a persisted map at
`.almfx/environments/<environment>.map.json` tracks this — commit it if you
want the team/CI to share the same per-environment identities).

## Safety

Every mutating function supports `-WhatIf` and `-Confirm`. Run `-WhatIf` first
against production.
