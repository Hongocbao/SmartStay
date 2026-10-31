using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class VSoDoPhongRealTime
{
    public int MaPhong { get; set; }

    public string KyHieuPhong { get; set; } = null!;

    public int SoTang { get; set; }

    public decimal? DienTich { get; set; }

    public int SucChua { get; set; }

    public decimal GiaThue { get; set; }

    public string TrangThaiPhong { get; set; } = null!;

    public int MaToaNha { get; set; }

    public string TenToaNha { get; set; } = null!;

    public string TenLoaiPhong { get; set; } = null!;

    public int? MaHopDong { get; set; }

    public string? SoHopDong { get; set; }

    public string? TenCuDanDaiDien { get; set; }

    public string? SdtCuDan { get; set; }

    public decimal CongNoChuaThu { get; set; }

    public int SoSuCoChuaXong { get; set; }
}
