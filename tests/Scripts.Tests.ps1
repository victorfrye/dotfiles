#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    $RepoRoot   = (Get-Item $PSScriptRoot).Parent.FullName
    $ScriptsDir = Join-Path $RepoRoot 'files\powershell\scripts'

    . (Join-Path $ScriptsDir 'ConvertTo-Sha256Hash.ps1')
    . (Join-Path $ScriptsDir 'Get-Path.ps1')
    . (Join-Path $ScriptsDir 'Set-JavaVersion.ps1')
    . (Join-Path $ScriptsDir 'Set-NodeVersion.ps1')
    . (Join-Path $ScriptsDir 'Set-CopilotProvider.ps1')
}

# ---------------------------------------------------------------------------- #
# ConvertTo-Sha256Hash
# ---------------------------------------------------------------------------- #

Describe 'ConvertTo-Sha256Hash' {
    It 'returns a 64-character lowercase hex string' {
        $result = ConvertTo-Sha256Hash 'hello'
        $result.Length | Should -Be 64
        $result | Should -Match '^[0-9a-f]+$'
    }

    It 'produces the correct SHA-256 for a known value' {
        # echo -n "hello" | sha256sum => 2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
        ConvertTo-Sha256Hash 'hello' | Should -Be '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824'
    }

    It 'produces different hashes for different inputs' {
        $a = ConvertTo-Sha256Hash 'foo'
        $b = ConvertTo-Sha256Hash 'bar'
        $a | Should -Not -Be $b
    }

    It 'is idempotent for the same input' {
        $a = ConvertTo-Sha256Hash 'stable'
        $b = ConvertTo-Sha256Hash 'stable'
        $a | Should -Be $b
    }
}

# ---------------------------------------------------------------------------- #
# Get-Path
# ---------------------------------------------------------------------------- #

Describe 'Get-Path' {
    It 'returns an array of path entries' {
        $result = Get-Path
        $result | Should -Not -BeNullOrEmpty
        $result.GetType().IsArray -or $result -is [System.Collections.IEnumerable] | Should -BeTrue
    }

    It 'does not contain semicolons in any entry' {
        Get-Path | ForEach-Object { $_ | Should -Not -Match ';' }
    }
}

# ---------------------------------------------------------------------------- #
# Set-JavaVersion / Reset-JavaVersion
# ---------------------------------------------------------------------------- #

Describe 'Set-JavaVersion' {
    BeforeEach {
        $env:JAVA_HOME    = $null
        $env:JDK_21_HOME  = $null
        $env:JDK_25_HOME  = $null
    }

    AfterEach {
        $env:JAVA_HOME    = $null
        $env:JDK_21_HOME  = $null
        $env:JDK_25_HOME  = $null
    }

    It 'sets JAVA_HOME when the versioned path exists' {
        $fakeJdk = $env:TEMP
        $env:JDK_21_HOME = $fakeJdk
        Set-JavaVersion -Version 21
        $env:JAVA_HOME | Should -Be $fakeJdk
    }

    It 'aborts without changing JAVA_HOME when version is not configured' {
        $env:JAVA_HOME = 'original'
        Set-JavaVersion -Version 99
        $env:JAVA_HOME | Should -Be 'original'
    }

    It 'aborts when the configured path does not exist on disk' {
        $env:JDK_21_HOME = 'C:\does\not\exist\jdk21'
        $env:JAVA_HOME   = 'original'
        Set-JavaVersion -Version 21
        $env:JAVA_HOME | Should -Be 'original'
    }
}

Describe 'Reset-JavaVersion' {
    BeforeEach { $env:JDK_25_HOME = $null; $env:JAVA_HOME = $null }
    AfterEach  { $env:JDK_25_HOME = $null; $env:JAVA_HOME = $null }

    It 'sets JAVA_HOME to JDK_25_HOME' {
        $env:JDK_25_HOME = $env:TEMP
        Reset-JavaVersion
        $env:JAVA_HOME | Should -Be $env:TEMP
    }
}

# ---------------------------------------------------------------------------- #
# Set-NodeVersion / Reset-NodeVersion
# ---------------------------------------------------------------------------- #

