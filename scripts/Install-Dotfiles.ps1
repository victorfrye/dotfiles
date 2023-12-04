$MyName = 'Victor Frye'
$MyEmail = 'victorfrye@outlook.com'

$FontFilesPath = Join-Path $RepoRoot '\files\Fonts\*.otf'
$NewProfile = Join-Path $RepoRoot '\files\Profile.ps1'
$PackagesFile = Join-Path $RepoRoot '\files\Packages.json'

function Initialize-Git() {
    winget install --exact --id Git.Git --source winget
    git config --global user.name $MyName
    git config --global user.email $MyEmail
    git config --global core.autocrlf true
    git config --global core.editor nvim
    git config --global init.defaultBranch main
    git config --global push.autoSetupRemote true
}

function Format-DevDrive() {
    Write-Output 'Formatting development drive...'

    $PreferredDriveLetters = 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N'
    $Volumes = Get-Volume
    $global:DevDriveLetter = $PreferredDriveLetters | Where-Object { $Volumes.DriveLetter -notcontains $_ } | Select-Object -First 1

    Format-Volume -DriveLetter $DevDriveLetter -DevDrive

    Write-Output "Complete!! Development drive $DevDriveLetter has been formatted."
}

function Get-Repository() {
    Write-Output 'Cloning dotfiles repository...'

    $global:RepoRoot = "$global:DevDriveLetter:\Source\Repos\VictorFrye\Dotfiles"
    git clone https://github.com/victorfrye/dotfiles $global:RepoRoot
    Push-Location $global:RepoRoot

    Write-Output "Complete!! Dotfiles repository has been cloned to $global:RepoRoot."
}

function Install-WinGetPackages() {
    Write-Output 'Installing WinGet packages...'
    winget import --import-file $PackagesFile --accept-source-agreements --accept-package-agreements
    Write-Output 'Complete!! WinGet packages installed successfully.'
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

function Set-PowerShellProfile() {
    Write-Output 'Setting PowerShell profile...'

    if (!(Test-Path -Path $PROFILE.CurrentUserAllHosts)) {
        New-Item -ItemType File -Path $PROFILE.CurrentUserAllHosts -Force
    }
    Get-Content $NewProfile | Set-Content $PROFILE.CurrentUserAllHosts

    Write-Output 'Complete!! PowerShell profile has been set.'
}

function Install-PoshGit() {
    Write-Output 'Installing PoshGit...'
    PowerShellGet\Install-Module posh-git -Scope CurrentUser -Force
    Write-Output 'Complete!! PoshGit has been installed.'
}

function Install-TheFuck() {
    Write-Output 'Installing TheFuck...'
    Invoke-Expression ((New-Object net.webclient).DownloadString('https://raw.githubusercontent.com/mattparkes/PoShFuck/master/Install-TheFucker.ps1'))
    Write-Output 'Complete!! TheFuck has been installed'
}

Write-Output 'Starting installation of my dotfiles...'

Initialize-Git
Format-DevDrive
Get-Repository
Install-WinGetPackages
Install-Fonts
Set-PowerShellProfile
Install-PoshGit
Install-TheFuck

Write-Output 'Complete!! Dotfiles installed successfully.'
