# Stop Sync Platform API processes (by listening ports + dotnet API executables).
# Keep in sync with ports in run-all.ps1.

$ports = @(
    5057, # Gateway
    5288, # IAM
    5084, # Payment
    5118, # Roadmap
    5187, # Exercise
    5106, # Notification
    5120, # Social
    5122, # Nutrition
    5119, # Marketplace
    5123  # Order
)

$stoppedPids = [System.Collections.Generic.HashSet[int]]::new()

function Stop-ProcessSafe {
    param([int]$ProcessId, [string]$Reason)
    if ($stoppedPids.Contains($ProcessId)) { return }
    $proc = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    if (-not $proc) { return }
    Write-Host "Stopping PID $($proc.Id) ($($proc.ProcessName)) - $Reason" -ForegroundColor Yellow
    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    $stoppedPids.Add($ProcessId) | Out-Null
}

function Stop-PortListener {
    param([int]$Port, [int]$MaxAttempts = 6)

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        $conns = @(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
        if ($conns.Count -eq 0) { return $true }

        foreach ($conn in $conns) {
            Stop-ProcessSafe -ProcessId $conn.OwningProcess -Reason "port $Port"
        }

        Start-Sleep -Milliseconds 700
    }

    return -not (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
}

foreach ($port in $ports) {
    if (-not (Stop-PortListener -Port $port)) {
        Write-Host "Warning: port $port may still be in use." -ForegroundColor Red
    }
}

# Fallback: kill stray API executables started via dotnet run (not bound yet / port mismatch).
$apiNames = @(
    'Gateway.API', 'Iam.API', 'Payment.API', 'Roadmap.API', 'Exercise.API',
    'Notification.API', 'Social.API', 'Nutrition.API', 'Marketplace.API', 'Order.API'
)

foreach ($name in $apiNames) {
    Get-Process -Name $name -ErrorAction SilentlyContinue | ForEach-Object {
        Stop-ProcessSafe -ProcessId $_.Id -Reason $name
    }
}

# Second pass: dotnet hosts that keep DLL locks after API exe exits.
Get-CimInstance Win32_Process -Filter "Name = 'dotnet.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match '\.(Gateway|Iam|Payment|Roadmap|Exercise|Notification|Social|Nutrition|Marketplace|Order)\.API\.csproj' } |
    ForEach-Object {
        Stop-ProcessSafe -ProcessId $_.ProcessId -Reason "dotnet host"
    }

Start-Sleep -Seconds 1
Write-Host "Done." -ForegroundColor Green
