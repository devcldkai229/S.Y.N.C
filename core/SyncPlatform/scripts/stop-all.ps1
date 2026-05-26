# Stop dotnet processes for Sync Platform API projects (by listening ports).
$ports = @(5057, 5288, 5084, 5118, 5187, 5106, 5120)

foreach ($port in $ports) {
    $conns = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    foreach ($conn in $conns) {
        $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
        if ($proc -and $proc.ProcessName -match "dotnet|Gateway|Iam|Payment|Roadmap|Exercise|Notification|Social|Marketplace") {
            Write-Host "Stopping PID $($proc.Id) on port $port ($($proc.ProcessName))" -ForegroundColor Yellow
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "Done." -ForegroundColor Green
