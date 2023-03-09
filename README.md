# dotfiles

## About
This repository is a partially automated setup for a local development environment on a Windows device. A few pre-requisite steps are outlined in the below setup guide. The final step is the invocation of a key PowerShell script that automatically installs development tools and sets a pre-defined profile for PowerShell. These elements may all be expanded over time as tool and environment needs change.

## Setup Guide

### Test Windows Package Manager CLI (aka winget)
1. The winget command-line tool should be pre-installed on Windows 11 as part of the **App Installer**. Let's test this:
```
winget -v
```
2. If already installed and version is greater than v.1.3.X, we're good. Otherwise, install or update it via [Microsoft Store](https://learn.microsoft.com/en-us/windows/package-manager/winget/#install-winget) and repeat above test.

### Install PowerShell
1. Install PowerShell Core utilizing winget:
```
winget install --id=Microsoft.PowerShell --source=winget
```
2. Open a PowerShell session for further steps.

### Install Windows Subsystem for Linux (aka WSL)
1. Install WSL directly via the following command:
```
wsl --install
```
2. Afterwards, you will need to restart the machine before continuing.

### Install Git
1. Install Git for Windows via winget:
```
winget install --id=Git.Git --source=winget
```
2. Test git to verify installation:
```
git -v
```
3. Set global git configurations for user name and email:
```
git config --global user.name "Victor Frye"; git config --global user.email "victorfrye@outlook.com";
```
### Clone Dotfiles Repository
1. Clone the dotfiles repository from [GitHub](https://github.com/victorfrye/dotfiles):
```
git clone https://github.com/victorfrye/dotfiles $HOME\Source\Repos\VictorFrye\Dotfiles
```

### Invoke Scripts
1. Invoke the dotfiles initialization script as an administrator:
```
pwsh.exe $HOME\Source\Repos\VictorFrye\Dotfiles\scripts\Initialize-Dotfiles.ps1
```