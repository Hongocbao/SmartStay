# Hướng Dẫn Deploy Hệ Thống SmartStay Lên Render (2 Link Chạy Song Song + Phương Án A Supabase)

## 1. Kiến trúc 2 Dịch vụ độc lập chạy song song trên Render

File [`render.yaml`](../render.yaml) đã được cấu hình sẵn theo chuẩn **Render Blueprint** để tự động tạo **2 đường link riêng biệt chạy song song** trên cùng 1 cơ sở dữ liệu **Supabase PostgreSQL (`odasdzyuriucofavonjl`)**:

| Dịch vụ Render | Loại dịch vụ (Gói Free) | Đường dẫn (URL) dự kiến | Đối tượng & Vai trò |
| :--- | :--- | :--- | :--- |
| **`smartstay-admin`** | **Web Service (Docker .NET 8)** | `https://smartstay-admin.onrender.com` | **Ban Quản Lý & Kỹ Thuật (Web Admin)** + Cổng API/SignalR điều khiển toàn hệ thống |
| **`smartstay-client`** | **Static Site (Flutter Web)** | `https://smartstay-client.onrender.com` | **Web App Cư Dân (`P.305`) & Kỹ Thuật** (Không bao giờ ngủ đông, không giới hạn 750h/tháng) |

### Cơ chế Phương án A (Supabase Direct + Realtime) kết hợp Điều khiển Liên thông:
- **Ghi & Điều khiển từ Admin (`smartstay-admin`)**: Khi Admin thao tác trên `smartstay-admin` (Đổi trạng thái phòng, duyệt hóa đơn VietQR, tạo/chuyển trạng thái phiếu Kanban, phát thông báo tòa nhà), dữ liệu được ghi thẳng vào **Supabase PostgreSQL**.
- **Đọc trực tiếp từ Supabase theo Phương án A (`smartstay-client`)**: Ứng dụng Flutter Web (`smartstay-client`) tích hợp [`SupabaseDirectService`](../SmartStay/lib/services/supabase_direct_service.dart) sử dụng `SUPABASE_URL` và `SUPABASE_ANON_KEY` (`sb_publishable_...`) để đọc/ghi trực tiếp qua cổng PostgREST của Supabase (`/rest/v1/Phong`, `/rest/v1/PhieuSuCo`, `/rest/v1/ThongBao`) kết hợp cổng `/api/sync/snapshot`.
- **Tự động kích hoạt RLS & Realtime không mất dữ liệu**: File [`database/supabase_rls_and_realtime_option_a.sql`](../database/supabase_rls_and_realtime_option_a.sql) tự động bật `supabase_realtime` và cấu hình **Row Level Security (RLS)** trên đúng bộ 40 bảng hiện có của dự án mà **không xóa (`DROP`) bất kỳ bảng hay dữ liệu nào**.

---

## 2. Các bước đưa lên Render (Chỉ mất 3 phút)

### Bước 1: Đẩy code lên GitHub
Chạy lệnh sau tại thư mục gốc `E:\DAN_ChuyenNganh`:
```powershell
git add .
git commit -m "Setup Render Blueprint dual-link Admin + Client with Supabase Option A"
git push origin main
```

### Bước 2: Tạo Blueprint trên Render
1. Đăng nhập vào [https://dashboard.render.com](https://dashboard.render.com).
2. Bấm nút **New +** (góc trên bên phải) $\rightarrow$ chọn **Blueprint**.
3. Kết nối tới kho lưu trữ GitHub của bạn. Render sẽ tự động nhận diện file [`render.yaml`](../render.yaml) và hiển thị 2 dịch vụ:
   - `smartstay-admin` (Docker Web Service)
   - `smartstay-client` (Static Site)
4. Nhập biến môi trường duy nhất được hỏi là **`ConnectionStrings__DefaultConnection`**:
   - Dán chuỗi kết nối PostgreSQL của Supabase (lấy trong **Supabase Dashboard $\rightarrow$ Connect $\rightarrow$ Session Pooler / Transaction Pooler (.NET)**):
     ```text
     User Id=postgres.odasdzyuriucofavonjl;Password=<MAT_KHAU_SUPABASE_CUA_BAN>;Server=aws-0-ap-southeast-1.pooler.supabase.com;Port=5432;Database=postgres;SSL Mode=Require;Trust Server Certificate=true
     ```
   - *(Lưu ý: Các biến `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_BASE_URL` và `Jwt__Key` đã được cấu hình tự động trong `render.yaml`, bạn không cần nhập tay).*
5. Bấm **Apply / Approve** để Render tiến hành build song song cả 2 link!

---

## 3. Kiểm tra chạy song song 2 Link sau khi Deploy
1. Mở **Tab 1 (Web Admin)**: `https://smartstay-admin.onrender.com/Account/Login` $\rightarrow$ Đăng nhập tài khoản **Ban Quản Lý & Kỹ Thuật** (`admin` / `123456`).
2. Mở **Tab 2 (Web App Client)**: `https://smartstay-client.onrender.com` $\rightarrow$ Đăng nhập tài khoản **Cư Dân P.305** (`2380600133` / `123456`).
3. Khi bạn đổi trạng thái phòng, tạo phiếu sự cố hoặc đăng thông báo bên **Tab 1 (`smartstay-admin`)**, bên **Tab 2 (`smartstay-client`)** sẽ tự động đồng bộ sau mỗi 12 giây (hoặc bấm nút xanh **`Supabase Realtime: SmartStayDB`** trên thanh Topbar để đồng bộ tức thì).
