# BÁO CÁO ĐỐI CHIẾU TÀI LIỆU ↔ MÃ NGUỒN

**Ngày rà soát:** {{EFFECTIVE_DATE}} · **Phạm vi:** `core/SyncPlatform/src`, `ai/sync-agent-service`, `ui/app`, `ui/web`
**Mục đích:** chứng minh mọi tuyên bố trong Legal Pack đều có căn cứ trong mã nguồn, và liệt kê các khoảng trống phải xử lý trước khi publish.

> ⚠️ **Tài liệu nội bộ — KHÔNG publish lên web.**

---

## 1. Tuyên bố đã được xác minh ĐÚNG trong mã nguồn

| # | Tuyên bố trong tài liệu | Bằng chứng |
|---|---|---|
| 1 | Không có SDK quảng cáo / analytics bên thứ ba | `ui/app/pubspec.yaml` — không có firebase_analytics, facebook_sdk, appsflyer, adjust, admob |
| 2 | Không dùng Advertising ID | Không có `AD_ID` permission trong `AndroidManifest.xml` |
| 3 | Không thu thập vị trí nền | Manifest chỉ có `ACCESS_FINE_LOCATION` + `ACCESS_COARSE_LOCATION`, **không** có `ACCESS_BACKGROUND_LOCATION` |
| 4 | Ứng dụng chạy HTTPS hoàn toàn | `android:usesCleartextTraffic="false"` |
| 5 | Quyền yêu cầu: Internet, Camera, Micro, Vị trí | Manifest — đúng 5 quyền, không thừa |
| 6 | Không đọc dữ liệu Health Connect / Google Fit | Không có permission `android.permission.health.*`, không có package health |
| 7 | Mật khẩu lưu dạng băm | `User.PasswordHash`; xoá tài khoản set `PasswordHash = string.Empty` |
| 8 | Refresh token lưu dạng băm | `UserDevice.RefreshTokenHash` |
| 9 | AI dùng OpenAI cho mọi tier | `app/config.py` — `MODEL_REGISTRY` toàn bộ provider `openai` (`gpt-4o-mini`, `gpt-4o`, `text-embedding-3-small`) |
| 10 | Có lớp che PII trước khi gửi ra cloud LLM | `app/safety/pii.py` — regex SĐT VN, email, CMND/CCCD, số thẻ |
| 11 | Có phát hiện prompt-injection | `app/safety/injection.py` |
| 12 | **AI không phân tích ảnh** | `app/config.py` — `vision_enabled: bool = False` |
| 13 | Bộ nhớ đệm ngữ nghĩa hết hạn 24 giờ | `semantic_cache_ttl_seconds: int = 86400` |
| 14 | Hành động chờ xác nhận hết hạn 30 phút | `pending_action_ttl_seconds: int = 1800` |
| 15 | Nhật ký AI chỉ lưu siêu dữ liệu, không lưu nội dung thô | `migrations/0001_init.sql` — bảng `ai_turn_audit` ghi rõ *"KHÔNG PII thô"*, cột: trace_id, user_id, session_id, intent, tier, locale |
| 16 | Bộ nhớ dài hạn AI lưu ở Postgres + pgvector | `ai_user_memory` (fact + embedding 1536d) |
| 17 | Cổng xác nhận chi tiêu không thể vô hiệu hoá | `app/knowledge/policies.md` — mục "Không bỏ qua bước xác nhận" |
| 18 | AI không bịa số liệu cá nhân (tool-first) | `policies.md` — mục "Không bịa số — tool-first" |
| 19 | AI tôn trọng dị ứng tuyệt đối | `policies.md` — mục "Tôn trọng dị ứng & ràng buộc người dùng" |
| 20 | AI không chẩn đoán/kê đơn | `policies.md` — mục "AI không phải bác sĩ / chuyên gia y tế" |
| 21 | Hạn mức chi tiêu tự động theo ngày & theo đơn | `UserPreference.MaxAutoOrderLimitDaily`, `MaxAutoOrderLimitPerOrder`, `AutoOrderEnabled` |
| 22 | Lưu lập luận của AI cho giao dịch AI khởi tạo | `Transaction.IsAiInitiated` + `AIReasoningSnapshotJson`; `Order.IsAiInitiated` + `AIReasoningSnapshotJson` |
| 23 | Story tự hết hạn sau 24 giờ | `StoryService.StoryLifetime = TimeSpan.FromHours(24)` |
| 24 | Xoá tài khoản: ẩn danh PII ngay lập tức | `UserMeService.DeleteAccountAsync` |
| 25 | Grace period **30 ngày** | `ScheduledHardDeleteAt = now.AddDays(30)` |
| 26 | Thu hồi toàn bộ phiên khi xoá | Duyệt `UserDevice` → `IsRevoked = true`, xoá token |
| 27 | Hết hạn đăng ký khi xoá | Cascade `POST /api/internal/payment/users/{id}/expire-subscriptions` |
| 28 | Ẩn danh nội dung Social → "Người dùng đã xoá" | `AccountAnonymizationService` — Posts, Comments, Blogs, Stories, BlogComments |
| 29 | Không lưu thông tin thẻ | `Transaction` chỉ có `ExternalReferenceId`, `OrderCode`, `RawProviderPayload`; không có trường số thẻ |
| 30 | `MarketingConsent` mặc định TẮT | `UserMeService.cs:258` — `MarketingConsent = false` |
| 31 | `DataSharingConsent` mặc định TẮT | `UserMeService.cs:257` — `DataSharingConsent = false` |
| 32 | Hạ tầng đặt tại Singapore | `appsettings.json` — `AWS.Region = ap-southeast-1`; Terraform `infra/aws` cùng region |
| 33 | Tệp riêng tư ở bucket không công khai | `Iam.API`/`Social.API` → `Storage.Bucket = sync-private-assets`; public assets tách riêng `sync-pub-assets` |
| 34 | Có mô hình báo cáo nội dung | `ContentReport` (ReporterId, TargetId, TargetType, Reason, Details, Status) + trang admin `ui/web/src/app/admin/content-reports` |
| 35 | Email giao dịch gửi qua Brevo | `Iam.API/appsettings.json` — `Email.Brevo.Host = smtp-relay.brevo.com` |
| 36 | Tìm kiếm web chỉ gửi chuỗi truy vấn | `app/tools/websearch.py` — payload chỉ gồm `api_key` + `query` |
| 37 | Đối tác giao hàng: Ahamove | `Order.API/Controllers` — `webhooks/ahamove` |
| 38 | Bản đồ dùng OpenStreetMap | `ui/app/lib/core/config/aws_map_config.dart` — `tile.openstreetmap.org` |
| 39 | Giới hạn lượt AI theo gói | `SubscriptionPlan.AiUsageLimitPerMonth`, `MaxAiAutoOrdersPerMonth`; `User.AiUsageCount` + `AiUsagePeriodKey` |
| 40 | Play Billing đã có tích hợp | `Payment.API/Controllers/GooglePlayController.cs` — `POST verify`, `POST rtdn`; `GooglePlayAndroidPublisherClient`; `in_app_purchase: ^3.2.3` trong pubspec |

