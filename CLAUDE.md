# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> Repo docs are written in Vietnamese; the team communicates in Vietnamese. Code, identifiers, and API contracts are in English.

## What this is

**Sync — Lifestyle Automation Platform**: a fitness/wellness product made of three deployables that all live in this monorepo:

| Path | Stack | Role |
|------|-------|------|
| `core/SyncPlatform` | .NET 10, microservices behind a YARP gateway | Backend APIs |
| `ui/web` | Next.js 16 (App Router), React 19, TS, Tailwind v4 | **Admin dashboard** + landing/marketing site |
| `ui/app` | Flutter (Dart SDK 3.11) | Mobile/web client app for end users |

Both UIs talk **only** to the Gateway at `http://localhost:5057` — never directly to individual services.

## Backend architecture (`core/SyncPlatform`)

Solution file: `SyncPlatform.slnx`. Seven services under `src/Services/`, each a separate ASP.NET app with its **own database and port**. A YARP **Gateway** (`src/Gateway`, port 5057) is the single public entry point.

| Service | Port | Storage | Notes |
|---------|------|---------|-------|
| IAM | 5288 | PostgreSQL | Auth, users, profiles, gamification, shop, achievements. Auto-seeds on startup. |
| Payment | 5084 | PostgreSQL | Subscriptions, PayOS integration + webhook |
| Roadmap | 5118 | MongoDB | Training roadmaps, sessions, activity |
| Exercise | 5187 | MongoDB | Exercise catalog, workout templates, motion assets (MinIO) |
| Notification | 5106 | MongoDB | Notifications, smart push, DeepSeek AI client |
| Social | 5120 | MongoDB | Social feed, posts, comments |
| Marketplace | — | — | **Stub only** (`Class1.cs` placeholders); not wired into `run-all.ps1` |

**Each service follows Clean Architecture with 4 projects** (e.g. `Iam.API` / `Iam.Application` / `Iam.Domain` / `Iam.Infrastructure`):
- `*.Domain` — entities, enums, repository interfaces. PostgreSQL entities extend `BaseAuditableEntity`; MongoDB entities extend `BaseMongoEntity` (see `libs/Libs.Shared`).
- `*.Application` — services, DTOs, mappers, validation, abstractions. Controllers return `ApiResponse<T>` / `PagedApiResponse<T>`.
- `*.Infrastructure` — EF Core (`*DbContext`) or Mongo context, repository implementations, external clients, seed data.
- `*.API` — controllers, `Program.cs`, `GlobalExceptionHandler`, middleware.

**Shared libraries** (`core/SyncPlatform/libs/`):
- `Libs.Auth` — JWT auth (`AddSyncJwtAuthentication` / `UseSyncJwtAuthentication`), health checks, shared config loader (`AddSharedConfiguration`), auth policies/headers.
- `Libs.Shared` — base entities and cross-service enums.
- `Contract` — shared contracts (mostly placeholder).

### Cross-cutting conventions
- **Gateway routing** (`src/Gateway/appsettings.json` → `ReverseProxy`): two styles — *passthrough* (`/api/v1/auth`, `/api/v1/me`, `/api/v1/biometrics`, `/api/v1/users/{id}/public-profile` → IAM as-is) and *prefix rewrite* (`/api/v1/{service}/**` strips the prefix, re-adds `/api/v1`). When adding/renaming an endpoint, update the route map here too. Full table in `src/Documents/APIs/api.md`.
- **Auth**: Gateway validates the JWT once at the edge, forwards the Bearer token downstream, and injects `X-User-*` headers (correlation only, not authorization — see `Gateway/Transforms/UserClaimsTransformProvider.cs`). Routes opt in via `AuthorizationPolicy: AuthenticatedUser`. The Gateway also rate-limits (120/min authenticated by user, 30/min anonymous by IP).
- **Inter-service calls are synchronous HTTP** via typed clients in `*.Infrastructure/Clients/` (e.g. Social → IAM gamification, Notification → IAM/Roadmap/DeepSeek). They hit `/api/internal/...` endpoints guarded by `InternalApiKeyMiddleware` (`X-Internal-Api-Key` header, value from `InternalApiKey` config). RabbitMQ/Redis are in docker-compose but the code path is HTTP, not a message bus.
- **Errors**: throw domain exceptions from `*.Application/Exceptions/` (`NotFoundException`, `ConflictException`, etc.); `GlobalExceptionHandler` maps them to `ApiResponse` JSON. Model-validation failures are reshaped into `ApiResponse.FailureResponse` in `Program.cs`.
- **Enums** serialize as strings (`JsonStringEnumConverter`).

