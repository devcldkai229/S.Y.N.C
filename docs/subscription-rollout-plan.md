# Kế hoạch triển khai chức năng Subscription (bản cuối)

> **Cập nhật:** 2026-06-09. Mọi quyết định phạm vi đã chốt — đây là bản tham chiếu để thực hiện.

## 0. Quyết định đã chốt

| Vấn đề | Chốt |
|--------|------|
| Surface mua | **Cả Flutter app và Web** |
| Mô hình thanh toán | **Một lần + gia hạn thủ công** (không auto-renew), qua **PayOS** |
| Gói | **Free 0đ** (tier mặc định, không có plan row, không mua) + **Premium 99k/tháng** (1 plan row) |
| Chu kỳ | **Chỉ theo tháng** — bỏ gói năm đợt này |
| Khuyến mãi | **Có áp mã/chiến dịch vào checkout** |
| Premium mở khóa gì | **Chỉ AI cá nhân hóa thông báo SmartPush** (các thứ khác để sau) |
| Map plan→tier | **Suy ra** (sub active = Premium) — không thêm cột; thêm sau nếu có Ultra |
| Bộ đếm quota AI | **HOÃN** — làm cùng lúc với tính năng AI người-dùng-gọi (chưa tồn tại) |
| Huỷ gói | **Giữ Premium tới hết hạn**; chỉ tắt gia hạn; hạ tier ở mốc hết hạn |
| Auth web khách | **Làm trong đợt này** (web hiện chỉ có auth admin) |

**Quy ước nền (giữ nguyên):** client chỉ gọi Gateway `:5057`; gọi liên service nội bộ qua `api/internal/...` + header `X-Internal-Api-Key`; controller trả `ApiResponse<T>`; lỗi ném domain exception cho `GlobalExceptionHandler`; enum serialize dạng string.

---

## 1. Hiện trạng

| Mảng | Đã có | Còn thiếu |
|------|-------|-----------|
| **Backend Payment** | CRUD plans/subscriptions/promotions; PayOS `create-link` + `webhook` (verify chữ ký, idempotent, kích hoạt/gia hạn `UserSubscription`) | (a) Không sync tier về IAM; (b) Không có job hết hạn; (c) `create-link` chưa nhận mã KM; (d) Không có endpoint tra trạng thái giao dịch |
| **IAM** | `User.SubscriptionTier` (Free/Premium/Ultra) đã có; pattern internal endpoint + `InternalApiKeyMiddleware` | Chưa có endpoint set tier cho Payment gọi; SmartPush context chưa gửi tier |
| **Web admin** | Quản lý subscription-plans & promotions | — |
| **Web khách** | `/register` (khách, OTP+Google); `/subscription` marketing tĩnh | **Chưa có trang login khách**; auth store thuần admin (`sync_admin_token`); chưa nối checkout; chưa có `/payment/success|cancel` |
| **Flutter** | Màn subscription gọi API thật, mở PayOS checkout ngoài app | Sau thanh toán không quay lại/poll/refresh; chưa hiển thị gói active + nút huỷ; còn toggle gói năm (phải bỏ) |

---

## 2. Luồng mục tiêu (end-to-end)

```
[App/Web]  POST /api/v1/payment/payos/create-link { planId, couponCode? }
   → Payment: validate plan + (nếu có) validate coupon → tính giá cuối
   → tạo Transaction(Pending) → gọi PayOS → trả checkoutUrl + qrCode
[App/Web]  mở checkoutUrl (PayOS)
[PayOS]    user trả tiền → redirect ReturnUrl/CancelUrl + gọi webhook (server-to-server)
[Payment]  webhook → verify chữ ký, idempotent → Transaction=Succeeded
   → ActivateSubscriptionAsync (luôn chu kỳ tháng) → tăng UsageCount của coupon
   → gọi IAM internal: set tier=Premium
[App/Web]  trang/màn return poll GET .../transactions/{id} → Succeeded → cập nhật UI
[Cron]     job hết hạn: UserSubscription quá ExpiredAt → Expired → gọi IAM set tier=Free
```
> **Test local không cần tiền/tunnel:** thay bước "PayOS gọi webhook" bằng endpoint giả lập `POST /payments/dev/confirm/{orderCode}` (DEV-only, xem P0).

