# Distributable plugins

Everything here is **shipped to users**. Install with:

```
/plugin marketplace add marat-365/ALMFx
/plugin install almfx@almfx
```

The marketplace manifest is `.claude-plugin/marketplace.json` at the repository
root; each plugin has its own `.claude-plugin/plugin.json`.

## Rules for skills in `almfx/skills/`

- They run in the **user's** repo against the **user's** tenant. They must never
  reference ALMFx's own build system, contributor workflow, or internal paths.
- Prerequisites (module versions, tenant roles) stated up front.
- Every destructive step tells the agent to confirm with the user and to show
  the read-only equivalent first.
- Every cmdlet verified against the PnP documentation — see
  `.claude/skills/pnp-reference/`.

Authoring conventions: `.claude/skills/skill-authoring/SKILL.md`.

## Current skills

| Skill | Covers |
|---|---|
| `spfx-package-deploy` | Upload, publish, install, tenant-wide deployment |
| `spfx-app-upgrade` | Version drift, rollout across sites, rollback |
| `spfx-tenant-inventory` | Read-only audit of what is deployed where |
| `spfx-api-permissions` | Pending permission requests, grants, the shared principal problem |
| `spfx-alm-troubleshoot` | Failure triage in likelihood order |
| `pnp-provisioning` | Extracting and applying site templates |
| `spfx-release-pipeline` | CI/CD, app-only auth, promotion, rollback artefacts |

## Candidates, not yet written

- `almfx-powershell` — driving the ALMFx module itself (write once the module
  has a real surface)
- `spfx-project-upgrade` — moving a solution between SPFx versions
- `spfx-governance` — naming, review, and approval policy for app catalogs
- `teams-app-lifecycle` — SPFx solutions surfaced as Teams apps (`Sync-PnPAppToTeams`)
- `spfx-scaffold` — creating a new solution with the right options first time
