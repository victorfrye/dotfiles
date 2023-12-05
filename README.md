# My Personal Dotfiles

## About

This repository is a partially automated set up of local machine configuration on a Windows device. A few pre-requisite steps are outlined in the below set up guide. The final step is the download and invocation of the [Install-Dotfiles.ps1](./scripts/Install-Dotfiles.ps1) script. This script will do the following:

- Install [Git for Windows](https://git-scm.com/)
- Format a [Dev Drive](https://learn.microsoft.com/en-us/windows/dev-drive/)
- Clone this repository to the new Dev Drive
- Import [WinGet packages](./files/Packages.json)
- Install a [Nerd Font](./files/Fonts)
- Install [PoshGit](https://github.com/dahlbyk/posh-git)
- Install [PoShFuck](https://github.com/mattparkes/PoShFuck)
- Set up [PowerShell Profile](./files/Profile.ps1)
- Set Environment Variables

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
    Invoke-RestMethod -Uri https://raw.githubusercontent.com/victorfrye/dotfiles/main/scripts/Install-Dotfiles.ps1 | Invoke-Expression
    ```
