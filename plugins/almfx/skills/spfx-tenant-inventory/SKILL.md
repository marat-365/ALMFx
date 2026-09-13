---
name: spfx-tenant-inventory
description: Use when auditing what SPFx solutions and apps are deployed across a tenant - which sites have which app at which version, what is unused, what drifted. Produces a report rather than changing anything. Trigger on "what apps are deployed", "app inventory", "audit app catalog", "which sites use", "version drift", "unused apps".
---

# Tenant SPFx inventory

Read-only. Nothing in this skill modifies a tenant. Run it before any migration,
upgrade wave, or governance review.

## Prerequisites

- `PnP.PowerShell` 3.x, PowerShell 7.4+
- SharePoint Administrator (tenant catalog) or site collection admin (site catalogs)

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
- `SkipDeploymentFeature` — true means tenant-wide, so per-site install data
  will not tell you where it is used.

## Which sites have which app

There is no single cmdlet for "every site that has app X". Enumerate sites and
query each one. On a large tenant this is slow — warn the user and scope it.

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

$report | Export-Csv ./app-inventory.csv -NoTypeInformation
```

Always record the errors in the output rather than dropping them — a site you
could not read is a finding, not a gap.

## Site collection app catalogs

Site collection catalogs are easy to forget and are a common source of "why is
this old version still here". List the sites that have one, then inventory each:

```powershell
Get-PnPApp -Scope Site -Connection $conn
```

## Questions this answers

- **Version drift** — `CanUpgrade -eq $true`, grouped by app.
- **Never deployed** — tenant catalog entries with `Deployed -eq $false`.
- **Unused** — in the catalog, installed nowhere. (Tenant-wide solutions will
  look unused. Check `SkipDeploymentFeature` before concluding anything.)
- **Legacy add-ins** — `IsClientSideSolution -eq $false`; these are on a
  retirement path and should be flagged.

## Reporting

Give the user a CSV plus a short summary: total apps, how many stale, how many
undeployed, and the top three things worth acting on. Do not offer to fix
anything in the same breath — inventory first, decide second.