---

## 2. ⛔ KHOẢNG TRỐNG CHẶN PHÁT HÀNH

Đây là những chỗ **tài liệu cam kết nhiều hơn mã nguồn đang làm**. Publish khi chưa xử lý = tuyên bố sai với người dùng và với Google Play.

### 2.1. 🔴 NGHIÊM TRỌNG — Xoá vĩnh viễn sau 30 ngày chưa hoạt động

`AccountHardDeleteHostedService.ProcessDueAsync` chỉ scrub lại `FullName`/`Email` rồi set `ScheduledHardDeleteAt = null`. **Không có bản ghi nào bị xoá.** Sau 30 ngày, toàn bộ `BiometricProfile`, `BiometricHistory`, chấn thương, thuốc, dị ứng, nhật ký ăn/tập, bộ nhớ AI **vẫn còn nguyên** trong DB.

Đây là mục Google Play soi kỹ nhất (*Data deletion*). Chi tiết việc cần làm: xem `05-account-deletion.vi.md` → Phụ lục §B (10 bước, đầy đủ theo từng service và từng collection).

### 2.2. 🔴 NGHIÊM TRỌNG — Cascade xoá là "best-effort", nuốt lỗi

`UserMeService.DeleteAccountAsync` gọi `_deletionCascade.NotifyDeletedAsync` trong `try/catch` và **chỉ log warning khi thất bại**. Nếu Social hoặc Payment tạm sập, nội dung của người dùng **không bao giờ được ẩn danh** và không có cơ chế thử lại.

