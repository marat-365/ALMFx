# Tenant SPFx inventory

Read-only. Nothing here modifies a tenant. Run it before any migration, upgrade
wave, or governance review.

## What is in the tenant catalog

```powershell
$catalog = Get-PnPTenantAppCatalogUrl
Connect-PnPOnline -Url $catalog -Interactive -ClientId <app-id>

Get-PnPApp -Scope Tenant |
    Select-Object Title, Id, AppCatalogVersion, Deployed, IsClientSideSolution, SkipDeploymentFeature |
    Sort-Object Title |
    Export-Csv ./tenant-apps.csv -NoTypeInformation
```

Key columns:

- `Deployed` — false means uploaded but never published; it does nothing.
- `IsClientSideSolution` — false means a legacy add-in, not SPFx.
- `SkipDeploymentFeature` — true means tenant-wide, so per-site install data will
  not tell you where it is used.

## Which sites have which app

There is no single cmdlet for "every site that has app X". Enumerate and query
each site. On a large tenant this is slow — scope it, and warn before running.

```powershell
Connect-PnPOnline -Url https://contoso-admin.sharepoint.com -Interactive -ClientId <app-id>
$sites = Get-PnPTenantSite -Filter "Url -like 'https://contoso.sharepoint.com/sites/'"

$report = foreach ($site in $sites) {
    try {
        $conn = Connect-PnPOnline -Url $site.Url -Interactive -ClientId <app-id> -ReturnConnection
        foreach ($app in (Get-PnPApp -Scope Site -Connection $conn)) {
            [PSCustomObject]@{
                SiteUrl          = $site.Url
                Title            = $app.Title
                InstalledVersion = $app.InstalledVersion
                CatalogVersion   = $app.AppCatalogVersion
                CanUpgrade       = $app.CanUpgrade
            }
        }
    }
    catch {
        [PSCustomObject]@{ SiteUrl = $site.Url; Title = 'ERROR'; InstalledVersion = "$_" }
    }
}
```

Record errors in the output rather than dropping them — a site you could not read
is a finding, not a gap.

## Questions this answers

- **Version drift** — `CanUpgrade -eq $true`, grouped by app.
- **Never deployed** — catalog entries with `Deployed -eq $false`.
- **Unused** — in the catalog, installed nowhere. Tenant-wide solutions will look
  unused; check `SkipDeploymentFeature` before concluding anything.
- **Legacy add-ins** — `IsClientSideSolution -eq $false`, on a retirement path.

Site collection catalogs are easy to forget and a common source of "why is this
old version still here".
