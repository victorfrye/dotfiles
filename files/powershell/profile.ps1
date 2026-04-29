# MARK: Environment Variables
$env:SRC_VFDOT = Join-Path $env:REPOS_VF 'Dotfiles'
$env:SRC_VFCOM = Join-Path $env:REPOS_VF 'DotCom'
$env:SRC_VFMSG = Join-Path $env:REPOS_VF 'MicrosoftGraveyard'
$env:SRC_VFMIR = Join-Path $env:REPOS_VF 'MockingMirror'
$env:SRC_VFSHG = Join-Path $env:REPOS_VF 'ShrugMan'

# MARK: Secrets — loaded from env.ps1 (gitignored, never committed)
$EnvFile = Join-Path $env:SRC_VFDOT 'env.ps1'
if (Test-Path $EnvFile) { . $EnvFile }

## Company repos — configure in env.ps1:
##   $env:REPOS_CO = Join-Path $env:REPOS_ROOT '<CompanyOrg>'
##   $env:SRC_CO* = Join-Path $env:REPOS_CO '<RepoName>'

## Client repos — configure in env.ps1:
##   $env:REPOS_CL = Join-Path $env:REPOS_ROOT '<ClientOrg>'
##   $env:SRC_CL* = Join-Path $env:REPOS_CL '<RepoName>'

# MARK: Oh My Posh
oh-my-posh init pwsh --config "$env:SRC_VFDOT\files\powershell\yfnd.omp.json" | Invoke-Expression

# MARK: Posh Git
Import-Module posh-git

# MARK: Aliases
Set-Alias -Name code -Value code-insiders

# MARK: Navigation — Personal Projects
function Set-LocationToVictorFryeRepositories { Set-Location $env:REPOS_VF }
function Set-LocationToVictorFryeDotfiles { Set-Location $env:SRC_VFDOT }
function Set-LocationToVictorFryeDotCom { Set-Location $env:SRC_VFCOM }
function Set-LocationToMicrosoftGraveyard { Set-Location $env:SRC_VFMSG }
function Set-LocationToMockingMirror { Set-Location $env:SRC_VFMIR }
function Set-LocationToShrugMan { Set-Location $env:SRC_VFSHG }

Set-Alias -Name slvf  -Value Set-LocationToVictorFryeRepositories
Set-Alias -Name sldot -Value Set-LocationToVictorFryeDotfiles
Set-Alias -Name slcom -Value Set-LocationToVictorFryeDotCom
Set-Alias -Name slmsg -Value Set-LocationToMicrosoftGraveyard
Set-Alias -Name slmir -Value Set-LocationToMockingMirror
Set-Alias -Name slshg -Value Set-LocationToShrugMan

## Company project navigation — configure in env.ps1:
##   function Set-LocationToCompanyRepos { Set-Location $env:REPOS_CO }
##   Set-Alias -Name slco -Value Set-LocationToCompanyRepos

## Client project navigation — configure in env.ps1:
##   function Set-LocationToClientRepos { Set-Location $env:REPOS_CL }
##   Set-Alias -Name slcl -Value Set-LocationToClientRepos

# MARK: App Launchers — Personal Projects
function Start-VictorFryeDotComApp { dotnet run --project "$env:SRC_VFCOM/src/AppHost/AppHost.csproj" }
function Start-MicrosoftGraveyardApp { dotnet run --project "$env:SRC_VFMSG/src/AppHost/AppHost.csproj" }
function Start-MockingMirrorApp { dotnet run --project "$env:SRC_VFMIR/src/AppHost/AppHost.csproj" }
function Start-ShrugManApp { dotnet run --project "$env:SRC_VFSHG/src/AppHost/AppHost.csproj" }

Set-Alias -Name sacom -Value Start-VictorFryeDotComApp
Set-Alias -Name samsg -Value Start-MicrosoftGraveyardApp
Set-Alias -Name samir -Value Start-MockingMirrorApp
Set-Alias -Name sashg -Value Start-ShrugManApp

# MARK: Scripts
$ScriptsDir = Join-Path $env:SRC_VFDOT 'files\powershell\scripts'
if (Test-Path $ScriptsDir) {
    Get-ChildItem -Path $ScriptsDir -Filter '*.ps1' | ForEach-Object { . $_.FullName }
}
