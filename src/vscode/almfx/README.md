# ALMFx — VS Code extension

Application lifecycle management for SharePoint Framework solutions and PnP
provisioning, from the editor.

## What works today

| Command | Does |
|---|---|
| `ALMFx: Show Version` | Reports the extension version. A placeholder that proves activation, command registration, disposal, and output-channel wiring. |
| `ALMFx: Build SPFx Environment` | Runs `New-SPFxEnvironment` interactively: pick the solution folder, type an environment name, choose whether to generate unique GUIDs/names. |
| `ALMFx: Deploy SPFx Environment` | Runs `Set-SPFxEnvironment` interactively: pick the solution folder, pick a previously-built `.<environment>/` (or type a new name), confirm, deploy. |

Both commands shell out to PowerShell (`pwsh`, automatically falling back to
Windows PowerShell 5.1's `powershell.exe` if `pwsh` isn't on `PATH`) to run
the real module functions — see `docs/powershell/index.md` for what those functions actually
do. Progress and results stream to the **ALMFx** output channel and a
progress notification; the run can be cancelled from that notification.

### Module resolution

By default the commands look for `ALMFx.psd1` next to this extension's own
source (works when developing this extension from a checkout of this
repository), then fall back to an `ALMFx` module already installed from the
PowerShell Gallery. Set `almfx.modulePath` to point at a specific manifest
if neither applies to you.

## Settings

| Setting | Default | Meaning |
|---|---|---|
| `almfx.tenantUrl` | `""` | SharePoint Online tenant URL, e.g. `https://contoso.sharepoint.com`. Blank prompts. |
| `almfx.modulePath` | `""` | Path to `ALMFx.psd1`. Blank auto-detects a local checkout, then falls back to an installed module. |
| `almfx.powershellPath` | `""` | Path to the PowerShell executable. Blank uses `pwsh`/`pwsh.exe` from `PATH`. |

## Development

```powershell
cd src/vscode/almfx
npm install
npm run compile
```

Press <kbd>F5</kbd> in VS Code to launch an Extension Development Host.

Conventions are in [`.github/instructions/typescript.instructions.md`](../../../.github/instructions/typescript.instructions.md)
and [`.claude/skills/vscode-extension/SKILL.md`](../../../.claude/skills/vscode-extension/SKILL.md).

Domain knowledge — what these commands will eventually automate — is in
[`docs/reference/spfx-alm/`](../../../docs/reference/spfx-alm/). Do not restate it here.

## Activation

`activationEvents` is deliberately empty. Since VS Code 1.74 an `onCommand`
event is generated automatically for every command in `contributes.commands`,
so listing them again is redundant. Never use `"*"`.
