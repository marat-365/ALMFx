---
name: spfx-alm-troubleshoot
description: Use when an SPFx deployment or web part is failing and the cause is not obvious - package will not upload, app shows "requires attention", web part missing from the toolbox, old code still running, or errors after a tenant change. Works through causes in likelihood order. Trigger on "sppkg won't deploy", "requires attention", "web part not showing", "still seeing old version", "SPFx broken after".
---

# Troubleshooting SPFx ALM

Work top to bottom. These are ordered by how often they are actually the cause.

## Read-only first

Never start by redeploying. Establish state:

```powershell
Get-PnPApp -Scope Tenant | Select-Object Title, Id, AppCatalogVersion, InstalledVersion, Deployed, CanUpgrade
Get-PnPTenantServicePrincipalPermissionRequests
```

## "App requires attention" / deployed but not working

Almost always a pending API permission request. See the `spfx-api-permissions`
skill. Check before doing anything else.

## Web part does not appear in the toolbox

1. Was it **published**, not just uploaded? `Deployed` must be `$true`.
   `Add-PnPApp` alone is not enough — `Publish-PnPApp` is "Deploy" in the UI.
2. Is it installed on this site? Unless the solution is tenant-wide
   (`SkipDeploymentFeature -eq $true`), each site needs `Install-PnPApp`.
3. Is the web part's `supportedHosts` in its manifest correct
   (`SharePointWebPart`, `SharePointFullPage`, `TeamsTab`)?
4. Is the page in a modern experience? SPFx web parts do not appear on classic pages.

## Old code still running

1. Was `solution.version` in `config/package-solution.json` bumped? Same version
   = no upgrade prompt.
2. Was the site upgraded? See the `spfx-app-upgrade` skill.
3. Office 365 CDN propagation — allow ~15 minutes.
4. Browser cache. Hard refresh, then a private window.
5. Was the build done with `--ship`? A debug bundle can reference `localhost`
   and appear to "not update" because it never loaded.

## Package will not upload

- Malformed or truncated `.sppkg` — rebuild with `gulp package-solution --ship`.
- Uploading over an existing app without `-Overwrite`.
- Not connected to the app catalog site. `Add-PnPApp -Scope Tenant` needs the
  connection to be the tenant app catalog, which is not the admin site.
  `Get-PnPTenantAppCatalogUrl` gives the right URL.
- No tenant app catalog exists yet — `Register-PnPAppCatalogSite`.
- For `-Scope Site`, no site collection app catalog —
  `Add-PnPSiteCollectionAppCatalog -Site <url>`.

## Works for me, fails for users

- Permissions on the underlying list/library the web part reads, not the app.
- The user's site is on an older app version.
- Conditional access or an unsupported browser.
- The web part calls Graph with a scope granted after the user's last sign-in.

## Broke after an SPFx version upgrade

- Node version mismatch — each SPFx release supports specific Node LTS versions.
  Check the version support matrix on Microsoft Learn before blaming the code.
- `npm ci` against a stale `package-lock.json`.
- Breaking changes in `@microsoft/sp-*` between major versions.
- Generated files left from the old version — `gulp clean`, delete `node_modules`,
  reinstall.

## Escalating

Before telling the user something is a service issue, confirm:
the same package deploys to a **different** site collection; a brand-new minimal
SPFx web part deploys to the same site. If both fail, it is environmental.
If the minimal one works, it is the solution.

## Rule

Do not "just redeploy" repeatedly. Each redeploy of a broken package burns a
version number and makes the rollback path longer.
