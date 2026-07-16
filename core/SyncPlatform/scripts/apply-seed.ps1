# Start each API once so startup seeders run, then stop. Skips Exercise catalog.
param(
    [int]$HealthTimeoutSec = 180
)

$ErrorActionPreference = "Stop"
$SyncRoot = "e:\programming\my_project\sync-lifestyle-automation-platform\core\SyncPlatform"

$services = @(
    @{ Name = "IAM";          Dir = "src\Services\Iam\Iam.API";                     Port = 5288 },
    @{ Name = "Payment";      Dir = "src\Services\Payment\Payment.API";             Port = 5084 },
    @{ Name = "Roadmap";      Dir = "src\Services\Roadmap\Roadmap.API";             Port = 5118 },
    @{ Name = "Nutrition";    Dir = "src\Services\Nutrition\Nutrition.API";         Port = 5122 },
    @{ Name = "Marketplace";  Dir = "src\Services\Marketplace\Marketplace.API";     Port = 5119 },
    @{ Name = "Social";       Dir = "src\Services\Social\Social.API";               Port = 5120 },
    @{ Name = "Notification"; Dir = "src\Services\Notification\Notification.API";   Port = 5106 },
    @{ Name = "Order";        Dir = "src\Services\Order\Order.API";                 Port = 5123 }
)

function Wait-Health([int]$port, [int]$maxSec) {
    $deadline = (Get-Date).AddSeconds($maxSec)
    while ((Get-Date) -lt $deadline) {
        try {
            $r = Invoke-WebRequest -Uri "http://localhost:$port/health" -TimeoutSec 3 -UseBasicParsing
            if ($r.StatusCode -eq 200) { return $true }
        } catch { }
        Start-Sleep -Seconds 2
    }
    return $false
}

function Stop-PortProcess([int]$port) {
    $conns = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    foreach ($c in $conns) {
        if ($c.OwningProcess -gt 0) {
            Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
        }
    }
}

$results = @()
Push-Location $SyncRoot
try {
    foreach ($svc in $services) {
        $name = $svc.Name
        $port = [int]$svc.Port
        $dir = Join-Path $SyncRoot $svc.Dir
        $logFile = Join-Path $env:TEMP "sync-apply-seed-$name.log"
        Write-Host ""
        Write-Host "=== Seeding $name (port $port) ===" -ForegroundColor Cyan

        Stop-PortProcess $port
        Start-Sleep -Seconds 1

        $env:ASPNETCORE_ENVIRONMENT = "Development"
        $proc = Start-Process -FilePath "dotnet" `
            -ArgumentList @("run", "--project", $dir, "--no-launch-profile", "--urls", "http://127.0.0.1:$port") `
            -WorkingDirectory $dir `
            -RedirectStandardOutput $logFile `
            -RedirectStandardError "$logFile.err" `
            -PassThru `
            -WindowStyle Hidden

        $ok = Wait-Health $port $HealthTimeoutSec
        if (-not $ok) {
            Write-Host "FAIL: $name did not become healthy" -ForegroundColor Red
            if (Test-Path $logFile) { Get-Content $logFile -Tail 50 }
            if (Test-Path "$logFile.err") { Get-Content "$logFile.err" -Tail 50 }
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            Stop-PortProcess $port
            $results += [pscustomobject]@{ Service = $name; Status = "FAIL"; Port = $port }
            continue
        }

        Write-Host "OK: $name healthy - seed applied" -ForegroundColor Green
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        Stop-PortProcess $port
        Start-Sleep -Seconds 1
        $results += [pscustomobject]@{ Service = $name; Status = "OK"; Port = $port }
    }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Yellow
$results | Format-Table -AutoSize
$failed = @($results | Where-Object { $_.Status -ne "OK" })
if ($failed.Count -gt 0) { exit 1 }
