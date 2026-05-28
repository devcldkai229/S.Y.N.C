# sync_app — Sync Lifestyle mobile / web client

## Prerequisites

- Flutter SDK 3.11+ (`flutter doctor`)
- Backend: Gateway `:5057`, IAM `:5288` — see [CONFIGURATION.md](../../core/SyncPlatform/CONFIGURATION.md)

```powershell
cd core\SyncPlatform
.\scripts\run-all.ps1
```

## Run

```powershell
cd ui\app
flutter pub get
flutter run -d chrome    # or windows / android
```

API base URL defaults to `http://localhost:5057/api` (Android emulator: `10.0.2.2`).

## Google Sign-In

1. **Google Cloud Console** → OAuth client **Web application** → copy Client ID.
2. Add to IAM `GoogleAuth:ClientIds` in `Iam.API/appsettings.Development.json`.
3. Flutter (already wired for local dev):
   - `web/index.html` → `<meta name="google-signin-client_id" …>`
   - `lib/core/config/app_config.dart` → `defaultGoogleWebClientId`
4. In Google Cloud, add authorized JavaScript origins for Web, e.g. `http://localhost` and your Flutter web port.

Override without editing files:

```powershell
flutter run -d chrome `
  --dart-define=GOOGLE_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com `
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

Flow: Flutter SDK → Google ID token → `POST /api/v1/auth/google` (Gateway → IAM).
