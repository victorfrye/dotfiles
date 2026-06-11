#Requires -RunAsAdministrator
#Requires -Version 7.0

<#
.SYNOPSIS
    Bootstrap script for Windows dotfiles.
.DESCRIPTION
    Initializes a Windows development machine by configuring Git,
    setting up a Dev Drive, cloning the dotfiles repository, applying
    WinGet Configuration, and setting environment variables.

    All operations are idempotent — re-running safely skips or updates
    existing installations.

    WinGet Configuration handles fonts, symlinks, Git global config,
    Docker CLI plugins, config file patching, PowerShell modules,
    Windows settings, and WSL installation as idempotent DSC resources.
.PARAMETER Name
    Full name for Git user.name configuration. Defaults to 'Victor Frye'.
.PARAMETER Email
    Email address for Git user.email configuration. Defaults to 'victorfrye@outlook.com'.
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
# Git
# ---------------------------------------------------------------------------- #

Write-Host "`n=== Installing dotfiles ===`n" -ForegroundColor Green

Write-Host 'Initializing Git...' -ForegroundColor Green

winget install --exact --id Git.Git --source winget --accept-source-agreements --accept-package-agreements

$env:PATH = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' +
            [System.Environment]::GetEnvironmentVariable('PATH', 'User')

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

$env:DOTFILES_ROOT = $RepoRoot

$ConfigFile = Join-Path $RepoRoot '.config\configuration.winget'
winget configure --file $ConfigFile --accept-configuration-agreements --disable-interactivity

Write-Host 'Done. WinGet Configuration applied.' -ForegroundColor Magenta

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

$nodejsPath = Join-Path $env:ProgramFiles 'nodejs'
if (Test-Path $nodejsPath) {
    $nodeExe = Join-Path $nodejsPath 'node.exe'
    if (Test-Path $nodeExe) {
        $nodeVersion = & $nodeExe --version 2>$null
        if ($nodeVersion -match 'v(\d+)\.') {
            $nodeMajor = [int]$Matches[1]
            [System.Environment]::SetEnvironmentVariable("NODE_${nodeMajor}_HOME", $nodejsPath, 'Machine')
        }
    }
    [System.Environment]::SetEnvironmentVariable('NODE_HOME', $nodejsPath, 'Machine')
}

Write-Host 'Done. Environment variables set.' -ForegroundColor Magenta

# ---------------------------------------------------------------------------- #

Write-Host 'Restarting Explorer to apply registry changes...' -ForegroundColor Cyan
Stop-Process -Name explorer -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------------- #

Write-Host "`n=== Dotfiles installed successfully ===`n" -ForegroundColor Green