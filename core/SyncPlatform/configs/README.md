# Shared configuration (`configs/`)

JWT and baseline settings linked into IAM, Payment, Notification, Roadmap, Exercise, and Gateway.

| Template (Git) | Local file (gitignored) |
|----------------|-------------------------|
| `appsettings.Shared.json.example` | `appsettings.Shared.json` |
| `appsettings.Shared.Development.json.example` | `appsettings.Shared.Development.json` |

```powershell
# From repo root
.\core\SyncPlatform\scripts\setup-appsettings.ps1
```

Then set `Jwt:SecretKey` in `appsettings.Shared.Development.json` (≥ 32 characters).

See [CONFIGURATION.md](../CONFIGURATION.md).
