---
trigger: always_on
---

# Quy chuẩn Đồ án SmartStay

1. **Kiến trúc song song**:
   - `SmartStay.Web` (.NET 8 MVC + API + SignalR, deploy tại `https://smartstay-admin.onrender.com`).
   - `SmartStay` (Flutter App & Web, deploy static `SmartStay/build/web` tại `https://smartstay-client-rp4w.onrender.com`).
2. **Thiết kế giao diện Mobile-First**:
   - Mọi trang Admin (Razor Views) phải hiển thị tốt ở chiều rộng `375px` (iPhone SE) lẫn desktop: sidebar off-canvas dưới `991.98px`, nút hamburger `40x40px`, thẻ KPI 2 cột (`col-6 col-xl-3`), header card dùng `flex-wrap`, mọi bảng bọc trong `.table-responsive`.
   - Giao diện Flutter phải tuân thủ chuẩn touch target tối thiểu `44-48px`, tránh tràn chữ (`overflow`) và giữ đồng nhất hệ màu Indigo/Slate của SmartStay.
3. **Quy tắc Build & Deploy**:
   - Không bao giờ commit `SmartStay/build/web` mà thiếu `--dart-define=API_BASE_URL=https://smartstay-admin.onrender.com/api` cùng cấu hình Supabase và `ADMIN_PORTAL_URL`.
   - Sau khi sửa code web/API, nhắc hoặc kiểm tra build/render deploy tương ứng.
