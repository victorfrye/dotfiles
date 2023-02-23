# dotfiles

## About
This repository is a partially automated set-up for a local development environment on a Windows device. A few pre-requisite steps are outlined in the below set-up guide. The final step is the invocation of a key PowerShell script that automatically installs development tools and sets a pre-defined profile for PowerShell. These elements may all be expanded over time as tool and environment needs change.

## Set-Up Guide

### Windows Package Manager
1. The winget command-line tool should be pre-installed on Windows 11 as part of the **App Installer**. Let's test this:
```
winget -v
```
2. If already installed, we're good. Otherwise, install it via [Microsoft Store](https://learn.microsoft.com/en-us/windows/package-manager/winget/#install-winget) and repeat above test.

### Install PowerShell
1. Install PowerShell Core utilizing winget:
```
winget install --id=Microsoft.PowerShell --source=winget
```
2. Open a PowerShell session for further steps.

### Install Git
1. Install Git for Windows via
winget:
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
git clone https://github.com/victorfrye/dotfiles $HOME\Repositories\victorfrye\dotfiles
```

### Invoke Scripts
1. Invoke the dotfiles initialization script:
```
pwsh.exe $HOME\Repositories\victorfrye\dotfiles\Initialize-Dotfiles.ps1
```