# Health-check all Sync Platform services (+ Gateway). Run while services are up.
# Usage: .\scripts\health-check.ps1

$ErrorActionPreference = "Continue"
$SyncRoot = Split-Path -Parent $PSScriptRoot

$targets = @(
    @{ Name = "IAM";          Url = "http://localhost:5288/health" },
    @{ Name = "Payment";      Url = "http://localhost:5084/health" },
    @{ Name = "Roadmap";      Url = "http://localhost:5118/health" },
    @{ Name = "Exercise";     Url = "http://localhost:5187/health" },
    @{ Name = "Notification"; Url = "http://localhost:5106/health" },
    @{ Name = "Gateway";      Url = "http://localhost:5057/health" }
)

$gatewayRoutes = @(
    @{ Name = "Gateway -> IAM auth (anonymous)"; Url = "http://localhost:5057/api/v1/auth/verify-email?token=invalid"; ExpectStatus = @(400, 404) },
    @{ Name = "Gateway health"; Url = "http://localhost:5057/health"; ExpectStatus = @(200) }
)

function Test-Health {
    param([string]$Url, [int[]]$ExpectStatus = @(200))
    try {
        $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10
        $ok = $ExpectStatus -contains [int]$resp.StatusCode
        $body = if ($resp.Content) { $resp.Content.Substring(0, [Math]::Min(80, $resp.Content.Length)) } else { "" }
        return @{ Ok = $ok; Status = $resp.StatusCode; Body = $body }
    }
    catch [System.Net.WebException] {
        if ($_.Exception.Response) {
            $code = [int]$_.Exception.Response.StatusCode
            $ok = $ExpectStatus -contains $code
            return @{ Ok = $ok; Status = $code; Body = $_.Exception.Message }
        }
        return @{ Ok = $false; Status = "ERR"; Body = $_.Exception.Message }
    }
    catch {
        return @{ Ok = $false; Status = "ERR"; Body = $_.Exception.Message }
    }
}

Write-Host ""
Write-Host "=== Direct service health ===" -ForegroundColor Cyan
$allOk = $true
foreach ($t in $targets) {
    $r = Test-Health -Url $t.Url
    if ($r.Ok) {
        Write-Host "[OK]   $($t.Name) $($t.Url) -> $($r.Status)" -ForegroundColor Green
    }
    else {
        Write-Host "[FAIL] $($t.Name) $($t.Url) -> $($r.Status) $($r.Body)" -ForegroundColor Red
        $allOk = $false
    }
}

Write-Host ""
Write-Host "=== Gateway probes ===" -ForegroundColor Cyan
foreach ($t in $gatewayRoutes) {
    $r = Test-Health -Url $t.Url -ExpectStatus $t.ExpectStatus
    if ($r.Ok) {
        Write-Host "[OK]   $($t.Name) -> $($r.Status)" -ForegroundColor Green
    }
    else {
        Write-Host "[FAIL] $($t.Name) -> $($r.Status) $($r.Body)" -ForegroundColor Red
        $allOk = $false
    }
}

Write-Host ""
if ($allOk) {
    Write-Host "All health checks passed." -ForegroundColor Green
    exit 0
}
else {
    Write-Host "Some checks failed. Ensure services are running (.\scripts\run-all.ps1)." -ForegroundColor Yellow
    exit 1
}
