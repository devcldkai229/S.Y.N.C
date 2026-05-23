# Shared configuration (`configs/`)

JWT and baseline logging linked into IAM, Payment, Notification, Roadmap, Exercise, and Gateway.

| File | Description |
|------|-------------|
| `appsettings.Shared.json` | Issuer, audience, token lifetimes — `SecretKey` is `""` in Git |
| `appsettings.Shared.Development.json` | Dev logging + dev issuer/audience — **fill `SecretKey` locally** |

See [CONFIGURATION.md](../CONFIGURATION.md).
