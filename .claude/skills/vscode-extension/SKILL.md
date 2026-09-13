---
name: vscode-extension
description: Use when adding, scaffolding, or modifying a VS Code extension under src/vscode - new commands, views, settings, activation events, or shared code between the two extensions. Trigger on "VS Code extension", "add a command", "tree view", "package.json contributes", "vsce".
---

# VS Code extensions in ALMFx

Two extensions over one shared library:

```
src/vscode/
├── shared/                 TypeScript used by both. No vscode API imports
│                           in pure-domain modules - keep them testable.
├── almfx-spfx-alm/         ALM operations: deploy, upgrade, inventory
└── almfx-provisioning/     PnP provisioning template authoring
```

**The split is provisional.** The audiences (admins deploying packages vs makers
authoring templates) overlap. Merging two extensions later is cheap; splitting a
published one is not. Revisit before the first Marketplace publish, and record
the decision in `docs/adr/`.

## Adding a command

1. Declare it in `package.json` → `contributes.commands`
   (`almfx.spfxAlm.deployPackage`, title in Title Case).
2. Register it in `activate()` and push the disposable onto
   `context.subscriptions`.
3. Add a matching `activationEvents` entry (`onCommand:almfx.spfxAlm.deployPackage`).
   **Never `"*"`.**
4. Add `contributes.menus` entries if it belongs in a context menu, with a
   `when` clause narrow enough not to appear everywhere.
5. Document the command in the extension's `README.md`.

## Rules

- `strict: true`. No `any` without a comment justifying it.
- Anything touching a tenant: `vscode.window.withProgress({ cancellable: true })`,
  and actually honour the `CancellationToken`.
- Secrets go in `context.secrets` (`SecretStorage`). Never `globalState`,
  `workspaceState`, or settings.
- Settings keys: `almfx.<extension>.<setting>`, declared in
  `contributes.configuration` with a `description`.
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
