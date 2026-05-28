# Kill processes on service ports, then launch all APIs (Development).
# Usage:
#   .\scripts\run-all.ps1
#   .\scripts\run-all.ps1 -SkipBuild

param(
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$SyncRoot = Split-Path -Parent $PSScriptRoot
$StartServiceScript = Join-Path $PSScriptRoot "start-service.ps1"

$services = @(
    @{ Name = "IAM";          Dir = "src\Services\Iam\Iam.API";                     Port = 5288 },
    @{ Name = "Payment";      Dir = "src\Services\Payment\Payment.API";             Port = 5084 },
    @{ Name = "Roadmap";      Dir = "src\Services\Roadmap\Roadmap.API";             Port = 5118 },
    @{ Name = "Exercise";     Dir = "src\Services\Exercise\Exercise.API";           Port = 5187 },
    @{ Name = "Notification"; Dir = "src\Services\Notification\Notification.API"; Port = 5106 },
    @{ Name = "Social";       Dir = "src\Services\Social\Social.API";               Port = 5120 },
    @{ Name = "Gateway";      Dir = "src\Gateway";                                  Port = 5057 }
)

function Get-LaunchShell {
    if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        return (Get-Command pwsh).Source
    }
    return "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
}

$launchShell = Get-LaunchShell

if (-not $SkipBuild) {
    Write-Host "Building..." -ForegroundColor Cyan
    foreach ($svc in $services) {
        $projectDir = Join-Path $SyncRoot $svc.Dir
        $csproj = Get-ChildItem $projectDir -Filter "*.csproj" -ErrorAction Stop |
            Select-Object -First 1 -ExpandProperty FullName
        dotnet build $csproj -v minimal --nologo
        if ($LASTEXITCODE -ne 0) { exit 1 }
    }
}

Write-Host "Stopping ports..." -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "stop-all.ps1")
Start-Sleep -Seconds 2

Write-Host "Starting services..." -ForegroundColor Cyan
foreach ($svc in $services) {
    $projectDir = (Resolve-Path (Join-Path $SyncRoot $svc.Dir)).Path
    $argString = @(
        "-NoExit",
        "-ExecutionPolicy Bypass",
        "-File `"$StartServiceScript`"",
        "-Name $($svc.Name)",
        "-ProjectDir `"$projectDir`"",
        "-Port $($svc.Port)"
    ) -join " "

    Start-Process -FilePath $launchShell -ArgumentList $argString
    Start-Sleep -Milliseconds 500
}

Write-Host "Done. Gateway: http://localhost:5057" -ForegroundColor Green
Write-Host "Stop: .\scripts\stop-all.ps1" -ForegroundColor DarkGray
