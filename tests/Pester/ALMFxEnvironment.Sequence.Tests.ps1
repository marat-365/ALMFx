#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

<#
    End-to-end New-ALMFxEnvironment -> Set-ALMFxEnvironment sequence, as a
    user would actually run it. New-/Set-ALMFxEnvironment.Tests.ps1 cover
    each function's own behaviour in isolation; this file is specifically the
    full workflow, including two environments coexisting side by side (the
    whole point of -CreateUniqueNames) without colliding.
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

Describe 'New-ALMFxEnvironment then Set-ALMFxEnvironment, end to end' {

    It 'builds dev, deploys it, and the deployed root matches the built .dev copy exactly' {
        $app = New-TestFixtureCopy

        $built = New-ALMFxEnvironment -Path $app -Environment dev
        $built.Files.Count | Should -BeGreaterThan 0

        $deployed = Set-ALMFxEnvironment -Path $app -Environment dev
        $deployed.Count | Should -Be $built.Files.Count

        foreach ($file in $deployed) {
            $rootContent = Get-Content $file.DestinationPath -Raw
            $devContent = Get-Content $file.SourcePath -Raw
            $rootContent | Should -Be $devContent -Because "$($file.RelativePath) must match its .dev source exactly after deploy"
        }
    }

    It 'building dev and prod for the same solution produces two non-colliding identities' {
        $app = New-TestFixtureCopy

        $dev = New-ALMFxEnvironment -Path $app -Environment dev
        $prod = New-ALMFxEnvironment -Path $app -Environment prod

        $devWebPartId = (Get-Content (Join-Path $app '.dev' 'src' 'webparts' 'helloWorld' 'HelloWorldWebPart.manifest.json') -Raw | ConvertFrom-Json).id
        $prodWebPartId = (Get-Content (Join-Path $app '.prod' 'src' 'webparts' 'helloWorld' 'HelloWorldWebPart.manifest.json') -Raw | ConvertFrom-Json).id

        # prod keeps the real, original identity by default; dev gets a fresh one.
        $prodWebPartId | Should -Be '439c85de-9fd0-41ee-bc4b-76b1502f4b8c'
        $devWebPartId | Should -Not -Be $prodWebPartId
        $devWebPartId | Should -Not -Be '439c85de-9fd0-41ee-bc4b-76b1502f4b8c'

        # Building one environment must not touch the other's payload folder.
        # -Force: a payload can legitimately include a dot-file (.yo-rc.json),
        # which Get-ChildItem otherwise silently undercounts.
        (Get-ChildItem (Join-Path $app '.dev') -Recurse -File -Force).Count | Should -Be $dev.Files.Count
        (Get-ChildItem (Join-Path $app '.prod') -Recurse -File -Force).Count | Should -Be $prod.Files.Count
    }

    It 'deploying dev then re-deploying prod over it leaves the solution in the prod (original) identity' {
        $app = New-TestFixtureCopy
        New-ALMFxEnvironment -Path $app -Environment dev | Out-Null
        New-ALMFxEnvironment -Path $app -Environment prod | Out-Null

        Set-ALMFxEnvironment -Path $app -Environment dev | Out-Null
        $afterDev = (Get-Content (Join-Path $app 'src' 'webparts' 'helloWorld' 'HelloWorldWebPart.manifest.json') -Raw | ConvertFrom-Json).alias
        $afterDev | Should -Be 'HelloWorldWebPart_dev'

        Set-ALMFxEnvironment -Path $app -Environment prod | Out-Null
        $afterProd = (Get-Content (Join-Path $app 'src' 'webparts' 'helloWorld' 'HelloWorldWebPart.manifest.json') -Raw | ConvertFrom-Json).alias
        $afterProd | Should -Be 'HelloWorldWebPart'
    }

    It 'the full sequence never touches a real tenant or makes a network call' {
        # Structural guard, not a runtime one: neither function's source
        # references Connect-PnPOnline or any network cmdlet - this is pure
        # filesystem/text work, satisfying AGENTS.md golden rule 6.
        $newSource = Get-Content (Join-Path $RepoRoot 'src' 'powershell' 'ALMFx' 'Public' 'New-ALMFxEnvironment.ps1') -Raw
        $setSource = Get-Content (Join-Path $RepoRoot 'src' 'powershell' 'ALMFx' 'Public' 'Set-ALMFxEnvironment.ps1') -Raw
        $newSource | Should -Not -Match 'Connect-PnP|Invoke-WebRequest|Invoke-RestMethod'
        $setSource | Should -Not -Match 'Connect-PnP|Invoke-WebRequest|Invoke-RestMethod'
    }
}
