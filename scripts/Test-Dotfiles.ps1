#Requires -Version 7.0

<#
.SYNOPSIS
    Doctor command for dotfiles.
.DESCRIPTION
    Reports the full current state of the machine after Install-Dotfiles.ps1.
    Shows pass/fail for required configurations and displays current values
    for key settings — giving a complete picture of machine state.
    Run after Install-Dotfiles.ps1 to verify installation and inspect config.
#>

$ErrorActionPreference = 'Continue'
$script:Failures = 0

function Test-Check {
    param(
        [string] $Name,
        [scriptblock] $Test,
        [string] $Detail
    )

    try {
        $result = & $Test
        if ($result) {
            $suffix = if ($Detail) { " [$Detail]" } else { '' }
            Write-Host "  PASS: $Name$suffix" -ForegroundColor Magenta
        } else {
            $suffix = if ($Detail) { " (got: $Detail)" } else { '' }
            Write-Host "  FAIL: $Name$suffix" -ForegroundColor Red
            $script:Failures++
        }
    } catch {
        Write-Host "  FAIL: $Name ($_)" -ForegroundColor Red
        $script:Failures++
    }
}

function Write-InfoLine {
    param([string] $Label, [string] $Value)
    Write-Host "  INFO: $Label" -NoNewline -ForegroundColor Cyan
    Write-Host " = $(if ($Value) { $Value } else { '(not set)' })"
}

function Test-SymlinkTarget {
    param(
        [string] $Path,
        [string] $ExpectedTarget
    )

    if (-not (Test-Path $Path -ErrorAction SilentlyContinue)) { return $false }
    $item = Get-Item $Path -Force
    if ($item.LinkType -ne 'SymbolicLink') { return $false }
    if ($ExpectedTarget) { return ($item.Target -eq $ExpectedTarget) }
    return $true
}

$RepoRoot = $PSScriptRoot | Split-Path -Parent

# ---------------------------------------------------------------------------- #
# Symlinks
# ---------------------------------------------------------------------------- #
Write-Host "`nChecking symlinks..." -ForegroundColor Green

