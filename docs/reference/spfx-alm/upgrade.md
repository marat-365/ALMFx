# Upgrading a deployed SPFx app

Version-bump rules, rollback, and why `Update-PnPApp` does not upload: see
[`cmdlets.md`](cmdlets.md).

Uploading a new `.sppkg` updates the **catalog** version. Sites that already have
the app installed keep running the version they have until each is upgraded.
That gap is what "requires upgrade" means.

## Find what is out of date

```powershell
Get-PnPApp -Scope Tenant |
    Select-Object Title, Id, AppCatalogVersion, InstalledVersion, CanUpgrade |
    Where-Object { $_.CanUpgrade }
```

## Upgrade one site

```powershell
Connect-PnPOnline -Url https://contoso.sharepoint.com/sites/marketing -Interactive -ClientId <app-id>
Update-PnPApp -Identity <app-id> -Scope Tenant
```

## Roll out across sites

Pilot one site, confirm, then the rest. Show the site list and get approval
before running the loop.

```powershell
$sites = @(
    'https://contoso.sharepoint.com/sites/marketing'
    'https://contoso.sharepoint.com/sites/hr'
)

$failures = foreach ($site in $sites) {
    $conn = Connect-PnPOnline -Url $site -Interactive -ClientId <app-id> -ReturnConnection
    try {
        Update-PnPApp -Identity <app-id> -Scope Tenant -Connection $conn
    }
    catch {
        [PSCustomObject]@{ Site = $site; Error = "$_" }
    }
}

$failures    # report these; never abort a rollout silently half-way
```

## Tenant-wide solutions

A solution published with `-SkipFeatureDeployment` is not installed per site, so
there is nothing to upgrade per site: overwriting the catalog package is the
whole rollout and takes effect everywhere at once. Faster, and riskier.

## Users still see the old web part

In likelihood order: the site was not upgraded; `solution.version` was not
bumped; browser cache; Office 365 CDN propagation (allow ~15 minutes); a page
holds a stale web part instance that needs re-adding after a breaking manifest
change.
