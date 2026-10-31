using System;
using System.Collections.Generic;

namespace SmartStay.Web.Models;

public partial class LichSuTruyCapCua
{
    public long MaLichSuTruyCap { get; set; }

    public int MaThietBiIoT { get; set; }

    public int? MaNguoiDung { get; set; }

    public string PhuongThucMo { get; set; } = null!;

    public DateTime ThoiDiemMo { get; set; }

    public bool ThanhCong { get; set; }

    public string? GhiChu { get; set; }

    public virtual NguoiDung? MaNguoiDungNavigation { get; set; }

    public virtual ThietBiIoT MaThietBiIoTNavigation { get; set; } = null!;
}
