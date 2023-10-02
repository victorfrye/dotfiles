# My Personal Dotfiles

## About

This repository is a partially automated set up of local machine configuration on a Windows device. A few pre-requisite steps are outlined in the below set up guide. The final step is the invocation of a key PowerShell script that automatically installs development tools and sets a pre-defined profile for PowerShell. These elements may all be expanded over time as tool and environment needs change.

## Set-up Guide

### Test Windows Package Manager CLI (aka WinGet)

1. The WinGet command-line tool should be pre-installed on Windows 11 as part of the **App Installer**. Let's test this:

    ``` pwsh
    winget --version
    ```

2. If already installed and version is greater than v.1.3.X, we're good. Otherwise, install or update it via [Microsoft Store](https://learn.microsoft.com/en-us/windows/package-manager/winget/#install-winget) and repeat above test.

### Install PowerShell

1. Install PowerShell Core utilizing WinGet:

    ``` pwsh
    winget install --id Microsoft.PowerShell --source winget
    ```

2. Open a PowerShell session for further steps.

### Install Windows Subsystem for Linux (aka WSL)

1. Install WSL directly via the following command:

    ``` pwsh
    wsl --install
    ```

2. Afterwards, you will need to restart the machine before continuing.

### Install Git

1. Install Git for Windows via WinGet:

    ``` pwsh
    winget install --id Git.Git --source winget
    ```

2. Test git to verify installation:

    ``` pwsh
    git --version
    ```

3. Set global git configurations for user name and email:

    ``` pwsh
    git config --global user.name "Victor Frye"; git config --global user.email "victorfrye@outlook.com";
    ```

### Add Dev Drive (optional)

1. Format Dev Drive volume as an administrator:

    ``` pwsh
    Format-Volume -DriveLetter D -DevDrive
    ```

### Clone Dotfiles Repository

1. Clone the dotfiles repository from [GitHub](https://github.com/victorfrye/dotfiles):

    ``` pwsh
    git clone https://github.com/victorfrye/dotfiles D:\Source\VictorFrye\Dotfiles
    ```

### Invoke Script

1. Invoke the dotfiles initialization script as an administrator:

    ``` pwsh
    pwsh D:\Source\VictorFrye\Dotfiles\scripts\Initialize-Dotfiles.ps1
    ```
