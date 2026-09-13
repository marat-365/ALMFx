#Requires -Version 7.4
<#
.SYNOPSIS
    Installs the modules needed to build, analyse, and test ALMFx.

.DESCRIPTION
    Installs Pester 5 and PSScriptAnalyzer for the current user. PnP.PowerShell
    is optional here - it is only needed to run ALMFx against a real tenant, not
    to build or test it.

.PARAMETER IncludePnP
    Also install PnP.PowerShell 3.x.

.EXAMPLE
    ./build/Install-Dependencies.ps1
#>
[CmdletBinding()]
param(
    [Parameter()]
    [switch] $IncludePnP
)

$ErrorActionPreference = 'Stop'

$modules = @(
    @{ Name = 'Pester'; MinimumVersion = '5.5.0' }
    @{ Name = 'PSScriptAnalyzer'; MinimumVersion = '1.21.0' }
)

if ($IncludePnP) {
    $modules += @{ Name = 'PnP.PowerShell'; MinimumVersion = '3.0.0' }
}

foreach ($module in $modules) {
    $existing = Get-Module -Name $module.Name -ListAvailable |
        Where-Object Version -ge $module.MinimumVersion

    if ($existing) {
        Write-Host "$($module.Name) $($existing[0].Version) already installed."
        continue
    }

    Write-Host "Installing $($module.Name) >= $($module.MinimumVersion)..."
    Install-Module @module -Scope CurrentUser -Force -SkipPublisherCheck -AllowClobber
}
