# GitHub Copilot — repository instructions

The full, canonical rules for this repository are in **[`AGENTS.md`](../AGENTS.md)**
at the repo root. Copilot coding agent reads `AGENTS.md` directly; this file
exists for Copilot Chat and Copilot code review. Keep the two in sync — edit
`AGENTS.md` first.

## Summary

ALMFx is a multi-format toolkit for SharePoint Framework (SPFx) Application
Lifecycle Management and PnP provisioning: a PowerShell module
(`src/powershell/ALMFx/`), standalone scripts (`scripts/`), VS Code extensions
(`src/vscode/`), and downloadable agent skills (`plugins/almfx/skills/`).

## Non-negotiables

- Never invent a PnP.PowerShell, CLI for Microsoft 365, or SPFx command.
  Verify it exists before suggesting it.
- Destructive tenant operations require `SupportsShouldProcess` / explicit
  confirmation.
- No tenant names, site URLs, secrets, or tokens in code, tests, or samples —
  use `contoso` placeholders.
- PowerShell 7.4+, approved verbs, `ALMFx` noun prefix, one function per file,
  comment-based help with an example, objects out (never `Write-Host`).
- TypeScript strict; lazy extension activation.
- Conventional Commits (`feat(powershell): …`), update `CHANGELOG.md`.
- Tests are Pester 5 with all network calls mocked. No test may hit a tenant.

Path-specific rules live in [`.github/instructions/`](instructions/).
