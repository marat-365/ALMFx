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

        # Both audiences must be represented. If this drops to one, -Force was
        # removed somewhere and half the skills stopped being validated.
        ($found | Where-Object { $_.FullName -match '[\\/]plugins[\\/]' }).Count |
            Should -BeGreaterThan 0 -Because 'shipped skills must be validated'
        ($found | Where-Object { $_.FullName -match '[\\/]\.claude[\\/]' }).Count |
            Should -BeGreaterThan 0 -Because 'repo-development skills must be validated'
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

    It 'gives every plugin a skills folder that exists and is not empty' {
        # -Force: plugin.json lives in the hidden .claude-plugin/ directory.
        $manifests = Get-ChildItem -Path (Join-Path $RepoRoot 'plugins') -Filter 'plugin.json' -Recurse -File -Force

        # Without this the foreach below iterates nothing and passes vacuously.
        $manifests.Count | Should -BeGreaterThan 0 -Because 'at least one plugin manifest must exist'

        foreach ($manifest in $manifests) {
            $json = Get-Content $manifest.FullName -Raw | ConvertFrom-Json
            $pluginRoot = Split-Path (Split-Path $manifest.FullName -Parent) -Parent
            $skills = Join-Path $pluginRoot ($json.skills -replace '^\./', '')

            $skills | Should -Exist -Because "$($manifest.Name) declares skills at $($json.skills)"
            (Get-ChildItem -Path $skills -Filter 'SKILL.md' -Recurse).Count |
                Should -BeGreaterThan 0
        }
    }

    It 'keeps repo-development skills out of the shipped plugin' {
        # A product skill that references this repo's build system is a bug.
        $shipped = Get-ChildItem -Path (Join-Path $RepoRoot 'plugins') -Filter 'SKILL.md' -Recurse -File -Force
        $shipped.Count | Should -BeGreaterThan 0

        foreach ($skill in $shipped) {
            $content = Get-Content $skill.FullName -Raw
            $content | Should -Not -Match 'Invoke-Build\.ps1' -Because "$($skill.Directory.Name) ships to users"
            $content | Should -Not -Match 'FunctionsToExport' -Because "$($skill.Directory.Name) ships to users"
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
}

Describe 'Golden rule: no tenant data committed' {

    It 'uses only contoso placeholders for SharePoint hosts' {
        # -Force so .github/ and .claude/ are scanned too - the instruction
        # files are exactly where a copy-pasted real tenant URL would land.
        $files = Get-ChildItem -Path $RepoRoot -Include '*.md', '*.ps1', '*.psm1', '*.psd1', '*.json', '*.yml' -Recurse -File -Force |
            Where-Object { $_.FullName -notmatch '[\\/](\.git|node_modules|out)[\\/]' }

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
