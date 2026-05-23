# Run all Sync Platform APIs in separate terminal windows (Development).
# Stops any existing processes on service ports before launching.
# Usage:
#   .\scripts\run-all.ps1
#   .\scripts\run-all.ps1 -Build
#   .\scripts\run-all.ps1 -Infra

param(
    [switch]$Build,
    [switch]$Infra
)

$ErrorActionPreference = "Stop"
$SyncRoot = Split-Path -Parent $PSScriptRoot
$RepoRoot = Resolve-Path (Join-Path $SyncRoot "..\..")
$StartServiceScript = Join-Path $PSScriptRoot "start-service.ps1"

function Get-ConfigSecretKey {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    try {
        return (Get-Content -Raw $Path | ConvertFrom-Json).Jwt.SecretKey
    }
    catch { return $null }
}

$secretKey = Get-ConfigSecretKey (Join-Path $SyncRoot "configs\appsettings.Shared.Development.local.json")
if ([string]::IsNullOrWhiteSpace($secretKey)) {
    $secretKey = Get-ConfigSecretKey (Join-Path $SyncRoot "configs\appsettings.Shared.Development.json")
}
if ([string]::IsNullOrWhiteSpace($secretKey) -or $secretKey.Length -lt 32) {
    Write-Host "Jwt:SecretKey not set (min 32 chars)." -ForegroundColor Red
    Write-Host "Use configs\appsettings.Shared.Development.local.json (gitignored) or fill Development.json locally." -ForegroundColor Yellow
    Write-Host "See CONFIGURATION.md" -ForegroundColor Yellow
    exit 1
}

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

if ($Build) {
    Write-Host "Building all API projects..." -ForegroundColor Cyan
    foreach ($svc in $services) {
        $projectDir = Join-Path $SyncRoot $svc.Dir
        $csproj = Get-ChildItem $projectDir -Filter "*.csproj" -ErrorAction Stop |
            Select-Object -First 1 -ExpandProperty FullName
        dotnet build $csproj -v q --nologo
        if ($LASTEXITCODE -ne 0) { throw "Build failed: $($svc.Name)" }
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

    $args = @(
        "-NoExit",
        "-ExecutionPolicy", "Bypass",
        "-File", $StartServiceScript,
        "-Name", $svc.Name,
        "-ProjectDir", $projectDir,
        "-Port", $svc.Port
    )

    Start-Process -FilePath $launchShell -ArgumentList $args -ErrorAction Stop
    Start-Sleep -Milliseconds 500
}

Write-Host "All processes launched." -ForegroundColor Green
Write-Host ""
Write-Host "Gateway (entry point): http://localhost:5057" -ForegroundColor Yellow
Write-Host "IAM Swagger:           http://localhost:5288/swagger" -ForegroundColor Yellow
Write-Host "Payment Swagger:       http://localhost:5084/swagger" -ForegroundColor Yellow
Write-Host "Roadmap Swagger:       http://localhost:5118/swagger" -ForegroundColor Yellow
Write-Host "Exercise Swagger:      http://localhost:5187/swagger" -ForegroundColor Yellow
Write-Host ""
Write-Host "Stop: close each window or run .\scripts\stop-all.ps1" -ForegroundColor DarkGray
