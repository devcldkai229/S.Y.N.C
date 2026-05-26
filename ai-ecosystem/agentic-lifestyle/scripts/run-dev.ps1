# Start SYNC voice gateway (development)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

if (-not (Test-Path ".venv")) {
    Write-Host "Creating venv..." -ForegroundColor Cyan
    python -m venv .venv
}

& .\.venv\Scripts\Activate.ps1
pip install -e ".[dev]" -q

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Created .env — set SYNC_GROQ_API_KEY before testing STT." -ForegroundColor Yellow
}

$env:SYNC_DEBUG = "true"
sync-agent
