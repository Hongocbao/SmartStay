using System;
using System.Collections.Generic;

namespace SmartStay.Web.Models;

public partial class HinhAnhSuCo
{
    public int MaHinhAnh { get; set; }

    public int MaPhieuSuCo { get; set; }

    public string DuongDanTep { get; set; } = null!;

    public string LoaiTep { get; set; } = null!;

    public string LoaiHinhAnh { get; set; } = null!;

    public int NguoiTaiLen { get; set; }

    public DateTime ThoiDiemTaiLen { get; set; }

    public virtual PhieuSuCo MaPhieuSuCoNavigation { get; set; } = null!;

    public virtual NguoiDung NguoiTaiLenNavigation { get; set; } = null!;
}
