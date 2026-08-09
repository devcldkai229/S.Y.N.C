# XOÁ TÀI KHOẢN & DỮ LIỆU — SYNC

**Phiên bản:** 1.0 · **Ngày hiệu lực:** {{EFFECTIVE_DATE}}
**Đơn vị cung cấp:** {{LEGAL_ENTITY_NAME}} — {{REGISTERED_ADDRESS}}
**URL công khai (khai báo cho Google Play):** `{{WEBSITE}}/account-deletion`

> Trang này công khai, **không cần cài ứng dụng và không cần đăng nhập để đọc**, theo yêu cầu của Google Play.

---

## 1. Hai cách xoá tài khoản

### Cách 1 — Trong ứng dụng (nhanh nhất)

**Hồ sơ → Cài đặt tài khoản → Xoá tài khoản** → đọc kỹ cảnh báo tại §2 → **Xác nhận xoá** (bước xác nhận hai lớp).

### Cách 2 — Qua web / email (nếu bạn không còn truy cập được ứng dụng)

Gửi email tới **{{PRIVACY_EMAIL}}** với:

- Tiêu đề: **"Yêu cầu xoá tài khoản SYNC"**
- Nội dung: email đã đăng ký tài khoản
- **Gửi từ chính địa chỉ email đã đăng ký** (để chúng tôi xác minh danh tính)

Chúng tôi xác nhận trong **72 giờ** và thực hiện xoá ngay sau khi xác minh.

---

## 2. ⚠️ Việc BẮT BUỘC làm TRƯỚC khi xoá

| Việc | Vì sao |
|---|---|
| **Huỷ gói đăng ký mua qua Google Play** tại Play Store | Xoá tài khoản SYNC **KHÔNG** huỷ gói ở Google — bạn sẽ **vẫn bị tính tiền** kỳ tiếp theo |
| **Rút / dùng hết số dư ví SYNC** | Số dư **không thể khôi phục** sau khi xoá vĩnh viễn |
| **Hoàn tất hoặc huỷ các đơn hàng đang giao** | Đơn đang xử lý có thể không hoàn được sau khi xoá |
| **Tải về dữ liệu bạn muốn giữ** | Sau thời gian chờ, dữ liệu không thể phục hồi |

---

## 3. Điều gì xảy ra — theo mốc thời gian

### 3.1. NGAY LẬP TỨC (trong vài giây)

| Hành động | Chi tiết |
|---|---|
| Tài khoản chuyển trạng thái **Đã xoá** | Bạn không đăng nhập được nữa |
| **Xoá/thay thế thông tin định danh** | Email → mã ẩn danh nội bộ; Họ tên → "Deleted User"; **Số điện thoại → xoá**; **Ảnh đại diện & ảnh bìa → xoá**; **Mật khẩu → xoá hoàn toàn**; mọi token xác thực email/đặt lại mật khẩu → xoá |
| **Thu hồi toàn bộ phiên đăng nhập** | Mọi thiết bị bị đăng xuất; refresh token bị vô hiệu và xoá |
| **Hạ gói về Free & chấm dứt đăng ký nội bộ** | Đăng ký trong hệ thống SYNC được đánh dấu hết hạn |
| **Ẩn danh nội dung cộng đồng** | Bài viết, bình luận, blog, story, bình luận blog → tên tác giả đổi thành **"Người dùng đã xoá"**, ảnh đại diện bị gỡ |

**Nội dung công khai bạn đã đăng KHÔNG bị xoá theo mặc định** — chỉ bị **ẩn danh**. Lý do: các cuộc trò chuyện/bình luận của người khác dựa trên nội dung đó sẽ mất ngữ cảnh.
👉 **Nếu bạn muốn XOÁ HẲN bài viết/ảnh của mình, hãy tự xoá từng nội dung TRƯỚC khi xoá tài khoản**, hoặc ghi rõ yêu cầu "xoá toàn bộ nội dung đã đăng" trong email gửi {{PRIVACY_EMAIL}} — chúng tôi sẽ xoá thay bạn.

### 3.2. THỜI GIAN CHỜ — 30 NGÀY

Tài khoản ở trạng thái chờ trong **30 ngày kể từ thời điểm bạn xác nhận xoá**.

