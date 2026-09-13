# SPFx ALM command reference

**Single source of truth for this repository.** Every other reference page, skill,
and function doc links here instead of restating these facts. If a cmdlet name,
parameter, or behaviour is wrong, it is wrong in exactly one place.

Verified against [`pnp/powershell`](https://github.com/pnp/powershell) `dev`
branch documentation on **2026-09-13**. Re-verify when PnP.PowerShell ships a
new major version and update this date.

## How to verify a cmdlet exists

Cmdlet hallucination is the dominant failure mode in this domain: PnP.PowerShell
has ~900 cmdlets with highly regular names, so an invented one
(`Get-PnPAppCatalogApp`, `Deploy-PnPApp`) looks exactly like a real one.

1. **With the module loaded**
   ```powershell
   Get-Command -Module PnP.PowerShell -Name '*App*'
   Get-Help Add-PnPApp -Parameter Scope
   ```
2. **Against the docs source** — every real cmdlet has a file at a predictable
   URL. A 404 means it does not exist:
   ```
   https://raw.githubusercontent.com/pnp/powershell/dev/documentation/<Cmdlet-Name>.md
   ```
   Rendered index: <https://pnp.github.io/powershell/cmdlets/>
3. **CLI for Microsoft 365** — <https://pnp.github.io/cli-microsoft365/>

Never rely on memory for a parameter name. `-Scope` vs `-SiteUrl` vs `-Site`
differ between cmdlets in this same family.

## Verified cmdlets

**App / ALM**
`Add-PnPApp`, `Get-PnPApp`, `Publish-PnPApp`, `Install-PnPApp`,
`Update-PnPApp`, `Uninstall-PnPApp`, `Remove-PnPApp`, `Sync-PnPAppToTeams`

**App catalog**
`Get-PnPTenantAppCatalogUrl`, `Register-PnPAppCatalogSite`,
`Add-PnPSiteCollectionAppCatalog`

**API permissions**
`Get-PnPTenantServicePrincipalPermissionRequests`,
`Approve-PnPTenantServicePrincipalPermissionRequest`,
`Get-PnPTenantServicePrincipalPermissionGrants`

**Provisioning**
`Get-PnPSiteTemplate`, `Invoke-PnPSiteTemplate`

> The v1 names `Get-PnPProvisioningTemplate` / `Apply-PnPProvisioningTemplate`
> belong to the legacy PnP-PowerShell module and will not resolve in v3.

## Signatures, verbatim

```powershell
Add-PnPApp [-Path] <String> [-Scope <AppCatalogScope>] [-Overwrite] [-Timeout <Int32>]
           [-Publish [-SkipFeatureDeployment]] [-Connection <PnPConnection>] [-Force]
```

```powershell
Approve-PnPTenantServicePrincipalPermissionRequest -RequestId <Guid> [-Force]
 [-Connection <PnPConnection>]
```

## The four operations are not the same

Conflating these is the most common source of "it deployed but nothing happened".

| Operation | Cmdlet | Effect |
|---|---|---|
| Upload | `Add-PnPApp` | Puts the `.sppkg` in the catalog. Not usable yet. |
| Deploy / publish | `Publish-PnPApp` | Makes it available to sites. This is "Deploy" in the UI. |
| Install | `Install-PnPApp` | Adds it to one specific site. |
| Upgrade | `Update-PnPApp` | Moves an already-installed site to the catalog's newer version. |

`Update-PnPApp` does **not** upload a new package — `Add-PnPApp -Overwrite` does.

## Cross-cutting facts

These are referenced from several pages. They live here only.

### `--ship` is mandatory for anything but local debugging

```bash
npm ci
gulp clean
gulp bundle --ship
gulp package-solution --ship     # -> sharepoint/solution/<name>.sppkg
```

Without `--ship` the bundle is unminified and may reference `localhost`. This is
the most common cause of "it works locally but the deployed web part is broken".

### The version number is what triggers an upgrade

`solution.version` in `config/package-solution.json` is four-part (e.g.
`1.2.0.0`). Sites do not detect a change unless it **increases**. Re-uploading
the same version with `-Overwrite` produces no upgrade prompt.

### There is no version history in the app catalog

Rollback means re-uploading the previous `.sppkg` with a version **higher** than
the bad one. Keep every shipped package as a build artefact — without it you
cannot roll back at all.

### `-SkipFeatureDeployment` requires the solution to be built for it

It only works if `config/package-solution.json` has
`"skipFeatureDeployment": true`. Passing the switch to a solution not built that
way silently does not make it tenant-wide.

### Connections in PnP.PowerShell v3

v3 requires your own Entra app registration — there is no built-in multi-tenant
app any more:

```powershell
Connect-PnPOnline -Url https://contoso.sharepoint.com -Interactive -ClientId <your-app-id>
```

Thread `-Connection` explicitly rather than relying on ambient connection state.
v3 requires PowerShell 7.4+ and is SharePoint Online only.

### All SPFx solutions share one service principal

A Graph scope granted for one web part is available to **every** SPFx solution
in the tenant, including ones another team deploys later. There is no per-solution
isolation. Treat any `.All` grant as a tenant-wide security decision.

## SPFx toolchain

Do not claim a `gulp` task exists beyond the ones the SPFx build rig registers —
check `gulpfile.js` and `gulp --tasks` in the target project.

Each SPFx release supports specific Node LTS versions. Check the support matrix
on Microsoft Learn before upgrading; a mismatched Node version produces
confusing build failures.
