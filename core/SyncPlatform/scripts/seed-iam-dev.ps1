# Apply IAM dev SQL seed to Postgres (sync-postgres container).
# Usage: .\scripts\seed-iam-dev.ps1

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sqlFile = Join-Path $scriptDir "seed-iam-dev.sql"

if (-not (Test-Path $sqlFile)) {
    Write-Error "Missing $sqlFile"
}

Write-Host "Applying IAM dev seed to database sync_iam..." -ForegroundColor Cyan
Get-Content $sqlFile -Raw | docker exec -i sync-postgres psql -U postgres -d sync_iam

if ($LASTEXITCODE -ne 0) {
    Write-Error "seed-iam-dev.sql failed"
}

Write-Host "Done. Test login:" -ForegroundColor Green
Write-Host "  Email:    dev.seed@sync.local"
Write-Host "  Password: Sync@12345"
