# PnP provisioning templates

Cmdlet names (`Get-PnPSiteTemplate` / `Invoke-PnPSiteTemplate`, and why the v1
names do not resolve) are in [`cmdlets.md`](cmdlets.md).

## Extract

```powershell
Connect-PnPOnline -Url https://contoso.sharepoint.com/sites/template-source -Interactive -ClientId <app-id>

Get-PnPSiteTemplate -Out ./templates/project-site.xml `
    -Handlers Lists, ContentTypes, Fields, Navigation
```

Scope it with `-Handlers` — a full extract of a real site is large and full of
noise. Useful values include `Lists`, `Fields`, `ContentTypes`, `Navigation`,
`SiteSecurity`, `PageContents`, `Pages`, `Files`, `CustomActions`,
`ComposedLook`. Check `Get-Help Get-PnPSiteTemplate -Parameter Handlers` for the
exact set your version supports rather than assuming.

## Review before applying — always

Open the XML. Remove:

- Hardcoded user accounts and group memberships from the source site
- Source-specific URLs that should be tokens
- Content you did not mean to carry (`PageContents`, `Files`)
- List items containing real data

Never apply an unreviewed extract to a production site.

## Apply

```powershell
Connect-PnPOnline -Url https://contoso.sharepoint.com/sites/new-project -Interactive -ClientId <app-id>
Invoke-PnPSiteTemplate -Path ./templates/project-site.xml
```

Provisioning is **not transactional**. A failure half-way leaves the site
partially configured. Apply to a throwaway site first, every time.

## Tokens

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
particular can duplicate. Verify on a test site before scheduling re-application.

## Where this meets SPFx

A template can include the SPFx apps a site needs and pages with web part
instances already placed, but the app must already be in the app catalog —
provisioning does not deploy packages. Order: deploy the `.sppkg`
([`deployment.md`](deployment.md)), then provision sites that use it.

## Version control

Keep templates in git as XML, one per site archetype, each with a README stating
what it assumes (a hub site? a content type hub? a deployed app?). Diff on every
change — a re-extract silently picks up drift from the source site.
