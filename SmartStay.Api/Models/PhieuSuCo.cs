using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class PhieuSuCo
{
    public int MaPhieuSuCo { get; set; }

    public string SoPhieuSuCo { get; set; } = null!;

    public int MaPhong { get; set; }

    public int MaCuDan { get; set; }

    public int MaDanhMuc { get; set; }

    public string TieuDe { get; set; } = null!;

    public string? MoTa { get; set; }

    public string UuTien { get; set; } = null!;

    public string TrangThai { get; set; } = null!;

    public int? NguoiDuocGiao { get; set; }

    public DateTime? HanXuLy { get; set; }

    public DateTime ThoiDiemTao { get; set; }

    public DateTime? ThoiDiemGiao { get; set; }

    public DateTime? ThoiDiemBatDau { get; set; }

    public DateTime? ThoiDiemHoanThanh { get; set; }

    public decimal? ChiPhiVatTu { get; set; }

    public string? GhiChuXuLy { get; set; }

    public string? LyDoTuChoi { get; set; }

    public byte? DanhGia { get; set; }

    public string? NhanXetDanhGia { get; set; }

    public DateTime? ThoiDiemDanhGia { get; set; }

    public virtual ICollection<ChiTietHoaDon> ChiTietHoaDons { get; set; } = new List<ChiTietHoaDon>();

    public virtual ICollection<HinhAnhSuCo> HinhAnhSuCos { get; set; } = new List<HinhAnhSuCo>();

    public virtual ICollection<LichSuSuCo> LichSuSuCos { get; set; } = new List<LichSuSuCo>();

    public virtual CuDan MaCuDanNavigation { get; set; } = null!;

    public virtual DanhMucSuCo MaDanhMucNavigation { get; set; } = null!;

    public virtual Phong MaPhongNavigation { get; set; } = null!;

    public virtual NguoiDung? NguoiDuocGiaoNavigation { get; set; }

    public virtual ICollection<PhieuXuatVatTuSuCo> PhieuXuatVatTuSuCos { get; set; } = new List<PhieuXuatVatTuSuCo>();

    public virtual ICollection<TraoDoiSuCo> TraoDoiSuCos { get; set; } = new List<TraoDoiSuCo>();
}
