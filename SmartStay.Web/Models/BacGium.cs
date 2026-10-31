using System;
using System.Collections.Generic;

namespace SmartStay.Web.Models;

public partial class BacGium
{
    public int MaBacGia { get; set; }

    public int MaDichVu { get; set; }

    public int ThuTuBac { get; set; }

    public decimal SoLuongTu { get; set; }

    public decimal? SoLuongDen { get; set; }

    public decimal DonGia { get; set; }

    public DateOnly HieuLucTu { get; set; }

    public DateOnly? HieuLucDen { get; set; }

    public virtual ICollection<ChiTietHoaDon> ChiTietHoaDons { get; set; } = new List<ChiTietHoaDon>();

    public virtual DichVu MaDichVuNavigation { get; set; } = null!;
}
