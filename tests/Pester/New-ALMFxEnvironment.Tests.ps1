#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

<#
    New-ALMFxEnvironment discovers SPFx artefact identity (solution, feature,
    and component ids/aliases) from a real fixture and builds an isolated
    per-environment copy with consistent GUID/name rewriting. Every test here
    runs against a fresh copy of testplaygrounds/spfx-sample-app inside
    $TestDrive, never the committed fixture itself.
#>

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
    $script:FixtureSource = Join-Path $RepoRoot 'testplaygrounds' 'spfx-sample-app'

    Import-Module (Join-Path $RepoRoot 'src' 'powershell' 'ALMFx' 'ALMFx.psd1') -Force

    function New-TestFixtureCopy {
        # Fresh, isolated copy of the real sample app under $TestDrive, so no
        # test ever mutates the committed fixture and tests cannot interfere
        # with each other.
        $destination = Join-Path $TestDrive ([guid]::NewGuid().ToString()) 'spfx-sample-app'
        New-Item -Path (Split-Path $destination -Parent) -ItemType Directory -Force | Out-Null
        Copy-Item -Path $FixtureSource -Destination $destination -Recurse -Force
        $destination
    }
}

Describe 'New-ALMFxEnvironment' {

    It 'fails clearly when Path is not an SPFx solution root' {
        $empty = Join-Path $TestDrive 'not-a-solution'
        New-Item -Path $empty -ItemType Directory -Force | Out-Null

        { New-ALMFxEnvironment -Path $empty -Environment dev -ErrorAction Stop } |
            Should -Throw -ErrorId 'ALMFx.NotAnSPFxSolution*'
    }

    Context 'default -CreateUniqueNames' {
        It 'defaults to $true for a non-prod environment name' {
            $app = New-TestFixtureCopy
            $result = New-ALMFxEnvironment -Path $app -Environment dev
            $result.CreateUniqueNames | Should -Be $true
        }

        It 'defaults to $false when -Environment is "prod" (any case)' -TestCases @(
            @{ EnvironmentName = 'prod' }
            @{ EnvironmentName = 'PROD' }
            @{ EnvironmentName = 'Production' }
        ) {
            param($EnvironmentName)
            $app = New-TestFixtureCopy
            $result = New-ALMFxEnvironment -Path $app -Environment $EnvironmentName
            $result.CreateUniqueNames | Should -Be $false
        }

        It 'can be overridden explicitly in either direction' {
            $app = New-TestFixtureCopy
            (New-ALMFxEnvironment -Path $app -Environment dev -CreateUniqueNames $false).CreateUniqueNames | Should -Be $false
            $app2 = New-TestFixtureCopy
            (New-ALMFxEnvironment -Path $app2 -Environment prod -CreateUniqueNames $true).CreateUniqueNames | Should -Be $true
        }
    }

    Context 'content-based file discovery' {
        BeforeAll {
            $script:App = New-TestFixtureCopy
            $script:Result = New-ALMFxEnvironment -Path $App -Environment dev
        }

        It 'copies config/serve.json, which is not in any fixed include-list' {
            $Result.Files.RelativePath | Should -Contain 'config/serve.json'
        }

        It 'copies .yo-rc.json (a dot-file, and legitimately relevant - echoes the solution GUID)' {
            $Result.Files.RelativePath | Should -Contain '.yo-rc.json'
        }

        It 'does not copy files that reference no known artefact identity' {
            $Result.Files.RelativePath | Should -Not -Contain 'package.json'
            $Result.Files.RelativePath | Should -Not -Contain 'package-lock.json'
            $Result.Files.RelativePath | Should -Not -Contain 'tsconfig.json'
            $Result.Files.RelativePath | Should -Not -Contain '.vscode/launch.json'
        }

        It 'copies every component manifest' {
            foreach ($manifest in 'src/webparts/helloWorld/HelloWorldWebPart.manifest.json',
                'src/extensions/headerFooter/HeaderFooterApplicationCustomizer.manifest.json',
                'src/extensions/colorCoded/ColorCodedFieldCustomizer.manifest.json',
                'src/extensions/itemActions/ItemActionsCommandSet.manifest.json',
                'src/libraries/sharedUtilities/SharedUtilitiesLibrary.manifest.json',
                'src/adaptiveCardExtensions/sampleCard/SampleCardAdaptiveCardExtension.manifest.json') {
                $Result.Files.RelativePath | Should -Contain $manifest
            }
        }
    }

    Context 'GUID/name rewriting (-CreateUniqueNames $true)' {
        BeforeAll {
            $script:App = New-TestFixtureCopy
            $script:Result = New-ALMFxEnvironment -Path $App -Environment dev
            $script:DevManifest = Get-Content (Join-Path $App '.dev' 'src' 'webparts' 'helloWorld' 'HelloWorldWebPart.manifest.json') -Raw
            $script:DevElements = Get-Content (Join-Path $App '.dev' 'sharepoint' 'assets' 'elements.xml') -Raw
            $script:DevInstance = Get-Content (Join-Path $App '.dev' 'sharepoint' 'assets' 'ClientSideInstance.xml') -Raw
            $script:DevServe = Get-Content (Join-Path $App '.dev' 'config' 'serve.json') -Raw
        }

        It 'suffixes the component alias with _<environment>' {
            $DevManifest | Should -Match 'HelloWorldWebPart_dev'
        }

        It 'replaces the component id with a freshly generated GUID' {
            $DevManifest | Should -Not -Match '439c85de-9fd0-41ee-bc4b-76b1502f4b8c'
        }

        It 'replaces the same component id consistently across manifest, elements.xml, ClientSideInstance.xml, and serve.json' {
            # HeaderFooterApplicationCustomizer's id - the one artefact in this
            # fixture that is genuinely echoed in four different files.
            $headerFooterOriginal = 'a4126475-6e6b-4729-96e5-4b125614765e'
            $headerFooterManifest = Get-Content (Join-Path $App '.dev' 'src' 'extensions' 'headerFooter' 'HeaderFooterApplicationCustomizer.manifest.json') -Raw

            $headerFooterManifest | Should -Not -Match $headerFooterOriginal
            $DevElements | Should -Not -Match $headerFooterOriginal
            $DevInstance | Should -Not -Match $headerFooterOriginal
            $DevServe | Should -Not -Match $headerFooterOriginal

            # And whatever new GUID it got, it must be the SAME new GUID in all four.
            if ($headerFooterManifest -match '"id":\s*"([0-9a-fA-F-]{36})"') {
                $newGuid = $Matches[1]
                $DevElements | Should -Match ([regex]::Escape($newGuid))
                $DevInstance | Should -Match ([regex]::Escape($newGuid))
                $DevServe | Should -Match ([regex]::Escape($newGuid))
            }
            else {
                throw 'Could not read the rewritten HeaderFooter id back out of its own manifest - test setup problem.'
            }
        }

        It 'does NOT touch the fixed Microsoft web-part-gallery category GUID (groupId)' {
            # This is not artefact identity - it is the same constant across
            # every SPFx project ("Advanced" category). Rewriting it would
            # break the web part gallery grouping.
            $DevManifest | Should -Match '5c03119e-3074-46fd-976b-c60198311f70'
        }

        It 'does NOT touch a GUID embedded inside a generated comment/URL' {
            # The support.office.com article id in the manifest's own comment.
            $DevManifest | Should -Match '1f2c515f-5d7e-448a-9fd7-835da935584f'
        }

        It 'rewrites the solution id and name too' {
            $devPackageSolution = Get-Content (Join-Path $App '.dev' 'config' 'package-solution.json') -Raw | ConvertFrom-Json
            $devPackageSolution.solution.id | Should -Not -Be '534b46d7-00cd-4dff-afd2-e52b47d513a3'
            $devPackageSolution.solution.name | Should -Be 'spfx-sample-app-client-side-solution_dev'
        }
    }

    Context '-CreateUniqueNames $false (prod default)' {
        It 'copies files verbatim, with the original id and alias unchanged' {
            $app = New-TestFixtureCopy
            New-ALMFxEnvironment -Path $app -Environment prod | Out-Null

            $originalManifest = Get-Content (Join-Path $FixtureSource 'src' 'webparts' 'helloWorld' 'HelloWorldWebPart.manifest.json') -Raw
            $prodManifest = Get-Content (Join-Path $app '.prod' 'src' 'webparts' 'helloWorld' 'HelloWorldWebPart.manifest.json') -Raw

            $prodManifest | Should -Be $originalManifest
            $prodManifest | Should -Match '439c85de-9fd0-41ee-bc4b-76b1502f4b8c'
        }

        It 'still copies config/serve.json (relevance is content-based regardless of rewriting)' {
            $app = New-TestFixtureCopy
            $result = New-ALMFxEnvironment -Path $app -Environment prod
            $result.Files.RelativePath | Should -Contain 'config/serve.json'
        }
    }

    Context 'idempotency and incremental components' {
        It 're-running with no source changes reuses every previously assigned id/alias exactly' {
            $app = New-TestFixtureCopy
            $run1 = New-ALMFxEnvironment -Path $app -Environment dev
            # -Force: without it, .yo-rc.json (a dot-file) is silently
            # excluded from the hash comparison, so both sides would be
            # missing it equally and this test would pass without ever
            # actually checking that file's idempotency.
            $hashesAfterRun1 = Get-ChildItem (Join-Path $app '.dev') -Recurse -File -Force |
                Sort-Object FullName | ForEach-Object { (Get-FileHash $_.FullName).Hash }

            $run2 = New-ALMFxEnvironment -Path $app -Environment dev
            $hashesAfterRun2 = Get-ChildItem (Join-Path $app '.dev') -Recurse -File -Force |
                Sort-Object FullName | ForEach-Object { (Get-FileHash $_.FullName).Hash }

            ($hashesAfterRun2 -join ',') | Should -Be ($hashesAfterRun1 -join ',')
            $run1.Files.Count | Should -Be $run2.Files.Count
        }

        It 'assigns a new id only to a component added after the first run, leaving existing ones untouched' {
            $app = New-TestFixtureCopy
            New-ALMFxEnvironment -Path $app -Environment dev | Out-Null
            $webPartIdBefore = (Get-Content (Join-Path $app '.dev' 'src' 'webparts' 'helloWorld' 'HelloWorldWebPart.manifest.json') -Raw |
                ConvertFrom-Json).id

            # Simulate a developer adding a brand-new web part.
            $newWebPartDir = Join-Path $app 'src' 'webparts' 'brandNew'
            New-Item -Path $newWebPartDir -ItemType Directory -Force | Out-Null
            $newId = [guid]::NewGuid().ToString()
            @"
{
  "`$schema": "https://developer.microsoft.com/json-schemas/spfx/client-side-web-part-manifest.schema.json",
  "id": "$newId",
  "alias": "BrandNewWebPart",
  "componentType": "WebPart"
}
"@ | Set-Content (Join-Path $newWebPartDir 'BrandNewWebPart.manifest.json')

            $rerun = New-ALMFxEnvironment -Path $app -Environment dev
            $webPartIdAfter = (Get-Content (Join-Path $app '.dev' 'src' 'webparts' 'helloWorld' 'HelloWorldWebPart.manifest.json') -Raw |
                ConvertFrom-Json).id

            $webPartIdAfter | Should -Be $webPartIdBefore
            $rerun.Files.RelativePath | Should -Contain 'src/webparts/brandNew/BrandNewWebPart.manifest.json'

            $newManifestCopy = Get-Content (Join-Path $app '.dev' 'src' 'webparts' 'brandNew' 'BrandNewWebPart.manifest.json') -Raw
            $newManifestCopy | Should -Match 'BrandNewWebPart_dev'
            $newManifestCopy | Should -Not -Match $newId
        }

        It 'prunes a component removed from the source out of the .<environment> folder' {
            $app = New-TestFixtureCopy
            New-ALMFxEnvironment -Path $app -Environment dev | Out-Null
            $staleFile = Join-Path $app '.dev' 'src' 'libraries' 'sharedUtilities' 'SharedUtilitiesLibrary.manifest.json'
            $staleFile | Should -Exist

            Remove-Item (Join-Path $app 'src' 'libraries' 'sharedUtilities') -Recurse -Force
            New-ALMFxEnvironment -Path $app -Environment dev | Out-Null

            $staleFile | Should -Not -Exist
        }
    }

    Context '-WhatIf' {
        It 'writes nothing to disk' {
            $app = New-TestFixtureCopy
            $beforeCount = (Get-ChildItem $app -Recurse -File -Force).Count

            New-ALMFxEnvironment -Path $app -Environment dev -WhatIf

            $afterCount = (Get-ChildItem $app -Recurse -File -Force).Count
            $afterCount | Should -Be $beforeCount
            (Join-Path $app '.dev') | Should -Not -Exist
        }
    }
}
