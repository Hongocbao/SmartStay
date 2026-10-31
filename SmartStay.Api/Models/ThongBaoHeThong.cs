using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class ThongBaoHeThong
{
    public long MaThongBao { get; set; }

    public int MaNguoiDung { get; set; }

    public string TieuDe { get; set; } = null!;

    public string? NoiDung { get; set; }

    public string LoaiThongBao { get; set; } = null!;

    public int? MaThamChieu { get; set; }

    public bool DaDoc { get; set; }

    public DateTime ThoiDiemTao { get; set; }

    public virtual NguoiDung MaNguoiDungNavigation { get; set; } = null!;
}
