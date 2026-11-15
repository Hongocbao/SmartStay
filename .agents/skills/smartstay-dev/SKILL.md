---
name: smartstay-dev
description: >-
  Use this skill when developing, styling, debugging, building, or deploying any part of the
  SmartStay project (both SmartStay.Web .NET 8 Admin/API and SmartStay Flutter Client/Web).
---

# SmartStay Project Development Runbook

## 1. Kiến trúc hệ thống & Deploy trên Render
Hệ thống gồm 2 dịch vụ chạy song song:

1. **`SmartStay.Web`** (.NET 8 MVC + Web API + SignalR + EF Core SQL Server / Supabase PostgreSQL)
   - Production URL: `https://smartstay-admin.onrender.com`
   - Health check: `/api/health`
   - Đóng vai trò cả cổng Web Admin/Kỹ thuật/Cư dân (Razor Views) và Backend REST API (`/api/*`) + SignalR Hub (`/hub/smartstay`).
   - CORS cho phép mọi origin `*.onrender.com`, `localhost`, `127.0.0.1`.

2. **`SmartStay`** (Flutter Mobile & Web App cho Cư dân & Kỹ thuật)
   - Production URL: `https://smartstay-client-rp4w.onrender.com`
   - Trên Render là static site phục vụ trực tiếp thư mục `SmartStay/build/web` đã build sẵn trong Git (không chạy `flutter build` trên Render).

---

## 2. Quy chuẩn Responsive Mobile cho Admin Web (`SmartStay.Web`)
Áp dụng cho `SmartStay.Web/Views/Shared/_Layout.cshtml` và toàn bộ các view (`Views/Home`, `Views/Phong`, `Views/SuCo`, `Views/HoaDon`, `Views/HopDong`, `Views/ThongBao`, `Views/CuDan`):

- **Sidebar & Topbar (`< 991.98px`)**:
  - Sidebar chuyển sang chế độ off-canvas (`transform: translateX(-100%)`, width `280px`), chỉ trượt ra khi `body.sidebar-open`.
  - Hiển thị nút hamburger `.menu-toggle` kích thước `40x40px` trên topbar và `.sidebar-close` + `.sidebar-overlay` để đóng dễ dàng.
  - `.main-wrapper` đặt `margin-left: 0` trên mobile.
- **KPI Cards & Grid (`< 575.98px`)**:
  - Các thẻ KPI trên Dashboard xếp 2 cột trên điện thoại bằng `col-6 col-xl-3` (kèm class `.kpi-card` thu gọn padding `12px`, font-size và badge).
  - Các header card có nút/dropdown ở góc phải phải dùng `d-flex flex-wrap gap-2 justify-content-between align-items-center`.
- **Bảng dữ liệu & Biểu đồ**:
  - Mọi `<table>` phải nằm trong `<div class="table-responsive">` để cuộn ngang mượt mà, không làm vỡ layout màn hình hẹp.
  - `<canvas>` biểu đồ giới hạn `max-width: 100% !important` và giảm chiều cao `.chart-box` trên mobile.

---

## 3. Quy trình Build & Deploy Flutter Web bắt buộc
Mỗi khi chỉnh sửa mã nguồn Flutter trong `SmartStay/`, **bắt buộc** build lại bản web release kèm đầy đủ `--dart-define` (nếu thiếu `API_BASE_URL`, app sẽ fallback về `http://localhost:5096/api` và lỗi `ERR_CONNECTION_REFUSED` trên Render):

```powershell
cd e:\DAN_ChuyenNganh\SmartStay
flutter build web --release --dart-define=API_BASE_URL=https://smartstay-admin.onrender.com/api --dart-define=SUPABASE_URL=https://odasdzyuriucofavonjl.supabase.co --dart-define=SUPABASE_ANON_KEY=sb_publishable_GYfWQ4xJCkpgxjI2XBNVmg_6eWoUWP7 --dart-define=ADMIN_PORTAL_URL=https://smartstay-admin.onrender.com
```

Sau khi build xong, kiểm tra `SmartStay/build/web/main.dart.js` đã chứa `smartstay-admin.onrender.com/api`, rồi mới commit và push thư mục `SmartStay/build/web` lên nhánh `main`.
