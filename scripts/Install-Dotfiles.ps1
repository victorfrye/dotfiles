#Requires -RunAsAdministrator
#Requires -Version 7.0

<#
.SYNOPSIS
    Bootstrap script for Windows dotfiles.
.DESCRIPTION
    Initializes a Windows development machine by configuring Git,
    setting up a Dev Drive, cloning the dotfiles repository, applying
    WinGet Configuration, creating symlinks, deploying one-time config
    templates, and setting environment variables.

    All operations are idempotent — re-running safely skips or updates
    existing installations.
.PARAMETER Name
    Full name for Git configuration. Defaults to 'Victor Frye'.
.PARAMETER Email
    Email address for Git configuration. Defaults to 'victorfrye@outlook.com'.
.PARAMETER DevDriveLetter
    Drive letter to assign when creating a new Dev Drive. Defaults to 'W'.
    Ignored if an existing ReFS Dev Drive is detected.
.PARAMETER DevDriveSizeGB
    Size in GB for a new Dev Drive VHD. Defaults to 100.
    Minimum is 50 GB per Microsoft requirements.
.EXAMPLE
    .\Install-Dotfiles.ps1
.EXAMPLE
    .\Install-Dotfiles.ps1 -Name 'Jane Doe' -Email 'jane@example.com' -DevDriveLetter 'D' -DevDriveSizeGB 200
#>

param(
    [string] $Name = 'Victor Frye',
    [string] $Email = 'victorfrye@outlook.com',
    [string] $DevDriveLetter = 'W',
    [ValidateRange(50, 2048)]
    [int] $DevDriveSizeGB = 100
)

$ErrorActionPreference = 'Stop'

$RepoUrl = 'https://github.com/victorfrye/dotfiles'

# ---------------------------------------------------------------------------- #
# Helpers
# ---------------------------------------------------------------------------- #

function New-SymlinkIfNeeded {
    param(
        [string] $Source,
        [string] $Target,
        [switch] $Directory
    )

    if (Test-Path -Path $Target) {
        $item = Get-Item $Target -Force
        if ($item.LinkType -eq 'SymbolicLink' -and $item.Target -eq $Source) {
            Write-Host "  Symlink already exists: $Target" -ForegroundColor Gray
            return
        }
        Remove-Item -Path $Target -Force -Recurse
    }

    $TargetParent = Split-Path $Target -Parent
    if (-not (Test-Path $TargetParent)) {
        New-Item -ItemType Directory -Path $TargetParent -Force | Out-Null
    }

    New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
    Write-Host "  Linked: $Target -> $Source" -ForegroundColor Magenta
}

function Copy-IfNotExists {
    param(
        [string] $Source,
        [string] $Target
    )

    if (Test-Path -Path $Target) {
        Write-Host "  Already exists (skipped): $Target" -ForegroundColor Gray
        return
    }

    $TargetParent = Split-Path $Target -Parent
    if (-not (Test-Path $TargetParent)) {
        New-Item -ItemType Directory -Path $TargetParent -Force | Out-Null
    }

    Copy-Item -Path $Source -Destination $Target
    Write-Host "  Deployed: $Target" -ForegroundColor Magenta
}

# ---------------------------------------------------------------------------- #
# Git
# ---------------------------------------------------------------------------- #

Write-Host "`n=== Installing dotfiles ===`n" -ForegroundColor Green

Write-Host 'Initializing Git...' -ForegroundColor Green

winget install --exact --id Git.Git --source winget --accept-source-agreements --accept-package-agreements

$env:PATH = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' +
            [System.Environment]::GetEnvironmentVariable('PATH', 'User')

git config --global user.name $Name
git config --global user.email $Email
git config --global core.editor edit
git config --global core.symlinks true
git config --global core.autocrlf false
git config --global core.hookspath '~/.githooks'
git config --global init.defaultBranch main
git config --global push.autoSetupRemote true

Write-Host 'Done. Git initialized.' -ForegroundColor Magenta

# ---------------------------------------------------------------------------- #
# Dev Drive
# ---------------------------------------------------------------------------- #

Write-Host 'Initializing Dev Drive...' -ForegroundColor Green

$ScriptDriveLetter = if ($PSScriptRoot) { (Split-Path $PSScriptRoot -Qualifier) -replace ':$', '' } else { $null }
$ScriptVolume = if ($ScriptDriveLetter) { Get-Volume -DriveLetter $ScriptDriveLetter -ErrorAction SilentlyContinue } else { $null }

