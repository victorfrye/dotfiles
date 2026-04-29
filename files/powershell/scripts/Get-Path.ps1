#Requires -Version 7.0

<#
.SYNOPSIS
    Displays the PATH environment variable as a list.
.DESCRIPTION
    Splits the current PATH by semicolons and outputs each entry on its own
    line, making it easy to inspect which directories are on the active search
    path without manually parsing the raw string.
.EXAMPLE
    Get-Path
#>

function Get-Path {
    [CmdletBinding()]
    param()

    $Env:PATH.Split(';')
}
