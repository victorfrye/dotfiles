# MARK: Utilities

function ConvertTo-Sha256Hash([string] $Value) {
  $HashedBytes = [System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($Value))
  return [System.BitConverter]::ToString($HashedBytes).Replace('-', '').ToLower()
}

function Get-Path() {
  Write-Output $Env:PATH.Split(';')
}

Set-Alias -Name cthash -Value ConvertTo-Sha256Hash
Set-Alias -Name code -Value code-insiders
