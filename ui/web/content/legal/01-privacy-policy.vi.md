# CHÍNH SÁCH QUYỀN RIÊNG TƯ — SYNC

**Phiên bản:** 1.0
**Ngày hiệu lực:** {{EFFECTIVE_DATE}}
**Áp dụng cho:** Ứng dụng di động SYNC
**Ngôn ngữ gốc:** Tiếng Việt. Bản tiếng Anh (`/en/privacy`) chỉ mang tính tham khảo; khi có khác biệt, bản tiếng Việt có hiệu lực.

---

## 1. Chúng tôi là ai

| Nội dung | Thông tin |
|---|---|
| Bên Kiểm soát dữ liệu | **{{LEGAL_ENTITY_NAME}}** |
| Mã số doanh nghiệp | {{BUSINESS_REG_NO}}, cấp ngày {{BUSINESS_REG_DATE}} bởi {{BUSINESS_REG_AUTHORITY}} |
| Người đại diện theo pháp luật | {{REPRESENTATIVE_NAME}} |
| Đầu mối bảo vệ dữ liệu cá nhân | {{DPO_NAME}} — {{PRIVACY_EMAIL}} |
| Hỗ trợ người dùng | {{SUPPORT_EMAIL}}{{#SUPPORT_PHONE}} · {{SUPPORT_PHONE}}{{/SUPPORT_PHONE}} |

Trong tài liệu này, "SYNC", "chúng tôi" là {{LEGAL_ENTITY_NAME}}; "bạn" là người dùng dịch vụ.

**SYNC là gì:** nền tảng đồng hành lối sống ứng dụng AI, gồm: huấn luyện viên AI (CYN AI), lộ trình tập luyện cá nhân hoá, theo dõi dinh dưỡng, cộng đồng (bài viết/story/thử thách), và đặt món ăn từ đối tác trong ứng dụng.

---

## 2. Cam kết nền tảng

1. **Chúng tôi KHÔNG bán dữ liệu cá nhân của bạn** cho bất kỳ bên nào, dưới mọi hình thức.
2. **Chúng tôi KHÔNG dùng dữ liệu của bạn để huấn luyện mô hình AI** — của chúng tôi hoặc của bên thứ ba. Xem §6.
3. **Ứng dụng KHÔNG tích hợp SDK quảng cáo, không mạng lưới quảng cáo, không theo dõi xuyên ứng dụng (cross-app tracking), không định danh quảng cáo (Advertising ID).**
4. **Nguyên tắc tối thiểu hoá:** chúng tôi chỉ thu thập dữ liệu cần cho tính năng bạn thực sự dùng. Bạn có thể dùng phần lớn ứng dụng mà không cấp quyền vị trí, camera hay micro.
5. **Bạn kiểm soát:** mọi dữ liệu đều có thể xem, sửa, xuất hoặc xoá — xem §9.

> Nếu trong tương lai chúng tôi thay đổi bất kỳ cam kết nào ở trên, chính sách này sẽ được cập nhật và bạn sẽ được thông báo **trước** khi thay đổi có hiệu lực (§13).

---

## 3. Dữ liệu chúng tôi thu thập (kiểm kê chi tiết)

Bảng dưới đây liệt kê **chính xác** các nhóm dữ liệu hệ thống lưu trữ, tương ứng với cấu trúc dữ liệu thực tế của sản phẩm. Cột "Bắt buộc" cho biết bạn có thể dùng ứng dụng mà không cung cấp dữ liệu đó hay không.

### 3.1. Dữ liệu định danh & tài khoản

| Trường dữ liệu | Mô tả | Bắt buộc | Căn cứ pháp lý | Lưu trữ |
|---|---|---|---|---|
| Email | Định danh đăng nhập, xác thực, khôi phục mật khẩu | ✅ Có | Thực hiện hợp đồng | Postgres (AWS Singapore) |
| Mật khẩu | Lưu dưới dạng **băm (hash) một chiều** — chúng tôi không bao giờ thấy mật khẩu gốc | ✅ (nếu không dùng Google) | Thực hiện hợp đồng | Postgres |
| Họ và tên | Hiển thị trong app & cộng đồng | ✅ Có | Thực hiện hợp đồng | Postgres |
| Số điện thoại | Tuỳ chọn; dùng cho giao nhận đơn hàng | ❌ Không | Thực hiện hợp đồng | Postgres |
| Ảnh đại diện, ảnh bìa | Tuỳ chọn | ❌ Không | Sự đồng ý | S3 (Singapore) |
| Google Account ID / ID token | Khi bạn chọn "Đăng nhập bằng Google" | ❌ Không | Sự đồng ý | Không lưu token; chỉ lưu email + tên do Google trả về |
| Ngôn ngữ, múi giờ | Hiển thị nội dung & tính lịch nhắc đúng giờ địa phương | ✅ Có (tự động) | Lợi ích hợp pháp | Postgres |
| Trạng thái tài khoản, hạng gói (Free/Premium/Ultra), vai trò | Quản lý quyền truy cập tính năng | ✅ Có | Thực hiện hợp đồng | Postgres |
| Thời điểm đăng nhập / hoạt động gần nhất | Bảo mật, phát hiện truy cập bất thường | ✅ Có | Lợi ích hợp pháp | Postgres |

### 3.2. Dữ liệu sức khoẻ & thể chất — **DỮ LIỆU CÁ NHÂN NHẠY CẢM**

Đây là nhóm dữ liệu được pháp luật Việt Nam xếp vào **dữ liệu cá nhân nhạy cảm**. Chúng tôi xử lý nhóm này **chỉ khi bạn chủ động cung cấp**, trên cơ sở **sự đồng ý riêng biệt, rõ ràng** của bạn tại bước khai báo hồ sơ.

| Trường dữ liệu | Mục đích cụ thể | Bắt buộc |
|---|---|---|
| Giới tính, ngày sinh | Tính BMR/TDEE theo công thức Mifflin-St Jeor; kiểm tra đủ tuổi | ✅ Có (để dùng tính năng huấn luyện) |
| Chiều cao, cân nặng hiện tại, cân nặng mục tiêu | Tính nhu cầu năng lượng, thiết kế lộ trình | ✅ Có |
| Tỷ lệ mỡ cơ thể, khối lượng cơ (hiện tại & mục tiêu) | Tinh chỉnh mục tiêu, đánh giá tiến độ | ❌ Không |
| Mục tiêu thể hình, mức vận động, trình độ kinh nghiệm, nơi tập ưa thích | Sinh lộ trình phù hợp | ✅ Có |
| **Chấn thương đã/đang có** (`Injuries`) | Loại bỏ bài tập gây rủi ro khỏi lộ trình | ❌ Không — nhưng khuyến nghị mạnh vì lý do an toàn |
| **Thuốc đang sử dụng** (`Medications`) | Cảnh báo tương tác với chế độ ăn/tập; **không** dùng để chẩn đoán | ❌ Không |
| **Dị ứng thực phẩm** (`Allergies`) | Chặn tuyệt đối gợi ý món chứa dị nguyên | ❌ Không — nhưng khuyến nghị mạnh vì lý do an toàn |
| Lịch sử chỉ số sinh trắc theo thời gian (cân nặng, %mỡ, cơ, ghi chú) | Vẽ biểu đồ tiến độ; tự động điều chỉnh mục tiêu calo/macro | Tự động khi bạn cập nhật |
| Mục tiêu calo & macro (đạm/tinh bột/chất béo) hằng ngày, BMR, TDEE | Nền tảng cho gợi ý dinh dưỡng | Tự động tính |
| Hồ sơ hồi phục, nhật ký buổi tập, nhật ký từng set (số rep, mức tạ) | Đo tải tập, phát hiện quá tải | Tự động khi bạn ghi nhận |
| Nhật ký bữa ăn, tổng hợp dinh dưỡng theo ngày | Theo dõi ăn uống | Tự động khi bạn ghi nhận |

> **Chúng tôi KHÔNG thu thập:** dữ liệu từ thiết bị đeo/cảm biến sức khoẻ của hệ điều hành (Google Fit / Health Connect / Apple Health), hồ sơ bệnh án, kết quả xét nghiệm, dữ liệu di truyền, dữ liệu sinh trắc học định danh (vân tay, khuôn mặt).

### 3.3. Dữ liệu suy luận do AI tạo ra (derived data)

Hệ thống tính toán một số chỉ số **suy luận** từ hành vi của bạn. Chúng tôi công bố minh bạch vì đây cũng là dữ liệu cá nhân:

| Chỉ số | Ý nghĩa | Ảnh hưởng tới bạn |
|---|---|---|
| Điểm tuân thủ (`AdherenceScore`) | Mức bám sát lộ trình | Điều chỉnh độ khó lộ trình |
| Nguy cơ kiệt sức (`BurnoutRiskScore`) | Dấu hiệu quá tải | Đề xuất giảm tải/nghỉ |
| Nguy cơ rời bỏ (`ChurnRiskScore`) | Khả năng ngừng sử dụng | Điều chỉnh tần suất & giọng điệu nhắc nhở |
| Điểm động lực, điểm hồi phục, tuân thủ dinh dưỡng/tập luyện | Cá nhân hoá | Nội dung gợi ý |
| Khung giờ năng lượng cao, tâm trạng hiện tại, phong cách can thiệp ưa thích | Chọn thời điểm & cách nhắc | Thời điểm gửi thông báo |
| Ảnh chụp lý do quyết định của AI (`AIReasoningSnapshot`) khi AI đề xuất chi tiêu/đơn hàng | Truy vết & giải trình | Bạn có quyền yêu cầu xem |

**Quyền phản đối:** bạn có thể yêu cầu chúng tôi ngừng dùng nhóm dữ liệu suy luận này để cá nhân hoá (tắt SmartPush / rút đồng ý chia sẻ dữ liệu trong phần Cài đặt), khi đó ứng dụng vẫn hoạt động nhưng gợi ý sẽ ở mức chung chung.

### 3.4. Nội dung do bạn tạo

| Loại | Ghi chú |
|---|---|
| Bài viết, bình luận, blog, ảnh/video kèm theo | **Công khai** với người dùng khác nếu bạn đặt chế độ công khai |
| Story (ảnh/video/chữ) | Tự hết hạn sau 24 giờ; lượt xem/thích của người khác được ghi nhận |
| Lượt theo dõi, thích, tham gia thử thách cộng đồng | Một phần công khai |
| Đánh giá quán ăn/sản phẩm | Công khai kèm tên hiển thị |
| Báo cáo vi phạm nội dung | Chỉ đội kiểm duyệt xem; danh tính người báo cáo **không** tiết lộ cho người bị báo cáo |
| Hội thoại với CYN AI | Riêng tư — xem §6 |

### 3.5. Vị trí

| Dạng | Khi nào thu thập | Bắt buộc |
|---|---|---|
| Vị trí chính xác (GPS) | **Chỉ khi bạn cấp quyền và chỉ trong lúc dùng tính năng**: tìm quán ăn gần, tính phí giao hàng, xác nhận địa chỉ nhận hàng | ❌ Không — bạn có thể nhập địa chỉ thủ công |
| Toạ độ giao hàng của đơn | Lưu kèm đơn hàng để đối tác giao đúng nơi | Chỉ khi bạn đặt món |
| Vị trí tài xế trong lúc giao | Do đối tác giao hàng cung cấp, hiển thị cho bạn theo dõi đơn | Chỉ khi có đơn đang giao |

**Chúng tôi KHÔNG thu thập vị trí nền (background location).** Ứng dụng không khai báo quyền `ACCESS_BACKGROUND_LOCATION`.

### 3.6. Camera, thư viện ảnh, micro

| Quyền | Dùng để làm gì | Có bắt buộc |
|---|---|---|
| Camera | Chụp ảnh đăng bài/story/ảnh đại diện | ❌ Không |
| Thư viện ảnh | Chọn ảnh có sẵn (qua bộ chọn ảnh của hệ điều hành) | ❌ Không |
| Micro | Tính năng trò chuyện bằng giọng nói với CYN AI | ❌ Không |

Chúng tôi **không** truy cập camera/micro ngầm. Ảnh và âm thanh chỉ được gửi lên khi bạn chủ động thực hiện hành động đăng/gửi.

### 3.7. Giao dịch & thanh toán

| Dữ liệu | Ghi chú |
|---|---|
| Đơn đặt món: món, số lượng, ghi chú, tổng tiền, mã giảm giá | Postgres |
| Địa chỉ giao, toạ độ, tên & số điện thoại người nhận | Postgres |
| Giao dịch: số tiền, phương thức (Ví/COD/VietQR/MoMo/Google Play), trạng thái, mã tham chiếu bên thanh toán | Postgres |
| Ví nội bộ & sổ cái ví | Postgres |
| Gói đăng ký: hạng, trạng thái, ngày bắt đầu/hết hạn, tự động gia hạn, nguồn mua | Postgres |
| Đánh dấu "giao dịch do AI khởi tạo" + hạn mức chi tiêu bạn đặt | Bảo vệ bạn khỏi chi tiêu ngoài ý muốn |

> **Chúng tôi KHÔNG lưu số thẻ ngân hàng, CVV, hay thông tin đăng nhập ngân hàng.** Toàn bộ thao tác thanh toán diễn ra trên hạ tầng của đơn vị trung gian thanh toán (Google Play, PayOS, MoMo). Chúng tôi chỉ nhận về mã giao dịch và trạng thái.

### 3.8. Dữ liệu thiết bị & kỹ thuật

| Dữ liệu | Mục đích |
|---|---|
| Mã định danh thiết bị nội bộ do ứng dụng sinh, nền tảng (Android/iOS/Web), phiên bản ứng dụng | Quản lý phiên đăng nhập, hỗ trợ kỹ thuật |
| Token thông báo đẩy | Gửi nhắc nhở (chỉ khi bạn bật) |
| Refresh token (lưu dạng băm) & thời hạn | Duy trì đăng nhập an toàn |
| Nhật ký lỗi & vận hành, địa chỉ IP trong log máy chủ | Bảo mật, chống lạm dụng, khắc phục sự cố |

**Chúng tôi KHÔNG dùng:** Advertising ID, fingerprinting thiết bị, SDK analytics thương mại của bên thứ ba.

---

## 4. Vì sao chúng tôi xử lý dữ liệu (mục đích & căn cứ)

| Mục đích | Dữ liệu dùng | Căn cứ |
|---|---|---|
| Tạo & vận hành tài khoản | §3.1 | Thực hiện hợp đồng |
| Sinh lộ trình tập & mục tiêu dinh dưỡng cá nhân hoá | §3.2, §3.3 | **Sự đồng ý riêng cho dữ liệu nhạy cảm** |
| Trợ lý AI trả lời & thực hiện tác vụ theo yêu cầu | §3.1–3.4 (tối thiểu hoá, xem §6) | Thực hiện hợp đồng + sự đồng ý |
| Nhắc nhở thông minh (SmartPush) | §3.2, §3.3 | Sự đồng ý (bật/tắt trong Cài đặt) 🔧 |
| Cộng đồng & kiểm duyệt nội dung | §3.4 | Thực hiện hợp đồng + lợi ích hợp pháp (an toàn cộng đồng) |
| Đặt món & giao hàng | §3.5, §3.7 | Thực hiện hợp đồng |
| Thanh toán, hoá đơn, chống gian lận | §3.7, §3.8 | Thực hiện hợp đồng + nghĩa vụ pháp lý |
| Bảo mật hệ thống, điều tra lạm dụng | §3.8 | Lợi ích hợp pháp |
| Thống kê tổng hợp để cải thiện sản phẩm | Dữ liệu **đã tổng hợp/khử định danh** | Lợi ích hợp pháp |
| Gửi thông tin khuyến mại | Email, tên | **Sự đồng ý** (`MarketingConsent`, mặc định TẮT) |

---

## 5. Chúng tôi chia sẻ dữ liệu với ai

Chúng tôi chỉ chia sẻ trong các trường hợp dưới đây, theo hợp đồng có điều khoản bảo mật và giới hạn mục đích.

### 5.1. Nhà cung cấp dịch vụ (bên xử lý dữ liệu)

| Bên nhận | Dữ liệu được chia sẻ | Mục đích | Nơi xử lý |
|---|---|---|---|
| **Amazon Web Services (AWS)** | Toàn bộ dữ liệu ứng dụng (lưu trữ, không đọc nội dung) | Hạ tầng máy chủ, cơ sở dữ liệu, lưu trữ tệp, CDN | **Singapore (ap-southeast-1)**; CDN có điểm phát toàn cầu |
| **OpenAI, L.L.C.** | Nội dung tin nhắn bạn gửi cho AI + ngữ cảnh tối thiểu đã che PII (xem §6) | Sinh câu trả lời của trợ lý AI | Hoa Kỳ |
| **Google LLC** — Play Billing & Play Developer API | Mã giao dịch, mã sản phẩm, trạng thái đăng ký | Xác thực & đồng bộ gói đăng ký mua qua Google Play | Hoa Kỳ / toàn cầu |
| **Google LLC** — Google Sign-In | Email, tên, ảnh đại diện do bạn cho phép | Đăng nhập bằng Google | Hoa Kỳ / toàn cầu |
| **PayOS / MoMo** (trung gian thanh toán VN) | Số tiền, mã đơn, thông tin cần thiết để thu tiền | Xử lý thanh toán | Việt Nam |
| **Ahamove** (đối tác giao hàng) | Địa chỉ giao, toạ độ, tên & SĐT người nhận, nội dung đơn | Giao hàng & theo dõi đơn | Việt Nam |
| **Đối tác quán ăn** trong ứng dụng | Nội dung đơn, tên & SĐT người nhận, ghi chú | Chuẩn bị & bàn giao đơn | Việt Nam |
| **Brevo (Sendinblue)** | Email, tên, nội dung thư giao dịch | Gửi email xác thực / khôi phục mật khẩu | Liên minh châu Âu |
| **Tavily** | **Chỉ chuỗi truy vấn tìm kiếm** do AI tạo ra — không kèm danh tính bạn | Tra cứu thông tin công khai khi bạn hỏi kiến thức bên ngoài | Hoa Kỳ |
| **OpenStreetMap Foundation** | Yêu cầu tải ảnh bản đồ (kèm IP kỹ thuật) | Hiển thị bản đồ | Toàn cầu |

### 5.2. Chia sẻ công khai

Nội dung bạn đăng ở chế độ công khai (bài viết, story, bình luận, đánh giá, bảng xếp hạng thử thách) hiển thị cho người dùng khác kèm tên và ảnh đại diện của bạn. **Đây là do bạn chủ động chọn** và có thể đổi trong Cài đặt quyền riêng tư.

### 5.3. Yêu cầu pháp lý

Chúng tôi có thể tiết lộ dữ liệu khi có yêu cầu hợp pháp bằng văn bản của cơ quan nhà nước có thẩm quyền, hoặc khi cần thiết để bảo vệ tính mạng, an toàn của người dùng. Chúng tôi rà soát tính hợp lệ của mọi yêu cầu và chỉ cung cấp trong phạm vi tối thiểu.

### 5.4. Chuyển giao doanh nghiệp

Nếu có sáp nhập/chuyển nhượng, dữ liệu có thể được chuyển giao cùng dịch vụ. Bạn sẽ được thông báo trước và có quyền xoá tài khoản trước khi việc chuyển giao có hiệu lực.

### 5.5. Chuyển dữ liệu ra nước ngoài

Một phần dữ liệu được xử lý ngoài lãnh thổ Việt Nam (AWS Singapore, OpenAI/Google tại Hoa Kỳ, Brevo tại EU). Chúng tôi áp dụng: hợp đồng xử lý dữ liệu với điều khoản bảo mật, mã hoá khi truyền, tối thiểu hoá & che PII trước khi gửi tới nhà cung cấp AI.
🔧 *Trước khi công bố: hoàn tất và lưu **Hồ sơ đánh giá tác động chuyển dữ liệu cá nhân ra nước ngoài** theo quy định pháp luật Việt Nam về bảo vệ dữ liệu cá nhân, và nộp cho cơ quan có thẩm quyền nếu thuộc diện phải nộp.*

---

## 6. AI hoạt động thế nào với dữ liệu của bạn

Đây là phần quan trọng nhất — chúng tôi mô tả chi tiết vì trợ lý AI là tính năng cốt lõi.

### 6.1. Những gì được gửi tới nhà cung cấp mô hình AI

Khi bạn trò chuyện với CYN AI, hệ thống gửi tới OpenAI:

- nội dung tin nhắn bạn nhập;
- một **bản tóm tắt ngữ cảnh tối thiểu** cần cho câu trả lời (ví dụ: mục tiêu thể hình, mục tiêu calo hôm nay, lịch tập hôm nay, danh sách dị ứng);
- lịch sử hội thoại gần nhất trong phiên.

**Trước khi rời hạ tầng của chúng tôi, dữ liệu đi qua lớp che PII tự động** (loại bỏ/thay thế số điện thoại, email, số CMND/CCCD, số thẻ theo định dạng Việt Nam).

### 6.2. Những gì KHÔNG được gửi

- Mật khẩu, token, số dư ví chi tiết ngoài phạm vi câu hỏi.
- Ảnh/video của bạn — **tính năng phân tích ảnh bằng AI hiện đang TẮT**.
- Dữ liệu của người dùng khác. AI chỉ truy cập được dữ liệu trong phạm vi tài khoản của chính bạn.

### 6.3. Cam kết về huấn luyện mô hình

Chúng tôi sử dụng OpenAI qua **API dành cho doanh nghiệp**. Theo điều khoản của OpenAI cho kênh API, **dữ liệu gửi qua API không được dùng để huấn luyện mô hình**. OpenAI có thể lưu tạm tối đa 30 ngày cho mục đích phát hiện lạm dụng, sau đó xoá.
Chúng tôi cũng **không** dùng hội thoại của bạn để huấn luyện mô hình riêng của SYNC.

### 6.4. Bộ nhớ dài hạn của AI

Để trợ lý "nhớ" bạn giữa các phiên, hệ thống lưu:

| Loại | Nội dung | Nơi lưu | Xoá khi |
|---|---|---|---|
| Ghi nhớ dài hạn | Các dữ kiện/sở thích rút gọn (ví dụ "thích tập buổi sáng", "không ăn hải sản") + vector ngữ nghĩa | Postgres (AWS Singapore) | Bạn xoá tài khoản, hoặc yêu cầu xoá bộ nhớ AI |
| Trạng thái hội thoại | Lịch sử phiên chat | Redis (AWS Singapore) | Hết hạn theo thời gian chờ của phiên |
| Bộ nhớ đệm ngữ nghĩa | Câu trả lời đã sinh cho câu hỏi tương tự | Redis | Tự hết hạn sau **24 giờ** |
| Hành động đang chờ xác nhận | Đơn hàng/chi tiêu chờ bạn bấm xác nhận | Redis | Tự hết hạn sau **30 phút** |
| Nhật ký truy vết mỗi lượt | **Chỉ siêu dữ liệu**: mã truy vết, ý định, hạng mô hình, ngôn ngữ, thời gian, chi phí — **không lưu nội dung thô** | Postgres | Theo lịch xoá tại §7 |

### 6.5. Ranh giới an toàn của AI

- AI **không** chẩn đoán bệnh, không kê đơn, không đưa liều thuốc — xem [Tuyên bố miễn trừ y tế](/health-disclaimer).
- AI **không bao giờ** tự động tiêu tiền của bạn: mọi hành động phát sinh chi phí đều phải qua bước bạn xác nhận, kể cả khi bạn yêu cầu "đặt luôn không cần hỏi". Hạn mức chi tiêu tự động do bạn tự đặt.
- AI được cấu hình để **không bịa số liệu cá nhân** — mọi con số về calo, cân nặng, số dư, lịch tập đều lấy từ dữ liệu thật của bạn.
- AI tuyệt đối không gợi ý món ăn chứa dị nguyên bạn đã khai báo.

### 6.6. Quyền của bạn với AI

- Tắt nhắc nhở do AI tạo (`AllowAiGeneratedNotification`) và SmartPush bất cứ lúc nào.
- Yêu cầu **xoá toàn bộ bộ nhớ dài hạn của AI** mà không cần xoá tài khoản — gửi yêu cầu tới {{PRIVACY_EMAIL}}.
- Yêu cầu giải thích lý do AI đưa ra một đề xuất chi tiêu cụ thể (chúng tôi lưu ảnh chụp lập luận cho các giao dịch do AI khởi tạo).
- **Bạn không bị ra quyết định hoàn toàn tự động gây hậu quả pháp lý.** Mọi đề xuất của AI đều mang tính gợi ý và cần bạn xác nhận.

---

## 7. Thời gian lưu trữ

| Nhóm dữ liệu | Thời hạn lưu | Trạng thái |
|---|---|---|
| Tài khoản & hồ sơ (khi bạn còn dùng) | Cho tới khi bạn xoá tài khoản | ✅ Đang áp dụng |
| Sau khi bạn yêu cầu xoá tài khoản | **Ẩn danh ngay lập tức** + **thời gian chờ khôi phục 30 ngày**, sau đó xoá vĩnh viễn | ✅ Đang áp dụng (xem tài liệu [Xoá tài khoản](/account-deletion)) |
| Story | Tự hết hạn sau **24 giờ** | ✅ Đang áp dụng |
| Hành động chờ xác nhận (AI) | 30 phút | ✅ Đang áp dụng |
| Bộ nhớ đệm ngữ nghĩa AI | 24 giờ | ✅ Đang áp dụng |
| Hồ sơ giao dịch, hoá đơn, chứng từ thanh toán | **10 năm** kể từ ngày phát sinh, theo pháp luật kế toán Việt Nam — kể cả khi bạn đã xoá tài khoản, ở dạng **đã tách khỏi danh tính tối đa có thể** | ✅ Cam kết |
| Nhật ký bảo mật & vận hành máy chủ | 🔧 **90 ngày** | Cần cấu hình vòng đời log |
| Nhật ký truy vết AI (siêu dữ liệu) | 🔧 **180 ngày** | Cần thêm job dọn dẹp |
| Báo cáo vi phạm nội dung & kết quả xử lý | 🔧 **24 tháng** kể từ khi khép hồ sơ (phục vụ xử lý tái phạm & khiếu nại) | Cần thêm job dọn dẹp |
| Dữ liệu thống kê đã khử định danh | Không giới hạn (không còn là dữ liệu cá nhân) | ✅ |

> 🔧 = hạng mục cần bổ sung cơ chế tự động trước khi công bố chính sách này. **Không publish khi các mục 🔧 chưa được thực thi hoặc chưa chỉnh lại cam kết cho đúng thực tế.**

---

## 8. Bảo mật

- **Truyền tải:** toàn bộ kết nối dùng HTTPS/TLS. Ứng dụng Android đã **tắt hoàn toàn lưu lượng không mã hoá** (`usesCleartextTraffic="false"`).
- **Mật khẩu:** băm một chiều, không lưu bản gốc, không thể khôi phục.
- **Phiên đăng nhập:** refresh token lưu dạng băm; bạn có thể thu hồi bằng cách đăng xuất; xoá tài khoản thu hồi toàn bộ phiên trên mọi thiết bị.
- **Phân quyền:** kiến trúc microservice, mỗi dịch vụ chỉ truy cập dữ liệu trong phạm vi của mình; API nội bộ yêu cầu khoá riêng.
- **Tệp riêng tư** (ảnh cá nhân, story) lưu trong kho lưu trữ **không công khai**, chỉ truy cập qua liên kết ký số có thời hạn.
- **Chống lạm dụng AI:** lớp phát hiện tấn công tiêm lệnh (prompt injection), lọc nội dung độc hại, giới hạn tần suất.
- **Máy chủ đặt tại Singapore**, mã hoá dữ liệu khi lưu trữ ở tầng dịch vụ đám mây.

Không hệ thống nào an toàn tuyệt đối. Nếu xảy ra sự cố lộ lọt dữ liệu cá nhân, chúng tôi sẽ **thông báo cho bạn và cơ quan có thẩm quyền theo thời hạn luật định**, kèm mô tả sự cố và biện pháp khắc phục.

---

## 9. Quyền của bạn

Theo pháp luật Việt Nam về bảo vệ dữ liệu cá nhân, bạn có các quyền sau:

| Quyền | Thực hiện thế nào |
|---|---|
| **Được biết** dữ liệu nào đang được xử lý | Tài liệu này + mục Hồ sơ trong app |
| **Đồng ý / rút lại đồng ý** | Cài đặt → Quyền riêng tư (chia sẻ dữ liệu, marketing, SmartPush) |
| **Truy cập & xem** dữ liệu của mình | Trong app (Hồ sơ, Lịch sử tập/ăn/đơn hàng) |
| **Chỉnh sửa** dữ liệu không chính xác | Trực tiếp trong app |
| **Yêu cầu bản sao dữ liệu (data portability)** | Gửi email tới {{PRIVACY_EMAIL}} — chúng tôi trả về tệp máy đọc được trong **30 ngày** 🔧 *cần xây endpoint xuất dữ liệu* |
| **Xoá dữ liệu / xoá tài khoản** | Trong app: Hồ sơ → Tài khoản → Xoá tài khoản; hoặc tại `{{WEBSITE}}/account-deletion` |
| **Hạn chế / phản đối xử lý** | Gửi yêu cầu tới {{PRIVACY_EMAIL}} |
| **Khiếu nại** | Gửi tới {{PRIVACY_EMAIL}}; nếu không hài lòng, bạn có quyền khiếu nại tới cơ quan quản lý nhà nước có thẩm quyền về bảo vệ dữ liệu cá nhân |

**Thời hạn phản hồi:** chúng tôi xử lý mọi yêu cầu trong **tối đa 72 giờ** kể từ khi tiếp nhận đối với yêu cầu đơn giản, và **tối đa 30 ngày** đối với yêu cầu phức tạp (có thông báo lý do nếu cần gia hạn). Yêu cầu miễn phí; chúng tôi có thể từ chối các yêu cầu lặp lại quá mức hoặc rõ ràng thiếu căn cứ, kèm nêu lý do.

**Xác minh danh tính:** để bảo vệ bạn, chúng tôi yêu cầu yêu cầu được gửi từ chính email đã đăng ký tài khoản.

---

## 10. Trẻ em

SYNC **dành cho người từ 16 tuổi trở lên**. Người dưới 18 tuổi chỉ được sử dụng khi có sự đồng ý và giám sát của cha mẹ/người giám hộ, đặc biệt với các tính năng thanh toán.

Chúng tôi **không cố ý thu thập** dữ liệu của trẻ dưới 16 tuổi. Nếu phát hiện, chúng tôi sẽ khoá tài khoản và xoá dữ liệu. Cha mẹ/người giám hộ phát hiện con em mình đã đăng ký, vui lòng liên hệ {{PRIVACY_EMAIL}} — chúng tôi sẽ xử lý trong **72 giờ**.

Vì ứng dụng chứa dữ liệu sức khoẻ, mạng xã hội và giao dịch thương mại, ứng dụng **không** thuộc chương trình dành cho gia đình/trẻ em của các kho ứng dụng.

---

## 11. Cookie & công nghệ tương tự

Ứng dụng di động **không dùng cookie quảng cáo**. Ứng dụng lưu dữ liệu cục bộ trên thiết bị (token đăng nhập trong kho lưu trữ bảo mật của hệ điều hành, cài đặt hiển thị).

Website `{{WEBSITE}}` chỉ dùng cookie/bộ nhớ cục bộ **cần thiết** cho đăng nhập và ghi nhớ lựa chọn giao diện. Không cookie theo dõi quảng cáo.

---

## 12. Người dùng ngoài Việt Nam

Dịch vụ hướng tới người dùng tại Việt Nam. Nếu bạn truy cập từ khu vực khác (EU/EEA, Anh), bạn vẫn được hưởng các quyền tương đương nêu tại §9. Dữ liệu của bạn sẽ được xử lý tại Singapore và các quốc gia nêu tại §5.

---

## 13. Thay đổi chính sách

Khi cập nhật, chúng tôi sẽ đăng phiên bản mới tại `{{WEBSITE}}/privacy` kèm ngày hiệu lực. Với **thay đổi trọng yếu** (mở rộng mục đích xử lý, thêm bên nhận dữ liệu mới, thay đổi cam kết tại §2), chúng tôi sẽ:

1. thông báo trong ứng dụng và qua email **ít nhất 15 ngày trước** ngày hiệu lực; và
2. xin lại sự đồng ý nếu thay đổi liên quan tới dữ liệu nhạy cảm.

Lịch sử phiên bản được lưu công khai để bạn đối chiếu.

---

## 14. Liên hệ

| Mục đích | Kênh |
|---|---|
| Dữ liệu cá nhân, quyền riêng tư, rút đồng ý | **{{PRIVACY_EMAIL}}** |
| Hỗ trợ chung, khiếu nại dịch vụ | **{{SUPPORT_EMAIL}}** |
| Báo cáo nội dung vi phạm | **{{ABUSE_EMAIL}}** |

---

*Tài liệu này được soạn dựa trên chức năng thực tế của sản phẩm tại thời điểm ban hành. Bản tiếng Anh: `/en/privacy`.*
