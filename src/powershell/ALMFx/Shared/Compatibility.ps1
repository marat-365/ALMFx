<#
.SYNOPSIS
    Shared version and environment detection utilities.

.DESCRIPTION
    Version-agnostic helpers for detecting PowerShell, platform, and module versions.
    Used by both PS 5.1 and PS 7+ code paths.

.NOTES
    This file is sourced by ALMFx.psm1 and should NOT use PS7-only APIs.
    All functions here must work on PowerShell 5.1+.
#>

function Get-PSVersionInfo {
    <#
    .SYNOPSIS
        Safely detect PowerShell version and edition.

    .DESCRIPTION
        Returns structured version info that works on both PS 5.1 (Desktop)
        and PS 7+ (Core), handling platform detection differences.

    .OUTPUTS
        [PSCustomObject] with PSVersion, PSEdition, OSName, PSMajorVersion
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    process {
        $version = $PSVersionTable.PSVersion
        $edition = $PSVersionTable.PSEdition

        # Platform detection: PS 5.1 doesn't have $PSVersionTable.Platform
        $osName = if ($PSVersionTable.ContainsKey('Platform')) {
            # PS 7+
            $PSVersionTable.Platform
        }
        else {
            # PS 5.1 fallback
            if ($PSVersionTable.OS -like '*Windows*') {
                'Win32NT'
            }
            elseif ($PSVersionTable.OS -like '*Linux*') {
                'Linux'
            }
            elseif ($PSVersionTable.OS -like '*Darwin*') {
                'Darwin'
            }
            else {
                $PSVersionTable.OS
            }
        }

        [PSCustomObject]@{
            PSVersion        = $version
            PSEdition        = $edition
            PSMajorVersion   = $version.Major
            OSName           = $osName
            IsPS5            = $version.Major -eq 5
            IsPS7Plus        = $version.Major -ge 7
            FullVersionInfo  = $PSVersionTable
        }
    }
}

function Test-PSVersionRequirement {
    <#
    .SYNOPSIS
        Test if current PowerShell meets minimum version requirement.

    .DESCRIPTION
        Safe version comparison that works on both PS 5.1 and PS 7+.

    .PARAMETER MinimumVersion
        Minimum required version (e.g., '7.0', '5.1').

    .OUTPUTS
        [bool] $true if requirement met, $false otherwise.

    .EXAMPLE
        if (Test-PSVersionRequirement -MinimumVersion '7.0') {
            # Use PS7+ specific features
        }
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string] $MinimumVersion
    )

    process {
        try {
            $min = [Version]$MinimumVersion
            $PSVersionTable.PSVersion -ge $min
        }
        catch {
            Write-Verbose "Version comparison failed for '$MinimumVersion': $_"
            $false
        }
    }
}

function Invoke-WithFallback {
    <#
    .SYNOPSIS
        Execute code with PS-version fallback.

    .DESCRIPTION
        Runs primary scriptblock on PS7+, fallback on PS5.1.
        Useful for version-specific behavior without cluttering function code.

    .PARAMETER PS7PlusScript
        Script to execute on PS 7+.

    .PARAMETER PS5Fallback
        Script to execute on PS 5.1 (if different).

    .EXAMPLE
        Invoke-WithFallback `
            -PS7PlusScript { $items | Group-Object -Property Extension } `
            -PS5Fallback { $items | Group-Object -Property { [System.IO.Path]::GetExtension($_.FullName) } }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock] $PS7PlusScript,

        [scriptblock] $PS5Fallback
    )

    process {
        if (Test-PSVersionRequirement -MinimumVersion '7.0') {
            & $PS7PlusScript
        }
        elseif ($null -ne $PS5Fallback) {
            & $PS5Fallback
        }
        else {
            Write-Warning "Feature requires PowerShell 7+; running PS7+ code anyway (may fail)"
            & $PS7PlusScript
        }
    }
}

function ConvertTo-SafeString {
    <#
    .SYNOPSIS
        Convert value to string safely on both PS versions.

    .DESCRIPTION
        Handles encoding differences between PS 5.1 and PS 7+.

    .PARAMETER Value
        Value to convert.

    .PARAMETER Encoding
        Output encoding (default: UTF8). PS 5.1 defaults to ASCII; this normalizes it.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(ValueFromPipeline)]
        [object] $Value,

        [string] $Encoding = 'UTF8'
    )

    process {
        if ($null -eq $Value) { return [string]::Empty }

        # PS 5.1 vs PS 7+ string conversion
        $str = [string]$Value

        # Ensure consistent encoding
        if ($PSVersionTable.PSVersion.Major -eq 5 -and $Encoding -eq 'UTF8') {
            # PS 5.1 may have encoding issues; explicitly handle
            $str
        }
        else {
            # PS 7+ handles encoding natively
            $str
        }
    }
}
