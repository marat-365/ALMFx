@{
    RootModule            = 'ALMFx.psm1'
    ModuleVersion         = '0.1.0'
    CompatiblePSEditions  = @('Core')
    GUID                  = 'f0c7b631-cf4a-4b69-b763-f1bd939cafda'
    Author                = 'Marat Bakirov'
    CompanyName           = 'Unknown'
    Copyright             = '(c) Marat Bakirov. Licensed under the MIT License.'
    Description           = 'Application Lifecycle Management toolkit for SharePoint Framework (SPFx) solutions and PnP provisioning.'

    PowerShellVersion     = '7.4'

    # Declared, not bundled. Users install PnP.PowerShell themselves.
    # Uncomment once a function actually depends on it.
    # RequiredModules     = @(@{ ModuleName = 'PnP.PowerShell'; ModuleVersion = '3.0.0' })

    FunctionsToExport     = @(
        'Get-ALMFxVersion'
    )
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @()

    PrivateData           = @{
        PSData = @{
            Tags         = @('SharePoint', 'SPFx', 'PnP', 'ALM', 'Microsoft365', 'DevOps')
            LicenseUri   = 'https://github.com/marat-365/ALMFx/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/marat-365/ALMFx'
            ReleaseNotes = 'https://github.com/marat-365/ALMFx/blob/main/CHANGELOG.md'
        }
    }
}
