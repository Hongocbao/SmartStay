using System;
using System.Collections.Generic;

namespace SmartStay.Web.Models;

public partial class MaDatLaiMatKhau
{
    public int MaToken { get; set; }

    public int MaNguoiDung { get; set; }

    public string MaXacThuc { get; set; } = null!;

    public DateTime HetHanLuc { get; set; }

    public bool DaSuDung { get; set; }

    public virtual NguoiDung MaNguoiDungNavigation { get; set; } = null!;
}
