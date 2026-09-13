# Shipped skills — intentionally empty

Nothing ships here yet, and that is deliberate.

A skill in this folder is installed by users and is meant to help them do SPFx
ALM **with ALMFx**. ALMFx does not do anything yet: the PowerShell module is a
skeleton and the VS Code extension is a scaffold. A skill written now could only
restate general SPFx and PnP knowledge, which would ship a plugin that never
mentions the product it is named after.

That general knowledge lives in [`docs/reference/spfx-alm/`](../../../docs/reference/spfx-alm/)
instead, as the repository's single source of truth.

## When to add the first skill

When ALMFx has cmdlets or extension commands that are genuinely easier to drive
with guidance than without. A skill that says "run `Deploy-ALMFxPackage -Path …`"
earns its place; a skill that says "run `Add-PnPApp`" does not — the user did not
need ALMFx for that.

## How to add one

1. Read `.claude/skills/skill-authoring/SKILL.md` for the conventions.
2. Create `plugins/almfx/skills/<kebab-case-name>/SKILL.md`.
3. Link to `docs/reference/spfx-alm/` rather than restating domain facts.
4. `tests/Pester/Repository.Tests.ps1` validates frontmatter, naming, and that
   no contributor-workflow detail leaks into a shipped skill.

Do not reference this repo's build system, file paths, or contributor workflow —
these run in the user's repository, not this one.

## Candidates

- `almfx-powershell` — driving the ALMFx module
- `spfx-project-upgrade` — moving a solution between SPFx versions
- `spfx-governance` — naming, review, and approval policy for app catalogs
- `teams-app-lifecycle` — SPFx solutions surfaced as Teams apps
