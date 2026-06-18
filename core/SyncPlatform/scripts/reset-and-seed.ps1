# Wipe all service databases and re-apply seed data by starting each API once.
# Usage: .\scripts\reset-and-seed.ps1
#        .\scripts\reset-and-seed.ps1 -SkipWipe   # only re-seed (DBs already empty)

param(
    [switch]$SkipWipe,
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$SyncRoot = Split-Path -Parent $PSScriptRoot
$RepoRoot = Split-Path -Parent (Split-Path -Parent $SyncRoot)

$services = @(
    @{ Name = "IAM";          Dir = "src\Services\Iam\Iam.API";                     Port = 5288 },
    @{ Name = "Payment";      Dir = "src\Services\Payment\Payment.API";             Port = 5084 },
    @{ Name = "Exercise";     Dir = "src\Services\Exercise\Exercise.API";           Port = 5187 },
    @{ Name = "Roadmap";      Dir = "src\Services\Roadmap\Roadmap.API";             Port = 5118 },
    @{ Name = "Social";       Dir = "src\Services\Social\Social.API";               Port = 5120 },
    @{ Name = "Notification"; Dir = "src\Services\Notification\Notification.API"; Port = 5106 }
)

function Write-Step([string]$Message) {
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

Write-Step "Stopping running APIs"
& (Join-Path $PSScriptRoot "stop-all.ps1")
Start-Sleep -Seconds 2

if (-not $SkipWipe) {
    Write-Step "Wiping PostgreSQL databases"
    docker exec sync-postgres psql -U postgres -c "DROP DATABASE IF EXISTS sync_iam;" | Out-Null
    docker exec sync-postgres psql -U postgres -c "DROP DATABASE IF EXISTS sync_payment;" | Out-Null
    docker exec sync-postgres psql -U postgres -c "CREATE DATABASE sync_iam;" | Out-Null
    docker exec sync-postgres psql -U postgres -c "CREATE DATABASE sync_payment;" | Out-Null

    Write-Step "Wiping MongoDB databases"
    docker exec sync-mongodb mongosh --quiet --eval @"
['sync_social','sync_notification','sync_exercise','sync_roadmap'].forEach(d => {
  const r = db.getSiblingDB(d).dropDatabase();
  print(d + ': ' + (r.ok ? 'dropped' : 'failed'));
});
"@ | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
}

if (-not $SkipBuild) {
    Write-Step "Building all services"
    foreach ($svc in $services) {
        $projectDir = Join-Path $SyncRoot $svc.Dir
        $csproj = Get-ChildItem $projectDir -Filter "*.csproj" | Select-Object -First 1 -ExpandProperty FullName
        Write-Host "  $($svc.Name)" -ForegroundColor DarkGray
        dotnet build $csproj -v minimal --nologo
        if ($LASTEXITCODE -ne 0) { throw "Build failed for $($svc.Name)" }
    }
}

Write-Step "Starting services sequentially (migrate + seed on startup)"
$results = @()

foreach ($svc in $services) {
    $projectDir = (Resolve-Path (Join-Path $SyncRoot $svc.Dir)).Path
    $stdoutLog = Join-Path $env:TEMP "sync-seed-$($svc.Name)-out.log"
    $stderrLog = Join-Path $env:TEMP "sync-seed-$($svc.Name)-err.log"
    Remove-Item $stdoutLog, $stderrLog -Force -ErrorAction SilentlyContinue

    $proc = Start-Process `
        -FilePath "dotnet" `
        -ArgumentList "run --launch-profile http --no-build" `
        -WorkingDirectory $projectDir `
        -PassThru `
        -RedirectStandardOutput $stdoutLog `
        -RedirectStandardError $stderrLog `
        -WindowStyle Hidden

    $env:ASPNETCORE_ENVIRONMENT = "Development"
    $healthy = $false
    $earlyExit = $null

    for ($i = 0; $i -lt 45; $i++) {
        Start-Sleep -Seconds 2
        if ($proc.HasExited) {
            $earlyExit = "exit code $($proc.ExitCode)"
            break
        }
        try {
            $resp = Invoke-WebRequest -Uri "http://localhost:$($svc.Port)/health" -UseBasicParsing -TimeoutSec 3
            if ($resp.StatusCode -eq 200) {
                $healthy = $true
                break
            }
        } catch {}
    }

    if (-not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }

    $stderr = if (Test-Path $stderrLog) { Get-Content $stderrLog -Raw } else { "" }
    $stdout = if (Test-Path $stdoutLog) { Get-Content $stdoutLog -Raw } else { "" }
    $logSnippet = ($stderr + "`n" + $stdout).Trim()
    if ($logSnippet.Length -gt 400) {
        $logSnippet = $logSnippet.Substring($logSnippet.Length - 400)
    }

    $status = if ($healthy) { "OK" } else { "FAIL" }
    $color = if ($healthy) { "Green" } else { "Red" }
    Write-Host "  $($svc.Name) (:$($svc.Port)): $status" -ForegroundColor $color
    if (-not $healthy) {
        if ($earlyExit) { Write-Host "    Early exit: $earlyExit" -ForegroundColor Yellow }
        if ($logSnippet) { Write-Host "    Log tail: $logSnippet" -ForegroundColor DarkGray }
    }

    $results += [PSCustomObject]@{
        Service = $svc.Name
        Port    = $svc.Port
        Health  = $healthy
        Note    = $earlyExit
    }
}

Write-Step "Verifying seeded data"
$checks = @()

try {
    $userCount = docker exec sync-postgres psql -U postgres -d sync_iam -tAc "SELECT COUNT(*) FROM iam.users;" 2>$null
    $checks += "IAM users: $userCount"
} catch { $checks += "IAM users: check failed" }

try {
    $planCount = docker exec sync-postgres psql -U postgres -d sync_payment -tAc "SELECT COUNT(*) FROM payment.subscription_plans;" 2>$null
    $checks += "Payment plans: $planCount"
} catch { $checks += "Payment plans: check failed" }

$mongoCounts = docker exec sync-mongodb mongosh --quiet --eval @"
const dbs = ['sync_social','sync_exercise','sync_roadmap','sync_notification'];
dbs.forEach(d => {
  const n = db.getSiblingDB(d).getCollectionNames().length;
  print(d + ' collections: ' + n);
});
"@ 2>$null
if ($mongoCounts) { $checks += $mongoCounts }

$checks | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }

$failed = $results | Where-Object { -not $_.Health }
if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "Seed completed with failures. Re-run after fixing errors above." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All databases wiped and re-seeded successfully." -ForegroundColor Green
Write-Host "Start dev stack: .\scripts\run-all.ps1" -ForegroundColor DarkGray
