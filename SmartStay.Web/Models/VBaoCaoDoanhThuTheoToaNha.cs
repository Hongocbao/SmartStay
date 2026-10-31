using System;
using System.Collections.Generic;

namespace SmartStay.Web.Models;

public partial class VBaoCaoDoanhThuTheoToaNha
{
    public int MaToaNha { get; set; }

    public string TenToaNha { get; set; } = null!;

    public DateOnly KyTinhTien { get; set; }

    public int? TongSoHoaDon { get; set; }

    public decimal? TongTienPhatHanh { get; set; }

    public decimal? DoanhThuDaThu { get; set; }

    public decimal? CongNoConLai { get; set; }

    public decimal? TyLeThuHoi { get; set; }
}
