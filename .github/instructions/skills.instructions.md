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
  shows as 'requires upgrade'…"), not as a topic label.
- Keep `SKILL.md` focused and under ~500 lines. Long reference material goes in
  sibling files (`reference.md`, `cmdlets.md`) that the skill points to.
- Two audiences, do not mix:
  - `plugins/almfx/skills/` — shipped to users. Must not mention this repo's
    build system, contributor workflow, or internal paths.
  - `.claude/skills/` — for agents working on this repository.
- State prerequisites explicitly (required module versions, permissions, roles
  such as SharePoint Administrator).
- Every destructive step must tell the agent to confirm with the user first and
  to show a dry run where one exists.
- Never assert a cmdlet, parameter, or CLI flag exists unless it is verified;
  link to the vendor documentation for anything non-obvious.
