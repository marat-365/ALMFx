---
name: vscode-extension
description: Use when adding, scaffolding, or modifying the VS Code extension under src/vscode/almfx - new commands, views, settings, or activation events. Trigger on "VS Code extension", "add a command", "tree view", "package.json contributes", "vsce".
---

# VS Code extensions in ALMFx

One extension:

```
src/vscode/almfx/
├── package.json            Commands, settings, activation
├── tsconfig.json           strict: true
└── src/extension.ts        activate() / deactivate()
```

Nothing is published yet, so a second extension can still be split out cheaply
if the ALM and provisioning audiences turn out to want different things. Do that
only with an ADR, and put shared TypeScript in `src/vscode/shared/` at the same
time. See `docs/adr/0001-record-architecture-decisions.md`.

Domain knowledge - what a command should actually do - is in
`docs/reference/spfx-alm/`. Do not restate it in extension copy or comments.

## Adding a command

1. Declare it in `package.json` → `contributes.commands`
   (`almfx.deployPackage`, title in Title Case).
2. Register it in `activate()` and push the disposable onto
   `context.subscriptions`.
3. Leave `activationEvents` empty. Since VS Code 1.74 an `onCommand` event is
   generated automatically for every command in `contributes.commands`, so
   listing them again is redundant. **Never `"*"`** - CI fails the build on it.
4. Add `contributes.menus` entries if it belongs in a context menu, with a
   `when` clause narrow enough not to appear everywhere.
5. Document the command in the extension's `README.md`.

## Rules

- `strict: true`. No `any` without a comment justifying it.
- Anything touching a tenant: `vscode.window.withProgress({ cancellable: true })`,
  and actually honour the `CancellationToken`.
- Secrets go in `context.secrets` (`SecretStorage`). Never `globalState`,
  `workspaceState`, or settings.
- Settings keys: `almfx.<setting>`, declared in `contributes.configuration`
  with a `markdownDescription`.
- Diagnostics go to a named `OutputChannel`, not `console.log`.
- Destructive operations get a `showWarningMessage` modal confirmation naming
  the target site or tenant.

## Shelling out

If the extension invokes PowerShell or CLI for Microsoft 365, use
`child_process.spawn` with an **argument array** — never string concatenation.
Interpolated site URLs and file paths are user input.

## Prior art

`pnp/vscode-viva` (SPFx Toolkit, MIT) solves many of the same problems. Reading
it is encouraged; copying from it means keeping its copyright header and adding
an entry to `THIRD-PARTY-NOTICES.md`.
