# Run all Sync Platform APIs in separate terminal windows (Development).
# Stops any existing processes on service ports before launching.
# Usage:
#   .\scripts\run-all.ps1
#   .\scripts\run-all.ps1 -SkipBuild
#   .\scripts\run-all.ps1 -Infra

param(
    [switch]$SkipBuild,
    [switch]$Infra
)

$ErrorActionPreference = "Stop"
$SyncRoot = Split-Path -Parent $PSScriptRoot
$RepoRoot = Resolve-Path (Join-Path $SyncRoot "..\..")
$StartServiceScript = Join-Path $PSScriptRoot "start-service.ps1"
$EnsureScript = Join-Path $PSScriptRoot "ensure-prerequisites.ps1"

& $EnsureScript -SyncRoot $SyncRoot -RequireDocker:(-not $Infra)
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

function Get-LaunchShell {
    if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        return (Get-Command pwsh).Source
    }
    return "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
}

$launchShell = Get-LaunchShell

$services = @(
    @{ Name = "IAM";          Dir = "src\Services\Iam\Iam.API";                     Port = 5288 },
    @{ Name = "Payment";      Dir = "src\Services\Payment\Payment.API";             Port = 5084 },
    @{ Name = "Roadmap";      Dir = "src\Services\Roadmap\Roadmap.API";             Port = 5118 },
    @{ Name = "Exercise";     Dir = "src\Services\Exercise\Exercise.API";           Port = 5187 },
    @{ Name = "Notification"; Dir = "src\Services\Notification\Notification.API"; Port = 5106 },
    @{ Name = "Social";       Dir = "src\Services\Social\Social.API";             Port = 5120 },
    @{ Name = "Gateway";      Dir = "src\Gateway";                                  Port = 5057 }
)

if ($Infra) {
    Write-Host "Starting Docker infra (Postgres, MongoDB, ...)..." -ForegroundColor Cyan
    Push-Location (Join-Path $RepoRoot "infra\docker")
    docker compose up -d
    if ($LASTEXITCODE -ne 0) { Pop-Location; throw "docker compose failed" }
    Pop-Location
    Write-Host "Waiting 5s for databases..." -ForegroundColor DarkGray
    Start-Sleep -Seconds 5
}

if (-not $SkipBuild) {
    Write-Host "Building all API projects..." -ForegroundColor Cyan
    foreach ($svc in $services) {
        $projectDir = Join-Path $SyncRoot $svc.Dir
        $csproj = Get-ChildItem $projectDir -Filter "*.csproj" -ErrorAction Stop |
            Select-Object -First 1 -ExpandProperty FullName
        Write-Host "  $($svc.Name)..." -ForegroundColor DarkGray
        dotnet build $csproj -v minimal --nologo
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Build failed: $($svc.Name). Fix errors above before re-running run-all.ps1." -ForegroundColor Red
            exit 1
        }
    }
    Write-Host "Build OK." -ForegroundColor Green
}

Write-Host ""
Write-Host "Stopping existing processes on service ports..." -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "stop-all.ps1")
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "Shell: $launchShell" -ForegroundColor DarkGray
Write-Host "Starting services (each in a new window)..." -ForegroundColor Cyan
Write-Host ""

foreach ($svc in $services) {
    $projectDir = (Resolve-Path (Join-Path $SyncRoot $svc.Dir)).Path

    # Single quoted argument string — required when paths contain spaces (e.g. "Semester 8").
    # Start-Process -ArgumentList @(..., $projectDir) splits "D:\Semester 8\..." at the space.
    $argString = @(
        "-NoExit",
        "-ExecutionPolicy Bypass",
        "-File `"$StartServiceScript`"",
        "-Name $($svc.Name)",
        "-ProjectDir `"$projectDir`"",
        "-Port $($svc.Port)"
    ) -join " "

    Start-Process -FilePath $launchShell -ArgumentList $argString -ErrorAction Stop
    Start-Sleep -Milliseconds 500
}

Write-Host "All processes launched." -ForegroundColor Green
Write-Host "Waiting for APIs to start (cold start + Exercise Mongo seed may take 30-60s)..." -ForegroundColor DarkGray

$waitPortsScript = Join-Path $PSScriptRoot "wait-for-ports.ps1"
$healthScript = Join-Path $PSScriptRoot "health-check-all.ps1"

& $waitPortsScript -TimeoutSec 90 -PollIntervalSec 3
$portsReady = $LASTEXITCODE -eq 0

$allHealthy = $false
if ($portsReady) {
    $maxAttempts = 5
    for ($i = 1; $i -le $maxAttempts; $i++) {
        Start-Sleep -Seconds 5
        & $healthScript -TimeoutSec 10
        if ($LASTEXITCODE -eq 0) {
            $allHealthy = $true
            break
        }
        if ($i -lt $maxAttempts) {
            Write-Host "Retry HTTP health check ($i/$maxAttempts)..." -ForegroundColor DarkYellow
        }
    }
}

if (-not $portsReady -or -not $allHealthy) {
    Write-Host ""
    Write-Host "Some services did not respond. Check each PowerShell window for errors." -ForegroundColor Red
    Write-Host "Common fixes:" -ForegroundColor Yellow
    Write-Host "  1. Docker infra:  .\scripts\run-all.ps1 -Infra   (Postgres :5434, Mongo :27017)" -ForegroundColor Yellow
    Write-Host "  2. Config:        .\scripts\setup-appsettings.ps1  then fill Development.json" -ForegroundColor Yellow
    Write-Host "  3. Jwt secret:    configs\appsettings.Shared.Development.json" -ForegroundColor Yellow
    Write-Host "  4. See:           CONFIGURATION.md" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Gateway (entry point): http://localhost:5057" -ForegroundColor Yellow
Write-Host "IAM Swagger:           http://localhost:5288/swagger" -ForegroundColor Yellow
Write-Host "Payment Swagger:       http://localhost:5084/swagger" -ForegroundColor Yellow
Write-Host "Roadmap Swagger:       http://localhost:5118/swagger" -ForegroundColor Yellow
Write-Host "Exercise Swagger:      http://localhost:5187/swagger" -ForegroundColor Yellow
Write-Host ""
Write-Host "Stop: close each window or run .\scripts\stop-all.ps1" -ForegroundColor DarkGray
