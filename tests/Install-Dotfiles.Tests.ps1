#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    $RepoRoot   = (Get-Item $PSScriptRoot).Parent.FullName
    $ConfigFile = Join-Path $RepoRoot '.config\configuration.winget'
    $ConfigYaml = Get-Content $ConfigFile -Raw
}

# ---------------------------------------------------------------------------
# WinGet Configuration — schema and structure
# ---------------------------------------------------------------------------

Describe 'WinGet Configuration — schema' {
    It 'uses DSCv3 processor identifier' {
        $ConfigYaml | Should -Match 'identifier:\s*dscv3'
    }

    It 'references DSC document schema' {
        $ConfigYaml | Should -Match '\$schema:.*PowerShell/DSC'
    }

    It 'has a resources array' {
        $ConfigYaml | Should -Match 'resources:'
        # Note: winget configure validate is designed for DSCv2 and reports warnings for
        # DSCv3 resource types (Microsoft.Windows/Registry, Microsoft.WinGet/Package with
        # useLatest, Microsoft.DSC.Transitional/*). Structural validation is done above.
    }

    It 'has valid YAML indentation (no tab characters)' {
        $ConfigYaml | Should -Not -Match "`t"
    }
}

# ---------------------------------------------------------------------------
# WinGet Configuration — packages
# ---------------------------------------------------------------------------

Describe 'WinGet Configuration — packages' {
    $requiredPackages = @(
        'Git.Git'
        'GitHub.cli'
        'GitHub.Copilot.Prerelease'
        'Microsoft.Edit'
        'Microsoft.VisualStudioCode.Insiders'
        'BiomeJS.Biome'
        'Hugo.Hugo.Extended'
        'FiloSottile.mkcert'
        'Anchore.Syft'
        'Microsoft.Coreutils'
        'Microsoft.DotNet.SDK.Preview'
        'Microsoft.DotNet.SDK.10'
        'Microsoft.DotNet.SDK.9'
        'Microsoft.DotNet.SDK.8'
        'Microsoft.DotNet.AspNetCore.Preview'
        'Microsoft.DotNet.AspNetCore.10'
        'Microsoft.DotNet.AspNetCore.9'
        'Microsoft.DotNet.AspNetCore.8'
        'Microsoft.NuGet'
        'Microsoft.Aspire.Prerelease'
        'Microsoft.OpenJDK.25'
        'Microsoft.OpenJDK.21'
        'Microsoft.OpenJDK.17'
        'astral-sh.uv'
        'Python.Python.3.14'
        'OpenJS.NodeJS.LTS'
        'OpenJS.NodeJS.22'
        'OpenJS.NodeJS.20'
        'Microsoft.PowerShell'
        'Microsoft.PowerShell.Preview'
        'Microsoft.AzureCLI'
        'Microsoft.Azd'
        'Microsoft.Azure.FunctionsCoreTools'
        'Microsoft.Azure.StorageExplorer'
        'Hashicorp.Terraform'
        'Kubernetes.kubectl'
        'Helm.Helm'
        'Docker.DockerCLI'
        'Docker.DockerCompose'
        'Docker.Buildx'
        'Docker.docker-credential-wincred'
        'RedHat.Podman'
        'RedHat.Podman-Desktop'
        'Microsoft.FoundryLocal'
        'Ollama.Ollama'
        'Microsoft.Sqlcmd'
        'Microsoft.WindowsTerminal.Preview'
        'JanDeDobbeleer.OhMyPosh'
        'Microsoft.PowerToys'
        'Microsoft.Edge.Beta'
        'Microsoft.Edge.Canary'
        'Mozilla.Firefox'
        'Google.Chrome'
        'SlackTechnologies.Slack'
        'Discord.Discord'
        'Microsoft.Teams'
        'Microsoft.BingWallpaper'
    )

    It 'declares package <_>' -ForEach $requiredPackages {
        $ConfigYaml | Should -Match "id:\s*$([regex]::Escape($_))"
    }
}

# ---------------------------------------------------------------------------
# WinGet Configuration — registry resources
# ---------------------------------------------------------------------------