- **Muốn khôi phục?** Liên hệ {{PRIVACY_EMAIL}} **trong vòng 30 ngày**. Chúng tôi khôi phục quyền truy cập và dữ liệu sức khoẻ/lịch sử tập luyện.
  ⚠️ Các thông tin đã bị xoá cứng ngay ở bước 3.1 (số điện thoại, ảnh đại diện, mật khẩu) **không** khôi phục được — bạn sẽ cần đặt lại.
- Trong thời gian này bạn **không** dùng được ứng dụng.

**Vì sao có 30 ngày:** bảo vệ bạn khỏi trường hợp xoá nhầm hoặc tài khoản bị người khác chiếm đoạt rồi xoá.

### 3.3. SAU 30 NGÀY — XOÁ VĨNH VIỄN

Hệ thống tự động xoá vĩnh viễn, **không thể khôi phục**:

| Nhóm dữ liệu | Kết quả |
|---|---|
| Hồ sơ tài khoản | Xoá |
| **Hồ sơ sinh trắc**: cân nặng, chiều cao, %mỡ, khối lượng cơ, mục tiêu, BMR/TDEE, macro | **Xoá** |
| **Chấn thương, thuốc đang dùng, dị ứng** | **Xoá** |
| **Lịch sử chỉ số sinh trắc theo thời gian** | **Xoá** |
| Hồ sơ ngữ cảnh AI (điểm tuân thủ, nguy cơ kiệt sức, tâm trạng...) | Xoá |
| Tuỳ chọn cá nhân, món yêu thích/không thích | Xoá |
| Lộ trình tập, lịch tập, nhật ký buổi tập, nhật ký từng set, hồ sơ hồi phục | Xoá |
| Nhật ký bữa ăn, tổng hợp dinh dưỡng theo ngày | Xoá |
| **Bộ nhớ dài hạn của AI** (các dữ kiện AI ghi nhớ về bạn) | **Xoá** |
| Hội thoại với AI, bộ nhớ đệm | Xoá |
| Thiết bị đã đăng ký, token thông báo đẩy | Xoá |
| Ảnh/video riêng tư trong kho lưu trữ | Xoá |
| Theo dõi/người theo dõi, lượt thích, tham gia thử thách | Xoá |
| Thành tựu, cấp độ, vật phẩm | Xoá |

---

## 4. Dữ liệu chúng tôi BẮT BUỘC phải giữ lại (và vì sao)

Chúng tôi minh bạch về phần **không** thể xoá theo yêu cầu, vì luật pháp bắt buộc:

| Dữ liệu | Thời hạn giữ | Căn cứ | Cách xử lý |
|---|---|---|---|
| **Hoá đơn, chứng từ giao dịch, sổ sách kế toán** | **10 năm** | Pháp luật kế toán & thuế Việt Nam | Giữ ở dạng chứng từ tài chính, **tách khỏi hồ sơ người dùng**; chỉ còn mã giao dịch và các thông tin luật bắt buộc |
| **Nhật ký báo cáo vi phạm & kết quả xử lý** | 24 tháng | An toàn cộng đồng, xử lý khiếu nại & tái phạm | Ẩn danh danh tính người dùng |
| **Nhật ký bảo mật máy chủ** (dấu vết truy cập, phòng chống gian lận) | 90 ngày | Lợi ích hợp pháp về an ninh hệ thống | Tự động xoá theo vòng đời log |
| **Dữ liệu thống kê đã khử định danh** | Không giới hạn | Không còn là dữ liệu cá nhân | Không thể truy ngược về bạn |
| **Nội dung công khai đã bị người khác chia sẻ lại/trích dẫn** | Theo vòng đời nội dung của người đó | Quyền của người dùng khác | Đã ẩn danh, không còn gắn với bạn |
| Bản sao lưu kỹ thuật | Tối đa **35 ngày** kể từ khi xoá | Khôi phục thảm hoạ | Ghi đè theo chu kỳ, không truy vấn được cho mục đích thông thường |

**Không dữ liệu nào trong danh sách trên được dùng để tiếp thị, hồ sơ hoá người dùng, hay huấn luyện AI.**

---

## 5. Dữ liệu ở bên thứ ba

