using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class SoQuyThuChi
{
    public long MaPhieuThuChi { get; set; }

    public string SoChungTu { get; set; } = null!;

    public int MaToaNha { get; set; }

    public string LoaiPhieu { get; set; } = null!;

    public string HangMuc { get; set; } = null!;

    public decimal SoTien { get; set; }

    public string HinhThuc { get; set; } = null!;

    public string NguoiNopNhan { get; set; } = null!;

    public string NoiDung { get; set; } = null!;

    public DateOnly NgayChungTu { get; set; }

    public int NguoiLapPhieu { get; set; }

    public DateTime ThoiDiemTao { get; set; }

    public virtual ToaNha MaToaNhaNavigation { get; set; } = null!;

    public virtual NguoiDung NguoiLapPhieuNavigation { get; set; } = null!;
}
