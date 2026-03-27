#Requires -RunAsAdministrator

param(
    [string] $DevDriveLetter = 'W'
)

$ErrorActionPreference = 'Stop'

$MyName = 'Victor Frye'
$MyEmail = 'victorfrye@outlook.com'

$RepoUrl = 'https://github.com/victorfrye/dotfiles'
$RepoRoot = $null

# ---------------------------------------------------------------------------- #
# MARK: Git
# ---------------------------------------------------------------------------- #
function Initialize-Git {
    Write-Host 'Initializing Git...'

    winget install --exact --id Git.Git --source winget --accept-source-agreements --accept-package-agreements

    # Refresh PATH so git is available in this session
    $env:PATH = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' +
                [System.Environment]::GetEnvironmentVariable('PATH', 'User')

    git config --global user.name $MyName
    git config --global user.email $MyEmail
    git config --global core.editor edit
    git config --global core.symlinks true
    git config --global core.autocrlf false
    git config --global core.hookspath '~/.githooks'
    git config --global init.defaultBranch main
    git config --global push.autoSetupRemote true

    Write-Host 'Done. Git initialized.'
}

# ---------------------------------------------------------------------------- #
# MARK: Dev Drive
# ---------------------------------------------------------------------------- #
function Format-DevDrive {
    Write-Host 'Initializing Dev Drive...'

    $ExistingDrive = Get-Volume | Where-Object { $_.FileSystemLabel -eq 'DEVDRIVE' } | Select-Object -First 1

    if ($ExistingDrive) {
        $script:DevDriveLetter = $ExistingDrive.DriveLetter
        Write-Host "Skipped. Dev Drive already exists at $($script:DevDriveLetter):."
        return
    }

    Format-Volume -DriveLetter $DevDriveLetter -DevDrive
    Write-Host "Done. Dev Drive formatted at $($DevDriveLetter):."
}

# ---------------------------------------------------------------------------- #
# MARK: Repository
# ---------------------------------------------------------------------------- #
function Get-Repository {
    Write-Host 'Cloning dotfiles repository...'

    $script:RepoRoot = "$($DevDriveLetter):\Source\Repos\VictorFrye\Dotfiles"

    if (Test-Path -Path $script:RepoRoot) {
        Write-Host "Repository exists at $script:RepoRoot. Fetching latest..."
        Push-Location $script:RepoRoot
        git fetch --all
        git pull --ff-only origin main 2>$null
        Write-Host 'Done. Repository updated.'
        return
    }

    $ParentDir = Split-Path $script:RepoRoot -Parent
    if (-not (Test-Path $ParentDir)) {
        New-Item -ItemType Directory -Path $ParentDir -Force | Out-Null
    }

    git clone $RepoUrl $script:RepoRoot
    Push-Location $script:RepoRoot

    Write-Host "Done. Repository cloned to $script:RepoRoot."
}

# ---------------------------------------------------------------------------- #
# MARK: WinGet Configuration
# ---------------------------------------------------------------------------- #
function Invoke-WinGetConfiguration {
    Write-Host 'Applying WinGet Configuration...'

    $ConfigFile = Join-Path $script:RepoRoot '.config\configuration.winget'

    winget configure --file $ConfigFile --accept-configuration-agreements --disable-interactivity

    Write-Host 'Done. WinGet Configuration applied.'
}

# ---------------------------------------------------------------------------- #
# MARK: Symlinks
# ---------------------------------------------------------------------------- #
function New-SymlinkIfNeeded {
    param(
        [string] $Source,
        [string] $Target,
        [switch] $Directory
    )

    if (Test-Path -Path $Target) {
        $item = Get-Item $Target -Force
        if ($item.LinkType -eq 'SymbolicLink') {
            $existingTarget = $item.Target
            if ($existingTarget -eq $Source) {
                Write-Host "  Symlink already exists: $Target"
                return
            }
        }
        Remove-Item -Path $Target -Force -Recurse
    }

    $TargetParent = Split-Path $Target -Parent
    if (-not (Test-Path $TargetParent)) {
        New-Item -ItemType Directory -Path $TargetParent -Force | Out-Null
    }

    if ($Directory) {
        New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
    } else {
        New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
    }

    Write-Host "  Linked: $Target -> $Source"
}

