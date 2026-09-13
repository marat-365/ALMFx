---
applyTo: "**/*.ps1,**/*.psm1,**/*.psd1"
---
# PowerShell instructions

- Target PowerShell 7.4+ (matches PnP.PowerShell v3). Cross-platform: no
  `[System.Windows.Forms]`, no COM, no registry unless guarded and documented.
- One function per file. Public functions in
  `src/powershell/ALMFx/Public/Verb-ALMFxNoun.ps1`, helpers in `Private/`.
  `ALMFx.psm1` dot-sources both and exports only `Public/`.
- Approved verbs only (`Get-Verb`). Every noun is prefixed `ALMFx`.
- Required on every public function:
  - `[CmdletBinding()]` (add `SupportsShouldProcess` + `ConfirmImpact='High'`
    for anything that writes to or removes from a tenant)
  - `[OutputType([...])]`
  - Comment-based help: `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER` for each
    parameter, at least one `.EXAMPLE`, `.NOTES`, `.LINK`
  - Typed parameters with `[Parameter()]` attributes; use
    `[ValidateNotNullOrEmpty()]` / `[ValidateSet()]` rather than manual checks
- Pipeline-friendly: `ValueFromPipeline` / `ValueFromPipelineByPropertyName` and
  `begin`/`process`/`end` where it makes sense.
- Output objects (`[PSCustomObject]` or a class in `Classes/`). Never
  `Write-Host`. Use `Write-Verbose`, `Write-Warning`, `Write-Progress`,
  and `$PSCmdlet.ThrowTerminatingError()` for fatal errors.
- Never swallow errors with `-ErrorAction SilentlyContinue` without handling.
- Connection handling: accept an optional `-Connection` (PnP connection object)
  parameter and pass it through, rather than relying on ambient connection state.
- No hardcoded tenant names, site URLs, client IDs, certificates, or secrets.
- Must pass `Invoke-ScriptAnalyzer -Settings ./PSScriptAnalyzerSettings.psd1`.
- Scripts in `scripts/` must run without the module installed: `#Requires` at
  the top, `[CmdletBinding()]`, `param()` first, and a comment-based help block.
