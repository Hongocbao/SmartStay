-- =========================================================================================
-- SMARTSTAY ENTERPRISE EXTENSION - NÂNG CẤP HỆ SINH THÁI CƠ SỞ DỮ LIỆU THÔNG MINH
-- Cơ sở dữ liệu: SmartStayDB (Microsoft SQL Server 2022)
-- Máy chủ: MSI-Bao\SQLEXPRESS
-- =========================================================================================

USE [SmartStayDB];
GO

-- 1. Phân hệ Quản lý Giường / Sleepbox cho mô hình Ký túc xá thông minh & Co-Living
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Giuong')
BEGIN
    CREATE TABLE [dbo].[Giuong] (
        [MaGiuong] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [MaPhong] INT NOT NULL,
        [KyHieuGiuong] NVARCHAR(50) NOT NULL, -- G.01, G.02, Tầng 1, Tầng 2
        [GiaThueThang] DECIMAL(18,2) NOT NULL DEFAULT 1500000.00,
        [TrangThai] NVARCHAR(40) NOT NULL DEFAULT N'Trống', -- Trống, Đang ở, Đã đặt, Bảo trì
        [GhiChu] NVARCHAR(500) NULL,
        CONSTRAINT [FK_Giuong_Phong] FOREIGN KEY ([MaPhong]) REFERENCES [dbo].[Phong]([MaPhong]) ON DELETE CASCADE
    );
END
GO

-- 2. Phân hệ Thiết bị IoT & Khóa cửa thông minh (Smart Lock, IoT Energy Meter)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ThietBiIoT')
BEGIN
    CREATE TABLE [dbo].[ThietBiIoT] (
        [MaThietBiIoT] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [MaPhong] INT NULL,
        [MaToaNha] INT NOT NULL,
        [TenThietBi] NVARCHAR(150) NOT NULL,
        [LoaiThietBi] NVARCHAR(50) NOT NULL, -- KhoaCuaThongMinh, CongToDienTu, CamBienKhoi, MayLanhIoT
        [MaSeri] NVARCHAR(100) NOT NULL UNIQUE,
        [DiaChiMac] NVARCHAR(50) NULL,
        [MatKhauTruyCap] NVARCHAR(255) NULL,
        [TrangThaiHoatDong] NVARCHAR(30) NOT NULL DEFAULT N'Online', -- Online, Offline, CanhBaoPin
        [MucPin] INT NULL, -- % pin của khóa cửa
        [LanDongBoCuoi] DATETIME2 NULL,
        CONSTRAINT [FK_IoT_Phong] FOREIGN KEY ([MaPhong]) REFERENCES [dbo].[Phong]([MaPhong]) ON DELETE SET NULL,
        CONSTRAINT [FK_IoT_ToaNha] FOREIGN KEY ([MaToaNha]) REFERENCES [dbo].[ToaNha]([MaToaNha])
    );
END
GO

-- 3. Nhật ký mở cửa & Truy cập an ninh (Access Log)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'LichSuTruyCapCua')
BEGIN
    CREATE TABLE [dbo].[LichSuTruyCapCua] (
        [MaLichSuTruyCap] BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [MaThietBiIoT] INT NOT NULL,
        [MaNguoiDung] INT NULL,
        [PhuongThucMo] NVARCHAR(50) NOT NULL, -- VanTay, TheTu, MatMaTamThoi, MoTuXaQuaApp, NhanDienKhuonMat
        [ThoiDiemMo] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        [ThanhCong] BIT NOT NULL DEFAULT 1,
        [GhiChu] NVARCHAR(255) NULL,
        CONSTRAINT [FK_LSTC_IoT] FOREIGN KEY ([MaThietBiIoT]) REFERENCES [dbo].[ThietBiIoT]([MaThietBiIoT]) ON DELETE CASCADE,
        CONSTRAINT [FK_LSTC_NguoiDung] FOREIGN KEY ([MaNguoiDung]) REFERENCES [dbo].[NguoiDung]([MaNguoiDung]) ON DELETE SET NULL
    );
