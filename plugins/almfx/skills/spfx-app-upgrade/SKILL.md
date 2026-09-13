---
name: spfx-app-upgrade
description: Use when an SPFx app shows "requires upgrade" or a newer version is in the app catalog but sites are still running the old one. Covers finding which sites are out of date and rolling the upgrade out safely. Trigger on "Update-PnPApp", "app requires upgrade", "InstalledVersion", "old version still showing", "roll out new version".
---

# Upgrading a deployed SPFx app

Uploading a new `.sppkg` updates the **catalog** version. Sites that already
have the app installed keep running the version they have until each one is
upgraded. That gap is what "requires upgrade" means.

## Find what is out of date

```powershell
Connect-PnPOnline -Url https://contoso.sharepoint.com -Interactive -ClientId <app-id>
Get-PnPApp -Scope Tenant |
    Select-Object Title, Id, AppCatalogVersion, InstalledVersion, CanUpgrade |
    Where-Object { $_.CanUpgrade }
```

`AppCatalogVersion` > `InstalledVersion` on a site means that site is stale.

## Upgrade one site

```powershell
Connect-PnPOnline -Url https://contoso.sharepoint.com/sites/marketing -Interactive -ClientId <app-id>
Update-PnPApp -Identity <app-id> -Scope Tenant
```

`Update-PnPApp` does **not** upload anything. Use `Add-PnPApp -Overwrite` to put
the new package in the catalog first.

## Roll out across sites

Do a pilot site first, confirm it, then the rest. **Ask the user to approve the
site list before running the loop**, and show it to them.

```powershell
$sites = @(
    'https://contoso.sharepoint.com/sites/marketing'
    'https://contoso.sharepoint.com/sites/hr'
)

foreach ($site in $sites) {
    Write-Verbose "Upgrading $site"
    $conn = Connect-PnPOnline -Url $site -Interactive -ClientId <app-id> -ReturnConnection
    try {
        Update-PnPApp -Identity <app-id> -Scope Tenant -Connection $conn
    }
    catch {
        Write-Warning "Failed on ${site}: $_"
    }
}
```

Keep going on failure and report the failures at the end — do not abort a rollout
half-way without telling the user which sites were done.

## Tenant-wide solutions

A solution published with `-SkipFeatureDeployment` is not "installed" per site,
so there is nothing to upgrade per site: overwriting the catalog package is the
whole rollout, and it takes effect everywhere at once. That makes it faster and
riskier. There is no staged rollout — test in a dev tenant first.

## Version bumping

The version that matters is `solution.version` in
`config/package-solution.json` (four-part, e.g. `1.2.0.0`). Sites do not detect
a change unless that number increases. Re-uploading the same version number with
`-Overwrite` will not produce an upgrade prompt.

## Rollback

There is no version history in the app catalog. To roll back you re-upload the
previous `.sppkg` with a **higher** version number than the bad one. Keep every
shipped `.sppkg` as a build artefact — this is the only reason you can undo a
bad release.

## Users still see the old web part

In order of likelihood: the site was not upgraded; the version number was not
bumped; browser cache; Office 365 CDN propagation (allow up to ~15 minutes);
the page has a stale web part instance that needs re-adding after a breaking
manifest change.
