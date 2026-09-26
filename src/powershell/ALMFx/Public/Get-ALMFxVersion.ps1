function Get-ALMFxVersion {
    <#
    .SYNOPSIS
        Returns version and environment information for ALMFx.

    .DESCRIPTION
        Reports the loaded ALMFx module version alongside the PowerShell version
        and the version of PnP.PowerShell that is available, so an issue report
        can state the exact environment a problem occurred in.

        Makes no network calls and requires no tenant connection.

        Compatible with PowerShell 5.1 and 7+.

    .PARAMETER IncludeDependencies
        Also inspect installed dependencies (PnP.PowerShell) and include their
        versions in the output.

    .EXAMPLE
        Get-ALMFxVersion

        Returns the ALMFx and PowerShell versions.

    .EXAMPLE
        Get-ALMFxVersion -IncludeDependencies | Format-List

        Returns full environment detail suitable for pasting into a bug report.

    .OUTPUTS
        System.Management.Automation.PSCustomObject

    .NOTES
        This function is the reference implementation for the conventions in
        AGENTS.md: comment-based help, CmdletBinding, OutputType, object output.

        Supports both PowerShell 5.1 (Desktop) and PowerShell 7+ (Core).
        Uses shared compatibility helpers from Shared\ folder.

    .LINK
        https://github.com/marat-365/ALMFx
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [switch] $IncludeDependencies
    )

    process {
        $module = $MyInvocation.MyCommand.Module

        # Use shared helper for version info
        $psInfo = Get-PSVersionInfo

        $result = [ordered]@{
            ALMFxVersion       = if ($module) { $module.Version.ToString() } else { 'unknown' }
            PowerShellVersion  = $psInfo.PSVersion.ToString()
            PowerShellEdition  = $psInfo.PSEdition
            PowerShellMajor    = $psInfo.PSMajorVersion
            Platform           = $psInfo.OSName
        }

        if ($IncludeDependencies) {
            Write-Verbose 'Inspecting installed dependencies.'
            $pnp = Get-Module -Name 'PnP.PowerShell' -ListAvailable |
                Sort-Object -Property Version -Descending |
                Select-Object -First 1

            $result['PnPPowerShellVersion'] = if ($pnp) { $pnp.Version.ToString() } else { 'not installed' }

            # Platform-specific guidance
            if ($psInfo.IsPS5) {
                $result['PnPVersionNote'] = 'PS 5.1 requires PnP.PowerShell v2.x'
            }
            elseif ($psInfo.IsPS7Plus) {
                $result['PnPVersionNote'] = 'PS 7+ should use PnP.PowerShell v3.x'
            }
        }

        [PSCustomObject]$result
    }
}
