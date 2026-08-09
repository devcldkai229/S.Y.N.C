# Kill processes on service ports, build, then launch APIs (Development).
#
# For full stack in Docker (infra + all services + web): see infra/docker/README.md
#   cd infra/docker && .\scripts\up-full.ps1 -Build
#
# Usage (all services on host):
#   .\scripts\run-all.ps1
#   .\scripts\run-all.ps1 -SkipBuild
#
# Restart only selected services (prefix --):
#   .\scripts\run-all.ps1 --iam
#   .\scripts\run-all.ps1 --gateway --ai
#   .\scripts\run-all.ps1 -SkipBuild --payment --order
#   .\scripts\run-all.ps1 --rcm
#
# Flags:
#   --iam --payment --roadmap --exercise --notification --social
#   --nutrition --marketplace --order --gateway --ai --rcm
#   --help

param(
    [switch]$SkipBuild,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ServiceFlags
)

$ErrorActionPreference = "Stop"
$SyncRoot = Split-Path -Parent $PSScriptRoot
$RepoRoot = Split-Path -Parent (Split-Path -Parent $SyncRoot)
$AiServiceDir = Join-Path $RepoRoot "ai\sync-agent-service"
$RcmServiceDir = Join-Path $RepoRoot "ai\sync-rcm-service"

$services = @(
    @{ Name = "IAM";          Key = "iam";          Dir = "src\Services\Iam\Iam.API";                     Port = 5288; Kind = "dotnet" },
    @{ Name = "Payment";      Key = "payment";      Dir = "src\Services\Payment\Payment.API";             Port = 5084; Kind = "dotnet" },
    @{ Name = "Roadmap";      Key = "roadmap";      Dir = "src\Services\Roadmap\Roadmap.API";             Port = 5118; Kind = "dotnet" },
    @{ Name = "Exercise";     Key = "exercise";     Dir = "src\Services\Exercise\Exercise.API";           Port = 5187; Kind = "dotnet" },
    @{ Name = "Notification"; Key = "notification"; Dir = "src\Services\Notification\Notification.API"; Port = 5106; Kind = "dotnet" },
    @{ Name = "Social";       Key = "social";       Dir = "src\Services\Social\Social.API";               Port = 5120; Kind = "dotnet" },
    @{ Name = "Nutrition";    Key = "nutrition";    Dir = "src\Services\Nutrition\Nutrition.API";         Port = 5122; Kind = "dotnet" },
    @{ Name = "Marketplace";  Key = "marketplace";  Dir = "src\Services\Marketplace\Marketplace.API";     Port = 5119; Kind = "dotnet" },
    @{ Name = "Order";        Key = "order";        Dir = "src\Services\Order\Order.API";                 Port = 5123; Kind = "dotnet" },
    @{ Name = "Gateway";      Key = "gateway";      Dir = "src\Gateway";                                  Port = 5057; Kind = "dotnet" },
    @{ Name = "AI";           Key = "ai";           Dir = $null;                                          Port = 8088; Kind = "ai" },
    @{ Name = "RCM";          Key = "rcm";          Dir = $null;                                          Port = 5300; Kind = "rcm" }
)

function Show-Help {
    Write-Host @"
run-all.ps1 — start / restart Sync Platform services

  All services:
    .\scripts\run-all.ps1
    .\scripts\run-all.ps1 -SkipBuild

  One or more services (restart only those):
    .\scripts\run-all.ps1 --iam
    .\scripts\run-all.ps1 --gateway --ai
    .\scripts\run-all.ps1 --rcm
    .\scripts\run-all.ps1 -SkipBuild --payment --order

  Service flags:
    --iam  --payment  --roadmap  --exercise  --notification
    --social  --nutrition  --marketplace  --order  --gateway
    --ai  --rcm
"@
}

function Get-LaunchShell {
    if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        return (Get-Command pwsh).Source
    }
    return "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
}

