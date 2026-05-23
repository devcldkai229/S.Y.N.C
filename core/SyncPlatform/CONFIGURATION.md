# Sync Platform — Local configuration

Repository **does not** contain real `appsettings.json` or `appsettings.Development.json` files.  
Only **templates** (`*.example.json`) are committed.

## After clone (required once per machine)

```powershell
cd core/SyncPlatform
.\scripts\setup-local-config.ps1
```

This copies every `*.example.json` → `*.json` in the same folder (skips if the target already exists).

Then edit the generated files with your local values:

| Area | Files |
|------|--------|
| JWT (all services) | `configs/appsettings.Shared.json`, `configs/appsettings.Shared.Development.json` |
| IAM | `src/Services/Iam/Iam.API/appsettings*.json` |
| Payment | `src/Services/Payment/Payment.API/appsettings*.json` |
| Exercise / Roadmap / Notification | respective `appsettings*.json` |
| Gateway (YARP) | `src/Gateway/appsettings*.json` |

## Manual copy (alternative)

```powershell
copy path\to\appsettings.json.example path\to\appsettings.json
copy path\to\appsettings.Development.json.example path\to\appsettings.Development.json
```

## Environment variables (optional override)

Double underscore maps to nested JSON keys:

```text
Jwt__SecretKey
ConnectionStrings__IamDatabase
PayOS__ApiKey
GoogleAuth__ClientIds__0
Email__Smtp__Password
```

## Git rules

| Committed | Gitignored |
|-----------|------------|
| `*.example.json` | `appsettings.json` |
| | `appsettings.Development.json` |
| | `configs/appsettings.Shared*.json` (non-example) |

Never `git add` local `appsettings.json` — use `git status` and confirm only `*.example.json` is staged.

## Run services

```powershell
.\scripts\run-all.ps1 -Build
```

If `appsettings.Shared.json` is missing, services fail at startup with `FileNotFoundException` — run setup script first.
