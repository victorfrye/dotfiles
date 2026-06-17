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
            $suffix = if ($Detail) { "  $Detail" } else { '' }
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
    @{ Name = 'Taskbar show end task';       Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced';  ValueName = 'TaskbarEndTask';                   Expected = 1 }
    @{ Name = 'Desktop hide icons';          Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced';  ValueName = 'HideIcons';                        Expected = 1 }
    @{ Name = 'Explorer full path titlebar'; Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced';  ValueName = 'FullPathAddress';                  Expected = 1 }
    @{ Name = 'Explorer opens to This PC';   Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced';  ValueName = 'LaunchTo';                         Expected = 1 }
    @{ Name = 'Explorer Git integration';    Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced';  ValueName = 'NavPaneShowVersionControl';         Expected = 1 }
    @{ Name = 'Start — no web search';       Path = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer';                 ValueName = 'DisableSearchBoxSuggestions';      Expected = 1 }
    @{ Name = 'Start — no recommendations'; Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced';  ValueName = 'Start_IrisRecommendations';        Expected = 0 }
)

foreach ($reg in $RegistryChecks) {
    $regPath   = $reg.Path; $regVal = $reg.ValueName; $regExp = $reg.Expected
    $actual    = (Get-ItemProperty $regPath -Name $regVal -ErrorAction SilentlyContinue).$regVal
    $detailStr = if ($null -ne $actual) { "$actual" } else { '(not set)' }
    Test-Check $reg.Name { $actual -eq $regExp } -Detail $detailStr
}

$vcRootRegPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\PerFolderRoots'
$vcRootEntry   = if (Test-Path $vcRootRegPath) {
    Get-ChildItem $vcRootRegPath -ErrorAction SilentlyContinue |
        ForEach-Object { Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue } |
        Where-Object { $_.Path -eq $env:REPOS_ROOT } |
        Select-Object -First 1
}
$vcRootDetail  = if ($vcRootEntry) { $env:REPOS_ROOT } else { '(not set)' }
Test-Check 'Explorer version control root' { $null -ne $vcRootEntry } -Detail $vcRootDetail

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

$copilotSettings = Join-Path $HOME '.copilot\settings.json'
if (Test-Path $copilotSettings) {
    $c = Get-Content $copilotSettings -Raw | ConvertFrom-Json
    Test-Check 'Copilot — banner = always'          { $c.banner -eq 'always' }
    Test-Check 'Copilot — theme = auto'             { $c.theme -eq 'auto' }
    Test-Check 'Copilot — renderMarkdown = true'    { $c.renderMarkdown -eq $true }
    Test-Check 'Copilot — footer configured'        { $null -ne $c.footer -and $c.footer.showContextWindow -eq $true }
} else { Test-Check 'Copilot settings.json' { $false } }

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
    @{ Key = 'user.name';                 Expected = 'Victor Frye' }
    @{ Key = 'user.email';                Expected = 'victorfrye@outlook.com' }
    @{ Key = 'init.defaultBranch';        Expected = 'main' }
    @{ Key = 'core.autocrlf';             Expected = 'false' }
    @{ Key = 'push.autoSetupRemote';      Expected = 'true' }
    @{ Key = 'gpg.format';                Expected = 'ssh' }
    @{ Key = 'user.signingKey';           Expected = '~/.ssh/id_ed25519.pub' }
    @{ Key = 'commit.gpgsign';            Expected = 'true' }
    @{ Key = 'tag.gpgsign';              Expected = 'true' }
    @{ Key = 'gpg.ssh.allowedSignersFile'; Expected = '~/.ssh/allowed_signers' }
)

foreach ($gc in $GitChecks) {
    $key = $gc.Key; $expected = $gc.Expected
    $actual = git config --global $key 2>$null
    Test-Check "git config $key" { $actual -eq $expected } -Detail $actual
}

$ghGitProtocol = gh config get git_protocol 2>$null
Test-Check 'gh config git_protocol' { $ghGitProtocol -eq 'ssh' } -Detail $ghGitProtocol

# ---------------------------------------------------------------------------- #
Write-Section 'SSH Configuration'

$sshKeyFile     = Join-Path $HOME '.ssh\id_ed25519'
$sshPubKeyFile  = "$sshKeyFile.pub"
$sshFingerprint = if (Test-Path $sshPubKeyFile) { ssh-keygen -l -f $sshPubKeyFile 2>$null } else { $null }
Test-Check 'id_ed25519 key' { Test-Path $sshKeyFile } -Detail $sshFingerprint

$rsaKeyFile     = Join-Path $HOME '.ssh\id_rsa'
$rsaPubKeyFile  = "$rsaKeyFile.pub"
$rsaFingerprint = if (Test-Path $rsaPubKeyFile) { ssh-keygen -l -f $rsaPubKeyFile 2>$null } else { $null }
Test-Check 'id_rsa key' { Test-Path $rsaKeyFile } -Detail $rsaFingerprint

$allowedSigners = Join-Path $HOME '.ssh\allowed_signers'
Test-Check 'allowed_signers' { Test-Path $allowedSigners } -Detail $allowedSigners

$pubKeyBody = if (Test-Path $sshPubKeyFile) { (Get-Content $sshPubKeyFile -Raw).Trim().Split(' ')[1] } else { $null }

$authKeysRaw  = gh api user/keys 2>$null
$authApiOk    = $LASTEXITCODE -eq 0
$authUploaded = if ($authApiOk -and $pubKeyBody) {
    $k = $authKeysRaw | ConvertFrom-Json -ErrorAction SilentlyContinue
    ($k | Where-Object { $_.key -and $_.key.Trim().Split(' ')[1] -eq $pubKeyBody } | Measure-Object).Count -gt 0
} else { $false }
$authDetail   = if (-not $authApiOk) { '(requires admin:public_key scope)' } elseif ($authUploaded) { 'registered' } else { 'not uploaded' }
Test-Check 'gh ssh-key auth' { $authUploaded } -Detail $authDetail

$signKeysRaw  = gh api user/ssh_signing_keys 2>$null
$signApiOk    = $LASTEXITCODE -eq 0
$signUploaded = if ($signApiOk -and $pubKeyBody) {
    $k = $signKeysRaw | ConvertFrom-Json -ErrorAction SilentlyContinue
    ($k | Where-Object { $_.key -and $_.key.Trim().Split(' ')[1] -eq $pubKeyBody } | Measure-Object).Count -gt 0
} else { $false }
$signDetail   = if (-not $signApiOk) { '(requires admin:ssh_signing_key scope)' } else { if ($signUploaded) { 'registered' } else { 'not uploaded' } }
Test-Check 'gh ssh-key signing' { $signUploaded } -Detail $signDetail

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
    'aspire', 'az', 'code-insiders', 'copilot', 'docker', 'docker-credential-wincred',
    'dotnet', 'foundry', 'gh', 'git', 'helm', 'java', 'kubectl',
    'node', 'oh-my-posh', 'ollama', 'pwsh', 'python', 'terraform', 'winget'
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
    Join-Path $RepoRoot 'files\copilot\settings.json'
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

Write-StateRow 'user.name'             (git config --global user.name  2>$null)
Write-StateRow 'user.email'            (git config --global user.email 2>$null)
Write-StateRow 'core.editor'           (git config --global core.editor 2>$null)
Write-StateRow 'gpg.format'            (git config --global gpg.format 2>$null)
Write-StateRow 'commit.gpgsign'        (git config --global commit.gpgsign 2>$null)

# ---------------------------------------------------------------------------- #
Write-Section 'SSH Keys'

Get-ChildItem -Path (Join-Path $HOME '.ssh') -Filter '*.pub' -ErrorAction SilentlyContinue | ForEach-Object {
    $info = ssh-keygen -l -f $_.FullName 2>$null
    if ($info) {
        $parts = $info.Trim().Split(' ')
        Write-StateRow $_.BaseName "$($parts[0]) $($parts[1]) $($parts[-1])"
    }
}

# ---------------------------------------------------------------------------- #
Write-Section 'GitHub'

Write-StateRow 'User'           (gh api user --jq '.login' 2>$null)
Write-StateRow 'Git Protocol'   (gh config get git_protocol 2>$null)

$authKeysRaw = gh api user/keys 2>$null
$authKeys    = if ($LASTEXITCODE -eq 0 -and $authKeysRaw) { ($authKeysRaw | ConvertFrom-Json | ForEach-Object { $_.title }) -join ', ' } else { $null }
Write-StateRow 'SSH Auth Keys'  $authKeys

$signKeysRaw = gh api user/ssh_signing_keys 2>$null
$signKeys    = if ($LASTEXITCODE -eq 0 -and $signKeysRaw) { ($signKeysRaw | ConvertFrom-Json | ForEach-Object { $_.title }) -join ', ' } else { $null }
Write-StateRow 'SSH Sign Keys'  $signKeys

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

if (Test-Path $copilotSettings) {
    $c = Get-Content $copilotSettings -Raw | ConvertFrom-Json
    Write-StateRow 'Model' $c.model
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