$Symlinks = @(
    @{ Target = $PROFILE.CurrentUserAllHosts;                                    Source = Join-Path $RepoRoot 'files\powershell\profile.ps1' }
    @{ Target = Join-Path $HOME '.copilot\copilot-instructions.md';              Source = Join-Path $RepoRoot 'files\copilot\copilot-instructions.md' }
    @{ Target = Join-Path $HOME '.copilot\agents';                               Source = Join-Path $RepoRoot 'files\copilot\agents' }
    @{ Target = Join-Path $HOME '.copilot\skills';                               Source = Join-Path $RepoRoot 'files\copilot\skills' }
    @{ Target = Join-Path $HOME '.Azure\AzConfig.json';                          Source = Join-Path $RepoRoot 'files\az\config.json' }
    @{ Target = Join-Path $HOME '.githooks';                                     Source = Join-Path $RepoRoot 'files\githooks' }
    @{ Target = Join-Path $HOME '.wslconfig';                                    Source = Join-Path $RepoRoot 'files\wsl\.wslconfig' }
    @{ Target = Join-Path $HOME '.docker\cli-plugins\docker-buildx.exe';         Source = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\docker-buildx.exe' }
    @{ Target = Join-Path $HOME '.docker\cli-plugins\docker-compose.exe';        Source = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\docker-compose.exe' }
)

foreach ($link in $Symlinks) {
    $tgt = $link.Target
    $src = $link.Source
    Test-Check "Symlink: $tgt" { Test-SymlinkTarget -Path $tgt -ExpectedTarget $src }
}

# ---------------------------------------------------------------------------- #
# Windows Registry Settings
# ---------------------------------------------------------------------------- #
Write-Host "`nChecking Windows registry settings..." -ForegroundColor Green

$RegistryChecks = @(
    @{ Name = 'Developer Mode';               Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock';     ValueName = 'AllowDevelopmentWithoutDevLicense'; Expected = 1 }
    @{ Name = 'Long paths enabled';           Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem';                  ValueName = 'LongPathsEnabled';                 Expected = 1 }
    @{ Name = 'Sudo inline mode';             Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo';               ValueName = 'Enabled';                          Expected = 3 }
    @{ Name = 'Dark theme (apps)';            Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'; ValueName = 'AppsUseLightTheme';                Expected = 0 }
    @{ Name = 'Dark theme (system)';          Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'; ValueName = 'SystemUsesLightTheme';             Expected = 0 }
    @{ Name = 'Show file extensions';         Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced';  ValueName = 'HideFileExt';                      Expected = 0 }
    @{ Name = 'Show hidden files';            Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced';  ValueName = 'Hidden';                           Expected = 1 }
    @{ Name = 'Taskbar centered';             Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced';  ValueName = 'TaskbarAl';                        Expected = 1 }
    @{ Name = 'Explorer full path titlebar';  Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced';  ValueName = 'FullPathAddress';                  Expected = 1 }
    @{ Name = 'Explorer opens to This PC';    Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced';  ValueName = 'LaunchTo';                         Expected = 1 }
    @{ Name = 'Explorer Git integration';     Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced';  ValueName = 'NavPaneShowVersionControl';         Expected = 1 }
    @{ Name = 'Start no web search';          Path = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer';                 ValueName = 'DisableSearchBoxSuggestions';      Expected = 1 }
    @{ Name = 'Start no recommendations';     Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced';  ValueName = 'Start_IrisRecommendations';        Expected = 0 }
)

foreach ($reg in $RegistryChecks) {
    $regPath     = $reg.Path
    $regValName  = $reg.ValueName
    $regExpected = $reg.Expected
    $regActual   = (Get-ItemProperty $regPath -Name $regValName -ErrorAction SilentlyContinue).$regValName
    Test-Check "Registry: $($reg.Name)" { $regActual -eq $regExpected } -Detail "$regActual"
}

# ---------------------------------------------------------------------------- #
# Environment Variables
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
    'MAVEN_OPTS'
)

foreach ($var in $EnvVars) {
    $val = [System.Environment]::GetEnvironmentVariable($var, 'Machine')
    Test-Check "Env: $var" { $null -ne $val } -Detail $val
}

# ---------------------------------------------------------------------------- #
# Config-patched files
# ---------------------------------------------------------------------------- #
Write-Host "`nChecking config-patched files..." -ForegroundColor Green

# Copilot config
$copilotConfig = Join-Path $HOME '.copilot\config.json'
if (Test-Path $copilotConfig) {
    $c = Get-Content $copilotConfig -Raw | ConvertFrom-Json
    Test-Check 'Copilot config: banner=always'        { $c.banner -eq 'always' }
    Test-Check 'Copilot config: theme=auto'           { $c.theme -eq 'auto' }
    Test-Check 'Copilot config: render_markdown=true' { $c.render_markdown -eq $true }
    Write-InfoLine 'Copilot config: model' $c.model
} else {
    Test-Check 'Copilot config.json exists' { $false }
}

# MCP config
$mcpConfig = Join-Path $HOME '.copilot\mcp-config.json'
if (Test-Path $mcpConfig) {
    $mcp = Get-Content $mcpConfig -Raw | ConvertFrom-Json -AsHashtable
    foreach ($srv in @('aspire', 'playwright', 'context7', 'winget')) {
        $srvKey = $srv
        Test-Check "MCP server present: $srv" { $mcp.mcpServers.ContainsKey($srvKey) }
    }
    Write-InfoLine 'MCP servers configured' ($mcp.mcpServers.Keys -join ', ')
} else {
    Test-Check 'Copilot mcp-config.json exists' { $false }
}

# Docker config
$dockerConfig = Join-Path $HOME '.docker\config.json'
if (Test-Path $dockerConfig) {
    $d = Get-Content $dockerConfig -Raw | ConvertFrom-Json
    Test-Check 'Docker config: credsStore=wincred' { $d.credsStore -eq 'wincred' }
} else {
    Test-Check 'Docker config.json exists' { $false }
}

# Podman auth
$podmanAuth = Join-Path $env:APPDATA 'containers\auth.json'
if (Test-Path $podmanAuth) {
    $p = Get-Content $podmanAuth -Raw | ConvertFrom-Json
    Test-Check 'Podman auth: credsStore=wincred' { $p.credsStore -eq 'wincred' }
} else {
    Test-Check 'Podman auth.json exists' { $false }
}

# Windows Terminal settings — default font
$wtSettingsPath = @(
    Get-ChildItem "$env:LOCALAPPDATA\Packages" -Filter 'Microsoft.WindowsTerminal*' -Directory -ErrorAction SilentlyContinue |
        ForEach-Object { Join-Path $_.FullName 'LocalState\settings.json' }
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($wtSettingsPath) {
    $raw   = Get-Content $wtSettingsPath -Raw
    $clean = [regex]::Replace($raw, '/\*[\s\S]*?\*/', '')
    $clean = [regex]::Replace($clean, '(?m)^\s*//.*$', '')
    $wt    = $clean | ConvertFrom-Json
    $face  = $wt.profiles.defaults.font.face
    Test-Check 'Terminal: default font = Cascadia Mono NF' { $face -eq 'Cascadia Mono NF' } -Detail $face
} else {
    Write-Host '  SKIP: Windows Terminal settings.json not found' -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------- #
# Git Global Config
# ---------------------------------------------------------------------------- #
Write-Host "`nChecking Git global config..." -ForegroundColor Green

$GitChecks = @(
    @{ Key = 'user.name';            Expected = 'Victor Frye' }
    @{ Key = 'user.email';           Expected = 'victorfrye@outlook.com' }
    @{ Key = 'init.defaultBranch';   Expected = 'main' }
    @{ Key = 'core.autocrlf';        Expected = 'false' }
    @{ Key = 'push.autoSetupRemote'; Expected = 'true' }
)

foreach ($gc in $GitChecks) {
    $key      = $gc.Key
    $expected = $gc.Expected
    $actual   = git config --global $key 2>$null
    Test-Check "Git: $key" { $actual -eq $expected } -Detail $actual
}

Write-InfoLine 'Git: core.editor' (git config --global core.editor 2>$null)

# ---------------------------------------------------------------------------- #
# PowerShell Modules
# ---------------------------------------------------------------------------- #
Write-Host "`nChecking PowerShell modules..." -ForegroundColor Green

foreach ($mod in @('Az', 'Pester', 'PSScriptAnalyzer', 'posh-git')) {
    $modName   = $mod
    $installed = Get-Module -Name $modName -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
    $version   = if ($installed) { $installed.Version.ToString() } else { $null }
    Test-Check "Module: $mod" { $null -ne $installed } -Detail $version
}

# ---------------------------------------------------------------------------- #
# Key Binaries
# ---------------------------------------------------------------------------- #
Write-Host "`nChecking key binaries..." -ForegroundColor Green

$Binaries = @(
    'git', 'gh', 'az', 'dotnet', 'pwsh', 'code-insiders', 'winget'
    'terraform', 'kubectl', 'docker', 'docker-credential-wincred'
    'helm', 'oh-my-posh', 'node', 'python', 'java', 'foundry', 'ollama', 'copilot'
)

foreach ($bin in $Binaries) {
    $binName = $bin
    Test-Check "Binary: $bin" { $null -ne (Get-Command $binName -ErrorAction SilentlyContinue) }
}

Write-Host ''
Write-InfoLine 'Node version'   (node --version 2>$null)
Write-InfoLine '.NET version'   (dotnet --version 2>$null)
Write-InfoLine 'Java version'   (java -version 2>&1 | Select-Object -First 1 | ForEach-Object { [string]$_ -replace '^.*?"(.+?)".*$', '$1' })
Write-InfoLine 'Python version' (python --version 2>$null)
Write-InfoLine 'gh auth user'   (gh api user --jq '.login' 2>$null)

# ---------------------------------------------------------------------------- #
# Fonts (user-scope)
# ---------------------------------------------------------------------------- #
Write-Host "`nChecking fonts (user-scope)..." -ForegroundColor Green

$UserFontsDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$Fonts = @(
    'CascadiaCode.ttf'
    'CascadiaCodeItalic.ttf'
    'CascadiaMono.ttf'
    'CascadiaMonoItalic.ttf'
    'CascadiaCodePL.ttf'
    'CascadiaCodePLItalic.ttf'
    'CascadiaMonoPL.ttf'
    'CascadiaMonoPLItalic.ttf'
    'CascadiaCodeNF.ttf'
    'CascadiaCodeNFItalic.ttf'
    'CascadiaMonoNF.ttf'
    'CascadiaMonoNFItalic.ttf'
)

foreach ($font in $Fonts) {
    $fontPath = Join-Path $UserFontsDir $font
    Test-Check "Font: $font" { Test-Path $fontPath }
}

# ---------------------------------------------------------------------------- #
# WSL
# ---------------------------------------------------------------------------- #
Write-Host "`nChecking WSL..." -ForegroundColor Green

Test-Check 'WSL: vmcompute service present' {
    $null -ne (Get-CimInstance -ClassName Win32_Service -Filter "Name='vmcompute'" -ErrorAction SilentlyContinue)
}

# ---------------------------------------------------------------------------- #
# Repo config file validity
# ---------------------------------------------------------------------------- #
Write-Host "`nChecking repo config file validity..." -ForegroundColor Green

$JsonFiles = @(
    Join-Path $RepoRoot 'files\copilot\config.json'
    Join-Path $RepoRoot 'files\copilot\mcp-config.json'
    Join-Path $RepoRoot 'files\az\config.json'
    Join-Path $RepoRoot 'files\docker\config.json'
    Join-Path $RepoRoot 'files\terminal\settings.json'
)

foreach ($json in $JsonFiles) {
    $leaf = Split-Path $json -Leaf
    Test-Check "Valid JSON: $leaf" { $null -ne (Get-Content $json -Raw | ConvertFrom-Json) }
}

Test-Check 'PowerShell profile syntax' {
    $profilePath = Join-Path $RepoRoot 'files\powershell\profile.ps1'
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($profilePath, [ref]$null, [ref]$errors)
    $errors.Count -eq 0
}

# ---------------------------------------------------------------------------- #
# Summary
# ---------------------------------------------------------------------------- #
Write-Host ''
if ($script:Failures -eq 0) {
    Write-Host 'All checks passed.' -ForegroundColor Magenta
} else {
    Write-Host "$($script:Failures) check(s) failed." -ForegroundColor Red
    exit 1
}

