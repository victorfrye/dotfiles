#Requires -Version 7.0

<#
.SYNOPSIS
    GitHub Copilot provider and model management.
.DESCRIPTION
    Provides interactive and parameterized switching between GitHub Copilot
    providers: GitHub-hosted (default), LiteLLM BYOK proxy, and Azure AI
    Foundry Local. Sets the COPILOT_PROVIDER_BASE_URL, COPILOT_PROVIDER_API_KEY,
    and COPILOT_MODEL environment variables consumed by the Copilot CLI.

    LiteLLM requires LITELLM_BASE_URL and LITELLM_API_KEY environment variables.
    FoundryLocal requires the 'foundry' CLI and a running local inference service.
#>

$script:LiteLLMModels = @(
    'claude-haiku-4.5'
    'gpt-5-mini'
    'claude-opus-4.7'
    'claude-sonnet-4.6'
)

function Set-CopilotProvider {
    <#
    .SYNOPSIS
        Switches the active GitHub Copilot provider and model.
    .DESCRIPTION
        When called without parameters, displays an interactive flat menu listing
        GitHub Copilot (default), all configured LiteLLM models, and any models
        currently loaded in a running FoundryLocal service. When -Model is provided,
        switches directly without prompting. Changes are session-scoped only.
    .PARAMETER Model
        The model identifier to activate (e.g., 'claude-sonnet-4.6').
        If omitted, an interactive selection menu is displayed.
    .PARAMETER Provider
        Optional provider hint when using -Model directly ('GitHub', 'LiteLLM', 'FoundryLocal').
    .EXAMPLE
        Set-CopilotProvider
    .EXAMPLE
        Set-CopilotProvider -Model 'claude-sonnet-4.6'
    .EXAMPLE
        Set-CopilotProvider -Model 'claude-sonnet-4.6' -Provider 'LiteLLM'
    #>
    [CmdletBinding()]
    param(
        [string] $Model,
        [string] $Provider
    )

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
            $label = if ($entry.Model) { "[$($entry.Provider)] $($entry.Label ?? $entry.Model)" } else { $entry.Provider }
            $current = if (($entry.Provider -eq 'GitHub' -and -not $env:COPILOT_MODEL) -or ($entry.Model -and $env:COPILOT_MODEL -ieq $entry.Model)) { ' [current]' } else { '' }
            Write-Host "$($i + 1)) $label$current" -ForegroundColor Yellow
        }
        Write-Host "$($entries.Count + 1)) Exit" -ForegroundColor DarkGray

        Write-Host ''
        Write-Host -NoNewline "Enter number (1-$($entries.Count + 1)) [Esc to cancel]: "
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
        if (-not [int]::TryParse($raw.Trim(), [ref]$idx) -or $idx -lt 1 -or $idx -gt ($entries.Count + 1)) {
            Write-Warning "Invalid selection '$raw'. Aborting."
            return
        }
        if ($idx -eq ($entries.Count + 1)) { return }
        $selected = $entries[$idx - 1]
    }

    Set-CopilotEnvironmentVariables $selected
}

function Reset-CopilotProvider {
    <#
    .SYNOPSIS
        Restores GitHub Copilot to the default GitHub-hosted provider.
    .DESCRIPTION
        Clears COPILOT_PROVIDER_BASE_URL, COPILOT_PROVIDER_API_KEY, and
        COPILOT_MODEL from the current session, reverting to standard
        GitHub-hosted Copilot routing.
    .EXAMPLE
        Reset-CopilotProvider
    #>
    [CmdletBinding()]
    param()

    foreach ($var in @('COPILOT_PROVIDER_BASE_URL', 'COPILOT_PROVIDER_API_KEY', 'COPILOT_MODEL',
                       'COPILOT_PROVIDER_WIRE_API', 'COPILOT_PROVIDER_MAX_PROMPT_TOKENS', 'COPILOT_PROVIDER_MAX_OUTPUT_TOKENS')) {
        [System.Environment]::SetEnvironmentVariable($var, $null, 'Process')
    }
    Write-Host 'GitHub Copilot provider restored (BYOK variables cleared).' -ForegroundColor Green
}

