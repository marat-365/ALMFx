---
name: pnp-provisioning
description: Use when extracting, authoring, or applying PnP provisioning templates to shape SharePoint sites - site columns, content types, lists, navigation, pages, theme. Covers Get-PnPSiteTemplate and Invoke-PnPSiteTemplate and the tokens/handlers model. Trigger on "provisioning template", "site template", "Get-PnPSiteTemplate", "Invoke-PnPSiteTemplate", "extract site structure", "PnP XML template", "apply template to site".
---

# PnP provisioning templates

Capture a site's structure as a template, review it, apply it elsewhere.

## Cmdlet names matter

PnP.PowerShell v3 uses:

- `Get-PnPSiteTemplate` — extract
- `Invoke-PnPSiteTemplate` — apply

The old `Get-PnPProvisioningTemplate` / `Apply-PnPProvisioningTemplate` names are
from PnP-PowerShell v1 and will not resolve. If a user's script uses them, they
are on the legacy module.

## Extract

```powershell
Connect-PnPOnline -Url https://contoso.sharepoint.com/sites/template-source -Interactive -ClientId <app-id>

Get-PnPSiteTemplate -Out ./templates/project-site.xml
```

Scope it — a full extract of a real site is large and full of noise:

```powershell
Get-PnPSiteTemplate -Out ./templates/project-site.xml `
    -Handlers Lists, ContentTypes, Fields, Navigation
```

`-Handlers` is the main control. Useful values include `Lists`, `Fields`,
`ContentTypes`, `Navigation`, `SiteSecurity`, `PageContents`, `Pages`,
`Files`, `CustomActions`, `ComposedLook`. Check
`Get-Help Get-PnPSiteTemplate -Parameter Handlers` for the exact set your
version supports rather than assuming.

## Review before applying — always

Open the XML. Look for and remove:
- Hardcoded user accounts and group memberships from the source site
- Source-specific URLs that should be `{site}` / `{sitecollection}` tokens
- Content you did not mean to carry (`PageContents`, `Files`)
- List items containing real data

**Never apply an unreviewed extract to a production site.** Show the user what
the template will create before running it.

## Apply

```powershell
Connect-PnPOnline -Url https://contoso.sharepoint.com/sites/new-project -Interactive -ClientId <app-id>

Invoke-PnPSiteTemplate -Path ./templates/project-site.xml
```

Provisioning is **not transactional**. A failure half-way leaves the site
partially configured. Apply to a throwaway site first, every time.

## Tokens

Templates use tokens so they are portable:

| Token | Resolves to |
|---|---|
| `{site}` | Current web URL |
| `{sitecollection}` | Site collection root URL |
| `{siteid}` | Site GUID |
| `{themecatalog}` | Theme catalog URL |
| `{masterpagecatalog}` | Master page catalog URL |

A template full of `https://contoso.sharepoint.com/sites/source/...` is not a
template — it is a copy of one site.

## Idempotency

`Invoke-PnPSiteTemplate` is largely additive. Re-applying generally updates or
skips rather than duplicating, but this varies by handler — list **items** in
particular can duplicate. Verify on a test site before building a pipeline that
re-applies a template on a schedule.

## Where this meets SPFx

A provisioning template can include the SPFx apps a site needs, and pages with
web part instances already placed. The app must already be in the app catalog —
provisioning does not deploy packages. Order is: deploy the `.sppkg`
(`spfx-package-deploy`), then provision sites that use it.

## Version control

Keep templates in git as XML, one per site archetype, with a README covering
what each one assumes (a hub site? a specific content type hub? a deployed app?).
Diff the XML on every change — a re-extract can silently pick up drift from the
source site.
