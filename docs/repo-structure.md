# Repository structure

ALMFx is a **polyglot monorepo**: one domain (SPFx ALM + PnP provisioning),
several distribution formats. The rule that keeps it sane is *domain logic lives
in one place per concern; the formats are wrappers.*

```
ALMFx/
├── AGENTS.md                  Canonical agent rules (edit this first)
├── CLAUDE.md                  Imports AGENTS.md + Claude-specific notes
├── README.md  CONTRIBUTING.md  SECURITY.md  CHANGELOG.md
├── LICENSE  THIRD-PARTY-NOTICES.md
│
├── .github/
│   ├── copilot-instructions.md    Copilot Chat / code review
│   ├── instructions/              Path-scoped rules (applyTo frontmatter)
│   ├── prompts/                   Reusable Copilot prompt files
│   ├── workflows/                 CI
│   ├── ISSUE_TEMPLATE/
│   └── dependabot.yml
│
├── .claude/
│   ├── settings.json              Shared Claude Code settings (committed)
│   └── skills/                    Skills for working ON this repo
│
├── .claude-plugin/
│   └── marketplace.json           Makes this repo a Claude plugin marketplace
├── plugins/
│   └── almfx/                     The plugin users install
│       ├── .claude-plugin/plugin.json
│       └── skills/                Skills shipped TO users
│
├── src/
│   ├── powershell/ALMFx/
│   │   ├── ALMFx.psd1             Manifest (version, exports, dependencies)
│   │   ├── ALMFx.psm1             Loader: dot-sources Public/ + Private/
│   │   ├── Public/                One exported function per file
│   │   ├── Private/               Internal helpers, not exported
│   │   ├── Classes/               PowerShell classes / output types
│   │   └── en-US/                 about_* help topics
│   └── vscode/
│       ├── shared/                TypeScript shared by extensions
│       ├── almfx-spfx-alm/        Extension: ALM operations
│       └── almfx-provisioning/    Extension: PnP provisioning authoring
│
├── scripts/                       Standalone .ps1, no module install needed
├── tests/Pester/                  Pester 5 tests, all network mocked
├── build/                         Invoke-Build.ps1, Install-Dependencies.ps1
├── docs/                          Documentation
└── samples/                       Example templates, configs, pipelines
```

## Why this shape

**`src/` split by language, not by feature.** Toolchains do not mix: PowerShell
needs a module manifest at a predictable path, npm needs a `package.json` at the
workspace root of each extension. Trying to co-locate a cmdlet and its VS Code
command in one folder fights both.

**`scripts/` is separate from the module.** A standalone script and a module
function have different constraints (the script cannot assume the module is
installed). Keeping them apart makes the duplication visible instead of
accidental. Where logic is genuinely shared, generate the script from the module
source at build time rather than maintaining two copies.

**Skills are split by audience, not by topic.** `.claude/skills/` is loaded
automatically when you open this repo and is about *contributing*.
`plugins/almfx/skills/` is packaged and installed by users and is about *doing
SPFx ALM*. A product skill that mentions `Invoke-Build.ps1` is a bug.

**Two VS Code extensions, one shared library.** The SPFx ALM audience (admins
deploying packages) and the provisioning audience (makers authoring templates)
overlap but are not the same. Starting with two thin extensions over
`src/vscode/shared/` keeps the option open; merging later is cheap, splitting a
shipped extension is not. Decide before the first Marketplace publish.

**One version per format.** The PowerShell module, each extension, and the
plugin version independently. `CHANGELOG.md` notes which format an entry affects.

## Adding a new format later

`d) maybe other formats in the future` — e.g. an MCP server, a GitHub Action, an
Azure DevOps task, a dotnet tool. Each gets a top-level home
(`src/mcp/`, `actions/`, `src/dotnet/`), reuses the domain rules from
`AGENTS.md`, and gets its own CI workflow and version stream. Do not add a
format until there is a concrete user for it.
