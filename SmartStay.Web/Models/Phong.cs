using System;
using System.Collections.Generic;

namespace SmartStay.Web.Models;

public partial class Phong
{
    public int MaPhong { get; set; }

    public int MaToaNha { get; set; }

    public int MaLoaiPhong { get; set; }

    public string KyHieuPhong { get; set; } = null!;

    public int SoTang { get; set; }

    public decimal? DienTich { get; set; }

    public int SucChua { get; set; }

    public decimal GiaThue { get; set; }

    public string TrangThai { get; set; } = null!;

    public string? MoTa { get; set; }

    public virtual ICollection<ChiSoSuDung> ChiSoSuDungs { get; set; } = new List<ChiSoSuDung>();

    public virtual ICollection<Giuong> Giuongs { get; set; } = new List<Giuong>();

    public virtual HopDong? HopDong { get; set; }

    public virtual LoaiPhong MaLoaiPhongNavigation { get; set; } = null!;

    public virtual ToaNha MaToaNhaNavigation { get; set; } = null!;

    public virtual ICollection<PhieuDatGiuCho> PhieuDatGiuChos { get; set; } = new List<PhieuDatGiuCho>();

    public virtual ICollection<PhieuSuCo> PhieuSuCos { get; set; } = new List<PhieuSuCo>();

    public virtual ICollection<TaiSanPhong> TaiSanPhongs { get; set; } = new List<TaiSanPhong>();

    public virtual ICollection<ThietBiIoT> ThietBiIoTs { get; set; } = new List<ThietBiIoT>();
}