END
GO

-- 4. Phân hệ Phương tiện & Thẻ gửi xe cư dân
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PhuongTienCuDan')
BEGIN
    CREATE TABLE [dbo].[PhuongTienCuDan] (
        [MaPhuongTien] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [MaCuDan] INT NOT NULL,
        [LoaiXe] NVARCHAR(50) NOT NULL DEFAULT N'Xe máy', -- Xe máy, Xe đạp điện, Ô tô
        [BienSoXe] NVARCHAR(30) NOT NULL,
        [NhanHieu] NVARCHAR(100) NULL, -- Honda Vision, Yamaha Grande...
        [MauXe] NVARCHAR(50) NULL,
        [MaTheXeRFID] NVARCHAR(50) NULL,
        [PhiGuiXeHangThang] DECIMAL(18,2) NOT NULL DEFAULT 120000.00,
        [DuongDanAnhDangKyXe] NVARCHAR(600) NULL,
        [DangHoatDong] BIT NOT NULL DEFAULT 1,
        [NgayDangKy] DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
        CONSTRAINT [FK_PT_CuDan] FOREIGN KEY ([MaCuDan]) REFERENCES [dbo].[CuDan]([MaCuDan]) ON DELETE CASCADE
    );
END
GO

-- 5. Phân hệ Đặt giữ chỗ phòng trực tuyến (Booking / Reservation)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PhieuDatGiuCho')
BEGIN
    CREATE TABLE [dbo].[PhieuDatGiuCho] (
        [MaPhieuDat] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [SoPhieuDat] NVARCHAR(50) NOT NULL UNIQUE,
        [MaPhong] INT NOT NULL,
        [MaGiuong] INT NULL,
        [HoTenKhach] NVARCHAR(150) NOT NULL,
        [SoDienThoai] NVARCHAR(30) NOT NULL,
        [Email] NVARCHAR(150) NULL,
        [SoCCCD] NVARCHAR(40) NULL,
        [TienCocGiuCho] DECIMAL(18,2) NOT NULL,
        [NgayDat] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        [HanGiuCho] DATETIME2 NOT NULL,
        [NgayDuKienNhanPhong] DATE NOT NULL,
        [TrangThai] NVARCHAR(40) NOT NULL DEFAULT N'Chờ nhận phòng', -- Chờ nhận phòng, Đã nhận phòng, Đã hủy cọc, Hết hạn
        [GhiChu] NVARCHAR(500) NULL,
        CONSTRAINT [FK_DatCho_Phong] FOREIGN KEY ([MaPhong]) REFERENCES [dbo].[Phong]([MaPhong]),
        CONSTRAINT [FK_DatCho_Giuong] FOREIGN KEY ([MaGiuong]) REFERENCES [dbo].[Giuong]([MaGiuong])
    );
END
GO

-- 6. Phân hệ Webhook Ngân hàng Tự động Gạch nợ (SePAY / Casso / Bank Auto-Reconciliation)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'WebhookGiaoDichNganHang')
BEGIN
    CREATE TABLE [dbo].[WebhookGiaoDichNganHang] (
        [MaGiaoDichNganHang] BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [MaThamChieuNganHang] NVARCHAR(150) NOT NULL UNIQUE, -- Mã FT giao dịch
        [SoTien] DECIMAL(18,2) NOT NULL,
        [NoiDungChuyenKhoan] NVARCHAR(500) NOT NULL,
        [ThoiGianGiaoDich] DATETIME2 NOT NULL,
        [SoTaiKhoanNhan] NVARCHAR(50) NOT NULL,
        [MaHoaDonKhop] INT NULL,
        [TrangThaiKhop] NVARCHAR(40) NOT NULL DEFAULT N'Chưa khớp', -- Đã khớp tự động, Đã khớp thủ công, Không tìm thấy hóa đơn
        [ThoiDiemNhanWebhook] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT [FK_Webhook_HoaDon] FOREIGN KEY ([MaHoaDonKhop]) REFERENCES [dbo].[HoaDon]([MaHoaDon]) ON DELETE SET NULL
    );