Describe 'Set-NodeVersion' {
    BeforeEach {
        $env:NODE_HOME    = $null
        $env:NODE_22_HOME = $null
    }

    AfterEach {
        $env:NODE_HOME    = $null
        $env:NODE_22_HOME = $null
    }

    It 'sets NODE_HOME when the versioned path exists' {
        $fakeNode = $env:TEMP
        $env:NODE_22_HOME = $fakeNode
        Set-NodeVersion -Version 22
        $env:NODE_HOME | Should -Be $fakeNode
    }

    It 'aborts without changing NODE_HOME when version is not configured' {
        $env:NODE_HOME = 'original'
        Set-NodeVersion -Version 99
        $env:NODE_HOME | Should -Be 'original'
    }
}

Describe 'Reset-NodeVersion' {
    BeforeEach { $env:NODE_24_HOME = $null; $env:NODE_HOME = $null }
    AfterEach  { $env:NODE_24_HOME = $null; $env:NODE_HOME = $null }

    It 'sets NODE_HOME to NODE_24_HOME' {
        $env:NODE_24_HOME = $env:TEMP
        Reset-NodeVersion
        $env:NODE_HOME | Should -Be $env:TEMP
    }

    It 'writes a warning when NODE_24_HOME is not configured' {
        $env:NODE_24_HOME = $null
        $output = Reset-NodeVersion 2>&1 | Out-String
        $output | Should -Match 'NODE_24_HOME'
    }
}

# ---------------------------------------------------------------------------- #
# Reset-CopilotProvider
# ---------------------------------------------------------------------------- #

Describe 'Reset-CopilotProvider' {
    BeforeEach {
        $env:COPILOT_PROVIDER_BASE_URL = 'https://example.com'
        $env:COPILOT_PROVIDER_API_KEY  = 'key'
        $env:COPILOT_MODEL             = 'some-model'
    }

    AfterEach {
        $env:COPILOT_PROVIDER_BASE_URL = $null
        $env:COPILOT_PROVIDER_API_KEY  = $null
        $env:COPILOT_MODEL             = $null
    }

    It 'clears COPILOT_PROVIDER_BASE_URL' {
        Reset-CopilotProvider
        $env:COPILOT_PROVIDER_BASE_URL | Should -BeNullOrEmpty
    }

    It 'clears COPILOT_PROVIDER_API_KEY' {
        Reset-CopilotProvider
        $env:COPILOT_PROVIDER_API_KEY | Should -BeNullOrEmpty
    }

    It 'clears COPILOT_MODEL' {
        Reset-CopilotProvider
        $env:COPILOT_MODEL | Should -BeNullOrEmpty
    }
}

# ---------------------------------------------------------------------------- #
# Get-MaskedKey
# ---------------------------------------------------------------------------- #

Describe 'Get-MaskedKey' {
    It 'returns (none) for a null key' {
        Get-MaskedKey $null | Should -Be '(none)'
    }

    It 'returns (none) for an empty string' {
        Get-MaskedKey '' | Should -Be '(none)'
    }

    It 'returns **** for a short key (<= 8 chars)' {
        Get-MaskedKey 'short' | Should -Be '****'
    }

    It 'masks the middle of a long key' {
        $result = Get-MaskedKey 'abcd1234efgh'
        $result | Should -BeLike 'abcd****efgh'
    }

    It 'preserves the first 4 and last 4 characters' {
        $key    = 'sk-abcdefghijklmnop'
        $result = Get-MaskedKey $key
        $result | Should -Match '^sk-a'
        $result | Should -Match 'mnop$'
    }
}

# ---------------------------------------------------------------------------- #
# Build-ProviderEntries
# ---------------------------------------------------------------------------- #

