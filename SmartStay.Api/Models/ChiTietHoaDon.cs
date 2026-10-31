using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class ChiTietHoaDon
{
    public long MaChiTiet { get; set; }

    public int MaHoaDon { get; set; }

    public string LoaiKhoanThu { get; set; } = null!;

    public string MoTa { get; set; } = null!;

    public int? MaDichVu { get; set; }

    public int? MaBacGia { get; set; }

    public long? MaChiSo { get; set; }

    public int? MaPhieuSuCo { get; set; }

    public decimal SoLuong { get; set; }

    public decimal DonGia { get; set; }

    public decimal? ThanhTien { get; set; }

    public virtual BacGium? MaBacGiaNavigation { get; set; }

    public virtual ChiSoSuDung? MaChiSoNavigation { get; set; }

    public virtual DichVu? MaDichVuNavigation { get; set; }

    public virtual HoaDon MaHoaDonNavigation { get; set; } = null!;

    public virtual PhieuSuCo? MaPhieuSuCoNavigation { get; set; }
}
