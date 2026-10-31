using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class CuDanHopDong
{
    public int MaHopDong { get; set; }

    public int MaCuDan { get; set; }

    public bool LaDaiDien { get; set; }

    public DateOnly? NgayChuyenVao { get; set; }

    public DateOnly? NgayChuyenRa { get; set; }

    public virtual CuDan MaCuDanNavigation { get; set; } = null!;

    public virtual HopDong MaHopDongNavigation { get; set; } = null!;
}
