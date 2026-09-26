# CLAUDE.md

All shared repository rules, domain conventions, skills distinction,
multi-shape sweep requirements, and GitHub PR permissions live in
**[`AGENTS.md`](AGENTS.md)** at the repo root. Read it first.

@AGENTS.md

## Claude-specific notes

Content here is Claude Code-specific — things another agent's tooling
(Copilot, Codex, Cursor) wouldn't have or wouldn't understand. Everything
that applies to every agent belongs in `AGENTS.md` instead; do not duplicate
it here, or the two will drift.

- **PS 5.1 + 7.4 support is intentional, not a bug to "fix" back to 7.4-only.**
  See AGENTS.md's PowerShell conventions and ADR 0001. Many target admins run
  Windows PowerShell 5.1 on locked-down machines; do not flag dual-version
  support itself as a problem in review — only flag it if a function claims 5.1
  compatibility but actually uses a 7-only API without a documented fallback.
- Prefer `Task`/`TaskUpdate` tracking for multi-shape changes (a feature often
  touches the module, a script, a skill, and docs) and for any change with more
  than a couple of sequential phases.
- Read `docs/reference/spfx-alm/cmdlets.md` before writing any PnP.PowerShell
  call — `.claude/skills/pnp-reference/` points at it, but the file itself
  carries the verification method and the verified list.
