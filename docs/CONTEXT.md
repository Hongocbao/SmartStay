# BỐI CẢNH DỰ ÁN SMARTSTAY

## 1. Thông tin chung
- **Đề tài:** "Xây dựng hệ thống quản trị hệ sinh thái lưu trú thông minh đa nền tảng" (SmartStay)
- **Phạm vi phục vụ:** Ký túc xá thông minh (Sleepbox/Co-living), nhà trọ, chuỗi căn hộ dịch vụ (Serviced Apartment), homestay.
- **Tác nhân hệ thống (Actors):**
  1. **Admin (Quản trị viên):** Kế thừa toàn bộ quyền của Quản lý vận hành, quản lý nhân sự, phân quyền vai trò, cấu hình đơn vị, xem báo cáo tài chính & nhật ký kiểm toán.
  2. **Quản lý vận hành (Operation Manager):** Quản lý tòa nhà, sơ đồ phòng (Room Matrix), cư dân, hợp đồng, thủ tục Check-in/Check-out, chốt chỉ số điện nước, phát hành hóa đơn bậc thang, đối soát thanh toán, điều phối sự cố Kanban, đăng thông báo & tổ chức sự kiện.
  3. **Nhân viên kỹ thuật (Technician):** Xem phiếu sự cố được phân công trên giao diện rút gọn di động, cập nhật tiến độ sửa chữa, tải ảnh nghiệm thu & chi phí vật tư.
  4. **Cư dân (Resident):** Sử dụng ứng dụng di động Flutter để tra cứu hợp đồng & tài sản bàn giao, xem chi tiết hóa đơn bậc thang, quét mã VietQR & tải ảnh biên lai thanh toán, gửi báo cáo sự cố kèm ảnh/video, đánh giá kết quả sửa chữa, xem bảng tin & đăng ký sự kiện, trò chuyện với Trợ lý ảo AI 24/7.

## 2. Kiến trúc kỹ thuật
- **Backend API (`SmartStay.Api`):** ASP.NET Core Web API (.NET 8), Entity Framework Core, SQL Server / MySQL, xác thực JWT, truyền tải thời gian thực SignalR, QuestPDF, ClosedXML, BCrypt.Net-Next.
- **Web Admin (`SmartStay.Web`):** ASP.NET Core MVC (.NET 8), Bootstrap 5, Chart.js.
- **Mobile App (`SmartStay`):** Flutter (Android/iOS, Material 3, tiếng Việt), quản lý trạng thái với `provider`, gọi API qua `dio` (kèm JWT interceptor) + chế độ Demo/Offline fallback để kiểm thử mượt mà.

## 3. Cấu trúc Cơ sở dữ liệu (32 bảng - Tên tiếng Việt không dấu, Khóa chính `MaXxx`)

### Nhóm 1: Tài khoản, Phân quyền & Cấu hình
1. `VaiTro` (`MaVaiTro`, `TenVaiTro`, `MoTa`)
2. `NguoiDung` (`MaNguoiDung`, `TenDangNhap`, `ThuDienTu`, `SoDienThoai`, `MaBamMatKhau`, `HoTen`, `MaVaiTro`, `DangHoatDong`, `CanDoiMatKhau`, `LanDangNhapCuoi`, `NgayTao`)
3. `MaDatLaiMatKhau` (`MaToken`, `MaNguoiDung`, `MaXacThuc`, `HanSuDung`, `DaSuDung`, `NgayTao`)
4. `NhatKyKiemToan` (`MaNhatKy`, `MaNguoiDung`, `HanhDong`, `TenBang`, `MaBanGhi`, `GiaTriCu`, `GiaTriMoi`, `ThoiGian`)
5. `CauHinhDonVi` (`MaCauHinh`, `TenDonVi`, `DiaChi`, `SoDienThoai`, `ThuDienTu`, `MaNganHangBin`, `TenNganHang`, `SoTaiKhoan`, `TenChuTaiKhoan`, `SoNgayHanThanhToan`, `NoiQuyToaNha`)

### Nhóm 2: Hạ tầng Tòa nhà & Phòng
6. `ToaNha` (`MaToaNha`, `TenToaNha`, `DiaChi`, `TongSoTang`, `MoTa`, `DangHoatDong`)
7. `LoaiPhong` (`MaLoaiPhong`, `TenLoaiPhong`, `DonGiaCoBan`, `SucChuaToiDa`, `DienTichMacDinh`, `MoTa`)
8. `Phong` (`MaPhong`, `MaToaNha`, `MaLoaiPhong`, `MaSoPhong`, `SoTang`, `DienTich`, `SucChua`, `GiaThue`, `TrangThai`, `GhiChu`)
   - *Giá trị `TrangThai`:* `Trống`, `Đang ở`, `Bảo trì`, `Đã đặt`
