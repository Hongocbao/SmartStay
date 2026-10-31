using System;
using System.Collections.Generic;

namespace SmartStay.Web.Models;

public partial class TaiSanBanGiao
{
    public int MaTaiSanBanGiao { get; set; }

    public int MaBienBanBanGiao { get; set; }

    public int MaTaiSan { get; set; }

    public int SoLuong { get; set; }

    public string TinhTrang { get; set; } = null!;

    public string? HinhAnhDuongDan { get; set; }

    public decimal PhiHuHong { get; set; }

    public string? GhiChu { get; set; }

    public virtual BienBanBanGiao MaBienBanBanGiaoNavigation { get; set; } = null!;

    public virtual TaiSanPhong MaTaiSanNavigation { get; set; } = null!;
}
