# 1. Record architecture decisions

Date: 2026-09-13

## Status

Accepted

## Context

ALMFx ships one domain in several formats (PowerShell module, standalone
scripts, VS Code extensions, agent skills). Several structural decisions are
cheap now and expensive later — particularly anything published to a public
registry, which cannot be unpublished.

## Decision

Record significant decisions here as short numbered files. Anything that is hard
to reverse gets an ADR before it ships.

## Open decisions

- **One VS Code extension or two?** Currently scaffolded as two
  (`almfx-spfx-alm`, `almfx-provisioning`) over `src/vscode/shared/`. Merging
  later is cheap; splitting a published extension is not. **Must be decided
  before the first Marketplace publish.**
- **Are standalone scripts generated or hand-written?** Currently hand-written
  with a rule against duplicating real logic. Generation from module source is
  the intended end state.
- **Does the module take a hard dependency on PnP.PowerShell?**
  `RequiredModules` forces an install on every user. Currently commented out.
