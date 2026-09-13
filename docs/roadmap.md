# Roadmap

Nothing here is a commitment. It exists so "planned" is distinguishable from
"documented but missing", which is the failure mode this repo is most exposed to.

## Now

- [x] Repository structure and agent instructions
- [x] PowerShell module skeleton, build, and test harness
- [x] VS Code extension scaffold (`src/vscode/almfx/`) — activation, one
      placeholder command, no ALM functionality
- [x] `docs/reference/spfx-alm/` — domain knowledge as single source of truth
- [x] Repository contract tests (`tests/Pester/Repository.Tests.ps1`)
- [ ] First real cmdlets: app catalog inventory and package deployment

## Next

- [ ] Standalone script equivalents for the deployment cmdlets
- [ ] First real VS Code command, backed by the module or a direct PnP call —
      read-only views first
- [ ] First shipped skill in `plugins/almfx/skills/`, once there is an ALMFx
      surface worth driving rather than general PnP knowledge to restate
- [ ] Settle [ADR 0002](adr/0002-code-signing.md) (code signing) before this
- [ ] Publish the module to the PowerShell Gallery

## Later / undecided

- [ ] Second VS Code extension for provisioning, if the ALM and provisioning
      audiences turn out to want different things — see [ADR 0001](adr/0001-record-architecture-decisions.md)
- [ ] Script generator so `scripts/` stops being an unbacked promise — see
      the open decision in ADR 0001
- [ ] MCP server exposing the same operations to any agent
- [ ] GitHub Action / Azure DevOps task for pipeline deployment
- [ ] Governance reporting across multiple tenants

## Explicitly out of scope

- Replacing PnP.PowerShell or CLI for Microsoft 365. ALMFx builds on them.
- SharePoint on-premises. PnP.PowerShell v3 is SharePoint Online only.
- Redistributing any part of the SPFx toolchain (see `docs/licensing.md`).
