#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    $RepoRoot = (Get-Item $PSScriptRoot).Parent.FullName
}

Describe 'WinGet Configuration' {
    It 'validates without errors' {
        $configFile = Join-Path $RepoRoot '.config\configuration.winget'
        $configFile | Should -Exist

        $output = winget configure validate --file $configFile 2>&1
        $LASTEXITCODE | Should -Be 0
        ($output | Out-String) | Should -Match 'no issues'
    }
}

Describe 'JSON config files' {
    $jsonFiles = @(
        'files\copilot\config.json'
        'files\copilot\mcp-config.json'
        'files\az\config.json'
        'files\docker\config.json'
        'files\terminal\settings.json'
    )

    It 'parses <_> as valid JSON' -ForEach $jsonFiles {
        $filePath = Join-Path $RepoRoot $_
        $filePath | Should -Exist
        { Get-Content $filePath -Raw | ConvertFrom-Json } | Should -Not -Throw
    }
}

Describe 'PowerShell scripts' {
    $psFiles = @(
        'scripts\Install-Dotfiles.ps1'
        'scripts\Test-Dotfiles.ps1'
        'files\powershell\profile.ps1'
    )

    It 'has valid syntax in <_>' -ForEach $psFiles {
        $filePath = Join-Path $RepoRoot $_
        $filePath | Should -Exist
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$null, [ref]$errors)
        $errors | Should -BeNullOrEmpty
    }
}

Describe 'PSScriptAnalyzer' {
    $psFiles = @(
        'scripts\Install-Dotfiles.ps1'
        'scripts\Test-Dotfiles.ps1'
        'files\powershell\profile.ps1'
    )

    It 'passes lint for <_>' -ForEach $psFiles {
        if (-not (Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
            Set-ItResult -Skipped -Because 'PSScriptAnalyzer is not installed'
            return
        }
        $filePath = Join-Path $RepoRoot $_
        $results = Invoke-ScriptAnalyzer -Path $filePath -Severity Error, Warning -ExcludeRule PSAvoidUsingWriteHost, PSUseShouldProcessForStateChangingFunctions, PSUseSingularNouns, PSAvoidUsingInvokeExpression, PSUseBOMForUnicodeEncodedFile, PSReviewUnusedParameter
        $results | Should -BeNullOrEmpty
    }
}

Describe 'Repository structure' {
    $expectedFiles = @(
        '.config\configuration.winget'
        'scripts\Install-Dotfiles.ps1'
        'scripts\Test-Dotfiles.ps1'
        'files\powershell\profile.ps1'
        'files\powershell\yfnd.omp.json'
        'files\az\config.json'
        'files\copilot\config.json'
        'files\copilot\copilot-instructions.md'
        'files\copilot\mcp-config.json'
        'files\githooks\pre-commit'
        'files\terminal\settings.json'
        'files\wsl\.wslconfig'
        'files\docker\config.json'
        'README.md'
        'AGENTS.md'
    )

    It 'contains <_>' -ForEach $expectedFiles {
        $filePath = Join-Path $RepoRoot $_
        $filePath | Should -Exist
    }
}
