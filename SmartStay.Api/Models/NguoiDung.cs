using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class NguoiDung
{
    public int MaNguoiDung { get; set; }

    public string TenDangNhap { get; set; } = null!;

    public string? ThuDienTu { get; set; }

    public string? SoDienThoai { get; set; }

    public string MaBamMatKhau { get; set; } = null!;

    public string HoTen { get; set; } = null!;

    public int MaVaiTro { get; set; }

    public bool DangHoatDong { get; set; }

    public bool CanDoiMatKhau { get; set; }

    public DateTime? LanDangNhapCuoi { get; set; }

    public DateTime ThoiDiemTao { get; set; }

    public virtual ICollection<BienBanBanGiao> BienBanBanGiaos { get; set; } = new List<BienBanBanGiao>();

    public virtual ICollection<ChiSoSuDung> ChiSoSuDungs { get; set; } = new List<ChiSoSuDung>();

    public virtual CuDan? CuDan { get; set; }

    public virtual ICollection<HinhAnhSuCo> HinhAnhSuCos { get; set; } = new List<HinhAnhSuCo>();

    public virtual ICollection<HoaDon> HoaDons { get; set; } = new List<HoaDon>();

    public virtual ICollection<HopDong> HopDongs { get; set; } = new List<HopDong>();

    public virtual ICollection<LichSuSuCo> LichSuSuCos { get; set; } = new List<LichSuSuCo>();

    public virtual ICollection<LichSuTruyCapCua> LichSuTruyCapCuas { get; set; } = new List<LichSuTruyCapCua>();

    public virtual ICollection<MaDatLaiMatKhau> MaDatLaiMatKhaus { get; set; } = new List<MaDatLaiMatKhau>();

    public virtual VaiTro MaVaiTroNavigation { get; set; } = null!;

    public virtual ICollection<NhatKyKiemToan> NhatKyKiemToans { get; set; } = new List<NhatKyKiemToan>();

    public virtual ICollection<PhienTroChuyen> PhienTroChuyens { get; set; } = new List<PhienTroChuyen>();

    public virtual ICollection<PhieuSuCo> PhieuSuCos { get; set; } = new List<PhieuSuCo>();

    public virtual ICollection<SoQuyThuChi> SoQuyThuChis { get; set; } = new List<SoQuyThuChi>();

    public virtual ICollection<SuKien> SuKiens { get; set; } = new List<SuKien>();

    public virtual ICollection<ThanhToan> ThanhToanNguoiGuiThanhToanNavigations { get; set; } = new List<ThanhToan>();

    public virtual ICollection<ThanhToan> ThanhToanNguoiXacNhanNavigations { get; set; } = new List<ThanhToan>();

    public virtual ICollection<ThietBiThongBao> ThietBiThongBaos { get; set; } = new List<ThietBiThongBao>();

    public virtual ICollection<ThongBaoHeThong> ThongBaoHeThongs { get; set; } = new List<ThongBaoHeThong>();

    public virtual ICollection<ThongBao> ThongBaoMaNguoiNhanNavigations { get; set; } = new List<ThongBao>();

    public virtual ICollection<ThongBao> ThongBaoNguoiTaoNavigations { get; set; } = new List<ThongBao>();

    public virtual ICollection<TraoDoiSuCo> TraoDoiSuCos { get; set; } = new List<TraoDoiSuCo>();
}
