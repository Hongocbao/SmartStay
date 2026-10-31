using System;
using System.Collections.Generic;

namespace SmartStay.Web.Models;

public partial class CauHinhToChuc
{
    public int MaToChuc { get; set; }

    public string TenToChuc { get; set; } = null!;

    public string? DiaChi { get; set; }

    public string? SoDienThoai { get; set; }

    public string? ThuDienTu { get; set; }

    public string? DuongDanLogo { get; set; }

    public string? MaNganHang { get; set; }

    public string? SoTaiKhoanNganHang { get; set; }

    public string? TenChuTaiKhoan { get; set; }

    public int SoNgayHanThanhToan { get; set; }

    public string? MauHopDong { get; set; }

    public string? MauHoaDon { get; set; }
}
