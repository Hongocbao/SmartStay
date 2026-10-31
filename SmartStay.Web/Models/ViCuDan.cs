using System;
using System.Collections.Generic;

namespace SmartStay.Web.Models;

public partial class ViCuDan
{
    public int MaVi { get; set; }

    public int MaCuDan { get; set; }

    public decimal SoDuKhaDung { get; set; }

    public bool TrangThaiKhoa { get; set; }

    public DateTime CapNhatCuoi { get; set; }

    public virtual ICollection<LichSuGiaoDichVi> LichSuGiaoDichVis { get; set; } = new List<LichSuGiaoDichVi>();

    public virtual CuDan MaCuDanNavigation { get; set; } = null!;
}