function Stop-PortListener {
    param([int]$Port, [int]$MaxAttempts = 6)

    $stopped = [System.Collections.Generic.HashSet[int]]::new()
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        $conns = @(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
        if ($conns.Count -eq 0) { return $true }

        foreach ($conn in $conns) {
            $owningPid = $conn.OwningProcess
            if ($stopped.Contains($owningPid)) { continue }
            $proc = Get-Process -Id $owningPid -ErrorAction SilentlyContinue
            if ($proc) {
                Write-Host "Stopping PID $($proc.Id) ($($proc.ProcessName)) - port $Port" -ForegroundColor Yellow
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                [void]$stopped.Add($owningPid)
            }
        }
        Start-Sleep -Milliseconds 700
    }

    return -not (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
}

function Stop-SelectedServices {
    param([object[]]$Selected)

    foreach ($svc in $Selected) {
        if (-not (Stop-PortListener -Port $svc.Port)) {
            Write-Host "Warning: port $($svc.Port) ($($svc.Name)) may still be in use." -ForegroundColor Red
        }
    }

    $dotnetSelected = @($Selected | Where-Object { $_.Kind -eq "dotnet" })
    foreach ($svc in $dotnetSelected) {
        $exeName = if ($svc.Name -eq "Gateway") { "Gateway.API" } else { "$($svc.Name).API" }
        Get-Process -Name $exeName -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Host "Stopping PID $($_.Id) ($exeName)" -ForegroundColor Yellow
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        }
    }

    if ($dotnetSelected.Count -gt 0) {
        $namePattern = ($dotnetSelected | ForEach-Object {
            if ($_.Name -eq "Gateway") { "Gateway" } else { $_.Name }
        }) -join "|"
        Get-CimInstance Win32_Process -Filter "Name = 'dotnet.exe'" -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandLine -match "\.($namePattern)\.API\.csproj" -or ($_.CommandLine -match "\\Gateway\\" -and $namePattern -match "Gateway") } |
            ForEach-Object {
                Write-Host "Stopping PID $($_.ProcessId) (dotnet host)" -ForegroundColor Yellow
                Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
            }
    }

    if (@($Selected | Where-Object { $_.Kind -eq "ai" }).Count -gt 0) {
        Get-CimInstance Win32_Process -Filter "Name = 'python.exe'" -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandLine -match 'uvicorn.*app\.api\.main:app' } |
            ForEach-Object {
                Write-Host "Stopping PID $($_.ProcessId) (uvicorn AI)" -ForegroundColor Yellow
                Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
            }
    }

    if (@($Selected | Where-Object { $_.Kind -eq "rcm" }).Count -gt 0) {
        Get-CimInstance Win32_Process -Filter "Name = 'python.exe'" -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandLine -match 'uvicorn.*app\.main:app' } |
            ForEach-Object {
                Write-Host "Stopping PID $($_.ProcessId) (uvicorn sync-rcm-service)" -ForegroundColor Yellow
                Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
            }
    }

    Start-Sleep -Seconds 1
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
    Write-Host 'Service failed to start. Re-run: .\scripts\run-all.ps1 --$($Name.ToLower())' -ForegroundColor Red
}
"@
}

function Resolve-UvicornCommand {
    $uvicorn = Get-Command uvicorn -ErrorAction SilentlyContinue
    if ($uvicorn) { return "uvicorn" }

    $pyCheck = Get-Command py -ErrorAction SilentlyContinue
    if (-not $pyCheck) {
        Write-Host "Skip AI: neither uvicorn nor py launcher found. Install Python 3.11+." -ForegroundColor Yellow
        return $null
    }
    $null = & py -m pip --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Skip AI: py found but pip missing. Run: py -m ensurepip --upgrade" -ForegroundColor Yellow
        return $null
    }
    return "py -m uvicorn"
}

