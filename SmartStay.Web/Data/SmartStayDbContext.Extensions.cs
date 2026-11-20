using Microsoft.EntityFrameworkCore;
using SmartStay.Web.Models;

namespace SmartStay.Web.Data;

public partial class SmartStayDbContext
{
    public virtual DbSet<ChoDoCuTin> ChoDoCuTins { get; set; }
    public virtual DbSet<ChoDoCuDanhGia> ChoDoCuDanhGias { get; set; }
    public virtual DbSet<VeKhachVangLai> VeKhachVangLais { get; set; }
    public virtual DbSet<ChiaTienPhong> ChiaTienPhongs { get; set; }
    public virtual DbSet<ChiSoTuKiemTra> ChiSoTuKiemTras { get; set; }
    public virtual DbSet<NhatKyCuocGoi> NhatKyCuocGois { get; set; }
    public virtual DbSet<PhongMedia> PhongMedias { get; set; }
    public virtual DbSet<PhieuDangKyPhong> PhieuDangKyPhongs { get; set; }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<ChoDoCuTin>(entity =>
        {
            entity.ToTable("ChoDoCuTin");
            entity.HasKey(e => e.MaTin);
            entity.Property(e => e.MaTin).HasMaxLength(64);
            entity.Property(e => e.GiaBan).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.GiaGoc).HasColumnType("decimal(18, 2)");

            entity.HasOne(d => d.MaPhongNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaPhong)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_ChoDoCuTin_Phong");

            entity.HasOne(d => d.MaCuDanBanNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaCuDanBan)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_ChoDoCuTin_CuDanBan");

            entity.HasOne(d => d.MaCuDanGiuChoNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaCuDanGiuCho)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_ChoDoCuTin_CuDanGiuCho");
        });

        modelBuilder.Entity<ChoDoCuDanhGia>(entity =>
        {
            entity.ToTable("ChoDoCuDanhGia");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.MaTin).HasMaxLength(64);

            entity.HasOne(d => d.MaTinNavigation)
                .WithMany(p => p.ChoDoCuDanhGias)
                .HasForeignKey(d => d.MaTin)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_ChoDoCuDanhGia_ChoDoCuTin");

            entity.HasOne(d => d.MaCuDanNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaCuDan)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_ChoDoCuDanhGia_CuDan");

            entity.HasOne(d => d.MaPhongNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaPhong)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_ChoDoCuDanhGia_Phong");
        });

        modelBuilder.Entity<VeKhachVangLai>(entity =>
        {
            entity.ToTable("VeKhachVangLai");
            entity.HasKey(e => e.MaVe);
            entity.Property(e => e.MaVe).HasMaxLength(64);

            entity.HasOne(d => d.MaPhongNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaPhong)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_VeKhachVangLai_Phong");

            entity.HasOne(d => d.MaCuDanNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaCuDan)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_VeKhachVangLai_CuDan");
        });

        modelBuilder.Entity<ChiaTienPhong>(entity =>
        {
            entity.ToTable("ChiaTienPhong");
            entity.HasKey(e => e.MaChia);
            entity.Property(e => e.MaChia).HasMaxLength(64);
            entity.Property(e => e.TongTien).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.MoiNguoi).HasColumnType("decimal(18, 2)");

            entity.HasOne(d => d.MaPhongNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaPhong)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_ChiaTienPhong_Phong");

            entity.HasOne(d => d.MaHoaDonNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaHoaDon)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_ChiaTienPhong_HoaDon");

            entity.HasOne(d => d.MaCuDanTaoNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaCuDanTao)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_ChiaTienPhong_CuDan");
        });

        modelBuilder.Entity<ChiSoTuKiemTra>(entity =>
        {
            entity.ToTable("ChiSoTuKiemTra");
            entity.HasKey(e => e.Id);

            entity.HasOne(d => d.MaPhongNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaPhong)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_ChiSoTuKiemTra_Phong");

            entity.HasOne(d => d.MaCuDanNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaCuDan)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_ChiSoTuKiemTra_CuDan");

            entity.HasOne(d => d.MaChiSoChinhThucNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaChiSoChinhThuc)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_ChiSoTuKiemTra_ChiSoSuDung");
        });

        modelBuilder.Entity<NhatKyCuocGoi>(entity =>
        {
            entity.ToTable("NhatKyCuocGoi");
            entity.HasKey(e => e.MaCuocGoi);
            entity.Property(e => e.MaCuocGoi).HasMaxLength(64);

            entity.HasOne(d => d.MaNguoiGoiNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaNguoiGoi)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_NhatKyCuocGoi_NguoiGoi");

            entity.HasOne(d => d.MaNguoiNhanNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaNguoiNhan)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_NhatKyCuocGoi_NguoiNhan");

            entity.HasOne(d => d.MaCuDanNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaCuDan)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_NhatKyCuocGoi_CuDan");

            entity.HasOne(d => d.MaPhongNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaPhong)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_NhatKyCuocGoi_Phong");
        });

        modelBuilder.Entity<CauHinhToChuc>(entity =>
        {
            entity.HasOne(d => d.MaToaNhaMacDinhNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaToaNhaMacDinh)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_CauHinhToChuc_ToaNha");

            entity.HasOne(d => d.NguoiCapNhatNavigation)
                .WithMany()
                .HasForeignKey(d => d.NguoiCapNhat)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_CauHinhToChuc_NguoiDung");
        });

        modelBuilder.Entity<TriThucAiRag>(entity =>
        {
            entity.HasOne(d => d.MaToaNhaNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaToaNha)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_TriThucAiRAG_ToaNha");

            entity.HasOne(d => d.NguoiCapNhatNavigation)
                .WithMany()
                .HasForeignKey(d => d.NguoiCapNhat)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_TriThucAiRAG_NguoiDung");
        });

        modelBuilder.Entity<LichSuGiaoDichVi>(entity =>
        {
            entity.HasOne(d => d.MaHoaDonLienQuanNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaHoaDonLienQuan)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_LSVi_HoaDon");
        });

        modelBuilder.Entity<PhongMedia>(entity =>
        {
            entity.ToTable("PhongMedia");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.KyHieuPhong).HasMaxLength(32);
            entity.Property(e => e.LoaiMedia).HasMaxLength(16);

            entity.HasOne(d => d.MaPhongNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaPhong)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_PhongMedia_Phong");
        });

        modelBuilder.Entity<PhieuDangKyPhong>(entity =>
        {
            entity.ToTable("PhieuDangKyPhong");
            entity.HasKey(e => e.MaPhieu);
            entity.Property(e => e.MaPhieu).HasMaxLength(64);
            entity.Property(e => e.KyHieuPhong).HasMaxLength(32);
            entity.Property(e => e.LoaiYeuCau).HasMaxLength(32);
            entity.Property(e => e.SoDienThoai).HasMaxLength(32);
            entity.Property(e => e.SoCanCuoc).HasMaxLength(32);
            entity.Property(e => e.TrangThai).HasMaxLength(32);

            entity.HasOne(d => d.MaPhongNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaPhong)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_PhieuDangKyPhong_Phong");

            entity.HasOne(d => d.MaCuDanNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaCuDan)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_PhieuDangKyPhong_CuDan");

            entity.HasOne(d => d.MaHopDongTaoNavigation)
                .WithMany()
                .HasForeignKey(d => d.MaHopDongTao)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_PhieuDangKyPhong_HopDong");
        });
    }
}
