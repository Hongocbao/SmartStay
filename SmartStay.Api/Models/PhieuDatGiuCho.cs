using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class PhieuDatGiuCho
{
    public int MaPhieuDat { get; set; }

    public string SoPhieuDat { get; set; } = null!;

    public int MaPhong { get; set; }

    public int? MaGiuong { get; set; }

    public string HoTenKhach { get; set; } = null!;

    public string SoDienThoai { get; set; } = null!;

    public string? Email { get; set; }

    public string? SoCccd { get; set; }

    public decimal TienCocGiuCho { get; set; }

    public DateTime NgayDat { get; set; }

    public DateTime HanGiuCho { get; set; }

    public DateOnly NgayDuKienNhanPhong { get; set; }

    public string TrangThai { get; set; } = null!;

    public string? GhiChu { get; set; }

    public virtual Giuong? MaGiuongNavigation { get; set; }

    public virtual Phong MaPhongNavigation { get; set; } = null!;
}