---

## 3. Phân rã công việc

### Phase 0 — Chuẩn bị (0.5 ngày)
- [x] **DB Payment đã dựng** *(2026-06-09)*: dùng chung container `sync-postgres` (:5434), database `sync_payment`. Payment **không auto-migrate** → đã `dotnet ef database update` thủ công. *Mỗi lần reset DB phải chạy lại.*
- [ ] **Seed 1 gói Premium**: 1 row `IsActive=true`, `Name="Premium"`, `MonthlyPrice=99000`, `Currency="VND"`. (Free không seed — là tier mặc định.) Cách: admin UI/API, hoặc thêm `PaymentSeedData`.
- [ ] **Config Payment→IAM**: `Services:IamBaseUrl` (`http://localhost:5288`) + `InternalApiKey` (trùng giá trị IAM). Cập nhật cả `appsettings*.json.example`.
- [ ] **Endpoint giả lập confirm (DEV-ONLY)** ⭐: `POST /api/v1/payments/dev/confirm/{orderCode}` chạy thẳng logic activation (tái dùng `ActivateSubscriptionAsync`), bỏ qua verify chữ ký. **Chặn ngoài Development** (`IWebHostEnvironment.IsDevelopment()` → 404). File riêng `PaymentDevController.cs` để dễ xoá khi lên prod.

### Phase 1 — Đồng bộ tier Payment → IAM (1 ngày) ⭐ ưu tiên cao nhất · KHÔNG đụng schema
Gap khiến mua xong mà các service khác không "thấy" Premium. Dùng cột `User.SubscriptionTier` đã có.
- [ ] **IAM**: `InternalSubscriptionController` (`POST /api/internal/subscriptions/tier` body `{ userId, tier }`) theo pattern `InternalGamificationController`; service cập nhật `User.SubscriptionTier`.
  - Files: `Iam.API/Controllers/InternalSubscriptionController.cs`, `Iam.Application/Abstractions/I*Service.cs` + service + DTO.
- [ ] **Payment**: typed client `IamSubscriptionClient` trong `Payment.Infrastructure/Clients/` (mẫu `Iam.Infrastructure/Clients/NotificationClient.cs`), gửi `X-Internal-Api-Key`; đăng ký DI trong `InfrastructureServiceExtensions`.
- [ ] **Suy ra tier**: sub active = Premium. Activate → sync `tier=Premium`; hết hạn → sync `tier=Free` (P2).
- [ ] Gọi client trong `PayosPaymentService.ActivateSubscriptionAsync`; nuốt lỗi mạng + log + retry nhẹ (không làm fail webhook).
- **Acceptance:** mua (hoặc dev-confirm) thành công → `User.SubscriptionTier`=Premium; `/api/v1/me` phản ánh đúng.

