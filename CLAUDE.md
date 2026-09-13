# CLAUDE.md

All shared repository rules live in **AGENTS.md**. Read it first.

@AGENTS.md

## Claude-specific notes

### Skills in this repo — two different things

| Folder | Audience | Loaded by |
|---|---|---|
| `.claude/skills/` | You, working **on** ALMFx | Claude Code, automatically, in this repo |
| `plugins/almfx/skills/` | End users doing SPFx ALM **with** ALMFx | `/plugin install almfx@almfx` after `/plugin marketplace add marat-365/ALMFx` |

When asked to "add a skill", ask which of the two is meant. Product skills must
not reference this repo's build system, file paths, or contributor workflow.

### Working here

- `.claude/skills/pnp-reference/` exists because cmdlet hallucination is the
  single most common failure mode in this domain. Use it before writing any
  PnP.PowerShell call.
- Prefer `Task`/`TaskUpdate` tracking for multi-shape changes (a feature often
  touches the module, a script, a skill, and docs).
- This repo is Windows-first for its users. Paths in docs and examples use
  Windows conventions; scripts themselves stay cross-platform (PS 7).
- There is no tenant available in CI or in your sandbox. Never write a test or
  a verification step that requires one.

### When changing behaviour, sweep all shapes

A change to an ALM operation usually needs updates in more than one place:
module function → standalone script → skill instructions → docs → changelog.
Check each before reporting completion; say explicitly which ones you touched.
