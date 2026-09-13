# CI/CD for SPFx solutions

Build commands, version bumping, and why artefacts must be retained: see
[`cmdlets.md`](cmdlets.md).

## The shape

```
build:   npm ci -> gulp bundle --ship -> gulp package-solution --ship -> artefact
deploy:  connect app-only -> Add-PnPApp -Overwrite -Publish
```

Build once, deploy the same artefact to each environment. Rebuilding per
environment defeats the purpose of having tested the artefact.

## Authentication for unattended deployment

Interactive login does not work in a pipeline. Use app-only authentication with a
certificate:

1. Register an Entra application.
2. Grant SharePoint application permissions. App deployment needs
   `Sites.FullControl.All` — a significant grant; call it out in review.
3. Admin-consent it.
4. Upload a certificate; store the password and base64 certificate in the
   pipeline secret store.

```powershell
Connect-PnPOnline -Url https://contoso.sharepoint.com/sites/appcatalog `
    -ClientId $env:ENTRA_CLIENT_ID `
    -Tenant   $env:TENANT_ID `
    -CertificateBase64Encoded $env:CERT_BASE64 `
    -CertificatePassword (ConvertTo-SecureString $env:CERT_PASSWORD -AsPlainText -Force)
```

Client secrets work but certificates are preferred — secrets expire noisily and
leak more easily. Never put either in a YAML file, a script, or a log.

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

Deploy in a separate job gated on a GitHub environment with required reviewers
for production. Automatic deployment to a production tenant on every merge is
worth arguing against.

## Deriving the version from the build

```powershell
$json = Get-Content ./config/package-solution.json -Raw | ConvertFrom-Json
$json.solution.version = "1.0.$env:GITHUB_RUN_NUMBER.0"
$json | ConvertTo-Json -Depth 20 | Set-Content ./config/package-solution.json
```

## Promotion

dev -> test -> production, same artefact each time. After deploying to
production, check whether an API permission approval is pending
([`api-permissions.md`](api-permissions.md)) — that step is manual and will not
happen in the pipeline.
