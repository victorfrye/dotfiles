function Install-PowerUserTools() {
    winget install --exact --id GitHub.cli --source winget
    winget install --exact --id JanDeDobbeleer.OhMyPosh --source winget
    winget install --exact --id Microsoft.DevHome --source winget
    winget install --exact --id Microsoft.PowerToys --source winget
    winget install --exact --id Microsoft.WindowsTerminal --source winget
    winget install --exact --id Neovim.Neovim --source winget
}

function Install-DotNetTools() {
    winget install --exact --id Microsoft.DotNet.SDK.7 --source winget
    winget install --exact --id Microsoft.NuGet --source winget
    winget install --exact --id Microsoft.VisualStudio.2022.Community --source winget
    winget install --exact --id Microsoft.VisualStudioCode --source winget
}

function Install-JavaTools() {
    winget install --exact --id Microsoft.OpenJDK.11 --source winget
    winget install --exact --id Microsoft.OpenJDK.17 --source winget
    winget install --exact --id Microsoft.OpenJDK.21 --source winget
}

function Install-MiscellaneousTools() {
    winget install --exact --id Docker.DockerDesktop --source winget
    winget install --exact --id Hashicorp.Terraform --source winget
    winget install --exact --id OpenJS.NodeJS --source winget
    winget install --exact --id Postman.Postman --source winget
    winget install --exact --id Python.Python.3.11 --source winget
}

function Install-CommunicationTools() {
    winget install --exact --id Discord.Discord --source winget
    winget install --exact --id SlackTechnologies.Slack --source winget
    winget install --exact --id Zoom.Zoom --source winget
}

# TODO: Install preview tools based on a switch from initialize script
function Install-PreviewTools() {
    winget install --exact --id Microsoft.PowerShell.Preview --source winget
    winget install --exact --id Microsoft.VisualStudioCode.Insiders --source winget
    winget install --exact --id Microsoft.VisualStudio.2022.Community.Preview --source winget
    winget install --exact --id Microsoft.WindowsTerminal.Preview --source winget
}

Write-Host "Installing local development tools..."

Install-PowerUserTools
Install-DotNetTools
Install-JavaTools
Install-MiscellaneousTools
Install-CommunicationTools
Install-PreviewTools

Write-Host "Complete!! Development tools installed successfully."
