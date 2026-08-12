# APK prod regression (after fix-apk-prod-bugs)

## Before testing: ops prerequisites

### Brevo OTP (required for email verification)

SSM currently has placeholder Brevo credentials. Set real values then force-redeploy IAM:

```bash
aws ssm put-parameter --name /sync/prod/mail/brevo-username --type String --value "<brevo-smtp-login>" --overwrite --region ap-southeast-1
aws secretsmanager put-secret-value --secret-id /sync/prod/mail/brevo-password --secret-string "<brevo-smtp-key>" --region ap-southeast-1
aws ssm put-parameter --name /sync/prod/mail/brevo-from-email --type String --value "<verified-sender-in-brevo>" --overwrite --region ap-southeast-1
```

Then `terraform apply` (prod) so IAM task gets `Email__Brevo__Enabled/Host/FromEmail/...`, and redeploy **iam** with the new image.

CloudWatch should show `Brevo SMTP email sent to …` (not `[EMAIL DISABLED]`).

### Google Sign-In `aud`

SSM already has Web+Android IDs comma-separated. **IAM code** now splits commas — redeploy **iam** with this build. No SSM change required if value stays:

`366172488368-n76f7r1ab2joffko6cvf2b3564togekv.apps.googleusercontent.com,366172488368-4brct5chejltaa6rlk42b0pnn2a53skr.apps.googleusercontent.com`

### Media CDN

Redeploy **iam** + **social** (and any service using Libs.Storage upload) after Storage URL fix. New uploads must be `https://cdn.synctis.in/prod/...` (no `sync-pub-assets` in path).

### RCM AI Generate

With RCM healthy:

```bash
# Login SystemAdmin, then:
curl -X POST "https://api.synctis.in/api/v1/ai/admin/reindex" -H "Authorization: Bearer <admin-token>"
```

### Build APK

```powershell
cd ui/app
flutter build apk --release --dart-define-from-file=dart_defines.prod.json
```

## Test checklist

- [ ] Register → OTP email arrives (or friendly error if Brevo still misconfigured)
- [ ] Google Sign-In → no `untrusted aud` (or friendly fallback to email/password)
- [ ] Upload avatar / background → image visible
- [ ] Post story image/video → media visible in feed/viewer
- [ ] CYN chat "hello" → real reply text (not only "đã xử lý…")
- [ ] Custom workout AI Generate → exercises or still-friendly empty message after reindex
- [ ] Profile: no "Hoàn tiền & huỷ gói"
- [ ] Subscription: no "Khôi phục mua hàng Google Play"
- [ ] Map deliver-to: no orange `run-chrome.ps1` hint
