using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class WebhookGiaoDichNganHang
{
    public long MaGiaoDichNganHang { get; set; }

    public string MaThamChieuNganHang { get; set; } = null!;

    public decimal SoTien { get; set; }

    public string NoiDungChuyenKhoan { get; set; } = null!;

    public DateTime ThoiGianGiaoDich { get; set; }

    public string SoTaiKhoanNhan { get; set; } = null!;

    public int? MaHoaDonKhop { get; set; }

    public string TrangThaiKhop { get; set; } = null!;

    public DateTime ThoiDiemNhanWebhook { get; set; }

    public virtual HoaDon? MaHoaDonKhopNavigation { get; set; }
}
