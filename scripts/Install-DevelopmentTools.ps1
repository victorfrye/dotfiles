function Install-PowerUserTools() {
    winget install --id=Microsoft.WindowsTerminal --source=winget

    winget install --id=JanDeDobbeleer.OhMyPosh --source=winget

    winget install --id=Microsoft.PowerToys --source=winget

    winget install --id=Neovim.Neovim --source=winget
}

function Install-CoreDotNetTools() {
    winget install --id=Microsoft.DotNet.SDK.7

    winget install --id=Microsoft.VisualStudioCode --source=winget

    winget install --id=Microsoft.VisualStudio.2022.Community --source=winget

    winget install --id=Microsoft.NuGet --source=winget

    winget install --id=Docker.DockerDesktop --source=winget
}

function Install-CoreJavaTools() {
    winget install --id=EclipseAdoptium.Temurin.17.JDK --source=winget
    [Environment]::SetEnvironmentVariable('JDK_17', $env:JAVA_HOME, 'Machine')

    winget install --id=Microsoft.OpenJDK.17 --source=winget

    winget install --id=Microsoft.OpenJDK.16 --source=winget
    
    winget install --id=Microsoft.OpenJDK.11 --source=winget

    winget install --id=JetBrains.IntelliJIDEA.Community --source=winget
}

function Install-CoreWebTools() {
    winget install --id=OpenJS.NodeJS --source=winget

    winget install --id=Postman.Postman --source=winget
}

function Install-CommunicationTools() {
    winget install --id=SlackTechnologies.Slack --source=winget

    winget install --id=Discord.Discord --source=winget
}

# TODO: Install preview tools based on a switch from initialize script
function Install-PreviewTools() {
    winget install --id=Microsoft.PowerShell.Preview --source=winget
    winget install --id=Microsoft.WindowsTerminal.Preview --source=winget
    winget install --id=Microsoft.VisualStudioCode.Insiders --source=winget
    winget install --id=Microsoft.VisualStudio.2022.Community.Preview --source=winget
}

Write-Host "Installing local development tools..."

Install-PowerUserTools
Install-CoreDotNetTools
Install-CoreJavaTools
Install-CoreWebTools
Install-CommunicationTools
Install-PreviewTools

Write-Host "Complete!! Development tools installed successfully."
