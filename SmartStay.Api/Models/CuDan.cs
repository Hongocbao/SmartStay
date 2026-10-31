using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class CuDan
{
    public int MaCuDan { get; set; }

    public int MaNguoiDung { get; set; }

    public DateOnly? NgaySinh { get; set; }

    public string? GioiTinh { get; set; }

    public string SoCanCuoc { get; set; } = null!;

    public string? DiaChiThuongTru { get; set; }

    public string? TenNguoiLienHeKhanCap { get; set; }

    public string? SoDienThoaiKhanCap { get; set; }

    public virtual ICollection<CuDanHopDong> CuDanHopDongs { get; set; } = new List<CuDanHopDong>();

    public virtual ICollection<DangKySuKien> DangKySuKiens { get; set; } = new List<DangKySuKien>();

    public virtual NguoiDung MaNguoiDungNavigation { get; set; } = null!;

    public virtual ICollection<PhieuSuCo> PhieuSuCos { get; set; } = new List<PhieuSuCo>();

    public virtual ICollection<PhuongTienCuDan> PhuongTienCuDans { get; set; } = new List<PhuongTienCuDan>();

    public virtual ViCuDan? ViCuDan { get; set; }
}
