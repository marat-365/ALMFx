#Requires -Version 7.4

# ALMFx module loader.
# Dot-sources every function file, then exports only what lives in Public/.
# Do not add function definitions to this file - one function per file.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$moduleRoot = $PSScriptRoot

foreach ($folder in 'Classes', 'Private', 'Public') {
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
