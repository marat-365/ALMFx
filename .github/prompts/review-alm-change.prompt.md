---
mode: agent
description: Review a change for SPFx ALM safety and cross-shape consistency.
---
Review the current changes against `AGENTS.md` and report findings. Check:

- **Tenant safety** — does anything delete, retract, unpublish, or overwrite
  without `ShouldProcess`/confirmation? Is there a dry-run path?
- **Cmdlet reality** — is every PnP.PowerShell / CLI for Microsoft 365 / SPFx
  command used actually real, with the parameters as spelled?
- **Leakage** — any real tenant names, site URLs, GUIDs, tokens, or certificates
  in code, tests, fixtures, or docs?
- **Cross-shape drift** — the same operation may exist as a module function, a
  standalone script in `scripts/`, a VS Code command, and a skill. Did the change
  update all of the shapes it affects?
- **Contract** — comment-based help present and accurate, `FunctionsToExport`
  updated, Pester test added, `CHANGELOG.md` entry present.

Report findings most severe first. Do not fix anything unless I ask.
