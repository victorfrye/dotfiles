# MARK: Node — version management
#
# Convention: NODE_20_HOME, NODE_22_HOME, NODE_24_HOME point to each Node.js installation.
# NODE_HOME points to the active version and its bin directory is kept in PATH.

function Reset-NodeVersion() {
  $defaultPath = [System.Environment]::GetEnvironmentVariable('NODE_24_HOME')
  if (-not $defaultPath -or -not (Test-Path $defaultPath)) {
    Write-Output 'NODE_24_HOME is not configured or does not exist.'
    return
  }
  Update-NodePath $env:NODE_HOME $defaultPath
  $env:NODE_HOME = $defaultPath
  Write-Output "The NODE_HOME environment variable is now set to $env:NODE_HOME."
}

function Set-NodeVersion([int] $Version) {
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

    Write-Host ''
    $raw = Read-Host "Enter number (1-$($configured.Count))"
    $idx = 0
    if (-not [int]::TryParse($raw.Trim(), [ref]$idx) -or $idx -lt 1 -or $idx -gt $configured.Count) {
      Write-Warning "Invalid selection '$raw'. Aborting."
      return
    }

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

function Update-NodePath([string] $OldHome, [string] $NewHome) {
  $pathParts = $env:PATH.Split(';') | Where-Object { $_ -and $_ -ne $OldHome }
  $env:PATH = ($NewHome + ';' + ($pathParts -join ';')).TrimEnd(';')
}

Set-Alias -Name snv -Value Set-NodeVersion
Set-Alias -Name rsnv -Value Reset-NodeVersion
