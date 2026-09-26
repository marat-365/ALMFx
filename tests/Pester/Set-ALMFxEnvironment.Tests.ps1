#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

<#
    Set-ALMFxEnvironment is the deploy half of the pair: copy everything from
    <Path>/.<Environment>/ back to <Path>, overwriting. Tested against
    New-ALMFxEnvironment's real output (not a hand-built fixture) so a
    regression in either function's file-naming/relative-path convention
    shows up here.
#>

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
    $script:FixtureSource = Join-Path $RepoRoot 'testplaygrounds' 'spfx-sample-app'

    Import-Module (Join-Path $RepoRoot 'src' 'powershell' 'ALMFx' 'ALMFx.psd1') -Force

    function New-TestFixtureCopy {
        $destination = Join-Path $TestDrive ([guid]::NewGuid().ToString()) 'spfx-sample-app'
        New-Item -Path (Split-Path $destination -Parent) -ItemType Directory -Force | Out-Null
        Copy-Item -Path $FixtureSource -Destination $destination -Recurse -Force
        $destination
    }
}

Describe 'Set-ALMFxEnvironment' {

    It 'fails clearly when the environment has not been built yet' {
        $app = New-TestFixtureCopy
        { Set-ALMFxEnvironment -Path $app -Environment dev -ErrorAction Stop } |
            Should -Throw -ErrorId 'ALMFx.EnvironmentNotBuilt*'
    }

    Context 'deploying a built environment' {
        BeforeAll {
            $script:App = New-TestFixtureCopy
            New-ALMFxEnvironment -Path $App -Environment dev | Out-Null
            $script:Deployed = Set-ALMFxEnvironment -Path $App -Environment dev
        }

        It 'deploys exactly the files New-ALMFxEnvironment built' {
            $builtFiles = Get-ChildItem (Join-Path $App '.dev') -Recurse -File -Force
            $Deployed.Count | Should -Be $builtFiles.Count
        }

        It 'overwrites the root manifest with the environment copy' {
            $rootManifest = Get-Content (Join-Path $App 'src' 'webparts' 'helloWorld' 'HelloWorldWebPart.manifest.json') -Raw
            $devManifest = Get-Content (Join-Path $App '.dev' 'src' 'webparts' 'helloWorld' 'HelloWorldWebPart.manifest.json') -Raw
            $rootManifest | Should -Be $devManifest
            $rootManifest | Should -Match 'HelloWorldWebPart_dev'
        }

        It 'overwrites config/serve.json at the root, not just files that were in the original narrow guess' {
            $rootServe = Get-Content (Join-Path $App 'config' 'serve.json') -Raw
            $rootServe | Should -Not -Match 'a4126475-6e6b-4729-96e5-4b125614765e'
        }

        It 'deploys the dot-file (.yo-rc.json) too' {
            $rootYoRc = Get-Content (Join-Path $App '.yo-rc.json') -Raw
            $devYoRc = Get-Content (Join-Path $App '.dev' '.yo-rc.json') -Raw
            $rootYoRc | Should -Be $devYoRc
        }

        It 'leaves the fixed groupId system constant intact after a full deploy round-trip' {
            $rootManifest = Get-Content (Join-Path $App 'src' 'webparts' 'helloWorld' 'HelloWorldWebPart.manifest.json') -Raw
            $rootManifest | Should -Match '5c03119e-3074-46fd-976b-c60198311f70'
        }
    }

    Context '-WhatIf' {
        It 'writes nothing to disk' {
            $app = New-TestFixtureCopy
            New-ALMFxEnvironment -Path $app -Environment dev | Out-Null
            $originalManifest = Get-Content (Join-Path $app 'src' 'webparts' 'helloWorld' 'HelloWorldWebPart.manifest.json') -Raw

            Set-ALMFxEnvironment -Path $app -Environment dev -WhatIf

            $manifestAfter = Get-Content (Join-Path $app 'src' 'webparts' 'helloWorld' 'HelloWorldWebPart.manifest.json') -Raw
            $manifestAfter | Should -Be $originalManifest
        }
    }
}
