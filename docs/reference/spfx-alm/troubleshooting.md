# Troubleshooting SPFx ALM

Ordered by how often each is actually the cause. Work top to bottom.

## Establish state first

Never start by redeploying. Each redeploy of a broken package burns a version
number and lengthens the rollback path.

```powershell
Get-PnPApp -Scope Tenant | Select-Object Title, Id, AppCatalogVersion, InstalledVersion, Deployed, CanUpgrade
Get-PnPTenantServicePrincipalPermissionRequests
```

## "App requires attention" / deployed but not working

Almost always a pending API permission request. See
[`api-permissions.md`](api-permissions.md). Check this before anything else.

## Web part does not appear in the toolbox

1. Was it **published**, not just uploaded? `Deployed` must be `$true`.
2. Is it installed on this site? Unless tenant-wide
   (`SkipDeploymentFeature -eq $true`), each site needs `Install-PnPApp`.
3. Is `supportedHosts` in the web part manifest correct
   (`SharePointWebPart`, `SharePointFullPage`, `TeamsTab`)?
4. Is the page modern? SPFx web parts do not appear on classic pages.

## Old code still running

See [`upgrade.md`](upgrade.md) — version bump, site upgrade, CDN, cache, `--ship`.

## Package will not upload

- Malformed or truncated `.sppkg` — rebuild with `gulp package-solution --ship`.
- Uploading over an existing app without `-Overwrite`.
- Connected to the admin site rather than the app catalog site. Use
  `Get-PnPTenantAppCatalogUrl`.
- No tenant app catalog exists — `Register-PnPAppCatalogSite`.
- For `-Scope Site`, no site collection app catalog —
  `Add-PnPSiteCollectionAppCatalog -Site <url>`.

## Works for me, fails for users

- Permissions on the underlying list or library the web part reads, not the app.
- Their site is on an older app version.
- Conditional access, or an unsupported browser.
- The web part calls Graph with a scope granted after their last sign-in.

## Broke after an SPFx version upgrade

- Node version mismatch — check the SPFx support matrix before blaming the code.
- `npm ci` against a stale `package-lock.json`.
- Breaking changes in `@microsoft/sp-*` between majors.
- Stale generated files — `gulp clean`, delete `node_modules`, reinstall.

## Before calling it a service issue

Confirm both: the same package deploys to a **different** site collection, and a
brand-new minimal SPFx web part deploys to **this** site. If both fail it is
environmental. If the minimal one works, it is the solution.
