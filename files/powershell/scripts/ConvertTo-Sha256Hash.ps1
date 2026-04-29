#Requires -Version 7.0

<#
.SYNOPSIS
    Computes the SHA-256 hash of a string.
.DESCRIPTION
    Encodes the input value as UTF-8, computes a SHA-256 hash, and returns
    the result as a lowercase hexadecimal string. Useful for verifying string
    integrity or generating deterministic identifiers during development.
.PARAMETER Value
    The string to hash.
.EXAMPLE
    ConvertTo-Sha256Hash 'hello world'
.EXAMPLE
    cthash 'my-secret-value'
#>

function ConvertTo-Sha256Hash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Value
    )

    $HashedBytes = [System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($Value))
    return [System.BitConverter]::ToString($HashedBytes).Replace('-', '').ToLower()
}

Set-Alias -Name cthash -Value ConvertTo-Sha256Hash
