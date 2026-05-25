# Moves non-empty secrets from tracked appsettings*.json into gitignored *.local.json,
# then resets tracked files to empty placeholders so git commit succeeds.
#
# Usage (from core/SyncPlatform):
#   .\scripts\migrate-secrets-to-local.ps1
#   .\scripts\migrate-secrets-to-local.ps1 -WhatIf

param([switch]$WhatIf)

$ErrorActionPreference = "Stop"
$SyncRoot = Split-Path -Parent $PSScriptRoot

$targets = Get-ChildItem -Path $SyncRoot -Recurse -Filter 'appsettings*.json' -File |
    Where-Object {
        $_.FullName -notmatch '\\bin\\|\\obj\\' -and
        $_.Name -notlike '*.local.json' -and
        $_.Name -notin @('appsettings.Production.json', 'appsettings.Staging.json')
    }

function Get-LocalPath([string]$appsettingsPath) {
    if ($appsettingsPath -match '\.Development\.json$') {
        return $appsettingsPath -replace '\.Development\.json$', '.Development.local.json'
    }
    return $appsettingsPath -replace '\.json$', '.local.json'
}

function Merge-JsonObject([hashtable]$into, [object]$from) {
    if ($null -eq $from) { return $into }
    if ($from -is [System.Management.Automation.PSCustomObject]) {
        foreach ($prop in $from.PSObject.Properties) {
            $name = $prop.Name
            $val = $prop.Value
            if ($val -is [System.Management.Automation.PSCustomObject]) {
                if (-not $into.ContainsKey($name)) { $into[$name] = @{} }
                $nested = $into[$name]
                if ($nested -isnot [hashtable]) { $nested = @{}; $into[$name] = $nested }
                Merge-JsonObject $nested $val | Out-Null
            }
            elseif ($val -is [System.Array]) {
                $into[$name] = @($val)
            }
            else {
                $into[$name] = $val
            }
        }
    }
    return $into
}

function Clear-SecretsInPlace([object]$node) {
    if ($null -eq $node) { return }
    if ($node -is [string] -or $node -is [bool] -or $node -is [int] -or $node -is [long] -or $node -is [double]) { return }
    if ($node -is [System.Array]) {
        foreach ($item in $node) { Clear-SecretsInPlace $item }
        return
    }
    if ($node.GetType().FullName -ne 'System.Management.Automation.PSCustomObject') { return }

    foreach ($prop in @($node.PSObject.Properties)) {
        $name = $prop.Name
        if ($name.StartsWith('_')) { continue }

        if ($name -eq 'ConnectionStrings') {
            foreach ($cs in $prop.Value.PSObject.Properties) {
                $cs.Value = ''
            }
            continue
        }
        if ($name -eq 'ClientIds') {
            $prop.Value = @()
            continue
        }
        if ($name -in @('SecretKey', 'Password', 'ApiKey', 'ChecksumKey', 'ClientId', 'UserName', 'FromEmail')) {
            if ($prop.Value -is [string]) { $prop.Value = '' }
            continue
        }
        Clear-SecretsInPlace $prop.Value
    }
}

foreach ($file in $targets) {
    $raw = Get-Content -Raw -Path $file.FullName
    if ([string]::IsNullOrWhiteSpace($raw)) { continue }

    $json = $raw | ConvertFrom-Json
    $localPath = Get-LocalPath $file.FullName

    $localHash = @{}
    if (Test-Path $localPath) {
        $existing = Get-Content -Raw $localPath | ConvertFrom-Json
        $localHash = Merge-JsonObject @{} $existing
    }
    $localHash = Merge-JsonObject $localHash $json

    $localObj = $localHash | ConvertTo-Json -Depth 20
    $clean = $raw | ConvertFrom-Json
    Clear-SecretsInPlace $clean
    $cleanJson = ($clean | ConvertTo-Json -Depth 20)

    if ($WhatIf) {
        Write-Host "[WhatIf] $($file.FullName) -> secrets to $localPath, tracked file cleared"
        continue
    }

    $localDir = Split-Path $localPath -Parent
    if (-not (Test-Path $localDir)) { New-Item -ItemType Directory -Path $localDir -Force | Out-Null }

    [System.IO.File]::WriteAllText($localPath, $localObj + "`n")
    [System.IO.File]::WriteAllText($file.FullName, $cleanJson + "`n")
    Write-Host "OK: $($file.Name) -> $(Split-Path $localPath -Leaf), tracked cleared" -ForegroundColor Green
}

if (-not $WhatIf) {
    Write-Host ""
    Write-Host "Done. Run: git add . && git commit" -ForegroundColor Cyan
    Write-Host "Secrets are only in *.local.json (gitignored)." -ForegroundColor Yellow
}
