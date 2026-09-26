# 1. Record architecture decisions

Date: 2026-09-13

## Status

Accepted

## Context

ALMFx ships one domain in several formats (PowerShell module, standalone
scripts, a VS Code extension, agent skills). Several structural decisions are
cheap now and expensive later — particularly anything published to a public
registry, which cannot be unpublished.

## Decision

Record significant decisions here as short numbered files. Anything hard to
reverse gets an ADR before it ships.

## Decisions taken

- **One VS Code extension, not two.** Scaffolded as `src/vscode/almfx/`.
  The original plan split ALM operations from provisioning authoring; the
  audiences overlap enough that two empty extensions was speculative structure.
  Nothing is published, so splitting later remains cheap — do it with an ADR,
  and introduce `src/vscode/shared/` at the same time. Revisit before the first
  Marketplace publish.
- **Domain knowledge lives in `docs/reference/spfx-alm/`, once.** Skills,
  cmdlet help, and extension copy link to it rather than restating it. The first
  draft of the shipped skills duplicated the same facts across five files; that
  is exactly the drift `AGENTS.md` forbids.
- **Shipped skills stay empty until ALMFx has a surface worth driving.** A skill
  that only restates general PnP knowledge would ship a plugin that never
  mentions the product it is named after.
- **Target PowerShell 5.1+ and 7.4+, deliberately.** Not a compatibility
  oversight to be "fixed" back to 7.4-only: many SharePoint/M365 admins run
  Windows PowerShell 5.1 on locked-down workstations where installing PS 7 is
  not an option, and ALMFx should be usable there for anything that doesn't
  require PnP.PowerShell v3 itself (which stays PS 7.4+-only — see
  `docs/reference/spfx-alm/cmdlets.md`). Cross-version logic lives in
  `src/powershell/ALMFx/Shared/`. This raises the stakes on
  [ADR 0002](0002-code-signing.md): 5.1 is exactly where enterprise `AllSigned`
  execution policy is most common, so an unsigned release is a bigger real-world
  problem under this decision than it would be for a 7.4-only module, not a
  smaller one.

## Open decisions

- **Script module or binary module?** Currently a script module (`.psm1` plus
  one `.ps1` per function). PnP.PowerShell is a binary .NET module. This
  interacts with [ADR 0002](0002-code-signing.md): execution policy
  Authenticode-checks `.ps1`/`.psm1`/`.psd1` but not a compiled `.dll`, so the
  script-module shape is more exposed in `AllSigned` environments — and more so
  now that PS 5.1 is an intentional target (above), not less.
- **Code signing.** See [ADR 0002](0002-code-signing.md). Must be settled before
  the first PowerShell Gallery publish.
- **Does the module take a hard dependency on PnP.PowerShell?**
  `RequiredModules` forces an install on every user. Currently commented out.
- **Are standalone scripts generated or hand-written?** `scripts/` is empty and
  `AGENTS.md` promises generation from module source. Either build the generator
  or drop the shape — an unbacked promise is worse than neither.
- **One changelog or one per artefact?** The module manifest's `ReleaseNotes`
  points at the root `CHANGELOG.md`, so a PowerShell Gallery user currently sees
  VS Code entries mixed in. The extension has its own changelog already.
