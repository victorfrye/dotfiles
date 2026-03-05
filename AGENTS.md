# Agent Instructions

This document provides context for AI coding agents working in this repository.

## Architecture

This is a Windows dotfiles repository that partially automates the setup of a local Windows development machine. The single entry point is `scripts/Install-Dotfiles.ps1`, invoked remotely on a fresh machine via:

```pwsh
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/victorfrye/dotfiles/main/scripts/Install-Dotfiles.ps1' | Invoke-Expression
```

The script is **idempotent** — re-running it on an already-configured machine safely skips or updates existing installations.

### Repository Structure

- **`scripts/Install-Dotfiles.ps1`** — master installation script; orchestrates all setup steps in order
- **`files/winget/packages.json`** — WinGet package manifest, imported with `winget import`
- **`files/powershell/profile.ps1`** — PowerShell profile, copied to `$PROFILE.CurrentUserAllHosts`
- **`files/powershell/yfnd.omp.json`** — custom Oh My Posh theme (active theme, referenced from repo path)
- **`files/az/config.json`** — Azure PowerShell config, imported via `Import-AzConfig`
- **`files/fonts/`** — CaskaydiaCove Nerd Font `.otf` files, installed to `C:\Windows\Fonts`
- **`files/copilot/`** — GitHub Copilot CLI configuration (see below)
- **`env.ps1`** — local secrets file (**gitignored**, never committed; see below)

### Copilot CLI Configuration (`files/copilot/`)

Deployed to `~/.copilot/` by the install script. Contains:

- **`config.json`** — portable Copilot CLI settings (banner, theme, model preference)
- **`copilot-instructions.md`** — personal coding instructions, engineering philosophy, device repo map with placeholder sections for company/client orgs
- **`mcp-config.json`** — MCP server definitions: Aspire, Playwright, Context7, and Azure DevOps (placeholder org — configure the `<YOUR_ORG>` value in `~/.copilot/mcp-config.json` after install)
- **`agents/`** — custom agent definitions: `dotnet-developer`, `interviewer`, `react-developer`, `terraform-developer`

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

**Post-install step:** After the install script completes and `env.ps1` is created, run the Copilot CLI from the repo root to get guided assistance with any remaining workstation configuration:

```pwsh
cd $env:SRC_VFDOT
copilot
```

### Environment Variables

Set at Machine scope by `Install-Dotfiles.ps1`:

| Variable | Value |
|---|---|
| `DEVDRIVE` | Root of Dev Drive (e.g. `L:`) |
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
| `JAVA_HOME` | `%JDK_21_HOME%` (default) |
| `NVIM_ROOT` | `%PROGRAMFILES%\Neovim` |

Session-scoped vars set in `files/powershell/profile.ps1`: `SRC_VFDOT`, `SRC_VFCOM`, `SRC_VFMSG`, `SRC_VFMIR`, `SRC_VFCNT`, `SRC_VFSHG`, `ANDROID_HOME`.

### PowerShell Profile

`files/powershell/profile.ps1` configures the shell environment:

- Oh My Posh with custom `yfnd` theme (referenced from `$env:SRC_VFDOT\files\powershell\yfnd.omp.json`)
- posh-git module for Git integration
- Aliases: `sjh`/`rsjh` (Java home switching), `slvf`/`slcom`/`slmsg`/`slmir`/`slcnt`/`slshg` (quick `cd` to repos), `sacom`/`samsg`/`samir`/`sashg` (app launchers), `code` → `code-insiders`, `cthash` (SHA-256 hash), `clctx` (clear solution context)
- `Initialize-SolutionContext` — generic function to set ARM_* env vars; project-specific shortcuts defined in `env.ps1`
- Placeholder comment blocks for company and client navigation/aliases (populated via `env.ps1`)

## Commands

There is no build or test system — this is a pure configuration and scripting repository. Changes are validated by running the install script on a target machine:

```pwsh
.\scripts\Install-Dotfiles.ps1
```

To add a new WinGet package, append its `PackageIdentifier` to `files/winget/packages.json` under `Sources[0].Packages`.

## Conventions

### Git

- Trunk-based development on `main` with short-lived PR branches
- Conventional commits: `feat:`, `fix:`, `chore:`, etc.

### Maintaining This File

When introducing new scripts, configuration files, environment variable changes, or Copilot agent/config updates, update this `AGENTS.md` file to keep future sessions informed.

---

## Personal Repo Ecosystem

This dotfiles repo configures the machine that runs all personal repositories cloned under `%REPOS_VF%`. The other repos in this ecosystem share a common architecture; their `AGENTS.md` files are the authoritative reference for each.

### VictorFrye/DotCom

Personal portfolio and blog at [victorfrye.com](https://victorfrye.com). Deployed as an Azure Static Web App.

- **`src/WebClient/`** — Next.js 16 app with static export (`output: 'export'`). No SSR or API routes.
- **`src/AppHost/`** — .NET Aspire AppHost (net10.0) for local orchestration via `aspire run`. Not deployed.
- **`infra/`** — Terraform for Azure infrastructure (Static Web App, DNS).
- UI: **Fluent UI React v9** + **Griffel** (`makeStyles`) for CSS-in-JS. No CSS modules or Tailwind.
- Blog posts are MDX with YAML frontmatter, file-based routing under `app/blog/posts/<slug>/`.
- See [`%SRC_VFCOM%/AGENTS.md`](../DotCom/AGENTS.md) for full commands and conventions.

### VictorFrye/MicrosoftGraveyard

Open-source memorial site at [microsoftgraveyard.com](https://microsoftgraveyard.com). Deployed as an Azure Static Web App.

- Identical stack to DotCom: Next.js 16 static export, .NET Aspire AppHost, Terraform infra.
- Core feature: `corpses.json` data file + `use-corpse.ts` business logic (age calculation, obituary generation) + `headstone.tsx` card component.
- UI: **Fluent UI React v9** + **Griffel** (`makeStyles`).
- See [`%SRC_MSG%/AGENTS.md`](../MicrosoftGraveyard/AGENTS.md) for full commands and conventions.

### Shared Conventions Across DotCom and MicrosoftGraveyard

- **Biome** for linting and formatting (not ESLint/Prettier); `npm run lint:fix` to auto-fix
- **Jest 30** + `@testing-library/react`; 80% coverage threshold; test files colocated with source
- Path alias `@/*` → `./app/*` for all intra-app imports
- `'use client'` on interactive components; pages/layouts are server components by default
- Feature directories under `app/` use barrel exports (`index.ts`) and `strings.ts` for UI text
- 2-space indent / LF for web files; 4-space indent / CRLF for C# files (EditorConfig enforced)
- Conventional commits with feature scopes (e.g., `feat(blog):`, `fix(graveyard):`, `chore(infra):`)
