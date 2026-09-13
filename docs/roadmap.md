# Roadmap

Nothing here is a commitment. It exists so "planned" is distinguishable from
"documented but missing", which is the failure mode this repo is most exposed to.

## Now

- [x] Repository structure and agent instructions
- [x] PowerShell module skeleton, build, and test harness
- [x] Skills plugin scaffold with the core SPFx ALM skills
- [ ] First real cmdlets: app catalog inventory and package deployment

## Next

- [ ] Standalone script equivalents for the deployment cmdlets
- [ ] `almfx-powershell` skill, once the module has a real surface
- [ ] First VS Code extension (`almfx-spfx-alm`), read-only views first
- [ ] Publish the module to the PowerShell Gallery

## Later / undecided

- [ ] Second VS Code extension for provisioning, **or** merge into one.
      Decide before the first Marketplace publish — see `docs/adr/`.
- [ ] MCP server exposing the same operations to any agent
- [ ] GitHub Action / Azure DevOps task for pipeline deployment
- [ ] Governance reporting across multiple tenants

## Explicitly out of scope

- Replacing PnP.PowerShell or CLI for Microsoft 365. ALMFx builds on them.
- SharePoint on-premises. PnP.PowerShell v3 is SharePoint Online only.
- Redistributing any part of the SPFx toolchain (see `docs/licensing.md`).
