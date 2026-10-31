using System;
using System.Collections.Generic;

namespace SmartStay.Web.Models;

public partial class DangKySuKien
{
    public int MaDangKy { get; set; }

    public int MaSuKien { get; set; }

    public int MaCuDan { get; set; }

    public DateTime ThoiDiemDangKy { get; set; }

    public string TrangThai { get; set; } = null!;

    public bool DaThamDu { get; set; }

    public virtual CuDan MaCuDanNavigation { get; set; } = null!;

    public virtual SuKien MaSuKienNavigation { get; set; } = null!;
}
