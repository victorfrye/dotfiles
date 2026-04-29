#Requires -Version 7.0

<#
.SYNOPSIS
    JDK version management for the current PowerShell session.
.DESCRIPTION
    Provides interactive and parameterized switching between installed JDK
    versions using the JDK_X_HOME environment variables set by Install-Dotfiles.ps1.
    All changes are session-scoped only — JAVA_HOME is not persisted to Machine scope.
#>

function Set-JavaVersion {
    <#
    .SYNOPSIS
        Switches the active JDK version for the current session.
    .DESCRIPTION
        When called without -Version, displays an interactive numbered menu of all
        configured JDK installations detected via JDK_11_HOME, JDK_17_HOME,
        JDK_21_HOME, and JDK_25_HOME environment variables. When -Version is
        provided, switches directly without prompting. Changes only affect the
        current PowerShell session.
    .PARAMETER Version
        The JDK major version number to activate (e.g., 17, 21, 25).
        If omitted, an interactive selection menu is displayed.
    .EXAMPLE
        Set-JavaVersion
    .EXAMPLE
        Set-JavaVersion -Version 21
    #>
    [CmdletBinding()]
    param(
        [int] $Version
    )

    if (-not $Version) {
        $configured = @()
        foreach ($ver in @(11, 17, 21, 25)) {
            $varName = "JDK_${ver}_HOME"
            $path = [System.Environment]::GetEnvironmentVariable($varName)
            if ($path -and (Test-Path $path)) {
                $configured += [PSCustomObject]@{ Version = $ver; Path = $path }
            }
        }

        if ($configured.Count -eq 0) {
            Write-Output 'No JDK versions configured. Set JDK_<version>_HOME environment variables.'
            return
        }

        Write-Host ''
        Write-Host ('─' * 60) -ForegroundColor DarkCyan
        Write-Host 'Java — JDK Version Switcher' -ForegroundColor Cyan
        Write-Host ('─' * 60) -ForegroundColor DarkCyan
        Write-Host 'Select a JDK version:' -ForegroundColor White
        Write-Host ''

        for ($i = 0; $i -lt $configured.Count; $i++) {
            $entry = $configured[$i]
            $current = if ($env:JAVA_HOME -eq $entry.Path) { ' [current]' } else { '' }
            Write-Host "$($i + 1)) JDK $($entry.Version)$current" -ForegroundColor Yellow -NoNewline
            Write-Host "  — $($entry.Path)" -ForegroundColor DarkGray
        }
        Write-Host "$($configured.Count + 1)) Exit" -ForegroundColor DarkGray

        Write-Host ''
        $raw = Read-Host "Enter number (1-$($configured.Count + 1))"
        $idx = 0
        if (-not [int]::TryParse($raw.Trim(), [ref]$idx) -or $idx -lt 1 -or $idx -gt ($configured.Count + 1)) {
            Write-Warning "Invalid selection '$raw'. Aborting."
            return
        }
        if ($idx -eq ($configured.Count + 1)) { return }

        $selected = $configured[$idx - 1]
        $env:JAVA_HOME = $selected.Path
        Write-Output "The JAVA_HOME environment variable is now set to $env:JAVA_HOME."
        return
    }

    $varName = "JDK_${Version}_HOME"
    $path = [System.Environment]::GetEnvironmentVariable($varName)

    if (-not $path -or -not (Test-Path $path)) {
        Write-Output "No JDK configured for version $Version... Aborted."
        return
    }

    if ($env:JAVA_HOME -ne $path) {
        $env:JAVA_HOME = $path
        Write-Output "The JAVA_HOME environment variable is now set to $env:JAVA_HOME."
    }
}

function Reset-JavaVersion {
    <#
    .SYNOPSIS
        Resets JAVA_HOME to the default JDK version (JDK 25).
    .DESCRIPTION
        Sets JAVA_HOME back to the path configured in JDK_25_HOME, restoring
        the default JDK for the current PowerShell session.
    .EXAMPLE
        Reset-JavaVersion
    #>
    [CmdletBinding()]
    param()

    $env:JAVA_HOME = $env:JDK_25_HOME
    Write-Output "The JAVA_HOME environment variable is now set to $env:JAVA_HOME."
}

Set-Alias -Name sjv -Value Set-JavaVersion
Set-Alias -Name rsjv -Value Reset-JavaVersion