**Cần:** hàng đợi/outbox + retry có backoff, hoặc job đối soát chạy định kỳ tìm user `Status=Deleted` mà nội dung Social chưa ẩn danh.

### 2.3. 🟠 CAO — `DELETE /api/v1/me` không có bước xác nhận lại

Chỉ cần access token hợp lệ là xoá được tài khoản. Cần thêm xác nhận hai lớp ở UI (nhập lại mật khẩu hoặc gõ chuỗi xác nhận).

### 2.4. 🟠 CAO — Chưa có endpoint xuất dữ liệu (data portability)

Privacy Policy §9 cam kết trả bản sao dữ liệu máy đọc được trong 30 ngày. Hiện chưa có API nào làm việc này.
**Chọn một:** xây endpoint xuất JSON/CSV, **hoặc** sửa tài liệu thành quy trình thủ công có SLA rõ ràng (vẫn phải làm được thật).

### 2.5. 🟠 CAO — SmartPush mặc định BẬT

`UserMeService.cs:259-260` — `SmartPushEnabled = true`, `AllowAiGeneratedNotification = true` cho user mới.

Đây là **opt-out**, không phải opt-in. Vì SmartPush dùng **dữ liệu sức khoẻ** (lịch tập, dinh dưỡng, điểm kiệt sức) để sinh nội dung bằng AI, mặc định bật là rủi ro về cơ sở pháp lý cho dữ liệu nhạy cảm.
**Chọn một:** (a) đổi mặc định thành `false` và xin đồng ý ở onboarding — an toàn nhất; hoặc (b) giữ mặc định bật nhưng phải hiển thị rõ ở onboarding rằng tính năng đang bật + cách tắt, và đổi căn cứ pháp lý trong Privacy Policy §4 từ "sự đồng ý" sang "lợi ích hợp pháp" (yếu hơn với dữ liệu nhạy cảm — không khuyến nghị).

### 2.6. 🟠 CAO — `ContentReport` chưa đo được SLA

Thiếu: mức ưu tiên P0–P3, `ReviewedAt`, `ResolvedAt`, `ReviewerId`, `Action`, `AppealStatus`. `Status` đang là string tự do.
Không có các trường này thì bảng SLA tại Tiêu chuẩn cộng đồng §4.1 **không thể chứng minh** khi có sự cố hoặc khi Google hỏi.
Ngoài ra: chưa có cơ chế **ẩn tạm thời tự động** cho P0/P1, và `UserStatus` chỉ có `Suspended` — không có trạng thái "hạn chế đăng bài N ngày" mà bảng chế tài §4.3 yêu cầu.

### 2.7. 🟡 TRUNG BÌNH — Chưa có job dọn dữ liệu theo thời hạn

Privacy Policy §7 cam kết: log server 90 ngày, `ai_turn_audit` 180 ngày, `ContentReport` 24 tháng. **Chưa có job nào.**
**Chọn một:** viết job dọn, hoặc bỏ các dòng đó khỏi tài liệu.

### 2.8. 🟡 TRUNG BÌNH — Rút tiền ví chưa rõ

`Wallet` + `WalletLedger` có `topup` (`POST /api/internal/wallet/topup`) nhưng **không thấy endpoint rút tiền**.
Nếu người dùng nạp được mà không rút được, **phải nói rõ điều đó trong app tại màn nạp tiền** trước khi họ nạp — nếu không là vi phạm quyền lợi người tiêu dùng. Chính sách hoàn tiền §4.2 đã đánh dấu 🔧 chỗ này.

