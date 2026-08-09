# THÔNG TIN DOANH NGHIỆP & LIÊN HỆ / COMPANY & CONTACT

**Phiên bản / Version:** 1.0 · **Ngày hiệu lực / Effective:** {{EFFECTIVE_DATE}}
**URL công khai / Public URL:** `{{WEBSITE}}/contact`

> ⚠️ **Đây là tài liệu duy nhất trong bộ Legal Pack mà tôi KHÔNG thể tự điền.** Google Play đối chiếu thông tin ở đây với hồ sơ tài khoản developer của bạn — sai lệch là lý do từ chối phổ biến. Vui lòng điền bằng thông tin **thật, khớp giấy tờ**.

---

## 1. Thông tin pháp nhân / Legal entity

| Mục / Item | Giá trị / Value |
|---|---|
| Tên đầy đủ (tiếng Việt) | {{LEGAL_ENTITY_NAME}} |
| Tên tiếng Anh / giao dịch quốc tế | {{LEGAL_ENTITY_NAME_EN}} |
| Tên viết tắt / thương hiệu | SYNC |
| Loại hình | ☐ Công ty TNHH ☐ Công ty cổ phần ☐ Hộ kinh doanh ☐ Cá nhân (developer cá nhân) |
| Mã số doanh nghiệp / MST | {{BUSINESS_REG_NO}} |
| Ngày cấp | {{BUSINESS_REG_DATE}} |
| Cơ quan cấp | {{BUSINESS_REG_AUTHORITY}} |
| Người đại diện theo pháp luật | {{REPRESENTATIVE_NAME}} |
| Ngành nghề liên quan | Lập trình máy vi tính; Dịch vụ nền tảng số trung gian; Bán lẻ qua nền tảng thương mại điện tử |

## 2. Địa chỉ / Address

| Mục | Giá trị |
|---|---|
| Trụ sở đăng ký / Registered office | {{REGISTERED_ADDRESS}} |
| Địa chỉ nhận thư (nếu khác) | {{MAILING_ADDRESS}} |
| Quốc gia / Country | Việt Nam / Vietnam |

## 3. Kênh liên hệ / Contact channels

| Mục đích / Purpose | Email | SLA phản hồi |
|---|---|---|
| Hỗ trợ người dùng chung / General support | **{{SUPPORT_EMAIL}}** | 24 giờ làm việc |
| Quyền riêng tư & dữ liệu cá nhân / Privacy | **{{PRIVACY_EMAIL}}** | 72 giờ |
| Báo cáo nội dung vi phạm / Abuse & content reports | **{{ABUSE_EMAIL}}** | Theo SLA tại Tiêu chuẩn cộng đồng §4.1 |
| Hợp tác & đối tác / Business & partnerships | {{BUSINESS_EMAIL}} | 5 ngày làm việc |
| Bảo mật (báo lỗ hổng) / Security disclosure | {{SECURITY_EMAIL}} | 72 giờ |

| Kênh khác | Giá trị |
|---|---|
| Hotline | {{SUPPORT_PHONE}} |
| Website | {{WEBSITE}} |
| Giờ làm việc / Business hours | Thứ Hai – Thứ Sáu, 09:00–18:00 (GMT+7), trừ ngày lễ |

## 4. Thông tin ứng dụng / App details

| Mục | Giá trị |
|---|---|
| Tên ứng dụng / App name | SYNC |
| Package name (Android) | {{PLAY_PACKAGE_NAME}} — hiện mã nguồn dùng `com.sync.sync_app` |
| Tài khoản Google Play Developer | {{PLAY_DEVELOPER_ACCOUNT}} |
| Loại tài khoản Play | ☐ Organisation (cần D-U-N-S) ☐ Personal |
| D-U-N-S Number (nếu là tổ chức) | {{DUNS_NUMBER}} |

## 5. Các URL bắt buộc khai báo trong Play Console

| Mục trong Play Console | URL |
|---|---|
| Privacy policy URL | `{{WEBSITE}}/privacy` |
| Account deletion URL (Data deletion) | `{{WEBSITE}}/account-deletion` |
| Terms of service | `{{WEBSITE}}/terms` |
| Health disclaimer | `{{WEBSITE}}/health-disclaimer` |
| Refund policy | `{{WEBSITE}}/refund-policy` |
| Community standards | `{{WEBSITE}}/community-standards` |
| Support contact | `{{WEBSITE}}/contact` |

