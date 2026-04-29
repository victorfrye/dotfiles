#Requires -Version 7.0

<#
.SYNOPSIS
    Node.js version management for the current PowerShell session.
.DESCRIPTION
    Provides interactive and parameterized switching between installed Node.js
    versions using the NODE_X_HOME environment variables set by Install-Dotfiles.ps1.
    Switches both NODE_HOME and the PATH entry so 'node' and 'npm' resolve correctly.
    All changes are session-scoped only — NODE_HOME is not persisted to Machine scope.
#>

function Set-NodeVersion {
    <#
    .SYNOPSIS
        Switches the active Node.js version for the current session.
    .DESCRIPTION
        When called without -Version, displays an interactive numbered menu of all
        configured Node.js installations detected via NODE_20_HOME, NODE_22_HOME,
        and NODE_24_HOME environment variables. When -Version is provided, switches
        directly without prompting. Updates both NODE_HOME and PATH so 'node' and
        'npm' resolve to the selected version immediately. Changes only affect the
        current PowerShell session.
    .PARAMETER Version
        The Node.js major version number to activate (e.g., 20, 22, 24).
        If omitted, an interactive selection menu is displayed.
    .EXAMPLE
        Set-NodeVersion
    .EXAMPLE
        Set-NodeVersion -Version 22
    #>
    [CmdletBinding()]
    param(
        [int] $Version
    )

    if (-not $Version) {
        $configured = @()
        foreach ($ver in @(20, 22, 24)) {
            $varName = "NODE_${ver}_HOME"
            $path = [System.Environment]::GetEnvironmentVariable($varName)
            if ($path -and (Test-Path $path)) {
                $configured += [PSCustomObject]@{ Version = $ver; Path = $path }
            }
        }

        if ($configured.Count -eq 0) {
            Write-Output 'No Node.js versions configured. Set NODE_<version>_HOME environment variables.'
            return
        }

        Write-Host ''
        Write-Host ('─' * 60) -ForegroundColor DarkCyan
        Write-Host 'Node.js — Version Switcher' -ForegroundColor Cyan
        Write-Host ('─' * 60) -ForegroundColor DarkCyan
        Write-Host 'Select a Node.js version:' -ForegroundColor White
        Write-Host ''

        for ($i = 0; $i -lt $configured.Count; $i++) {
            $entry = $configured[$i]
            $current = if ($env:NODE_HOME -eq $entry.Path) { ' [current]' } else { '' }
            Write-Host "$($i + 1)) Node.js $($entry.Version)$current" -ForegroundColor Yellow -NoNewline
            Write-Host "  — $($entry.Path)" -ForegroundColor DarkGray
        }
        Write-Host "$($configured.Count + 1)) Exit" -ForegroundColor DarkGray

        Write-Host ''
        Write-Host -NoNewline "Enter number (1-$($configured.Count + 1)) [Esc to cancel]: "
        $raw = ''
        while ($true) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq 'Escape') { Write-Host ''; return }
            if ($key.Key -eq 'Enter') { Write-Host ''; break }
            if ($key.Key -eq 'Backspace') {
                if ($raw.Length -gt 0) { $raw = $raw.Substring(0, $raw.Length - 1); [Console]::Write("`b `b") }
                continue
            }
            if ($key.KeyChar -match '\d') { $raw += $key.KeyChar; [Console]::Write($key.KeyChar) }
        }
        $idx = 0
        if (-not [int]::TryParse($raw.Trim(), [ref]$idx) -or $idx -lt 1 -or $idx -gt ($configured.Count + 1)) {
            Write-Warning "Invalid selection '$raw'. Aborting."
            return
        }
        if ($idx -eq ($configured.Count + 1)) { return }

        $selected = $configured[$idx - 1]
        Update-NodePath $env:NODE_HOME $selected.Path
        $env:NODE_HOME = $selected.Path
        Write-Output "The NODE_HOME environment variable is now set to $env:NODE_HOME."
        return
    }

    $varName = "NODE_${Version}_HOME"
    $path = [System.Environment]::GetEnvironmentVariable($varName)

    if (-not $path -or -not (Test-Path $path)) {
        Write-Output "No Node.js configured for version $Version... Aborted."
        return
    }

    if ($env:NODE_HOME -ne $path) {
        Update-NodePath $env:NODE_HOME $path
        $env:NODE_HOME = $path
        Write-Output "The NODE_HOME environment variable is now set to $env:NODE_HOME."
    }
}

function Reset-NodeVersion {
    <#
    .SYNOPSIS
        Resets NODE_HOME to the default Node.js version (Node 24).
    .DESCRIPTION
        Sets NODE_HOME back to the path configured in NODE_24_HOME and updates
        PATH accordingly, restoring the default Node.js for the current session.
    .EXAMPLE
        Reset-NodeVersion
    #>
    [CmdletBinding()]
    param()

    $defaultPath = [System.Environment]::GetEnvironmentVariable('NODE_24_HOME')
    if (-not $defaultPath -or -not (Test-Path $defaultPath)) {
        Write-Output 'NODE_24_HOME is not configured or does not exist.'
        return
    }

    Update-NodePath $env:NODE_HOME $defaultPath
    $env:NODE_HOME = $defaultPath
    Write-Output "The NODE_HOME environment variable is now set to $env:NODE_HOME."
}

function Update-NodePath {
    <#
    .SYNOPSIS
        Swaps the Node.js directory in the current session PATH.
    .DESCRIPTION
        Removes OldHome from PATH and prepends NewHome, ensuring 'node' and 'npm'
        resolve to the correct version after a version switch. Session-scoped only.
    .PARAMETER OldHome
        The Node.js directory to remove from PATH.
    .PARAMETER NewHome
        The Node.js directory to prepend to PATH.
    .EXAMPLE
        Update-NodePath $env:NODE_HOME 'C:\Program Files\nodejs'
    #>
    [CmdletBinding()]
    param(
        [string] $OldHome,
        [string] $NewHome
    )

    $pathParts = $env:PATH.Split(';') | Where-Object { $_ -and $_ -ne $OldHome }
    $env:PATH = ($NewHome + ';' + ($pathParts -join ';')).TrimEnd(';')
}

Set-Alias -Name snv -Value Set-NodeVersion
Set-Alias -Name rsnv -Value Reset-NodeVersion
