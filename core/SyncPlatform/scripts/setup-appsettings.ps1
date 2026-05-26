# Creates gitignored appsettings*.json from committed *.example.json templates (skip if target exists).
# Usage (from repo root):
#   .\core\SyncPlatform\scripts\setup-appsettings.ps1
#   .\core\SyncPlatform\scripts\setup-appsettings.ps1 -Force

param([switch]$Force)

$ErrorActionPreference = "Stop"
$SyncRoot = Split-Path -Parent $PSScriptRoot

$examples = Get-ChildItem -Path $SyncRoot -Recurse -Filter "*.example.json" -File
if ($examples.Count -eq 0) {
    Write-Host "No *.example.json found under $SyncRoot" -ForegroundColor Yellow
    exit 0
}

$created = 0
$skipped = 0

foreach ($example in $examples) {
  $targetName = $example.Name -replace '\.example\.json$', '.json'
  $target = Join-Path $example.DirectoryName $targetName

  if ((Test-Path $target) -and -not $Force) {
    $skipped++
    continue
  }

  Copy-Item -Path $example.FullName -Destination $target -Force
  Write-Host "  $($target.Replace($SyncRoot, '.'))" -ForegroundColor Green
  $created++
}

Write-Host ""
Write-Host "Created/updated: $created  |  Skipped (exists): $skipped" -ForegroundColor Cyan
if ($skipped -gt 0) {
  Write-Host "Use -Force to overwrite existing files." -ForegroundColor DarkGray
}
Write-Host "Fill secrets in appsettings.Development.json — see CONFIGURATION.md" -ForegroundColor Yellow
