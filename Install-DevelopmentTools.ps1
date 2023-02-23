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

function Install-Java() {
    winget install --id=EclipseAdoptium.Temurin.17.JDK --source=winget
    [Environment]::SetEnvironmentVariable('JDK_17', $env:JAVA_HOME, 'Machine')
}

function Install-VisualStudioCode() {
    winget install --id=Microsoft.VisualStudioCode --source=winget
}

function Install-NuGet() {
    winget install --id=Microsoft.NuGet --source=winget
}


function Install-DockerDesktop() {
    winget install --id=Docker.DockerDesktop --source=winget
}

function Install-Postman() {
    winget install --id=Postman.Postman --source=winget
}

Write-Host "Installing local development tools..."
Install-WindowsTerminal
Install-OhMyPosh
Install-PowerToys
Install-DotNet
Install-Java
Install-VisualStudioCode
Install-NuGet
Install-DockerDesktop
Install-Postman

Write-Host "Complete!! Development tools installed successfully."