function Get-ALMFxVersion {
    <#
    .SYNOPSIS
        Returns version and environment information for ALMFx.

    .DESCRIPTION
        Reports the loaded ALMFx module version alongside the PowerShell version
        and the version of PnP.PowerShell that is available, so an issue report
        can state the exact environment a problem occurred in.

        Makes no network calls and requires no tenant connection.

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

        $result = [ordered]@{
            ALMFxVersion      = if ($module) { $module.Version.ToString() } else { 'unknown' }
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            PowerShellEdition = $PSVersionTable.PSEdition
            Platform          = if ($PSVersionTable.ContainsKey('Platform')) { $PSVersionTable.Platform } else { 'Win32NT' }
        }

        if ($IncludeDependencies) {
            Write-Verbose 'Inspecting installed dependencies.'
            $pnp = Get-Module -Name 'PnP.PowerShell' -ListAvailable |
                Sort-Object -Property Version -Descending |
                Select-Object -First 1

            $result['PnPPowerShellVersion'] = if ($pnp) { $pnp.Version.ToString() } else { 'not installed' }
        }

        [PSCustomObject]$result
    }
}
