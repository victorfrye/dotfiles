#Requires -Version 7.0

<#
.SYNOPSIS
    Uploads the local SSH public key to a GitHub account using a given token.
.DESCRIPTION
    Registers id_ed25519.pub as both an authentication key and a signing key
    on GitHub. Uses GH_TOKEN to authenticate without affecting the current
    gh session — useful for uploading to a secondary account such as a work
    or enterprise managed GitHub account.
.PARAMETER Token
    GitHub personal access token with admin:public_key and admin:ssh_signing_key
    scopes. Defaults to the GITHUB_WORK_TOKEN environment variable.
.PARAMETER Title
    Friendly name for the keys in GitHub. Defaults to the machine hostname.
.EXAMPLE
    Add-GitHubSshKey
.EXAMPLE
    Add-GitHubSshKey -Token $myWorkToken -Title 'DESKTOP-WORK'
#>

function Add-GitHubSshKey {
    [CmdletBinding()]
    param(
        [string] $Token = $env:GITHUB_WORK_TOKEN,
        [string] $Title = $env:COMPUTERNAME,
        [string] $KeyFile = (Join-Path $HOME '.ssh\id_ed25519.pub')
    )

    if (-not $Token) {
        Write-Warning 'No token provided. Pass -Token or set GITHUB_WORK_TOKEN in env.ps1.'
        return
    }

    if (-not (Test-Path $KeyFile)) {
        Write-Warning "Key file not found: $KeyFile. Run winget configure to generate an SSH key first."
        return
    }

    $pubKeyBody = (Get-Content $KeyFile -Raw).Trim().Split(' ')[1]

    $prevToken = $env:GH_TOKEN
    $env:GH_TOKEN = $Token
    try {
        # Auth key
        $authKeys = gh api user/keys 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue
        $authMatch = $authKeys | Where-Object { $_.key -and $_.key.Trim().Split(' ')[1] -eq $pubKeyBody }
        if ($authMatch) {
            Write-Host "SSH auth key already registered ($($authMatch.title))." -ForegroundColor Magenta
        } else {
            gh ssh-key add $KeyFile --title $Title --type authentication 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "SSH auth key added as '$Title'." -ForegroundColor Magenta
            } else {
                Write-Warning "Failed to upload SSH auth key."
            }
        }

        # Signing key
        $signKeys = gh api user/ssh_signing_keys 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue
        $signMatch = $signKeys | Where-Object { $_.key -and $_.key.Trim().Split(' ')[1] -eq $pubKeyBody }
        if ($signMatch) {
            Write-Host "SSH signing key already registered ($($signMatch.title))." -ForegroundColor Magenta
        } else {
            gh ssh-key add $KeyFile --title $Title --type signing 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "SSH signing key added as '$Title'." -ForegroundColor Magenta
            } else {
                Write-Warning "Failed to upload SSH signing key."
            }
        }
    } finally {
        $env:GH_TOKEN = $prevToken
    }
}

Set-Alias -Name ghssh -Value Add-GitHubSshKey
