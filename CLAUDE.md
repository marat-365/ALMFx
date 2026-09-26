# CLAUDE.md

All shared repository rules live in **AGENTS.md**. Read it first.

@AGENTS.md

## Claude-specific notes

### Three places knowledge can go — keep them separate

| Folder | Audience | Contains | State |
|---|---|---|---|
| `docs/reference/spfx-alm/` | Anyone | **Domain facts.** Cmdlets, procedures, failure modes | The single source of truth |
| `.claude/skills/` | You, working **on** ALMFx | How to contribute here | 5 skills |
| `plugins/almfx/skills/` | End users doing SPFx ALM **with** ALMFx | How to drive ALMFx | **Empty on purpose** |

When asked to "add a skill", ask which of the two skill folders is meant — and
first ask whether it is a skill at all. If the content is a fact about SPFx or
PnP rather than a procedure for using something, it belongs in
`docs/reference/spfx-alm/` and both skill folders should link to it.

Product skills must not reference this repo's build system, file paths, or
contributor workflow. `tests/Pester/Repository.Tests.ps1` enforces that.

Shipped skills stay empty until ALMFx has cmdlets or extension commands worth
driving. A skill that says "run `Add-PnPApp`" does not earn its place — the user
did not need ALMFx for that.

### Working here

- Read `docs/reference/spfx-alm/cmdlets.md` before writing any PnP.PowerShell
  call. Cmdlet hallucination is the single most common failure mode in this
  domain, and that file carries both the verification method and the verified
  list. `.claude/skills/pnp-reference/` points at it.
- Prefer `Task`/`TaskUpdate` tracking for multi-shape changes (a feature often
  touches the module, a script, a skill, and docs).
- This repo is Windows-first for its users. Paths in docs and examples use
  Windows conventions.
- **PS 5.1 + 7.4 support is intentional, not a bug to "fix" back to 7.4-only.**
  See AGENTS.md's PowerShell conventions and ADR 0001. Many target admins run
  Windows PowerShell 5.1 on locked-down machines; do not flag dual-version
  support itself as a problem in review — only flag it if a function claims 5.1
  compatibility but actually uses a 7-only API without a documented fallback.
- There is no tenant available in CI or in your sandbox. Never write a test or
  a verification step that requires one.

### When changing behaviour, sweep all shapes

A change to an ALM operation usually needs updates in more than one place:
module function → standalone script → skill instructions → docs → changelog.
Check each before reporting completion; say explicitly which ones you touched.
