$RepoHome=$Home + '\Repositories'
$DotfilesRepo=$RepoHome + '\victorfrye\dotfiles'
$DotfilesPowerShellProfile=$DotfilesRepo + '\files\DotfilesPowerShellProfile.ps1'

function Test-WindowsPackageManager() {
    winget -v
    if (-NOT($LASTEXITCODE -EQ 0)) {
        Write-Host "Aborting... Please check that winget is installed before utilizing Windows dotfiles."
        return $false;
    }
    return $true
}

function Install-DevelopmentTools() {
    pwsh.exe $DotfilesRepo + "\Install-DevelopmentTools.ps1"
}

function Initialize-PowerShellProfile() {
    Write-Host "Initializing PowerShell profile..."
    if (!(Test-Path -Path $PROFILE.CurrentUserAllHosts)) {
        New-Item -ItemType File -Path $PROFILE.CurrentUserAllHosts -Force
      }
    
    Get-Content $PROFILE.CurrentUserAllHosts, $DotfilesPowerShellProfile | Set-Content $PROFILE.CurrentUserAllHosts
    Write-Host "Complete!! PowerShell profile has been initialized"
}

Write-Host "Starting initialization of dotfiles for local development on this Windows machine..."

[Environment]::SetEnvironmentVariable('REPOHOME', $RepoHome, 'User')

if (Test-WindowsPackageManager -eq $false) {
    exit 1
}

Install-DevelopmentTools
Initialize-PowerShellProfile

Write-Host "Complete!! Machine is ready for local Windows development."
