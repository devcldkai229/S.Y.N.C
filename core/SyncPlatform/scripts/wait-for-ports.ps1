# Wait until service ports are listening (process started) before HTTP health probes.
param(
    [int]$TimeoutSec = 90,
    [int]$PollIntervalSec = 2
)

$services = @(
    @{ Name = "IAM";          Port = 5288 },
    @{ Name = "Payment";      Port = 5084 },
    @{ Name = "Roadmap";      Port = 5118 },
    @{ Name = "Exercise";     Port = 5187 },
    @{ Name = "Notification"; Port = 5106 },
    @{ Name = "Gateway";      Port = 5057 }
)

function Test-PortListening([int]$Port) {
    return [bool](Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
}

$deadline = (Get-Date).AddSeconds($TimeoutSec)
Write-Host "Waiting for ports to listen (timeout ${TimeoutSec}s)..." -ForegroundColor DarkGray

while ((Get-Date) -lt $deadline) {
    $ready = @()
    $pending = @()

    foreach ($svc in $services) {
        if (Test-PortListening $svc.Port) { $ready += $svc.Name }
        else { $pending += "$($svc.Name):$($svc.Port)" }
    }

    Write-Host "  Ready ($($ready.Count)/$($services.Count)): $($ready -join ', ')" -ForegroundColor DarkGray

    if ($pending.Count -eq 0) {
        Write-Host "All ports are listening." -ForegroundColor Green
        exit 0
    }

    Start-Sleep -Seconds $PollIntervalSec
}

Write-Host "Timed out. Still not listening:" -ForegroundColor Red
foreach ($item in $pending) { Write-Host "  - $item" -ForegroundColor Red }
Write-Host "Open each Sync PowerShell window and read the error output." -ForegroundColor Yellow
exit 1
