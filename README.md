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

My Windows dotfiles are a collection of configuration files and a bootstrap script to initialize a Windows development machine. The primary technologies attributed to this project are:

- **PowerShell**: The scripting language used to bootstrap the machine and configure the shell environment.
- **WinGet Configuration**: Declarative YAML-based configuration (DSC) for packages, Windows settings, PowerShell modules, and fonts.
- **GitHub**: The version control platform used to store and serve the dotfiles.
- **Windows**: The intended operating system for the development environment.

## Overview

This repository uses a **hybrid approach**: a declarative [WinGet Configuration](./.config/configuration.winget) file handles package installs, Windows settings, PowerShell modules, and fonts via DSC resources, while a thin [bootstrap script](./scripts/Install-Dotfiles.ps1) handles Git setup, Dev Drive creation, repo cloning, symlinks, and environment variables.

The bootstrap script does the following:

1. Install and configure [Git for Windows](https://git-scm.com/)
2. Format a [Dev Drive](https://learn.microsoft.com/en-us/windows/dev-drive/) (or detect an existing one)
3. Clone the dotfiles repository (or fetch latest if it exists)
4. Apply [WinGet Configuration](./.config/configuration.winget) — installs packages, configures Windows settings, and sets up PowerShell modules
5. Create symlinks from repo files to their system destinations
6. Deploy one-time config templates (copied only if target doesn't already exist)
7. Set machine-level environment variables

All operations are **idempotent** — re-running the script on an already-configured machine safely skips or updates existing installations.

### Symlinked Configuration

Configuration files are symlinked from the repo to their system destinations. Edits on disk are automatically reflected in the repository:

| Source (repo) | Target |
|---|---|
| `files/powershell/profile.ps1` | `$PROFILE.CurrentUserAllHosts` |
| `files/copilot/copilot-instructions.md` | `~/.copilot/copilot-instructions.md` |
| `files/copilot/agents/` | `~/.copilot/agents/` (directory) |
| `files/az/config.json` | `~/.Azure/AzConfig.json` |
| `files/githooks/` | `~/.githooks` (directory) |
| `files/wsl/.wslconfig` | `~/.wslconfig` |
| `files/docker/config.json` | `~/.docker/config.json` |

### One-Time Config Templates

These files are copied to their targets **only if the target doesn't already exist**. Tools write runtime state to these files, so they are not symlinked to avoid git noise:

| Source (repo) | Target |
|---|---|
| `files/copilot/config.json` | `~/.copilot/config.json` |
| `files/copilot/mcp-config.json` | `~/.copilot/mcp-config.json` |
| `files/terminal/settings.json` | Windows Terminal Preview LocalState |

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

    Optionally specify a custom Dev Drive letter (defaults to `W`):

    ``` pwsh
    $script = Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/victorfrye/dotfiles/main/scripts/Install-Dotfiles.ps1'
    & ([scriptblock]::Create($script)) -DevDriveLetter 'D'
    ```

### Post-Install — Configure Secrets

After the install script completes, use the Copilot CLI to interactively scaffold your local `env.ps1` secrets file (Azure identities, org repos, navigation aliases, etc.):

``` pwsh
cd $env:SRC_VFDOT
copilot -i "Help me create my env.ps1 file. This file is dot-sourced by my PowerShell profile to load secrets and org-specific configuration that must not be committed. Read AGENTS.md for the env.ps1 template and expected structure, then interview me to gather my Azure tenant IDs, subscription IDs, app client IDs, company/client org names, repo names, navigation aliases, solution context shortcuts, and any feed tokens or API keys. Generate the complete env.ps1 file when done."
```
