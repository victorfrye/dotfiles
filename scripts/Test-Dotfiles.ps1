#Requires -Version 7.0

<#
.SYNOPSIS
    Doctor command for dotfiles.
.DESCRIPTION
    Runs health checks (pass/fail) then prints a system state report.
    Run after Install-Dotfiles.ps1 to verify installation and inspect
    the current configuration of the machine.
#>

$ErrorActionPreference = 'Continue'
$script:Failures  = 0
$script:Checks    = 0

# ---------------------------------------------------------------------------- #
# Helpers
# ---------------------------------------------------------------------------- #

function Write-Phase {
    param([string] $Title)
    $bar = [string]::new([char]0x2501, 65)  # ━
    Write-Host ''
    Write-Host $bar -ForegroundColor DarkCyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host $bar -ForegroundColor DarkCyan
}

function Write-Section {
    param([string] $Title)
    Write-Host ''
    Write-Host "  $Title" -ForegroundColor Yellow
}

function Test-Check {
    param(
        [string]      $Name,
        [scriptblock] $Test,
        [string]      $Detail
    )

    $script:Checks++
    try {
        $result = & $Test
        if ($result) {
            $suffix = if ($Detail) { "  $Detail" } else { '' }
            Write-Host "    [+] $Name" -NoNewline -ForegroundColor Green
            if ($suffix) { Write-Host $suffix -ForegroundColor DarkGray } else { Write-Host '' }
        } else {
            $suffix = if ($Detail) { "  (got: $Detail)" } else { '' }
            Write-Host "    [-] $Name$suffix" -ForegroundColor Red
            $script:Failures++
        }
    } catch {
        Write-Host "    [-] $Name  ($_)" -ForegroundColor Red
        $script:Failures++
    }
}

function Write-StateRow {
    param([string] $Label, [string] $Value, [int] $Width = 22)
    Write-Host "    $($Label.PadRight($Width))" -NoNewline -ForegroundColor DarkGray
    Write-Host $Value -ForegroundColor White
}

$RepoRoot = $PSScriptRoot | Split-Path -Parent

# ============================================================================ #
#  PHASE 1 — HEALTH CHECKS
# ============================================================================ #

Write-Phase 'HEALTH CHECKS'

# ---------------------------------------------------------------------------- #
Write-Section 'Symlinks'

function Test-SymlinkTarget {
    param([string] $Path, [string] $ExpectedTarget)
    if (-not (Test-Path $Path -ErrorAction SilentlyContinue)) { return $false }
    $item = Get-Item $Path -Force
    if ($item.LinkType -ne 'SymbolicLink') { return $false }
    if ($ExpectedTarget) { return ($item.Target -eq $ExpectedTarget) }
    return $true
}

