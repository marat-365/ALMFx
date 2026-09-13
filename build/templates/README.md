# Templates

Starting points, copied by hand or by a skill. Deliberately **outside** the
module tree: on Windows, `Get-ChildItem -Filter '*.ps1'` can match
`*.ps1.template` through 8.3 short-name semantics, so a template living in
`src/powershell/ALMFx/Public/` would be dot-sourced at import time and leak into
`FunctionsToExport`. Do not move these back.

| File | Use |
|---|---|
| `Function.ps1.txt` | New public ALMFx function — see `.claude/skills/new-cmdlet/` |
