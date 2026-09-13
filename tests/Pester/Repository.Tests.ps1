#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

<#
    Repository contract tests.

    Skills, manifests, and the docs table are the parts of this repo with no
    compiler behind them - nothing else catches a frontmatter typo, a plugin
    source path that does not resolve, or a real tenant URL in an example.
    These run offline and need no tenant.
#>

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path

    function Get-SkillFrontmatter {
        param([string] $Path)

        $lines = Get-Content -Path $Path
        if ($lines[0] -ne '---') { return $null }

        $end = 1
        while ($end -lt $lines.Count -and $lines[$end] -ne '---') { $end++ }
        if ($end -ge $lines.Count) { return $null }

        $map = @{}
        foreach ($line in $lines[1..($end - 1)]) {
            if ($line -match '^(?<key>[a-zA-Z_]+):\s*(?<value>.+)$') {
                $map[$Matches.key] = $Matches.value.Trim()
            }
        }
        $map
    }
}

Describe 'Skill contract' {

    BeforeDiscovery {
        $root = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
        # -Force is mandatory: .claude/ and .claude-plugin/ are hidden
        # directories, and Get-ChildItem -Recurse will not descend into them
        # without it. Omitting it silently skips every repo-development skill.
        $SkillCases = Get-ChildItem -Path $root -Filter 'SKILL.md' -Recurse -File -Force |
            Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' } |
            ForEach-Object {
                @{
                    Name         = Split-Path (Split-Path $_.FullName -Parent) -Leaf
                    Path         = $_.FullName
                    RelativePath = $_.FullName.Substring($root.Length + 1)
                }
            }
    }

    It 'finds skills to validate' {
        # Re-derived at run phase on purpose: a -ForEach over an empty
        # discovery set generates zero tests and passes silently, which is
        # exactly the regression this guards against.
        $found = Get-ChildItem -Path $RepoRoot -Filter 'SKILL.md' -Recurse -File -Force |
            Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' }
        $found.Count | Should -BeGreaterThan 0

        # Repo-development skills must always exist. If this drops to zero,
        # -Force was removed somewhere and the .claude/ tree stopped being
        # scanned at all.
        ($found | Where-Object { $_.FullName -match '[\\/]\.claude[\\/]' }).Count |
            Should -BeGreaterThan 0 -Because 'repo-development skills must be validated'

        # Shipped skills are deliberately empty until ALMFx has a surface worth
        # driving - see plugins/almfx/skills/README.md. No assertion on their
        # count; the tests below validate them only if they exist.
    }

    It '<RelativePath> has YAML frontmatter with name and description' -ForEach $SkillCases {
        $fm = Get-SkillFrontmatter -Path $Path
        $fm | Should -Not -BeNullOrEmpty -Because 'the file must open with a --- delimited block'
        $fm.name | Should -Not -BeNullOrEmpty
        $fm.description | Should -Not -BeNullOrEmpty
    }

    It '<RelativePath> has a name matching its folder' -ForEach $SkillCases {
        (Get-SkillFrontmatter -Path $Path).name | Should -BeExactly $Name
    }

    It '<RelativePath> describes triggers, not a topic' -ForEach $SkillCases {
        # The description is the only thing an agent sees before loading the
        # skill. A short topic label ("SPFx deployment.") will not trigger it.
        # "before"/"after" are allowed alongside "when": an anticipatory skill
        # (verify this before you write the call) has a genuinely different
        # trigger shape from a reactive one, and forcing "Use when" on it
        # produces worse wording, not better triggering.
        $description = (Get-SkillFrontmatter -Path $Path).description
        $description.Length | Should -BeGreaterThan 60
        $description | Should -Match '^Use (when|before|after)\b'
    }

    It '<RelativePath> stays under 500 lines' -ForEach $SkillCases {
        (Get-Content -Path $Path).Count | Should -BeLessOrEqual 500 -Because 'detail belongs in sibling reference files'
    }
}

