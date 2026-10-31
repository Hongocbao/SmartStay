using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class PhieuXuatVatTuSuCo
{
    public long MaXuatVatTu { get; set; }

    public int MaPhieuSuCo { get; set; }

    public int MaVatTu { get; set; }

    public int SoLuongXuat { get; set; }

    public decimal DonGia { get; set; }

    public decimal? ThanhTien { get; set; }

    public DateTime ThoiDiemXuat { get; set; }

    public virtual PhieuSuCo MaPhieuSuCoNavigation { get; set; } = null!;

    public virtual VatTuLinhKien MaVatTuNavigation { get; set; } = null!;
}
