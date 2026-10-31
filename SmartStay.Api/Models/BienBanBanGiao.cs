using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class BienBanBanGiao
{
    public int MaBienBanBanGiao { get; set; }

    public int MaHopDong { get; set; }

    public string LoaiBanGiao { get; set; } = null!;

    public DateTime ThoiDiemBanGiao { get; set; }

    public decimal? ChiSoDien { get; set; }

    public decimal? ChiSoNuoc { get; set; }

    public decimal? TienCocDaNhan { get; set; }

    public decimal? TienKhauTruHuHong { get; set; }

    public decimal? TienKhauTruCongNo { get; set; }

    public decimal? TienHoanLai { get; set; }

    public string? GhiChu { get; set; }

    public int NguoiTao { get; set; }

    public virtual HopDong MaHopDongNavigation { get; set; } = null!;

    public virtual NguoiDung NguoiTaoNavigation { get; set; } = null!;

    public virtual ICollection<TaiSanBanGiao> TaiSanBanGiaos { get; set; } = new List<TaiSanBanGiao>();
}
