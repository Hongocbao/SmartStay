using System;
using System.Collections.Generic;

namespace SmartStay.Web.Models;

public partial class ChiSoSuDung
{
    public long MaChiSo { get; set; }

    public int MaPhong { get; set; }

    public int MaDichVu { get; set; }

    public DateOnly KyTinhTien { get; set; }

    public string LoaiGhiChiSo { get; set; } = null!;

    public decimal ChiSoTruoc { get; set; }

    public decimal ChiSoHienTai { get; set; }

    public DateOnly NgayGhiChiSo { get; set; }

    public bool BatThuong { get; set; }

    public string? GhiChu { get; set; }

    public int NguoiGhiNhan { get; set; }

    public decimal? MucTieuThu { get; set; }

    public virtual ICollection<ChiTietHoaDon> ChiTietHoaDons { get; set; } = new List<ChiTietHoaDon>();

    public virtual DichVu MaDichVuNavigation { get; set; } = null!;

    public virtual Phong MaPhongNavigation { get; set; } = null!;

    public virtual NguoiDung NguoiGhiNhanNavigation { get; set; } = null!;
}
