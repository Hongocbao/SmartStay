using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class Giuong
{
    public int MaGiuong { get; set; }

    public int MaPhong { get; set; }

    public string KyHieuGiuong { get; set; } = null!;

    public decimal GiaThueThang { get; set; }

    public string TrangThai { get; set; } = null!;

    public string? GhiChu { get; set; }

    public virtual Phong MaPhongNavigation { get; set; } = null!;

    public virtual ICollection<PhieuDatGiuCho> PhieuDatGiuChos { get; set; } = new List<PhieuDatGiuCho>();
}
