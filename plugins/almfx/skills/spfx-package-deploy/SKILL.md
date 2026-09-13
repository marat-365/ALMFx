---
name: spfx-package-deploy
description: Use when deploying a SharePoint Framework solution (.sppkg) to a tenant or site collection app catalog - uploading, publishing, installing on sites, tenant-wide deployment, or overwriting an existing version. Trigger on "deploy sppkg", "Add-PnPApp", "publish app", "app catalog", "package-solution.json", "gulp package-solution --ship".
---

# Deploying an SPFx package

## Prerequisites

- PowerShell 7.4+ and `PnP.PowerShell` 3.x
- A connection: `Connect-PnPOnline -Url https://contoso.sharepoint.com -Interactive -ClientId <your-app-id>`
  (v3 requires your own Entra app registration)
- SharePoint Administrator for tenant scope; site collection admin + an existing
  site collection app catalog for site scope

**Confirm the target with the user before any write.** Deploying to the wrong
tenant is not undoable in any pleasant way.

## The four distinct steps

People conflate these constantly. They are not the same operation:

| Step | Cmdlet | What it does |
|---|---|---|
| Upload | `Add-PnPApp` | Puts the `.sppkg` in the catalog. Not usable yet. |
| Deploy/publish | `Publish-PnPApp` | Makes it available to sites. ("Deploy" in the UI.) |
| Install | `Install-PnPApp` | Adds it to one specific site. |
| Upgrade | `Update-PnPApp` | Moves an installed site to the catalog's newer version. |

## Build first

```bash
npm ci
gulp clean
gulp bundle --ship
gulp package-solution --ship
# -> ./sharepoint/solution/<name>.sppkg
```

`--ship` is mandatory for anything but local debugging. Without it the bundle is
unminified and may reference `localhost`.

## Tenant app catalog

```powershell
$catalog = Get-PnPTenantAppCatalogUrl
Connect-PnPOnline -Url $catalog -Interactive -ClientId <app-id>

# Upload and deploy in one step
Add-PnPApp -Path ./sharepoint/solution/contoso-webpart.sppkg -Scope Tenant -Publish -Overwrite
```

Verbatim signature:
```powershell
Add-PnPApp [-Path] <String> [-Scope <AppCatalogScope>] [-Overwrite] [-Timeout <Int32>]
           [-Publish [-SkipFeatureDeployment]] [-Connection <PnPConnection>] [-Force]
```

Or separate the steps when you want to review before going live:
```powershell
$app = Add-PnPApp -Path ./contoso-webpart.sppkg -Scope Tenant -Overwrite
Get-PnPApp -Scope Tenant | Where-Object Title -eq 'contoso-webpart'   # verify first
Publish-PnPApp -Identity $app.Id -Scope Tenant
```

### Tenant-wide deployment

`-SkipFeatureDeployment` makes the solution available on every site without a
per-site install. It only works if `package-solution.json` contains
`"skipFeatureDeployment": true`. Passing the switch to a solution not built that
way silently does nothing useful.

```powershell
Publish-PnPApp -Identity $app.Id -Scope Tenant -SkipFeatureDeployment
```

This is a tenant-wide change. **Ask the user to confirm explicitly.**

## Site collection app catalog

```powershell
# Once per site collection, from the tenant admin connection:
Add-PnPSiteCollectionAppCatalog -Site https://contoso.sharepoint.com/sites/marketing

Connect-PnPOnline -Url https://contoso.sharepoint.com/sites/marketing -Interactive -ClientId <app-id>
Add-PnPApp -Path ./contoso-webpart.sppkg -Scope Site -Publish -Overwrite
Install-PnPApp -Identity $app.Id -Scope Site
```

Site scope is the right default for pilots and for solutions only one department
needs — it keeps the blast radius small.

## Verify

```powershell
Get-PnPApp -Scope Tenant | Select-Object Title, Id, AppCatalogVersion, Deployed, InstalledVersion
```

## After deploying

If the solution requests Microsoft Graph or SharePoint API permissions, the
package is deployed but **the permissions are pending approval** and the web
part will fail at runtime until they are granted. See the
`spfx-api-permissions` skill.

## Common failures

| Symptom | Cause |
|---|---|
| "requires attention" in the catalog | Solution needs API permission approval |
| Deployed but web part missing on site | Not tenant-wide; needs `Install-PnPApp` per site |
| Old code still running | Browser/CDN cache, or the site is on an older version — see `spfx-app-upgrade` |
| `Add-PnPApp` fails on an existing app | Missing `-Overwrite` |
| Huge bundle, `localhost` references | Built without `--ship` |
