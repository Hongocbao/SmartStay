using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using SmartStay.Api.Models;

namespace SmartStay.Api.Data;

public partial class SmartStayDbContext : DbContext
{
    public SmartStayDbContext()
    {
    }

    public SmartStayDbContext(DbContextOptions<SmartStayDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<BacGium> BacGia { get; set; }

    public virtual DbSet<BienBanBanGiao> BienBanBanGiaos { get; set; }

    public virtual DbSet<CauHinhToChuc> CauHinhToChucs { get; set; }

    public virtual DbSet<ChiSoSuDung> ChiSoSuDungs { get; set; }

    public virtual DbSet<ChiTietHoaDon> ChiTietHoaDons { get; set; }

    public virtual DbSet<CuDan> CuDans { get; set; }

    public virtual DbSet<CuDanHopDong> CuDanHopDongs { get; set; }

    public virtual DbSet<DangKySuKien> DangKySuKiens { get; set; }

    public virtual DbSet<DanhMucSuCo> DanhMucSuCos { get; set; }

    public virtual DbSet<DichVu> DichVus { get; set; }

    public virtual DbSet<DichVuHopDong> DichVuHopDongs { get; set; }

    public virtual DbSet<Giuong> Giuongs { get; set; }

    public virtual DbSet<HinhAnhSuCo> HinhAnhSuCos { get; set; }

    public virtual DbSet<HoaDon> HoaDons { get; set; }

    public virtual DbSet<HopDong> HopDongs { get; set; }

    public virtual DbSet<LichSuGiaoDichVi> LichSuGiaoDichVis { get; set; }

    public virtual DbSet<LichSuSuCo> LichSuSuCos { get; set; }

    public virtual DbSet<LichSuTruyCapCua> LichSuTruyCapCuas { get; set; }

    public virtual DbSet<LoaiPhong> LoaiPhongs { get; set; }

    public virtual DbSet<MaDatLaiMatKhau> MaDatLaiMatKhaus { get; set; }

    public virtual DbSet<NguoiDung> NguoiDungs { get; set; }

    public virtual DbSet<NhatKyKiemToan> NhatKyKiemToans { get; set; }

    public virtual DbSet<PhienTroChuyen> PhienTroChuyens { get; set; }

    public virtual DbSet<PhieuDatGiuCho> PhieuDatGiuChos { get; set; }

    public virtual DbSet<PhieuSuCo> PhieuSuCos { get; set; }

    public virtual DbSet<PhieuXuatVatTuSuCo> PhieuXuatVatTuSuCos { get; set; }

    public virtual DbSet<Phong> Phongs { get; set; }

    public virtual DbSet<PhuongTienCuDan> PhuongTienCuDans { get; set; }

    public virtual DbSet<SoQuyThuChi> SoQuyThuChis { get; set; }

    public virtual DbSet<SuKien> SuKiens { get; set; }

    public virtual DbSet<TaiSanBanGiao> TaiSanBanGiaos { get; set; }

    public virtual DbSet<TaiSanPhong> TaiSanPhongs { get; set; }

    public virtual DbSet<ThanhToan> ThanhToans { get; set; }

    public virtual DbSet<ThietBiIoT> ThietBiIoTs { get; set; }

    public virtual DbSet<ThietBiThongBao> ThietBiThongBaos { get; set; }

    public virtual DbSet<ThongBao> ThongBaos { get; set; }

    public virtual DbSet<ThongBaoHeThong> ThongBaoHeThongs { get; set; }

    public virtual DbSet<TinNhanTroChuyen> TinNhanTroChuyens { get; set; }

    public virtual DbSet<ToaNha> ToaNhas { get; set; }

    public virtual DbSet<TraoDoiSuCo> TraoDoiSuCos { get; set; }

    public virtual DbSet<TriThucAiRag> TriThucAiRags { get; set; }

    public virtual DbSet<VBaoCaoDoanhThuTheoToaNha> VBaoCaoDoanhThuTheoToaNhas { get; set; }

    public virtual DbSet<VSoDoPhongRealTime> VSoDoPhongRealTimes { get; set; }

    public virtual DbSet<VaiTro> VaiTros { get; set; }

    public virtual DbSet<VatTuLinhKien> VatTuLinhKiens { get; set; }

    public virtual DbSet<ViCuDan> ViCuDans { get; set; }

    public virtual DbSet<WebhookGiaoDichNganHang> WebhookGiaoDichNganHangs { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        if (!optionsBuilder.IsConfigured)
        {
            optionsBuilder.UseSqlServer("Server=MSI-Bao\\SQLEXPRESS;Database=SmartStayDB;Trusted_Connection=True;TrustServerCertificate=True");
        }
    }
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<BacGium>(entity =>
        {
            entity.HasKey(e => e.MaBacGia).HasName("PK_PriceTiers");

            entity.HasIndex(e => new { e.MaDichVu, e.HieuLucTu, e.HieuLucDen }, "IX_PriceTiers_Service_Effective");

            entity.HasIndex(e => new { e.MaDichVu, e.ThuTuBac, e.HieuLucTu }, "UQ_PriceTiers").IsUnique();

            entity.Property(e => e.DonGia).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.SoLuongDen).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.SoLuongTu).HasColumnType("decimal(18, 2)");

            entity.HasOne(d => d.MaDichVuNavigation).WithMany(p => p.BacGia)
                .HasForeignKey(d => d.MaDichVu)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PriceTiers_Services");
        });

        modelBuilder.Entity<BienBanBanGiao>(entity =>
        {
            entity.HasKey(e => e.MaBienBanBanGiao).HasName("PK_HandoverReports");

            entity.ToTable("BienBanBanGiao");

            entity.HasIndex(e => new { e.MaHopDong, e.LoaiBanGiao }, "UQ_Handover").IsUnique();

            entity.Property(e => e.ChiSoDien).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.ChiSoNuoc).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.GhiChu).HasMaxLength(500);
            entity.Property(e => e.LoaiBanGiao).HasMaxLength(10);
            entity.Property(e => e.ThoiDiemBanGiao).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.TienCocDaNhan).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.TienHoanLai).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.TienKhauTruCongNo).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.TienKhauTruHuHong).HasColumnType("decimal(18, 2)");

            entity.HasOne(d => d.MaHopDongNavigation).WithMany(p => p.BienBanBanGiaos)
                .HasForeignKey(d => d.MaHopDong)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Handover_Contracts");

            entity.HasOne(d => d.NguoiTaoNavigation).WithMany(p => p.BienBanBanGiaos)
                .HasForeignKey(d => d.NguoiTao)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Handover_Users");
        });

        modelBuilder.Entity<CauHinhToChuc>(entity =>
        {
            entity.HasKey(e => e.MaToChuc).HasName("PK_OrganizationSettings");

            entity.ToTable("CauHinhToChuc");

            entity.Property(e => e.MaToChuc).ValueGeneratedNever();
            entity.Property(e => e.DiaChi).HasMaxLength(250);
            entity.Property(e => e.DuongDanLogo).HasMaxLength(300);
            entity.Property(e => e.MaNganHang).HasMaxLength(10);
            entity.Property(e => e.SoDienThoai).HasMaxLength(15);
            entity.Property(e => e.SoNgayHanThanhToan).HasDefaultValue(10);
            entity.Property(e => e.SoTaiKhoanNganHang).HasMaxLength(30);
            entity.Property(e => e.TenChuTaiKhoan).HasMaxLength(100);
            entity.Property(e => e.TenToChuc).HasMaxLength(150);
            entity.Property(e => e.ThuDienTu).HasMaxLength(100);
        });

        modelBuilder.Entity<ChiSoSuDung>(entity =>
        {
            entity.HasKey(e => e.MaChiSo).HasName("PK_MeterReadings");

            entity.ToTable("ChiSoSuDung");

            entity.HasIndex(e => e.KyTinhTien, "IX_MeterReadings_Month");

            entity.HasIndex(e => new { e.MaPhong, e.KyTinhTien, e.MaDichVu }, "IX_MeterReadings_Room_Month").IsDescending(false, true, false);

            entity.HasIndex(e => new { e.MaPhong, e.MaDichVu, e.KyTinhTien }, "IX_MeterReadings_Room_Service_Month");

            entity.HasIndex(e => new { e.MaPhong, e.MaDichVu, e.KyTinhTien, e.LoaiGhiChiSo }, "UQ_MeterReadings").IsUnique();

            entity.Property(e => e.ChiSoHienTai).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.ChiSoTruoc).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.GhiChu).HasMaxLength(300);
            entity.Property(e => e.LoaiGhiChiSo)
                .HasMaxLength(10)
                .HasDefaultValue("Monthly");
            entity.Property(e => e.MucTieuThu)
                .HasComputedColumnSql("([ChiSoHienTai]-[ChiSoTruoc])", true)
                .HasColumnType("decimal(19, 2)");
            entity.Property(e => e.NgayGhiChiSo).HasDefaultValueSql("(CONVERT([date],sysdatetime()))");

            entity.HasOne(d => d.MaDichVuNavigation).WithMany(p => p.ChiSoSuDungs)
                .HasForeignKey(d => d.MaDichVu)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_MeterReadings_Services");

            entity.HasOne(d => d.MaPhongNavigation).WithMany(p => p.ChiSoSuDungs)
                .HasForeignKey(d => d.MaPhong)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_MeterReadings_Rooms");

            entity.HasOne(d => d.NguoiGhiNhanNavigation).WithMany(p => p.ChiSoSuDungs)
                .HasForeignKey(d => d.NguoiGhiNhan)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_MeterReadings_Users");
        });

        modelBuilder.Entity<ChiTietHoaDon>(entity =>
        {
            entity.HasKey(e => e.MaChiTiet).HasName("PK_InvoiceItems");

            entity.ToTable("ChiTietHoaDon");

            entity.HasIndex(e => e.MaHoaDon, "IX_InvoiceItems_Invoice");

            entity.HasIndex(e => e.MaChiSo, "IX_InvoiceItems_Reading").HasFilter("([MaChiSo] IS NOT NULL)");

            entity.HasIndex(e => e.MaDichVu, "IX_InvoiceItems_ServiceId").HasFilter("([MaDichVu] IS NOT NULL)");

            entity.HasIndex(e => e.MaPhieuSuCo, "IX_InvoiceItems_Ticket").HasFilter("([MaPhieuSuCo] IS NOT NULL)");

            entity.HasIndex(e => e.MaPhieuSuCo, "IX_InvoiceItems_TicketId").HasFilter("([MaPhieuSuCo] IS NOT NULL)");

            entity.Property(e => e.DonGia).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.LoaiKhoanThu).HasMaxLength(15);
            entity.Property(e => e.MoTa).HasMaxLength(200);
            entity.Property(e => e.SoLuong)
                .HasDefaultValue(1m)
                .HasColumnType("decimal(18, 2)");
            entity.Property(e => e.ThanhTien)
                .HasComputedColumnSql("([SoLuong]*[DonGia])", true)
                .HasColumnType("decimal(37, 4)");

            entity.HasOne(d => d.MaBacGiaNavigation).WithMany(p => p.ChiTietHoaDons)
                .HasForeignKey(d => d.MaBacGia)
                .HasConstraintName("FK_InvoiceItems_Tiers");

            entity.HasOne(d => d.MaChiSoNavigation).WithMany(p => p.ChiTietHoaDons)
                .HasForeignKey(d => d.MaChiSo)
                .HasConstraintName("FK_InvoiceItems_Readings");

            entity.HasOne(d => d.MaDichVuNavigation).WithMany(p => p.ChiTietHoaDons)
                .HasForeignKey(d => d.MaDichVu)
                .HasConstraintName("FK_InvoiceItems_Services");

            entity.HasOne(d => d.MaHoaDonNavigation).WithMany(p => p.ChiTietHoaDons)
                .HasForeignKey(d => d.MaHoaDon)
                .HasConstraintName("FK_InvoiceItems_Invoices");

            entity.HasOne(d => d.MaPhieuSuCoNavigation).WithMany(p => p.ChiTietHoaDons)
                .HasForeignKey(d => d.MaPhieuSuCo)
                .HasConstraintName("FK_InvoiceItems_Tickets");
        });

        modelBuilder.Entity<CuDan>(entity =>
        {
            entity.HasKey(e => e.MaCuDan).HasName("PK_Residents");

            entity.ToTable("CuDan");

            entity.HasIndex(e => e.SoCanCuoc, "UQ_Residents_IdCard").IsUnique();

            entity.HasIndex(e => e.MaNguoiDung, "UQ_Residents_UserId").IsUnique();

            entity.Property(e => e.DiaChiThuongTru).HasMaxLength(250);
            entity.Property(e => e.GioiTinh).HasMaxLength(10);
            entity.Property(e => e.SoCanCuoc).HasMaxLength(20);
            entity.Property(e => e.SoDienThoaiKhanCap).HasMaxLength(15);
            entity.Property(e => e.TenNguoiLienHeKhanCap).HasMaxLength(100);

            entity.HasOne(d => d.MaNguoiDungNavigation).WithOne(p => p.CuDan)
                .HasForeignKey<CuDan>(d => d.MaNguoiDung)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Residents_Users");
        });

        modelBuilder.Entity<CuDanHopDong>(entity =>
        {
            entity.HasKey(e => new { e.MaHopDong, e.MaCuDan }).HasName("PK_ContractResidents");

            entity.ToTable("CuDanHopDong");

            entity.HasIndex(e => new { e.MaHopDong, e.LaDaiDien }, "IX_ContractResidents_Contract_Primary");

            entity.HasIndex(e => e.MaCuDan, "IX_ContractResidents_Resident");

            entity.HasIndex(e => e.MaHopDong, "UX_ContractResidents_Primary")
                .IsUnique()
                .HasFilter("([LaDaiDien]=(1))");

            entity.HasOne(d => d.MaCuDanNavigation).WithMany(p => p.CuDanHopDongs)
                .HasForeignKey(d => d.MaCuDan)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_ContractResidents_Residents");

            entity.HasOne(d => d.MaHopDongNavigation).WithOne(p => p.CuDanHopDong)
                .HasForeignKey<CuDanHopDong>(d => d.MaHopDong)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_ContractResidents_Contracts");
        });

        modelBuilder.Entity<DangKySuKien>(entity =>
        {
            entity.HasKey(e => e.MaDangKy).HasName("PK_EventRegistrations");

            entity.ToTable("DangKySuKien");

            entity.HasIndex(e => new { e.MaCuDan, e.ThoiDiemDangKy }, "IX_EventRegistrations_Resident_Date").IsDescending(false, true);

            entity.HasIndex(e => new { e.MaCuDan, e.TrangThai }, "IX_EventRegistrations_Resident_Status");

            entity.HasIndex(e => new { e.MaSuKien, e.MaCuDan }, "UQ_EventReg").IsUnique();

            entity.Property(e => e.ThoiDiemDangKy).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.TrangThai)
                .HasMaxLength(12)
                .HasDefaultValue("Registered");

            entity.HasOne(d => d.MaCuDanNavigation).WithMany(p => p.DangKySuKiens)
                .HasForeignKey(d => d.MaCuDan)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_EventReg_Residents");

            entity.HasOne(d => d.MaSuKienNavigation).WithMany(p => p.DangKySuKiens)
                .HasForeignKey(d => d.MaSuKien)
                .HasConstraintName("FK_EventReg_Events");
        });

        modelBuilder.Entity<DanhMucSuCo>(entity =>
        {
            entity.HasKey(e => e.MaDanhMuc).HasName("PK_TicketCategories");

            entity.ToTable("DanhMucSuCo");

            entity.HasIndex(e => e.TenDanhMuc, "UQ_TicketCategories_Name").IsUnique();

            entity.Property(e => e.TenDanhMuc).HasMaxLength(50);
        });

        modelBuilder.Entity<DichVu>(entity =>
        {
            entity.HasKey(e => e.MaDichVu).HasName("PK_Services");

            entity.ToTable("DichVu");

            entity.HasIndex(e => e.TenDichVu, "UQ_Services_Name").IsUnique();

            entity.Property(e => e.DangHoatDong).HasDefaultValue(true);
            entity.Property(e => e.DonVi).HasMaxLength(20);
            entity.Property(e => e.LoaiDichVu).HasMaxLength(10);
            entity.Property(e => e.TenDichVu).HasMaxLength(100);
        });

        modelBuilder.Entity<DichVuHopDong>(entity =>
        {
            entity.HasKey(e => e.MaDichVuHopDong).HasName("PK_ContractServices");

            entity.ToTable("DichVuHopDong");

            entity.HasIndex(e => new { e.MaHopDong, e.NgayBatDau, e.NgayKetThuc }, "IX_ContractServices_Contract_Dates");

            entity.HasIndex(e => new { e.MaDichVu, e.NgayBatDau, e.NgayKetThuc }, "IX_ContractServices_Service_Period");

            entity.HasIndex(e => new { e.MaHopDong, e.MaDichVu, e.NgayBatDau }, "UQ_ContractServices").IsUnique();

            entity.Property(e => e.SoLuong).HasDefaultValue(1);

            entity.HasOne(d => d.MaDichVuNavigation).WithMany(p => p.DichVuHopDongs)
                .HasForeignKey(d => d.MaDichVu)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_ContractServices_Services");

            entity.HasOne(d => d.MaHopDongNavigation).WithMany(p => p.DichVuHopDongs)
                .HasForeignKey(d => d.MaHopDong)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_ContractServices_Contracts");
        });

        modelBuilder.Entity<Giuong>(entity =>
        {
            entity.HasKey(e => e.MaGiuong).HasName("PK__Giuong__9C9FF4DC38BCFEDF");

            entity.ToTable("Giuong");

            entity.Property(e => e.GhiChu).HasMaxLength(500);
            entity.Property(e => e.GiaThueThang)
                .HasDefaultValue(1500000.00m)
                .HasColumnType("decimal(18, 2)");
            entity.Property(e => e.KyHieuGiuong).HasMaxLength(50);
            entity.Property(e => e.TrangThai)
                .HasMaxLength(40)
                .HasDefaultValue("Trống");

            entity.HasOne(d => d.MaPhongNavigation).WithMany(p => p.Giuongs)
                .HasForeignKey(d => d.MaPhong)
                .HasConstraintName("FK_Giuong_Phong");
        });

        modelBuilder.Entity<HinhAnhSuCo>(entity =>
        {
            entity.HasKey(e => e.MaHinhAnh).HasName("PK_TicketImages");

            entity.ToTable("HinhAnhSuCo");

            entity.Property(e => e.DuongDanTep).HasMaxLength(300);
            entity.Property(e => e.LoaiHinhAnh).HasMaxLength(15);
            entity.Property(e => e.LoaiTep)
                .HasMaxLength(10)
                .HasDefaultValue("Image");
            entity.Property(e => e.ThoiDiemTaiLen).HasDefaultValueSql("(sysdatetime())");

            entity.HasOne(d => d.MaPhieuSuCoNavigation).WithMany(p => p.HinhAnhSuCos)
                .HasForeignKey(d => d.MaPhieuSuCo)
                .HasConstraintName("FK_TicketImages_Tickets");

            entity.HasOne(d => d.NguoiTaiLenNavigation).WithMany(p => p.HinhAnhSuCos)
                .HasForeignKey(d => d.NguoiTaiLen)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_TicketImages_Users");
        });

        modelBuilder.Entity<HoaDon>(entity =>
        {
            entity.HasKey(e => e.MaHoaDon).HasName("PK_Invoices");

            entity.ToTable("HoaDon");

            entity.HasIndex(e => new { e.TrangThai, e.KyTinhTien }, "IX_HoaDon_TrangThai_KyTinhTien");

            entity.HasIndex(e => new { e.MaHopDong, e.KyTinhTien }, "IX_Invoices_Contract_Month");

            entity.HasIndex(e => new { e.TrangThai, e.NgayDenHan }, "IX_Invoices_Status_Due");

            entity.HasIndex(e => e.SoHoaDon, "UQ_Invoices_Code").IsUnique();

            entity.HasIndex(e => new { e.MaHopDong, e.KyTinhTien }, "UX_Invoices_Contract_Month")
                .IsUnique()
                .HasFilter("([TrangThai]<>N'Cancelled')");

            entity.Property(e => e.DuongDanQr)
                .HasMaxLength(500)
                .HasColumnName("DuongDanQR");
            entity.Property(e => e.NoiDungQr)
                .HasMaxLength(100)
                .HasColumnName("NoiDungQR");
            entity.Property(e => e.SoHoaDon).HasMaxLength(30);
            entity.Property(e => e.ThoiDiemTao).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.TongTien).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.TrangThai)
                .HasMaxLength(15)
                .HasDefaultValue("Draft");

            entity.HasOne(d => d.MaHopDongNavigation).WithMany(p => p.HoaDons)
                .HasForeignKey(d => d.MaHopDong)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Invoices_Contracts");

            entity.HasOne(d => d.NguoiTaoNavigation).WithMany(p => p.HoaDons)
                .HasForeignKey(d => d.NguoiTao)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Invoices_CreatedBy");
        });

        modelBuilder.Entity<HopDong>(entity =>
        {
            entity.HasKey(e => e.MaHopDong).HasName("PK_Contracts");

            entity.ToTable("HopDong");

            entity.HasIndex(e => e.NguoiTao, "IX_Contracts_CreatedBy");

            entity.HasIndex(e => e.NgayKetThuc, "IX_Contracts_EndDate").HasFilter("([TrangThai]=N'Active')");

            entity.HasIndex(e => new { e.MaPhong, e.TrangThai, e.NgayBatDau, e.NgayKetThuc }, "IX_Contracts_Room_Status_Dates");

            entity.HasIndex(e => e.SoHopDong, "UQ_Contracts_Code").IsUnique();

            entity.HasIndex(e => e.MaPhong, "UX_Contracts_Room_Active")
                .IsUnique()
                .HasFilter("([TrangThai]=N'Active')");

            entity.Property(e => e.LyDoChamDut).HasMaxLength(300);
            entity.Property(e => e.SoHopDong).HasMaxLength(30);
            entity.Property(e => e.ThoiDiemTao).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.TienDatCoc).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.TienThueHangThang).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.TrangThai)
                .HasMaxLength(20)
                .HasDefaultValue("Draft");

            entity.HasOne(d => d.MaPhongNavigation).WithOne(p => p.HopDong)
                .HasForeignKey<HopDong>(d => d.MaPhong)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Contracts_Rooms");

            entity.HasOne(d => d.NguoiTaoNavigation).WithMany(p => p.HopDongs)
                .HasForeignKey(d => d.NguoiTao)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Contracts_CreatedBy");
        });

        modelBuilder.Entity<LichSuGiaoDichVi>(entity =>
        {
            entity.HasKey(e => e.MaGiaoDichVi).HasName("PK__LichSuGi__F00F7E0CEBC44905");

            entity.ToTable("LichSuGiaoDichVi");

            entity.Property(e => e.LoaiGiaoDich).HasMaxLength(50);
            entity.Property(e => e.NoiDung).HasMaxLength(300);
            entity.Property(e => e.SoDuSau).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.SoDuTruoc).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.SoTien).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.ThoiGian).HasDefaultValueSql("(sysutcdatetime())");

            entity.HasOne(d => d.MaViNavigation).WithMany(p => p.LichSuGiaoDichVis)
                .HasForeignKey(d => d.MaVi)
                .HasConstraintName("FK_LSVi_Vi");
        });

        modelBuilder.Entity<LichSuSuCo>(entity =>
        {
            entity.HasKey(e => e.MaLichSu).HasName("PK_TicketHistories");

            entity.ToTable("LichSuSuCo");

            entity.HasIndex(e => new { e.MaPhieuSuCo, e.ThoiDiemThayDoi }, "IX_TicketHistories_Ticket_Date").IsDescending(false, true);

            entity.Property(e => e.GhiChu).HasMaxLength(300);
            entity.Property(e => e.ThoiDiemThayDoi).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.TrangThaiCu).HasMaxLength(15);
            entity.Property(e => e.TrangThaiMoi).HasMaxLength(15);

            entity.HasOne(d => d.MaPhieuSuCoNavigation).WithMany(p => p.LichSuSuCos)
                .HasForeignKey(d => d.MaPhieuSuCo)
                .HasConstraintName("FK_TicketHistories_Tickets");

            entity.HasOne(d => d.NguoiThayDoiNavigation).WithMany(p => p.LichSuSuCos)
                .HasForeignKey(d => d.NguoiThayDoi)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_TicketHistories_Users");
        });

        modelBuilder.Entity<LichSuTruyCapCua>(entity =>
        {
            entity.HasKey(e => e.MaLichSuTruyCap).HasName("PK__LichSuTr__E665B018A2186FBD");

            entity.ToTable("LichSuTruyCapCua");

            entity.Property(e => e.GhiChu).HasMaxLength(255);
            entity.Property(e => e.PhuongThucMo).HasMaxLength(50);
            entity.Property(e => e.ThanhCong).HasDefaultValue(true);
            entity.Property(e => e.ThoiDiemMo).HasDefaultValueSql("(sysutcdatetime())");

            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany(p => p.LichSuTruyCapCuas)
                .HasForeignKey(d => d.MaNguoiDung)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_LSTC_NguoiDung");

            entity.HasOne(d => d.MaThietBiIoTNavigation).WithMany(p => p.LichSuTruyCapCuas)
                .HasForeignKey(d => d.MaThietBiIoT)
                .HasConstraintName("FK_LSTC_IoT");
        });

        modelBuilder.Entity<LoaiPhong>(entity =>
        {
            entity.HasKey(e => e.MaLoaiPhong).HasName("PK_RoomTypes");

            entity.ToTable("LoaiPhong");

            entity.HasIndex(e => e.TenLoaiPhong, "UQ_RoomTypes_Name").IsUnique();

            entity.Property(e => e.GiaCoBan).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.MoTa).HasMaxLength(300);
            entity.Property(e => e.TenLoaiPhong).HasMaxLength(100);
        });

        modelBuilder.Entity<MaDatLaiMatKhau>(entity =>
        {
            entity.HasKey(e => e.MaToken).HasName("PK_PasswordResetTokens");

            entity.ToTable("MaDatLaiMatKhau");

            entity.HasIndex(e => new { e.MaNguoiDung, e.DaSuDung, e.HetHanLuc }, "IX_PasswordResetTokens_User_State");

            entity.HasIndex(e => e.MaXacThuc, "UQ_PwdReset_Token").IsUnique();

            entity.Property(e => e.MaXacThuc).HasMaxLength(200);

            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany(p => p.MaDatLaiMatKhaus)
                .HasForeignKey(d => d.MaNguoiDung)
                .HasConstraintName("FK_PwdReset_Users");
        });

        modelBuilder.Entity<NguoiDung>(entity =>
        {
            entity.HasKey(e => e.MaNguoiDung).HasName("PK_Users");

            entity.ToTable("NguoiDung");

            entity.HasIndex(e => e.MaVaiTro, "IX_Users_RoleId");

            entity.HasIndex(e => new { e.MaVaiTro, e.DangHoatDong }, "IX_Users_Role_Active");

            entity.HasIndex(e => e.TenDangNhap, "UQ_Users_Username").IsUnique();

            entity.HasIndex(e => e.ThuDienTu, "UX_Users_Email")
                .IsUnique()
                .HasFilter("([ThuDienTu] IS NOT NULL)");

            entity.HasIndex(e => e.SoDienThoai, "UX_Users_Phone")
                .IsUnique()
                .HasFilter("([SoDienThoai] IS NOT NULL)");

            entity.Property(e => e.CanDoiMatKhau).HasDefaultValue(true);
            entity.Property(e => e.DangHoatDong).HasDefaultValue(true);
            entity.Property(e => e.HoTen).HasMaxLength(100);
            entity.Property(e => e.MaBamMatKhau).HasMaxLength(256);
            entity.Property(e => e.SoDienThoai).HasMaxLength(15);
            entity.Property(e => e.TenDangNhap).HasMaxLength(50);
            entity.Property(e => e.ThoiDiemTao).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.ThuDienTu).HasMaxLength(100);

            entity.HasOne(d => d.MaVaiTroNavigation).WithMany(p => p.NguoiDungs)
                .HasForeignKey(d => d.MaVaiTro)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Users_Roles");
        });

        modelBuilder.Entity<NhatKyKiemToan>(entity =>
        {
            entity.HasKey(e => e.MaNhatKy).HasName("PK_AuditLogs");

            entity.ToTable("NhatKyKiemToan");

            entity.HasIndex(e => new { e.TenDoiTuong, e.MaDoiTuong, e.ThoiDiemTao }, "IX_AuditLogs_Entity_Created").IsDescending(false, false, true);

            entity.HasIndex(e => new { e.TenDoiTuong, e.MaDoiTuong, e.ThoiDiemTao }, "IX_AuditLogs_Entity_CreatedAt").IsDescending(false, false, true);

            entity.HasIndex(e => new { e.MaNguoiDung, e.ThoiDiemTao }, "IX_AuditLogs_User_Created").IsDescending(false, true);

            entity.Property(e => e.DiaChiIp)
                .HasMaxLength(45)
                .HasColumnName("DiaChiIP");
            entity.Property(e => e.HanhDong).HasMaxLength(50);
            entity.Property(e => e.MaDoiTuong).HasMaxLength(50);
            entity.Property(e => e.TenDoiTuong).HasMaxLength(100);
            entity.Property(e => e.ThoiDiemTao).HasDefaultValueSql("(sysdatetime())");

            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany(p => p.NhatKyKiemToans)
                .HasForeignKey(d => d.MaNguoiDung)
                .HasConstraintName("FK_AuditLogs_Users");
        });

        modelBuilder.Entity<PhienTroChuyen>(entity =>
        {
            entity.HasKey(e => e.MaPhien).HasName("PK_ChatSessions");

            entity.ToTable("PhienTroChuyen");

            entity.HasIndex(e => new { e.MaNguoiDung, e.ThoiDiemTao }, "IX_ChatSessions_User_Date").IsDescending(false, true);

            entity.Property(e => e.ThoiDiemTao).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.TieuDe).HasMaxLength(150);

            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany(p => p.PhienTroChuyens)
                .HasForeignKey(d => d.MaNguoiDung)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_ChatSessions_Users");
        });

        modelBuilder.Entity<PhieuDatGiuCho>(entity =>
        {
            entity.HasKey(e => e.MaPhieuDat).HasName("PK__PhieuDat__01EA0D2BEE819CAD");

            entity.ToTable("PhieuDatGiuCho");

            entity.HasIndex(e => e.SoPhieuDat, "UQ__PhieuDat__9B0534E8EE9B25E6").IsUnique();

            entity.Property(e => e.Email).HasMaxLength(150);
            entity.Property(e => e.GhiChu).HasMaxLength(500);
            entity.Property(e => e.HoTenKhach).HasMaxLength(150);
            entity.Property(e => e.NgayDat).HasDefaultValueSql("(sysutcdatetime())");
            entity.Property(e => e.SoCccd)
                .HasMaxLength(40)
                .HasColumnName("SoCCCD");
            entity.Property(e => e.SoDienThoai).HasMaxLength(30);
            entity.Property(e => e.SoPhieuDat).HasMaxLength(50);
            entity.Property(e => e.TienCocGiuCho).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.TrangThai)
                .HasMaxLength(40)
                .HasDefaultValue("Chờ nhận phòng");

            entity.HasOne(d => d.MaGiuongNavigation).WithMany(p => p.PhieuDatGiuChos)
                .HasForeignKey(d => d.MaGiuong)
                .HasConstraintName("FK_DatCho_Giuong");

            entity.HasOne(d => d.MaPhongNavigation).WithMany(p => p.PhieuDatGiuChos)
                .HasForeignKey(d => d.MaPhong)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_DatCho_Phong");
        });

        modelBuilder.Entity<PhieuSuCo>(entity =>
        {
            entity.HasKey(e => e.MaPhieuSuCo).HasName("PK_Tickets");

            entity.ToTable("PhieuSuCo", tb => tb.HasTrigger("trg_PhieuSuCo_GhiNhatKyKanban"));

            entity.HasIndex(e => new { e.TrangThai, e.UuTien }, "IX_PhieuSuCo_TrangThai_UuTien");

            entity.HasIndex(e => e.NguoiDuocGiao, "IX_Tickets_AssignedTo");

            entity.HasIndex(e => e.MaCuDan, "IX_Tickets_Resident");

            entity.HasIndex(e => new { e.MaPhong, e.ThoiDiemTao }, "IX_Tickets_Room_CreatedAt").IsDescending(false, true);

            entity.HasIndex(e => new { e.MaPhong, e.TrangThai, e.ThoiDiemTao }, "IX_Tickets_Room_Status_Date").IsDescending(false, false, true);

            entity.HasIndex(e => new { e.TrangThai, e.UuTien }, "IX_Tickets_Status");

            entity.HasIndex(e => e.SoPhieuSuCo, "UQ_Tickets_Code").IsUnique();

            entity.Property(e => e.ChiPhiVatTu).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.GhiChuXuLy).HasMaxLength(500);
            entity.Property(e => e.LyDoTuChoi).HasMaxLength(300);
            entity.Property(e => e.MoTa).HasMaxLength(1000);
            entity.Property(e => e.NhanXetDanhGia).HasMaxLength(300);
            entity.Property(e => e.SoPhieuSuCo).HasMaxLength(20);
            entity.Property(e => e.ThoiDiemTao).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.TieuDe).HasMaxLength(150);
            entity.Property(e => e.TrangThai)
                .HasMaxLength(15)
                .HasDefaultValue("Pending");
            entity.Property(e => e.UuTien)
                .HasMaxLength(10)
                .HasDefaultValue("Medium");

            entity.HasOne(d => d.MaCuDanNavigation).WithMany(p => p.PhieuSuCos)
                .HasForeignKey(d => d.MaCuDan)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Tickets_Residents");

            entity.HasOne(d => d.MaDanhMucNavigation).WithMany(p => p.PhieuSuCos)
                .HasForeignKey(d => d.MaDanhMuc)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Tickets_Categories");

            entity.HasOne(d => d.MaPhongNavigation).WithMany(p => p.PhieuSuCos)
                .HasForeignKey(d => d.MaPhong)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Tickets_Rooms");

            entity.HasOne(d => d.NguoiDuocGiaoNavigation).WithMany(p => p.PhieuSuCos)
                .HasForeignKey(d => d.NguoiDuocGiao)
                .HasConstraintName("FK_Tickets_AssignedTo");
        });

        modelBuilder.Entity<PhieuXuatVatTuSuCo>(entity =>
        {
            entity.HasKey(e => e.MaXuatVatTu).HasName("PK__PhieuXua__2C5F4D957C7E85FD");

            entity.ToTable("PhieuXuatVatTuSuCo");

            entity.Property(e => e.DonGia).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.SoLuongXuat).HasDefaultValue(1);
            entity.Property(e => e.ThanhTien)
                .HasComputedColumnSql("([SoLuongXuat]*[DonGia])", false)
                .HasColumnType("decimal(29, 2)");
            entity.Property(e => e.ThoiDiemXuat).HasDefaultValueSql("(sysutcdatetime())");

            entity.HasOne(d => d.MaPhieuSuCoNavigation).WithMany(p => p.PhieuXuatVatTuSuCos)
                .HasForeignKey(d => d.MaPhieuSuCo)
                .HasConstraintName("FK_XVTSC_PhieuSuCo");

            entity.HasOne(d => d.MaVatTuNavigation).WithMany(p => p.PhieuXuatVatTuSuCos)
                .HasForeignKey(d => d.MaVatTu)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_XVTSC_VatTu");
        });

        modelBuilder.Entity<Phong>(entity =>
        {
            entity.HasKey(e => e.MaPhong).HasName("PK_Rooms");

            entity.ToTable("Phong");

            entity.HasIndex(e => new { e.TrangThai, e.SoTang }, "IX_Phong_TrangThai");

            entity.HasIndex(e => new { e.MaToaNha, e.SoTang }, "IX_Rooms_Building_Floor");

            entity.HasIndex(e => e.MaLoaiPhong, "IX_Rooms_RoomTypeId");

            entity.HasIndex(e => e.TrangThai, "IX_Rooms_Status");

            entity.HasIndex(e => new { e.MaToaNha, e.KyHieuPhong }, "UQ_Rooms_Building_Code").IsUnique();

            entity.Property(e => e.DienTich).HasColumnType("decimal(8, 2)");
            entity.Property(e => e.GiaThue).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.KyHieuPhong).HasMaxLength(20);
            entity.Property(e => e.MoTa).HasMaxLength(500);
            entity.Property(e => e.TrangThai)
                .HasMaxLength(20)
                .HasDefaultValue("Vacant");

            entity.HasOne(d => d.MaLoaiPhongNavigation).WithMany(p => p.Phongs)
                .HasForeignKey(d => d.MaLoaiPhong)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Rooms_RoomTypes");

            entity.HasOne(d => d.MaToaNhaNavigation).WithMany(p => p.Phongs)
                .HasForeignKey(d => d.MaToaNha)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Rooms_Buildings");
        });

        modelBuilder.Entity<PhuongTienCuDan>(entity =>
        {
            entity.HasKey(e => e.MaPhuongTien).HasName("PK__PhuongTi__35B6C8B00B3B0C37");

            entity.ToTable("PhuongTienCuDan");

            entity.Property(e => e.BienSoXe).HasMaxLength(30);
            entity.Property(e => e.DangHoatDong).HasDefaultValue(true);
            entity.Property(e => e.DuongDanAnhDangKyXe).HasMaxLength(600);
            entity.Property(e => e.LoaiXe)
                .HasMaxLength(50)
                .HasDefaultValue("Xe máy");
            entity.Property(e => e.MaTheXeRfid)
                .HasMaxLength(50)
                .HasColumnName("MaTheXeRFID");
            entity.Property(e => e.MauXe).HasMaxLength(50);
            entity.Property(e => e.NgayDangKy).HasDefaultValueSql("(CONVERT([date],getdate()))");
            entity.Property(e => e.NhanHieu).HasMaxLength(100);
            entity.Property(e => e.PhiGuiXeHangThang)
                .HasDefaultValue(120000.00m)
                .HasColumnType("decimal(18, 2)");

            entity.HasOne(d => d.MaCuDanNavigation).WithMany(p => p.PhuongTienCuDans)
                .HasForeignKey(d => d.MaCuDan)
                .HasConstraintName("FK_PT_CuDan");
        });

        modelBuilder.Entity<SoQuyThuChi>(entity =>
        {
            entity.HasKey(e => e.MaPhieuThuChi).HasName("PK__SoQuyThu__F0B2799018365609");

            entity.ToTable("SoQuyThuChi");

            entity.HasIndex(e => e.SoChungTu, "UQ__SoQuyThu__BB91EF56E1CA6B15").IsUnique();

            entity.Property(e => e.HangMuc).HasMaxLength(100);
            entity.Property(e => e.HinhThuc)
                .HasMaxLength(50)
                .HasDefaultValue("Chuyển khoản");
            entity.Property(e => e.LoaiPhieu).HasMaxLength(20);
            entity.Property(e => e.NguoiNopNhan).HasMaxLength(150);
            entity.Property(e => e.NoiDung).HasMaxLength(500);
            entity.Property(e => e.SoChungTu).HasMaxLength(50);
            entity.Property(e => e.SoTien).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.ThoiDiemTao).HasDefaultValueSql("(sysutcdatetime())");

            entity.HasOne(d => d.MaToaNhaNavigation).WithMany(p => p.SoQuyThuChis)
                .HasForeignKey(d => d.MaToaNha)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_SQ_ToaNha");

            entity.HasOne(d => d.NguoiLapPhieuNavigation).WithMany(p => p.SoQuyThuChis)
                .HasForeignKey(d => d.NguoiLapPhieu)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_SQ_NguoiDung");
        });

        modelBuilder.Entity<SuKien>(entity =>
        {
            entity.HasKey(e => e.MaSuKien).HasName("PK_Events");

            entity.ToTable("SuKien");

            entity.HasIndex(e => new { e.TrangThai, e.ThoiGianBatDau }, "IX_Events_Status_StartTime");

            entity.Property(e => e.DiaDiem).HasMaxLength(200);
            entity.Property(e => e.HinhAnhDuongDan).HasMaxLength(300);
            entity.Property(e => e.ThoiDiemTao).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.TieuDe).HasMaxLength(200);
            entity.Property(e => e.TrangThai)
                .HasMaxLength(10)
                .HasDefaultValue("Open");

            entity.HasOne(d => d.NguoiTaoNavigation).WithMany(p => p.SuKiens)
                .HasForeignKey(d => d.NguoiTao)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Events_CreatedBy");
        });

        modelBuilder.Entity<TaiSanBanGiao>(entity =>
        {
            entity.HasKey(e => e.MaTaiSanBanGiao).HasName("PK_HandoverItems");

            entity.ToTable("TaiSanBanGiao");

            entity.HasIndex(e => new { e.MaTaiSan, e.MaBienBanBanGiao }, "IX_HandoverItems_Asset");

            entity.HasIndex(e => new { e.MaBienBanBanGiao, e.MaTaiSan }, "UQ_HandoverItems").IsUnique();

            entity.Property(e => e.GhiChu).HasMaxLength(300);
            entity.Property(e => e.HinhAnhDuongDan).HasMaxLength(300);
            entity.Property(e => e.PhiHuHong).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.TinhTrang).HasMaxLength(20);

            entity.HasOne(d => d.MaBienBanBanGiaoNavigation).WithMany(p => p.TaiSanBanGiaos)
                .HasForeignKey(d => d.MaBienBanBanGiao)
                .HasConstraintName("FK_HandoverItems_Handover");

            entity.HasOne(d => d.MaTaiSanNavigation).WithMany(p => p.TaiSanBanGiaos)
                .HasForeignKey(d => d.MaTaiSan)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_HandoverItems_Assets");
        });

        modelBuilder.Entity<TaiSanPhong>(entity =>
        {
            entity.HasKey(e => e.MaTaiSan).HasName("PK_RoomAssets");

            entity.ToTable("TaiSanPhong");

            entity.HasIndex(e => e.MaPhong, "IX_RoomAssets_Room");

            entity.Property(e => e.GhiChu).HasMaxLength(300);
            entity.Property(e => e.HinhAnhDuongDan).HasMaxLength(300);
            entity.Property(e => e.SoLuong).HasDefaultValue(1);
            entity.Property(e => e.TenTaiSan).HasMaxLength(100);
            entity.Property(e => e.TinhTrang)
                .HasMaxLength(20)
                .HasDefaultValue("Good");

            entity.HasOne(d => d.MaPhongNavigation).WithMany(p => p.TaiSanPhongs)
                .HasForeignKey(d => d.MaPhong)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_RoomAssets_Rooms");
        });

        modelBuilder.Entity<ThanhToan>(entity =>
        {
            entity.HasKey(e => e.MaThanhToan).HasName("PK_Payments");

            entity.ToTable("ThanhToan");

            entity.HasIndex(e => e.MaHoaDon, "IX_Payments_Invoice");

            entity.HasIndex(e => e.TrangThai, "IX_Payments_Status");

            entity.HasIndex(e => e.TrangThai, "IX_ThanhToan_TrangThai");

            entity.Property(e => e.DuongDanBienLai).HasMaxLength(300);
            entity.Property(e => e.GhiChu).HasMaxLength(300);
            entity.Property(e => e.MaGiaoDich).HasMaxLength(60);
            entity.Property(e => e.PhuongThucThanhToan).HasMaxLength(15);
            entity.Property(e => e.SoTien).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.ThoiDiemThanhToan).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.TrangThai)
                .HasMaxLength(10)
                .HasDefaultValue("Pending");

            entity.HasOne(d => d.MaHoaDonNavigation).WithMany(p => p.ThanhToans)
                .HasForeignKey(d => d.MaHoaDon)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Payments_Invoices");

            entity.HasOne(d => d.NguoiGuiThanhToanNavigation).WithMany(p => p.ThanhToanNguoiGuiThanhToanNavigations)
                .HasForeignKey(d => d.NguoiGuiThanhToan)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Payments_SubmittedBy");

            entity.HasOne(d => d.NguoiXacNhanNavigation).WithMany(p => p.ThanhToanNguoiXacNhanNavigations)
                .HasForeignKey(d => d.NguoiXacNhan)
                .HasConstraintName("FK_Payments_ConfirmedBy");
        });

        modelBuilder.Entity<ThietBiIoT>(entity =>
        {
            entity.HasKey(e => e.MaThietBiIoT).HasName("PK__ThietBiI__8D054AE8F3C59B69");

            entity.ToTable("ThietBiIoT");

            entity.HasIndex(e => e.MaSeri, "UQ__ThietBiI__B3BADCB4AE103389").IsUnique();

            entity.Property(e => e.DiaChiMac).HasMaxLength(50);
            entity.Property(e => e.LoaiThietBi).HasMaxLength(50);
            entity.Property(e => e.MaSeri).HasMaxLength(100);
            entity.Property(e => e.MatKhauTruyCap).HasMaxLength(255);
            entity.Property(e => e.TenThietBi).HasMaxLength(150);
            entity.Property(e => e.TrangThaiHoatDong)
                .HasMaxLength(30)
                .HasDefaultValue("Online");

            entity.HasOne(d => d.MaPhongNavigation).WithMany(p => p.ThietBiIoTs)
                .HasForeignKey(d => d.MaPhong)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_IoT_Phong");

            entity.HasOne(d => d.MaToaNhaNavigation).WithMany(p => p.ThietBiIoTs)
                .HasForeignKey(d => d.MaToaNha)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_IoT_ToaNha");
        });

        modelBuilder.Entity<ThietBiThongBao>(entity =>
        {
            entity.HasKey(e => e.MaThietBi).HasName("PK_DeviceTokens");

            entity.ToTable("ThietBiThongBao");

            entity.HasIndex(e => new { e.MaNguoiDung, e.LanSuDungCuoi }, "IX_DeviceTokens_User_LastUsed").IsDescending(false, true);

            entity.HasIndex(e => e.MaXacThuc, "UQ_DeviceTokens_Token").IsUnique();

            entity.Property(e => e.LanSuDungCuoi).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.MaXacThuc).HasMaxLength(300);
            entity.Property(e => e.NenTang).HasMaxLength(10);

            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany(p => p.ThietBiThongBaos)
                .HasForeignKey(d => d.MaNguoiDung)
                .HasConstraintName("FK_DeviceTokens_Users");
        });

        modelBuilder.Entity<ThongBao>(entity =>
        {
            entity.HasKey(e => e.MaThongBao).HasName("PK_Announcements");

            entity.ToTable("ThongBao");

            entity.HasIndex(e => new { e.MaToaNha, e.TrangThai, e.LichGui }, "IX_Announcements_Building_Scheduled").HasFilter("([MaToaNha] IS NOT NULL)");

            entity.HasIndex(e => new { e.TrangThai, e.LichGui }, "IX_Announcements_Status_ScheduledAt");

            entity.HasIndex(e => new { e.MaNguoiNhan, e.TrangThai, e.LichGui }, "IX_Announcements_User_Scheduled").HasFilter("([MaNguoiNhan] IS NOT NULL)");

            entity.Property(e => e.HinhAnhDuongDan).HasMaxLength(300);
            entity.Property(e => e.PhamViNhan).HasMaxLength(10);
            entity.Property(e => e.ThoiDiemTao).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.TieuDe).HasMaxLength(200);
            entity.Property(e => e.TrangThai)
                .HasMaxLength(10)
                .HasDefaultValue("Draft");

            entity.HasOne(d => d.MaNguoiNhanNavigation).WithMany(p => p.ThongBaoMaNguoiNhanNavigations)
                .HasForeignKey(d => d.MaNguoiNhan)
                .HasConstraintName("FK_Announcements_TargetUser");

            entity.HasOne(d => d.MaToaNhaNavigation).WithMany(p => p.ThongBaos)
                .HasForeignKey(d => d.MaToaNha)
                .HasConstraintName("FK_Announcements_Buildings");

            entity.HasOne(d => d.NguoiTaoNavigation).WithMany(p => p.ThongBaoNguoiTaoNavigations)
                .HasForeignKey(d => d.NguoiTao)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Announcements_CreatedBy");
        });

        modelBuilder.Entity<ThongBaoHeThong>(entity =>
        {
            entity.HasKey(e => e.MaThongBao).HasName("PK_Notifications");

            entity.ToTable("ThongBaoHeThong");

            entity.HasIndex(e => new { e.MaNguoiDung, e.DaDoc, e.ThoiDiemTao }, "IX_Notifications_User").IsDescending(false, false, true);

            entity.Property(e => e.LoaiThongBao).HasMaxLength(15);
            entity.Property(e => e.NoiDung).HasMaxLength(500);
            entity.Property(e => e.ThoiDiemTao).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.TieuDe).HasMaxLength(200);

            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany(p => p.ThongBaoHeThongs)
                .HasForeignKey(d => d.MaNguoiDung)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Notifications_Users");
        });

        modelBuilder.Entity<TinNhanTroChuyen>(entity =>
        {
            entity.HasKey(e => e.MaTinNhan).HasName("PK_ChatMessages");

            entity.ToTable("TinNhanTroChuyen");

            entity.HasIndex(e => new { e.MaPhien, e.ThoiDiemTao }, "IX_ChatMessages_Session");

            entity.Property(e => e.NguoiGui).HasMaxLength(5);
            entity.Property(e => e.ThoiDiemTao).HasDefaultValueSql("(sysdatetime())");

            entity.HasOne(d => d.MaPhienNavigation).WithMany(p => p.TinNhanTroChuyens)
                .HasForeignKey(d => d.MaPhien)
                .HasConstraintName("FK_ChatMessages_Sessions");
        });

        modelBuilder.Entity<ToaNha>(entity =>
        {
            entity.HasKey(e => e.MaToaNha).HasName("PK_Buildings");

            entity.ToTable("ToaNha");

            entity.HasIndex(e => e.TenToaNha, "UQ_Buildings_Name").IsUnique();

            entity.Property(e => e.DangHoatDong).HasDefaultValue(true);
            entity.Property(e => e.DiaChi).HasMaxLength(250);
            entity.Property(e => e.MoTa).HasMaxLength(500);
            entity.Property(e => e.TenToaNha).HasMaxLength(100);
        });

        modelBuilder.Entity<TraoDoiSuCo>(entity =>
        {
            entity.HasKey(e => e.MaTraoDoi).HasName("PK_TicketComments");

            entity.ToTable("TraoDoiSuCo");

            entity.HasIndex(e => new { e.MaPhieuSuCo, e.ThoiDiemTao }, "IX_TicketComments_Ticket_Date").IsDescending(false, true);

            entity.Property(e => e.NoiDung).HasMaxLength(1000);
            entity.Property(e => e.ThoiDiemTao).HasDefaultValueSql("(sysdatetime())");

            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany(p => p.TraoDoiSuCos)
                .HasForeignKey(d => d.MaNguoiDung)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_TicketComments_Users");

            entity.HasOne(d => d.MaPhieuSuCoNavigation).WithMany(p => p.TraoDoiSuCos)
                .HasForeignKey(d => d.MaPhieuSuCo)
                .HasConstraintName("FK_TicketComments_Tickets");
        });

        modelBuilder.Entity<TriThucAiRag>(entity =>
        {
            entity.HasKey(e => e.MaTriThuc).HasName("PK__TriThucA__82ACFCC918F62AF5");

            entity.ToTable("TriThucAiRAG");

            entity.Property(e => e.CauHoiPhoBien).HasMaxLength(500);
            entity.Property(e => e.ChuDe).HasMaxLength(100);
            entity.Property(e => e.DangHoatDong).HasDefaultValue(true);
            entity.Property(e => e.DoUuTien).HasDefaultValue(1);
            entity.Property(e => e.NgayCapNhat).HasDefaultValueSql("(sysutcdatetime())");
        });

        modelBuilder.Entity<VBaoCaoDoanhThuTheoToaNha>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("v_BaoCaoDoanhThuTheoToaNha");

            entity.Property(e => e.CongNoConLai).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.DoanhThuDaThu).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.TenToaNha).HasMaxLength(100);
            entity.Property(e => e.TongTienPhatHanh).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.TyLeThuHoi).HasColumnType("decimal(5, 1)");
        });

        modelBuilder.Entity<VSoDoPhongRealTime>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("v_SoDoPhongRealTime");

            entity.Property(e => e.CongNoChuaThu).HasColumnType("decimal(38, 2)");
            entity.Property(e => e.DienTich).HasColumnType("decimal(8, 2)");
            entity.Property(e => e.GiaThue).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.KyHieuPhong).HasMaxLength(20);
            entity.Property(e => e.SdtCuDan).HasMaxLength(15);
            entity.Property(e => e.SoHopDong).HasMaxLength(30);
            entity.Property(e => e.TenCuDanDaiDien).HasMaxLength(100);
            entity.Property(e => e.TenLoaiPhong).HasMaxLength(100);
            entity.Property(e => e.TenToaNha).HasMaxLength(100);
            entity.Property(e => e.TrangThaiPhong).HasMaxLength(20);
        });

        modelBuilder.Entity<VaiTro>(entity =>
        {
            entity.HasKey(e => e.MaVaiTro).HasName("PK_Roles");

            entity.ToTable("VaiTro");

            entity.HasIndex(e => e.TenVaiTro, "UQ_Roles_RoleName").IsUnique();

            entity.Property(e => e.MoTa).HasMaxLength(200);
            entity.Property(e => e.TenVaiTro).HasMaxLength(50);
        });

        modelBuilder.Entity<VatTuLinhKien>(entity =>
        {
            entity.HasKey(e => e.MaVatTu).HasName("PK__VatTuLin__0BD27B6A1EB7A659");

            entity.ToTable("VatTuLinhKien");

            entity.Property(e => e.DinhMucToiThieu).HasDefaultValue(5);
            entity.Property(e => e.DonGiaNhap).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.DonViTinh).HasMaxLength(30);
            entity.Property(e => e.GiaXuatSuaChua).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.TenVatTu).HasMaxLength(150);

            entity.HasOne(d => d.MaToaNhaNavigation).WithMany(p => p.VatTuLinhKiens)
                .HasForeignKey(d => d.MaToaNha)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_VT_ToaNha");
        });

        modelBuilder.Entity<ViCuDan>(entity =>
        {
            entity.HasKey(e => e.MaVi).HasName("PK__ViCuDan__27251013990899DF");

            entity.ToTable("ViCuDan");

            entity.HasIndex(e => e.MaCuDan, "UQ__ViCuDan__080D9BC730438A13").IsUnique();

            entity.Property(e => e.CapNhatCuoi).HasDefaultValueSql("(sysutcdatetime())");
            entity.Property(e => e.SoDuKhaDung).HasColumnType("decimal(18, 2)");

            entity.HasOne(d => d.MaCuDanNavigation).WithOne(p => p.ViCuDan)
                .HasForeignKey<ViCuDan>(d => d.MaCuDan)
                .HasConstraintName("FK_Vi_CuDan");
        });

        modelBuilder.Entity<WebhookGiaoDichNganHang>(entity =>
        {
            entity.HasKey(e => e.MaGiaoDichNganHang).HasName("PK__WebhookG__7D7FA3009B49264E");

            entity.ToTable("WebhookGiaoDichNganHang");

            entity.HasIndex(e => e.MaThamChieuNganHang, "UQ__WebhookG__7C9C06A6E560D455").IsUnique();

            entity.Property(e => e.MaThamChieuNganHang).HasMaxLength(150);
            entity.Property(e => e.NoiDungChuyenKhoan).HasMaxLength(500);
            entity.Property(e => e.SoTaiKhoanNhan).HasMaxLength(50);
            entity.Property(e => e.SoTien).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.ThoiDiemNhanWebhook).HasDefaultValueSql("(sysutcdatetime())");
            entity.Property(e => e.TrangThaiKhop)
                .HasMaxLength(40)
                .HasDefaultValue("Chưa khớp");

            entity.HasOne(d => d.MaHoaDonKhopNavigation).WithMany(p => p.WebhookGiaoDichNganHangs)
                .HasForeignKey(d => d.MaHoaDonKhop)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_Webhook_HoaDon");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
