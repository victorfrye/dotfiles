function Install-WindowsTerminal() {
    winget install --id=Microsoft.WindowsTerminal --source=winget
}

function Install-OhMyPosh() {
    winget install --id=XP8K0HKJFRXGCK --source=msstore
}

function Install-PowerToys() {
    winget install --id=Microsoft.PowerToys --source=winget
}

function Install-DotNet() {
    winget install --id=Microsoft.DotNet.SDK.7
}

function Install-VisualStudioCode() {
    winget install --id=Microsoft.VisualStudioCode --source=winget
}

function Install-VisualStudioCommunity() {
    winget install --id=Microsoft.VisualStudio.2022.Community --source=winget
}

function Install-NuGet() {
    winget install --id=Microsoft.NuGet --source=winget
}

function Install-Java() {
    winget install --id=EclipseAdoptium.Temurin.17.JDK --source=winget
    [Environment]::SetEnvironmentVariable('JDK_17', $env:JAVA_HOME, 'Machine')
}

function Install-IntelliJ() {
    winget install --id=JetBrains.IntelliJIDEA.Community --source=winget
}

function Install-NodeJS() {
    winget install --id=OpenJS.NodeJS --source=winget
}

function Install-DockerDesktop() {
    winget install --id=Docker.DockerDesktop --source=winget
}

function Install-Postman() {
    winget install --id=Postman.Postman --source=winget
}

function Install-GitHubDesktop() {
    winget install --id=GitHub.GitHubDesktop --source=winget
}

function Install-Slack() {
    winget install --id=SlackTechnologies.Slack --source=winget
}

function Install-Discord() {
    winget install --id=Discord.Discord --source=winget
}

Write-Host "Installing local development tools..."
Install-WindowsTerminal
Install-OhMyPosh
Install-PowerToys
Install-DotNet
Install-Java
Install-VisualStudioCode
Install-VisualStudioCommunity
Install-NuGet
Install-NodeJS
Install-DockerDesktop
Install-Postman
Install-GitHubDesktop
Install-Slack
Install-Discord

Write-Host "Complete!! Development tools installed successfully."