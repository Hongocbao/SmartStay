using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class TinNhanTroChuyen
{
    public long MaTinNhan { get; set; }

    public int MaPhien { get; set; }

    public string NguoiGui { get; set; } = null!;

    public string NoiDung { get; set; } = null!;

    public DateTime ThoiDiemTao { get; set; }

    public virtual PhienTroChuyen MaPhienNavigation { get; set; } = null!;
}
