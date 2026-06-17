#Requires -Version 7.0

<#
.SYNOPSIS
    Resets all git repositories under REPOS_ROOT to a clean main-branch state.
.DESCRIPTION
    For each git repository discovered under REPOS_ROOT (or a given Root):
    - Removes all linked worktrees and runs worktree prune
    - Stashes any uncommitted changes including untracked files
    - Switches to the main branch
    - Fetches and fast-forward pulls origin/main
    - Rewrites any HTTPS GitHub remote URLs to SSH (git@github.com:)
.PARAMETER Root
    Root directory to search for git repositories. Defaults to $env:REPOS_ROOT.
.EXAMPLE
    Reset-Repositories
.EXAMPLE
    Reset-Repositories -Root 'W:\Source\Repos\VictorFrye'
#>

function Reset-Repositories {
    [CmdletBinding()]
    param(
        [string] $Root = $env:REPOS_ROOT
    )

    if (-not $Root -or -not (Test-Path $Root)) {
        Write-Warning 'REPOS_ROOT is not set or does not exist. Pass -Root or set the environment variable.'
        return
    }

    $repos = @(Get-ChildItem -Path $Root -Recurse -Force -Directory -Filter '.git' |
        Select-Object -ExpandProperty Parent)

    if ($repos.Count -eq 0) {
        Write-Host "No git repositories found under $Root." -ForegroundColor Yellow
        return
    }

    Write-Host ''
    Write-Host ('─' * 60) -ForegroundColor DarkCyan
    Write-Host "Repositories — Reset ($($repos.Count) repos)" -ForegroundColor Cyan
    Write-Host ('─' * 60) -ForegroundColor DarkCyan

    foreach ($repo in $repos) {
        $repoPath = $repo.FullName

        Write-Host ''
        Write-Host "  $($repo.Name)" -ForegroundColor White

        # Remove linked worktrees
        $worktrees = @(git -C $repoPath worktree list --porcelain 2>$null |
            Where-Object { $_ -match '^worktree ' } |
            ForEach-Object { ($_ -replace '^worktree ', '').Trim() } |
            Select-Object -Skip 1)
        if ($worktrees.Count -gt 0) {
            foreach ($wt in $worktrees) {
                git -C $repoPath worktree remove --force $wt 2>$null | Out-Null
            }
            git -C $repoPath worktree prune 2>$null | Out-Null
            Write-Host "    Pruned $($worktrees.Count) worktree(s)" -ForegroundColor DarkGray
        }

        # Stash uncommitted changes
        $dirty = git -C $repoPath status --porcelain 2>$null
        if ($dirty) {
            git -C $repoPath stash push --include-untracked --message "Reset-Repositories $(Get-Date -Format 'yyyy-MM-dd')" 2>$null | Out-Null
            Write-Host '    Stashed uncommitted changes' -ForegroundColor DarkGray
        }

        # Switch to main
        $branch = git -C $repoPath branch --show-current 2>$null
        if ($branch -ne 'main') {
            git -C $repoPath checkout main 2>$null | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "    $($repo.Name): could not switch to main — skipping"
                continue
            }
        }

        # Fetch and fast-forward pull
        git -C $repoPath fetch origin --prune 2>$null | Out-Null
        $pull = git -C $repoPath pull --ff-only origin main 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "    Pull skipped — not fast-forwardable" -ForegroundColor Yellow
        }

        # Rewrite HTTPS GitHub remote to SSH
        $remoteUrl = git -C $repoPath remote get-url origin 2>$null
        if ($remoteUrl -match '^https://github\.com/(.+?)(?:\.git)?$') {
            git -C $repoPath remote set-url origin "git@github.com:$($Matches[1]).git" 2>$null | Out-Null
            Write-Host '    Remote rewritten to SSH' -ForegroundColor DarkGray
        }

        Write-Host '    Done' -ForegroundColor Magenta
    }

    Write-Host ''
    Write-Host ('─' * 60) -ForegroundColor DarkCyan
    Write-Host "Done. $($repos.Count) repositories reset." -ForegroundColor Cyan
    Write-Host ('─' * 60) -ForegroundColor DarkCyan
    Write-Host ''
}

Set-Alias -Name rsrep -Value Reset-Repositories
