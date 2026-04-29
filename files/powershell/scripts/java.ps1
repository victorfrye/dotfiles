# MARK: Java — JDK version management

function Reset-JavaVersion() {
  $env:JAVA_HOME = $env:JDK_25_HOME
  Write-Output "The JAVA_HOME environment variable is now set to $env:JAVA_HOME."
}

function Set-JavaVersion([int] $Version) {
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

    Write-Host ''
    $raw = Read-Host "Enter number (1-$($configured.Count))"
    $idx = 0
    if (-not [int]::TryParse($raw.Trim(), [ref]$idx) -or $idx -lt 1 -or $idx -gt $configured.Count) {
      Write-Warning "Invalid selection '$raw'. Aborting."
      return
    }

    $selected = $configured[$idx - 1]
    $env:JAVA_HOME = $selected.Path
    Write-Output "The JAVA_HOME environment variable is now set to $env:JAVA_HOME."
    return
  }

  $varName = "JDK_${Version}_HOME"
  $path = [System.Environment]::GetEnvironmentVariable($varName)

  if (-not $path) {
    Write-Output "No JDK configured for version $Version... Aborted."
    return
  }

  if (-not (Test-Path $path)) {
    Write-Output "No JDK configured for version $Version... Aborted."
    return
  }

  if ($env:JAVA_HOME -ne $path) {
    $env:JAVA_HOME = $path
    Write-Output "The JAVA_HOME environment variable is now set to $env:JAVA_HOME."
  }
}

Set-Alias -Name sjv -Value Set-JavaVersion
Set-Alias -Name rsjv -Value Reset-JavaVersion
