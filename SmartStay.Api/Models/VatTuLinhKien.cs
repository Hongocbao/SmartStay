using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class VatTuLinhKien
{
    public int MaVatTu { get; set; }

    public int MaToaNha { get; set; }

    public string TenVatTu { get; set; } = null!;

    public string DonViTinh { get; set; } = null!;

    public int SoLuongTon { get; set; }

    public decimal DonGiaNhap { get; set; }

    public decimal GiaXuatSuaChua { get; set; }

    public int DinhMucToiThieu { get; set; }

    public virtual ToaNha MaToaNhaNavigation { get; set; } = null!;

    public virtual ICollection<PhieuXuatVatTuSuCo> PhieuXuatVatTuSuCos { get; set; } = new List<PhieuXuatVatTuSuCo>();
}
