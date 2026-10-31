# SMARTSTAY – HỆ THỐNG QUẢN TRỊ HỆ SINH THÁI LƯU TRÚ THÔNG MINH ĐA NỀN TẢNG

> **Đồ án Chuyên ngành Công nghệ Thông tin / Kỹ thuật Phần mềm**  
> Thành viên thực hiện:  
> • **Hồ Ngọc Bảo** (MSSV: `2380600133`)  
> • **Nguyễn Dương Bảo** (MSSV: `2380600154`)  
> • **Trần Hoàng Gia Bảo** (MSSV: `2380600178`)  

---

## 1. Tổng Quan Kiến Trúc Đồ Án

Hệ sinh thái **SmartStay** được thiết kế hiện đại, giải quyết trọn vẹn bài toán quản lý vận hành căn hộ Co-Living và ký túc xá thông minh:

```
E:\DAN_ChuyenNganh
├── database/                                # Kịch bản CSDL SQL Server & MySQL
│   ├── upgrade_smartstay_enterprise.sql     # Script nâng cấp CSDL lên 46 bảng Enterprise
│   └── schema_mysql.sql                     # Script dự phòng MySQL
│
├── SmartStay/                               # ỨNG DỤNG FLUTTER ALL-IN-ONE (MỞ BẰNG ANDROID STUDIO)
│   ├── lib/
│   │   ├── models/                          # Data Models (User, Room, Ticket, Invoice, IoT, Contract...)
│   │   ├── providers/                       # State Management (Auth, Admin, Ticket, Invoice, AI Chat...)
│   │   ├── screens/
│   │   │   ├── auth/                        # Màn hình đăng nhập & bảo mật
│   │   │   ├── home/                        # Trang chủ Cư dân P.305 (Hồ Ngọc Bảo)
│   │   │   ├── invoice/                     # Chi tiết hóa đơn bậc thang & VietQR NAPAS 247
│   │   │   ├── ticket/                      # Báo hỏng thiết bị 3 bước, đánh giá sao
│   │   │   ├── community/                   # Bảng tin nội khu & sự kiện KTXRace 2026
│   │   │   ├── profile/                     # Hợp đồng điện tử & 5 tài sản bàn giao
│   │   │   ├── ai_chat/                     # Trợ lý ảo AI Gemini 24/7 hỗ trợ cư dân
│   │   │   ├── admin/                       # PHÂN HỆ QUẢN LÝ VẬN HÀNH & KỸ THUẬT:
│   │   │   │   ├── admin_dashboard_screen.dart    # Dashboard KPI, lấp đầy %, doanh thu
│   │   │   │   ├── admin_room_matrix_screen.dart  # Sơ đồ phòng 5 tầng, Check-in / Check-out
│   │   │   │   ├── admin_kanban_screen.dart       # Kanban 3 cột, phân công KTV
│   │   │   │   ├── admin_finance_screen.dart      # Phát hành hóa đơn bậc thang, đối soát VietQR
│   │   │   │   └── admin_iot_screen.dart          # Giám sát khóa IoT, pin %, mở cửa từ xa
│   │   │   └── main_layout.dart             # Điều hướng động kèm nút "Chuyển Đổi Vai Trò" (Multi-Role)
│   │   ├── services/                        # MockDataService & ApiService kết nối Backend
│   │   └── utils/                           # Formatters (VNĐ, ngày giờ, trạng thái)
│   └── pubspec.yaml
│
├── SmartStay.Api/                           # BACKEND RESTful API (.NET 8 + EF Core + SignalR)
│   ├── Controllers/                         # AuthController, PhongController, HoaDonController, SuCoController, TroLyAiController
│   ├── Data/SmartStayDbContext.cs           # EF Core Database-First ánh xạ từ SQL Server
│   ├── Hubs/SmartStayHub.cs                 # SignalR Realtime Hub cho Room Matrix & Kanban
│   └── Program.cs
│
└── SmartStay.Web/                           # Phân hệ Web Admin MVC (Dự phòng cho báo cáo Web)
```