function Start-AiService {
    param([string]$LaunchShell)

    if (-not (Test-Path $AiServiceDir)) {
        Write-Host "Skip AI: folder not found at $AiServiceDir" -ForegroundColor Yellow
        return
    }

    $aiEnv = Join-Path $AiServiceDir ".env"
    if (-not (Test-Path $aiEnv)) {
        Write-Host "Skip AI: copy ai/sync-agent-service/.env.example -> .env first" -ForegroundColor Yellow
        return
    }

    $uvicornCmd = Resolve-UvicornCommand
    if (-not $uvicornCmd) { return }

    $aiCommand = @"
`$Host.UI.RawUI.WindowTitle = 'Sync - AI Agent (:8088)'
Set-Location '$AiServiceDir'
Write-Host '>>> SYNC AI Agent - http://localhost:8088' -ForegroundColor Green
Write-Host '    Health:  http://localhost:8088/healthz' -ForegroundColor DarkGray
Write-Host '    Chat:    POST /ai/chat (SSE) via Gateway /api/v1/ai/chat' -ForegroundColor DarkGray
Write-Host '    Needs:   Docker postgres+redis, Ollama :11434, OPENAI_API_KEY (tier mid/large)' -ForegroundColor DarkGray
$uvicornCmd app.api.main:app --reload --host 0.0.0.0 --port 8088
if (`$LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host 'AI service failed. Check .env, Redis, Postgres sync_ai, Ollama models.' -ForegroundColor Red
}
"@

    Write-Host "Starting AI Agent (uvicorn :8088)..." -ForegroundColor Cyan
    Start-Process -FilePath $LaunchShell -ArgumentList @("-NoExit", "-Command", $aiCommand)
}

function Start-RcmService {
    param([string]$LaunchShell)

    if (-not (Test-Path $RcmServiceDir)) {
        Write-Host "Skip RCM: folder not found at $RcmServiceDir" -ForegroundColor Yellow
        return
    }

    $rcmEnv = Join-Path $RcmServiceDir ".env"
    if (-not (Test-Path $rcmEnv)) {
        Write-Host "Skip RCM: copy ai/sync-rcm-service/.env.example -> .env first" -ForegroundColor Yellow
        return
    }

    $uvicornCmd = Resolve-UvicornCommand
    if (-not $uvicornCmd) {
        Write-Host "Skip RCM: uvicorn / py not available." -ForegroundColor Yellow
        return
    }

    $rcmCommand = @"
`$Host.UI.RawUI.WindowTitle = 'Sync - sync-rcm-service (:5300)'
Set-Location '$RcmServiceDir'
Write-Host '>>> sync-rcm-service (workout RCM) - http://localhost:5300' -ForegroundColor Green
Write-Host '    Health:  http://localhost:5300/health' -ForegroundColor DarkGray
Write-Host '    Workout: POST /api/v1/ai/workout/... (via Gateway when routed)' -ForegroundColor DarkGray
Write-Host '    Needs:   Postgres sync_ai_agent (:5434), OPENAI_API_KEY, admin reindex once' -ForegroundColor DarkGray
$uvicornCmd app.main:app --reload --host 0.0.0.0 --port 5300
if (`$LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host 'sync-rcm-service failed. Check .env, Postgres sync_ai_agent, OPENAI_API_KEY, init_db/reindex.' -ForegroundColor Red
}
"@

    Write-Host "Starting sync-rcm-service (uvicorn :5300)..." -ForegroundColor Cyan
    Start-Process -FilePath $LaunchShell -ArgumentList @("-NoExit", "-Command", $rcmCommand)
}

# --- parse --service flags ---
$flagList = @($ServiceFlags | Where-Object { $_ -and $_.Trim() -ne "" })
if ($flagList -contains "--help" -or $flagList -contains "-h" -or $flagList -contains "-?") {
    Show-Help
    exit 0
}

$unknown = @()
$selectedKeys = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($flag in $flagList) {
    if ($flag -notmatch '^--([a-zA-Z0-9]+)$') {
        $unknown += $flag
        continue
    }
    $key = $Matches[1].ToLowerInvariant()
    if ($key -eq "notif") { $key = "notification" }
    if ($key -eq "aiagent") { $key = "rcm" } # legacy alias
    $match = $services | Where-Object { $_.Key -eq $key } | Select-Object -First 1
    if (-not $match) {
        $unknown += $flag
        continue
    }
    [void]$selectedKeys.Add($key)
}

