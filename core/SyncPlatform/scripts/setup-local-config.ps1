# Copy every *.example.json → same path without ".example" (first-time / new clone).
# Usage: .\scripts\setup-local-config.ps1
#        .\scripts\setup-local-config.ps1 -Force   # overwrite existing local files

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$SyncRoot = Split-Path -Parent $PSScriptRoot

$examples = Get-ChildItem -Path $SyncRoot -Recurse -Filter "*.example.json" -File |
    Where-Object { $_.FullName -notmatch '\\bin\\|\\obj\\' }

if ($examples.Count -eq 0) {
    Write-Warning "No *.example.json templates found under $SyncRoot"
    exit 1
}

$created = 0
$skipped = 0

foreach ($example in $examples) {
    $targetPath = $example.FullName -replace '\.example\.json$', '.json'

    if ((Test-Path $targetPath) -and -not $Force) {
        Write-Host "Skip (exists): $targetPath" -ForegroundColor DarkGray
        $skipped++
        continue
    }

    Copy-Item -Path $example.FullName -Destination $targetPath -Force:$Force
    Write-Host "Created: $targetPath" -ForegroundColor Green
    $created++
}

Write-Host ""
Write-Host "Done. Created: $created | Skipped: $skipped" -ForegroundColor Cyan
Write-Host "Edit copied files with your secrets (DB, JWT, PayOS, Google, SMTP)." -ForegroundColor Yellow
Write-Host "These paths are gitignored — only *.example.json is committed." -ForegroundColor Yellow
