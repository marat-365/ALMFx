---
name: pnp-reference
description: Use before writing or reviewing any PnP.PowerShell, CLI for Microsoft 365, or SPFx toolchain command in this repo. Verifies a cmdlet, parameter, or CLI flag actually exists instead of guessing, and gives the canonical SPFx ALM command sequences. Trigger on any Add-PnP*, Get-PnP*, Publish-PnP*, m365 spo *, gulp bundle/package-solution, or "does this cmdlet exist" question.
---

# PnP / SPFx command reference

Cmdlet hallucination is the most common failure mode in this domain. PnP
PowerShell has ~900 cmdlets with highly regular names, so a plausible-sounding
invention (`Get-PnPAppCatalogApp`, `Deploy-PnPApp`) looks exactly like a real
one. **Verify before you write.**

## How to verify

In order of preference:

1. **In a session with the module loaded**
   ```powershell
   Get-Command -Module PnP.PowerShell -Name '*App*'
   Get-Help Add-PnPApp -Parameter Scope
   ```
2. **Against the docs source** — every cmdlet has a markdown file at a
   predictable URL. A 404 means the cmdlet does not exist:
   ```
   https://raw.githubusercontent.com/pnp/powershell/dev/documentation/<Cmdlet-Name>.md
   ```
   The rendered index is <https://pnp.github.io/powershell/cmdlets/>.
3. **CLI for Microsoft 365** — <https://pnp.github.io/cli-microsoft365/cmd/spo/app/app-add/>

Never rely on memory for a parameter name. `-Scope` vs `-SiteUrl` vs `-Site`
differ between cmdlets in this family.

## Verified cmdlets (checked against pnp/powershell `dev`)

App / ALM:
`Add-PnPApp`, `Get-PnPApp`, `Publish-PnPApp`, `Install-PnPApp`,
`Update-PnPApp`, `Uninstall-PnPApp`, `Remove-PnPApp`, `Sync-PnPAppToTeams`

App catalog:
`Get-PnPTenantAppCatalogUrl`, `Register-PnPAppCatalogSite`,
`Add-PnPSiteCollectionAppCatalog`

API permissions:
`Get-PnPTenantServicePrincipalPermissionRequests`,
`Approve-PnPTenantServicePrincipalPermissionRequest`,
`Get-PnPTenantServicePrincipalPermissionGrants`

Provisioning:
`Get-PnPSiteTemplate`, `Invoke-PnPSiteTemplate`
(the older `Get-PnPProvisioningTemplate` / `Apply-PnPProvisioningTemplate` names
belong to PnP-PowerShell v1 — do not use them for v3)

`Add-PnPApp` signature, verbatim from the docs:
```powershell
Add-PnPApp [-Path] <String> [-Scope <AppCatalogScope>] [-Overwrite] [-Timeout <Int32>]
           [-Publish [-SkipFeatureDeployment]] [-Connection <PnPConnection>] [-Force]
```

## Things that trip people up

- **`-Scope`** is `Tenant` (default) or `Site`. With `Site` you must be
  connected to the site whose collection app catalog you mean.
- **`-SkipFeatureDeployment`** only works if the solution's
  `package-solution.json` has `skipFeatureDeployment: true`. Passing it to a
  solution that was not built that way silently does not make it tenant-wide.
- **`Publish-PnPApp` is "deploy"** in the UI. Adding is not deploying.
- **`Install-PnPApp`** adds the app to a *site*; publishing makes it available
  tenant-wide. Both are needed unless the solution is tenant-scoped.
- **`Update-PnPApp`** triggers the upgrade on a site where an older version is
  installed — it does not upload a new package. `Add-PnPApp -Overwrite` does.
- **Connections**: PnP.PowerShell v3 requires your own Entra app registration —
  `Connect-PnPOnline -Url ... -Interactive -ClientId <guid>`. There is no longer
  a built-in multi-tenant app. Always thread `-Connection` through rather than
  relying on ambient state.
- **PnP.PowerShell v3 requires PowerShell 7.4+** and is SharePoint Online only.

## SPFx toolchain

```bash
npm ci
gulp clean
gulp bundle --ship
gulp package-solution --ship     # produces sharepoint/solution/*.sppkg
```
`--ship` is what makes it a production build; forgetting it is the most common
cause of "it works locally but the deployed web part is huge / points at
localhost".

Do not claim a `gulp` task exists beyond the ones the SPFx build rig actually
registers — check `gulpfile.js` and `gulp --tasks` in the target project.
