# APK regression checklist (prod)

Use this after deploying backend fixes and building a new release APK:

```powershell
cd ui/app
flutter build apk --release --dart-define-from-file=dart_defines.prod.json
```

APK output: `ui/app/build/app/outputs/flutter-apk/app-release.apk`

## 1. Register + OTP email

1. Open app → **Đăng ký** with a new email.
2. On verify screen, hint should say **6-digit code from email** (no IAM/dev log text).
3. If Brevo SMTP is configured on prod IAM:
   - Email arrives with OTP → enter code → registration completes.
4. If email service is down:
   - Show friendly message: *"Không thể gửi email xác minh…"* (no Brevo/SMTP/stack trace).

## 2. Login

| Flow | Expected |
|------|----------|
| Email + password (verified account) | Login succeeds, home loads |
| Google Sign-In (if OAuth not configured) | Friendly message + suggestion to use email/password (no SHA-1/OAuth Console instructions) |
| Wrong password | *"Email hoặc mật khẩu không đúng"* |

## 3. Roadmap / custom workout

1. Open **Workouts** → **AI Roadmap** tab.
2. No Mongo `E11000` / duplicate key / stack trace on screen.
3. If roadmap load fails → generic *"Could not load your roadmap"* or sync message.
4. **Tạo custom workout** → AI generate session:
   - Success: exercises appear.
   - RCM not indexed: *"Gợi ý bài tập AI tạm thời chưa sẵn sàng"* (no "admin reindex").

## 4. CYN AI chat

1. Send a simple message.
2. On network/API error → friendly bubble text (no raw exception).
3. Empty response without error → *"Không nhận được phản hồi từ CYN"* (not technical details).

## 5. Subscription / Premium

1. Open Premium / subscription screen.
2. If Play product `sync_premium_monthly` is not published:
   - *"Gói Premium tạm thời chưa khả dụng trên cửa hàng"* (no Play Console / productId jargon).

## 6. Notifications

1. Open notifications tab while logged in.
2. On connection failure → *"Không kết nối được dịch vụ thông báo…"* (no `run-all.ps1`).

## 7. Backend smoke (ops)

After deploy Roadmap + IAM services:

```bash
# Roadmap service should start even when seed data partially exists
# IAM register should return 400 with friendly message when email send fails
```

## Sign-off

- [ ] No dev hints (IAM log, run-all.ps1, ports, Play Console IDs) visible in UI
- [ ] Auth flows usable with email/password on APK
- [ ] Roadmap tab opens without crash
- [ ] Custom workout AI errors are user-friendly
