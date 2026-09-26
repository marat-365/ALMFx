#Requires -Version 5.1

# ALMFx module loader.
# Dot-sources every function file, then exports only what lives in Public/.
# Do not add function definitions to this file - one function per file.
#
# Compatibility notes:
# - Supports PowerShell 5.1 (Windows PowerShell) and PowerShell 7.x+ (Core).
# - PnP.PowerShell v3 requires PS7+; users on PS5 must use an older PnP version.
# - Some functions may be unavailable or limited on PS5; check help and .NOTES.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$moduleRoot = $PSScriptRoot

foreach ($folder in 'Shared', 'Classes', 'Private', 'Public') {
    $path = Join-Path -Path $moduleRoot -ChildPath $folder
    if (-not (Test-Path -Path $path)) { continue }

    Get-ChildItem -Path $path -Filter '*.ps1' -Recurse |
        Sort-Object -Property FullName |
        ForEach-Object {
            try {
                . $_.FullName
            }
            catch {
                throw "Failed to import $($_.FullName): $_"
            }
        }
}

$publicPath = Join-Path -Path $moduleRoot -ChildPath 'Public'
$publicFunctions = if (Test-Path -Path $publicPath) {
    (Get-ChildItem -Path $publicPath -Filter '*.ps1' -Recurse).BaseName
}
else {
    @()
}

Export-ModuleMember -Function $publicFunctions
