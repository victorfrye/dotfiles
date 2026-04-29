# MARK: Copilot — provider and model management
#
# Supports three providers:
#   GitHub    — default GitHub-hosted Copilot (clears all BYOK env vars)
#   LiteLLM   — custom models via a LiteLLM proxy; reads LITELLM_BASE_URL and LITELLM_API_KEY from env
#   FoundryLocal — local inference via Azure AI Foundry Local; queries the service at runtime

$script:LiteLLMModels = @(
  'claude-haiku-4.5'
  'gpt-5-mini'
  'claude-opus-4.7'
  'claude-sonnet-4.6'
)

function Reset-CopilotProvider() {
  foreach ($var in @('COPILOT_PROVIDER_BASE_URL', 'COPILOT_PROVIDER_API_KEY', 'COPILOT_MODEL')) {
    [System.Environment]::SetEnvironmentVariable($var, $null, 'Process')
  }
  Write-Host 'GitHub Copilot provider restored (BYOK variables cleared).' -ForegroundColor Green
}

function Set-CopilotProvider([string] $Model, [string] $Provider) {
  $entries = Build-ProviderEntries

  if ($entries.Count -eq 0) {
    Write-Warning 'No providers available. Ensure LITELLM_BASE_URL is set or FoundryLocal is running.'
    return
  }

  $selected = $null

  if (-not [string]::IsNullOrWhiteSpace($Model)) {
    $selected = $entries | Where-Object { $_.Model -ieq $Model } | Select-Object -First 1
    if (-not $selected) {
      $validModels = ($entries | Where-Object { $_.Model } | ForEach-Object { $_.Model }) -join ', '
      Write-Error "Model '$Model' not found. Valid options: $validModels"
      return
    }
  } else {
    Write-Host ''
    Write-Host ('─' * 70) -ForegroundColor DarkCyan
    Write-Host 'GitHub Copilot — Provider & Model Switcher' -ForegroundColor Cyan
    Write-Host ('─' * 70) -ForegroundColor DarkCyan
    Write-Host 'Select a provider and model:' -ForegroundColor White
    Write-Host ''

    for ($i = 0; $i -lt $entries.Count; $i++) {
      $entry = $entries[$i]
      $label = if ($entry.Model) { "$($entry.Provider)] $($entry.Model)" } else { $entry.Provider }
      $current = if (($entry.Provider -eq 'GitHub' -and -not $env:COPILOT_MODEL) -or ($entry.Model -and $env:COPILOT_MODEL -ieq $entry.Model)) { ' [current]' } else { '' }
      Write-Host "$($i + 1)) $label$current" -ForegroundColor Yellow
    }

    Write-Host ''
    $raw = Read-Host "Enter number (1-$($entries.Count))"
    $idx = 0
    if (-not [int]::TryParse($raw.Trim(), [ref]$idx) -or $idx -lt 1 -or $idx -gt $entries.Count) {
      Write-Warning "Invalid selection '$raw'. Aborting."
      return
    }
    $selected = $entries[$idx - 1]
  }

  Set-CopilotEnvironmentVariables $selected
}

function Build-ProviderEntries() {
  $entries = @()

  $entries += [PSCustomObject]@{ Provider = 'GitHub'; Model = $null; BaseUrl = $null; ApiKey = $null }

  $litellmBase = [System.Environment]::GetEnvironmentVariable('LITELLM_BASE_URL')
  $litellmKey = [System.Environment]::GetEnvironmentVariable('LITELLM_API_KEY')
  foreach ($model in $script:LiteLLMModels) {
    $entries += [PSCustomObject]@{ Provider = 'LiteLLM'; Model = $model; BaseUrl = $litellmBase; ApiKey = $litellmKey }
  }

  $foundryModels = Get-FoundryLocalModels
  foreach ($model in $foundryModels) {
    $entries += [PSCustomObject]@{ Provider = 'FoundryLocal'; Model = $model.Id; BaseUrl = $model.Endpoint; ApiKey = $null }
  }

  return $entries
}

function Get-FoundryLocalModels() {
  try {
    $statusOutput = foundry service status 2>&1 | Out-String
    $endpointMatch = [regex]::Match($statusOutput, 'https?://[^\s]+')
    if (-not $endpointMatch.Success) { return @() }

    $endpoint = $endpointMatch.Value.TrimEnd('/')
    $response = Invoke-RestMethod -Uri "$endpoint/foundry/list" -Method Get -ErrorAction Stop
    return $response | ForEach-Object {
      [PSCustomObject]@{ Id = $_.modelId; Endpoint = "$endpoint/v1" }
    }
  } catch {
    return @()
  }
}

function Set-CopilotEnvironmentVariables([PSCustomObject] $Entry) {
  $byokVars = @('COPILOT_PROVIDER_BASE_URL', 'COPILOT_PROVIDER_API_KEY', 'COPILOT_MODEL')

  if ($Entry.Provider -eq 'GitHub') {
    foreach ($var in $byokVars) {
      [System.Environment]::SetEnvironmentVariable($var, $null, 'Process')
    }
    Write-Host ''
    Write-Host 'Applying: GitHub Copilot' -ForegroundColor Cyan
    Write-Host 'BYOK variables cleared. GitHub-hosted routing will be used.' -ForegroundColor Green
    return
  }

  $env:COPILOT_PROVIDER_BASE_URL = $Entry.BaseUrl
  $env:COPILOT_PROVIDER_API_KEY = $Entry.ApiKey
  $env:COPILOT_MODEL = $Entry.Model

  Write-Host ''
  Write-Host "Applying: [$($Entry.Provider)] $($Entry.Model)" -ForegroundColor Cyan
  Write-Host "  COPILOT_PROVIDER_BASE_URL  = $($Entry.BaseUrl)" -ForegroundColor Green
  Write-Host "  COPILOT_MODEL              = $($Entry.Model)" -ForegroundColor Green

  if ($Entry.Provider -eq 'LiteLLM') {
    $masked = Get-MaskedKey $Entry.ApiKey
    Write-Host "  COPILOT_PROVIDER_API_KEY   = $masked" -ForegroundColor Green
  }
}

function Get-MaskedKey([string] $Key) {
  if ([string]::IsNullOrWhiteSpace($Key)) { return '(none)' }
  if ($Key.Length -le 8) { return '****' }
  return ($Key.Substring(0, 4) + ('*' * ($Key.Length - 8)) + $Key.Substring($Key.Length - 4))
}

Set-Alias -Name scp -Value Set-CopilotProvider
Set-Alias -Name rscp -Value Reset-CopilotProvider
