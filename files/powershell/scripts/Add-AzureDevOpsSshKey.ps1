#Requires -Version 7.0

<#
.SYNOPSIS
    Uploads the local RSA SSH public key to an Azure DevOps organization.
.DESCRIPTION
    Reads id_rsa.pub and registers it with the given Azure DevOps organization
    via the REST API. Skips gracefully if the key is already registered.
    Azure DevOps does not support ed25519 keys — id_rsa is required.
.PARAMETER Org
    The Azure DevOps organization name (e.g. 'contoso' for dev.azure.com/contoso).
.PARAMETER Token
    Personal access token with SSH key management permissions.
    Defaults to the ADO_TOKEN environment variable.
.PARAMETER Title
    Friendly name for the key in Azure DevOps. Defaults to the machine hostname.
.EXAMPLE
    Add-AzureDevOpsSshKey -Org contoso
.EXAMPLE
    Add-AzureDevOpsSshKey -Org contoso -Token $myPat -Title 'DESKTOP-WORK'
#>

function Add-AzureDevOpsSshKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Org,
        [string] $Token = $env:ADO_TOKEN,
        [string] $Title = $env:COMPUTERNAME,
        [string] $KeyFile = (Join-Path $HOME '.ssh\id_rsa.pub')
    )

    if (-not $Token) {
        Write-Warning 'ADO_TOKEN not set — pass -Token or set the environment variable in env.ps1.'
        return
    }

    if (-not (Test-Path $KeyFile)) {
        Write-Warning "Key file not found at $KeyFile. Run winget configure to generate an RSA key first."
        return
    }

    $keyData = (Get-Content $KeyFile -Raw).Trim()
    $pubKeyBody = $keyData.Split(' ')[1]
    $base64Token = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$Token"))
    $headers = @{
        Authorization  = "Basic $base64Token"
        'Content-Type' = 'application/json'
    }
    $apiUrl = "https://vssps.dev.azure.com/$Org/_apis/ssh/publickeys?api-version=7.1-preview.1"

    $existing = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method GET -ErrorAction SilentlyContinue
    if ($existing -and $existing.value) {
        $match = $existing.value | Where-Object { $_.keyData -and $_.keyData.Trim().Split(' ')[1] -eq $pubKeyBody }
        if ($match) {
            Write-Host "SSH key already registered for $Org ($($match.friendlyName))." -ForegroundColor Magenta
            return
        }
    }

    $body = @{ keyData = $keyData; friendlyName = $Title } | ConvertTo-Json
    Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method POST -Body $body | Out-Null
    Write-Host "SSH key added to Azure DevOps org '$Org' as '$Title'." -ForegroundColor Magenta
}

Set-Alias -Name adossh -Value Add-AzureDevOpsSshKey
