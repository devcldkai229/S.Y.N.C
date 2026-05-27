# Quick health probe for all Sync Platform APIs.
param([int]$TimeoutSec = 10)

$services = @(
    @{ Name = "IAM";          Port = 5288 },
    @{ Name = "Payment";      Port = 5084 },
    @{ Name = "Roadmap";      Port = 5118 },
    @{ Name = "Exercise";     Port = 5187 },
    @{ Name = "Notification"; Port = 5106 },
    @{ Name = "Social";       Port = 5120 },
    @{ Name = "Gateway";      Port = 5057 }
)

function Test-PortListening([int]$Port) {
    return [bool](Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
}

$ok = 0
$fail = 0

foreach ($svc in $services) {
    $url = "http://localhost:$($svc.Port)/health"

    if (-not (Test-PortListening $svc.Port)) {
        Write-Host "[FAIL] $($svc.Name) (:$($svc.Port)) - port not listening (service did not start)" -ForegroundColor Red
        $fail++
        continue
    }

    try {
        $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec $TimeoutSec
        if ($r.StatusCode -eq 200) {
            Write-Host "[OK]   $($svc.Name) (:$($svc.Port))" -ForegroundColor Green
            $ok++
        }
        else {
            Write-Host "[FAIL] $($svc.Name) HTTP $($r.StatusCode)" -ForegroundColor Red
            $fail++
        }
    }
    catch {
        Write-Host "[FAIL] $($svc.Name) (:$($svc.Port)) - $($_.Exception.Message)" -ForegroundColor Red
        $fail++
    }
}

Write-Host ""
Write-Host "Healthy: $ok / $($services.Count)" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Yellow" })
exit $(if ($fail -eq 0) { 0 } else { 1 })
