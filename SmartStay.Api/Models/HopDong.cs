using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class HopDong
{
    public int MaHopDong { get; set; }

    public string SoHopDong { get; set; } = null!;

    public int MaPhong { get; set; }

    public DateOnly NgayBatDau { get; set; }

    public DateOnly NgayKetThuc { get; set; }

    public decimal TienThueHangThang { get; set; }

    public decimal TienDatCoc { get; set; }

    public string? DieuKhoan { get; set; }

    public string TrangThai { get; set; } = null!;

    public DateOnly? NgayChamDut { get; set; }

    public string? LyDoChamDut { get; set; }

    public int NguoiTao { get; set; }

    public DateTime ThoiDiemTao { get; set; }

    public virtual ICollection<BienBanBanGiao> BienBanBanGiaos { get; set; } = new List<BienBanBanGiao>();

    public virtual CuDanHopDong? CuDanHopDong { get; set; }

    public virtual ICollection<DichVuHopDong> DichVuHopDongs { get; set; } = new List<DichVuHopDong>();

    public virtual ICollection<HoaDon> HoaDons { get; set; } = new List<HoaDon>();

    public virtual Phong MaPhongNavigation { get; set; } = null!;

    public virtual NguoiDung NguoiTaoNavigation { get; set; } = null!;
}
