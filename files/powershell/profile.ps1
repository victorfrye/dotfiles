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

# MARK: Scripts
$ScriptsDir = Join-Path $env:SRC_VFDOT 'files\powershell\scripts'
if (Test-Path $ScriptsDir) {
  Get-ChildItem -Path $ScriptsDir -Filter '*.ps1' | ForEach-Object { . $_.FullName }
}