function Build-ProviderEntries {
    <#
    .SYNOPSIS
        Builds the flat list of selectable provider/model entries.
    .DESCRIPTION
        Always includes the GitHub entry first, then LiteLLM models (when
        LITELLM_BASE_URL is configured), then cached FoundryLocal models,
        then locally available Ollama models.
    #>
    [CmdletBinding()]
    param()

    $entries = @()
    $entries += [PSCustomObject]@{ Provider = 'GitHub'; Model = $null; Label = $null; BaseUrl = $null; ApiKey = $null }

    $litellmBase = [System.Environment]::GetEnvironmentVariable('LITELLM_BASE_URL')
    $litellmKey  = [System.Environment]::GetEnvironmentVariable('LITELLM_API_KEY')
    if (-not [string]::IsNullOrWhiteSpace($litellmBase)) {
        foreach ($model in $script:LiteLLMModels) {
            $entries += [PSCustomObject]@{ Provider = 'LiteLLM'; Model = $model; Label = $null; BaseUrl = $litellmBase; ApiKey = $litellmKey }
        }
    }

    $foundryModels = Get-FoundryLocalModels
    foreach ($model in $foundryModels) {
        $entries += [PSCustomObject]@{ Provider = 'FoundryLocal'; Model = $model.ModelId; Label = $model.Alias; BaseUrl = $null; ApiKey = $null }
    }

    $ollamaModels = Get-OllamaModels
    foreach ($model in $ollamaModels) {
        $entries += [PSCustomObject]@{ Provider = 'Ollama'; Model = $model; Label = $null; BaseUrl = 'http://localhost:11434/v1'; ApiKey = $null }
    }

    return $entries
}

function Get-FoundryLocalModels {
    <#
    .SYNOPSIS
        Returns models available in the local FoundryLocal cache.
    .DESCRIPTION
        Parses 'foundry cache list' to enumerate locally downloaded models.
        Returns results without requiring the service to be running — the
        service is started on demand when a model is selected.
    #>
    [CmdletBinding()]
    param()

    try {
        $lines = foundry cache list 2>&1 | Where-Object { $_ -match '\S' }
        $models = @()
        foreach ($line in $lines) {
            $clean = $line -replace '[^\x20-\x7E]', '' # strip non-ASCII (emoji)
            if ($clean -match '^\s+(\S+)\s{2,}(\S+)\s*$') {
                $models += [PSCustomObject]@{ Alias = $Matches[1]; ModelId = $Matches[2] }
            }
        }
        return $models
    } catch {
        return @()
    }
}

function Get-FoundryLocalEndpoint {
    <#
    .SYNOPSIS
        Returns the running FoundryLocal service endpoint, starting it if needed.
    .DESCRIPTION
        Checks 'foundry service status' for a running endpoint. If the service is
        not running, calls 'foundry service start' and waits up to 30 seconds for
        it to become available. Returns $null if startup fails.
    #>
    [CmdletBinding()]
    param()

    $statusOutput = foundry service status 2>&1 | Out-String
    $match = [regex]::Match($statusOutput, 'https?://[^\s]+')
    if ($match.Success) {
        $uri = [System.Uri]$match.Value
        return "$($uri.Scheme)://$($uri.Authority)"
    }

    Write-Host '  FoundryLocal service is not running. Starting...' -ForegroundColor Yellow
    foundry service start 2>&1 | Out-Null

    $deadline = (Get-Date).AddSeconds(30)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 2
        $statusOutput = foundry service status 2>&1 | Out-String
        $match = [regex]::Match($statusOutput, 'https?://[^\s]+')
        if ($match.Success) {
            Write-Host '  FoundryLocal service started.' -ForegroundColor Green
            $uri = [System.Uri]$match.Value
            return "$($uri.Scheme)://$($uri.Authority)"
        }
    }

    Write-Warning 'FoundryLocal service did not start within 30 seconds.'
    return $null
}

function Get-OllamaModels {
    <#
    .SYNOPSIS
        Returns models available in the local Ollama installation.
    .DESCRIPTION
        Parses 'ollama list' to enumerate locally pulled models. Returns an empty
        array silently if Ollama is not installed or no models are present.
    #>
    [CmdletBinding()]
    param()

    try {
        $ollamaCmd = Get-Command ollama -ErrorAction Stop
        if (-not $ollamaCmd) { return @() }
        $lines = ollama list 2>&1 | Select-Object -Skip 1 | Where-Object { $_ -match '\S' }
        return $lines | ForEach-Object { ($_ -split '\s+')[0] } | Where-Object { $_ }
    } catch {
        return @()
    }
}

