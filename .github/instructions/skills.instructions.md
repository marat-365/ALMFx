---
applyTo: "plugins/**/SKILL.md,.claude/skills/**/SKILL.md,plugins/**/*.md"
---
# Skill authoring instructions

- Every `SKILL.md` starts with YAML frontmatter:
  ```yaml
  ---
  name: kebab-case-name          # must match the folder name
  description: Use when ...      # third person, names the triggers explicitly
  ---
  ```
- `description` is the *only* thing an agent sees before loading the skill.
  Write it as concrete triggers ("Use when deploying an .sppkg…, when an app
  shows as 'requires upgrade'…"), not as a topic label. It must open with
  `Use when`, `Use before`, or `Use after` — an anticipatory skill ("use before
  writing any PnP call") has a different trigger shape from a reactive one, and
  forcing it into "Use when" wording makes it trigger worse, not better.
  `tests/Pester/Repository.Tests.ps1` enforces this.
- Keep `SKILL.md` focused and under ~500 lines. Long reference material goes in
  sibling files (`reference.md`, `cmdlets.md`) that the skill points to.
- **Domain facts do not go in skills.** Cmdlet names, procedures, and failure
  modes live in `docs/reference/spfx-alm/`; a skill links to them. A skill that
  restates them creates a second copy that will drift.
- Two audiences, do not mix:
  - `plugins/almfx/skills/` — shipped to users. Empty until ALMFx has a surface
    worth driving. Must not mention this repo's build system, contributor
    workflow, or internal paths.
  - `.claude/skills/` — for agents working on this repository.
- State prerequisites explicitly (required module versions, permissions, roles
  such as SharePoint Administrator).
- Every destructive step must tell the agent to confirm with the user first and
  to show a dry run where one exists.
- Never assert a cmdlet, parameter, or CLI flag exists unless it is verified;
  link to the vendor documentation for anything non-obvious.
