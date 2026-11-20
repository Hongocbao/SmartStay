using System;
using System.Collections.Generic;

namespace SmartStay.Web.Models;

public class ChoDoCuTin
{
    public string MaTin { get; set; } = string.Empty;
    public int? MaPhong { get; set; }
    public int? MaCuDanBan { get; set; }
    public int? MaCuDanGiuCho { get; set; }
    public string TieuDe { get; set; } = string.Empty;
    public string DanhMuc { get; set; } = "electronics";
    public decimal GiaBan { get; set; }
    public decimal GiaGoc { get; set; }
    public string KyHieuPhong { get; set; } = "P.305";
    public string NguoiBan { get; set; } = "Cư dân SmartStay";
    public string TinhTrang { get; set; } = "Mới đăng";
    public string MoTa { get; set; } = string.Empty;
    public string? HinhAnhUrl { get; set; }
    public string? VideoUrl { get; set; }
    public string TrangThai { get; set; } = "Đang bán";
    public string? NguoiGiuCho { get; set; }
    public double SoSaoTrungBinh { get; set; } = 5.0;
    public int SoLuotDanhGia { get; set; }
    public DateTime TaoLuc { get; set; } = DateTime.UtcNow;

    public virtual Phong? MaPhongNavigation { get; set; }
    public virtual CuDan? MaCuDanBanNavigation { get; set; }
    public virtual CuDan? MaCuDanGiuChoNavigation { get; set; }
    public virtual ICollection<ChoDoCuDanhGia> ChoDoCuDanhGias { get; set; } = new List<ChoDoCuDanhGia>();
}

public class ChoDoCuDanhGia
{
    public int Id { get; set; }
    public string MaTin { get; set; } = string.Empty;
    public int? MaCuDan { get; set; }
    public int? MaPhong { get; set; }
    public string NguoiDanhGia { get; set; } = string.Empty;
    public string KyHieuPhong { get; set; } = "P.305";
    public int SoSao { get; set; } = 5;
    public string BinhLuan { get; set; } = string.Empty;
    public string ThoiGian { get; set; } = "Vừa xong";
    public DateTime TaoLuc { get; set; } = DateTime.UtcNow;

    public virtual ChoDoCuTin MaTinNavigation { get; set; } = null!;
    public virtual CuDan? MaCuDanNavigation { get; set; }
    public virtual Phong? MaPhongNavigation { get; set; }
}

public class VeKhachVangLai
{
    public string MaVe { get; set; } = string.Empty;
    public int? MaPhong { get; set; }
    public int? MaCuDan { get; set; }
    public string KyHieuPhong { get; set; } = "P.305";
    public string TenKhach { get; set; } = string.Empty;
    public string? SoDienThoai { get; set; }
    public string MaPin { get; set; } = string.Empty;
    public string HieuLucDen { get; set; } = string.Empty;
    public string TrangThai { get; set; } = "Đang hiệu lực";
    public DateTime TaoLuc { get; set; } = DateTime.UtcNow;

    public virtual Phong? MaPhongNavigation { get; set; }
    public virtual CuDan? MaCuDanNavigation { get; set; }
}

public class ChiaTienPhong
{
    public string MaChia { get; set; } = string.Empty;
    public int? MaPhong { get; set; }
    public int? MaHoaDon { get; set; }
    public int? MaCuDanTao { get; set; }
    public string KyHieuPhong { get; set; } = "P.305";
    public string TieuDe { get; set; } = string.Empty;
    public decimal TongTien { get; set; }
    public int SoThanhVien { get; set; } = 3;
    public decimal MoiNguoi { get; set; }
    public string TrangThai { get; set; } = "Chờ đóng";
    public DateTime TaoLuc { get; set; } = DateTime.UtcNow;

    public virtual Phong? MaPhongNavigation { get; set; }
    public virtual HoaDon? MaHoaDonNavigation { get; set; }
    public virtual CuDan? MaCuDanTaoNavigation { get; set; }
}