---

## 2. Cơ Sở Dữ Liệu SQL Server Thực Tế

- **Máy chủ SQL Server:** `MSI-Bao\SQLEXPRESS`
- **Tên CSDL:** `SmartStayDB`
- **Quy mô:** **46 bảng vật lý chuẩn Enterprise**
  - **Nhóm Lưu trú & Phòng:** `ToaNha`, `Tang`, `Phong`, `Giuong`, `LoaiPhong`, `TienNghi`, `HopDongThue`, `DanhSachTaiSanBanGiao`, `LichSuChuyenPhong`.
  - **Nhóm Cư dân & Khách:** `NguoiDung`, `VaiTro`, `CuDan`, `KhachLuuTru`, `PhuongTienCuDan`, `PhieuDatGiuCho`.
  - **Nhóm Tài chính & VietQR:** `HoaDon`, `ChiTietHoaDon`, `BieuGiaDien`, `BieuGiaNuoc`, `LichSuDongTien`, `WebhookGiaoDichNganHang`, `ViCuDan`, `LichSuGiaoDichVi`, `SoQuyThuChi`.
  - **Nhóm Sự cố & Kanban:** `PhieuBaoSuCo`, `NhatKyXuLySuCo`, `HinhAnhSuCo`, `DanhGiaSuCo`, `VatTuLinhKien`, `PhieuXuatVatTuSuCo`.
  - **Nhóm IoT Smart Lock & Ra vào:** `ThietBiIoT`, `LichSuTruyCapCua`, `LichSuRaVaoToaNha`.
  - **Nhóm Tiện ích & AI:** `ThongBao`, `SuKienCongDong`, `DangKySuKien`, `TriThucAiRAG`.
- **Views & Stored Procedures:**
  - `v_SoDoPhongRealTime`: Trạng thái phòng theo thời gian thực.
  - `v_BaoCaoDoanhThuTheoToaNha`: Báo cáo doanh thu tài chính theo tòa nhà.
  - `sp_PhatHanhHoaDonThangTuDong`: Tự động tính tiền điện nước lũy tiến bậc thang và phát hành hóa đơn hàng loạt.
  - `trg_PhieuSuCo_GhiNhatKyKanban`: Tự động đồng bộ lịch sử Kanban khi trạng thái sự cố thay đổi.

---

## 3. Hướng Dẫn Mở & Chạy Dự Án Trong Android Studio

### Bước 1: Mở Android Studio
1. Mở **Android Studio**.
2. Chọn **Open** (hoặc `File -> Open...`).
3. Điều hướng và chọn thư mục: `E:\DAN_ChuyenNganh\SmartStay`.
4. Đợi Android Studio hoàn tất việc tải project và index thư viện.

### Bước 2: Khởi chạy
1. Chọn thiết bị đích trên thanh công cụ:
   - **Máy ảo Android Emulator** (Pixel / Samsung bất kỳ).
   - Hoặc **Thiết bị thật** (cắm cáp USB bật USB Debugging).
   - Hoặc **Chrome (web)** / **Windows (desktop)** nếu muốn chạy xem giao diện rộng trên máy tính.
2. Bấm nút **Run (tam giác xanh)** hoặc nhấn tổ hợp `Shift + F10`.

---

## 4. Kịch Bản Demo Cho Thầy Cô & Hội Đồng Đánh Giá

Ứng dụng tích hợp huy hiệu **"Chuyển Đổi Vai Trò"** cố định ở góc trên bên phải màn hình. Chỉ cần bấm vào huy hiệu này để chuyển đổi tức thì giữa 3 phân hệ:

### Kịch bản 1: Phân hệ Cư dân (Resident)
- **Tài khoản:** `Hồ Ngọc Bảo` – Phòng `P.305`.
- **Hóa đơn & Biểu giá bậc thang:** Xem chi tiết hóa đơn tháng 10. Điện nước được bóc tách minh bạch theo từng bậc (Bậc 1, Bậc 2, Bậc 3, Bậc 4) khớp chính xác với công thức Bộ Công Thương.
- **Thanh toán VietQR NAPAS 247:** Bấm "Thanh toán VietQR ngay" để sinh mã QR động chứa sẵn số tài khoản, số tiền và nội dung `HD 2026 10 305`. Có tính năng tải ảnh chụp biên lai chuyển khoản.
- **Báo sự cố thiết bị:** Tạo phiếu báo hỏng 3 bước (Máy lạnh kêu to, rò rỉ nước), tải ảnh chụp, theo dõi tiến độ xử lý và chấm điểm 5★ sau khi hoàn thành.
- **Trợ lý ảo AI Gemini 24/7:** Hỏi đáp nội quy tòa nhà, cách tính tiền điện nước, quy định gửi xe qua giao diện AI Chat.

### Kịch bản 2: Phân hệ Ban Quản lý (Admin Portal)
- **Bàn điều hành (Dashboard):** Xem KPI tỷ lệ lấp đầy %, tổng doanh thu tháng, sự cố tồn đọng, danh sách cảnh báo pin khóa IoT.
- **Sơ đồ phòng trực quan (Room Matrix):** Bản đồ phòng 5 tầng trực quan:
  - Bấm vào phòng Trống -> Chọn **"Nhận phòng (Check-in)"** để ký hợp đồng mới.
  - Bấm vào phòng Đang ở -> Chọn **"Ghi chỉ số điện nước"**, **"Mở khóa từ xa"**, hoặc **"Trả phòng (Check-out)"**.
- **Bảng Kanban Sự cố:** Quản lý quy trình 3 cột (Chờ xử lý -> Đang sửa -> Hoàn thành). Chọn nút **"Phân công Kỹ thuật viên"** (gán cho KTV Trần Văn Tuấn / Lê Minh Khang).
- **Tài chính & Đối soát:** Bấm nút **"⚡ Phát Hành Hóa Đơn Tự Động Toàn Hệ Sinh Thái"** để kích hoạt thuật toán tính bậc thang cho tất cả các phòng đang ở. Bấm **"Xác Nhận Đối Soát Biên Lai VietQR"** để khớp lệnh thanh toán.
- **Khóa thông minh IoT & Nhật ký cửa:** Giám sát 20 khóa thông minh (mức pin %, trạng thái online WiFi), xem lịch sử quẹt thẻ RFID/vân tay, bấm mở khóa từ xa trực tiếp.

### Kịch bản 3: Phân hệ Kỹ thuật viên (Technician)
- Xem bảng việc cần làm trong ngày do Ban Quản lý phân công.
- Cập nhật ghi chú sửa chữa và xác nhận hoàn thành công việc.

---

## 5. Hướng Dẫn Chạy Backend API (Nếu Cần Kết Nối Trực Tiếp)

Backend API đã được xây dựng sẵn sàng và biên dịch thành công 100%:

```bash
cd E:\DAN_ChuyenNganh\SmartStay.Api
dotnet run
```
* Swagger UI: **http://localhost:5000/swagger** (hoặc http://localhost:5000)
* SignalR Hub: **http://localhost:5000/smartstay-hub**

---

## 6. Tổng Kết Trạng Thái Kỹ Thuật

- ✅ CSDL SQL Server: Đã nâng cấp 46 bảng trên `MSI-Bao\SQLEXPRESS`.
- ✅ Backend .NET 8 API: Build thành công (0 Errors).
- ✅ Flutter App: `dart analyze` kiểm tra đạt chuẩn **`No issues found!` (0 Errors, 0 Warnings)**.
- ✅ Tích hợp All-in-One: Toàn bộ hệ thống chạy trọn vẹn trong Android Studio.