Describe 'WinGet Configuration — registry resources' {
    $requiredRegistryNames = @(
        'DeveloperMode'
        'LongPaths'
        'Sudo'
        'DarkThemeApps'
        'DarkThemeSystem'
        'ShowFileExtensions'
        'ShowHiddenFiles'
        'TaskbarAlignment'
        'ExplorerFullPath'
        'ExplorerOpenThisPC'
        'ExplorerGitIntegration'
        'StartNoWebSearch'
        'StartNoRecommendations'
        'TaskbarEndTask'
        'HideDesktopIcons'
    )

    It 'declares registry resource <_>' -ForEach $requiredRegistryNames {
        $ConfigYaml | Should -Match "name:\s*$_"
        $ConfigYaml | Should -Match 'type:\s*Microsoft\.Windows/Registry'
    }
}

# ---------------------------------------------------------------------------
# WinGet Configuration — DSC script resources
# ---------------------------------------------------------------------------

Describe 'WinGet Configuration — DSC script resources' {
    $requiredScriptNames = @(
        'poshGitModule'
        'azModule'
        'pesterModule'
        'psScriptAnalyzerModule'
        'CascadiaCodeNerdFonts'
        'TerminalDefaultFont'
        'TerminalDefaultProfile'
        'CopilotTerminalFragment'
        'GitGlobalConfig'
        'Symlinks'
        'FileExplorerVersionControlRoot'
        'DockerCLIPlugins'
        'CopilotSettingsPatch'
        'CopilotMcpConfigPatch'
        'DockerConfigPatch'
        'PodmanAuthPatch'
        'InstallWslComponents'
        'RebootForVmp'
        'InstallUbuntu'
        'GitHubSshKey'
        'GitHubSshGitProtocol'
        'GitHubCliAuth'
        'GitHubSshKeyUpload'
        'GitSigningConfig'
        'GitHubSshSigningKeyUpload'
        'GitRsaKey'
    )

    It 'declares DSC script resource <_>' -ForEach $requiredScriptNames {
        $ConfigYaml | Should -Match "name:\s*$_"
    }

    It 'uses Transitional PowerShellScript type' {
        $ConfigYaml | Should -Match 'Microsoft\.DSC\.Transitional/PowerShellScript'
    }

    It 'uses Transitional WindowsPowerShellScript type for WSL' {
        $ConfigYaml | Should -Match 'Microsoft\.DSC\.Transitional/WindowsPowerShellScript'
    }
}

# ---------------------------------------------------------------------------
# WinGet Configuration — DSC script resource patterns
# ---------------------------------------------------------------------------

Describe 'WinGet Configuration — DSC script resource patterns' {
    It 'each PowerShellScript resource has getScript, testScript, and setScript' {
        $resources = [regex]::Matches($ConfigYaml, 'type:\s*Microsoft\.DSC\.Transitional/PowerShellScript[\s\S]*?(?=- type:|$)')
        foreach ($match in $resources) {
            $block = $match.Value
            $block | Should -Match 'getScript:'
            $block | Should -Match 'testScript:'
            $block | Should -Match 'setScript:'
        }
    }
}

# ---------------------------------------------------------------------------
# JSON config files
# ---------------------------------------------------------------------------

