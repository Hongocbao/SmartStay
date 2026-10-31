using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class LoaiPhong
{
    public int MaLoaiPhong { get; set; }

    public string TenLoaiPhong { get; set; } = null!;

    public string? MoTa { get; set; }

    public decimal GiaCoBan { get; set; }

    public int SucChua { get; set; }

    public virtual ICollection<Phong> Phongs { get; set; } = new List<Phong>();
}
