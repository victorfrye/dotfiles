# Agent Instructions

This document provides context for AI coding agents working in this repository.

## Architecture

This is a Windows dotfiles repository that automates the setup of a local Windows development machine using a **hybrid approach**: a declarative WinGet Configuration file (**DSCv3**) handles packages, Windows registry settings, PowerShell modules, fonts, symlinks, Git config, Docker plugins, and config file patching — all as idempotent DSC script resources. A thin bootstrap script handles only Dev Drive creation, repo cloning, and environment variable setup before invoking `winget configure`.

The single entry point is `scripts/Install-Dotfiles.ps1`, invoked remotely on a fresh machine via:

```pwsh
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/victorfrye/dotfiles/main/scripts/Install-Dotfiles.ps1' | Invoke-Expression
```

The script is **idempotent** — re-running it on an already-configured machine safely skips or updates existing installations.

### Repository Structure

- **`.config/configuration.winget`** — WinGet Configuration (**DSCv3** YAML): registry settings, packages, PS modules, fonts, terminal patches, Git config, symlinks, Docker plugins, config file patches, WSL install
- **`scripts/Install-Dotfiles.ps1`** — thin bootstrap: Dev Drive detection/creation, repo clone, set `$env:DOTFILES_ROOT`, invoke `winget configure`, set machine-scope environment variables
- **`scripts/Test-Dotfiles.ps1`** — post-install verification: checks symlinks, binaries, env vars, config validity
- **`tests/Install-Dotfiles.Tests.ps1`** — Pester tests for CI: config validation, linting, JSON parsing
- **`files/powershell/profile.ps1`** — PowerShell profile, symlinked to `$PROFILE.CurrentUserAllHosts`; sets env vars, loads Oh My Posh and posh-git, then dot-sources all scripts in `files/powershell/scripts/`
- **`files/powershell/yfnd.omp.json`** — custom Oh My Posh theme (active theme, referenced from repo path)
- **`files/powershell/scripts/`** — modular profile scripts, dot-sourced dynamically at profile load:
  - `copilot.ps1` — `Set-CopilotProvider`/`Reset-CopilotProvider` (GitHub / LiteLLM / FoundryLocal), aliases `scp`/`rscp`
  - `docker.ps1` — `Clear-Docker` (prune images and system resources), `Connect-ContainerRegistry` (az acr login wrapper — authenticates to ACR using current az login session, no plaintext creds), alias `ccreg`
  - `git.ps1` — `Reset-AllRepositories`, `Get-AllRepositories`, `Clear-RepositoryBranches`
  - `java.ps1` — `Set-JavaVersion`/`Reset-JavaVersion` (interactive or `-Version` param), aliases `sjv`/`rsjv`
  - `navigation.ps1` — `Set-LocationTo*` and `Start-*App` functions + aliases
  - `node.ps1` — `Set-NodeVersion`/`Reset-NodeVersion` (interactive or `-Version` param), aliases `snv`/`rsnv`
  - `solution-context.ps1` — `Initialize-SolutionContext`, `Clear-SolutionContext`, alias `clctx`
  - `utilities.ps1` — `ConvertTo-Sha256Hash`, `Get-Path`, aliases `cthash`/`code`
- **`files/az/config.json`** — Azure PowerShell config, symlinked to `~/.Azure/AzConfig.json`
- **`files/copilot/`** — GitHub Copilot CLI configuration (see below)
- **`files/githooks/`** — Git hooks directory, symlinked to `~/.githooks`
- **`files/terminal/settings.json`** — Windows Terminal settings template; the DSC config patches the live settings.json for font and default profile (does not deploy this file directly)
- **`files/wsl/.wslconfig`** — WSL configuration, symlinked to `~/.wslconfig`
- **`files/docker/config.json`** — Docker credential store config (`credsStore: wincred`); the DSC config patches the live `~/.docker/config.json` and `%APPDATA%\containers\auth.json` using this as a reference — NOT deployed directly to avoid capturing runtime auth entries
- **`env.ps1`** — local secrets file (**gitignored**, never committed; see below)

### Copilot CLI Configuration (`files/copilot/`)

Deployed to `~/.copilot/` by the install script. Contains:

- **`config.json`** — portable Copilot CLI settings (banner, theme, model preference); **patched by DSC** (not deployed as a one-time copy)
- **`copilot-instructions.md`** — personal coding instructions and engineering philosophy, symlinked to `~/.copilot/copilot-instructions.md`
- **`mcp-config.json`** — MCP server definitions: Aspire, Playwright, Context7, WinGet. **Patched by DSC** (merges missing server entries, never overwrites extras) — add org-specific servers (e.g., Azure DevOps) post-install.
- **`agents/`** — custom agent definitions directory, symlinked to `~/.copilot/agents/`: reserved for future custom agents
- **`skills/`** — custom skill definitions directory, symlinked to `~/.copilot/skills/`: `interviewer`, `storywriter`

### DSCv3 Configuration Schema

`.config/configuration.winget` uses the **DSCv3** schema with `metadata.winget.processor.identifier: dscv3`. Key differences from DSCv2:

| Concern | DSCv2 | DSCv3 |
|---|---|---|
| Schema header | `configurationVersion: 0.2.0` | `$schema: .../PowerShell/DSC/.../config/document.json` |
| Processor | implicit | `metadata.winget.processor.identifier: dscv3` |
| Package resource | `Microsoft.WinGet.DSC/WinGetPackage` | `Microsoft.WinGet/Package` + `useLatest: true` |
| Registry resource | `Microsoft.Windows.Developer/*` | `Microsoft.Windows/Registry` |
| PS7 script resource | `PSDscResources/Script` | `Microsoft.DSC.Transitional/PowerShellScript` |
| PS5 script resource | `PSDscResources/Script` | `Microsoft.DSC.Transitional/WindowsPowerShellScript` |
| Elevated security | `directives.securityContext: elevated` | `metadata.securityContext: elevated` |

