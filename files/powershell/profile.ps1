# MARK: Environment Variables
$env:SRC_VFDOT = Join-Path $env:REPOS_VF 'Dotfiles'
$env:SRC_VFCOM = Join-Path $env:REPOS_VF 'DotCom'
$env:SRC_VFMSG = Join-Path $env:REPOS_VF 'MicrosoftGraveyard'
$env:SRC_VFMIR = Join-Path $env:REPOS_VF 'MockingMirror'
$env:SRC_VFCNT = Join-Path $env:REPOS_VF 'Counter'
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

# MARK: Git — repository management functions
function Reset-AllRepositories() {
  Get-AllRepositories | ForEach-Object { git init $_.FullName }
}

function Get-AllRepositories() {
  return (Get-ChildItem $env:DEVDRIVE -Attributes Directory+Hidden -ErrorAction SilentlyContinue -Filter '.\.git' -Recurse).Parent
}

function Clear-RepositoryBranches() {
  git branch --list `
  | Select-String -Pattern '^\*' -NotMatch `
  | Select-String -Pattern 'main' -NotMatch `
  | ForEach-Object { git branch -D $_.Line.Trim() }
}

# MARK: Docker
function Clear-Docker { docker image prune -a --filter 'until=12h'; docker system prune }

# MARK: Java — JDK version management
function Reset-JavaHome() {
  $env:JAVA_HOME = $env:JDK_21_HOME
  Write-Output "The JAVA_HOME environment variable is now set to $env:JAVA_HOME."
}

function Set-JavaHome([int] $Version) {
  $CurrentJdk = $env:JAVA_HOME

  if (-not $Version) {
    Reset-JavaHome
    return
  }

  switch ($Version) {
    11 {
      if (-not (Test-Path -Path $env:JDK_11_HOME)) {
        Write-Output "No JDK configured for version $PSItem... Aborted."
        break
      }
      $CurrentJdk = $env:JDK_11_HOME
      break
    }
    17 {
      if (-not (Test-Path -Path $env:JDK_17_HOME)) {
        Write-Output "No JDK configured for version $PSItem... Aborted."
        break
      }
      $CurrentJdk = $env:JDK_17_HOME
      break
    }
    21 {
      if (-not (Test-Path -Path $env:JDK_21_HOME)) {
        Write-Output "No JDK configured for version $PSItem... Aborted."
        break
      }
      $CurrentJdk = $env:JDK_21_HOME
      break
    }
    default { Write-Output "No JDK configured for version $PSItem... Aborted." }
  }

  if ($env:JAVA_HOME -ne $CurrentJdk) {
    $env:JAVA_HOME = $CurrentJdk
    Write-Output "The JAVA_HOME environment variable is now set to $env:JAVA_HOME."
  }
}

Set-Alias -Name sjh -Value Set-JavaHome
Set-Alias -Name rsjh -Value Reset-JavaHome

# MARK: Utilities
function ConvertTo-Sha256Hash([string] $Value) {
  $HashedBytes = [System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($Value))
  return [System.BitConverter]::ToString($HashedBytes).Replace('-', '').ToLower()
}

Set-Alias -Name cthash -Value ConvertTo-Sha256Hash
Set-Alias -Name code -Value code-insiders

# MARK: Solution Context Management
function Initialize-SolutionContext([string] $TenantId, [string] $SubscriptionId, [string] $ClientId, [string] $Location) {
  $env:ARM_TENANT_ID = $TenantId
  $env:ARM_SUBSCRIPTION_ID = $SubscriptionId
  $env:ARM_CLIENT_ID = $ClientId

  if ($Location -and (Test-Path $Location)) {
    Set-Location $Location
  }

  Write-Output "Solution context initialized (Tenant: $TenantId, Subscription: $SubscriptionId)."
}

function Clear-SolutionContext {
  Remove-Item env:AZURE_TENANT_ID -ErrorAction SilentlyContinue
  Remove-Item env:AZURE_SUBSCRIPTION_ID -ErrorAction SilentlyContinue
  Remove-Item env:AZURE_CLIENT_ID -ErrorAction SilentlyContinue
  Remove-Item env:ARM_TENANT_ID -ErrorAction SilentlyContinue
  Remove-Item env:ARM_SUBSCRIPTION_ID -ErrorAction SilentlyContinue
  Remove-Item env:ARM_CLIENT_ID -ErrorAction SilentlyContinue

  Write-Output 'Solution context cleared.'
}

Set-Alias -Name clctx -Value Clear-SolutionContext

## Solution context shortcuts — define in env.ps1, e.g.:
##   function Initialize-MyAppContext { Initialize-SolutionContext $MY_TENANT $MY_SUB $MY_CLIENT $env:SRC_MYAPP }
##   Set-Alias -Name inmyapp -Value Initialize-MyAppContext

# MARK: Personal Projects — Navigation
function Set-LocationToVictorFryeRepositories { Set-Location $env:REPOS_VF }
function Set-LocationToVictorFryeDotfiles { Set-Location $env:SRC_VFDOT }
function Set-LocationToVictorFryeDotCom { Set-Location $env:SRC_VFCOM }
function Set-LocationToMicrosoftGraveyard { Set-Location $env:SRC_VFMSG }
function Set-LocationToMockingMirror { Set-Location $env:SRC_VFMIR }
function Set-LocationToCounter { Set-Location $env:SRC_VFCNT }
function Set-LocationToShrugMan { Set-Location $env:SRC_VFSHG }

Set-Alias -Name slvf -Value Set-LocationToVictorFryeRepositories
Set-Alias -Name slcom -Value Set-LocationToVictorFryeDotCom
Set-Alias -Name slmsg -Value Set-LocationToMicrosoftGraveyard
Set-Alias -Name slmir -Value Set-LocationToMockingMirror
Set-Alias -Name slcnt -Value Set-LocationToCounter
Set-Alias -Name slshg -Value Set-LocationToShrugMan

# MARK: Personal Projects — App Launchers
function Start-VictorFryeDotComApp { dotnet run --project "$env:SRC_VFCOM/src/AppHost/AppHost.csproj" }
function Start-MicrosoftGraveyardApp { dotnet run --project "$env:SRC_VFMSG/src/AppHost/AppHost.csproj" }
function Start-MockingMirrorApp { dotnet run --project "$env:SRC_VFMIR/src/AppHost/AppHost.csproj" }
function Start-ShrugManApp { dotnet run --project "$env:SRC_VFSHG/src/AppHost/AppHost.csproj" }

Set-Alias -Name sacom -Value Start-VictorFryeDotComApp
Set-Alias -Name samsg -Value Start-MicrosoftGraveyardApp
Set-Alias -Name samir -Value Start-MockingMirrorApp
Set-Alias -Name sashg -Value Start-ShrugManApp

## Company project navigation — configure in env.ps1:
##   function Set-LocationToCompanyRepos { Set-Location $env:REPOS_CO }
##   Set-Alias -Name slco -Value Set-LocationToCompanyRepos

## Client project navigation — configure in env.ps1:
##   function Set-LocationToClientRepos { Set-Location $env:REPOS_CL }
##   Set-Alias -Name slcl -Value Set-LocationToClientRepos

# MARK: Android SDK
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"

# MARK: Path
function Get-Path() {
  Write-Output $Env:PATH.Split(';')
}

$env:PATH += ";$env:ANDROID_HOME\tools;$env:ANDROID_HOME\tools\bin;$env:ANDROID_HOME\platform-tools"