public class ChiSoTuKiemTra
{
    public int Id { get; set; }
    public int? MaPhong { get; set; }
    public int? MaCuDan { get; set; }
    public long? MaChiSoChinhThuc { get; set; }
    public string KyHieuPhong { get; set; } = "P.305";
    public string CheDo { get; set; } = "both";
    public double DienKyTruoc { get; set; } = 1420;
    public double DienMoiChup { get; set; } = 1540;
    public double NuocKyTruoc { get; set; } = 84;
    public double NuocMoiChup { get; set; } = 92;
    public double TongTienTamTinh { get; set; }
    public string? TomTatTieuThu { get; set; }
    public string? NguonCapNhat { get; set; }
    public string? AnhBangChungUrl { get; set; }
    public string TrangThaiDuyet { get; set; } = "Chờ quản lý duyệt";
    public DateTime TaoLuc { get; set; } = DateTime.UtcNow;

    public virtual Phong? MaPhongNavigation { get; set; }
    public virtual CuDan? MaCuDanNavigation { get; set; }
    public virtual ChiSoSuDung? MaChiSoChinhThucNavigation { get; set; }
}

public class NhatKyCuocGoi
{
    public string MaCuocGoi { get; set; } = string.Empty;
    public int? MaNguoiGoi { get; set; }
    public int? MaNguoiNhan { get; set; }
    public int? MaCuDan { get; set; }
    public int? MaPhong { get; set; }
    public string NguoiGoi { get; set; } = string.Empty;
    public string VaiTroNguoiGoi { get; set; } = "CuDan";
    public string NguoiNhan { get; set; } = string.Empty;
    public string VaiTroNguoiNhan { get; set; } = "QuanLy";
    public string LoaiCuocGoi { get; set; } = "Video";
    public string NoiDungTraoDoi { get; set; } = string.Empty;
    public int ThoiLuongGiay { get; set; }
    public string TrangThai { get; set; } = "Đã kết nối";
    public DateTime ThoiDiem { get; set; } = DateTime.UtcNow;

    public virtual NguoiDung? MaNguoiGoiNavigation { get; set; }
    public virtual NguoiDung? MaNguoiNhanNavigation { get; set; }
    public virtual CuDan? MaCuDanNavigation { get; set; }
    public virtual Phong? MaPhongNavigation { get; set; }
}

public class PhongMedia
{
    public int Id { get; set; }
    public int MaPhong { get; set; }
    public string KyHieuPhong { get; set; } = string.Empty;
    public string LoaiMedia { get; set; } = "Image"; // Image | Video
    public string Url { get; set; } = string.Empty;
    public string? MoTa { get; set; }
    public int ThuTu { get; set; }
    public DateTime TaoLuc { get; set; } = DateTime.UtcNow;

    public virtual Phong MaPhongNavigation { get; set; } = null!;
}

public class PhieuDangKyPhong
{
    public string MaPhieu { get; set; } = string.Empty;
    public int MaPhong { get; set; }
    public string KyHieuPhong { get; set; } = string.Empty;
    public int? MaCuDan { get; set; }
    public string LoaiYeuCau { get; set; } = "ThueMoi"; // ThueMoi | ChuyenPhong
    public string HoTen { get; set; } = string.Empty;
    public string SoDienThoai { get; set; } = string.Empty;
    public string? SoCanCuoc { get; set; }
    public DateOnly NgayDuKienVaoO { get; set; } = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(3));
    public string? GhiChu { get; set; }
    public string TrangThai { get; set; } = "ChoDuyet"; // ChoDuyet | DaDuyet | TuChoi
    public string? LyDoTuChoi { get; set; }
    public int? MaHopDongTao { get; set; }
    public DateTime TaoLuc { get; set; } = DateTime.UtcNow;
    public DateTime CapNhatLuc { get; set; } = DateTime.UtcNow;

    public virtual Phong MaPhongNavigation { get; set; } = null!;
    public virtual CuDan? MaCuDanNavigation { get; set; }
    public virtual HopDong? MaHopDongTaoNavigation { get; set; }
}