| Bên | Việc cần làm |
|---|---|
| **Google Play** (gói đăng ký) | **Bạn phải tự huỷ** trong Play Store. Lịch sử mua hàng do Google lưu theo chính sách của Google. |
| **PayOS / MoMo** | Giữ hồ sơ giao dịch theo quy định pháp luật về trung gian thanh toán. |
| **Ahamove / quán ăn đối tác** | Lưu thông tin đơn đã giao theo chính sách của họ; bạn có thể liên hệ trực tiếp để yêu cầu xoá. |
| **OpenAI** | Dữ liệu gửi qua API bị xoá theo chu kỳ của OpenAI (tối đa 30 ngày cho mục đích chống lạm dụng). Chúng tôi không lưu bản sao ngoài phần nêu tại §3.3. |
| **Brevo** | Nhật ký email giao dịch; chúng tôi yêu cầu xoá khi bạn xoá tài khoản. |

---

## 6. Xoá một phần (không xoá cả tài khoản)

Bạn không nhất thiết phải xoá toàn bộ. Gửi yêu cầu tới {{PRIVACY_EMAIL}}:

| Bạn muốn | Kết quả |
|---|---|
| Xoá **bộ nhớ dài hạn của AI** | AI "quên" mọi thứ đã học về bạn, tài khoản giữ nguyên |
| Xoá **toàn bộ nội dung cộng đồng** đã đăng | Bài viết/bình luận/story bị xoá hẳn, tài khoản giữ nguyên |
| Xoá **lịch sử sinh trắc** | Giữ tài khoản & lộ trình, xoá dữ liệu cân nặng/%mỡ theo thời gian |
| Xoá **lịch sử đơn hàng** | Xoá phần không thuộc diện bắt buộc lưu theo §4 |
| **Rút đồng ý** dùng dữ liệu cho cá nhân hoá | Ứng dụng vẫn chạy, gợi ý trở nên chung chung |

Thời hạn xử lý: **30 ngày** kể từ khi xác minh danh tính.

---

## 7. Thời hạn xử lý & khiếu nại

| Việc | Thời hạn |
|---|---|
| Xoá trong ứng dụng | **Ngay lập tức** |
| Xác nhận yêu cầu gửi qua email | **72 giờ** |
| Thời gian chờ khôi phục | **30 ngày** |
| Xoá vĩnh viễn | **Ngay sau khi hết 30 ngày** (chạy tự động hằng ngày) |
| Yêu cầu xoá một phần | **30 ngày** |

**Không đồng ý với cách xử lý?** Gửi {{PRIVACY_EMAIL}}. Nếu chưa thoả đáng, bạn có quyền khiếu nại tới cơ quan nhà nước có thẩm quyền về bảo vệ dữ liệu cá nhân.

---

## 8. Liên hệ

**{{LEGAL_ENTITY_NAME}}**
{{REGISTERED_ADDRESS}}
Yêu cầu về dữ liệu: **{{PRIVACY_EMAIL}}** · Hỗ trợ chung: **{{SUPPORT_EMAIL}}**

---
---

# 🔧 PHỤ LỤC KỸ THUẬT — KHÔNG PUBLISH

> Phần này dành cho đội phát triển. **Xoá toàn bộ phần này trước khi đưa nội dung lên web.**

## A. Trạng thái triển khai hiện tại (đã kiểm chứng trong mã nguồn)

| Cam kết trong tài liệu | Mã nguồn | Trạng thái |
|---|---|---|
| Ẩn danh PII ngay lập tức | `UserMeService.DeleteAccountAsync` — set email ẩn danh, `FullName="Deleted User"`, xoá phone/avatar/background/passwordHash/token | ✅ Đúng |
| Thu hồi phiên | Duyệt `UserDevice`, `IsRevoked=true`, xoá `RefreshTokenHash` + expiry | ✅ Đúng |
| Hạ gói về Free + hết hạn đăng ký | `SubscriptionTier=Free` + cascade `POST /api/internal/payment/users/{id}/expire-subscriptions` | ✅ Đúng |
| Ẩn danh nội dung Social | `AccountAnonymizationService` — Posts, Comments, Blogs, Stories, BlogComments → `AuthorSnapshot = "Người dùng đã xoá"` | ✅ Đúng |
| Grace period 30 ngày | `ScheduledHardDeleteAt = now.AddDays(30)` | ✅ Đúng |
| **Xoá vĩnh viễn sau 30 ngày (§3.3)** | `AccountHardDeleteHostedService.ProcessDueAsync` **chỉ scrub lại tên/email rồi set `ScheduledHardDeleteAt = null`** — **KHÔNG xoá bất kỳ bản ghi nào** | ❌ **CHƯA TRIỂN KHAI** |

