using System;
using System.Collections.Generic;

namespace SmartStay.Web.Models;

public partial class LichSuSuCo
{
    public long MaLichSu { get; set; }

    public int MaPhieuSuCo { get; set; }

    public string? TrangThaiCu { get; set; }

    public string TrangThaiMoi { get; set; } = null!;

    public int NguoiThayDoi { get; set; }

    public DateTime ThoiDiemThayDoi { get; set; }

    public string? GhiChu { get; set; }

    public virtual PhieuSuCo MaPhieuSuCoNavigation { get; set; } = null!;

    public virtual NguoiDung NguoiThayDoiNavigation { get; set; } = null!;
}