if ($unknown.Count -gt 0) {
    Write-Host "Unknown flag(s): $($unknown -join ', ')" -ForegroundColor Red
    Show-Help
    exit 1
}

$runAll = $selectedKeys.Count -eq 0
$selected = if ($runAll) {
    $services
} else {
    @($services | Where-Object { $selectedKeys.Contains($_.Key) })
}

$launchShell = Get-LaunchShell
$selectedNames = ($selected | ForEach-Object { $_.Name }) -join ", "

if ($runAll) {
    Write-Host "Stopping all ports (release file locks before build)..." -ForegroundColor Cyan
    & (Join-Path $PSScriptRoot "stop-all.ps1")
} else {
    Write-Host "Restarting: $selectedNames" -ForegroundColor Cyan
    Stop-SelectedServices -Selected $selected
}
Start-Sleep -Seconds 2

# Ensure Postgres DB for Smart Push schedule/log (Notification) — best effort
if ($selectedKeys.Contains("notification") -or $runAll) {
    try {
        $pgContainer = docker ps --filter "publish=5434" -q 2>$null | Select-Object -First 1
        if ($pgContainer) {
            $exists = (docker exec $pgContainer psql -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname='sync_smart_push'" 2>$null).Trim()
            if ($exists -ne "1") {
                Write-Host "Creating Postgres database sync_smart_push..." -ForegroundColor Cyan
                docker exec $pgContainer psql -U postgres -c "CREATE DATABASE sync_smart_push" | Out-Null
            }
        }
    } catch {
        Write-Host "Could not ensure sync_smart_push DB (create manually if Notification fails to migrate)." -ForegroundColor DarkYellow
    }
}

$dotnetSelected = @($selected | Where-Object { $_.Kind -eq "dotnet" })
$useNoBuild = $false

if ($dotnetSelected.Count -gt 0 -and -not $SkipBuild) {
    Write-Host "Building..." -ForegroundColor Cyan
    foreach ($svc in $dotnetSelected) {
        $projectDir = Join-Path $SyncRoot $svc.Dir
        $csproj = Get-ChildItem $projectDir -Filter "*.csproj" -ErrorAction Stop |
            Select-Object -First 1 -ExpandProperty FullName
        Write-Host "  $($svc.Name)" -ForegroundColor DarkGray
        dotnet build $csproj -v minimal --nologo
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Build failed for $($svc.Name). Fix errors above, then re-run." -ForegroundColor Red
            exit 1
        }
    }
    $useNoBuild = $true
}

Write-Host "Starting services..." -ForegroundColor Cyan
foreach ($svc in $selected) {
    if ($svc.Kind -eq "ai") {
        Start-AiService -LaunchShell $launchShell
        continue
    }
    if ($svc.Kind -eq "rcm") {
        Start-RcmService -LaunchShell $launchShell
        continue
    }

    $projectDir = (Resolve-Path (Join-Path $SyncRoot $svc.Dir)).Path
    $command = New-ServiceStartCommand -Name $svc.Name -ProjectDir $projectDir -Port $svc.Port -UseNoBuild:$useNoBuild
    Start-Process -FilePath $launchShell -ArgumentList @("-NoExit", "-Command", $command)
    Start-Sleep -Milliseconds 500
}

Write-Host "Done." -ForegroundColor Green
if ($runAll -or $selectedKeys.Contains("gateway")) {
    Write-Host "       Gateway: http://localhost:5057" -ForegroundColor Green
}
if ($runAll -or $selectedKeys.Contains("ai")) {
    Write-Host "       AI:      http://localhost:8088/healthz" -ForegroundColor Green
}
if ($runAll -or $selectedKeys.Contains("rcm")) {
    Write-Host "       RCM:     http://localhost:5300/health" -ForegroundColor Green
}
if (-not $runAll) {
    Write-Host "       Restarted: $selectedNames" -ForegroundColor Green
}
Write-Host "Stop all: .\scripts\stop-all.ps1" -ForegroundColor DarkGray
