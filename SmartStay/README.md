# SMARTSTAY MOBILE APP – HỆ SINH THÁI QUẢN TRỊ LƯU TRÚ THÔNG MINH

Ứng dụng di động đa nền tảng (Android, iOS, Web, Windows Desktop) xây dựng bằng **Flutter**, phục vụ trọn vẹn 3 nhóm người dùng: **Cư dân**, **Quản lý vận hành (Admin)** và **Kỹ thuật viên**.

---

## 🌟 Tính Năng Trọng Tâm

### 1. Phân Hệ Cư Dân (Resident)
- **Hóa đơn & Biểu giá bậc thang lũy tiến**: Bóc tách chi tiết 4 bậc điện sinh hoạt (1.800 đ - 3.200 đ/kWh) và 3 bậc nước (12.000 đ - 18.000 đ/m³) theo quy định.
- **Thanh toán VietQR Napas 247**: Mã QR động sinh tự động chuẩn Open API (img.vietqr.io) chứa số tiền và cú pháp chuyển khoản chính xác; hỗ trợ chụp/gửi ủy nhiệm chi đối soát.
- **Báo sự cố thiết bị thông minh**: Tích hợp **AI Triage** tự động phân tích mô tả hiện trường để gợi ý danh mục và nâng mức độ ưu tiên Khẩn cấp (SLA 4h).
- **Cảnh báo bất thường điện nước**: Thuật toán phát hiện lượng điện nước tăng đột biến (>30%) so với mức trung bình để cảnh báo nguy cơ rò rỉ hoặc quá tải thiết bị.
- **Trợ lý ảo AI Contextual**: AI Chat đọc trực tiếp dữ liệu hóa đơn, phòng và hợp đồng của cư dân để giải đáp nguyên nhân tiền điện tăng và gợi ý mẹo tiết kiệm.
- **Tiện ích cư dân trên app**: Có màn hình riêng gồm chia hóa đơn theo đầu người, tạo PIN khách demo, nhập chỉ số điện/nước và cảnh báo mức tiêu thụ bất thường, cùng chợ đồ cũ nội khu.

> Chia hóa đơn, PIN khách, ghi nhận công tơ và chợ đồ cũ hiện là tiện ích demo cục bộ trên app. OCR ảnh, tích hợp khóa IoT, QR thanh toán từng thành viên và đồng bộ các tiện ích này lên backend cần API tương ứng.

### 2. Phân Hệ Quản Lý Vận Hành (Admin & Operation)
- **Sơ đồ phòng (Room Matrix 5 tầng)**: Giám sát trạng thái phòng thời gian thực (Đang ở, Trống, Đã đặt, Bảo trì).
- **Quy trình Check-in & Check-out hoàn cọc**: Tự động tính toán chiết tính thanh lý hợp đồng: `Hoàn cọc = Tiền cọc - Hư hao cơ sở vật chất - Nợ hóa đơn tồn đọng`, xuất biên bản bàn giao nghiệm thu.
- **Đối soát thanh toán VietQR**: Xem ủy nhiệm chi cư dân gửi, phê duyệt số tiền thực nhận (hỗ trợ thanh toán từng phần) hoặc từ chối kèm lý do phản hồi.
- **Tự động phát hành hóa đơn hàng loạt**: Thuật toán đọc chỉ số công tơ, áp dụng biểu giá bậc thang và sinh hóa đơn đồng loạt cho tất cả các phòng đang ở.

### 3. Phân Hệ Kỹ Thuật Viên & Kanban Sự Cố
- **Kanban 3 cột**: Chờ xử lý -> Đang sửa -> Hoàn thành.
- **Luồng xử lý chuẩn đặc tả**: Khi được phân công, phiếu sự cố vẫn giữ "Chờ xử lý" cho đến khi Kỹ thuật viên có mặt tại phòng bấm "Bắt đầu sửa chữa".
- **SLA Countdown Timer**: Đếm ngược thời gian cam kết sửa chữa (Khẩn cấp 4h, Cao 12h, Trung bình 24h, Thấp 48h), cảnh báo viền đỏ khi quá hạn.
- **Nhật ký kiểm toán (Audit Logs)**: Ghi lại đầy đủ lịch sử ai phân công, ai bắt đầu và chi phí vật tư linh kiện khi hoàn thành.

---

## 🛠 Kiến Trúc Kỹ Thuật

- **Framework:** Flutter 3.x / Dart 3.x
- **State Management:** `MultiProvider` & `ChangeNotifier` (Single Source of Truth với `InvoiceDataService`)
- **Backend API:** Kết nối ASP.NET Core Web API 8.0 / 9.0 (.NET)
- **Kiến trúc Resilient / Offline-First:** Tự động phát hiện Backend Online/Offline; nếu Backend offline, hệ thống tự động fallback sang Local Data Service để quá trình chấm thi / demo luôn mượt mà.
- **Package Id:** `vn.smartstay.app`

---

## 🚀 Hướng Dẫn Chạy Trong Android Studio

1. Mở **Android Studio** -> Chọn **File -> Open...** -> Chọn thư mục `SmartStay`.
2. Mở file `lib/main.dart`.
3. Chọn thiết bị đích (Android Emulator, Chrome Web hoặc Windows Desktop).
4. Bấm **Run (Shift + F10)**.
5. Trên màn hình đăng nhập, có thể chọn nhanh 1-chạm vào các tài khoản Demo:
   - **Cư dân:** `2380600133` / `123456` (Hồ Ngọc Bảo - P.305)
   - **Quản lý:** `admin` / `123456` (Nguyễn Hoàng Nam)
   - **Kỹ thuật:** `kythuat` / `123456` (Nguyễn Văn Bình)
