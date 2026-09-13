---
applyTo: "src/vscode/**/*.ts,src/vscode/**/*.tsx"
---
# VS Code extension instructions

- TypeScript `strict: true`. No `any` without an adjacent comment saying why.
- Activation events must be specific (`onCommand:`, `onLanguage:`,
  `workspaceContains:`). Never `"*"`.
- All commands declared in `package.json#contributes.commands` must be
  registered in `activate()` and pushed onto `context.subscriptions`.
- Any tenant/network call: `vscode.window.withProgress` with
  `cancellable: true`, and honour the `CancellationToken`.
- User-facing errors go through `vscode.window.showErrorMessage`; diagnostics go
  to a dedicated `OutputChannel`. Never `console.log` in shipped code paths.
- Secrets (tokens, client secrets, certificates) use `context.secrets`
  (`SecretStorage`) — never `globalState`, `workspaceState`, or settings.
- Settings keys are namespaced `almfx.<extension>.<setting>` and documented in
  `contributes.configuration`.
- Shared logic between extensions belongs in `src/vscode/shared/`, imported as a
  workspace dependency — do not copy-paste between extensions.
- If the extension shells out to PowerShell or CLI for Microsoft 365, quote all
  interpolated user input and prefer argument arrays over string concatenation.
