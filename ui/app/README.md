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

**Never put the Android OAuth client ID into `GOOGLE_CLIENT_ID` for web builds** — that causes `Error 401: invalid_client` / “no registered origin”.

| Use | Client type | Where |
|-----|-------------|--------|
| Browser GIS / Flutter web | **Web** (`…n76f7r…`) | `GOOGLE_CLIENT_ID`, `web/index.html` meta |
| Mobile idToken audience | **Web** (same) | `GOOGLE_SERVER_CLIENT_ID` / `serverClientId` |
| Android package + SHA-1 | **Android** (`…4brct5…`) | Cloud Console only (not dart-define for web) |

1. **Google Cloud Console** → OAuth client **Web application**.
2. **Authorized JavaScript origins** (exact scheme+host+port, no path):
   - Dev: `http://localhost`, `http://localhost:<flutter-web-port>`, maybe `http://127.0.0.1:<port>`
   - Prod web: `https://synctis.in`, `https://www.synctis.in` if used
3. **Android client**: package `com.sync.sync_app` + debug/release SHA-1 fingerprints.
4. Add Web (and Android if used as `aud`) to IAM `GoogleAuth:ClientIds` / SSM `/sync/{env}/auth/google-client-ids`.
5. Flutter defaults: `web/index.html` meta + `lib/core/config/app_config.dart` (`defaultGoogleWebClientId`).

Override without editing files:

```powershell
flutter run -d chrome `
  --dart-define=GOOGLE_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com `
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

Release: copy `dart_defines.prod.example.json` → `dart_defines.prod.json` (both Google IDs = **Web** client).

Flow: Flutter SDK → Google ID token → `POST /api/v1/auth/google` (Gateway → IAM).
