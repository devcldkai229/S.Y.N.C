# Kill processes on service ports, build, then launch all APIs (Development).
# Usage:
#   .\scripts\run-all.ps1
#   .\scripts\run-all.ps1 -SkipBuild

param(
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$SyncRoot = Split-Path -Parent $PSScriptRoot

$services = @(
    @{ Name = "IAM";          Dir = "src\Services\Iam\Iam.API";                     Port = 5288 },
    @{ Name = "Payment";      Dir = "src\Services\Payment\Payment.API";             Port = 5084 },
    @{ Name = "Roadmap";      Dir = "src\Services\Roadmap\Roadmap.API";             Port = 5118 },
    @{ Name = "Exercise";     Dir = "src\Services\Exercise\Exercise.API";           Port = 5187 },
    @{ Name = "Notification"; Dir = "src\Services\Notification\Notification.API"; Port = 5106 },
    @{ Name = "Social";       Dir = "src\Services\Social\Social.API";               Port = 5120 },
    @{ Name = "Nutrition";    Dir = "src\Services\Nutrition\Nutrition.API";         Port = 5122 },
    @{ Name = "Marketplace";  Dir = "src\Services\Marketplace\Marketplace.API";     Port = 5119 },
    @{ Name = "Order";        Dir = "src\Services\Order\Order.API";                 Port = 5123 },
    @{ Name = "Gateway";      Dir = "src\Gateway";                                  Port = 5057 }
)

function Get-LaunchShell {
    if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        return (Get-Command pwsh).Source
    }
    return "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
}

function New-ServiceStartCommand {
    param(
        [string]$Name,
        [string]$ProjectDir,
        [int]$Port,
        [bool]$UseNoBuild
    )

    $noBuildArg = if ($UseNoBuild) { " --no-build" } else { "" }
    $gatewayUrls = if ($Name -eq "Gateway") {
        "`$env:ASPNETCORE_URLS = 'http://0.0.0.0:$Port';"
    } else { "" }

    @"
`$Host.UI.RawUI.WindowTitle = 'Sync - $Name (:$Port)'
Set-Location '$ProjectDir'
`$env:ASPNETCORE_ENVIRONMENT = 'Development'
$gatewayUrls
Write-Host '>>> $Name API - http://localhost:$Port' -ForegroundColor Green
if ('$Name' -eq 'Gateway') {
    Write-Host '    Entry point (YARP) - LAN: http://<your-pc-ip>:$Port/health' -ForegroundColor DarkGray
} else {
    Write-Host '    Swagger: http://localhost:$Port/swagger' -ForegroundColor DarkGray
    Write-Host '    Health:  http://localhost:$Port/health' -ForegroundColor DarkGray
}
dotnet run --launch-profile http$noBuildArg
if (`$LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host 'Service failed to start. Re-run: .\scripts\run-all.ps1' -ForegroundColor Red
}
"@
}

$launchShell = Get-LaunchShell

Write-Host "Stopping ports (release file locks before build)..." -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "stop-all.ps1")
Start-Sleep -Seconds 2

if (-not $SkipBuild) {
    Write-Host "Building..." -ForegroundColor Cyan
    foreach ($svc in $services) {
        $projectDir = Join-Path $SyncRoot $svc.Dir
        $csproj = Get-ChildItem $projectDir -Filter "*.csproj" -ErrorAction Stop |
            Select-Object -First 1 -ExpandProperty FullName
        Write-Host "  $($svc.Name)" -ForegroundColor DarkGray
        dotnet build $csproj -v minimal --nologo
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Build failed for $($svc.Name). Fix errors above, then re-run run-all.ps1." -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host "Starting services..." -ForegroundColor Cyan
$useNoBuild = -not $SkipBuild
foreach ($svc in $services) {
    $projectDir = (Resolve-Path (Join-Path $SyncRoot $svc.Dir)).Path
    $command = New-ServiceStartCommand -Name $svc.Name -ProjectDir $projectDir -Port $svc.Port -UseNoBuild:$useNoBuild
    Start-Process -FilePath $launchShell -ArgumentList @("-NoExit", "-Command", $command)
    Start-Sleep -Milliseconds 500
}

Write-Host "Done. Gateway: http://localhost:5057" -ForegroundColor Green
Write-Host "Stop: .\scripts\stop-all.ps1" -ForegroundColor DarkGray
