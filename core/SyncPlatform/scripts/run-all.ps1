# Kill processes on service ports, build, then launch all APIs (Development).
# Usage:
#   .\scripts\run-all.ps1
#   .\scripts\run-all.ps1 -SkipBuild

param(
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$SyncRoot = Split-Path -Parent $PSScriptRoot
$RepoRoot = Split-Path -Parent (Split-Path -Parent $SyncRoot)
$AiServiceDir = Join-Path $RepoRoot "ai\sync-agent-service"

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
Start-Sleep -Seconds 3

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
Write-Host "       AI:      http://localhost:8088/healthz" -ForegroundColor Green
Write-Host "Stop: .\scripts\stop-all.ps1" -ForegroundColor DarkGray

# --- SYNC AI (Python / uvicorn) — chạy ngoài dotnet, cùng repo ---
if (-not (Test-Path $AiServiceDir)) {
    Write-Host "Skip AI: folder not found at $AiServiceDir" -ForegroundColor Yellow
    exit 0
}

$aiEnv = Join-Path $AiServiceDir ".env"
if (-not (Test-Path $aiEnv)) {
    Write-Host "Skip AI: copy ai/sync-agent-service/.env.example -> .env first" -ForegroundColor Yellow
    exit 0
}

$uvicorn = Get-Command uvicorn -ErrorAction SilentlyContinue
$uvicornCmd = if ($uvicorn) { "uvicorn" } else { "py -m uvicorn" }
if (-not $uvicorn) {
    $pyCheck = Get-Command py -ErrorAction SilentlyContinue
    if (-not $pyCheck) {
        Write-Host "Skip AI: neither uvicorn nor py launcher found. Install Python 3.11+." -ForegroundColor Yellow
        exit 0
    }
    $pipCheck = & py -m pip --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Skip AI: py found but pip missing. Run: py -m ensurepip --upgrade" -ForegroundColor Yellow
        exit 0
    }
}

$aiCommand = @"
`$Host.UI.RawUI.WindowTitle = 'Sync - AI Agent (:8088)'
Set-Location '$AiServiceDir'
Write-Host '>>> SYNC AI Agent - http://localhost:8088' -ForegroundColor Green
Write-Host '    Health:  http://localhost:8088/healthz' -ForegroundColor DarkGray
Write-Host '    Chat:    POST /ai/chat (SSE) via Gateway /api/v1/ai/chat' -ForegroundColor DarkGray
Write-Host '    Needs:   Docker postgres+redis, Ollama :11434, OPENAI_API_KEY (tier mid/large)' -ForegroundColor DarkGray
$($uvicornCmd) app.api.main:app --reload --host 0.0.0.0 --port 8088
if (`$LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host 'AI service failed. Check .env, Redis, Postgres sync_ai, Ollama models.' -ForegroundColor Red
}
"@

Write-Host "Starting AI Agent (uvicorn :8088)..." -ForegroundColor Cyan
Start-Process -FilePath $launchShell -ArgumentList @("-NoExit", "-Command", $aiCommand)
