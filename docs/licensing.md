# Licensing

## ALMFx

**MIT Licence** — see [`LICENSE`](../LICENSE).

## Why MIT

MIT matches every project ALMFx sits next to, so code, samples, and patterns can
flow between them without a licence-compatibility problem:

| Project | Licence | Copyright holder | Source |
|---|---|---|---|
| PnP PowerShell | MIT | .NET Foundation | <https://github.com/pnp/powershell/blob/dev/LICENSE> |
| PnP Framework | MIT | .NET Foundation | <https://github.com/pnp/pnpframework/blob/dev/LICENSE> |
| SPFx web part samples (`sp-dev-fx-webparts`) | MIT | Microsoft Corporation | <https://github.com/SharePoint/sp-dev-fx-webparts/blob/main/LICENSE> |
| SPFx Toolkit for VS Code (`pnp/vscode-viva`) | MIT | Microsoft 365 Community (PnP) | <https://github.com/pnp/vscode-viva/blob/main/LICENSE> |
| CLI for Microsoft 365 | MIT | Microsoft 365 Community (PnP) | <https://github.com/pnp/cli-microsoft365/blob/main/LICENSE> |

MIT is also what the PowerShell Gallery and the VS Code Marketplace expect for
community tooling, and it imposes no obligation on the enterprises that will run
these scripts against their tenants.

## Important distinction

The **SharePoint Framework itself is not open source.** The
`@microsoft/sp-*` runtime packages and the `@microsoft/generator-sharepoint`
scaffolder are shipped by Microsoft under their own package licence terms, not
MIT. What *is* MIT is the community ecosystem around it — the samples, the PnP
libraries, the docs samples, the community tooling. ALMFx depends on and
automates the SPFx toolchain; it does not redistribute it. Always check the
`LICENSE` file in the specific `node_modules/@microsoft/...` package you depend
on before vendoring anything from it.

## If you borrow code

1. Keep the original copyright header in the file.
2. Add an entry to [`THIRD-PARTY-NOTICES.md`](../THIRD-PARTY-NOTICES.md) with
   the project, licence, and a link to the source file.
3. Note it in the PR description.

## Runtime dependencies

ALMFx does not bundle PnP.PowerShell, CLI for Microsoft 365, or the SPFx
toolchain — it requires them at runtime, so their licences apply to the user's
installation, not to this distribution.
