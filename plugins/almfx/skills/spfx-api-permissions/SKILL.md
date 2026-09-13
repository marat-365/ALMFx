---
name: spfx-api-permissions
description: Use when an SPFx solution requests Microsoft Graph or third-party API permissions - approving pending requests, auditing existing grants, or diagnosing a web part that fails with 403 or "access denied" after a successful deployment. Trigger on "API access", "pending permission request", "webApiPermissionRequests", "AadHttpClient", "Approve-PnPTenantServicePrincipalPermissionRequest", "SharePoint Online Client Extensibility".
---

# SPFx API permissions

A solution can deploy successfully and still fail at runtime because its
requested API permissions are pending approval. This is the single most common
"it deployed but it doesn't work" cause.

## Where the request comes from

`config/package-solution.json`:

```json
"webApiPermissionRequests": [
  { "resource": "Microsoft Graph", "scope": "User.ReadBasic.All" }
]
```

Uploading the `.sppkg` creates a **pending permission request** in the tenant.
Nothing is granted until an administrator approves it.

## Prerequisites

- SharePoint Administrator **and** the ability to consent on the
  `SharePoint Online Client Extensibility Web Application Principal`.
  In many tenants approving Graph scopes needs Global Administrator or
  Privileged Role Administrator — say so rather than letting the user hit a
  wall.
- Connection to the tenant admin site.

## Review what is pending

```powershell
Connect-PnPOnline -Url https://contoso-admin.sharepoint.com -Interactive -ClientId <app-id>
Get-PnPTenantServicePrincipalPermissionRequests
```

Show this to the user and **walk through each scope before approving anything.**
These are tenant-wide grants against a shared service principal.

## Approve

```powershell
Approve-PnPTenantServicePrincipalPermissionRequest -RequestId <guid>
```

Verbatim signature:
```powershell
Approve-PnPTenantServicePrincipalPermissionRequest -RequestId <Guid> [-Force]
 [-Connection <PnPConnection>]
```

Approve one request at a time, named explicitly. **Never loop over all pending
requests and approve them.** Requests from other people's solutions may be
queued alongside yours.

## Audit what is already granted

```powershell
Get-PnPTenantServicePrincipalPermissionGrants |
    Select-Object Resource, Scope, ClientId |
    Sort-Object Resource, Scope
```

Worth doing periodically. Grants accumulate; they are rarely removed when the
solution that needed them is retired.

## The shared-principal problem

All SPFx solutions in a tenant share one service principal. A scope granted for
one web part is available to **every** SPFx solution in the tenant, including
ones a different team deploys later. There is no per-solution isolation.

Consequences to raise with the user:
- Treat any grant of `.All`, `Directory.Read.All`, `Mail.Read`, `Sites.FullControl.All`
  or similar as a tenant-wide security decision, not a deployment detail.
- Prefer the narrowest scope that works (`User.ReadBasic.All` over `User.Read.All`).
- If a solution needs a broad scope, consider a dedicated Azure Function /
  Entra app registration behind the web part instead, so the grant is scoped to
  that app.

## Diagnosing runtime 403s

1. Is the request still pending? `Get-PnPTenantServicePrincipalPermissionRequests`
2. Is the scope actually granted? `Get-PnPTenantServicePrincipalPermissionGrants`
3. Does the granted scope match what the code asks `AadHttpClient` for?
   A mismatch between `package-solution.json` and the runtime call fails silently
   at deploy time and loudly at runtime.
4. Newly approved grants can take a few minutes to propagate. Have the user
   sign out and back in before re-testing.
