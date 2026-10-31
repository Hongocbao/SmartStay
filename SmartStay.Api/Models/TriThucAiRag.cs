using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class TriThucAiRag
{
    public int MaTriThuc { get; set; }

    public string ChuDe { get; set; } = null!;

    public string CauHoiPhoBien { get; set; } = null!;

    public string NoiDungGiaiDap { get; set; } = null!;

    public int DoUuTien { get; set; }

    public bool DangHoatDong { get; set; }

    public DateTime NgayCapNhat { get; set; }
}