Describe 'Plugin packaging' {

    It 'declares a marketplace whose plugin sources resolve on disk' {
        $marketplacePath = Join-Path $RepoRoot '.claude-plugin' 'marketplace.json'
        $marketplacePath | Should -Exist

        $marketplace = Get-Content $marketplacePath -Raw | ConvertFrom-Json
        $marketplace.name | Should -Not -BeNullOrEmpty
        $marketplace.owner.name | Should -Not -BeNullOrEmpty
        $marketplace.plugins.Count | Should -BeGreaterThan 0

        foreach ($plugin in $marketplace.plugins) {
            $source = Join-Path $RepoRoot ($plugin.source -replace '^\./', '')
            $source | Should -Exist -Because "marketplace.json points at $($plugin.source)"
            (Join-Path $source '.claude-plugin' 'plugin.json') | Should -Exist
        }
    }

    It 'gives every plugin a skills folder that exists' {
        # -Force: plugin.json lives in the hidden .claude-plugin/ directory.
        $manifests = Get-ChildItem -Path (Join-Path $RepoRoot 'plugins') -Filter 'plugin.json' -Recurse -File -Force

        # Without this the foreach below iterates nothing and passes vacuously.
        $manifests.Count | Should -BeGreaterThan 0 -Because 'at least one plugin manifest must exist'

        foreach ($manifest in $manifests) {
            $json = Get-Content $manifest.FullName -Raw | ConvertFrom-Json
            $pluginRoot = Split-Path (Split-Path $manifest.FullName -Parent) -Parent
            $skills = Join-Path $pluginRoot ($json.skills -replace '^\./', '')

            $skills | Should -Exist -Because "$($manifest.Name) declares skills at $($json.skills)"

            # The folder may legitimately hold no skills yet, but it must say so
            # deliberately - otherwise an accidental deletion looks identical to
            # the intended pre-release state.
            (Join-Path $skills 'README.md') | Should -Exist -Because 'an empty shipped-skills folder must explain itself'
        }
    }

    It 'keeps repo-development skills out of the shipped plugin' {
        # A product skill that references this repo's build system is a bug.
        # May be empty today; this guards the day it is not.
        $shipped = Get-ChildItem -Path (Join-Path $RepoRoot 'plugins') -Filter 'SKILL.md' -Recurse -File -Force

        foreach ($skill in $shipped) {
            $content = Get-Content $skill.FullName -Raw
            $content | Should -Not -Match 'Invoke-Build\.ps1' -Because "$($skill.Directory.Name) ships to users"
            $content | Should -Not -Match 'FunctionsToExport' -Because "$($skill.Directory.Name) ships to users"
            $content | Should -Not -Match 'tests[\\/]Pester' -Because "$($skill.Directory.Name) ships to users"
        }
    }
}

Describe 'Documentation contract' {

    It 'lists every exported function in the cmdlet table' {
        Import-Module (Join-Path $RepoRoot 'src' 'powershell' 'ALMFx' 'ALMFx.psd1') -Force
        $indexPath = Join-Path $RepoRoot 'docs' 'powershell' 'index.md'
        $index = Get-Content $indexPath -Raw

        foreach ($name in (Get-Module ALMFx).ExportedFunctions.Keys) {
            $index | Should -Match ([regex]::Escape($name)) -Because "docs/powershell/index.md must document $name"
        }
    }

    It 'keeps the single-source-of-truth reference tree intact' {
        # docs/reference/spfx-alm/ is where AGENTS.md says domain facts must
        # live. If a page here goes missing, something that links to it (a
        # skill, an instruction file, extension copy) is now a dead link.
        $referenceRoot = Join-Path $RepoRoot 'docs' 'reference' 'spfx-alm'
        (Join-Path $referenceRoot 'README.md') | Should -Exist

        foreach ($page in 'cmdlets', 'deployment', 'upgrade', 'inventory', 'api-permissions', 'troubleshooting', 'provisioning', 'cicd') {
            (Join-Path $referenceRoot "$page.md") | Should -Exist -Because "the reference index links to $page.md"
        }
    }
}

Describe 'VS Code extension' {

    BeforeAll {
        $script:VSCodeRoot = Join-Path $RepoRoot 'src' 'vscode' 'almfx'
    }

    It 'has a package.json with no wildcard activation event' {
        $packagePath = Join-Path $VSCodeRoot 'package.json'
        $packagePath | Should -Exist

        $package = Get-Content $packagePath -Raw | ConvertFrom-Json
        $package.activationEvents | Should -Not -Contain '*' -Because 'wildcard activation runs the extension in every window'
    }

    It 'has an entry point' {
        (Join-Path $VSCodeRoot 'src' 'extension.ts') | Should -Exist
    }

    It 'does not resurrect the abandoned two-extension layout' {
        # ADR 0001: one extension, not almfx-spfx-alm + almfx-provisioning.
        (Join-Path $RepoRoot 'src' 'vscode' 'almfx-spfx-alm') | Should -Not -Exist
        (Join-Path $RepoRoot 'src' 'vscode' 'almfx-provisioning') | Should -Not -Exist
    }
}

Describe 'Golden rule: no tenant data committed' {

    It 'uses only contoso placeholders for SharePoint hosts' {
        # -Force so .github/ and .claude/ are scanned too - the instruction
        # files are exactly where a copy-pasted real tenant URL would land.
        $files = Get-ChildItem -Path $RepoRoot -Include '*.md', '*.ps1', '*.psm1', '*.psd1', '*.json', '*.yml' -Recurse -File -Force |
            Where-Object { $_.FullName -notmatch '[\\/](\.git|node_modules|out|dist)[\\/]' }

        $files.Count | Should -BeGreaterThan 0

        $offenders = foreach ($file in $files) {
            foreach ($match in [regex]::Matches((Get-Content $file.FullName -Raw), 'https://([a-z0-9-]+)\.sharepoint\.com')) {
                # Not $host - that is a reserved automatic variable.
                $tenantHost = $match.Groups[1].Value
                if ($tenantHost -notlike 'contoso*') {
                    "$($file.Name): $($match.Value)"
                }
            }
        }

        $offenders | Should -BeNullOrEmpty -Because 'AGENTS.md forbids real tenant URLs in committed files'
    }

    It 'commits no certificate or key material' {
        $secrets = Get-ChildItem -Path $RepoRoot -Include '*.pfx', '*.p12', '*.pem', '*.key' -Recurse -File -Force |
            Where-Object { $_.FullName -notmatch '[\\/](\.git|node_modules)[\\/]' }

        $secrets | Should -BeNullOrEmpty
    }
}
