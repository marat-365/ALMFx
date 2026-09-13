---
applyTo: "docs/**/*.md,README.md,*.md"
---
# Documentation instructions

- Audience is a SharePoint/M365 developer or admin on Windows. Use PowerShell
  examples they can paste into an elevated PowerShell 7 prompt.
- Placeholders are always `contoso`: `https://contoso.sharepoint.com`,
  `https://contoso.sharepoint.com/sites/appcatalog`.
- Every code fence is tagged (```powershell, ```json, ```bash).
- Link to official docs (Microsoft Learn, pnp.github.io) rather than restating
  vendor behaviour that may change.
- Do not document a parameter or cmdlet that does not exist in the code yet;
  mark planned work as "Planned" in `docs/roadmap.md` instead.
