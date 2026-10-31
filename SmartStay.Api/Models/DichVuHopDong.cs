using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class DichVuHopDong
{
    public int MaDichVuHopDong { get; set; }

    public int MaHopDong { get; set; }

    public int MaDichVu { get; set; }

    public int SoLuong { get; set; }

    public DateOnly NgayBatDau { get; set; }

    public DateOnly? NgayKetThuc { get; set; }

    public virtual DichVu MaDichVuNavigation { get; set; } = null!;

    public virtual HopDong MaHopDongNavigation { get; set; } = null!;
}
