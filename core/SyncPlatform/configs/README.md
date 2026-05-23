# Shared configuration (`configs/`)

JWT and baseline logging shared by IAM, Payment, Notification, Roadmap, Exercise, and Gateway.

## Templates (committed)

| Template | Copy to (gitignored) |
|----------|----------------------|
| `appsettings.Shared.json.example` | `appsettings.Shared.json` |
| `appsettings.Shared.Development.json.example` | `appsettings.Shared.Development.json` |

## Setup

From `core/SyncPlatform`:

```powershell
.\scripts\setup-local-config.ps1
```

See [CONFIGURATION.md](../CONFIGURATION.md) for the full onboarding flow.

## Production

Set `Jwt__SecretKey` (and other secrets) via environment variables or a secret store — not via committed JSON.
