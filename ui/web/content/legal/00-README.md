# SYNC — Bộ tài liệu pháp lý & chính sách (Legal Pack)

> Nguồn chân lý (source of truth) cho toàn bộ nội dung pháp lý hiển thị trong app, trên website `ui/web`, và khai báo trong Google Play Console.
> Mọi thay đổi chính sách phải sửa **ở đây trước**, rồi mới đồng bộ sang `ui/web/src/app/*` và Play Console.

---

## 1. Danh mục tài liệu

| # | Tài liệu | Tiếng Việt | English | URL công khai dự kiến |
|---|---|---|---|---|
| 1 | Chính sách quyền riêng tư | `01-privacy-policy.vi.md` | `01-privacy-policy.en.md` | `/privacy`, `/en/privacy` |
| 2 | Điều khoản dịch vụ | `02-terms-of-service.vi.md` | `02-terms-of-service.en.md` | `/terms`, `/en/terms` |
| 3 | Tuyên bố miễn trừ y tế | `03-health-disclaimer.vi.md` | `03-health-disclaimer.en.md` | `/health-disclaimer` |
| 4 | Chính sách hoàn tiền & huỷ | `04-refund-cancellation.vi.md` | `04-refund-cancellation.en.md` | `/refund-policy` |
| 5 | Xoá tài khoản & dữ liệu | `05-account-deletion.vi.md` | `05-account-deletion.en.md` | `/account-deletion` |
| 6 | Tiêu chuẩn cộng đồng | `06-community-standards.vi.md` | `06-community-standards.en.md` | `/community-standards` |
| 7 | Thông tin doanh nghiệp & liên hệ | `07-company-contact.md` (song ngữ) | — | `/contact` |
| 8 | **Báo cáo đối chiếu tài liệu ↔ mã nguồn** | `08-code-verification-report.md` | — | ⛔ **nội bộ, không publish** |

> 👉 **Đọc `08-code-verification-report.md` trước tiên.** Tài liệu đó liệt kê 40 tuyên bố đã xác minh đúng trong mã nguồn, và **11 khoảng trống** mà tài liệu đang cam kết nhiều hơn code đang làm — trong đó **2 mục nghiêm trọng chặn phát hành**.

---

## 2. ⚠️ Placeholder BẮT BUỘC phải điền trước khi công bố

Tất cả tài liệu dùng chung bộ biến sau. **Tìm & thay toàn bộ** (`{{...}}`) trước khi publish — Google Play sẽ từ chối nếu trang chính sách còn placeholder hoặc thông tin pháp nhân không khớp tài khoản Play Console.

| Biến | Ý nghĩa | Gợi ý nguồn |
|---|---|---|
| `{{LEGAL_ENTITY_NAME}}` | Tên pháp nhân đầy đủ (hoặc họ tên cá nhân nếu đăng ký developer cá nhân) | Giấy chứng nhận ĐKKD / CCCD |
| `{{LEGAL_ENTITY_NAME_EN}}` | Tên tiếng Anh của pháp nhân | ĐKKD |
| `{{BUSINESS_REG_NO}}` | Mã số doanh nghiệp / MST | ĐKKD |
| `{{BUSINESS_REG_DATE}}` | Ngày cấp | ĐKKD |
| `{{BUSINESS_REG_AUTHORITY}}` | Cơ quan cấp (Sở KH&ĐT tỉnh/TP) | ĐKKD |
| `{{REGISTERED_ADDRESS}}` | Địa chỉ trụ sở đăng ký (đầy đủ, có phường/xã, quận/huyện, tỉnh/TP) | ĐKKD |
| `{{REPRESENTATIVE_NAME}}` | Người đại diện theo pháp luật | ĐKKD |
| `{{SUPPORT_EMAIL}}` | Email hỗ trợ người dùng | mặc định gợi ý `support@synctis.in` |
| `{{PRIVACY_EMAIL}}` | Email tiếp nhận yêu cầu về dữ liệu cá nhân | gợi ý `privacy@synctis.in` |
| `{{ABUSE_EMAIL}}` | Email báo cáo nội dung vi phạm | gợi ý `report@synctis.in` |
| `{{DPO_NAME}}` | Người/bộ phận phụ trách bảo vệ dữ liệu cá nhân | nội bộ |
| `{{SUPPORT_PHONE}}` | Hotline (nếu có) | nội bộ |
| `{{WEBSITE}}` | Domain chính thức | hiện code đang dùng `synctis.in` |
| `{{EFFECTIVE_DATE}}` | Ngày hiệu lực | ngày publish |
| `{{PLAY_PACKAGE_NAME}}` | Package name | `com.sync.sync_app` |

