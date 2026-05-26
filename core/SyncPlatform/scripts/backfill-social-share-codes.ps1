# Backfills ShareCode on Social posts missing one.
# Requires Social.API running (Development or AllowShareCodeBackfillApi=true) and a valid JWT.

param(
    [string]$BaseUrl = "http://localhost:5120",
    [string]$GatewayUrl = "",
    [string]$Token = $env:JWT_TOKEN
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Token)) {
    Write-Error "Set JWT_TOKEN env var or pass -Token (login via IAM first)."
}

$root = if ([string]::IsNullOrWhiteSpace($GatewayUrl)) { $BaseUrl.TrimEnd("/") } else { $GatewayUrl.TrimEnd("/") }
$path = if ([string]::IsNullOrWhiteSpace($GatewayUrl)) {
    "/api/v1/posts/maintenance/backfill-share-codes"
} else {
    "/api/v1/social/posts/maintenance/backfill-share-codes"
}

$uri = "$root$path"
Write-Host "POST $uri"

$response = Invoke-RestMethod -Method Post -Uri $uri -Headers @{
    Authorization = "Bearer $Token"
    Accept        = "application/json"
}

$response | ConvertTo-Json -Depth 6
Write-Host "Done. Updated: $($response.data.updated), Remaining: $($response.data.remaining)"
