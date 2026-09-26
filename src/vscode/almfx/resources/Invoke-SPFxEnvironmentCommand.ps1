#Requires -Version 5.1
<#
    Bundled with the ALMFx VS Code extension. Not part of the ALMFx module -
    this is a thin, argv-only shim the extension spawns so that user input
    (Path, Environment) never has to be interpolated into a PowerShell
    command string. Every value below arrives as its own process argument;
    none of it is re-parsed as script text, so nothing here is a shell/
    PowerShell injection surface.

    Runs on PowerShell 5.1+ and 7+, matching New-SPFxEnvironment/
    Set-SPFxEnvironment themselves (both are pure filesystem/text
    operations with no PnP dependency).
#>
[CmdletBinding()]
param(
    # Explicit module manifest path, or $null/empty to fall back to
    # `Import-Module ALMFx` (an installed-from-Gallery module on $env:PSModulePath).
    [Parameter()]
    [string] $ModulePath,

    [Parameter(Mandatory)]
    [ValidateSet('New-SPFxEnvironment', 'Set-SPFxEnvironment')]
    [string] $FunctionName,

    [Parameter(Mandatory)]
    [string] $Path,

    [Parameter(Mandatory)]
    [string] $Environment,

    # Passed as a literal "True"/"False" string, not [bool]: PowerShell's
    # own [bool] cast treats any non-empty string (including "false") as
    # $true, so a naive [bool]$CreateUniqueNames parameter would silently
    # ignore an explicit "no". [System.Convert]::ToBoolean parses it
    # correctly instead.
    [Parameter()]
    [ValidateSet('True', 'False')]
    [string] $CreateUniqueNames,

    # Whether -CreateUniqueNames was set at all by the caller, vs. left for
    # New-SPFxEnvironment's own prod/production-aware default to decide.
    [switch] $CreateUniqueNamesSpecified
)

$ErrorActionPreference = 'Stop'

if ($ModulePath) {
    Import-Module -Name $ModulePath -Force -ErrorAction Stop
}
else {
    Import-Module -Name ALMFx -ErrorAction Stop
}

$functionParams = @{
    Path        = $Path
    Environment = $Environment
}
if ($CreateUniqueNamesSpecified) {
    $functionParams.CreateUniqueNames = [System.Convert]::ToBoolean($CreateUniqueNames)
}

$result = & $FunctionName @functionParams
$result | ConvertTo-Json -Depth 6
