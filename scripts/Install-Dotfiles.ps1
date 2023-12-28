$MyName = 'Victor Frye'
$MyEmail = 'victorfrye@outlook.com'

$DevDriveLetter = $null
$RepoRoot = $null

function Initialize-Git() {
    Write-Host 'Initializing Git...'

    winget install --exact --id Git.Git --source winget

    git config --global user.name $MyName
    git config --global user.email $MyEmail
    git config --global core.autocrlf true
    git config --global core.editor nvim
    git config --global init.defaultBranch main
    git config --global push.autoSetupRemote true

    Write-Host 'Done. Git has been initialized.'
}

function Format-DevDrive() {
    Write-Host 'Initializing development drive...'

    $Volumes = Get-Volume

    $DevDrive = $Volumes | Where-Object { $_.FileSystemLabel -eq 'DEVDRIVE' } | Select-Object -First 1

    if ($DevDrive) {
        $global:DevDriveLetter = $DevDrive.DriveLetter
        Write-Host "Skipped. Development drive $global:DevDriveLetter already exists."
        return
    }

    $PreferredDriveLetters = 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
    $global:DevDriveLetter = $PreferredDriveLetters | Where-Object { $Volumes.DriveLetter -notcontains $_ } | Select-Object -First 1

    Format-Volume -DriveLetter $DevDriveLetter -DevDrive

    Write-Host "Done. Development drive $DevDriveLetter has been initialized."
}

function Get-Repository() {
    Write-Host 'Cloning dotfiles repository...'

    $global:RepoRoot = "$($global:DevDriveLetter):\Source\Repos\VictorFrye\Dotfiles"

    if (Test-Path -Path $global:RepoRoot) {
        Write-Host "Dotfiles repository already exists at $global:RepoRoot. Fetching latest instead."
        Push-Location $global:RepoRoot

        git fetch --all

        Write-Host 'Done. Existing dotfiles repository has been updated with the latest sources.'
        return
    }

    git clone https://github.com/victorfrye/dotfiles $global:RepoRoot
    Push-Location $global:RepoRoot

    Write-Host "Done. Dotfiles repository has been cloned to $global:RepoRoot."
}

function Install-WinGetPackages() {
    Write-Host 'Installing WinGet packages...'

    $PackagesFile = Join-Path $global:RepoRoot '\files\Packages.json'
    winget import --import-file $PackagesFile --accept-source-agreements --accept-package-agreements

    Write-Host 'Done. WinGet packages installed successfully.'
}

function Install-Fonts() {
    Write-Host 'Installing fonts...'

    $FontFilesPath = Join-Path $global:RepoRoot '\files\Fonts\*.otf'

    $fonts = (New-Object -ComObject Shell.Application).Namespace(0x14)
    foreach ($file in Get-ChildItem -Path $FontFilesPath -Recurse) {
        $fileName = $file.Name
        if (!(Test-Path -Path "C:\Windows\Fonts\$fileName")) {
            Get-ChildItem $file | ForEach-Object { $fonts.CopyHere($_.fullname) }
        }
    }

    Write-Host 'Done. Fonts have been installed.'
}

function Install-PoshGit() {
    Write-Host 'Installing PoshGit...'
    PowerShellGet\Install-Module posh-git -Scope CurrentUser -Force
    Write-Host 'Done. PoshGit has been installed.'
}

function Install-TheFucker() {
    Write-Host 'Installing TheFuck...'
    Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/mattparkes/PoShFuck/master/Install-TheFucker.ps1' | Invoke-Expression
    Write-Host 'Done. TheFuck has been installed.'
}

function Install-AzPowerShell() {
    Write-Host 'Installing Azure PowerShell...'
    Install-Module -Name Az -Repository PSGallery -Force
    Write-Host 'Done. Azure PowerShell has been installed.'
}