if ($ScriptVolume -and $ScriptVolume.FileSystemType -eq 'ReFS') {
    $DevDriveLetter = "$($ScriptDriveLetter):"
    Write-Host "Detected Dev Drive from script location at $DevDriveLetter." -ForegroundColor Magenta
} elseif (($RefsVolume = Get-Volume | Where-Object { $_.FileSystemType -eq 'ReFS' } | Select-Object -First 1)) {
    $DevDriveLetter = "$($RefsVolume.DriveLetter):"
    Write-Host "Detected existing Dev Drive at $DevDriveLetter." -ForegroundColor Magenta
} else {
    $VhdPath = 'C:\DevDrives\DevDrive.vhdx'
    New-Item -Path 'C:\DevDrives' -ItemType Directory -Force | Out-Null
    Write-Host "Creating $DevDriveSizeGB GB Dev Drive VHD at $VhdPath..." -ForegroundColor Green
    New-VHD -Path $VhdPath -SizeBytes ($DevDriveSizeGB * 1GB) -Dynamic -ErrorAction Stop |
        Mount-VHD -Passthru |
        Initialize-Disk -Passthru |
        New-Partition -DriveLetter $DevDriveLetter -UseMaximumSize |
        Format-Volume -DevDrive -FileSystem ReFS -NewFileSystemLabel 'DevDrive' -Confirm:$false -ErrorAction Stop
    $DevDriveLetter = "$($DevDriveLetter):"
    Write-Host "Done. Dev Drive created at $DevDriveLetter." -ForegroundColor Magenta
}

# ---------------------------------------------------------------------------- #
# Repository
# ---------------------------------------------------------------------------- #

Write-Host 'Cloning dotfiles repository...' -ForegroundColor Green

$RepoRoot = Join-Path $DevDriveLetter 'Source\Repos\VictorFrye\Dotfiles'

if (Test-Path -Path $RepoRoot) {
    Write-Host "Repository exists at $RepoRoot. Fetching latest..." -ForegroundColor Green
    Push-Location $RepoRoot
    git fetch --all
    git pull --ff-only origin main 2>$null
    Write-Host 'Done. Repository updated.' -ForegroundColor Magenta
} else {
    $ParentDir = Split-Path $RepoRoot -Parent
    if (-not (Test-Path $ParentDir)) {
        New-Item -ItemType Directory -Path $ParentDir -Force | Out-Null
    }

    git clone $RepoUrl $RepoRoot
    Push-Location $RepoRoot
    Write-Host "Done. Repository cloned to $RepoRoot." -ForegroundColor Magenta
}

# ---------------------------------------------------------------------------- #
# WinGet Configuration
# ---------------------------------------------------------------------------- #

Write-Host 'Applying WinGet Configuration...' -ForegroundColor Green

$ConfigFile = Join-Path $RepoRoot '.config\configuration.winget'
winget configure --file $ConfigFile --accept-configuration-agreements --disable-interactivity

Write-Host 'Done. WinGet Configuration applied.' -ForegroundColor Magenta

# ---------------------------------------------------------------------------- #
# Symlinks
# ---------------------------------------------------------------------------- #

Write-Host 'Creating symlinks...' -ForegroundColor Green

New-SymlinkIfNeeded `
    -Source (Join-Path $RepoRoot 'files\powershell\profile.ps1') `
    -Target $PROFILE.CurrentUserAllHosts

New-SymlinkIfNeeded `
    -Source (Join-Path $RepoRoot 'files\copilot\copilot-instructions.md') `
    -Target (Join-Path $HOME '.copilot\copilot-instructions.md')

New-SymlinkIfNeeded `
    -Source (Join-Path $RepoRoot 'files\copilot\agents') `
    -Target (Join-Path $HOME '.copilot\agents') `
    -Directory

New-SymlinkIfNeeded `
    -Source (Join-Path $RepoRoot 'files\az\config.json') `
    -Target (Join-Path $HOME '.Azure\AzConfig.json')

New-SymlinkIfNeeded `
    -Source (Join-Path $RepoRoot 'files\githooks') `
    -Target (Join-Path $HOME '.githooks') `
    -Directory

