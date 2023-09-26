function Install-PowerUserTools() {
    winget install --id Microsoft.WindowsTerminal --source winget

    winget install --id Microsoft.DevHome --source winget

    winget install --id GitHub.cli --source winget

    winget install --id JanDeDobbeleer.OhMyPosh --source winget

    winget install --id Microsoft.PowerToys --source winget

    winget install --id Neovim.Neovim --source winget
}

function Install-DotNetTools() {
    winget install --id Microsoft.DotNet.SDK.7

    winget install --id Microsoft.VisualStudioCode --source winget

    winget install --id Microsoft.VisualStudio.2022.Community --source winget

    winget install --id Microsoft.NuGet --source winget

}

function Install-JavaTools() {
    winget install --id Microsoft.OpenJDK.17 --source winget

    winget install --id Microsoft.OpenJDK.16 --source winget
    
    winget install --id Microsoft.OpenJDK.11 --source winget

    winget install --id JetBrains.IntelliJIDEA.Community --source winget
}

function Install-WebTools() {
    winget install --id OpenJS.NodeJS --source winget

    winget install --id Postman.Postman --source winget
}

function Install-MiscellaneousTools() {
    winget install --id Docker.DockerDesktop --source winget

    winget install --id Python.Python.3.11 --source winget
}

function Install-CommunicationTools() {
    winget install --id SlackTechnologies.Slack --source winget

    winget install --id Discord.Discord --source winget

    winget install --id Zoom.Zoom --source winget
}

# TODO: Install preview tools based on a switch from initialize script
function Install-PreviewTools() {
    winget install --id Microsoft.PowerShell.Preview --source winget
    winget install --id Microsoft.WindowsTerminal.Preview --source winget
    winget install --id Microsoft.VisualStudioCode.Insiders --source winget
    winget install --id Microsoft.VisualStudio.2022.Community.Preview --source winget
}

Write-Host "Installing local development tools..."

Install-PowerUserTools
Install-DotNetTools
Install-JavaTools
Install-WebTools
Install-MiscellaneousTools
Install-CommunicationTools
Install-PreviewTools

Write-Host "Complete!! Development tools installed successfully."
