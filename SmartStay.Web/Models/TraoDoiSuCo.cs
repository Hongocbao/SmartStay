using System;
using System.Collections.Generic;

namespace SmartStay.Web.Models;

public partial class TraoDoiSuCo
{
    public int MaTraoDoi { get; set; }

    public int MaPhieuSuCo { get; set; }

    public int MaNguoiDung { get; set; }

    public string NoiDung { get; set; } = null!;

    public bool LaNoiBo { get; set; }

    public DateTime ThoiDiemTao { get; set; }

    public virtual NguoiDung MaNguoiDungNavigation { get; set; } = null!;

    public virtual PhieuSuCo MaPhieuSuCoNavigation { get; set; } = null!;
}
