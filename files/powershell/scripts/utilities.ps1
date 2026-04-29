#Requires -Version 7.0

<#
.SYNOPSIS
    General-purpose developer utilities.
.DESCRIPTION
    Provides small helper functions for hashing, PATH inspection, and
    other common shell tasks used during development.
#>

function ConvertTo-Sha256Hash {
    <#
    .SYNOPSIS
        Computes the SHA-256 hash of a string.
    .DESCRIPTION
        Encodes the input as UTF-8, computes a SHA-256 hash, and returns
        the result as a lowercase hexadecimal string.
    .PARAMETER Value
        The string to hash.
    .EXAMPLE
        ConvertTo-Sha256Hash 'hello world'
    .EXAMPLE
        cthash 'my-secret-value'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Value
    )

    $HashedBytes = [System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($Value))
    return [System.BitConverter]::ToString($HashedBytes).Replace('-', '').ToLower()
}

function Get-Path {
    <#
    .SYNOPSIS
        Displays the PATH environment variable as a list.
    .DESCRIPTION
        Splits the current PATH by semicolons and outputs each entry on
        its own line, making it easier to inspect the active search path.
    .EXAMPLE
        Get-Path
    #>
    [CmdletBinding()]
    param()

    $Env:PATH.Split(';')
}

Set-Alias -Name cthash -Value ConvertTo-Sha256Hash
