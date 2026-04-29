# MARK: Personal Projects — Navigation

function Set-LocationToVictorFryeRepositories { Set-Location $env:REPOS_VF }
function Set-LocationToVictorFryeDotfiles { Set-Location $env:SRC_VFDOT }
function Set-LocationToVictorFryeDotCom { Set-Location $env:SRC_VFCOM }
function Set-LocationToMicrosoftGraveyard { Set-Location $env:SRC_VFMSG }
function Set-LocationToMockingMirror { Set-Location $env:SRC_VFMIR }
function Set-LocationToShrugMan { Set-Location $env:SRC_VFSHG }

Set-Alias -Name slvf -Value Set-LocationToVictorFryeRepositories
Set-Alias -Name slcom -Value Set-LocationToVictorFryeDotCom
Set-Alias -Name slmsg -Value Set-LocationToMicrosoftGraveyard
Set-Alias -Name slmir -Value Set-LocationToMockingMirror
Set-Alias -Name slshg -Value Set-LocationToShrugMan

# MARK: Personal Projects — App Launchers

function Start-VictorFryeDotComApp { dotnet run --project "$env:SRC_VFCOM/src/AppHost/AppHost.csproj" }
function Start-MicrosoftGraveyardApp { dotnet run --project "$env:SRC_VFMSG/src/AppHost/AppHost.csproj" }
function Start-MockingMirrorApp { dotnet run --project "$env:SRC_VFMIR/src/AppHost/AppHost.csproj" }
function Start-ShrugManApp { dotnet run --project "$env:SRC_VFSHG/src/AppHost/AppHost.csproj" }

Set-Alias -Name sacom -Value Start-VictorFryeDotComApp
Set-Alias -Name samsg -Value Start-MicrosoftGraveyardApp
Set-Alias -Name samir -Value Start-MockingMirrorApp
Set-Alias -Name sashg -Value Start-ShrugManApp

## Company project navigation — configure in env.ps1:
##   function Set-LocationToCompanyRepos { Set-Location $env:REPOS_CO }
##   Set-Alias -Name slco -Value Set-LocationToCompanyRepos

## Client project navigation — configure in env.ps1:
##   function Set-LocationToClientRepos { Set-Location $env:REPOS_CL }
##   Set-Alias -Name slcl -Value Set-LocationToClientRepos
