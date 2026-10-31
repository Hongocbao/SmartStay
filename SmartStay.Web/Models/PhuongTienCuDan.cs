using System;
using System.Collections.Generic;

namespace SmartStay.Web.Models;

public partial class PhuongTienCuDan
{
    public int MaPhuongTien { get; set; }

    public int MaCuDan { get; set; }

    public string LoaiXe { get; set; } = null!;

    public string BienSoXe { get; set; } = null!;

    public string? NhanHieu { get; set; }

    public string? MauXe { get; set; }

    public string? MaTheXeRfid { get; set; }

    public decimal PhiGuiXeHangThang { get; set; }

    public string? DuongDanAnhDangKyXe { get; set; }

    public bool DangHoatDong { get; set; }

    public DateOnly NgayDangKy { get; set; }

    public virtual CuDan MaCuDanNavigation { get; set; } = null!;
}