END
GO

-- 7. Phân hệ Ví Cư Dân & Thanh Toán Nội Khu (Resident Wallet)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ViCuDan')
BEGIN
    CREATE TABLE [dbo].[ViCuDan] (
        [MaVi] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [MaCuDan] INT NOT NULL UNIQUE,
        [SoDuKhaDung] DECIMAL(18,2) NOT NULL DEFAULT 0.00,
        [TrangThaiKhoa] BIT NOT NULL DEFAULT 0,
        [CapNhatCuoi] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT [FK_Vi_CuDan] FOREIGN KEY ([MaCuDan]) REFERENCES [dbo].[CuDan]([MaCuDan]) ON DELETE CASCADE
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'LichSuGiaoDichVi')
BEGIN
    CREATE TABLE [dbo].[LichSuGiaoDichVi] (
        [MaGiaoDichVi] BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [MaVi] INT NOT NULL,
        [LoaiGiaoDich] NVARCHAR(50) NOT NULL, -- NapTienVietQR, TruTienDienNuoc, TruTienDichVu, HoanTienCoc
        [SoTien] DECIMAL(18,2) NOT NULL,
        [SoDuTruoc] DECIMAL(18,2) NOT NULL,
        [SoDuSau] DECIMAL(18,2) NOT NULL,
        [MaHoaDonLienQuan] INT NULL,
        [NoiDung] NVARCHAR(300) NOT NULL,
        [ThoiGian] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT [FK_LSVi_Vi] FOREIGN KEY ([MaVi]) REFERENCES [dbo].[ViCuDan]([MaVi]) ON DELETE CASCADE
    );
END
GO

-- 8. Phân hệ Quản lý Sổ Quỹ Thu Chi Tòa Nhà (Cash Flow Management)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SoQuyThuChi')
BEGIN
    CREATE TABLE [dbo].[SoQuyThuChi] (
        [MaPhieuThuChi] BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [SoChungTu] NVARCHAR(50) NOT NULL UNIQUE,
        [MaToaNha] INT NOT NULL,
        [LoaiPhieu] NVARCHAR(20) NOT NULL, -- PhieuThu, PhieuChi
        [HangMuc] NVARCHAR(100) NOT NULL, -- ThuTienPhong, ThuDienNuoc, ChiTienDienEVN, ChiTienNuoc, ChiLuongTapVu, ChiSuaChua
        [SoTien] DECIMAL(18,2) NOT NULL,
        [HinhThuc] NVARCHAR(50) NOT NULL DEFAULT N'Chuyển khoản', -- Tiền mặt, Chuyển khoản, VietQR
        [NguoiNopNhan] NVARCHAR(150) NOT NULL,
        [NoiDung] NVARCHAR(500) NOT NULL,
        [NgayChungTu] DATE NOT NULL,
        [NguoiLapPhieu] INT NOT NULL,
        [ThoiDiemTao] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT [FK_SQ_ToaNha] FOREIGN KEY ([MaToaNha]) REFERENCES [dbo].[ToaNha]([MaToaNha]),
        CONSTRAINT [FK_SQ_NguoiDung] FOREIGN KEY ([NguoiLapPhieu]) REFERENCES [dbo].[NguoiDung]([MaNguoiDung])
    );
END
GO