9. `TaiSanPhong` (`MaTaiSan`, `MaPhong`, `TenTaiSan`, `SoLuong`, `TinhTrang`, `GiaTriDenBu`, `DuongDanAnh`)

### Nhóm 3: Cư dân, Hợp đồng & Bàn giao
10. `CuDan` (`MaCuDan`, `MaNguoiDung`, `NgaySinh`, `GioiTinh`, `SoCanCuoc`, `DiaChiThuongTru`, `NguoiLienHeKhanCap`, `SdtKhanCap`)
11. `HopDong` (`MaHopDong`, `MaSoHopDong`, `MaPhong`, `NgayBatDau`, `NgayKetThuc`, `TienThueHangThang`, `TienDatCoc`, `DieuKhoan`, `TrangThai`, `NgayTao`)
    - *Giá trị `TrangThai`:* `Nháp`, `Đang hiệu lực`, `Hết hạn`, `Đã thanh lý`
12. `CuDanHopDong` (`MaHopDong`, `MaCuDan`, `LaDaiDien`, `NgayVaoO`, `NgayRoiDi`)
13. `BienBanBanGiao` (`MaBienBan`, `MaHopDong`, `LoaiBienBan`, `NgayBanGiao`, `ChiSoDien`, `ChiSoNuoc`, `KhauTruHuHong`, `KhauTruCongNo`, `SoTienHoanCoc`, `GhiChu`)
    - *Giá trị `LoaiBienBan`:* `CheckIn`, `CheckOut`
14. `TaiSanBanGiao` (`MaChiTietBanGiao`, `MaBienBan`, `MaTaiSan`, `TenTaiSan`, `SoLuong`, `TinhTrang`, `ChiPhiDenBu`, `DuongDanAnh`)

### Nhóm 4: Dịch vụ, Điện nước bậc thang & Hóa đơn
15. `DichVu` (`MaDichVu`, `TenDichVu`, `DonViTinh`, `LoaiDichVu`, `DonGiaCoDinh`, `DangHoatDong`)
    - *Giá trị `LoaiDichVu`:* `BacThang` (Điện, Nước), `CoDinh` (Rác, Wifi, Giữ xe, Quản lý)
16. `BacGia` (`MaBacGia`, `MaDichVu`, `ThuTuBac`, `TuSo`, `DenSo`, `DonGia`, `NgayApDung`, `NgayKetThuc`)
17. `DichVuHopDong` (`MaHopDong`, `MaDichVu`, `SoLuong`, `NgayBatDau`)
18. `ChiSoSuDung` (`MaChiSo`, `MaPhong`, `MaDichVu`, `KyChot`, `ChiSoDau`, `ChiSoCuoi`, `SanLuong`, `BatThuong`, `NgayGhi`)
19. `HoaDon` (`MaHoaDon`, `MaSoHoaDon`, `MaHopDong`, `MaPhong`, `KyHoaDon`, `NgayPhatHanh`, `HanThanhToan`, `TienPhong`, `TienDien`, `TienNuoc`, `TienDichVu`, `GiamTru`, `TongTien`, `SoTienDaTra`, `NoiDungQr`, `UrlVietQr`, `TrangThai`)
    - *Giá trị `TrangThai`:* `Nháp`, `Đã phát hành`, `Thanh toán một phần`, `Đã thanh toán`, `Quá hạn`, `Đã hủy`
20. `ChiTietHoaDon` (`MaChiTiet`, `MaHoaDon`, `LoaiKhoanThu`, `MoTa`, `SoLuong`, `DonGia`, `ThanhTien`)
21. `ThanhToan` (`MaThanhToan`, `MaHoaDon`, `SoTien`, `PhuongThuc`, `ThoiGianThanhToan`, `DuongDanBienLai`, `MaNguoiXacNhan`, `TrangThai`, `GhiChu`)
    - *Giá trị `TrangThai`:* `Chờ xác nhận`, `Đã xác nhận`, `Từ chối`

