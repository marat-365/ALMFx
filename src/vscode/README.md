# VS Code

One extension: [`almfx/`](almfx/). Scaffold only — activation, command
registration, an output channel, and one placeholder command. No ALM
functionality yet.

```
src/vscode/almfx/
├── package.json            Commands, settings, activation
├── tsconfig.json           strict: true
├── .eslintrc.json
└── src/extension.ts
```

## Why one and not two

The original plan was two extensions — ALM operations and provisioning authoring
— over a shared library. The audiences overlap enough that two empty extensions
was speculative structure. Nothing is published, so splitting later is still
cheap; do it with an ADR and add `src/vscode/shared/` at the same time. See
[`docs/adr/0001`](../../docs/adr/0001-record-architecture-decisions.md).

## Prior art

[`pnp/vscode-viva`](https://github.com/pnp/vscode-viva) — the SPFx Toolkit, MIT,
Microsoft 365 Community. Worth reading before designing anything here. It already
covers scaffolding, project upgrade, and environment views; ALMFx should
complement it rather than duplicate it. Deliberate overlap needs an ADR.

## Rules

- [`.github/instructions/typescript.instructions.md`](../../.github/instructions/typescript.instructions.md)
- [`.claude/skills/vscode-extension/SKILL.md`](../../.claude/skills/vscode-extension/SKILL.md)
- Domain facts go in [`docs/reference/spfx-alm/`](../../docs/reference/spfx-alm/),
  not in extension copy.
