# Deploying an SPFx package

Prerequisites, cmdlet signatures, the upload/publish/install/upgrade distinction,
`--ship`, and `-SkipFeatureDeployment`: see [`cmdlets.md`](cmdlets.md).

## Prerequisites

- PowerShell 7.4+, `PnP.PowerShell` 3.x
- SharePoint Administrator for tenant scope; site collection admin plus an
  existing site collection app catalog for site scope

Confirm the target tenant before any write. Deploying to the wrong tenant is not
undoable in any pleasant way.

## Tenant app catalog

```powershell
$catalog = Get-PnPTenantAppCatalogUrl
Connect-PnPOnline -Url $catalog -Interactive -ClientId <app-id>

Add-PnPApp -Path ./sharepoint/solution/contoso-webpart.sppkg -Scope Tenant -Publish -Overwrite
```

Note the connection target: `Add-PnPApp -Scope Tenant` needs a connection to the
**app catalog site**, which is not the admin site. `Get-PnPTenantAppCatalogUrl`
gives the right URL.

Separate the steps when you want to review before going live:

```powershell
$app = Add-PnPApp -Path ./contoso-webpart.sppkg -Scope Tenant -Overwrite
Get-PnPApp -Scope Tenant | Where-Object Title -eq 'contoso-webpart'   # verify first
Publish-PnPApp -Identity $app.Id -Scope Tenant
```

### Tenant-wide deployment

```powershell
Publish-PnPApp -Identity $app.Id -Scope Tenant -SkipFeatureDeployment
```

This makes the solution available on every site with no per-site install. It is
a tenant-wide change with no staged rollout — confirm explicitly before running
it, and test in a dev tenant first.

## Site collection app catalog

```powershell
# Once per site collection, from the tenant admin connection:
Add-PnPSiteCollectionAppCatalog -Site https://contoso.sharepoint.com/sites/marketing

Connect-PnPOnline -Url https://contoso.sharepoint.com/sites/marketing -Interactive -ClientId <app-id>
$app = Add-PnPApp -Path ./contoso-webpart.sppkg -Scope Site -Publish -Overwrite
Install-PnPApp -Identity $app.Id -Scope Site
```

Site scope is the right default for pilots and for solutions one department
needs — it keeps the blast radius small.

## Verify

```powershell
Get-PnPApp -Scope Tenant | Select-Object Title, Id, AppCatalogVersion, Deployed, InstalledVersion
```

## After deploying

If the solution requests Graph or SharePoint API permissions, it is deployed but
the permissions are **pending approval**, and the web part fails at runtime until
they are granted. See [`api-permissions.md`](api-permissions.md).

## Common failures

| Symptom | Cause |
|---|---|
| "requires attention" in the catalog | Pending API permission request |
| Deployed but web part missing on a site | Not tenant-wide; needs `Install-PnPApp` per site |
| Old code still running | See [`upgrade.md`](upgrade.md) |
| `Add-PnPApp` fails on an existing app | Missing `-Overwrite` |
| Huge bundle, `localhost` references | Built without `--ship` |
