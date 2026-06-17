#Requires -Version 7.0

<#
.SYNOPSIS
    Configures an alternate git identity for all repositories under a given path.
.DESCRIPTION
    Creates a gitconfig file under ~/.config/git/ with the given name and email,
    then wires it into the global gitconfig via an includeIf gitdir condition so
    git automatically applies the identity for any repo under the specified path.
    Idempotent — re-running with the same path updates the identity config file
    without adding a duplicate includeIf entry.
.PARAMETER Path
    Root directory whose git repositories should use the alternate identity.
    Typically an org-level folder like 'W:\Source\Repos\Orion'.
.PARAMETER Email
    Email address for git commits in the workspace.
.PARAMETER Name
    Display name for git commits. Defaults to the global user.name.
.EXAMPLE
    Set-WorkspaceIdentity -Path 'W:\Source\Repos\Orion' -Email 'victor.frye@leadingedje.com'
.EXAMPLE
    Set-WorkspaceIdentity -Path 'W:\Source\Repos\Orion' -Email 'victor.frye@leadingedje.com' -Name 'Victor Frye'
#>

function Set-WorkspaceIdentity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Email,
        [string] $Name = (git config --global user.name 2>$null)
    )

    if (-not (Test-Path $Path)) {
        Write-Warning "Path does not exist: $Path"
        return
    }

    $gitPath = $Path.Replace('\', '/').TrimEnd('/') + '/'
    $slug = (Split-Path $Path -Leaf).ToLower() -replace '[^a-z0-9]', '-'

    $configDir = Join-Path $HOME '.config\git'
    if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }
    $configFile = Join-Path $configDir "$slug.gitconfig"
    $configRelPath = "~/.config/git/$slug.gitconfig"

    @"
[user]
    name = $Name
    email = $Email
"@ | Set-Content -Path $configFile -Encoding UTF8

    $gitconfigPath = Join-Path $HOME '.gitconfig'
    $existing = if (Test-Path $gitconfigPath) { Get-Content $gitconfigPath -Raw } else { '' }
    if ($existing -notmatch [regex]::Escape("gitdir:$gitPath")) {
        $block = "`n[includeIf `"gitdir:$gitPath`"]`n    path = $configRelPath"
        Add-Content -Path $gitconfigPath -Value $block -Encoding UTF8
    }

    Write-Host "Workspace identity set: $gitPath -> $Email" -ForegroundColor Magenta
}

Set-Alias -Name swid -Value Set-WorkspaceIdentity