function Set-PowerShellProfile() {
    Write-Host 'Setting PowerShell profile...'

    $NewProfile = Join-Path $global:RepoRoot '\files\Profile.ps1'

    if (!(Test-Path -Path $PROFILE.CurrentUserAllHosts)) {
        New-Item -ItemType File -Path $PROFILE.CurrentUserAllHosts -Force
    }
    Get-Content $NewProfile | Set-Content $PROFILE.CurrentUserAllHosts

    Write-Host 'Done. PowerShell profile has been set.'
}

function Set-EnvironmentVariables() {
    Write-Host 'Setting system environment variables...'

    [System.Environment]::SetEnvironmentVariable('DEVDRIVE', "$($global:DevDriveLetter):", 'Machine')

    [System.Environment]::SetEnvironmentVariable('REPOS_ROOT', "$($global:DevDriveLetter):\Source\Repos", 'Machine')
    [System.Environment]::SetEnvironmentVariable('REPOS_VF', "$($global:DevDriveLetter):\Source\Repos\VictorFrye", 'Machine')

    [System.Environment]::SetEnvironmentVariable('PACKAGES_ROOT', "$($global:DevDriveLetter):\Packages", 'Machine')
    [System.Environment]::SetEnvironmentVariable('NPM_CONFIG_CACHE', "$($global:DevDriveLetter):\Packages\.npm", 'Machine')
    [System.Environment]::SetEnvironmentVariable('NUGET_PACKAGES', "$($global:DevDriveLetter):\Packages\.nuget", 'Machine')
    [System.Environment]::SetEnvironmentVariable('PIP_CACHE_DIR', "$($global:DevDriveLetter):\Packages\.pip", 'Machine')
    [System.Environment]::SetEnvironmentVariable('MAVEN_OPTS', "-Dmaven.repo.local=$($global:DevDriveLetter):\Packages\.maven $env:MAVEN_OPTS", 'Machine')

    [System.Environment]::SetEnvironmentVariable('DOTNET_ROOT', "$env:PROGRAMFILES\dotnet", 'Machine')
    [System.Environment]::SetEnvironmentVariable('PATH', "$env:PATH;%DOTNET_ROOT%", 'Machine')

    [System.Environment]::SetEnvironmentVariable('NVIM_ROOT', "$env:PROGRAMFILES\Neovim", 'Machine')
    [System.Environment]::SetEnvironmentVariable('PATH', "$env:PATH;%NVIM_ROOT_%\bin", 'Machine')

    $MsftJavaHome = Join-Path $env:ProgramFiles 'Microsoft'
    $Java11 = Get-ChildItem -Path $MsftJavaHome -Filter 'jdk-11*' -Name
    $Java17 = Get-ChildItem -Path $MsftJavaHome -Filter 'jdk-17*' -Name
    $Java21 = Get-ChildItem -Path $MsftJavaHome -Filter 'jdk-21*' -Name
    [System.Environment]::SetEnvironmentVariable('JDK_11_HOME', "$MsftJavaHome\$Java11\", 'Machine')
    [System.Environment]::SetEnvironmentVariable('JDK_17_HOME', "$MsftJavaHome\$Java17\", 'Machine')
    [System.Environment]::SetEnvironmentVariable('JDK_21_HOME', "$MsftJavaHome\$Java21\", 'Machine')
    [System.Environment]::SetEnvironmentVariable('JAVA_HOME', '%JDK_21_HOME%', 'Machine')
    [System.Environment]::SetEnvironmentVariable('PATH', "$env:PATH;%JAVA_HOME%", 'Machine')

    Write-Host 'Done. System environment variables have been set.'
}

Write-Host 'Starting installation of my dotfiles...'

Initialize-Git
Format-DevDrive
Get-Repository
Install-WinGetPackages
Install-Fonts
Install-PoshGit
Install-TheFucker
Install-AzPowerShell
Set-PowerShellProfile
Set-EnvironmentVariables

Write-Host 'Complete!! Dotfiles installed successfully.' -ForegroundColor Green
