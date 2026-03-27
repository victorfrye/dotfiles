# Agent Instructions

This document provides context for AI coding agents working in this repository.

## Architecture

This is a Windows dotfiles repository that automates the setup of a local Windows development machine using a **hybrid approach**: a declarative WinGet Configuration file (DSC) handles packages, Windows settings, PowerShell modules, and fonts, while a thin bootstrap script handles Git setup, Dev Drive, repo cloning, symlinks, and environment variables.

The single entry point is `scripts/Install-Dotfiles.ps1`, invoked remotely on a fresh machine via:

```pwsh
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/victorfrye/dotfiles/main/scripts/Install-Dotfiles.ps1' | Invoke-Expression
```

The script is **idempotent** — re-running it on an already-configured machine safely skips or updates existing installations.

### Repository Structure

- **`.config/configuration.winget`** — WinGet Configuration (DSC YAML): packages, Windows settings, PS modules
- **`scripts/Install-Dotfiles.ps1`** — bootstrap script: Git init, Dev Drive, repo clone, `winget configure`, symlinks, one-time deploys, env vars
- **`scripts/Test-Dotfiles.ps1`** — post-install verification: checks symlinks, binaries, env vars, config validity
- **`tests/Install-Dotfiles.Tests.ps1`** — Pester tests for CI: config validation, linting, JSON parsing
- **`files/powershell/profile.ps1`** — PowerShell profile, symlinked to `$PROFILE.CurrentUserAllHosts`
- **`files/powershell/yfnd.omp.json`** — custom Oh My Posh theme (active theme, referenced from repo path)
- **`files/az/config.json`** — Azure PowerShell config, symlinked to `~/.Azure/AzConfig.json`
- **`files/copilot/`** — GitHub Copilot CLI configuration (see below)
- **`files/githooks/`** — Git hooks directory, symlinked to `~/.githooks`
- **`files/terminal/settings.json`** — Windows Terminal Preview settings, deployed as one-time template
- **`files/wsl/.wslconfig`** — WSL configuration, symlinked to `~/.wslconfig`
- **`files/docker/config.json`** — Docker config, symlinked to `~/.docker/config.json`
- **`env.ps1`** — local secrets file (**gitignored**, never committed; see below)

### Copilot CLI Configuration (`files/copilot/`)

Deployed to `~/.copilot/` by the install script. Contains:

- **`config.json`** — portable Copilot CLI settings (banner, theme, model preference)
- **`copilot-instructions.md`** — personal coding instructions and engineering philosophy, symlinked to `~/.copilot/copilot-instructions.md`
- **`mcp-config.json`** — MCP server definitions: Aspire, Playwright, Context7, WinGet. Deployed as one-time template — add org-specific servers (e.g., Azure DevOps) post-install.
- **`agents/`** — custom agent definitions directory, symlinked to `~/.copilot/agents/`: `dotnet-developer`, `interviewer`, `react-developer`, `storywriter`, `terraform-developer`

### Dev Drive

The install script creates (or detects) a Windows ReFS Dev Drive volume labeled `DEVDRIVE`. All repositories and package manager caches live on this drive. The drive letter is dynamic — never hardcode it; always reference via the `DEVDRIVE` environment variable.

### Secrets and Local Configuration (`env.ps1`)

The PowerShell profile dot-sources `env.ps1` from the repo root (`$env:SRC_VFDOT\env.ps1`) to load sensitive values that must not be committed. This file is **gitignored**.

After running the install script, create `env.ps1` in the repo root with your secrets and org-specific configuration:

```pwsh
# Azure identity — personal projects
$script:AZ_PERSONAL_TENANT_ID = '<your-tenant-id>'
$script:AZ_PERSONAL_SUBSCRIPTION_ID = '<your-subscription-id>'
$script:AZ_MYAPP_CLIENT_ID = '<your-app-client-id>'

# Company repos
$env:REPOS_CO = Join-Path $env:REPOS_ROOT '<CompanyOrg>'
$env:SRC_CO_REPO1 = Join-Path $env:REPOS_CO '<RepoName>'

# Company navigation aliases
function Set-LocationToCompanyRepos { Set-Location $env:REPOS_CO }
Set-Alias -Name slco -Value Set-LocationToCompanyRepos

# Client repos
$env:REPOS_CL = Join-Path $env:REPOS_ROOT '<ClientOrg>'
$env:SRC_CL_REPO1 = Join-Path $env:REPOS_CL '<RepoName>'

# Client navigation aliases
function Set-LocationToClientRepos { Set-Location $env:REPOS_CL }
Set-Alias -Name slcl -Value Set-LocationToClientRepos

# Solution context shortcuts
function Initialize-MyAppContext {
  Initialize-SolutionContext $script:AZ_PERSONAL_TENANT_ID $script:AZ_PERSONAL_SUBSCRIPTION_ID $script:AZ_MYAPP_CLIENT_ID $env:SRC_VFCOM
}
Set-Alias -Name inmyapp -Value Initialize-MyAppContext

# NuGet feed tokens, API keys, etc.
# $env:MY_FEED_TOKEN = '<your-token>'
```

