# SPFx ALM reference

Domain knowledge for SharePoint Framework application lifecycle management and
PnP provisioning. This is the **single source of truth** for the repository:
skills, cmdlet help, and VS Code extension copy all link here rather than
restating it.

The rule from `AGENTS.md` — *domain rules live in exactly one place per concern*
— applies to documentation too. Before writing a fact about SPFx or PnP anywhere
else in this repo, check whether it belongs here instead.

| Page | Covers |
|---|---|
| [`cmdlets.md`](cmdlets.md) | **Start here.** Verified cmdlets, how to check one exists, and every cross-cutting fact |
| [`deployment.md`](deployment.md) | Uploading, publishing, installing, tenant-wide deployment |
| [`upgrade.md`](upgrade.md) | Version drift, rollout across sites, rollback |
| [`inventory.md`](inventory.md) | Read-only audit of what is deployed where |
| [`api-permissions.md`](api-permissions.md) | Pending requests, grants, the shared principal problem |
| [`troubleshooting.md`](troubleshooting.md) | Failure triage in likelihood order |
| [`provisioning.md`](provisioning.md) | Extracting and applying PnP site templates |
| [`cicd.md`](cicd.md) | Pipelines, app-only auth, promotion, rollback artefacts |

## Conventions

- Placeholders are always `contoso`. `tests/Pester/Repository.Tests.ps1` fails
  the build on any other SharePoint host.
- Every cmdlet named here was verified against the PnP documentation source, not
  recalled. See [`cmdlets.md`](cmdlets.md) for the verification method.
- Destructive operations always show the read-only equivalent first.
