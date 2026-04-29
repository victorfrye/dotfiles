# MARK: Solution Context Management

function Initialize-SolutionContext([string] $TenantId, [string] $SubscriptionId, [string] $ClientId, [string] $Location) {
  $env:ARM_TENANT_ID = $TenantId
  $env:ARM_SUBSCRIPTION_ID = $SubscriptionId
  $env:ARM_CLIENT_ID = $ClientId

  if ($Location -and (Test-Path $Location)) {
    Set-Location $Location
  }

  Write-Output "Solution context initialized (Tenant: $TenantId, Subscription: $SubscriptionId)."
}

function Clear-SolutionContext {
  Remove-Item env:AZURE_TENANT_ID -ErrorAction SilentlyContinue
  Remove-Item env:AZURE_SUBSCRIPTION_ID -ErrorAction SilentlyContinue
  Remove-Item env:AZURE_CLIENT_ID -ErrorAction SilentlyContinue
  Remove-Item env:ARM_TENANT_ID -ErrorAction SilentlyContinue
  Remove-Item env:ARM_SUBSCRIPTION_ID -ErrorAction SilentlyContinue
  Remove-Item env:ARM_CLIENT_ID -ErrorAction SilentlyContinue

  Write-Output 'Solution context cleared.'
}

Set-Alias -Name clctx -Value Clear-SolutionContext

## Solution context shortcuts — define in env.ps1, e.g.:
##   function Initialize-MyAppContext { Initialize-SolutionContext $MY_TENANT $MY_SUB $MY_CLIENT $env:SRC_MYAPP }
##   Set-Alias -Name inmyapp -Value Initialize-MyAppContext
