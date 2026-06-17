#Requires -Version 7.0

<#
.SYNOPSIS
    Opens the Azure DevOps SSH key settings page and prints the RSA public key for pasting.
.DESCRIPTION
    Azure DevOps has no public REST API for SSH key management. This helper opens
    the SSH keys settings page for the given organization in the browser and prints
    the contents of id_rsa.pub to the terminal so you can copy and paste it in.
.PARAMETER Org
    The Azure DevOps organization name (e.g. 'contoso' for dev.azure.com/contoso).
.EXAMPLE
    Add-AzureDevOpsSshKey -Org contoso
#>

function Add-AzureDevOpsSshKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Org,
        [string] $KeyFile = (Join-Path $HOME '.ssh\id_rsa.pub')
    )

    if (-not (Test-Path $KeyFile)) {
        Write-Warning "Key file not found at $KeyFile. Run winget configure to generate an RSA key first."
        return
    }

    $keyData = (Get-Content $KeyFile -Raw).Trim()
    $url = "https://dev.azure.com/$Org/_usersSettings/keys"

    Write-Host ''
    Write-Host ('─' * 60) -ForegroundColor DarkCyan
    Write-Host "  Azure DevOps SSH Key — $Org" -ForegroundColor Cyan
    Write-Host ('─' * 60) -ForegroundColor DarkCyan
    Write-Host ''
    Write-Host '  Copy and paste this key into the browser:' -ForegroundColor White
    Write-Host ''
    Write-Host "  $keyData" -ForegroundColor DarkGray
    Write-Host ''
    Write-Host "  Opening $url..." -ForegroundColor Magenta

    Start-Process $url

    Write-Host ('─' * 60) -ForegroundColor DarkCyan
    Write-Host ''
}

Set-Alias -Name azdossh -Value Add-AzureDevOpsSshKey