### 2.9. 🟡 TRUNG BÌNH — Trang pháp lý trên web còn quá sơ sài

| Trang | Số dòng hiện tại |
|---|---|
| `ui/web/src/app/privacy/page.tsx` | 53 |
| `ui/web/src/app/terms/page.tsx` | 46 |
| `ui/web/src/app/account-deletion/page.tsx` | 48 |
| `ui/web/src/app/community-standards/page.tsx` | 39 |

Cần thay bằng nội dung đầy đủ trong Legal Pack, và **tạo thêm** `/health-disclaimer`, `/refund-policy`, `/contact`, cùng bản EN (`/en/...`).

### 2.10. 🟡 TRUNG BÌNH — Email gửi từ Gmail cá nhân

`Iam.API/appsettings.json` → `Email.Brevo.FromEmail = kag40222@gmail.com`, `FromName = "Sync Lifestyle"`.
Gửi thư thay mặt thương hiệu từ địa chỉ Gmail cá nhân qua Brevo sẽ **fail DMARC alignment** → email xác thực tài khoản rơi vào spam, và trông thiếu tin cậy khi Google review.
**Cần:** đổi sang `no-reply@{{WEBSITE}}` và cấu hình SPF + DKIM + DMARC cho domain.

### 2.11. 🔵 THẤP — `AppConfig` còn hardcode domain chưa chốt

`ui/app/lib/core/config/app_config.dart` đang dùng `https://api.synctis.in` và `legalBaseUrl = https://synctis.in`. Nếu domain cuối cùng khác, phải sửa đồng bộ ở: `app_config.dart`, các `appsettings.json` (`PublicBaseUrl`, `VerificationBaseUrl`), Terraform `domain_name`, và toàn bộ `{{WEBSITE}}` trong Legal Pack.

---

## 3. Ghi chú bảo mật ngoài phạm vi pháp lý

`Iam.API/appsettings.json` và `Notification.API/appsettings.json` (bản local, **không được git track** — chỉ `.example` được track, đã kiểm tra bằng `git ls-files`) đang chứa **secret thật ở dạng plaintext**: OpenAI API key, mật khẩu SMTP Brevo, JWT secret, mật khẩu DB.

Không phải sự cố lộ lọt vì file đã được gitignore, nhưng khi lên production cần chuyển toàn bộ sang AWS Secrets Manager / SSM Parameter Store như đã thiết kế trong `infra/aws/modules/secrets`. Khoá OpenAI trong file hiện tại nên được **rotate** trước khi phát hành, vì nó đã tồn tại lâu trong môi trường dev.

---

## 4. Thứ tự khuyến nghị xử lý

| Ưu tiên | Việc | Ước lượng |
|---|---|---|
| 1 | §2.1 Xoá vĩnh viễn thật sự (cascade đủ 8 kho dữ liệu) | 2–3 ngày |
| 2 | §2.2 Cascade có retry/outbox | 1 ngày |
| 3 | §2.3 Xác nhận hai lớp khi xoá tài khoản | 2 giờ |
| 4 | §2.5 Quyết định mặc định SmartPush | 2 giờ |
| 5 | §2.9 Viết đầy đủ 7 trang pháp lý × 2 ngôn ngữ trên `ui/web` | 1 ngày |
| 6 | §2.10 Domain + email + SPF/DKIM/DMARC | 0.5 ngày |
| 7 | §2.6 Nâng cấp `ContentReport` + SLA đo được | 2 ngày |
| 8 | §2.4 Endpoint xuất dữ liệu | 1 ngày |
| 9 | §2.7 Job dọn dữ liệu theo thời hạn | 0.5 ngày |
| 10 | §2.8 Làm rõ / triển khai rút tiền ví | tuỳ quyết định |

**Mục 1–6 là điều kiện cần để nộp Google Play mà không bị từ chối vì lý do chính sách.**
