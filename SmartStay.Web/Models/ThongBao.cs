using System;
using System.Collections.Generic;

namespace SmartStay.Web.Models;

public partial class ThongBao
{
    public int MaThongBao { get; set; }

    public string TieuDe { get; set; } = null!;

    public string NoiDung { get; set; } = null!;

    public string? HinhAnhDuongDan { get; set; }

    public string PhamViNhan { get; set; } = null!;

    public int? MaToaNha { get; set; }

    public int? SoTang { get; set; }

    public int? MaNguoiNhan { get; set; }

    public DateTime? LichGui { get; set; }

    public DateTime? ThoiDiemCongBo { get; set; }

    public string TrangThai { get; set; } = null!;

    public int NguoiTao { get; set; }

    public DateTime ThoiDiemTao { get; set; }

    public virtual NguoiDung? MaNguoiNhanNavigation { get; set; }

    public virtual ToaNha? MaToaNhaNavigation { get; set; }

    public virtual NguoiDung NguoiTaoNavigation { get; set; } = null!;
}
