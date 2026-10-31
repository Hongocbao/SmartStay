using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class TaiSanPhong
{
    public int MaTaiSan { get; set; }

    public int MaPhong { get; set; }

    public string TenTaiSan { get; set; } = null!;

    public int SoLuong { get; set; }

    public string TinhTrang { get; set; } = null!;

    public string? HinhAnhDuongDan { get; set; }

    public string? GhiChu { get; set; }

    public virtual Phong MaPhongNavigation { get; set; } = null!;

    public virtual ICollection<TaiSanBanGiao> TaiSanBanGiaos { get; set; } = new List<TaiSanBanGiao>();
}
