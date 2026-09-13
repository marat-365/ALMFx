# VS Code extensions

Not yet scaffolded. Intended layout:

```
src/vscode/
├── shared/                 Domain logic shared by both extensions.
│                           Keep vscode API imports out of pure-domain modules
│                           so they stay unit-testable.
├── almfx-spfx-alm/         ALM operations: deploy, upgrade, inventory
└── almfx-provisioning/     PnP provisioning template authoring
```

Each extension gets its own `package.json`, `tsconfig.json`, `CHANGELOG.md`,
`README.md`, and version stream. Wire them together with npm workspaces from the
repository root when the first one is scaffolded.

## Open decision

Two extensions or one? The audiences (admins deploying packages, makers
authoring templates) overlap but are not identical. Two thin extensions over a
shared library keeps the option open. **Decide before the first Marketplace
publish** — merging is cheap, splitting a published extension is not. Record the
decision in `docs/adr/`.

## Prior art

`pnp/vscode-viva` — the SPFx Toolkit, MIT licensed, Microsoft 365 Community.
Worth reading before designing anything here. It already covers scaffolding,
project upgrade, and environment views; ALMFx should complement it rather than
duplicate it. Deliberately overlapping is a decision that belongs in an ADR.

Rules: `.github/instructions/typescript.instructions.md`,
`.claude/skills/vscode-extension/SKILL.md`.
