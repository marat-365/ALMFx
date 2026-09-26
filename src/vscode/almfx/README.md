# ALMFx — VS Code extension

> Scaffold only. No ALM functionality yet.

Application lifecycle management for SharePoint Framework solutions and PnP
provisioning, from the editor.

## What works today

| Command | Does |
|---|---|
| `ALMFx: Show Version` | Reports the extension version. A placeholder that proves activation, command registration, disposal, and output-channel wiring. |

## Settings

| Setting | Default | Meaning |
|---|---|---|
| `almfx.tenantUrl` | `""` | SharePoint Online tenant URL, e.g. `https://contoso.sharepoint.com`. Blank prompts. |

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
