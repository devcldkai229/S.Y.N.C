# Shared preflight for run-all.ps1 / CI local dev.
param(
    [switch]$RequireDocker,
    [string]$SyncRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

function Test-DotNet10Sdk {
    $sdks = dotnet --list-sdks 2>$null
    return ($sdks -match "^\s*10\.")
}

function Test-DockerRunning {
    try {
        docker info 2>$null | Out-Null
        return $LASTEXITCODE -eq 0
    }
    catch { return $false }
}

function Test-PostgresPort {
    param([int]$Port = 5434)
    return [bool](Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
}

function Test-MongoPort {
    param([int]$Port = 27017)
    return [bool](Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
}

if (-not (Test-DotNet10Sdk)) {
    Write-Host ".NET 10 SDK is required (project targets net10.0)." -ForegroundColor Red
    Write-Host "Install: winget install Microsoft.DotNet.SDK.10" -ForegroundColor Yellow
    Write-Host "Or:      https://dotnet.microsoft.com/download/dotnet/10.0" -ForegroundColor Yellow
    Write-Host "Then open a new terminal and run this script again." -ForegroundColor DarkGray
    exit 1
}

$sharedDevPath = Join-Path $SyncRoot "configs\appsettings.Shared.Development.json"
if (-not (Test-Path $sharedDevPath)) {
    Write-Host "Missing configs\appsettings.Shared.Development.json" -ForegroundColor Red
    Write-Host "Run: .\scripts\setup-appsettings.ps1" -ForegroundColor Yellow
    exit 1
}

try {
    $secretKey = (Get-Content -Raw $sharedDevPath | ConvertFrom-Json).Jwt.SecretKey
}
catch {
    $secretKey = $null
}

if ([string]::IsNullOrWhiteSpace($secretKey) -or $secretKey.Length -lt 32) {
    Write-Host "Jwt:SecretKey missing or too short in configs\appsettings.Shared.Development.json" -ForegroundColor Red
    exit 1
}

if ($RequireDocker) {
    if (-not (Test-DockerRunning)) {
        Write-Host "Docker is not running. Start Docker Desktop first." -ForegroundColor Red
        exit 1
    }
    if (-not (Test-PostgresPort)) {
        Write-Host "Postgres not listening on :5434. Run: .\scripts\run-all.ps1 -Infra" -ForegroundColor Red
        exit 1
    }
    if (-not (Test-MongoPort)) {
        Write-Host "MongoDB not listening on :27017. Run: .\scripts\run-all.ps1 -Infra" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Prerequisites OK (.NET 10 SDK, appsettings, JWT)." -ForegroundColor Green