$Symlinks = @(
    @{ Target = $PROFILE.CurrentUserAllHosts;                             Source = Join-Path $RepoRoot 'files\powershell\profile.ps1' }
    @{ Target = Join-Path $HOME '.copilot\copilot-instructions.md';       Source = Join-Path $RepoRoot 'files\copilot\copilot-instructions.md' }
    @{ Target = Join-Path $HOME '.copilot\agents';                        Source = Join-Path $RepoRoot 'files\copilot\agents' }
    @{ Target = Join-Path $HOME '.copilot\skills';                        Source = Join-Path $RepoRoot 'files\copilot\skills' }
    @{ Target = Join-Path $HOME '.Azure\AzConfig.json';                   Source = Join-Path $RepoRoot 'files\az\config.json' }
    @{ Target = Join-Path $HOME '.githooks';                              Source = Join-Path $RepoRoot 'files\githooks' }
    @{ Target = Join-Path $HOME '.wslconfig';                             Source = Join-Path $RepoRoot 'files\wsl\.wslconfig' }
    @{ Target = Join-Path $HOME '.docker\cli-plugins\docker-buildx.exe';  Source = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\docker-buildx.exe' }
    @{ Target = Join-Path $HOME '.docker\cli-plugins\docker-compose.exe'; Source = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\docker-compose.exe' }
)

foreach ($link in $Symlinks) {
    $tgt = $link.Target; $src = $link.Source
    Test-Check "$tgt" { Test-SymlinkTarget -Path $tgt -ExpectedTarget $src }
}

# ---------------------------------------------------------------------------- #
Write-Section 'Windows Settings'

$RegistryChecks = @(
    @{ Name = 'Developer Mode';              Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock';     ValueName = 'AllowDevelopmentWithoutDevLicense'; Expected = 1 }
    @{ Name = 'Long paths enabled';          Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem';                  ValueName = 'LongPathsEnabled';                 Expected = 1 }
    @{ Name = 'Sudo inline mode';            Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo';               ValueName = 'Enabled';                          Expected = 3 }
    @{ Name = 'Dark theme (apps)';           Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'; ValueName = 'AppsUseLightTheme';                Expected = 0 }
    @{ Name = 'Dark theme (system)';         Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'; ValueName = 'SystemUsesLightTheme';             Expected = 0 }
    @{ Name = 'Show file extensions';        Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced';  ValueName = 'HideFileExt';                      Expected = 0 }
    @{ Name = 'Show hidden files';           Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced';  ValueName = 'Hidden';                           Expected = 1 }
    @{ Name = 'Taskbar centered';            Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced';  ValueName = 'TaskbarAl';                        Expected = 1 }
    @{ Name = 'Explorer full path titlebar'; Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced';  ValueName = 'FullPathAddress';                  Expected = 1 }
    @{ Name = 'Explorer opens to This PC';   Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced';  ValueName = 'LaunchTo';                         Expected = 1 }
    @{ Name = 'Explorer Git integration';    Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced';  ValueName = 'NavPaneShowVersionControl';         Expected = 1 }
    @{ Name = 'Start — no web search';       Path = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer';                 ValueName = 'DisableSearchBoxSuggestions';      Expected = 1 }
    @{ Name = 'Start — no recommendations'; Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced';  ValueName = 'Start_IrisRecommendations';        Expected = 0 }
)

foreach ($reg in $RegistryChecks) {
    $regPath = $reg.Path; $regVal = $reg.ValueName; $regExp = $reg.Expected
    $actual  = (Get-ItemProperty $regPath -Name $regVal -ErrorAction SilentlyContinue).$regVal
    Test-Check $reg.Name { $actual -eq $regExp } -Detail "$actual"
}

# ---------------------------------------------------------------------------- #
Write-Section 'Environment Variables'

$EnvVars = @(
    'DEVDRIVE', 'REPOS_ROOT', 'REPOS_VF', 'PACKAGES_ROOT',
    'NPM_CONFIG_CACHE', 'NUGET_PACKAGES', 'PIP_CACHE_DIR',
    'DOTNET_ROOT', 'DOTNET_ENVIRONMENT', 'ASPNETCORE_ENVIRONMENT',
    'JAVA_HOME', 'MAVEN_OPTS'
)

foreach ($var in $EnvVars) {
    $val = [System.Environment]::GetEnvironmentVariable($var, 'Machine')
    Test-Check $var { $null -ne $val } -Detail $val
}

# ---------------------------------------------------------------------------- #
Write-Section 'Configuration Files'

$copilotConfig = Join-Path $HOME '.copilot\config.json'
if (Test-Path $copilotConfig) {
    $c = Get-Content $copilotConfig -Raw | ConvertFrom-Json
    Test-Check 'Copilot — banner = always'         { $c.banner -eq 'always' }
    Test-Check 'Copilot — theme = auto'            { $c.theme -eq 'auto' }
    Test-Check 'Copilot — render_markdown = true'  { $c.render_markdown -eq $true }
} else { Test-Check 'Copilot config.json' { $false } }

$mcpConfig = Join-Path $HOME '.copilot\mcp-config.json'
if (Test-Path $mcpConfig) {
    $mcp = Get-Content $mcpConfig -Raw | ConvertFrom-Json -AsHashtable
    foreach ($srv in @('aspire', 'playwright', 'context7', 'winget')) {
        $srvKey = $srv
        Test-Check "MCP — $srv" { $mcp.mcpServers.ContainsKey($srvKey) }
    }
} else { Test-Check 'Copilot mcp-config.json' { $false } }

$dockerConfig = Join-Path $HOME '.docker\config.json'
if (Test-Path $dockerConfig) {
    $d = Get-Content $dockerConfig -Raw | ConvertFrom-Json
    Test-Check 'Docker — credsStore = wincred' { $d.credsStore -eq 'wincred' }
} else { Test-Check 'Docker config.json' { $false } }

$podmanAuth = Join-Path $env:APPDATA 'containers\auth.json'
if (Test-Path $podmanAuth) {
    $p = Get-Content $podmanAuth -Raw | ConvertFrom-Json
    Test-Check 'Podman — credsStore = wincred' { $p.credsStore -eq 'wincred' }
} else { Test-Check 'Podman auth.json' { $false } }

$wtPath = @(
    Get-ChildItem "$env:LOCALAPPDATA\Packages" -Filter 'Microsoft.WindowsTerminal*' -Directory -ErrorAction SilentlyContinue |
        ForEach-Object { Join-Path $_.FullName 'LocalState\settings.json' }
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($wtPath) {
    $clean = [regex]::Replace((Get-Content $wtPath -Raw), '/\*[\s\S]*?\*/', '')
    $clean = [regex]::Replace($clean, '(?m)^\s*//.*$', '')
    $face  = ($clean | ConvertFrom-Json).profiles.defaults.font.face
    Test-Check 'Terminal — default font = Cascadia Mono NF' { $face -eq 'Cascadia Mono NF' } -Detail $face
} else { Write-Host '    [~] Terminal settings.json not found — skipping' -ForegroundColor DarkYellow }

# ---------------------------------------------------------------------------- #
Write-Section 'Git Configuration'

$GitChecks = @(
    @{ Key = 'user.name';            Expected = 'Victor Frye' }
    @{ Key = 'user.email';           Expected = 'victorfrye@outlook.com' }
    @{ Key = 'init.defaultBranch';   Expected = 'main' }
    @{ Key = 'core.autocrlf';        Expected = 'false' }
    @{ Key = 'push.autoSetupRemote'; Expected = 'true' }
)

foreach ($gc in $GitChecks) {
    $key = $gc.Key; $expected = $gc.Expected
    $actual = git config --global $key 2>$null
    Test-Check "git config $key" { $actual -eq $expected } -Detail $actual
}

# ---------------------------------------------------------------------------- #
Write-Section 'PowerShell Modules'

foreach ($mod in @('Az', 'Pester', 'PSScriptAnalyzer', 'posh-git')) {
    $modName   = $mod
    $installed = Get-Module -Name $modName -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
    $ver       = if ($installed) { $installed.Version.ToString() } else { $null }
    Test-Check $mod { $null -ne $installed } -Detail $ver
}

# ---------------------------------------------------------------------------- #
Write-Section 'Binaries'

$Binaries = @(
    'git', 'gh', 'az', 'dotnet', 'pwsh', 'code-insiders', 'winget',
    'terraform', 'kubectl', 'docker', 'docker-credential-wincred',
    'helm', 'oh-my-posh', 'node', 'python', 'java', 'foundry', 'ollama', 'copilot'
)

foreach ($bin in $Binaries) {
    $b = $bin
    Test-Check $bin { $null -ne (Get-Command $b -ErrorAction SilentlyContinue) }
}

# ---------------------------------------------------------------------------- #
Write-Section 'Fonts'

$UserFontsDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$Fonts = @(
    'CascadiaCode.ttf',        'CascadiaCodeItalic.ttf',
    'CascadiaMono.ttf',        'CascadiaMonoItalic.ttf',
    'CascadiaCodePL.ttf',      'CascadiaCodePLItalic.ttf',
    'CascadiaMonoPL.ttf',      'CascadiaMonoPLItalic.ttf',
    'CascadiaCodeNF.ttf',      'CascadiaCodeNFItalic.ttf',
    'CascadiaMonoNF.ttf',      'CascadiaMonoNFItalic.ttf'
)

foreach ($font in $Fonts) {
    $fp = Join-Path $UserFontsDir $font
    Test-Check $font { Test-Path $fp }
}

# ---------------------------------------------------------------------------- #
Write-Section 'WSL'

Test-Check 'vmcompute service' {
    $null -ne (Get-CimInstance -ClassName Win32_Service -Filter "Name='vmcompute'" -ErrorAction SilentlyContinue)
}

# ---------------------------------------------------------------------------- #
Write-Section 'Repository'

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

$profilePath = Join-Path $RepoRoot 'files\powershell\profile.ps1'
Test-Check 'PowerShell profile syntax' {
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($profilePath, [ref]$null, [ref]$errors)
    $errors.Count -eq 0
}

# ============================================================================ #
#  PHASE 2 — SYSTEM STATE
# ============================================================================ #

Write-Phase 'SYSTEM STATE'

# ---------------------------------------------------------------------------- #
Write-Section 'Runtimes'

Write-StateRow 'Node'   (node --version 2>$null)
Write-StateRow '.NET'   (dotnet --version 2>$null)
Write-StateRow 'Java'   (java -version 2>&1 | Select-Object -First 1 | ForEach-Object { [string]$_ -replace '^.*?"(.+?)".*$', '$1' })
Write-StateRow 'Python' (python --version 2>$null)

# ---------------------------------------------------------------------------- #
Write-Section 'Git Identity'

Write-StateRow 'user.name'    (git config --global user.name  2>$null)
Write-StateRow 'user.email'   (git config --global user.email 2>$null)
Write-StateRow 'core.editor'  (git config --global core.editor 2>$null)

# ---------------------------------------------------------------------------- #
Write-Section 'GitHub'

Write-StateRow 'User' (gh api user --jq '.login' 2>$null)

# ---------------------------------------------------------------------------- #
Write-Section 'Azure'

$azJson    = az account show --output json 2>$null
$azAccount = if ($azJson) { $azJson | ConvertFrom-Json -ErrorAction SilentlyContinue } else { $null }

if ($azAccount) {
    Write-StateRow 'User'         $azAccount.user.name
    Write-StateRow 'Subscription' "$($azAccount.name)  ($($azAccount.id))"
    Write-StateRow 'Tenant'       "$($azAccount.tenantDisplayName)  ($($azAccount.tenantId))"
} else {
    Write-StateRow 'Azure' '(not logged in)'
}

# ---------------------------------------------------------------------------- #
Write-Section 'Copilot'

if (Test-Path $copilotConfig) {
    $c = Get-Content $copilotConfig -Raw | ConvertFrom-Json
    Write-StateRow 'Model'           $c.model
    Write-StateRow 'Theme'           $c.theme
    Write-StateRow 'Render Markdown' $c.render_markdown
}

if (Test-Path $mcpConfig) {
    $mcp = Get-Content $mcpConfig -Raw | ConvertFrom-Json -AsHashtable
    Write-StateRow 'MCP Servers' ($mcp.mcpServers.Keys -join ', ')
}

# ============================================================================ #
#  SUMMARY
# ============================================================================ #

Write-Host ''
$bar = [string]::new([char]0x2501, 65)
Write-Host $bar -ForegroundColor DarkCyan
$passed = $script:Checks - $script:Failures
if ($script:Failures -eq 0) {
    Write-Host "  $passed checks passed" -ForegroundColor Green
} else {
    Write-Host "  $passed passed  " -NoNewline -ForegroundColor Green
    Write-Host "$($script:Failures) failed" -ForegroundColor Red
}
Write-Host $bar -ForegroundColor DarkCyan
Write-Host ''

if ($script:Failures -gt 0) { exit 1 }