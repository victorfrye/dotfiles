$FontFilesPath = Join-Path $RepoRoot '\files\Fonts\*.otf'
$NewProfile = Join-Path $RepoRoot '\files\Profile.ps1'
$PackagesFile = Join-Path $RepoRoot '\files\Packages.json'

function Install-WinGetPackages() {
    Write-Output 'Installing WinGet packages...'
    winget import --import-file $PackagesFile --accept-source-agreements --accept-package-agreements
    Write-Output 'Complete!! Development tools installed successfully.'
}

function Install-Fonts() {
    Write-Output 'Installing fonts...'

    $fonts = (New-Object -ComObject Shell.Application).Namespace(0x14)
    foreach ($file in Get-ChildItem -Path $FontFilesPath -Recurse) {
        $fileName = $file.Name
        if (!(Test-Path -Path "C:\Windows\Fonts\$fileName" )) {
            Get-ChildItem $file | ForEach-Object { $fonts.CopyHere($_.fullname) }
        }
    }
    
    Write-Output 'Complete!! Fonts have been installed.'
}

function Install-PoshGit() {
    Write-Output 'Installing PoshGit...'
    PowerShellGet\Install-Module posh-git -Scope CurrentUser -Force
    Write-Output 'Complete!! PoshGit has been installed.'
}

function Set-PowerShellProfile() {
    Write-Output 'Setting PowerShell profile...'
    if (!(Test-Path -Path $PROFILE.CurrentUserAllHosts)) {
        New-Item -ItemType File -Path $PROFILE.CurrentUserAllHosts -Force
    }
    
    Get-Content $NewProfile | Set-Content $PROFILE.CurrentUserAllHosts
    Write-Output 'Complete!! PowerShell profile has been set.'
}

function Set-GitConfigurations() {
    git config --global core.autocrlf true
    git config --global core.editor nvim
    git config --global init.defaultBranch main
    git config --global push.autoSetupRemote true
}

Write-Output 'Starting initialization of machine configuration...'

$RepoRoot = Split-Path -Parent $PSScriptRoot

Install-WinGetPackages
Install-Fonts
Set-PowerShellProfile
Set-GitConfigurations

Write-Output 'Complete!! Machine is ready.'
