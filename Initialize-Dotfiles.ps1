$RepoHome=$Home + '\Repositories'
$DotfilesRepo=$RepoHome + '\victorfrye\dotfiles'

$InstallDevToolsScript=$DotfilesRepo + "\Install-DevelopmentTools.ps1"
$DotfilesPowerShellProfile=$DotfilesRepo + '\files\DotfilesPowerShellProfile.ps1'

function Install-DevelopmentTools() {
    pwsh.exe $InstallDevToolsScript
}

function Set-PowerShellProfile() {
    Write-Host "Setting PowerShell profile..."
    if (!(Test-Path -Path $PROFILE.CurrentUserAllHosts)) {
        New-Item -ItemType File -Path $PROFILE.CurrentUserAllHosts -Force
      }
    
    Get-Content $DotfilesPowerShellProfile | Set-Content $PROFILE.CurrentUserAllHosts
    Write-Host "Complete!! PowerShell profile has been set."
}

function Set-GitConfigurations() {
    git config --global core.editor "code --wait"
    git config --global init.defaultBranch main
}

Write-Host "Starting initialization of dotfiles for local development on this Windows machine..."

[Environment]::SetEnvironmentVariable('REPOHOME', $RepoHome, 'User')

Install-DevelopmentTools
Set-PowerShellProfile
Set-GitConfigurations

Write-Host "Complete!! Machine is ready for local Windows development."

