using System;
using System.Collections.Generic;

namespace SmartStay.Web.Models;

public partial class ToaNha
{
    public int MaToaNha { get; set; }

    public string TenToaNha { get; set; } = null!;

    public string? DiaChi { get; set; }

    public int TongSoTang { get; set; }

    public string? MoTa { get; set; }

    public bool DangHoatDong { get; set; }

    public virtual ICollection<Phong> Phongs { get; set; } = new List<Phong>();

    public virtual ICollection<SoQuyThuChi> SoQuyThuChis { get; set; } = new List<SoQuyThuChi>();

    public virtual ICollection<ThietBiIoT> ThietBiIoTs { get; set; } = new List<ThietBiIoT>();

    public virtual ICollection<ThongBao> ThongBaos { get; set; } = new List<ThongBao>();

    public virtual ICollection<VatTuLinhKien> VatTuLinhKiens { get; set; } = new List<VatTuLinhKien>();
}
