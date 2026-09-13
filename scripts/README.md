# Standalone scripts

Single-file PowerShell scripts for people who cannot or will not install a
module — locked-down admin workstations, one-off remediation, pipeline steps.

## Rules

- Runs with no `Import-Module ALMFx`. If it needs PnP.PowerShell, say so in
  `#Requires` and fail with a clear message if it is missing.
- `#Requires -Version 7.4` at the top, then comment-based help, then `param()`.
- `[CmdletBinding()]`, and `SupportsShouldProcess` for anything that mutates a
  tenant.
- Outputs objects; a `-CsvPath` style export parameter is fine, `Write-Host`
  for data is not.
- Same safety rules as the module: no tenant names, no secrets, `-WhatIf` first.

Where a script and a module function do the same thing, the module is the source
of truth and the script should be generated from it at build time rather than
maintained by hand.
