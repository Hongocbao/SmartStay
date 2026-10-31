using System;
using System.Collections.Generic;

namespace SmartStay.Web.Models;

public partial class ThanhToan
{
    public int MaThanhToan { get; set; }

    public int MaHoaDon { get; set; }

    public decimal SoTien { get; set; }

    public string PhuongThucThanhToan { get; set; } = null!;

    public DateTime ThoiDiemThanhToan { get; set; }

    public string? DuongDanBienLai { get; set; }

    public string? MaGiaoDich { get; set; }

    public string TrangThai { get; set; } = null!;

    public int NguoiGuiThanhToan { get; set; }

    public int? NguoiXacNhan { get; set; }

    public DateTime? ThoiDiemXacNhan { get; set; }

    public string? GhiChu { get; set; }

    public virtual HoaDon MaHoaDonNavigation { get; set; } = null!;

    public virtual NguoiDung NguoiGuiThanhToanNavigation { get; set; } = null!;

    public virtual NguoiDung? NguoiXacNhanNavigation { get; set; }
}
