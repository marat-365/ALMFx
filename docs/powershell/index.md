# ALMFx PowerShell module

```powershell
Install-Module ALMFx -Scope CurrentUser   # once published
Import-Module ALMFx
Get-Command -Module ALMFx
```

Requires PowerShell 7.4+. Functions that touch a tenant also require
`PnP.PowerShell` 3.x and an authenticated connection:

```powershell
Connect-PnPOnline -Url https://contoso.sharepoint.com -Interactive -ClientId <your-app-id>
```

## Cmdlets

| Cmdlet | Description | Mutates tenant |
|---|---|---|
| `Get-ALMFxVersion` | Version and environment information for bug reports | No |

_Add a row here for every function added to `FunctionsToExport`._

## Safety

Every mutating function supports `-WhatIf` and `-Confirm`. Run `-WhatIf` first
against production.
