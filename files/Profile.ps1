# Oh My Posh
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\paradox.omp.json" | Invoke-Expression

#Functions
## Git - These functions allow for management of Git Repositories
function Initialize-AllRepositories() {
  $RepositoryDirectories = Get-AllRepositories

  foreach ($r in $RepositoryDirectories) {
    git init $r.FullName
  }
}

function Get-AllRepositories() {
  return (Get-ChildItem $env:SOURCE_ROOT -Attributes Directory+Hidden -ErrorAction SilentlyContinue -Filter ".\.git" -Recurse).Parent
}

function Clear-RepositoryBranches() {
  $branches = git branch --list | Select-String -Pattern '^\*' -NotMatch | Select-String -Pattern 'main' -NotMatch

  foreach ($b in $Branches) {
    $Branch = $b.Line.Trim()
    git branch -D $Branch
  }
}

## Java - These functions allow for JDK version management
function Set-JavaVersion([int] $Version) {

  if (-NOT($Version)) {
    $env:JAVA_HOME = $env:JDK_17
    Write-Output "The JAVA_HOME environment variable is now set to $env:JAVA_HOME."
    return
  }

  switch ($Version) {
    17 {
      $env:JAVA_HOME = $env:JDK_17
      Write-Output "The JAVA_HOME environment variable is now set to $env:JAVA_HOME."
      break
    }
    16 {
      $env:JAVA_HOME = $env:JDK_16
      Write-Output "The JAVA_HOME environment variable is now set to $env:JAVA_HOME."
      break
    }
    11 {
      $env:JAVA_HOME = $env:JDK_11
      Write-Output "The JAVA_HOME environment variable is now set to $env:JAVA_HOME."
      break
    }
    Default { Write-Output "No JDK configured for version $PSItem... Aborted." }
  }
}

## Miscellaneous
function Get-Path() {
  Write-Output $Env:PATH.Split(';');
}

# Aliases
Set-Alias -Name code -Value code-insiders

# # Environment Variables
# ## Git
# $env:DEVDRIVE = 'D:'
# $env:SOURCE_ROOT = ''
# $env:GITHUB_TOKEN = ''

# ## .NET
# $env:DOTNET_ROOT = ''
# $env:DOTNET_TOOLS = ''

# ## Java
# $env:JDK_17 = ''
# $env:JDK_16 = ''
# $env:JDK_11 = ''
# $env:JAVA_HOME = $env:JDK_17
