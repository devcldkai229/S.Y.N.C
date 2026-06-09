param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$ProjectDir,
    [Parameter(Mandatory = $true)][int]$Port
)

$Host.UI.RawUI.WindowTitle = "Sync - $Name (:$Port)"
Set-Location $ProjectDir
$env:ASPNETCORE_ENVIRONMENT = "Development"
if ($Name -eq "Gateway") {
    # 0.0.0.0 so physical phones on the same LAN can reach the API (not just localhost).
    $env:ASPNETCORE_URLS = "http://0.0.0.0:$Port"
}

Write-Host ">>> $Name API - http://localhost:$Port" -ForegroundColor Green
if ($Name -eq "Gateway") {
    Write-Host "    Entry point (YARP) - LAN: http://<your-pc-ip>:$Port/health" -ForegroundColor DarkGray
}
elseif ($Name -eq "Marketplace") {
    Write-Host "    OpenAPI: http://localhost:$Port/openapi/v1.json" -ForegroundColor DarkGray
}
else {
    Write-Host "    Swagger: http://localhost:$Port/swagger" -ForegroundColor DarkGray
    Write-Host "    Health:  http://localhost:$Port/health" -ForegroundColor DarkGray
}

dotnet run --launch-profile http --no-build
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Service failed to start. Run without --no-build once, or rebuild from run-all.ps1 -Build." -ForegroundColor Red
}