**Post-install step:** After the install script completes, run the Copilot CLI from the repo root to interactively scaffold your `env.ps1` secrets file:

```pwsh
cd $env:SRC_VFDOT
copilot -i "Help me create my env.ps1 file. This file is dot-sourced by my PowerShell profile to load secrets and org-specific configuration that must not be committed. Read AGENTS.md for the env.ps1 template and expected structure, then interview me to gather my Azure tenant IDs, subscription IDs, app client IDs, company/client org names, repo names, navigation aliases, solution context shortcuts, and any feed tokens or API keys. Generate the complete env.ps1 file when done."
```

### Environment Variables

Set at Machine scope by `Install-Dotfiles.ps1`:

| Variable | Value |
|---|---|
| `DEVDRIVE` | Root of Dev Drive (e.g. `W:`) |
| `REPOS_ROOT` | `<DEVDRIVE>\Source\Repos` |
| `REPOS_VF` | `<DEVDRIVE>\Source\Repos\VictorFrye` |
| `PACKAGES_ROOT` | `<DEVDRIVE>\Packages` |
| `NPM_CONFIG_CACHE` | `<PACKAGES_ROOT>\.npm` |
| `NUGET_PACKAGES` | `<PACKAGES_ROOT>\.nuget` |
| `PIP_CACHE_DIR` | `<PACKAGES_ROOT>\.pip` |
| `DOTNET_ROOT` | `%PROGRAMFILES%\dotnet` |
| `DOTNET_ENVIRONMENT` | `Development` |
| `ASPNETCORE_ENVIRONMENT` | `Development` |
| `JDK_17_HOME` | Microsoft OpenJDK 17 path |
| `JDK_21_HOME` | Microsoft OpenJDK 21 path |
| `JDK_25_HOME` | Microsoft OpenJDK 25 path |
| `JAVA_HOME` | `%JDK_25_HOME%` (default) |


Session-scoped vars set in `files/powershell/profile.ps1`: `SRC_VFDOT`, `SRC_VFCOM`, `SRC_VFMSG`, `SRC_VFMIR`, `SRC_VFSHG`.

### PowerShell Profile

`files/powershell/profile.ps1` configures the shell environment:

- Oh My Posh with custom `yfnd` theme (referenced from `$env:SRC_VFDOT\files\powershell\yfnd.omp.json`)
- posh-git module for Git integration
- Aliases: `sjh`/`rsjh` (Java home switching, supports JDK 11/17/21/25), `slvf`/`slcom`/`slmsg`/`slmir`/`slshg` (quick `cd` to repos), `sacom`/`samsg`/`samir`/`sashg` (app launchers), `code` → `code-insiders`, `cthash` (SHA-256 hash), `clctx` (clear solution context)
- `Initialize-SolutionContext` — generic function to set ARM_* env vars; project-specific shortcuts defined in `env.ps1`
- Placeholder comment blocks for company and client navigation/aliases (populated via `env.ps1`)

## Commands

### Install

Run the full bootstrap (requires admin):

```pwsh
.\scripts\Install-Dotfiles.ps1
```

### Validate

Validate the WinGet Configuration without applying:

```pwsh
winget configure validate --file .config/configuration.winget
```

### Test

Run the post-install verification script (checks symlinks, binaries, env vars):

```pwsh
.\scripts\Test-Dotfiles.ps1
```

Run Pester tests (config validation, linting, JSON parsing):

```pwsh
Invoke-Pester .\tests\
```

### CI

GitHub Actions CI runs on `windows-2025` and validates:
- WinGet Configuration schema (`winget configure validate`)
- PSScriptAnalyzer lint on all `.ps1` files
- Pester tests (config structure, JSON parsing, syntax checks)

CI cannot test symlinks, env vars, or package installs (no Dev Drive or admin on runners).

### Add a Package

Add a `WinGetPackage` resource entry to `.config/configuration.winget`.

### Apply WinGet Config Only

```pwsh
winget configure --file .config/configuration.winget --accept-configuration-agreements
```

## Conventions

### Git

- Trunk-based development on `main` with short-lived PR branches
- Conventional commits: `feat:`, `fix:`, `chore:`, etc.

### Maintaining This File

When introducing new scripts, configuration files, environment variable changes, or Copilot agent/config updates, update this `AGENTS.md` file to keep future sessions informed.
