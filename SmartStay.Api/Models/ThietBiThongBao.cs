using System;
using System.Collections.Generic;

namespace SmartStay.Api.Models;

public partial class ThietBiThongBao
{
    public int MaThietBi { get; set; }

    public int MaNguoiDung { get; set; }

    public string MaXacThuc { get; set; } = null!;

    public string NenTang { get; set; } = null!;

    public DateTime LanSuDungCuoi { get; set; }

    public virtual NguoiDung MaNguoiDungNavigation { get; set; } = null!;
}
