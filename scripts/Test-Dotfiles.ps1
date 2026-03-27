#Requires -Version 7.0

<#
.SYNOPSIS
    Post-install verification for dotfiles.
.DESCRIPTION
    Checks that symlinks, one-time deploys, environment variables,
    key binaries, and configuration files are set up correctly.
    Run after Install-Dotfiles.ps1 to verify the installation.
#>

$ErrorActionPreference = 'Continue'
$script:Failures = 0

function Test-Check {
    param(
        [string] $Name,
        [scriptblock] $Test
    )

    try {
        $result = & $Test
        if ($result) {
            Write-Host "  PASS: $Name" -ForegroundColor Magenta
        } else {
            Write-Host "  FAIL: $Name" -ForegroundColor Red
            $script:Failures++
        }
    } catch {
        Write-Host "  FAIL: $Name ($_)" -ForegroundColor Red
        $script:Failures++
    }
}

function Test-SymlinkTarget {
    param(
        [string] $Path
    )

    if (-not (Test-Path $Path)) { return $false }
    $item = Get-Item $Path -Force
    return ($item.LinkType -eq 'SymbolicLink')
}

# ---------------------------------------------------------------------------- #
# Symlinks
# ---------------------------------------------------------------------------- #
Write-Host "`nChecking symlinks..." -ForegroundColor Green

$RepoRoot = $PSScriptRoot | Split-Path -Parent

$Symlinks = @(
    @{ Target = $PROFILE.CurrentUserAllHosts;                       Source = (Join-Path $RepoRoot 'files\powershell\profile.ps1') }
    @{ Target = (Join-Path $HOME '.copilot\copilot-instructions.md'); Source = (Join-Path $RepoRoot 'files\copilot\copilot-instructions.md') }
    @{ Target = (Join-Path $HOME '.copilot\agents');                Source = (Join-Path $RepoRoot 'files\copilot\agents') }
    @{ Target = (Join-Path $HOME '.Azure\AzConfig.json');           Source = (Join-Path $RepoRoot 'files\az\config.json') }
    @{ Target = (Join-Path $HOME '.githooks');                      Source = (Join-Path $RepoRoot 'files\githooks') }
    @{ Target = (Join-Path $HOME '.wslconfig');                     Source = (Join-Path $RepoRoot 'files\wsl\.wslconfig') }
    @{ Target = (Join-Path $HOME '.docker\config.json');            Source = (Join-Path $RepoRoot 'files\docker\config.json') }
)

foreach ($link in $Symlinks) {
    Test-Check "Symlink: $($link.Target)" {
        Test-SymlinkTarget -Path $link.Target -ExpectedTarget $link.Source
    }
}

# ---------------------------------------------------------------------------- #
# One-time deploys
# ---------------------------------------------------------------------------- #
Write-Host "`nChecking one-time deploy targets..." -ForegroundColor Green

$Deploys = @(
    (Join-Path $HOME '.copilot\config.json')
    (Join-Path $HOME '.copilot\mcp-config.json')
)

$WtSettings = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'
if (Test-Path (Split-Path $WtSettings -Parent)) {
    $Deploys += $WtSettings
}

foreach ($file in $Deploys) {
    Test-Check "Exists: $file" { Test-Path $file }
}

# ---------------------------------------------------------------------------- #
# Environment variables
# ---------------------------------------------------------------------------- #
Write-Host "`nChecking environment variables..." -ForegroundColor Green

$EnvVars = @(
    'DEVDRIVE'
    'REPOS_ROOT'
    'REPOS_VF'
    'PACKAGES_ROOT'
    'NPM_CONFIG_CACHE'
    'NUGET_PACKAGES'
    'PIP_CACHE_DIR'
    'DOTNET_ROOT'
    'DOTNET_ENVIRONMENT'
    'ASPNETCORE_ENVIRONMENT'
    'JAVA_HOME'
)

foreach ($var in $EnvVars) {
    Test-Check "Env: $var" {
        $null -ne [System.Environment]::GetEnvironmentVariable($var, 'Machine')
    }
}

# ---------------------------------------------------------------------------- #
# Key binaries on PATH
# ---------------------------------------------------------------------------- #
Write-Host "`nChecking key binaries on PATH..." -ForegroundColor Green

$Binaries = @(
    'git'
    'dotnet'
    'pwsh'
    'code-insiders'
    'winget'
    'terraform'
    'kubectl'
    'docker'
    'helm'
    'oh-my-posh'
    'node'
    'python'
    'java'
)

foreach ($bin in $Binaries) {
    Test-Check "Binary: $bin" { $null -ne (Get-Command $bin -ErrorAction SilentlyContinue) }
}

# ---------------------------------------------------------------------------- #
# Config file validity
# ---------------------------------------------------------------------------- #
Write-Host "`nChecking config file validity..." -ForegroundColor Green

$JsonFiles = @(
    (Join-Path $RepoRoot 'files\copilot\config.json')
    (Join-Path $RepoRoot 'files\copilot\mcp-config.json')
    (Join-Path $RepoRoot 'files\az\config.json')
    (Join-Path $RepoRoot 'files\docker\config.json')
    (Join-Path $RepoRoot 'files\terminal\settings.json')
)

foreach ($json in $JsonFiles) {
    Test-Check "Valid JSON: $(Split-Path $json -Leaf)" {
        $null -ne (Get-Content $json -Raw | ConvertFrom-Json)
    }
}

Test-Check "PowerShell profile syntax" {
    $profilePath = Join-Path $RepoRoot 'files\powershell\profile.ps1'
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($profilePath, [ref]$null, [ref]$errors)
    $errors.Count -eq 0
}

# ---------------------------------------------------------------------------- #
# Summary
# ---------------------------------------------------------------------------- #
Write-Host ""
if ($script:Failures -eq 0) {
    Write-Host "All checks passed." -ForegroundColor Magenta
} else {
    Write-Host "$($script:Failures) check(s) failed." -ForegroundColor Red
    exit 1
}