Describe 'Build-ProviderEntries' {
    BeforeEach {
        $env:LITELLM_BASE_URL = $null
        $env:LITELLM_API_KEY  = $null
    }

    AfterEach {
        $env:LITELLM_BASE_URL = $null
        $env:LITELLM_API_KEY  = $null
    }

    It 'always includes a GitHub entry as the first item' {
        $entries = Build-ProviderEntries
        $entries[0].Provider | Should -Be 'GitHub'
        $entries[0].Model    | Should -BeNullOrEmpty
    }

    It 'includes LiteLLM entries when LITELLM_BASE_URL is set' {
        $env:LITELLM_BASE_URL = 'https://litellm.example.com'
        $entries = Build-ProviderEntries
        $litellm = $entries | Where-Object { $_.Provider -eq 'LiteLLM' }
        $litellm | Should -Not -BeNullOrEmpty
    }

    It 'does not include LiteLLM entries when LITELLM_BASE_URL is not set' {
        $entries = Build-ProviderEntries
        $litellm = $entries | Where-Object { $_.Provider -eq 'LiteLLM' }
        $litellm | Should -BeNullOrEmpty
    }

    It 'has the correct count of LiteLLM entries when configured' {
        $env:LITELLM_BASE_URL = 'https://litellm.example.com'
        $entries = Build-ProviderEntries
        $litellm = @($entries | Where-Object { $_.Provider -eq 'LiteLLM' })
        $litellm.Count | Should -Be $script:LiteLLMModels.Count
    }
}

# ---------------------------------------------------------------------------- #
# Get-CopilotProvider
# ---------------------------------------------------------------------------- #

Describe 'Get-CopilotProvider' {
    BeforeEach {
        $env:COPILOT_PROVIDER_BASE_URL = $null
        $env:COPILOT_PROVIDER_API_KEY  = $null
        $env:COPILOT_MODEL             = $null
    }

    AfterEach {
        $env:COPILOT_PROVIDER_BASE_URL = $null
        $env:COPILOT_PROVIDER_API_KEY  = $null
        $env:COPILOT_MODEL             = $null
    }

    It 'runs without error when no BYOK vars are set' {
        { Get-CopilotProvider } | Should -Not -Throw
    }

    It 'runs without error when BYOK vars are set' {
        $env:COPILOT_PROVIDER_BASE_URL = 'https://litellm.example.com'
        $env:COPILOT_PROVIDER_API_KEY  = 'sk-testkey12345678'
        $env:COPILOT_MODEL             = 'claude-sonnet-4.6'
        { Get-CopilotProvider } | Should -Not -Throw
    }

    It 'reports GitHub provider when no vars are set' {
        $output = Get-CopilotProvider *>&1 | Out-String
        $output | Should -Match 'GitHub'
    }

    It 'reports LiteLLM provider when BYOK URL matches LITELLM_BASE_URL' {
        $env:LITELLM_BASE_URL          = 'https://litellm.example.com'
        $env:COPILOT_PROVIDER_BASE_URL = 'https://litellm.example.com'
        $env:COPILOT_MODEL             = 'claude-sonnet-4.6'
        $output = Get-CopilotProvider *>&1 | Out-String
        $output | Should -Match 'LiteLLM'
    }
}

# ---------------------------------------------------------------------------- #
# Get-OllamaModels
# ---------------------------------------------------------------------------- #

Describe 'Get-OllamaModels' {
    It 'returns an array (possibly empty) without throwing' {
        { Get-OllamaModels } | Should -Not -Throw
    }

    It 'returns an empty array when ollama is not installed' {
        Mock Get-Command { $null } -ParameterFilter { $Name -eq 'ollama' } -ModuleName ''
        $result = Get-OllamaModels
        $result.Count | Should -Be 0
    }
}

# ---------------------------------------------------------------------------- #
# Build-ProviderEntries (Ollama)
# ---------------------------------------------------------------------------- #

Describe 'Build-ProviderEntries Ollama' {
    It 'includes Ollama entries when ollama returns models' {
        Mock Get-OllamaModels { return @('llama3.2:latest', 'mistral:latest') }
        $entries = Build-ProviderEntries
        $ollama  = $entries | Where-Object { $_.Provider -eq 'Ollama' }
        $ollama | Should -Not -BeNullOrEmpty
    }

    It 'sets BaseUrl to localhost:11434 for Ollama entries' {
        Mock Get-OllamaModels { return @('llama3.2:latest') }
        $entries = Build-ProviderEntries
        $entry   = $entries | Where-Object { $_.Provider -eq 'Ollama' } | Select-Object -First 1
        $entry.BaseUrl | Should -Be 'http://localhost:11434/v1'
    }

    It 'does not include Ollama entries when no models are available' {
        Mock Get-OllamaModels { return @() }
        $entries = Build-ProviderEntries
        $ollama  = $entries | Where-Object { $_.Provider -eq 'Ollama' }
        $ollama | Should -BeNullOrEmpty
    }
}
