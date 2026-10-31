using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class LichSuGiaoDichVi
{
    public long MaGiaoDichVi { get; set; }

    public int MaVi { get; set; }

    public string LoaiGiaoDich { get; set; } = null!;

    public decimal SoTien { get; set; }

    public decimal SoDuTruoc { get; set; }

    public decimal SoDuSau { get; set; }

    public int? MaHoaDonLienQuan { get; set; }

    public string NoiDung { get; set; } = null!;

    public DateTime ThoiGian { get; set; }

    public virtual ViCuDan MaViNavigation { get; set; } = null!;
}
