using System;
using System.Collections.Generic;

namespace SmartStay.Web.Models;

public partial class HoaDon
{
    public int MaHoaDon { get; set; }

    public string SoHoaDon { get; set; } = null!;

    public int MaHopDong { get; set; }

    public DateOnly KyTinhTien { get; set; }

    public DateOnly? NgayPhatHanh { get; set; }

    public DateOnly? NgayDenHan { get; set; }

    public decimal TongTien { get; set; }

    public string TrangThai { get; set; } = null!;

    public string? NoiDungQr { get; set; }

    public string? DuongDanQr { get; set; }

    public int NguoiTao { get; set; }

    public DateTime ThoiDiemTao { get; set; }

    public DateTime? ThoiDiemCongBo { get; set; }

    public virtual ICollection<ChiTietHoaDon> ChiTietHoaDons { get; set; } = new List<ChiTietHoaDon>();

    public virtual HopDong MaHopDongNavigation { get; set; } = null!;

    public virtual NguoiDung NguoiTaoNavigation { get; set; } = null!;

    public virtual ICollection<ThanhToan> ThanhToans { get; set; } = new List<ThanhToan>();

    public virtual ICollection<WebhookGiaoDichNganHang> WebhookGiaoDichNganHangs { get; set; } = new List<WebhookGiaoDichNganHang>();
}
