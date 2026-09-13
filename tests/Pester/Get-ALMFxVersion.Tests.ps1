#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    $moduleManifest = Join-Path $PSScriptRoot '..' '..' 'src' 'powershell' 'ALMFx' 'ALMFx.psd1'
    Import-Module $moduleManifest -Force
}

Describe 'Get-ALMFxVersion' {

    It 'returns an object with the module and PowerShell versions' {
        $result = Get-ALMFxVersion

        $result | Should -Not -BeNullOrEmpty
        $result.ALMFxVersion | Should -Not -BeNullOrEmpty
        $result.PowerShellVersion | Should -Be $PSVersionTable.PSVersion.ToString()
    }

    It 'omits dependency information by default' {
        $result = Get-ALMFxVersion
        $result.PSObject.Properties.Name | Should -Not -Contain 'PnPPowerShellVersion'
    }

    It 'includes dependency information when asked' {
        $result = Get-ALMFxVersion -IncludeDependencies
        $result.PSObject.Properties.Name | Should -Contain 'PnPPowerShellVersion'
    }

    It 'makes no network calls' {
        # Guard: if this function ever grows a tenant dependency, this fails.
        Mock -CommandName Invoke-WebRequest -MockWith { throw 'Network call attempted' }
        { Get-ALMFxVersion -IncludeDependencies } | Should -Not -Throw
    }
}

Describe 'ALMFx module contract' {

    It 'exports every function declared in the manifest' {
        $manifestPath = Join-Path $PSScriptRoot '..' '..' 'src' 'powershell' 'ALMFx' 'ALMFx.psd1'
        $manifest = Import-PowerShellDataFile -Path $manifestPath
        $exported = (Get-Module ALMFx).ExportedFunctions.Keys

        foreach ($declared in $manifest.FunctionsToExport) {
            $exported | Should -Contain $declared
        }
    }

    It 'gives every exported function comment-based help with an example' {
        foreach ($name in (Get-Module ALMFx).ExportedFunctions.Keys) {
            $help = Get-Help -Name $name -Full
            $help.Synopsis    | Should -Not -BeNullOrEmpty -Because "$name needs a .SYNOPSIS"
            $help.Description | Should -Not -BeNullOrEmpty -Because "$name needs a .DESCRIPTION"
            $help.Examples.Example.Count | Should -BeGreaterThan 0 -Because "$name needs an .EXAMPLE"
        }
    }
}
