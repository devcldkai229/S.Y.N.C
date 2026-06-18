param(
    [int]$Limit = 0,
    [switch]$UsersOnly,
    [switch]$SkipImages
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$repoRoot = Resolve-Path (Join-Path $root "..\..")

function Run-Seed {
    param(
        [string]$Project,
        [string]$Command,
        [string[]]$ExtraArgs
    )

    $args = @("run", "--project", $Project, "--", $Command) + $ExtraArgs
    if ($Limit -gt 0) { $args += @("--limit", $Limit.ToString()) }
    Write-Host ">> dotnet $($args -join ' ')" -ForegroundColor Cyan
    dotnet @args
    if ($LASTEXITCODE -ne 0) { throw "Seed failed: $Command" }
}

$iamProject = Join-Path $root "src\Services\Iam\Iam.SeedTool\Iam.SeedTool.csproj"
$marketProject = Join-Path $root "src\Services\Marketplace\Marketplace.SeedTool\Marketplace.SeedTool.csproj"
$socialProject = Join-Path $root "src\Services\Social\Social.SeedTool\Social.SeedTool.csproj"

# JSON seed files live at repo root; SeedFileLocator walks up from tool output dir.
Write-Host "Repo root (JSON seeds): $repoRoot" -ForegroundColor DarkGray

if (-not $UsersOnly) {
    Run-Seed $iamProject "seed-iam-achievements" @()
    Run-Seed $iamProject "seed-iam-users" @()
    Run-Seed $iamProject "seed-iam-dev" @()
    Run-Seed $marketProject "seed-marketplace" @()
}

Run-Seed $socialProject "seed-social" @()

Write-Host "Seed pipeline completed." -ForegroundColor Green
