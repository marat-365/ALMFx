# Distributable plugins

Everything here is **shipped to users**. Once there is something to install:

```
/plugin marketplace add marat-365/ALMFx
/plugin install almfx@almfx
```

The marketplace manifest is `.claude-plugin/marketplace.json` at the repository
root; each plugin has its own `.claude-plugin/plugin.json`.

## Current state: no skills ship yet

`almfx/skills/` is deliberately empty — see
[`almfx/skills/README.md`](almfx/skills/README.md) for why and for when the first
one should land. The SPFx and PnP domain knowledge that a skill might have
carried lives in [`docs/reference/spfx-alm/`](../docs/reference/spfx-alm/)
instead, as the repository's single source of truth.

## Rules for skills here

- They run in the **user's** repo against the **user's** tenant. They must never
  reference ALMFx's own build system, contributor workflow, or internal paths.
  `tests/Pester/Repository.Tests.ps1` enforces this.
- Link to `docs/reference/spfx-alm/` for domain facts; never restate them.
- Prerequisites (module versions, tenant roles) stated up front.
- Every destructive step tells the agent to confirm with the user and to show
  the read-only equivalent first.

Authoring conventions: [`.claude/skills/skill-authoring/SKILL.md`](../.claude/skills/skill-authoring/SKILL.md).