function Get-CopilotProvider {
    <#
    .SYNOPSIS
        Displays the currently active GitHub Copilot provider and model.
    .DESCRIPTION
        Reads COPILOT_PROVIDER_BASE_URL, COPILOT_PROVIDER_API_KEY, and
        COPILOT_MODEL from the current session and outputs a formatted summary.
        When no BYOK variables are set, reports GitHub-hosted as the active provider.
    .EXAMPLE
        Get-CopilotProvider
    #>
    [CmdletBinding()]
    param()

    $baseUrl = $env:COPILOT_PROVIDER_BASE_URL
    $apiKey  = $env:COPILOT_PROVIDER_API_KEY
    $model   = $env:COPILOT_MODEL

    Write-Host ''
    Write-Host ('─' * 70) -ForegroundColor DarkCyan
    Write-Host 'GitHub Copilot — Active Provider' -ForegroundColor Cyan
    Write-Host ('─' * 70) -ForegroundColor DarkCyan

    if ([string]::IsNullOrWhiteSpace($baseUrl) -and [string]::IsNullOrWhiteSpace($model)) {
        Write-Host '  Provider  : GitHub (default)' -ForegroundColor Green
        Write-Host '  Model     : (GitHub-routed)' -ForegroundColor Green
    } else {
        $provider = if (-not [string]::IsNullOrWhiteSpace($baseUrl)) {
            $litellmBase = [System.Environment]::GetEnvironmentVariable('LITELLM_BASE_URL')
            if ($baseUrl -eq $litellmBase) { 'LiteLLM' }
            elseif ($baseUrl -like '*11434*') { 'Ollama' }
            else { 'FoundryLocal' }
        } else { 'GitHub (custom model)' }

        Write-Host "  Provider  : $provider" -ForegroundColor Green
        Write-Host "  Model     : $model" -ForegroundColor Green

        if (-not [string]::IsNullOrWhiteSpace($baseUrl)) {
            Write-Host "  Base URL  : $baseUrl" -ForegroundColor Green
        }
        if (-not [string]::IsNullOrWhiteSpace($apiKey)) {
            Write-Host "  API Key   : $(Get-MaskedKey $apiKey)" -ForegroundColor Green
        }
        if (-not [string]::IsNullOrWhiteSpace($env:COPILOT_PROVIDER_WIRE_API)) {
            Write-Host "  Wire API  : $env:COPILOT_PROVIDER_WIRE_API" -ForegroundColor Green
        }
    }

    Write-Host ''
}

