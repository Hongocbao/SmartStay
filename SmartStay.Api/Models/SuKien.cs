using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class SuKien
{
    public int MaSuKien { get; set; }

    public string TieuDe { get; set; } = null!;

    public string? MoTa { get; set; }

    public string? HinhAnhDuongDan { get; set; }

    public string DiaDiem { get; set; } = null!;

    public DateTime ThoiGianBatDau { get; set; }

    public DateTime ThoiGianKetThuc { get; set; }

    public DateTime HanDangKy { get; set; }

    public int? SoNguoiThamGiaToiDa { get; set; }

    public string TrangThai { get; set; } = null!;

    public int NguoiTao { get; set; }

    public DateTime ThoiDiemTao { get; set; }

    public virtual ICollection<DangKySuKien> DangKySuKiens { get; set; } = new List<DangKySuKien>();

    public virtual NguoiDung NguoiTaoNavigation { get; set; } = null!;
}