---

## 6. ✅ Checklist trước khi nộp Google Play

- [ ] **Tên pháp nhân trong tài liệu KHỚP CHÍNH XÁC** tên trên tài khoản Play Console (kể cả loại hình: "Công ty TNHH ..." đầy đủ).
- [ ] **Địa chỉ khớp** địa chỉ đã xác minh trong Play Console → Payments profile.
- [ ] **Email hỗ trợ có người trả lời thật.** Google gửi email kiểm tra trong quá trình review; không phản hồi = từ chối.
- [ ] Email dùng **domain riêng**, không dùng Gmail cá nhân.
      *Hiện `Iam.API/appsettings.json` đang cấu hình `FromEmail = kag40222@gmail.com` — cần đổi sang `no-reply@{{WEBSITE}}` và cấu hình SPF/DKIM/DMARC cho domain trước khi phát hành, nếu không email xác thực tài khoản sẽ rơi vào spam.*
- [ ] Tất cả URL ở §5 **truy cập được công khai, không cần đăng nhập, không lỗi 404**, và **không còn placeholder `{{...}}`**.
- [ ] Trang chính sách có thể mở được **từ trình duyệt trên điện thoại** (Google review bằng thiết bị thật).
- [ ] Nếu là tổ chức: đã có **D-U-N-S Number** và hoàn tất xác minh danh tính/địa chỉ trong Play Console.
- [ ] Đã tạo **merchant account** cho Google Play Billing và khai báo thuế Việt Nam.
- [ ] Nội dung tiếng Việt là chính, có bản tiếng Anh cho reviewer quốc tế.

---

## 7. Ghi chú cho việc điền

**Nếu bạn đăng ký developer với tư cách cá nhân:**
- `{{LEGAL_ENTITY_NAME}}` = họ tên đầy đủ trên CCCD.
- `{{BUSINESS_REG_NO}}`, `{{BUSINESS_REG_DATE}}`, `{{BUSINESS_REG_AUTHORITY}}`, `{{DUNS_NUMBER}}` → ghi **"Không áp dụng (cá nhân)"**, đừng để trống.
- `{{REGISTERED_ADDRESS}}` = địa chỉ thường trú.
- ⚠️ Lưu ý: bán gói đăng ký (Premium/Ultra) và làm trung gian đơn hàng có thu hoa hồng thường **cần tư cách kinh doanh** theo pháp luật Việt Nam. Nên tham vấn kế toán/luật sư về việc đăng ký hộ kinh doanh hoặc doanh nghiệp trước khi thu tiền người dùng, để tránh vướng cả về thuế lẫn về điều kiện hoạt động sàn/nền tảng trung gian.

**Nếu bạn chưa có domain:** đăng ký domain trước khi làm bất cứ bước nào khác — 7 trong 7 tài liệu đều tham chiếu tới URL trên domain đó, và mã nguồn (`AppConfig.legalBaseUrl`) đang mặc định `synctis.in`. Nếu chọn domain khác, phải sửa đồng thời: `ui/app/lib/core/config/app_config.dart`, các `appsettings.json` (`PublicBaseUrl`, `VerificationBaseUrl`), và toàn bộ `{{WEBSITE}}` trong bộ tài liệu này.

---

## 8. Nội dung hiển thị cuối trang web (footer)

Bản rút gọn để dán vào footer của `ui/web`:

```
© {{YEAR}} {{LEGAL_ENTITY_NAME}}
{{REGISTERED_ADDRESS}}
MSDN: {{BUSINESS_REG_NO}} · Người đại diện: {{REPRESENTATIVE_NAME}}
Hỗ trợ: {{SUPPORT_EMAIL}} · Quyền riêng tư: {{PRIVACY_EMAIL}}

Chính sách bảo mật · Điều khoản dịch vụ · Miễn trừ y tế · Hoàn tiền · Xoá tài khoản · Tiêu chuẩn cộng đồng
```

**English footer:**

```
© {{YEAR}} {{LEGAL_ENTITY_NAME_EN}}
{{REGISTERED_ADDRESS}}
Business reg. no.: {{BUSINESS_REG_NO}} · Legal representative: {{REPRESENTATIVE_NAME}}
Support: {{SUPPORT_EMAIL}} · Privacy: {{PRIVACY_EMAIL}}

Privacy Policy · Terms of Service · Health Disclaimer · Refunds · Account Deletion · Community Standards
```