### Phase 1B — Bật Premium cho SmartPush (0.5 ngày) · KHÔNG đụng schema
> Premium → thông báo do DeepSeek cá nhân hóa; Free → thông báo mẫu. Móc `SmartPushAiUsagePolicy` rule #4 đã có nhưng đọc field tier mà IAM **không gửi** (`IamSmartPushContextDto` thiếu) → luôn null.
- [ ] Thêm `SubscriptionTier` vào `IamSmartPushContextDto` (`Iam.Application/DTOs/SmartPushDtos.cs`).
- [ ] Map `User.SubscriptionTier.ToString()` vào context trong `InternalSmartPushService.GetSmartPushContextAsync` (~dòng 84). Notification đã đọc sẵn `iamContext.SubscriptionTier`.
- **Acceptance:** user Premium → `SmartPushAiUsagePolicy.ShouldUseAi` trả `true` (rule #4); verify qua `api/internal/smart-push/context/{userId}` thấy tier đúng.
> ⚠️ **Lưu ý sản phẩm:** lợi ích "ngầm" — người dùng không thấy khác biệt rõ ngay. Cân nhắc thêm 1 tính năng "thấy được" ở đợt sau.

### Phase 2 — Hết hạn & hạ tier (1 ngày)
- [ ] **Background job** trong `Payment.API` (`BackgroundService`, ~mỗi giờ): `UserSubscription` `Active` có `ExpiredAt < now` → set `Expired` → gọi IAM set `tier=Free` (nếu user không còn gói active khác).
- [ ] `GetActiveByUserIdAsync` lọc thêm `ExpiredAt > now` (phòng job chưa chạy).
- [ ] **Huỷ gói (đã chốt: giữ tới hết hạn)**: `CancelSubscriptionAsync` chỉ set `AutoRenew=false` + `Status=Cancelled` + lý do, **giữ `ExpiredAt` nguyên**, **KHÔNG hạ tier ngay**. Tier hạ về Free khi job hết hạn chạm `ExpiredAt`. (→ `GetActiveByUserIdAsync` coi `Cancelled` mà còn hạn vẫn là "đang Premium".)
- **Acceptance:** set `ExpiredAt` quá khứ → sau 1 chu kỳ job: status=Expired, tier IAM=Free. Huỷ gói còn hạn → vẫn Premium tới hết hạn rồi mới về Free.

### Phase 3 — Áp khuyến mãi + endpoint trạng thái (1.5 ngày)
> Bỏ gói năm → activation luôn theo tháng → **lỗi "đoán chu kỳ theo tiền" tự biến mất**, KHÔNG cần cột `Transaction.BillingCycle`.
- [ ] **DTO**: thêm `CouponCode?` vào `CreatePaymentLinkRequest` (bỏ field `BillingCycle` hoặc luôn Monthly).
- [ ] **Validate + tính giá** trong `create-link`: có coupon → tìm `PromotionCampaign` theo `CouponCode` đang `IsActive`, trong `StartsAt..EndsAt`, đạt `MinimumSpend`, còn lượt (`UsageCount < UsageLimit`); áp theo `PromotionType` → `finalAmount`; lưu coupon + `finalAmount` vào Transaction; gửi `finalAmount` cho PayOS.
- [ ] **Schema**: `PromotionCampaign.UsageCount` (int) + (tuỳ chọn) `Transaction.CouponCode?` cho audit → migration Payment + `dotnet ef database update` thủ công.
- [ ] Tăng `UsageCount` khi webhook/dev-confirm `Succeeded`.
- [ ] **Endpoint trạng thái**: `GET /api/v1/payments/transactions/{id}` (hoặc `/by-order-code/{orderCode}`) trả `{ status }`, chỉ owner. Tạo `TransactionsController`.
- **Acceptance:** coupon hợp lệ → giá PayOS đã giảm; coupon sai/hết hạn/hết lượt → lỗi rõ; endpoint trạng thái trả đúng Pending→Succeeded.

### Phase 4 — Web: customer auth + checkout + return (2 ngày)
- [ ] **Auth khách (làm trong đợt này)**: web hiện chỉ có auth admin (`sync_admin_token`, store admin-only) và có `/register` nhưng **thiếu trang login khách**.
  - Tạo `/login` (khách) gọi `/api/v1/auth/login`; lưu token riêng `sync_user_token` (tách khỏi admin).
  - Customer auth store + biến thể `api` dùng `sync_user_token` cho các call mua (đừng dùng nhầm token admin).
- [ ] **Nối checkout**: trang `/subscription` (hoặc `PricingSection`) load plan thật từ Gateway → ô nhập mã KM → gọi `create-link` → mở `checkoutUrl`. Service + hook mới trong `ui/web/src/services` + `src/hooks`.
- [ ] **Trang return**: `ui/web/src/app/payment/success/page.tsx` + `.../cancel/page.tsx` (PayOS đang trỏ về `localhost:3000/payment/success|cancel`). Success poll endpoint trạng thái (P3) tới `Succeeded`; cancel báo huỷ + thử lại.
- **Acceptance:** khách login web → chọn Premium → (nhập mã) → PayOS → quay lại `/payment/success` thấy "đã kích hoạt".

### Phase 5 — Flutter: hoàn thiện sau-thanh-toán (1.5 ngày)
- [ ] **Bỏ gói năm**: gỡ `_BillingToggle` + tham số `yearly` (chỉ còn theo tháng) trong `subscription_screen.dart` + `subscription_api_service.dart`.
- [ ] **Ô nhập mã KM**, truyền `couponCode` vào `createPaymentLink`.
- [ ] **Quay lại app & xác nhận**: app resume → poll `/user-subscriptions/me/active` (hoặc trạng thái giao dịch) → active thì hiện "Đã nâng cấp"; có nút "Tôi đã thanh toán → kiểm tra". *(Deep link để sau.)*
- [ ] **Hiển thị gói active** (`getActiveSubscription`) + ngày hết hạn + **nút Huỷ** (`/user-subscriptions/me/cancel`); nêu rõ "huỷ vẫn dùng tới hết hạn".
- **Acceptance:** thanh toán xong, quay lại app thấy Premium + hạn dùng; huỷ được (vẫn Premium tới hết hạn).

### Phase 6 — Gateway & docs (0.5 ngày)
- [ ] Route `/api/v1/payment/**` (prefix rewrite) đã phủ endpoint mới; chỉ sửa `Gateway/appsettings.json` nếu thêm path top-level mới. Đảm bảo `/auth/login` đã có route cho web khách.
- [ ] Cập nhật `core/SyncPlatform/src/Documents/APIs/api.md`: create-link (coupon), transaction status, internal subscriptions/tier.

### Phase 7 — Test & rollout (1 ngày)
- [ ] E2E **local** qua dev-confirm: mua → kích hoạt → tier=Premium → SmartPush bật AI; coupon hợp lệ/sai; huỷ giữ tới hết hạn; hết hạn → Free.
- [ ] E2E **thật** (nghiệm thu): tunnel (ngrok) phơi Gateway `:5057` → đăng ký webhook `<public>/api/v1/payment/payos/webhook` trên PayOS → trả 1 khoản nhỏ thật; test idempotency (PayOS gọi lại).
- [ ] Bảo mật: webhook `AllowAnonymous` + verify chữ ký; endpoint trạng thái chỉ owner; internal endpoint chặn thiếu/sai key; dev-confirm trả 404 ngoài Dev.
- [ ] **Trước prod**: thay PayOS ClientId/ApiKey/ChecksumKey thật; ReturnUrl/CancelUrl theo domain thật; **xoá/khoá** `PaymentDevController`.

---

## 4. Thay đổi schema
- **Khối lõi P0–P2: KHÔNG có thay đổi schema** (dùng `User.SubscriptionTier` đã có; tier suy ra; P1C hoãn).
- **Phase 3 (Payment)**: `PromotionCampaign.UsageCount` (+ tuỳ chọn `Transaction.CouponCode?`). *(Không cần `BillingCycle` vì đã bỏ gói năm.)*
- **Hoãn** (làm cùng tính năng AI sau): IAM `User.AiUsageCount` + `User.AiUsagePeriodKey` cho quota AI.

> Payment **không auto-migrate** → sau migration P3 phải `dotnet ef database update --project Payment.Infrastructure --startup-project Payment.API`. IAM auto-migrate lúc startup.

## 5. Rủi ro / điểm còn mở (không chặn khối lõi)
- **Đồng bộ tier bị lệch nếu call IAM lỗi**: mua xong nhưng sync thất bại → user trả tiền mà vẫn Free. Mitigation: log + retry; cân nhắc job reconcile (đối chiếu sub active ↔ tier) ở đợt sau.
- **Giá trị Premium "ngầm"** (chỉ SmartPush): xem lưu ý P1B.
- **PayOS production**: credentials thật + webhook public + xoá dev-confirm (P7).
- **Quota AI**: hoãn — khi build tính năng AI mới làm bộ đếm (2 cột trên `User`, chỉ Free chạm tới).

## 6. Thứ tự & ước lượng
**Khối lõi đợt này = P0 + P1 + P1B (~2 ngày, 0 schema)** → "mua Premium" có tác dụng thật.
Đầy đủ: P0 → **P1** → **P1B** → P2 → P3 → P4 → P5 → P6/P7. P4 và P5 song song được sau P3.
Ước lượng thô: **~8 ngày-người**.