## Configuration (read before running the backend)

Secrets live in **gitignored** `appsettings*.json`; only `*.json.example` templates are committed. See `core/SyncPlatform/CONFIGURATION.md`.

```powershell
# From repo root — copies every *.json.example -> *.json (skips existing; -Force to overwrite)
.\core\SyncPlatform\scripts\setup-appsettings.ps1
```

Then fill in:
1. `core/SyncPlatform/configs/appsettings.Shared.Development.json` → `Jwt:SecretKey` (≥ 32 chars) — shared JWT/logging linked into every service via `<Content Include>` in each `.API.csproj`.
2. Each service's `appsettings.Development.json` → connection strings, `InternalApiKey`, PayOS, Google, SMTP, MinIO, DeepSeek.

## Common commands

### Backend
```powershell
cd core/SyncPlatform
.\scripts\setup-appsettings.ps1          # first-time config
docker compose -f ..\..\infra\docker\docker-compose.yml up -d   # Postgres :5434, Mongo :27018, RabbitMQ, Redis, MinIO :9000/:9001
.\scripts\run-all.ps1                     # builds all services, then launches each in its own window
.\scripts\run-all.ps1 -SkipBuild          # relaunch without rebuild
.\scripts\stop-all.ps1                    # kill processes on the service ports

dotnet build core/SyncPlatform/SyncPlatform.slnx     # build everything
dotnet run --project core/SyncPlatform/src/Services/Iam/Iam.API   # run one service
```
- Postgres is mapped to host **:5434** and Mongo to **:27018** to avoid clashing with locally-installed DBs.
- IAM/Roadmap/Exercise **auto-seed on startup** (migrations + data, idempotent) — no manual SQL. Dev seed users (`IamSeedData.DefaultDevPassword = Sync@12345`): `admin@sync.local` (SystemAdmin), `demo@sync.local`, `partner@sync.local`, `dev.seed@sync.local`.
- Each service exposes Swagger at `/swagger` and `/health` in Development.
- EF migrations: `dotnet ef migrations add <Name> --project <Service>.Infrastructure --startup-project <Service>.API` (PostgreSQL services only).
- No automated test projects exist in the backend yet.

### Web admin (`ui/web`)
```powershell
cd ui/web
npm install
npm run dev        # http://localhost:3000
npm run build
npm run lint       # eslint (flat config, eslint-config-next)
```
- API base from `NEXT_PUBLIC_API_URL` (defaults to `http://localhost:5057`); see `src/services/api.ts`.
- Auth token stored in `localStorage["sync_admin_token"]`; a 401 clears it and redirects to `/admin/login`. State via Zustand (`src/stores/`), server state via TanStack Query (hooks in `src/hooks/admin/`), forms via react-hook-form + Zod (`src/lib/validations/`), UI is shadcn (`src/components/ui/`).
- `/admin/*` routes are gated client-side by `src/app/admin/layout.tsx`.

### Flutter app (`ui/app`)
```powershell
cd ui/app
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # codegen: freezed, json_serializable, retrofit
flutter run                                    # device/emulator
flutter run --dart-define=BASE_URL=http://10.0.2.2:5057/api # Android emulator -> host gateway
flutter test
flutter analyze
```
- Architecture: feature-first under `lib/features/<feature>/` with BLoC/Cubit state management; shared infra in `lib/core/` (Dio client + auth interceptor, DI via get_it in `core/utils/injection.dart`, routing via go_router). API base defaults to `:5057/api` (`10.0.2.2` on Android). Localized (en/vi) in `lib/l10n/`.

## Reference docs in repo
- `core/SyncPlatform/CONFIGURATION.md` — full setup/secrets flow.
- `core/SyncPlatform/src/Documents/APIs/api.md` — API reference + Gateway route table.
- `domain.md` — every entity and enum across services, with storage mapping.
- `onboarding.txt`, `setting-profile.txt`, `calculate.txt` — domain notes (onboarding flow, profile settings, biometric target formulas).
