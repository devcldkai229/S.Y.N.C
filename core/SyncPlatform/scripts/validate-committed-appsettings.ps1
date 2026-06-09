# Blocks commits that put secret values into tracked appsettings*.json files.
# Usage:
#   .\validate-committed-appsettings.ps1
#   .\validate-committed-appsettings.ps1 -Staged

param(
    [switch]$Staged
)

$ErrorActionPreference = "Stop"

$repoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) {
    Write-Error "Not inside a git repository."
}

$syncRoot = Join-Path $repoRoot "core\SyncPlatform"

$secretKeyNames = @(
    'SecretKey', 'Password', 'ApiKey', 'ChecksumKey', 'ClientSecret',
    'PrivateKey', 'AccessKey', 'Token', 'RefreshToken', 'SigningKey'
)

$sensitiveIdKeyNames = @('ClientId')

$blockedPatterns = @(
    '(?i)password\s*=\s*[^;\s]+',
    '(?i)mongodb(\+srv)?://[^:]+:[^@]+@',
    '(?i)postgres(ql)?://[^:]+:[^@]+@',
    'sk_live_', 'sk_test_', 'BEGIN PRIVATE KEY', 'AIza[0-9A-Za-z_-]{20,}'
)

function Get-TargetFiles {
    if ($Staged) {
        $names = git -C $repoRoot diff --cached --name-only --diff-filter=ACMR
        return $names | Where-Object {
            $_ -like 'core/SyncPlatform/**/appsettings*.json' -and
            $_ -notlike '*.local.json' -and
            $_ -notlike '*appsettings.Production.json' -and
            $_ -notlike '*appsettings.Staging.json'
        } | ForEach-Object { Join-Path $repoRoot ($_ -replace '/', '\') }
    }

    return Get-ChildItem -Path $syncRoot -Recurse -Filter 'appsettings*.json' -File |
        Where-Object {
            $_.FullName -notmatch '\\bin\\|\\obj\\' -and
            $_.Name -notlike '*.local.json' -and
            $_.Name -notin @('appsettings.Production.json', 'appsettings.Staging.json')
        }
}

function Test-IsSecretPropertyName([string]$name) {
    foreach ($sk in $secretKeyNames) {
        if ($name -eq $sk -or $name.EndsWith($sk)) { return $true }
    }
    foreach ($id in $sensitiveIdKeyNames) {
        if ($name -eq $id) { return $true }
    }
    return $false
}

function Test-IsJsonObject([object]$node) {
    if ($null -eq $node) { return $false }
    if ($node -is [string] -or $node -is [bool] -or $node -is [int] -or $node -is [long] -or $node -is [double] -or $node -is [decimal]) {
        return $false
    }
    if ($node -is [System.Collections.IDictionary]) { return $true }
    return $node.GetType().FullName -eq 'System.Management.Automation.PSCustomObject'
}

function Test-IsJsonArray([object]$node) {
    if ($null -eq $node -or $node -is [string]) { return $false }
    return $node -is [System.Array] -or $node -is [System.Collections.IList]
}

function Get-PropertyNames([object]$node) {
    if ($node -is [System.Collections.IDictionary]) {
        return @($node.Keys)
    }
    return @($node.PSObject.Properties | ForEach-Object { $_.Name })
}

function Get-PropertyValue([object]$node, [string]$name) {
    if ($node -is [System.Collections.IDictionary]) {
        return $node[$name]
    }
    return $node.$name
}

function Test-JsonSecrets([object]$root, [System.Collections.Generic.List[string]]$violations) {
    $stack = [System.Collections.Generic.Stack[object]]::new()
    $pathStack = [System.Collections.Generic.Stack[string]]::new()
    $stack.Push($root)
    $pathStack.Push('')

    while ($stack.Count -gt 0) {
        $node = $stack.Pop()
        $path = $pathStack.Pop()

        if ($null -eq $node) { continue }

        if (Test-IsJsonArray $node) {
            $i = 0
            foreach ($item in @($node)) {
                $stack.Push($item)
                $pathStack.Push("$path[$i]")
                $i++
            }
            continue
        }

        if (-not (Test-IsJsonObject $node)) { continue }

        foreach ($key in Get-PropertyNames $node) {
            $childPath = if ($path) { "$path.$key" } else { [string]$key }
            $value = Get-PropertyValue $node $key

            if ($key -eq 'ConnectionStrings' -and (Test-IsJsonObject $value)) {
                foreach ($csKey in Get-PropertyNames $value) {
                    $csVal = [string](Get-PropertyValue $value $csKey)
                    if (-not [string]::IsNullOrWhiteSpace($csVal)) {
                        $violations.Add("ConnectionStrings:$csKey must be empty in committed config.")
                    }
                }
                continue
            }

            if ($key -eq 'ClientIds' -and (Test-IsJsonArray $value)) {
                foreach ($item in @($value)) {
                    if (-not [string]::IsNullOrWhiteSpace([string]$item)) {
                        $violations.Add("$childPath must be [] in committed config.")
                        break
                    }
                }
                continue
            }

            if (Test-IsSecretPropertyName ([string]$key)) {
                if ($value -is [string] -and -not [string]::IsNullOrWhiteSpace($value)) {
                    $violations.Add("$childPath must be empty in committed config.")
                }
                continue
            }

            if ((Test-IsJsonObject $value) -or (Test-IsJsonArray $value)) {
                $stack.Push($value)
                $pathStack.Push($childPath)
            }
        }
    }
}

$files = @(Get-TargetFiles)
if ($files.Count -eq 0) {
    exit 0
}

$allViolations = [System.Collections.Generic.List[string]]::new()

foreach ($file in $files) {
    if (-not (Test-Path $file)) { continue }

    $raw = Get-Content -Raw -Path $file

    foreach ($pattern in $blockedPatterns) {
        if ($raw -match $pattern) {
            $allViolations.Add("$file : matches blocked secret pattern.")
        }
    }

    try {
        $json = $raw | ConvertFrom-Json
    }
    catch {
        $allViolations.Add("$file : invalid JSON - $_")
        continue
    }

    $fileViolations = [System.Collections.Generic.List[string]]::new()
    Test-JsonSecrets $json $fileViolations
    foreach ($v in $fileViolations) {
        $rel = $file.FullName.Substring($repoRoot.Length + 1)
        $allViolations.Add("${rel}: $v")
    }
}

if ($allViolations.Count -gt 0) {
    Write-Host ""
    Write-Host "COMMIT BLOCKED: secret values in appsettings*.json" -ForegroundColor Red
    Write-Host "Put real values in gitignored appsettings.*.local.json or environment variables." -ForegroundColor Yellow
    Write-Host "See core/SyncPlatform/CONFIGURATION.md" -ForegroundColor Yellow
    Write-Host ""
    foreach ($v in $allViolations) {
        Write-Host "  - $v" -ForegroundColor Red
    }
    Write-Host ""
    exit 1
}

if (-not $Staged) {
    Write-Host "OK: $($files.Count) appsettings file(s) contain no secret values." -ForegroundColor Green
}

exit 0
