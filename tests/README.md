# Tests

Pester 5. Run the suite:

```powershell
./build/Invoke-Build.ps1 -Task Test
```

## Rules

- **No test may touch a real tenant.** Mock every PnP and network call. CI has
  no credentials and never will.
- One test file per public function: `tests/Pester/<Verb>-ALMFx<Noun>.Tests.ps1`.
- Cover the happy path, at least one validation failure, and the `-WhatIf` path
  for anything that mutates.
- `Get-ALMFxVersion.Tests.ps1` also holds the module **contract** tests: every
  declared export resolves, and every exported function has comment-based help
  with an example. Do not delete those.
- Fixtures go in `tests/Fixtures/` with `contoso` placeholders only.