**DSC resource sections in `.config/configuration.winget`** (in order):
1. **Registry resources** — `Microsoft.Windows/Registry`: developer mode, long paths, sudo inline, dark theme (apps + system), Explorer settings (extensions, hidden files, full path, open to This PC, Git sidebar, taskbar alignment), Start menu (disable web search, disable recommendations)
2. **Package resources** — `Microsoft.WinGet/Package`: all tools, languages, runtimes, apps
3. **PS module scripts** — `Microsoft.DSC.Transitional/PowerShellScript`: install Az, Pester, PSScriptAnalyzer, posh-git modules
4. **Font script** — Cascadia Code NF user-scope install (GitHub release API, HKCU registry, `%LOCALAPPDATA%\Microsoft\Windows\Fonts`)
5. **Terminal scripts** — patch `settings.json` for Cascadia Mono NF font face, PS7 Preview default profile, GitHub Copilot fragment profile
6. **Git config script** — set global `user.name`, `user.email`, `core.*`, `init.*`, `push.*`
7. **Symlinks script** — create 7 symlinks (profile, copilot-instructions, agents/, skills/, az config, githooks/, .wslconfig); reads `$env:DOTFILES_ROOT`
8. **Docker plugins script** — symlink `docker-buildx.exe` and `docker-compose.exe` into `~/.docker/cli-plugins/`
9. **Config patch scripts** — merge-patch Copilot config.json, mcp-config.json, Docker config.json, Podman auth.json
10. **WSL scripts** — 3-phase: enable WSL components → reboot for VMP → install Ubuntu 24.04 (uses `WindowsPowerShellScript`)

**`$env:DOTFILES_ROOT` bridge:** `Install-Dotfiles.ps1` sets `$env:DOTFILES_ROOT = $RepoRoot` (process-scoped) before calling `winget configure`. Child DSC processes inherit this variable and use it in script resources that need the repo path (symlinks, config patches).



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
| `NODE_HOME` | `%ProgramFiles%\nodejs` |


Session-scoped vars set in `files/powershell/profile.ps1`: `SRC_VFDOT`, `SRC_VFCOM`, `SRC_VFMSG`, `SRC_VFMIR`, `SRC_VFSHG`.

### PowerShell Profile

`files/powershell/profile.ps1` sets session env vars, initializes Oh My Posh and posh-git, then dot-sources all `*.ps1` files from `files/powershell/scripts/` dynamically.

#### Profile Scripts (`files/powershell/scripts/`)

| Script | Aliases | Description |
|---|---|---|
| `copilot.ps1` | `scp`, `rscp` | Switch Copilot provider interactively (GitHub / LiteLLM BYOK / FoundryLocal). `scp` shows a menu; `-Model` and `-Provider` params for non-interactive use. Reads `LITELLM_BASE_URL`/`LITELLM_API_KEY` from env; queries `foundry service status` for FoundryLocal. |
| `docker.ps1` | `ccreg` | `Clear-Docker` — prune images and system resources. `Connect-ContainerRegistry` — authenticate to ACR via `az acr login` (uses current az login session, no plaintext creds). |
| `git.ps1` | — | `Reset-AllRepositories`, `Get-AllRepositories`, `Clear-RepositoryBranches`. |
| `java.ps1` | `sjv`, `rsjv` | `Set-JavaVersion` — interactive JDK menu or `-Version` param (11/17/21/25). Updates `JAVA_HOME`. |
| `navigation.ps1` | `slvf`, `slcom`, `slmsg`, `slmir`, `slshg`, `sacom`, `samsg`, `samir`, `sashg` | Quick `cd` and `dotnet run` shortcuts for personal repos. |
| `Set-NodeVersion.ps1` | `snv`, `rsnv` | `Set-NodeVersion` — interactive Node.js menu or `-Version` param (20/22/24). Updates `NODE_HOME` and `PATH`. Reads `NODE_X_HOME` vars if manually configured. |
| `solution-context.ps1` | `clctx` | `Initialize-SolutionContext` (sets ARM_* env vars), `Clear-SolutionContext`. |
| `utilities.ps1` | `cthash`, `code` | `ConvertTo-Sha256Hash`, `Get-Path`, `code` → `code-insiders`. |

## Commands

### Install

Run the full bootstrap (requires admin):

```pwsh
.\scripts\Install-Dotfiles.ps1
```

### Validate

> **Note:** `winget configure validate` targets the DSCv2 schema and reports warnings for DSCv3 resource types (`Microsoft.Windows/Registry`, `Microsoft.WinGet/Package`, `Microsoft.DSC.Transitional/*`). Use Pester tests for structural validation instead.

Validate config YAML structure and lint all scripts:

```pwsh
Invoke-Pester .\tests\
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
- PSScriptAnalyzer lint on all `.ps1` files
- Pester tests (DSCv3 config structure, package declarations, registry resources, DSC script resources, JSON parsing, syntax checks)

> `winget configure validate` is **not used in CI** — it targets DSCv2 and reports false warnings for DSCv3 resources.

CI cannot test symlinks, env vars, or package installs (no Dev Drive or admin on runners).

### Add a Package

Add a `Microsoft.WinGet/Package` resource entry to `.config/configuration.winget` with `properties.id`, `properties.source: winget`, and `useLatest: true`.

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
