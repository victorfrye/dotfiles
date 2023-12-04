# My Personal Dotfiles

## About

This repository is a partially automated set up of local machine configuration on a Windows device. A few pre-requisite steps are outlined in the below set up guide. The final step is the invocation of a key PowerShell script that automatically installs development tools and sets a pre-defined profile for PowerShell. These elements may all be expanded over time as tool and environment needs change.

## Set-up Guide

### Test Windows Package Manager CLI (aka WinGet)

1. The WinGet command-line tool should be pre-installed on Windows 11 as part of the **App Installer**. Let's test this:

    ``` cmd
    winget --version
    ```

2. If already installed and version is greater than v1.3.X, we're good. Otherwise, install or update it via [Microsoft Store](https://learn.microsoft.com/en-us/windows/package-manager/winget/#install-winget) and repeat above test.

### Install PowerShell

1. Install PowerShell via WinGet:

    ``` cmd
    winget install --exact --id Microsoft.PowerShell.Preview --source winget
    ```

2. Open a PowerShell session for further steps.

### Install Windows Subsystem for Linux (aka WSL)

1. Install WSL directly via the following command:

    ``` cmd
    wsl --install
    ```

2. Afterwards, you will need to restart the machine before continuing.

### Install Dotfiles

1. Set execution to remote signed on local machine:

    ``` pwsh
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
    ```

2. From an administrative PowerShell session, invoke and install dotfiles:

    ``` pwsh
    Invoke-Expression ((New-Object net.webclient).DownloadString('https://raw.githubusercontent.com/victorfrye/dotfiles/main/scripts/Install-Dotfiles.ps1'))
    ```
