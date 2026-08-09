#Requires -Version 5.1
<#
.SYNOPSIS
  Start full SYNC stack in Docker Compose (infra + backend + UI).

.EXAMPLE
  .\scripts\up-full.ps1
  .\scripts\up-full.ps1 -Build
  .\scripts\up-full.ps1 -InfraOnly
#>
param(
    [switch]$Build,
    [switch]$InfraOnly,
    [switch]$Optional
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

if (-not (Test-Path ".env")) {
    if (Test-Path ".env.example") {
        Copy-Item ".env.example" ".env"
        Write-Host "Created .env from .env.example — set OPENAI_API_KEY / AWS as needed." -ForegroundColor Yellow
    } else {
        throw "Missing .env — copy .env.example to .env"
    }
}

function Repair-NetworkMembership {
    $net = (docker network ls --format "{{.Name}}" | Where-Object { $_ -like "*sync-network*" } | Select-Object -First 1)
    if (-not $net) { return }
    foreach ($c in @("sync-postgres", "sync-mongodb", "sync-redis", "sync-rabbitmq")) {
        $running = docker inspect -f "{{.State.Running}}" $c 2>$null
        if ($running -ne "true") { continue }
        $hasNet = docker inspect -f "{{json .NetworkSettings.Networks}}" $c 2>$null
        if ($hasNet -and ($hasNet -notlike "*$net*")) {
            Write-Host "Reconnecting $c -> $net" -ForegroundColor Yellow
            docker network connect $net $c 2>$null | Out-Null
        }
    }
}

$profiles = @()
if (-not $InfraOnly) {
    $profiles += "app", "ui"
}
if ($Optional) {
    $profiles += "optional"
}

$composeArgs = @("compose")
foreach ($p in $profiles) { $composeArgs += "--profile", $p }
$composeArgs += "up", "-d"
if ($Build) { $composeArgs += "--build" }

Write-Host "> docker $($composeArgs -join ' ')" -ForegroundColor Cyan
& docker @composeArgs
if ($LASTEXITCODE -ne 0) {
    Repair-NetworkMembership
    Write-Host "Retrying after network repair..." -ForegroundColor Yellow
    & docker @composeArgs
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
    Repair-NetworkMembership
}

if ($InfraOnly) {
    Write-Host "`nInfra ready. Host ports: Postgres 5434, Mongo 27018, Redis 6379, RabbitMQ 5672/15672" -ForegroundColor Green
    exit 0
}

Write-Host @"

Stack up. Wait ~1-2 min for .NET migrations on first boot.

  Gateway API:  http://localhost:5057/health
  Admin web:    http://localhost:3000
  Flutter web:  http://localhost:3002
  AI:           http://localhost:8088/healthz
  RCM:          http://localhost:5300/health
  RabbitMQ UI:  http://localhost:15672

Demo password: .env IAM_DEMO_USER_PASSWORD (default SyncDemo123!)
Secrets:       infra/docker/.env  (set OPENAI_API_KEY for chat/RCM)
"@ -ForegroundColor Green