### Nhóm 5: Sự cố & Bảo trì Kỹ thuật (Kanban)
22. `DanhMucSuCo` (`MaDanhMuc`, `TenDanhMuc`, `MoTa`)
23. `PhieuSuCo` (`MaPhieuSuCo`, `MaSoPhieu`, `MaPhong`, `MaCuDan`, `MaDanhMuc`, `MaNhanVienKyThuat`, `TieuDe`, `MoTa`, `MucDoUuTien`, `TrangThai`, `HanXuLy`, `ChiPhiVatTu`, `MaHoaDonTinhPhi`, `SoSaoDanhGia`, `NhanXetDanhGia`, `NgayTao`, `NgayHoanThanh`)
    - *Giá trị `MucDoUuTien`:* `Thấp`, `Trung bình`, `Cao`, `Khẩn cấp`
    - *Giá trị `TrangThai`:* `Chờ xử lý`, `Đang sửa`, `Hoàn thành`, `Từ chối`, `Đã hủy`
24. `HinhAnhSuCo` (`MaHinhAnh`, `MaPhieuSuCo`, `DuongDanMedia`, `LoaiHinhAnh`)
    - *Giá trị `LoaiHinhAnh`:* `TruocSuaChua`, `NghiemThu`, `Video`
25. `TraoDoiSuCo` (`MaTraoDoi`, `MaPhieuSuCo`, `MaNguoiDung`, `NoiDung`, `LaNoiBo`, `ThoiGian`)
26. `LichSuSuCo` (`MaLichSu`, `MaPhieuSuCo`, `MaNguoiThayDoi`, `TrangThaiCu`, `TrangThaiMoi`, `GhiChu`, `ThoiGian`)

### Nhóm 6: Thông báo nội khu & Sự kiện cộng đồng
27. `ThongBao` (`MaThongBao`, `MaNguoiTao`, `TieuDe`, `NoiDung`, `PhamVi`, `MaToaNha`, `SoTang`, `ThoiGianHenGio`, `TrangThai`, `NgayTao`)
28. `ThongBaoHeThong` (`MaThongBaoHeThong`, `MaNguoiDung`, `TieuDe`, `NoiDung`, `LoaiThongBao`, `MaThamChieu`, `DaDoc`, `NgayTao`)
29. `ThietBiThongBao` (`MaThietBi`, `MaNguoiDung`, `TokenFcm`, `NenTang`, `CapNhatCuoi`)
30. `SuKien` (`MaSuKien`, `MaNguoiTao`, `TieuDe`, `MoTa`, `DiaDiem`, `ThoiGianBatDau`, `ThoiGianKetThuc`, `HanDangKy`, `SoLuongToiDa`, `DuongDanAnh`)
31. `DangKySuKien` (`MaDangKy`, `MaSuKien`, `MaCuDan`, `ThoiGianDangKy`, `TrangThai`, `DaDiemDanh`)

### Nhóm 7: Trợ lý ảo AI (Gemini)
32. `PhienTroChuyen` (`MaPhien`, `MaNguoiDung`, `TieuDe`, `NgayTao`) & `TinNhanTroChuyen` (`MaTinNhan`, `MaPhien`, `NguoiGui`, `NoiDung`, `ThoiGian`)

## 4. Nghiệp vụ cốt lõi
- **Tính hóa đơn bậc thang:** Tiền phòng + Điện/Nước tính theo bậc thang có hiệu lực tại kỳ hóa đơn (mỗi bậc tạo 1 dòng `ChiTietHoaDon` minh bạch số lượng × đơn giá) + Dịch vụ cố định theo hợp đồng - Giảm trừ.
- **Mã VietQR động:** Khi phát hành hóa đơn, tự động sinh URL chuẩn VietQR:
  `https://img.vietqr.io/image/{MaNganHangBin}-{SoTaiKhoan}-compact2.png?amount={SoTienConLai}&addInfo={NoiDungQr}&accountName={TenChuTaiKhoan}`
- **Đối soát biên lai:** Cư dân tải ảnh biên lai chuyển khoản -> tạo bản ghi `ThanhToan` trạng thái `Chờ xác nhận` -> Quản lý vận hành duyệt -> cập nhật `HoaDon` sang `Đã thanh toán` hoặc `Thanh toán một phần`.
- **Luồng sự cố Kanban:** `Chờ xử lý` -> `Đang sửa` -> `Hoàn thành`. Mỗi lần chuyển trạng thái tự động lưu `LichSuSuCo`, tạo `ThongBaoHeThong` và đẩy sự kiện qua SignalR Hub (`/hubs/smartstay`).
