# Changelog — ALMFx VS Code extension

Versioned independently of the PowerShell module. See the repository root
`CHANGELOG.md` for how the version streams relate.

## [Unreleased]

### Added
- Extension scaffold: activation, command registration, output channel, and one
  placeholder command (`ALMFx: Show Version`). No ALM functionality yet.
- `ALMFx: Build SPFx Environment` and `ALMFx: Deploy SPFx Environment` —
  run `New-SPFxEnvironment`/`Set-SPFxEnvironment` interactively (folder
  picker, environment name input with validation, a QuickPick for
  `-CreateUniqueNames` that pre-selects the same prod/production-aware
  default the function itself uses, and a QuickPick of already-built
  `.<environment>/` folders for the deploy command). Runs via `pwsh`,
  falling back to Windows PowerShell 5.1's `powershell.exe` if `pwsh` isn't
  on `PATH` (or a configured `almfx.powershellPath`), spawned with an
  argument array — user input is never interpolated into a command string.
  Progress and results go to the `ALMFx` output channel and a cancellable
  progress notification. New settings `almfx.modulePath` and
  `almfx.powershellPath`.
