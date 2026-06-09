# One-time (per clone): wire repo git hooks to block secret commits.
# Usage: .\scripts\install-git-hooks.ps1

$ErrorActionPreference = "Stop"

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) {
    Write-Error "Run from inside the git repository."
}

Set-Location $repoRoot

git config core.hooksPath .githooks

$preCommit = Join-Path $repoRoot ".githooks\pre-commit"
if (-not (Test-Path $preCommit)) {
    Write-Error "Missing .githooks/pre-commit"
}

# Git for Windows respects executable bit; ensure LF for hook script
Write-Host "Git hooks path set to: .githooks" -ForegroundColor Green
Write-Host "Pre-commit will block non-empty secrets in appsettings*.json." -ForegroundColor Cyan
Write-Host ""
Write-Host "Validate current files:" -ForegroundColor Yellow
& (Join-Path $repoRoot "core\SyncPlatform\scripts\validate-committed-appsettings.ps1")
