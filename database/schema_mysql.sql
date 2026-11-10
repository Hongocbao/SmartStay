-- ============================================================
-- SMARTSTAY DATABASE SCHEMA (MYSQL 8.0 / MARIADB)
-- Hệ thống Quản trị Hệ sinh thái Lưu trú Thông minh Đa nền tảng
-- ============================================================

CREATE DATABASE IF NOT EXISTS `SmartStayDB` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `SmartStayDB`;

SET FOREIGN_KEY_CHECKS = 0;

-- 1. VaiTro
DROP TABLE IF EXISTS `VaiTro`;
CREATE TABLE `VaiTro` (
    `MaVaiTro` INT AUTO_INCREMENT PRIMARY KEY,
    `TenVaiTro` VARCHAR(50) NOT NULL UNIQUE,
    `MoTa` VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. NguoiDung
DROP TABLE IF EXISTS `NguoiDung`;
CREATE TABLE `NguoiDung` (
    `MaNguoiDung` INT AUTO_INCREMENT PRIMARY KEY,
    `TenDangNhap` VARCHAR(50) NOT NULL UNIQUE,
    `ThuDienTu` VARCHAR(100) NOT NULL UNIQUE,
    `SoDienThoai` VARCHAR(20) NOT NULL UNIQUE,
    `MaBamMatKhau` VARCHAR(255) NOT NULL,
    `HoTen` VARCHAR(100) NOT NULL,
    `MaVaiTro` INT NOT NULL,
    `DangHoatDong` BOOLEAN NOT NULL DEFAULT TRUE,
    `CanDoiMatKhau` BOOLEAN NOT NULL DEFAULT FALSE,
    `LanDangNhapCuoi` DATETIME NULL,
    `NgayTao` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `FK_NguoiDung_VaiTro` FOREIGN KEY (`MaVaiTro`) REFERENCES `VaiTro`(`MaVaiTro`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. MaDatLaiMatKhau
DROP TABLE IF EXISTS `MaDatLaiMatKhau`;
CREATE TABLE `MaDatLaiMatKhau` (
    `MaToken` INT AUTO_INCREMENT PRIMARY KEY,
    `MaNguoiDung` INT NOT NULL,
    `MaXacThuc` VARCHAR(100) NOT NULL,
    `HanSuDung` DATETIME NOT NULL,
    `DaSuDung` BOOLEAN NOT NULL DEFAULT FALSE,
    `NgayTao` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `FK_MaDatLai_NguoiDung` FOREIGN KEY (`MaNguoiDung`) REFERENCES `NguoiDung`(`MaNguoiDung`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. NhatKyKiemToan
DROP TABLE IF EXISTS `NhatKyKiemToan`;
CREATE TABLE `NhatKyKiemToan` (
    `MaNhatKy` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `MaNguoiDung` INT NULL,
    `HanhDong` VARCHAR(100) NOT NULL,
    `TenBang` VARCHAR(100) NOT NULL,
    `MaBanGhi` VARCHAR(50) NOT NULL,
    `GiaTriCu` TEXT NULL,
    `GiaTriMoi` TEXT NULL,
    `ThoiGian` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `FK_NhatKy_NguoiDung` FOREIGN KEY (`MaNguoiDung`) REFERENCES `NguoiDung`(`MaNguoiDung`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. CauHinhDonVi
DROP TABLE IF EXISTS `CauHinhDonVi`;
CREATE TABLE `CauHinhDonVi` (
    `MaCauHinh` INT AUTO_INCREMENT PRIMARY KEY,
    `TenDonVi` VARCHAR(150) NOT NULL,
    `DiaChi` VARCHAR(255) NOT NULL,
    `SoDienThoai` VARCHAR(20) NOT NULL,
    `ThuDienTu` VARCHAR(100) NOT NULL,
    `MaNganHangBin` VARCHAR(20) NOT NULL,
    `TenNganHang` VARCHAR(100) NOT NULL,
    `SoTaiKhoan` VARCHAR(50) NOT NULL,
    `TenChuTaiKhoan` VARCHAR(100) NOT NULL,
    `SoNgayHanThanhToan` INT NOT NULL DEFAULT 5,
    `NoiQuyToaNha` TEXT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. ToaNha
DROP TABLE IF EXISTS `ToaNha`;
CREATE TABLE `ToaNha` (
    `MaToaNha` INT AUTO_INCREMENT PRIMARY KEY,
    `TenToaNha` VARCHAR(100) NOT NULL,
    `DiaChi` VARCHAR(255) NOT NULL,
    `TongSoTang` INT NOT NULL DEFAULT 1,
    `MoTa` VARCHAR(255) NULL,
    `DangHoatDong` BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. LoaiPhong
DROP TABLE IF EXISTS `LoaiPhong`;
CREATE TABLE `LoaiPhong` (
    `MaLoaiPhong` INT AUTO_INCREMENT PRIMARY KEY,
    `TenLoaiPhong` VARCHAR(100) NOT NULL,
    `DonGiaCoBan` DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `SucChuaToiDa` INT NOT NULL DEFAULT 1,
    `DienTichMacDinh` DECIMAL(10,2) NOT NULL DEFAULT 20.00,
    `MoTa` VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8. Phong
DROP TABLE IF EXISTS `Phong`;
CREATE TABLE `Phong` (
    `MaPhong` INT AUTO_INCREMENT PRIMARY KEY,
    `MaToaNha` INT NOT NULL,
    `MaLoaiPhong` INT NOT NULL,
    `MaSoPhong` VARCHAR(20) NOT NULL,
    `SoTang` INT NOT NULL,
    `DienTich` DECIMAL(10,2) NOT NULL,
    `SucChua` INT NOT NULL,
    `GiaThue` DECIMAL(18,2) NOT NULL,
    `TrangThai` ENUM('Trống', 'Đang ở', 'Bảo trì', 'Đã đặt') NOT NULL DEFAULT 'Trống',
    `GhiChu` VARCHAR(255) NULL,
    CONSTRAINT `FK_Phong_ToaNha` FOREIGN KEY (`MaToaNha`) REFERENCES `ToaNha`(`MaToaNha`),
    CONSTRAINT `FK_Phong_LoaiPhong` FOREIGN KEY (`MaLoaiPhong`) REFERENCES `LoaiPhong`(`MaLoaiPhong`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 9. TaiSanPhong
DROP TABLE IF EXISTS `TaiSanPhong`;
CREATE TABLE `TaiSanPhong` (
    `MaTaiSan` INT AUTO_INCREMENT PRIMARY KEY,
    `MaPhong` INT NOT NULL,
    `TenTaiSan` VARCHAR(100) NOT NULL,
    `SoLuong` INT NOT NULL DEFAULT 1,
    `TinhTrang` VARCHAR(100) NOT NULL DEFAULT 'Mới',
    `GiaTriDenBu` DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `DuongDanAnh` VARCHAR(255) NULL,
    CONSTRAINT `FK_TaiSanPhong_Phong` FOREIGN KEY (`MaPhong`) REFERENCES `Phong`(`MaPhong`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 10. CuDan
DROP TABLE IF EXISTS `CuDan`;
CREATE TABLE `CuDan` (
    `MaCuDan` INT AUTO_INCREMENT PRIMARY KEY,
    `MaNguoiDung` INT NOT NULL UNIQUE,
    `NgaySinh` DATE NOT NULL,
    `GioiTinh` VARCHAR(10) NOT NULL DEFAULT 'Nam',
    `SoCanCuoc` VARCHAR(20) NOT NULL UNIQUE,
    `DiaChiThuongTru` VARCHAR(255) NOT NULL,
    `NguoiLienHeKhanCap` VARCHAR(100) NOT NULL,
    `SdtKhanCap` VARCHAR(20) NOT NULL,
    CONSTRAINT `FK_CuDan_NguoiDung` FOREIGN KEY (`MaNguoiDung`) REFERENCES `NguoiDung`(`MaNguoiDung`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 11. HopDong
DROP TABLE IF EXISTS `HopDong`;
CREATE TABLE `HopDong` (
    `MaHopDong` INT AUTO_INCREMENT PRIMARY KEY,
    `MaSoHopDong` VARCHAR(50) NOT NULL UNIQUE,
    `MaPhong` INT NOT NULL,
    `NgayBatDau` DATE NOT NULL,
    `NgayKetThuc` DATE NOT NULL,
    `TienThueHangThang` DECIMAL(18,2) NOT NULL,
    `TienDatCoc` DECIMAL(18,2) NOT NULL,
    `DieuKhoan` TEXT NULL,
    `TrangThai` ENUM('Nháp', 'Đang hiệu lực', 'Hết hạn', 'Đã thanh lý') NOT NULL DEFAULT 'Nháp',
    `NgayTao` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `FK_HopDong_Phong` FOREIGN KEY (`MaPhong`) REFERENCES `Phong`(`MaPhong`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 12. CuDanHopDong
DROP TABLE IF EXISTS `CuDanHopDong`;
CREATE TABLE `CuDanHopDong` (
    `MaHopDong` INT NOT NULL,
    `MaCuDan` INT NOT NULL,
    `LaDaiDien` BOOLEAN NOT NULL DEFAULT FALSE,
    `NgayVaoO` DATE NOT NULL,
    `NgayRoiDi` DATE NULL,
    PRIMARY KEY (`MaHopDong`, `MaCuDan`),
    CONSTRAINT `FK_CDHD_HopDong` FOREIGN KEY (`MaHopDong`) REFERENCES `HopDong`(`MaHopDong`) ON DELETE CASCADE,
    CONSTRAINT `FK_CDHD_CuDan` FOREIGN KEY (`MaCuDan`) REFERENCES `CuDan`(`MaCuDan`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 13. BienBanBanGiao
DROP TABLE IF EXISTS `BienBanBanGiao`;
CREATE TABLE `BienBanBanGiao` (
    `MaBienBan` INT AUTO_INCREMENT PRIMARY KEY,
    `MaHopDong` INT NOT NULL,
    `LoaiBienBan` ENUM('CheckIn', 'CheckOut') NOT NULL,
    `NgayBanGiao` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `ChiSoDien` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `ChiSoNuoc` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `KhauTruHuHong` DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `KhauTruCongNo` DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `SoTienHoanCoc` DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `GhiChu` TEXT NULL,
    CONSTRAINT `FK_BienBan_HopDong` FOREIGN KEY (`MaHopDong`) REFERENCES `HopDong`(`MaHopDong`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 14. TaiSanBanGiao
DROP TABLE IF EXISTS `TaiSanBanGiao`;
CREATE TABLE `TaiSanBanGiao` (
    `MaChiTietBanGiao` INT AUTO_INCREMENT PRIMARY KEY,
    `MaBienBan` INT NOT NULL,
    `MaTaiSan` INT NOT NULL,
    `TenTaiSan` VARCHAR(100) NOT NULL,
    `SoLuong` INT NOT NULL DEFAULT 1,
    `TinhTrang` VARCHAR(100) NOT NULL,
    `ChiPhiDenBu` DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `DuongDanAnh` VARCHAR(255) NULL,
    CONSTRAINT `FK_TSBG_BienBan` FOREIGN KEY (`MaBienBan`) REFERENCES `BienBanBanGiao`(`MaBienBan`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 15. DichVu
DROP TABLE IF EXISTS `DichVu`;
CREATE TABLE `DichVu` (
    `MaDichVu` INT AUTO_INCREMENT PRIMARY KEY,
    `TenDichVu` VARCHAR(100) NOT NULL,
    `DonViTinh` VARCHAR(20) NOT NULL,
    `LoaiDichVu` ENUM('BacThang', 'CoDinh') NOT NULL,
    `DonGiaCoDinh` DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `DangHoatDong` BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 16. BacGia
DROP TABLE IF EXISTS `BacGia`;
CREATE TABLE `BacGia` (
    `MaBacGia` INT AUTO_INCREMENT PRIMARY KEY,
    `MaDichVu` INT NOT NULL,
    `ThuTuBac` INT NOT NULL,
    `TuSo` DECIMAL(10,2) NOT NULL,
    `DenSo` DECIMAL(10,2) NULL,
    `DonGia` DECIMAL(18,2) NOT NULL,
    `NgayApDung` DATE NOT NULL,
    `NgayKetThuc` DATE NULL,
    CONSTRAINT `FK_BacGia_DichVu` FOREIGN KEY (`MaDichVu`) REFERENCES `DichVu`(`MaDichVu`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 17. DichVuHopDong
DROP TABLE IF EXISTS `DichVuHopDong`;
CREATE TABLE `DichVuHopDong` (
    `MaHopDong` INT NOT NULL,
    `MaDichVu` INT NOT NULL,
    `SoLuong` INT NOT NULL DEFAULT 1,
    `NgayBatDau` DATE NOT NULL,
    PRIMARY KEY (`MaHopDong`, `MaDichVu`),
    CONSTRAINT `FK_DVHD_HopDong` FOREIGN KEY (`MaHopDong`) REFERENCES `HopDong`(`MaHopDong`) ON DELETE CASCADE,
    CONSTRAINT `FK_DVHD_DichVu` FOREIGN KEY (`MaDichVu`) REFERENCES `DichVu`(`MaDichVu`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 18. ChiSoSuDung
DROP TABLE IF EXISTS `ChiSoSuDung`;
CREATE TABLE `ChiSoSuDung` (
    `MaChiSo` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `MaPhong` INT NOT NULL,
    `MaDichVu` INT NOT NULL,
    `KyChot` DATE NOT NULL,
    `ChiSoDau` DECIMAL(10,2) NOT NULL,
    `ChiSoCuoi` DECIMAL(10,2) NOT NULL,
    `SanLuong` DECIMAL(10,2) NOT NULL,
    `BatThuong` BOOLEAN NOT NULL DEFAULT FALSE,
    `NgayGhi` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `FK_ChiSo_Phong` FOREIGN KEY (`MaPhong`) REFERENCES `Phong`(`MaPhong`),
    CONSTRAINT `FK_ChiSo_DichVu` FOREIGN KEY (`MaDichVu`) REFERENCES `DichVu`(`MaDichVu`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 19. HoaDon
DROP TABLE IF EXISTS `HoaDon`;
CREATE TABLE `HoaDon` (
    `MaHoaDon` INT AUTO_INCREMENT PRIMARY KEY,
    `MaSoHoaDon` VARCHAR(50) NOT NULL UNIQUE,
    `MaHopDong` INT NOT NULL,
    `MaPhong` INT NOT NULL,
    `KyHoaDon` DATE NOT NULL,
    `NgayPhatHanh` DATE NOT NULL,
    `HanThanhToan` DATE NOT NULL,
    `TienPhong` DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `TienDien` DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `TienNuoc` DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `TienDichVu` DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `GiamTru` DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `TongTien` DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `SoTienDaTra` DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `NoiDungQr` VARCHAR(100) NOT NULL,
    `UrlVietQr` VARCHAR(500) NULL,
    `TrangThai` ENUM('Nháp', 'Đã phát hành', 'Thanh toán một phần', 'Đã thanh toán', 'Quá hạn', 'Đã hủy') NOT NULL DEFAULT 'Nháp',
    CONSTRAINT `FK_HoaDon_HopDong` FOREIGN KEY (`MaHopDong`) REFERENCES `HopDong`(`MaHopDong`),
    CONSTRAINT `FK_HoaDon_Phong` FOREIGN KEY (`MaPhong`) REFERENCES `Phong`(`MaPhong`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 20. ChiTietHoaDon
DROP TABLE IF EXISTS `ChiTietHoaDon`;
CREATE TABLE `ChiTietHoaDon` (
    `MaChiTiet` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `MaHoaDon` INT NOT NULL,
    `LoaiKhoanThu` VARCHAR(50) NOT NULL,
    `MoTa` VARCHAR(255) NOT NULL,
    `SoLuong` DECIMAL(10,2) NOT NULL DEFAULT 1.00,
    `DonGia` DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `ThanhTien` DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    CONSTRAINT `FK_CTHD_HoaDon` FOREIGN KEY (`MaHoaDon`) REFERENCES `HoaDon`(`MaHoaDon`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 21. ThanhToan
DROP TABLE IF EXISTS `ThanhToan`;
CREATE TABLE `ThanhToan` (
    `MaThanhToan` INT AUTO_INCREMENT PRIMARY KEY,
    `MaHoaDon` INT NOT NULL,
    `SoTien` DECIMAL(18,2) NOT NULL,
    `PhuongThuc` VARCHAR(50) NOT NULL DEFAULT 'VietQR',
    `ThoiGianThanhToan` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `DuongDanBienLai` VARCHAR(255) NULL,
    `MaNguoiXacNhan` INT NULL,
    `TrangThai` ENUM('Chờ xác nhận', 'Đã xác nhận', 'Từ chối') NOT NULL DEFAULT 'Chờ xác nhận',
    `GhiChu` VARCHAR(255) NULL,
    CONSTRAINT `FK_ThanhToan_HoaDon` FOREIGN KEY (`MaHoaDon`) REFERENCES `HoaDon`(`MaHoaDon`),
    CONSTRAINT `FK_ThanhToan_NguoiDung` FOREIGN KEY (`MaNguoiXacNhan`) REFERENCES `NguoiDung`(`MaNguoiDung`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 22. DanhMucSuCo
DROP TABLE IF EXISTS `DanhMucSuCo`;
CREATE TABLE `DanhMucSuCo` (
    `MaDanhMuc` INT AUTO_INCREMENT PRIMARY KEY,
    `TenDanhMuc` VARCHAR(100) NOT NULL UNIQUE,
    `MoTa` VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 23. PhieuSuCo
DROP TABLE IF EXISTS `PhieuSuCo`;
CREATE TABLE `PhieuSuCo` (
    `MaPhieuSuCo` INT AUTO_INCREMENT PRIMARY KEY,
    `MaSoPhieu` VARCHAR(50) NOT NULL UNIQUE,
    `MaPhong` INT NOT NULL,
    `MaCuDan` INT NOT NULL,
    `MaDanhMuc` INT NOT NULL,
    `MaNhanVienKyThuat` INT NULL,
    `TieuDe` VARCHAR(150) NOT NULL,
    `MoTa` TEXT NOT NULL,
    `MucDoUuTien` ENUM('Thấp', 'Trung bình', 'Cao', 'Khẩn cấp') NOT NULL DEFAULT 'Trung bình',
    `TrangThai` ENUM('Chờ xử lý', 'Đang sửa', 'Hoàn thành', 'Từ chối', 'Đã hủy') NOT NULL DEFAULT 'Chờ xử lý',
    `HanXuLy` DATETIME NULL,
    `ChiPhiVatTu` DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `MaHoaDonTinhPhi` INT NULL,
    `SoSaoDanhGia` INT NULL,
    `NhanXetDanhGia` TEXT NULL,
    `NgayTao` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `NgayHoanThanh` DATETIME NULL,
    CONSTRAINT `FK_PhieuSuCo_Phong` FOREIGN KEY (`MaPhong`) REFERENCES `Phong`(`MaPhong`),
    CONSTRAINT `FK_PhieuSuCo_CuDan` FOREIGN KEY (`MaCuDan`) REFERENCES `CuDan`(`MaCuDan`),
    CONSTRAINT `FK_PhieuSuCo_DanhMuc` FOREIGN KEY (`MaDanhMuc`) REFERENCES `DanhMucSuCo`(`MaDanhMuc`),
    CONSTRAINT `FK_PhieuSuCo_KyThuat` FOREIGN KEY (`MaNhanVienKyThuat`) REFERENCES `NguoiDung`(`MaNguoiDung`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 24. HinhAnhSuCo
DROP TABLE IF EXISTS `HinhAnhSuCo`;
CREATE TABLE `HinhAnhSuCo` (
    `MaHinhAnh` INT AUTO_INCREMENT PRIMARY KEY,
    `MaPhieuSuCo` INT NOT NULL,
    `DuongDanMedia` VARCHAR(255) NOT NULL,
    `LoaiHinhAnh` ENUM('TruocSuaChua', 'NghiemThu', 'Video') NOT NULL DEFAULT 'TruocSuaChua',
    CONSTRAINT `FK_HASC_PhieuSuCo` FOREIGN KEY (`MaPhieuSuCo`) REFERENCES `PhieuSuCo`(`MaPhieuSuCo`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 25. TraoDoiSuCo
DROP TABLE IF EXISTS `TraoDoiSuCo`;
CREATE TABLE `TraoDoiSuCo` (
    `MaTraoDoi` INT AUTO_INCREMENT PRIMARY KEY,
    `MaPhieuSuCo` INT NOT NULL,
    `MaNguoiDung` INT NOT NULL,
    `NoiDung` TEXT NOT NULL,
    `LaNoiBo` BOOLEAN NOT NULL DEFAULT FALSE,
    `ThoiGian` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `FK_TraoDoi_PhieuSuCo` FOREIGN KEY (`MaPhieuSuCo`) REFERENCES `PhieuSuCo`(`MaPhieuSuCo`) ON DELETE CASCADE,
    CONSTRAINT `FK_TraoDoi_NguoiDung` FOREIGN KEY (`MaNguoiDung`) REFERENCES `NguoiDung`(`MaNguoiDung`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 26. LichSuSuCo
DROP TABLE IF EXISTS `LichSuSuCo`;
CREATE TABLE `LichSuSuCo` (
    `MaLichSu` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `MaPhieuSuCo` INT NOT NULL,
    `MaNguoiThayDoi` INT NOT NULL,
    `TrangThaiCu` VARCHAR(50) NOT NULL,
    `TrangThaiMoi` VARCHAR(50) NOT NULL,
    `GhiChu` VARCHAR(255) NULL,
    `ThoiGian` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `FK_LSSC_PhieuSuCo` FOREIGN KEY (`MaPhieuSuCo`) REFERENCES `PhieuSuCo`(`MaPhieuSuCo`) ON DELETE CASCADE,
    CONSTRAINT `FK_LSSC_NguoiDung` FOREIGN KEY (`MaNguoiThayDoi`) REFERENCES `NguoiDung`(`MaNguoiDung`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 27. ThongBao
DROP TABLE IF EXISTS `ThongBao`;
CREATE TABLE `ThongBao` (
    `MaThongBao` INT AUTO_INCREMENT PRIMARY KEY,
    `MaNguoiTao` INT NOT NULL,
    `TieuDe` VARCHAR(150) NOT NULL,
    `NoiDung` TEXT NOT NULL,
    `PhamVi` VARCHAR(50) NOT NULL DEFAULT 'Toàn bộ',
    `MaToaNha` INT NULL,
    `SoTang` INT NULL,
    `ThoiGianHenGio` DATETIME NULL,
    `TrangThai` VARCHAR(50) NOT NULL DEFAULT 'Đã gửi',
    `NgayTao` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `FK_ThongBao_NguoiDung` FOREIGN KEY (`MaNguoiTao`) REFERENCES `NguoiDung`(`MaNguoiDung`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 28. ThongBaoHeThong
DROP TABLE IF EXISTS `ThongBaoHeThong`;
CREATE TABLE `ThongBaoHeThong` (
    `MaThongBaoHeThong` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `MaNguoiDung` INT NOT NULL,
    `TieuDe` VARCHAR(150) NOT NULL,
    `NoiDung` TEXT NOT NULL,
    `LoaiThongBao` VARCHAR(50) NOT NULL,
    `MaThamChieu` INT NULL,
    `DaDoc` BOOLEAN NOT NULL DEFAULT FALSE,
    `NgayTao` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `FK_TBHT_NguoiDung` FOREIGN KEY (`MaNguoiDung`) REFERENCES `NguoiDung`(`MaNguoiDung`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 29. ThietBiThongBao
DROP TABLE IF EXISTS `ThietBiThongBao`;
CREATE TABLE `ThietBiThongBao` (
    `MaThietBi` INT AUTO_INCREMENT PRIMARY KEY,
    `MaNguoiDung` INT NOT NULL,
    `TokenFcm` VARCHAR(255) NOT NULL,
    `NenTang` VARCHAR(50) NOT NULL DEFAULT 'Android',
    `CapNhatCuoi` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `FK_TBTB_NguoiDung` FOREIGN KEY (`MaNguoiDung`) REFERENCES `NguoiDung`(`MaNguoiDung`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 30. SuKien
DROP TABLE IF EXISTS `SuKien`;
CREATE TABLE `SuKien` (
    `MaSuKien` INT AUTO_INCREMENT PRIMARY KEY,
    `MaNguoiTao` INT NOT NULL,
    `TieuDe` VARCHAR(150) NOT NULL,
    `MoTa` TEXT NOT NULL,
    `DiaDiem` VARCHAR(255) NOT NULL,
    `ThoiGianBatDau` DATETIME NOT NULL,
    `ThoiGianKetThuc` DATETIME NOT NULL,
    `HanDangKy` DATETIME NOT NULL,
    `SoLuongToiDa` INT NOT NULL DEFAULT 50,
    `DuongDanAnh` VARCHAR(255) NULL,
    CONSTRAINT `FK_SuKien_NguoiDung` FOREIGN KEY (`MaNguoiTao`) REFERENCES `NguoiDung`(`MaNguoiDung`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 31. DangKySuKien
DROP TABLE IF EXISTS `DangKySuKien`;
CREATE TABLE `DangKySuKien` (
    `MaDangKy` INT AUTO_INCREMENT PRIMARY KEY,
    `MaSuKien` INT NOT NULL,
    `MaCuDan` INT NOT NULL,
    `ThoiGianDangKy` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `TrangThai` VARCHAR(50) NOT NULL DEFAULT 'Đã đăng ký',
    `DaDiemDanh` BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT `FK_DKSK_SuKien` FOREIGN KEY (`MaSuKien`) REFERENCES `SuKien`(`MaSuKien`) ON DELETE CASCADE,
    CONSTRAINT `FK_DKSK_CuDan` FOREIGN KEY (`MaCuDan`) REFERENCES `CuDan`(`MaCuDan`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 32. PhienTroChuyen & TinNhanTroChuyen (AI Gemini)
DROP TABLE IF EXISTS `TinNhanTroChuyen`;
DROP TABLE IF EXISTS `PhienTroChuyen`;

CREATE TABLE `PhienTroChuyen` (
    `MaPhien` INT AUTO_INCREMENT PRIMARY KEY,
    `MaNguoiDung` INT NOT NULL,
    `TieuDe` VARCHAR(150) NOT NULL DEFAULT 'Cuộc trò chuyện mới',
    `NgayTao` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `FK_PTC_NguoiDung` FOREIGN KEY (`MaNguoiDung`) REFERENCES `NguoiDung`(`MaNguoiDung`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `TinNhanTroChuyen` (
    `MaTinNhan` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `MaPhien` INT NOT NULL,
    `NguoiGui` VARCHAR(20) NOT NULL, -- 'User' hoặc 'AI'
    `NoiDung` TEXT NOT NULL,
    `ThoiGian` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `FK_TNTC_PhienTroChuyen` FOREIGN KEY (`MaPhien`) REFERENCES `PhienTroChuyen`(`MaPhien`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- DỮ LIỆU KHỞI TẠO BAN ĐẦU (SEED DATA)
-- ============================================================

-- Vai trò
INSERT INTO `VaiTro` (`MaVaiTro`, `TenVaiTro`, `MoTa`) VALUES
(1, 'Admin', 'Quản trị viên toàn quyền hệ thống'),
(2, 'QuanLy', 'Quản lý vận hành cơ sở lưu trú'),
(3, 'KyThuat', 'Nhân viên kỹ thuật bảo trì'),
(4, 'CuDan', 'Cư dân lưu trú tại phòng');

-- Người dùng mặc định
-- Mật khẩu mặc định: 123456 (BCrypt)
INSERT INTO `NguoiDung` (`MaNguoiDung`, `TenDangNhap`, `ThuDienTu`, `SoDienThoai`, `MaBamMatKhau`, `HoTen`, `MaVaiTro`, `DangHoatDong`) VALUES
(1, 'admin', 'admin@smartstay.vn', '0900000001', '$2a$11$FoiXjrhx5r4JkHQe4.49te0RHlFTtzy/HFRTnouZz/G3KanTYJHXW', 'Quản Trị Viên', 1, 1),
(2, 'quanly', 'quanly@smartstay.vn', '0900000002', '$2a$11$FoiXjrhx5r4JkHQe4.49te0RHlFTtzy/HFRTnouZz/G3KanTYJHXW', 'Nguyễn Dương Bảo', 2, 1),
(3, 'kythuat', 'kythuat@smartstay.vn', '0900000003', '$2a$11$FoiXjrhx5r4JkHQe4.49te0RHlFTtzy/HFRTnouZz/G3KanTYJHXW', 'Nguyễn Văn Bình', 3, 1),
(4, '2380600133', 'hongocbao@smartstay.vn', '0901234567', '$2a$11$FoiXjrhx5r4JkHQe4.49te0RHlFTtzy/HFRTnouZz/G3KanTYJHXW', 'Hồ Ngọc Bảo', 4, 1);

-- Cấu hình đơn vị
INSERT INTO `CauHinhDonVi` (`MaCauHinh`, `TenDonVi`, `DiaChi`, `SoDienThoai`, `ThuDienTu`, `MaNganHangBin`, `TenNganHang`, `SoTaiKhoan`, `TenChuTaiKhoan`, `SoNgayHanThanhToan`) VALUES
(1, 'Ban Quản Lý SmartStay Co-Living', '123 Điện Biên Phủ, P.25, Bình Thạnh, TP.HCM', '19008899', 'support@smartstay.vn', '970422', 'MBBank (Quân Đội)', '0987654321', 'SMARTSTAY MANAGEMENT', 5);

-- Tòa nhà
INSERT INTO `ToaNha` (`MaToaNha`, `TenToaNha`, `DiaChi`, `TongSoTang`, `MoTa`) VALUES
(1, 'Tòa nhà A - Co-Living SmartStay', '123 Điện Biên Phủ, Bình Thạnh, TP.HCM', 5, 'Khu ký túc xá Co-Living cao cấp');

-- Loại phòng
INSERT INTO `LoaiPhong` (`MaLoaiPhong`, `TenLoaiPhong`, `DonGiaCoBan`, `SucChuaToiDa`, `DienTichMacDinh`) VALUES
(1, 'Studio Co-Living 1 Giường', 3500000.00, 1, 22.50),
(2, 'Deluxe 2 Giường Tầng', 5000000.00, 2, 30.00);

-- Phòng
INSERT INTO `Phong` (`MaPhong`, `MaToaNha`, `MaLoaiPhong`, `MaSoPhong`, `SoTang`, `DienTich`, `SucChua`, `GiaThue`, `TrangThai`) VALUES
(1, 1, 1, 'P.305', 3, 22.50, 1, 3500000.00, 'Đang ở'),
(2, 1, 1, 'P.306', 3, 22.50, 1, 3500000.00, 'Trống'),
(3, 1, 2, 'P.401', 4, 30.00, 2, 5000000.00, 'Đang ở');

-- Cư dân Hồ Ngọc Bảo
INSERT INTO `CuDan` (`MaCuDan`, `MaNguoiDung`, `NgaySinh`, `GioiTinh`, `SoCanCuoc`, `DiaChiThuongTru`, `NguoiLienHeKhanCap`, `SdtKhanCap`) VALUES
(1, 4, '2003-05-15', 'Nam', '079203001234', '123 Điện Biên Phủ, P.25, Bình Thạnh, TP.HCM', 'Hồ Văn Minh (Phụ huynh)', '0988776655');

-- Dịch vụ
INSERT INTO `DichVu` (`MaDichVu`, `TenDichVu`, `DonViTinh`, `LoaiDichVu`, `DonGiaCoDinh`) VALUES
(1, 'Điện sinh hoạt', 'kWh', 'BacThang', 0.00),
(2, 'Nước sinh hoạt', 'm³', 'BacThang', 0.00),
(3, 'Internet Wifi tốc độ cao', 'Phòng', 'CoDinh', 100000.00),
(4, 'Vệ sinh & Thu gom rác', 'Phòng', 'CoDinh', 50000.00),
(5, 'Phí quản lý & Bảo trì', 'Phòng', 'CoDinh', 150000.00);

-- Biểu giá bậc thang Điện
INSERT INTO `BacGia` (`MaDichVu`, `ThuTuBac`, `TuSo`, `DenSo`, `DonGia`, `NgayApDung`) VALUES
(1, 1, 0, 50, 1800.00, '2026-01-01'),
(1, 2, 51, 100, 2200.00, '2026-01-01'),
(1, 3, 101, 200, 2700.00, '2026-01-01'),
(1, 4, 201, NULL, 3200.00, '2026-01-01');

-- Biểu giá bậc thang Nước
INSERT INTO `BacGia` (`MaDichVu`, `ThuTuBac`, `TuSo`, `DenSo`, `DonGia`, `NgayApDung`) VALUES
(2, 1, 0, 5, 12000.00, '2026-01-01'),
(2, 2, 6, 10, 15000.00, '2026-01-01'),
(2, 3, 11, NULL, 18000.00, '2026-01-01');

-- Danh mục sự cố
INSERT INTO `DanhMucSuCo` (`MaDanhMuc`, `TenDanhMuc`) VALUES
(1, 'Máy lạnh'),
(2, 'Điện'),
(3, 'Nước'),
(4, 'Nội thất'),
(5, 'Khóa từ / Cửa'),
(6, 'Khác');
