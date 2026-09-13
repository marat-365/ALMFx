---
name: skill-authoring
description: Use when writing or editing any SKILL.md in this repo, in either plugins/almfx/skills (shipped to users) or .claude/skills (for working on this repo). Covers frontmatter, description writing, the audience split, and safety rules for tenant-mutating steps. Trigger on "add a skill", "write a skill", "the skill isn't triggering".
---

# Authoring skills in ALMFx

## First: which audience?

| | `plugins/almfx/skills/` | `.claude/skills/` |
|---|---|---|
| Who | Users doing SPFx ALM in **their** repo | Agents working **on** ALMFx |
| Ships? | Yes, via the plugin marketplace | No, repo-local |
| May mention `Invoke-Build.ps1`? | **No** | Yes |
| May assume ALMFx is installed? | State it as a prerequisite | Yes |

A product skill that references this repository's build system or file paths is
a bug. Ask which one is meant if it is not obvious.

`plugins/almfx/skills/` is deliberately empty right now — ALMFx has no cmdlets or
extension commands yet worth writing a skill around. See
`plugins/almfx/skills/README.md` before adding the first one.

## Domain facts do not live in skills

Cmdlet names, procedures, and failure modes belong in
[`docs/reference/spfx-alm/`](../../../docs/reference/spfx-alm/), written once.
A skill **links** to the relevant reference page; it does not restate cmdlet
signatures, version-bump rules, or troubleshooting steps. A skill that
duplicates a fact from the reference is the exact drift this rule exists to
prevent — two copies of "how `Update-PnPApp` works" will eventually disagree,
and nothing will tell you which one is stale.

## Frontmatter

```yaml
---
name: kebab-case-matching-the-folder
description: Use when <concrete trigger>, <concrete trigger>. <What it does.> Trigger on "<phrase a user would type>".
---
```

The `description` is the only thing an agent sees before deciding to load the
skill. Write **triggers**, not a topic:

- Bad: `description: SPFx deployment.`
- Good: `description: Use when deploying an .sppkg to a tenant or site collection app catalog, when an app shows "requires upgrade", or when a deployment fails with a pending API permission request.`

Include the literal words users type — cmdlet names, error text, file
extensions (`.sppkg`, `package-solution.json`, "tenant-wide deployment").

## Body

- Under ~500 lines. Push long reference material into sibling files
  (`reference.md`, `cmdlets.md`) and link to them from `SKILL.md`.
- Lead with prerequisites: required modules and versions, required roles
  (SharePoint Administrator, site collection admin, app catalog owner).
- Give the happy path first, then failure modes. Failure modes are where the
  value is in this domain.
- Concrete commands, not prose descriptions of commands.

## Safety rules (non-negotiable for product skills)

- Every step that deploys, retracts, removes, overwrites, or grants permissions
  must instruct the agent to **confirm with the user first** and to show the
  read-only equivalent (`Get-PnPApp`, `-WhatIf`) before the write.
- Never put a real tenant name in an example. Use `contoso`.
- Never instruct an agent to store a client secret or certificate password in a
  file or environment variable it also commits.
- Distinguish production from dev tenants explicitly where the blast radius
  differs.

## Accuracy

Verify every cmdlet, parameter, and CLI flag against
[`docs/reference/spfx-alm/cmdlets.md`](../../../docs/reference/spfx-alm/cmdlets.md)
— see `.claude/skills/pnp-reference/` for the verification method if the cmdlet
you need is not already listed there. A skill that confidently tells an agent to
run a cmdlet that does not exist is worse than no skill.