## B. ⛔ Chặn phát hành — phải làm trước khi publish trang này

Tài liệu này cam kết xoá vĩnh viễn dữ liệu sức khoẻ sau 30 ngày. **Hiện mã nguồn không làm việc đó.** Publish khi chưa sửa = tuyên bố sai sự thật với người dùng và với Google Play (mục *Data deletion*), rủi ro bị gỡ ứng dụng.

Cần bổ sung vào `AccountHardDeleteHostedService` (hoặc một job xoá riêng, gọi cascade sang các service):

1. **IAM (Postgres):** xoá `BiometricProfile`, `BiometricHistory`, `AIContextProfile`, `UserPreference`, `UserDevice`, `UserAsset`, `UserAchievement`, `GamificationProfile`, `UserLevelSnapshot`, `TargetAdjustmentLog`, `UserVoucher`; cuối cùng xoá `User` hoặc giữ lại bản ghi trơ chỉ còn `Id` nếu có ràng buộc khoá ngoại từ dữ liệu tài chính.
2. **Roadmap (Mongo):** `PersonalizedRoadmap`, `ScheduledWorkout`, `RoadmapSession`, `WorkoutExecutionLog`, `ExerciseSetLog`, `RecoveryProfile`, `UserCustomWorkout` theo `UserId`.
3. **Nutrition (Mongo):** `MealLog`, `DailyNutritionSummary` theo `UserId`.
4. **Social (Mongo):** `Story`, `StoryView`, `StoryInteraction`, `Interaction`, `UserFollow`, `ChallengeParticipant`, `UserSocialSettings`; Post/Comment/Blog giữ ẩn danh (đúng như §3.1 đã công bố).
5. **Notification:** `NotificationMessage`, `SmartPushSchedule`, `SmartPushLog` theo `UserId`.
6. **AI service (Postgres `sync_ai`):** `DELETE FROM ai_user_memory WHERE user_id = ...`; `ai_turn_audit` → ẩn danh `user_id` hoặc xoá.
7. **S3:** xoá prefix ảnh riêng tư của user trong `sync-private-assets`.
8. **Payment:** **KHÔNG** xoá `Transaction`/`WalletLedger` (§4 — nghĩa vụ kế toán 10 năm); chỉ tách khỏi hồ sơ định danh.
9. Ghi **nhật ký kiểm toán** mỗi lần xoá vĩnh viễn (userId đã băm, thời điểm, các bảng đã xử lý) để chứng minh tuân thủ khi Google hoặc cơ quan quản lý yêu cầu.
10. Thiết kế **idempotent + retry**: cascade qua nhiều service phải chịu được lỗi mạng, không được bỏ sót âm thầm như `NotifyDeletedAsync` hiện tại (đang `best-effort`, nuốt lỗi chỉ log warning).

## C. Việc khác cần làm

- [ ] Trang `{{WEBSITE}}/account-deletion` phải liệt kê **đúng** bảng §3.3 và §4 (hiện `ui/web/src/app/account-deletion/page.tsx` chỉ ~48 dòng, chưa đủ chi tiết cho Play).
- [ ] Bổ sung endpoint **xuất dữ liệu** (data portability) — Privacy Policy §9 đang cam kết.
- [ ] Bổ sung endpoint **xoá một phần** cho các mục tại §6, hoặc chuyển sang quy trình thủ công có SLA rõ ràng.
- [ ] Thêm job dọn `ai_turn_audit` (180 ngày), `ContentReport` (24 tháng), log server (90 ngày) — Privacy Policy §7 đang cam kết.
- [ ] Trong app: màn xoá tài khoản phải hiển thị cảnh báo §2 (đặc biệt: **huỷ gói Google Play riêng** và **số dư ví không khôi phục được**).
- [ ] `DELETE /api/v1/me` hiện **không yêu cầu xác nhận lại** (không nhập mật khẩu, không nhập chuỗi xác nhận). Chỉ cần access token hợp lệ là xoá được tài khoản. Cần thêm **bước xác nhận hai lớp** ở tầng UI (gõ "XOA" hoặc nhập lại mật khẩu) — Play yêu cầu hành động xoá phải là chủ ý rõ ràng, và điều này chặn được kịch bản token bị đánh cắp dùng để xoá tài khoản nạn nhân.