New-SymlinkIfNeeded `
    -Source (Join-Path $RepoRoot 'files\wsl\.wslconfig') `
    -Target (Join-Path $HOME '.wslconfig')

New-SymlinkIfNeeded `
    -Source (Join-Path $RepoRoot 'files\docker\config.json') `
    -Target (Join-Path $HOME '.docker\config.json')

Write-Host 'Done. Symlinks created.' -ForegroundColor Magenta

# ---------------------------------------------------------------------------- #
# One-time config deploys
# ---------------------------------------------------------------------------- #

Write-Host 'Deploying one-time config files...' -ForegroundColor Green

$CopilotSource = Join-Path $RepoRoot 'files\copilot'
$CopilotDest = Join-Path $HOME '.copilot'

foreach ($file in @('config.json', 'mcp-config.json')) {
    Copy-IfNotExists `
        -Source (Join-Path $CopilotSource $file) `
        -Target (Join-Path $CopilotDest $file)
}

$WtLocalState = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState'
if (Test-Path (Split-Path $WtLocalState -Parent)) {
    Copy-IfNotExists `
        -Source (Join-Path $RepoRoot 'files\terminal\settings.json') `
        -Target (Join-Path $WtLocalState 'settings.json')
} else {
    Write-Host '  Skipped Windows Terminal (not yet installed).' -ForegroundColor Gray
}

Write-Host 'Done. Config files deployed.' -ForegroundColor Magenta

# ---------------------------------------------------------------------------- #
# Environment variables
# ---------------------------------------------------------------------------- #

Write-Host 'Setting environment variables...' -ForegroundColor Green

[System.Environment]::SetEnvironmentVariable('DEVDRIVE', $DevDriveLetter, 'Machine')

[System.Environment]::SetEnvironmentVariable('REPOS_ROOT', "$DevDriveLetter\Source\Repos", 'Machine')
[System.Environment]::SetEnvironmentVariable('REPOS_VF', "$DevDriveLetter\Source\Repos\VictorFrye", 'Machine')

[System.Environment]::SetEnvironmentVariable('PACKAGES_ROOT', "$DevDriveLetter\Packages", 'Machine')
[System.Environment]::SetEnvironmentVariable('NPM_CONFIG_CACHE', "$DevDriveLetter\Packages\.npm", 'Machine')
[System.Environment]::SetEnvironmentVariable('NUGET_PACKAGES', "$DevDriveLetter\Packages\.nuget", 'Machine')
[System.Environment]::SetEnvironmentVariable('PIP_CACHE_DIR', "$DevDriveLetter\Packages\.pip", 'Machine')
[System.Environment]::SetEnvironmentVariable('MAVEN_OPTS', "-Dmaven.repo.local=$DevDriveLetter\Packages\.maven", 'Machine')

[System.Environment]::SetEnvironmentVariable('DOTNET_ROOT', "$env:PROGRAMFILES\dotnet", 'Machine')
[System.Environment]::SetEnvironmentVariable('DOTNET_ENVIRONMENT', 'Development', 'Machine')
[System.Environment]::SetEnvironmentVariable('ASPNETCORE_ENVIRONMENT', 'Development', 'Machine')

$MsftDir = Join-Path $env:ProgramFiles 'Microsoft'
foreach ($ver in @(17, 21, 25)) {
    $jdkDir = Get-ChildItem -Path $MsftDir -Filter "jdk-$ver*" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($jdkDir) {
        [System.Environment]::SetEnvironmentVariable("JDK_${ver}_HOME", $jdkDir.FullName, 'Machine')
    }
}
[System.Environment]::SetEnvironmentVariable('JAVA_HOME', "%JDK_25_HOME%", 'Machine')

foreach ($ver in @(20, 22, 24)) {
    $nodeDir = Get-ChildItem -Path $env:ProgramFiles -Filter "*node*$ver*" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($nodeDir) {
        [System.Environment]::SetEnvironmentVariable("NODE_${ver}_HOME", $nodeDir.FullName, 'Machine')
    }
}
[System.Environment]::SetEnvironmentVariable('NODE_HOME', '%NODE_24_HOME%', 'Machine')

Write-Host 'Done. Environment variables set.' -ForegroundColor Magenta

# ---------------------------------------------------------------------------- #

Write-Host "`n=== Dotfiles installed successfully ===`n" -ForegroundColor Green