-- 9. Phân hệ Kho Vật tư & Linh kiện Bảo trì kỹ thuật
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'VatTuLinhKien')
BEGIN
    CREATE TABLE [dbo].[VatTuLinhKien] (
        [MaVatTu] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [MaToaNha] INT NOT NULL,
        [TenVatTu] NVARCHAR(150) NOT NULL,
        [DonViTinh] NVARCHAR(30) NOT NULL, -- Cái, Bộ, Mét, Cuộn, Bình
        [SoLuongTon] INT NOT NULL DEFAULT 0,
        [DonGiaNhap] DECIMAL(18,2) NOT NULL DEFAULT 0.00,
        [GiaXuatSuaChua] DECIMAL(18,2) NOT NULL DEFAULT 0.00,
        [DinhMucToiThieu] INT NOT NULL DEFAULT 5, -- Cảnh báo sắp hết hàng
        CONSTRAINT [FK_VT_ToaNha] FOREIGN KEY ([MaToaNha]) REFERENCES [dbo].[ToaNha]([MaToaNha])
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PhieuXuatVatTuSuCo')
BEGIN
    CREATE TABLE [dbo].[PhieuXuatVatTuSuCo] (
        [MaXuatVatTu] BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [MaPhieuSuCo] INT NOT NULL,
        [MaVatTu] INT NOT NULL,
        [SoLuongXuat] INT NOT NULL DEFAULT 1,
        [DonGia] DECIMAL(18,2) NOT NULL,
        [ThanhTien] AS ([SoLuongXuat] * [DonGia]),
        [ThoiDiemXuat] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT [FK_XVTSC_PhieuSuCo] FOREIGN KEY ([MaPhieuSuCo]) REFERENCES [dbo].[PhieuSuCo]([MaPhieuSuCo]) ON DELETE CASCADE,
        CONSTRAINT [FK_XVTSC_VatTu] FOREIGN KEY ([MaVatTu]) REFERENCES [dbo].[VatTuLinhKien]([MaVatTu])
    );
END
GO

-- 10. Phân hệ Cơ sở Tri thức Trợ lý AI (Gemini RAG Knowledge Base)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TriThucAiRAG')
BEGIN
    CREATE TABLE [dbo].[TriThucAiRAG] (
        [MaTriThuc] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [ChuDe] NVARCHAR(100) NOT NULL, -- NoiQuyToaNha, CachTinhDienNuoc, HuongDanSuDungThietBi, ThuTucTamTru
        [CauHoiPhoBien] NVARCHAR(500) NOT NULL,
        [NoiDungGiaiDap] NVARCHAR(MAX) NOT NULL,
        [DoUuTien] INT NOT NULL DEFAULT 1,
        [DangHoatDong] BIT NOT NULL DEFAULT 1,
        [NgayCapNhat] DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END
GO

-- =========================================================================================
-- INDEXES TỐI ƯU HIỆU NĂNG CHO CÁC BẢNG TRỌNG TÂM
-- =========================================================================================
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Phong_TrangThai')
    CREATE NONCLUSTERED INDEX [IX_Phong_TrangThai] ON [dbo].[Phong]([TrangThai], [SoTang]);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_HoaDon_TrangThai_KyTinhTien')
    CREATE NONCLUSTERED INDEX [IX_HoaDon_TrangThai_KyTinhTien] ON [dbo].[HoaDon]([TrangThai], [KyTinhTien]);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_PhieuSuCo_TrangThai_UuTien')
    CREATE NONCLUSTERED INDEX [IX_PhieuSuCo_TrangThai_UuTien] ON [dbo].[PhieuSuCo]([TrangThai], [UuTien]);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ThanhToan_TrangThai')
    CREATE NONCLUSTERED INDEX [IX_ThanhToan_TrangThai] ON [dbo].[ThanhToan]([TrangThai]);
GO

-- =========================================================================================
-- VIEWS BÁO CÁO TỔNG HỢP & THỜI GIAN THỰC
-- =========================================================================================

-- View 1: Báo cáo Doanh thu & Công nợ tổng hợp theo Tòa nhà
CREATE OR ALTER VIEW [dbo].[v_BaoCaoDoanhThuTheoToaNha]
AS
SELECT 
    t.[MaToaNha],
    t.[TenToaNha],
    h.[KyTinhTien],
    COUNT(h.[MaHoaDon]) AS [TongSoHoaDon],
    SUM(h.[TongTien]) AS [TongTienPhatHanh],
    SUM(CASE WHEN h.[TrangThai] = N'Đã thanh toán' THEN h.[TongTien] ELSE 0 END) AS [DoanhThuDaThu],
    SUM(CASE WHEN h.[TrangThai] != N'Đã thanh toán' THEN h.[TongTien] ELSE 0 END) AS [CongNoConLai],
    CAST(ROUND((SUM(CASE WHEN h.[TrangThai] = N'Đã thanh toán' THEN h.[TongTien] ELSE 0 END) * 100.0) / NULLIF(SUM(h.[TongTien]), 0), 1) AS DECIMAL(5,1)) AS [TyLeThuHoi]
FROM [dbo].[HoaDon] h
INNER JOIN [dbo].[HopDong] hd ON h.[MaHopDong] = hd.[MaHopDong]
INNER JOIN [dbo].[Phong] p ON hd.[MaPhong] = p.[MaPhong]
INNER JOIN [dbo].[ToaNha] t ON p.[MaToaNha] = t.[MaToaNha]
GROUP BY t.[MaToaNha], t.[TenToaNha], h.[KyTinhTien];
GO

-- View 2: Sơ đồ phòng tổng hợp thời gian thực kèm công nợ và thông tin cư dân
CREATE OR ALTER VIEW [dbo].[v_SoDoPhongRealTime]
AS
SELECT 
    p.[MaPhong],
    p.[KyHieuPhong],
    p.[SoTang],
    p.[DienTich],
    p.[SucChua],
    p.[GiaThue],
    p.[TrangThai] AS [TrangThaiPhong],
    t.[MaToaNha],
    t.[TenToaNha],
    lp.[TenLoaiPhong],
    hd.[MaHopDong],
    hd.[SoHopDong],
    u.[HoTen] AS [TenCuDanDaiDien],
    u.[SoDienThoai] AS [SdtCuDan],
    ISNULL(debt.[CongNoChuaThu], 0) AS [CongNoChuaThu],
    ISNULL(ticket.[SoSuCoChuaXong], 0) AS [SoSuCoChuaXong]
FROM [dbo].[Phong] p
INNER JOIN [dbo].[ToaNha] t ON p.[MaToaNha] = t.[MaToaNha]
INNER JOIN [dbo].[LoaiPhong] lp ON p.[MaLoaiPhong] = lp.[MaLoaiPhong]
LEFT JOIN [dbo].[HopDong] hd ON p.[MaPhong] = hd.[MaPhong] AND hd.[TrangThai] = N'Đang hiệu lực'
LEFT JOIN [dbo].[CuDanHopDong] cdhd ON hd.[MaHopDong] = cdhd.[MaHopDong] AND cdhd.[LaDaiDien] = 1
LEFT JOIN [dbo].[CuDan] c ON cdhd.[MaCuDan] = c.[MaCuDan]
LEFT JOIN [dbo].[NguoiDung] u ON c.[MaNguoiDung] = u.[MaNguoiDung]
LEFT JOIN (
    SELECT hd_sub.[MaPhong], SUM(h_sub.[TongTien]) AS [CongNoChuaThu]
    FROM [dbo].[HoaDon] h_sub
    INNER JOIN [dbo].[HopDong] hd_sub ON h_sub.[MaHopDong] = hd_sub.[MaHopDong]
    WHERE h_sub.[TrangThai] != N'Đã thanh toán'
    GROUP BY hd_sub.[MaPhong]
) debt ON p.[MaPhong] = debt.[MaPhong]
LEFT JOIN (
    SELECT [MaPhong], COUNT([MaPhieuSuCo]) AS [SoSuCoChuaXong]
    FROM [dbo].[PhieuSuCo]
    WHERE [TrangThai] IN (N'Chờ xử lý', N'Đang sửa')
    GROUP BY [MaPhong]
) ticket ON p.[MaPhong] = ticket.[MaPhong];
GO

-- =========================================================================================
-- TRIGGER TỰ ĐỘNG GHI NHẬT KÝ KHI THAY ĐỔI TRẠNG THÁI SỰ CỐ KANBAN
-- =========================================================================================
CREATE OR ALTER TRIGGER [dbo].[trg_PhieuSuCo_GhiNhatKyKanban]
ON [dbo].[PhieuSuCo]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF UPDATE([TrangThai])
    BEGIN
        INSERT INTO [dbo].[LichSuSuCo] (
            [MaPhieuSuCo],
            [TrangThaiCu],
            [TrangThaiMoi],
            [NguoiThayDoi],
            [ThoiDiemThayDoi],
            [GhiChu]
        )
        SELECT 
            i.[MaPhieuSuCo],
            d.[TrangThai],
            i.[TrangThai],
            ISNULL(i.[NguoiDuocGiao], 1),
            SYSUTCDATETIME(),
            N'Hệ thống tự động ghi nhật ký dịch chuyển thẻ Kanban: ' + d.[TrangThai] + N' -> ' + i.[TrangThai]
        FROM inserted i
        INNER JOIN deleted d ON i.[MaPhieuSuCo] = d.[MaPhieuSuCo]
        WHERE i.[TrangThai] <> d.[TrangThai];
    END
END;
GO

-- =========================================================================================
-- STORED PROCEDURE TÍNH TOÁN BẬC THANG & PHÁT HÀNH HÓA ĐƠN HÀNG LOẠT
-- =========================================================================================
CREATE OR ALTER PROCEDURE [dbo].[sp_PhatHanhHoaDonThangTuDong]
    @KyTinhTien DATE,
    @MaNguoiTao INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Khai báo bảng tạm lưu kết quả
        DECLARE @HoaDonMoi TABLE (
            [MaHoaDon] INT,
            [MaHopDong] INT,
            [MaPhong] INT
        );

        -- Tự động sinh mã hóa đơn và tạo bản ghi cho tất cả hợp đồng đang hiệu lực
        INSERT INTO [dbo].[HoaDon] (
            [SoHoaDon],
            [MaHopDong],
            [KyTinhTien],
            [NgayPhatHanh],
            [NgayDenHan],
            [TongTien],
            [TrangThai],
            [NoiDungQR],
            [DuongDanQR],
            [NguoiTao],
            [ThoiDiemTao]
        )
        SELECT 
            N'HD-' + FORMAT(@KyTinhTien, 'yyyyMM') + N'-' + p.[KyHieuPhong],
            hd.[MaHopDong],
            @KyTinhTien,
            CAST(GETDATE() AS DATE),
            DATEADD(DAY, 5, CAST(GETDATE() AS DATE)),
            hd.[TienThueHangThang], -- Tạm thời khởi tạo bằng tiền thuê phòng
            N'Chưa thanh toán',
            N'HD ' + p.[KyHieuPhong] + N' ' + FORMAT(@KyTinhTien, 'MM/yyyy'),
            N'https://img.vietqr.io/image/970422-0987654321-compact2.png?amount=' + CAST(CAST(ROUND(hd.[TienThueHangThang], 0) AS BIGINT) AS NVARCHAR(30)) + N'&addInfo=HD%20' + p.[KyHieuPhong] + N'&accountName=SMARTSTAY',
            @MaNguoiTao,
            SYSUTCDATETIME()
        FROM [dbo].[HopDong] hd
        INNER JOIN [dbo].[Phong] p ON hd.[MaPhong] = p.[MaPhong]
        WHERE hd.[TrangThai] = N'Đang hiệu lực'
          AND NOT EXISTS (
              SELECT 1 FROM [dbo].[HoaDon] h_check 
              WHERE h_check.[MaHopDong] = hd.[MaHopDong] AND h_check.[KyTinhTien] = @KyTinhTien
          );

        COMMIT TRANSACTION;
        SELECT @@ROWCOUNT AS [SoHoaDonDaTaoThanhCong];
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
