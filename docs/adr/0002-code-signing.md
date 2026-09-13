# 2. Code signing for the PowerShell module

Date: 2026-09-13

## Status

Proposed — **must be decided before the first PowerShell Gallery publish.**

## Context

ALMFx targets SharePoint and Microsoft 365 administrators in enterprises. That
audience disproportionately runs managed Windows machines with a PowerShell
execution policy set by Group Policy.

The facts that matter ([about_Execution_Policies][aep], [about_Signing][as]):

- Execution policy is enforced **only on Windows**. macOS and Linux are
  `Unrestricted` and cannot be changed.
- Defaults: `Restricted` on Windows 10/11 clients, `RemoteSigned` on Windows
  Server 2016/2019/2022.
- `AllSigned` requires a trusted-publisher signature on **all** scripts and
  configuration files, *including ones written locally*.
- The Group Policy setting **Turn on Script Execution → "Allow only signed
  scripts"** is equivalent to `AllSigned` and **overrides every locally set
  policy**. This is the common enterprise configuration.
- PowerShell checks the Authenticode signature of `.ps1`, `.psm1`, `.psd1`,
  `.ps1xml`, `.cdxml`, and `.xaml` files.

That last point interacts with an open decision in
[ADR 0001](0001-record-architecture-decisions.md). ALMFx is currently a **script
module**: `ALMFx.psm1`, `ALMFx.psd1`, and one `.ps1` per function. Every one of
those file types is signature-checked. A binary module — the shape
PnP.PowerShell uses — ships its logic in a `.dll`, which execution policy does
not Authenticode-check at all (WDAC and AppLocker are separate matters). So the
script-module choice maximises exposure to this problem.

PnP.PowerShell signs every release; their README attributes it to a .NET
Foundation certificate. We are next to a signed dependency, which makes an
unsigned ALMFx conspicuous: an admin who can `Import-Module PnP.PowerShell` under
`AllSigned` and then cannot `Import-Module ALMFx` will read that as ALMFx being
the unprofessional one.

Unsigned is not merely a warning under `AllSigned` — the import fails.

## Decision

**To be made.** Four options:

### A. Commercial code-signing certificate (OV or EV)

Roughly USD 200–400/year from a public CA. EV certificates require a hardware
token, which is awkward to use from CI and effectively rules out unattended
signing without an HSM-backed service.

- Works everywhere, no eligibility questions.
- Ongoing cost and renewal burden on one maintainer.

### B. Azure Trusted Signing

Microsoft's managed signing service, billed per month plus per signature, with
certificates issued and held in the service rather than on a token — designed for
signing from CI.

- Fits a GitHub Actions release job.
- **Verify current eligibility before committing**: identity validation
  requirements and whether an individual (as opposed to a legal entity with a
  verifiable trading history) can enrol have changed more than once. Do not
  treat this option as confirmed until checked against current Microsoft
  documentation.

### C. Join the .NET Foundation and use its certificate

The route PnP.PowerShell took.

- No direct cost, and strong provenance.
- Requires project acceptance and gives up some unilateral control. Almost
  certainly premature for a project at version 0.1.0 with no users.

### D. Ship unsigned, document the limitation

- Zero cost, available today.
- ALMFx cannot be imported at all in `AllSigned` environments, and the README
  must say so plainly rather than letting admins discover it at import time.
- Acceptable **only** as an explicitly time-boxed pre-1.0 position.

## Consequences

Whichever is chosen:

- The `Stage` step in `build/Invoke-Build.ps1` becomes the signing boundary —
  sign the staged `out/ALMFx` tree, not the source tree, so signatures are never
  committed to git and never go stale against an edited file.
- Signing must happen **before** `Publish-Module`. A PowerShell Gallery publish
  is irreversible; an unsigned 1.0.0 cannot be replaced, only unlisted.
- `tests/Pester/Repository.Tests.ps1` should gain a release-only check that every
  signature-checked file in `out/` has a valid signature
  (`Get-AuthenticodeSignature`), so an unsigned file cannot ship by accident.
- The certificate or signing credential goes in repository secrets and is used
  only by the tag-triggered release workflow, never by PR CI.
- If option D is chosen, the README and module manifest description must state
  the `AllSigned` limitation up front.

The VS Code extension has a separate and less urgent story: the Marketplace
signs `.vsix` packages itself as part of publishing, so this ADR concerns the
PowerShell module only.

[aep]: https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_execution_policies
[as]: https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_signing