function Set-Symlinks {
    Write-Host 'Creating symlinks...'

    # PowerShell profile
    New-SymlinkIfNeeded `
        -Source (Join-Path $script:RepoRoot 'files\powershell\profile.ps1') `
        -Target $PROFILE.CurrentUserAllHosts

    # Copilot CLI config files
    $CopilotSource = Join-Path $script:RepoRoot 'files\copilot'
    $CopilotDest = Join-Path $HOME '.copilot'

    foreach ($file in @('config.json', 'copilot-instructions.md', 'mcp-config.json')) {
        New-SymlinkIfNeeded `
            -Source (Join-Path $CopilotSource $file) `
            -Target (Join-Path $CopilotDest $file)
    }

    # Copilot agent definitions
    $AgentsSource = Join-Path $CopilotSource 'agents'
    $AgentsDest = Join-Path $CopilotDest 'agents'
    foreach ($agent in Get-ChildItem -Path $AgentsSource -Filter '*.md') {
        New-SymlinkIfNeeded `
            -Source $agent.FullName `
            -Target (Join-Path $AgentsDest $agent.Name)
    }

    # Azure CLI config
    New-SymlinkIfNeeded `
        -Source (Join-Path $script:RepoRoot 'files\az\config.json') `
        -Target (Join-Path $HOME '.Azure\AzConfig.json')

    # Git hooks directory
    New-SymlinkIfNeeded `
        -Source (Join-Path $script:RepoRoot 'files\githooks') `
        -Target (Join-Path $HOME '.githooks') `
        -Directory

    # Windows Terminal Preview settings
    $WtLocalState = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState'
    if (Test-Path (Split-Path $WtLocalState -Parent)) {
        New-SymlinkIfNeeded `
            -Source (Join-Path $script:RepoRoot 'files\terminal\settings.json') `
            -Target (Join-Path $WtLocalState 'settings.json')
    } else {
        Write-Host '  Skipped Windows Terminal symlink (package not yet installed).'
    }

    Write-Host 'Done. Symlinks created.'
}

# ---------------------------------------------------------------------------- #
# MARK: Environment Variables
# ---------------------------------------------------------------------------- #
function Set-EnvironmentVariables {
    Write-Host 'Setting environment variables...'

    $Drive = "$($DevDriveLetter):"

    # Dev Drive
    [System.Environment]::SetEnvironmentVariable('DEVDRIVE', $Drive, 'Machine')

    # Repository roots
    [System.Environment]::SetEnvironmentVariable('REPOS_ROOT', "$Drive\Source\Repos", 'Machine')
    [System.Environment]::SetEnvironmentVariable('REPOS_VF', "$Drive\Source\Repos\VictorFrye", 'Machine')

    # Package manager caches on Dev Drive
    [System.Environment]::SetEnvironmentVariable('PACKAGES_ROOT', "$Drive\Packages", 'Machine')
    [System.Environment]::SetEnvironmentVariable('NPM_CONFIG_CACHE', "$Drive\Packages\.npm", 'Machine')
    [System.Environment]::SetEnvironmentVariable('NUGET_PACKAGES', "$Drive\Packages\.nuget", 'Machine')
    [System.Environment]::SetEnvironmentVariable('PIP_CACHE_DIR', "$Drive\Packages\.pip", 'Machine')
    [System.Environment]::SetEnvironmentVariable('MAVEN_OPTS', "-Dmaven.repo.local=$Drive\Packages\.maven", 'Machine')

    # .NET
    [System.Environment]::SetEnvironmentVariable('DOTNET_ROOT', "$env:PROGRAMFILES\dotnet", 'Machine')
    [System.Environment]::SetEnvironmentVariable('DOTNET_ENVIRONMENT', 'Development', 'Machine')
    [System.Environment]::SetEnvironmentVariable('ASPNETCORE_ENVIRONMENT', 'Development', 'Machine')

    # Neovim
    [System.Environment]::SetEnvironmentVariable('NVIM_ROOT', "$env:PROGRAMFILES\Neovim", 'Machine')

    # Java — detect installed JDK versions dynamically
    $MsftDir = Join-Path $env:ProgramFiles 'Microsoft'
    foreach ($ver in @(17, 21, 25)) {
        $jdkDir = Get-ChildItem -Path $MsftDir -Filter "jdk-$ver*" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($jdkDir) {
            [System.Environment]::SetEnvironmentVariable("JDK_${ver}_HOME", $jdkDir.FullName, 'Machine')
        }
    }
    [System.Environment]::SetEnvironmentVariable('JAVA_HOME', "%JDK_25_HOME%", 'Machine')

    Write-Host 'Done. Environment variables set.'
}

# ---------------------------------------------------------------------------- #
# MARK: Orchestration
# ---------------------------------------------------------------------------- #
Write-Host "`n=== Installing dotfiles ===`n" -ForegroundColor Cyan

Initialize-Git
Format-DevDrive
Get-Repository
Invoke-WinGetConfiguration
Set-Symlinks
Set-EnvironmentVariables

Write-Host "`n=== Dotfiles installed successfully ===`n" -ForegroundColor Green
