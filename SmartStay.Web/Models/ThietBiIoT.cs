using System;
using System.Collections.Generic;

namespace SmartStay.Web.Models;

public partial class ThietBiIoT
{
    public int MaThietBiIoT { get; set; }

    public int? MaPhong { get; set; }

    public int MaToaNha { get; set; }

    public string TenThietBi { get; set; } = null!;

    public string LoaiThietBi { get; set; } = null!;

    public string MaSeri { get; set; } = null!;

    public string? DiaChiMac { get; set; }

    public string? MatKhauTruyCap { get; set; }

    public string TrangThaiHoatDong { get; set; } = null!;

    public int? MucPin { get; set; }

    public DateTime? LanDongBoCuoi { get; set; }

    public virtual ICollection<LichSuTruyCapCua> LichSuTruyCapCuas { get; set; } = new List<LichSuTruyCapCua>();

    public virtual Phong? MaPhongNavigation { get; set; }

    public virtual ToaNha MaToaNhaNavigation { get; set; } = null!;
}
