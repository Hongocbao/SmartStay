using System;
using System.Collections.Generic;

namespace SmartStay.Web.Models;

public partial class TriThucAiRag
{
    public int MaTriThuc { get; set; }

    public string ChuDe { get; set; } = null!;

    public string CauHoiPhoBien { get; set; } = null!;

    public string NoiDungGiaiDap { get; set; } = null!;

    public int DoUuTien { get; set; }

    public bool DangHoatDong { get; set; }

    public DateTime NgayCapNhat { get; set; }

    public int? MaToaNha { get; set; }

    public int? NguoiCapNhat { get; set; }

    public virtual ToaNha? MaToaNhaNavigation { get; set; }

    public virtual NguoiDung? NguoiCapNhatNavigation { get; set; }
}
