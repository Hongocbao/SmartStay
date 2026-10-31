using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class DichVu
{
    public int MaDichVu { get; set; }

    public string TenDichVu { get; set; } = null!;

    public string DonVi { get; set; } = null!;

    public string LoaiDichVu { get; set; } = null!;

    public bool DangHoatDong { get; set; }

    public virtual ICollection<BacGium> BacGia { get; set; } = new List<BacGium>();

    public virtual ICollection<ChiSoSuDung> ChiSoSuDungs { get; set; } = new List<ChiSoSuDung>();

    public virtual ICollection<ChiTietHoaDon> ChiTietHoaDons { get; set; } = new List<ChiTietHoaDon>();

    public virtual ICollection<DichVuHopDong> DichVuHopDongs { get; set; } = new List<DichVuHopDong>();
}
