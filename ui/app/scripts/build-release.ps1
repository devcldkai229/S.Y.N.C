# Build Android release artifacts for production deploy.
# Requires: Flutter SDK, Android SDK.
# Optional: android/key.properties + upload-keystore.jks for Play Store signing
#           (otherwise release is signed with debug keys - OK for sideload smoke test only).
#
# Usage:
#   cd ui/app
#   .\scripts\build-release.ps1
#   .\scripts\build-release.ps1 -ApkOnly
#   .\scripts\build-release.ps1 -DefinesFile dart_defines.prod.json

param(
    [switch]$ApkOnly,
    [string]$DefinesFile = "dart_defines.prod.json"
)

$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

if (-not (Test-Path $DefinesFile)) {
    Write-Host "Missing $DefinesFile - copy dart_defines.prod.example.json and fill AWS_MAP_API_KEY." -ForegroundColor Yellow
    Copy-Item dart_defines.prod.example.json $DefinesFile -ErrorAction SilentlyContinue
    if (-not (Test-Path $DefinesFile)) { exit 1 }
}

if (-not (Test-Path "android\key.properties")) {
    Write-Host "WARNING: android/key.properties not found - release will use DEBUG signing." -ForegroundColor Yellow
    Write-Host "  For Play Store: create keystore + key.properties from android/key.properties.example" -ForegroundColor Yellow
}
elseif (-not (Test-Path "android\upload-keystore.jks")) {
    Write-Host "WARNING: android/upload-keystore.jks missing - check storeFile in key.properties." -ForegroundColor Yellow
}
else {
    Write-Host "Signing: upload keystore (android/key.properties)" -ForegroundColor Green
}

flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$defineArg = "--dart-define-from-file=$DefinesFile"

Write-Host ""
Write-Host "==> Building release APK ($DefinesFile)..." -ForegroundColor Cyan
flutter build apk --release $defineArg
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (-not $ApkOnly) {
    Write-Host ""
    Write-Host "==> Building release App Bundle..." -ForegroundColor Cyan
    flutter build appbundle --release $defineArg
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "  APK:  build/app/outputs/flutter-apk/app-release.apk"
if (-not $ApkOnly) {
    Write-Host "  AAB:  build/app/outputs/bundle/release/app-release.aab"
}
