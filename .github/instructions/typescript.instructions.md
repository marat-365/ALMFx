---
applyTo: "src/vscode/**/*.ts,src/vscode/**/*.tsx"
---
# VS Code extension instructions

- TypeScript `strict: true`. No `any` without an adjacent comment saying why.
- Prefer an empty `activationEvents` array: since VS Code 1.74 an `onCommand`
  event is generated automatically for each command in `contributes.commands`.
  Add explicit entries only for events that cannot be inferred
  (`onLanguage:`, `workspaceContains:`). Never `"*"` - CI fails on it.
- All commands declared in `package.json#contributes.commands` must be
  registered in `activate()` and pushed onto `context.subscriptions`.
- Any tenant/network call: `vscode.window.withProgress` with
  `cancellable: true`, and honour the `CancellationToken`.
- User-facing errors go through `vscode.window.showErrorMessage`; diagnostics go
  to a dedicated `OutputChannel`. Never `console.log` in shipped code paths.
- Secrets (tokens, client secrets, certificates) use `context.secrets`
  (`SecretStorage`) — never `globalState`, `workspaceState`, or settings.
- Settings keys are namespaced `almfx.<setting>` and documented in
  `contributes.configuration` with a `markdownDescription`.
- There is one extension (`src/vscode/almfx/`). If a second is ever added,
  shared logic goes in `src/vscode/shared/` — never copy-pasted between them.
- Domain facts about SPFx, PnP, or app catalogs belong in
  `docs/reference/spfx-alm/`, not in extension copy, comments, or README text.
- If the extension shells out to PowerShell or CLI for Microsoft 365, quote all
  interpolated user input and prefer argument arrays over string concatenation.