function Set-CopilotEnvironmentVariables {
    <#
    .SYNOPSIS
        Applies provider environment variables for the selected entry.
    .DESCRIPTION
        Sets or clears COPILOT_PROVIDER_BASE_URL, COPILOT_PROVIDER_API_KEY,
        and COPILOT_MODEL based on the selected provider entry.
    .PARAMETER Entry
        A PSCustomObject with Provider, Model, BaseUrl, and ApiKey properties.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject] $Entry
    )

    $byokVars = @('COPILOT_PROVIDER_BASE_URL', 'COPILOT_PROVIDER_API_KEY', 'COPILOT_MODEL',
                  'COPILOT_PROVIDER_WIRE_API', 'COPILOT_PROVIDER_MAX_PROMPT_TOKENS', 'COPILOT_PROVIDER_MAX_OUTPUT_TOKENS')

    if ($Entry.Provider -eq 'GitHub') {
        foreach ($var in $byokVars) {
            [System.Environment]::SetEnvironmentVariable($var, $null, 'Process')
        }
        Write-Host ''
        Write-Host 'Applying: GitHub Copilot' -ForegroundColor Cyan
        Write-Host 'BYOK variables cleared. GitHub-hosted routing will be used.' -ForegroundColor Green
        return
    }

    if ($Entry.Provider -eq 'FoundryLocal') {
        $endpoint = Get-FoundryLocalEndpoint
        if (-not $endpoint) { return }
        $Entry.BaseUrl = "$endpoint/v1"

        try {
            $models    = Invoke-RestMethod -Uri "$endpoint/v1/models" -ErrorAction Stop
            $modelInfo = $models.data | Where-Object { $_.id -eq $Entry.Model } | Select-Object -First 1
            if ($modelInfo) {
                $env:COPILOT_PROVIDER_MAX_PROMPT_TOKENS = [string]$modelInfo.maxInputTokens
                $env:COPILOT_PROVIDER_MAX_OUTPUT_TOKENS = [string]$modelInfo.maxOutputTokens
            }
        } catch {
            [System.Environment]::SetEnvironmentVariable('COPILOT_PROVIDER_MAX_PROMPT_TOKENS', $null, 'Process')
            [System.Environment]::SetEnvironmentVariable('COPILOT_PROVIDER_MAX_OUTPUT_TOKENS', $null, 'Process')
        }
        [System.Environment]::SetEnvironmentVariable('COPILOT_PROVIDER_WIRE_API', $null, 'Process')
    } elseif ($Entry.Provider -eq 'Ollama') {
        $env:COPILOT_PROVIDER_WIRE_API = 'responses'
        try {
            $body      = "{`"name`":`"$($Entry.Model)`"}"
            $modelInfo = Invoke-RestMethod -Method Post -Uri 'http://localhost:11434/api/show' -Body $body -ContentType 'application/json' -ErrorAction Stop
            $ctxProp   = $modelInfo.model_info.PSObject.Properties | Where-Object { $_.Name -like '*.context_length' } | Select-Object -First 1
            if ($ctxProp) {
                $ctx = [int]$ctxProp.Value
                $env:COPILOT_PROVIDER_MAX_PROMPT_TOKENS  = [string]$ctx
                $env:COPILOT_PROVIDER_MAX_OUTPUT_TOKENS  = [string][Math]::Min($ctx, 8192)
            } else {
                [System.Environment]::SetEnvironmentVariable('COPILOT_PROVIDER_MAX_PROMPT_TOKENS', $null, 'Process')
                [System.Environment]::SetEnvironmentVariable('COPILOT_PROVIDER_MAX_OUTPUT_TOKENS', $null, 'Process')
            }
        } catch {
            [System.Environment]::SetEnvironmentVariable('COPILOT_PROVIDER_MAX_PROMPT_TOKENS', $null, 'Process')
            [System.Environment]::SetEnvironmentVariable('COPILOT_PROVIDER_MAX_OUTPUT_TOKENS', $null, 'Process')
        }
    } else {
        [System.Environment]::SetEnvironmentVariable('COPILOT_PROVIDER_WIRE_API', $null, 'Process')
        [System.Environment]::SetEnvironmentVariable('COPILOT_PROVIDER_MAX_PROMPT_TOKENS', $null, 'Process')
        [System.Environment]::SetEnvironmentVariable('COPILOT_PROVIDER_MAX_OUTPUT_TOKENS', $null, 'Process')
    }

    $env:COPILOT_PROVIDER_BASE_URL = $Entry.BaseUrl
    $env:COPILOT_PROVIDER_API_KEY  = $Entry.ApiKey
    $env:COPILOT_MODEL             = $Entry.Model

    Write-Host ''
    Write-Host "Applying: [$($Entry.Provider)] $($Entry.Label ?? $Entry.Model)" -ForegroundColor Cyan
    Write-Host "  COPILOT_PROVIDER_BASE_URL  = $($Entry.BaseUrl)" -ForegroundColor Green
    Write-Host "  COPILOT_MODEL              = $($Entry.Model)" -ForegroundColor Green

    if ($Entry.Provider -eq 'LiteLLM') {
        $masked = Get-MaskedKey $Entry.ApiKey
        Write-Host "  COPILOT_PROVIDER_API_KEY   = $masked" -ForegroundColor Green
    }
    if ($Entry.Provider -eq 'Ollama') {
        Write-Host "  COPILOT_PROVIDER_WIRE_API  = $env:COPILOT_PROVIDER_WIRE_API" -ForegroundColor Green
    }
    if ($env:COPILOT_PROVIDER_MAX_PROMPT_TOKENS) {
        Write-Host "  COPILOT_PROVIDER_MAX_PROMPT_TOKENS  = $env:COPILOT_PROVIDER_MAX_PROMPT_TOKENS" -ForegroundColor Green
        Write-Host "  COPILOT_PROVIDER_MAX_OUTPUT_TOKENS  = $env:COPILOT_PROVIDER_MAX_OUTPUT_TOKENS" -ForegroundColor Green
    }
}

function Get-MaskedKey {
    <#
    .SYNOPSIS
        Returns a partially masked version of an API key for display.
    .DESCRIPTION
        Shows the first 4 and last 4 characters of a key, masking the middle
        with asterisks. Returns '(none)' for null or empty keys.
    .PARAMETER Key
        The API key string to mask.
    .EXAMPLE
        Get-MaskedKey $env:LITELLM_API_KEY
    #>
    [CmdletBinding()]
    param(
        [string] $Key
    )

    if ([string]::IsNullOrWhiteSpace($Key)) { return '(none)' }
    if ($Key.Length -le 8) { return '****' }
    return ($Key.Substring(0, 4) + ('*' * ($Key.Length - 8)) + $Key.Substring($Key.Length - 4))
}

Set-Alias -Name scp  -Value Set-CopilotProvider
Set-Alias -Name rscp -Value Reset-CopilotProvider
Set-Alias -Name gcp  -Value Get-CopilotProvider