> **Lưu ý về email:** Google Play yêu cầu email liên hệ **hoạt động thật và trả lời được**. Hiện `Iam.API/appsettings.json` đang cấu hình `FromEmail = kag40222@gmail.com`. Nên chuyển sang email theo domain (`no-reply@synctis.in`) trước khi nộp — email Gmail cá nhân làm giảm độ tin cậy khi Play review và dễ vào spam.

---

## 3. Nguyên tắc soạn thảo (đã áp dụng)

1. **Chỉ tuyên bố những gì code thực sự làm.** Mọi mục trong bảng data inventory đều đối chiếu với entity/field có thật trong `core/SyncPlatform/src` và `ai/sync-agent-service`.
2. **Tách bạch "đã thực thi trong code" vs "cam kết chính sách".** Những mục chưa được enforce tự động được đánh dấu 🔧 kèm việc cần làm — **không** được publish khi còn 🔧 mà chưa xử lý hoặc chưa chỉnh lại câu chữ.
3. **Không bán dữ liệu, không quảng cáo hành vi.** Codebase hiện không có SDK quảng cáo/analytics bên thứ ba nào — tài liệu khẳng định điều này, nên **nếu sau này thêm SDK quảng cáo/analytics thì bắt buộc sửa lại Privacy Policy + Data Safety**.
4. **Song ngữ đối chiếu 1-1.** Bản EN là bản dịch trung thực, không thêm/bớt nghĩa vụ. Điều khoản ghi rõ bản tiếng Việt là bản gốc khi có mâu thuẫn.

---

## 4. Ánh xạ sang Google Play Console

| Mục trong Play Console | Dùng tài liệu / URL |
|---|---|
| Store listing → **Privacy policy URL** | `{{WEBSITE}}/privacy` |
| App content → **Data safety** | Bảng inventory tại `01-privacy-policy.vi.md` §3 |
| App content → **Account deletion** (Data deletion URL) | `{{WEBSITE}}/account-deletion` |
| App content → **Health apps declaration** | `03-health-disclaimer.vi.md` |
| App content → **Financial features / subscriptions** | `04-refund-cancellation.vi.md` |
| App content → **UGC declaration** | `06-community-standards.vi.md` |
| Policy → **Contact details** | `07-company-contact.md` |

---

## 5. Việc cần làm sau khi điền placeholder

- [ ] Đồng bộ nội dung sang `ui/web/src/app/{privacy,terms,account-deletion,community-standards}/page.tsx` (hiện đang là bản rút gọn ~40–50 dòng).
- [ ] Tạo thêm route `/health-disclaimer`, `/refund-policy`, `/contact` trên `ui/web`.
- [ ] Thêm màn hình hiển thị/link trong app: Hồ sơ → Pháp lý; checkbox đồng ý ở màn đăng ký (`AppConfig.privacyPolicyUrl`, `termsOfServiceUrl` đã có sẵn).
- [ ] Bổ sung `AppConfig.healthDisclaimerUrl` và `refundPolicyUrl` cho khớp.
- [ ] Rà lại Data Safety form khớp đúng bảng §3 của Privacy Policy.
- [ ] Nhờ luật sư/đơn vị tư vấn pháp lý VN review trước khi công bố (bộ tài liệu này là bản thảo kỹ thuật, **không phải tư vấn pháp lý**).
