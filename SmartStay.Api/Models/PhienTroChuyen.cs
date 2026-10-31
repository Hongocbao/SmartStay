using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class PhienTroChuyen
{
    public int MaPhien { get; set; }

    public int MaNguoiDung { get; set; }

    public string? TieuDe { get; set; }

    public DateTime ThoiDiemTao { get; set; }

    public virtual NguoiDung MaNguoiDungNavigation { get; set; } = null!;

    public virtual ICollection<TinNhanTroChuyen> TinNhanTroChuyens { get; set; } = new List<TinNhanTroChuyen>();
}