Describe 'JSON config files' {
    $jsonFiles = @(
        'files\copilot\settings.json'
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

# ---------------------------------------------------------------------------
# Copilot skills — presence and front matter
# ---------------------------------------------------------------------------

Describe 'Copilot skills — presence and front matter' {
    $skills = @(
        'interviewer'
        'storywriter'
        'session-retrospective'
    )

    It 'contains a SKILL.md for <_>' -ForEach $skills {
        $filePath = Join-Path $RepoRoot "files\copilot\skills\$_\SKILL.md"
        $filePath | Should -Exist
    }

    It 'has compliant YAML front matter for <_>' -ForEach $skills {
        $filePath = Join-Path $RepoRoot "files\copilot\skills\$_\SKILL.md"
        $content  = Get-Content $filePath -Raw
        $content | Should -Match '(?s)^---\r?\n.*?\r?\n---\r?\n'

        $frontMatter = [regex]::Match($content, '(?s)^---\r?\n(.*?)\r?\n---\r?\n').Groups[1].Value
        $frontMatter | Should -Match "(?m)^name:\s*$_\s*$"
        $frontMatter | Should -Match '(?m)^description:\s*\S+'
    }
}


# ---------------------------------------------------------------------------
# PowerShell scripts — syntax
# ---------------------------------------------------------------------------

Describe 'PowerShell scripts — syntax' {
    $psFiles = @(
        'scripts\Install-Dotfiles.ps1'
        'scripts\Test-Dotfiles.ps1'
        'files\powershell\profile.ps1'
        'files\powershell\scripts\ConvertTo-Sha256Hash.ps1'
        'files\powershell\scripts\Get-Path.ps1'
        'files\powershell\scripts\Set-CopilotProvider.ps1'
        'files\powershell\scripts\Set-JavaVersion.ps1'
        'files\powershell\scripts\Set-NodeVersion.ps1'
        'files\powershell\scripts\Reset-Repositories.ps1'
        'files\powershell\scripts\Add-AzureDevOpsSshKey.ps1'
        'files\powershell\scripts\Add-GitHubSshKey.ps1'
        'files\powershell\scripts\Set-WorkspaceIdentity.ps1'
        'files\powershell\scripts\docker.ps1'
    )

    It 'has valid syntax in <_>' -ForEach $psFiles {
        $filePath = Join-Path $RepoRoot $_
        $filePath | Should -Exist
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$null, [ref]$errors)
        $errors | Should -BeNullOrEmpty
    }
}

# ---------------------------------------------------------------------------
# PowerShell scripts — PSScriptAnalyzer
# ---------------------------------------------------------------------------

Describe 'PowerShell scripts — PSScriptAnalyzer' {
    $psFiles = @(
        'scripts\Install-Dotfiles.ps1'
        'scripts\Test-Dotfiles.ps1'
        'files\powershell\profile.ps1'
        'files\powershell\scripts\ConvertTo-Sha256Hash.ps1'
        'files\powershell\scripts\Get-Path.ps1'
        'files\powershell\scripts\Set-CopilotProvider.ps1'
        'files\powershell\scripts\Set-JavaVersion.ps1'
        'files\powershell\scripts\Set-NodeVersion.ps1'
        'files\powershell\scripts\Reset-Repositories.ps1'
        'files\powershell\scripts\Add-AzureDevOpsSshKey.ps1'
        'files\powershell\scripts\Add-GitHubSshKey.ps1'
        'files\powershell\scripts\Set-WorkspaceIdentity.ps1'
        'files\powershell\scripts\docker.ps1'
    )

    It 'passes lint for <_>' -ForEach $psFiles {
        if (-not (Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
            Set-ItResult -Skipped -Because 'PSScriptAnalyzer is not installed'
            return
        }
        $filePath = Join-Path $RepoRoot $_
        $results = Invoke-ScriptAnalyzer -Path $filePath -Severity Error, Warning -ExcludeRule `
            PSAvoidUsingWriteHost,
            PSUseShouldProcessForStateChangingFunctions,
            PSUseSingularNouns,
            PSAvoidUsingInvokeExpression,
            PSUseBOMForUnicodeEncodedFile,
            PSReviewUnusedParameter
        $results | Should -BeNullOrEmpty
    }
}

# ---------------------------------------------------------------------------
# Repository structure
# ---------------------------------------------------------------------------

Describe 'Repository structure' {
    $expectedFiles = @(
        '.config\configuration.winget'
        'scripts\Install-Dotfiles.ps1'
        'scripts\Test-Dotfiles.ps1'
        'files\powershell\profile.ps1'
        'files\powershell\yfnd.omp.json'
        'files\powershell\scripts\ConvertTo-Sha256Hash.ps1'
        'files\powershell\scripts\Get-Path.ps1'
        'files\powershell\scripts\Set-CopilotProvider.ps1'
        'files\powershell\scripts\Set-JavaVersion.ps1'
        'files\powershell\scripts\Set-NodeVersion.ps1'
        'files\powershell\scripts\Reset-Repositories.ps1'
        'files\powershell\scripts\Add-AzureDevOpsSshKey.ps1'
        'files\powershell\scripts\Add-GitHubSshKey.ps1'
        'files\powershell\scripts\Set-WorkspaceIdentity.ps1'
        'files\powershell\scripts\docker.ps1'
        'files\az\config.json'
        'files\copilot\settings.json'
        'files\copilot\copilot-instructions.md'
        'files\copilot\mcp-config.json'
        'files\copilot\skills\interviewer\SKILL.md'
        'files\copilot\skills\storywriter\SKILL.md'
        'files\copilot\skills\session-retrospective\SKILL.md'
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