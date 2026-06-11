# Run Flutter web with AWS Grab map (MapLibre).
# 1. Copy dart_defines.aws.example.json -> dart_defines.aws.json
# 2. Paste your Map API key (associated with map resource "sync-map" on AWS Console)
# 3. .\scripts\run-chrome.ps1

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

$definesFile = "dart_defines.aws.json"
if (-not (Test-Path $definesFile)) {
    Write-Error "Missing $definesFile. Copy dart_defines.aws.example.json and set AWS_MAP_API_KEY."
}

flutter run -d chrome `
  --dart-define-from-file=$definesFile
