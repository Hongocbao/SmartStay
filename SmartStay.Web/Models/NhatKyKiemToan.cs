using System;
using System.Collections.Generic;

namespace SmartStay.Web.Models;

public partial class NhatKyKiemToan
{
    public long MaNhatKy { get; set; }

    public int? MaNguoiDung { get; set; }

    public string HanhDong { get; set; } = null!;

    public string TenDoiTuong { get; set; } = null!;

    public string? MaDoiTuong { get; set; }

    public string? GiaTriCu { get; set; }

    public string? GiaTriMoi { get; set; }

    public string? DiaChiIp { get; set; }

    public DateTime ThoiDiemTao { get; set; }

    public virtual NguoiDung? MaNguoiDungNavigation { get; set; }
}
