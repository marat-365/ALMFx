# spfx-sample-app

## Purpose

`spfx-sample-app` is a real SharePoint Framework fixture for ALMFx contributors.
It gives the repository a buildable multi-component `.sppkg` that can be used to
exercise local ALM workflows such as packaging, inventory parsing, upgrade
scenarios, and future `Add-PnPApp` / `Get-PnPApp`-style cmdlet development
without connecting to a live tenant.

This solution was generated with the official Microsoft 365 SPFx Yeoman
generator and intentionally keeps all SharePoint references offline-friendly
(`{tenantDomain}` placeholders in serve config, no real tenant URLs).

## Included artifacts

| Artifact | SPFx type | Generated source folder | Notes |
|---|---|---|---|
| `HelloWorldWebPart` | React web part | `src\webparts\helloWorld` | Generated from component name `HelloWorld` |
| `HeaderFooterApplicationCustomizer` | Application Customizer | `src\extensions\headerFooter` | Simulates header/footer injection |
| `ColorCodedFieldCustomizer` | React Field Customizer | `src\extensions\colorCoded` | Simulates colored field rendering |
| `ItemActionsCommandSet` | ListView Command Set | `src\extensions\itemActions` | Simulates list item commands |
| `SharedUtilitiesLibrary` | Library | `src\libraries\sharedUtilities` | Reusable non-UI component |
| `SampleCardAdaptiveCardExtension` | Adaptive Card Extension | `src\adaptiveCardExtensions\sampleCard` | Generator-equivalent name for the requested sample ACE |

## Reproducible toolchain

- Node.js: `v22.23.2`
- npm: `10.9.8`
- Yeoman launcher: `yo` via `npx`
- SPFx generator: `@microsoft/generator-sharepoint@1.23.2`
- Solution scaffolding mode: legacy Gulp tooling (`--use-gulp`)

## Build and package

Run these commands from `testplaygrounds\spfx-sample-app` in PowerShell 7:

```powershell
npm install
npx gulp bundle
npx gulp bundle --ship
npx gulp package-solution --ship
```

For official SPFx build background, see Microsoft Learn:

- [SharePoint Framework overview](https://learn.microsoft.com/sharepoint/dev/spfx/sharepoint-framework-overview)
- [Build and package a SharePoint Framework solution](https://learn.microsoft.com/sharepoint/dev/spfx/web-parts/get-started/build-a-hello-world-web-part)
- [Build your first Adaptive Card Extension](https://learn.microsoft.com/sharepoint/dev/spfx/viva/get-started/build-first-sharepoint-adaptive-card-extension)

## Notes for ALMFx contributors

- Build outputs such as `node_modules\`, `temp\`, `release\`, and
  `sharepoint\solution\*.sppkg` are intentionally not committed; the repository
  root `.gitignore` already excludes them.
- `sharepoint\solution\spfx-sample-app.sppkg` is the primary offline fixture for
  packaging and app-catalog-oriented ALM experiments.
- The generated components keep their stock sample behavior on purpose so ALMFx
  can validate against realistic SPFx manifests, XML assets, client-side
  bundles, and localized resources.
