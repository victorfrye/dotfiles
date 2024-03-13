<div align="center">
    <img src="https://raw.githubusercontent.com/victorfrye/victorfrye/main/images/windows.svg" alt="Windows" height="64" width="64" />
    <h1>My Windows Dotfiles</h1>
    <p>My personal dotfiles to initialize Windows machine configuration</p>
</div>

<div align="center">

[![Unlicense license](https://img.shields.io/badge/License-Unlicense-blue.svg)](/LICENSE)

</div>

## Technology Stack

<p align="left">
    <a href="https://learn.microsoft.com/en-us/powershell/"target="_blank" rel="noreferrer noopener" style="text-decoration: none;">
        <img src="https://raw.githubusercontent.com/victorfrye/victorfrye/main/images/powershell.svg" width="36" height="36" alt="PowerShell" />
    </a>
    <a href="https://git-scm.com/" target="_blank" rel="noreferrer noopener" style="text-decoration: none;">
        <img src="https://raw.githubusercontent.com/victorfrye/victorfrye/main/images/git.svg" width="36" height="36" alt="Git" />
    </a>
    <a href="https://github.com/victorfrye" target="_blank" rel="noreferrer noopener" style="text-decoration: none;">
        <img src="https://raw.githubusercontent.com/victorfrye/victorfrye/main/images/github.svg" width="36" height="36" alt="GitHub" />
    </a>
        <a href="https://www.microsoft.com/en-us/windows/" target="_blank" rel="noreferrer noopener" style="text-decoration: none;">
        <img src="https://raw.githubusercontent.com/victorfrye/victorfrye/main/images/windows.svg" width="36" height="36" alt="Windows" >
    </a>
</p>

My Windows dotfiles are a collection of steps, scripts, and configuration files to initialize a Windows machine. The primary technologies attributed to this project are:

- **PowerShell**: The primary scripting language used to automate the configuration of the local machine.
- **GitHub**: The version control system and platform used to store and serve the distribution of the dotfiles.
- **Windows**: The intended operating system for the development environment.
- **WinGet**: The package manager used to install software and tools on the destination machine.

## Overview

This repository is a partially automated set up of local machine configuration on a Windows device. A few pre-requisite steps are outlined in the below set up guide. The final step is the download and invocation of the [Install-Dotfiles.ps1](./scripts/Install-Dotfiles.ps1) script. This script will do the following:

- Install [Git for Windows](https://git-scm.com/)
- Format a [Dev Drive](https://learn.microsoft.com/en-us/windows/dev-drive/) if one doesn't already exist
- Clone repository to Dev Drive or fetch latest if already exists
- Import [WinGet packages](./files/Packages.json)
- Install a [Nerd Font](./files/Fonts)
- Install [PoshGit](https://github.com/dahlbyk/posh-git)
- Install [PoShFuck](https://github.com/mattparkes/PoShFuck)
- Install [Azure PowerShell](https://learn.microsoft.com/en-us/powershell/azure/install-azps-windows)
- Set [PowerShell Profile](./files/Profile.ps1)
- Set Environment Variables

## Instructions

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

### Invoke Dotfiles

1. From an administrative PowerShell session, set execution policy to remote signed and invoke dotfiles installation:

    ``` pwsh
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
    Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/victorfrye/dotfiles/main/scripts/Install-Dotfiles.ps1' | Invoke-Expression
    ```
