# SPFx API permissions

The shared service principal problem is in [`cmdlets.md`](cmdlets.md), as is the
`Approve-PnPTenantServicePrincipalPermissionRequest` signature.

A solution can deploy successfully and still fail at runtime because its
requested API permissions are pending approval. This is the most common
"it deployed but it doesn't work" cause.

## Where the request comes from

`config/package-solution.json`:

```json
"webApiPermissionRequests": [
  { "resource": "Microsoft Graph", "scope": "User.ReadBasic.All" }
]
```

Uploading the `.sppkg` creates a pending request. Nothing is granted until an
administrator approves it.

## Prerequisites

SharePoint Administrator, **plus** the ability to consent on the
`SharePoint Online Client Extensibility Web Application Principal`. In many
tenants approving Graph scopes needs Global Administrator or Privileged Role
Administrator — say so rather than letting someone hit a wall.

## Review, then approve one at a time

```powershell
Connect-PnPOnline -Url https://contoso-admin.sharepoint.com -Interactive -ClientId <app-id>
Get-PnPTenantServicePrincipalPermissionRequests
```

Walk through each scope before approving anything — these are tenant-wide grants
against a shared principal.

```powershell
Approve-PnPTenantServicePrincipalPermissionRequest -RequestId <guid>
```

Never loop over all pending requests and approve them. Requests from other
people's solutions may be queued alongside yours.

## Audit what is already granted

```powershell
Get-PnPTenantServicePrincipalPermissionGrants |
    Select-Object Resource, Scope, ClientId |
    Sort-Object Resource, Scope
```

Worth doing periodically. Grants accumulate; they are rarely removed when the
solution that needed them is retired.

## Keeping grants narrow

- Prefer the narrowest scope that works (`User.ReadBasic.All` over `User.Read.All`).
- If a solution needs a broad scope, consider a dedicated Azure Function or Entra
  app registration behind the web part, so the grant is scoped to that app rather
  than to every SPFx solution in the tenant.

## Diagnosing runtime 403s

1. Still pending? `Get-PnPTenantServicePrincipalPermissionRequests`
2. Actually granted? `Get-PnPTenantServicePrincipalPermissionGrants`
3. Does the granted scope match what the code asks `AadHttpClient` for? A
   mismatch fails silently at deploy time and loudly at runtime.
4. Newly approved grants take a few minutes to propagate. Sign out and back in
   before re-testing.
