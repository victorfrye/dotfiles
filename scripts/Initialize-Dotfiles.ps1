$RepoHome = Join-Path $Home '\Source\Repos'
$DotfilesRepo = Join-Path $RepoHome '\VictorFrye\Dotfiles'

$InstallDevToolsScript = Join-Path $DotfilesRepo '\scripts\Install-DevelopmentTools.ps1'
$FontFilesPath = Join-Path $DotfilesRepo '\files\Fonts\*.otf'
$PowerShellProfilePath = Join-Path $DotfilesRepo '\files\Profile.ps1'

function Install-DevelopmentTools() {
    pwsh.exe $InstallDevToolsScript
}

function Install-Fonts() {
    Write-Host "Install fonts..."

    $fonts = (New-Object -ComObject Shell.Application).Namespace(0x14)

    foreach ($file in Get-ChildItem -Path $FontFilesPath -Recurse)
    {
        $fileName = $file.Name
        if (!(Test-Path -Path "C:\Windows\Fonts\$fileName" )) {
            Get-ChildItem $file | ForEach-Object { $fonts.CopyHere($_.fullname) }
        }
    }
    
    Write-Host "Complete!! Fonts have been installed."
}

function Set-PowerShellProfile() {
    Write-Host "Setting PowerShell profile..."
    if (!(Test-Path -Path $PROFILE.CurrentUserAllHosts)) {
        New-Item -ItemType File -Path $PROFILE.CurrentUserAllHosts -Force
      }
    
    Get-Content $PowerShellProfilePath | Set-Content $PROFILE.CurrentUserAllHosts
    Write-Host "Complete!! PowerShell profile has been set."
}

function Set-GitConfigurations() {
    git config --global core.autocrlf true
    git config --global core.editor "code --wait"
    git config --global init.defaultBranch main
}

Write-Host "Starting initialization of dotfiles for local development on this Windows machine..."

[Environment]::SetEnvironmentVariable('REPOHOME', $RepoHome, 'User')

Install-DevelopmentTools
Install-Fonts
Set-PowerShellProfile
Set-GitConfigurations

Write-Host "Complete!! Machine is ready for local Windows development."

