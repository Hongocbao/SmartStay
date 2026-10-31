using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class DanhMucSuCo
{
    public int MaDanhMuc { get; set; }

    public string TenDanhMuc { get; set; } = null!;

    public virtual ICollection<PhieuSuCo> PhieuSuCos { get; set; } = new List<PhieuSuCo>();
}
