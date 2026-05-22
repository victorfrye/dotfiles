function Clear-Docker {
    docker system prune --force
    docker image prune --all --force
}

function Connect-ContainerRegistry {
    <#
    .SYNOPSIS
        Authenticates to an Azure Container Registry using the current az login session.
    .PARAMETER Registry
        The short name of the ACR registry (e.g. 'myregistry', not 'myregistry.azurecr.io').
    .EXAMPLE
        Connect-ContainerRegistry -Registry myregistry
    #>
    param(
        [Parameter(Mandatory)]
        [string] $Registry
    )

    az acr login --name $Registry
}

Set-Alias -Name ccreg -Value Connect-ContainerRegistry
