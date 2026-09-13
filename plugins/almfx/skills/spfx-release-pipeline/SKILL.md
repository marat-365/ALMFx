---
name: spfx-release-pipeline
description: Use when setting up CI/CD for an SPFx solution - GitHub Actions or Azure Pipelines that build, package, and deploy an .sppkg to an app catalog, including app-only authentication for unattended deployment. Trigger on "SPFx CI/CD", "GitHub Actions SPFx", "Azure DevOps sppkg", "automate deployment", "app-only auth", "certificate authentication", "unattended deploy".
---

# CI/CD for SPFx solutions

## The shape

```
build:   npm ci  ->  gulp bundle --ship  ->  gulp package-solution --ship  ->  artefact
deploy:  connect app-only  ->  Add-PnPApp -Overwrite -Publish
```

Build once, deploy the same artefact to each environment. Never rebuild per
environment — that defeats the purpose of having tested the artefact.

## Authentication for unattended deployment

Interactive login does not work in a pipeline. Use **app-only authentication with
a certificate**:

1. Register an Entra application.
2. Grant it SharePoint application permissions (`Sites.FullControl.All` is what
   app deployment needs — note this in the PR, it is a significant grant).
3. Admin-consent it.
4. Upload a certificate; store the `.pfx` password and the base64 certificate in
   the pipeline's secret store.

```powershell
Connect-PnPOnline -Url https://contoso.sharepoint.com/sites/appcatalog `
    -ClientId $env:ENTRA_CLIENT_ID `
    -Tenant   $env:TENANT_ID `
    -CertificateBase64Encoded $env:CERT_BASE64 `
    -CertificatePassword (ConvertTo-SecureString $env:CERT_PASSWORD -AsPlainText -Force)
```

Client secrets are supported but certificates are preferred — secrets expire
noisily and are easier to leak. **Never** put either in a YAML file, a script, or
a log. Mask them in the pipeline's secret configuration.

## GitHub Actions sketch

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '18'          # match the SPFx version's supported Node LTS
    cache: npm
- run: npm ci
- run: npx gulp bundle --ship
- run: npx gulp package-solution --ship
- uses: actions/upload-artifact@v4
  with:
    name: sppkg
    path: sharepoint/solution/*.sppkg
```

Deploy in a separate job gated on a GitHub **environment** with required
reviewers for production. Automatic deployment to a production tenant on every
merge is a mistake worth arguing against.

## Node version

Each SPFx release supports specific Node LTS versions. Pin the version in the
workflow and in `.nvmrc`, and check the support matrix on Microsoft Learn when
upgrading SPFx — a mismatched Node version produces confusing build failures.

## Versioning

Bump `solution.version` in `config/package-solution.json` on every release.
Sites do not detect a change without it. Deriving it from the build number is
reliable:

```powershell
$json = Get-Content ./config/package-solution.json -Raw | ConvertFrom-Json
$json.solution.version = "1.0.$env:GITHUB_RUN_NUMBER.0"
$json | ConvertTo-Json -Depth 20 | Set-Content ./config/package-solution.json
```

## Promotion

dev tenant -> test tenant -> production, same artefact each time. Deploy to
production with `-Overwrite -Publish` on the tenant app catalog, then check
whether an API permission approval is pending (`spfx-api-permissions`) — that
step is manual and will not happen in the pipeline.

## Keep the artefacts

Retain every deployed `.sppkg`. The app catalog has no version history, so a
rollback means re-uploading a previous package with a higher version number.
Without the artefact you cannot roll back at all.
