namespace SmartStay.Api.Dtos;

public class LoginRequestDto
{
    public string TenDangNhap { get; set; } = string.Empty;
    public string MatKhau { get; set; } = string.Empty;
}

public class RegisterRequestDto
{
    public string TenDangNhap { get; set; } = string.Empty;
    public string MatKhau { get; set; } = string.Empty;
    public string HoTen { get; set; } = string.Empty;
    public string SoDienThoai { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? SoPhong { get; set; }
}

public class LoginResponseDto
{
    public string Token { get; set; } = string.Empty;
    public int MaNguoiDung { get; set; }
    public string TenDangNhap { get; set; } = string.Empty;
    public string HoTen { get; set; } = string.Empty;
    public string VaiTro { get; set; } = string.Empty;
    public string? SoPhong { get; set; }
}

public class TinhBacThangRequestDto
{
    public int MaPhong { get; set; }
    public decimal ChiSoDienDau { get; set; }
    public decimal ChiSoDienCuoi { get; set; }
    public decimal ChiSoNuocDau { get; set; }
    public decimal ChiSoNuocCuoi { get; set; }
}

public class ChiTietBacThangItemDto
{
    public string TenDichVu { get; set; } = string.Empty;
    public int ThuTuBac { get; set; }
    public string MoTaBac { get; set; } = string.Empty;
    public decimal SoLuong { get; set; }
    public decimal DonGia { get; set; }
    public decimal ThanhTien { get; set; }
}

public class KetQuaTinhBacThangDto
{
    public decimal SanLuongDien { get; set; }
    public decimal TienDien { get; set; }
    public decimal SanLuongNuoc { get; set; }
    public decimal TienNuoc { get; set; }
    public decimal TienPhong { get; set; }
    public decimal TienDichVu { get; set; }
    public decimal TongTien { get; set; }
    public string UrlVietQr { get; set; } = string.Empty;
    public List<ChiTietBacThangItemDto> ChiTietBacThang { get; set; } = new();
}

public class TaoPhieuSuCoDto
{
    public int MaPhong { get; set; }
    public int MaDanhMuc { get; set; }
    public string TieuDe { get; set; } = string.Empty;
    public string MoTa { get; set; } = string.Empty;
    public string MucDoUuTien { get; set; } = "Trung bình";
    public string? DuongDanAnh { get; set; }
}

public class DoiTrangThaiSuCoDto
{
    public string TrangThaiMoi { get; set; } = string.Empty;
    public int? MaNhanVienKyThuat { get; set; }
    public decimal ChiPhiVatTu { get; set; } = 0;
    public string? GhiChu { get; set; }
}

public class GuiTraoDoiDto
{
    public string NoiDung { get; set; } = string.Empty;
}

public class DanhGiaSuCoDto
{
    public int SoSao { get; set; }
    public string? NhanXet { get; set; }
}

public class XacNhanThanhToanDto
{
    public decimal SoTien { get; set; }
    public string DuongDanBienLai { get; set; } = string.Empty;
    public string? GhiChu { get; set; }
}

public class TroLyChatRequestDto
{
    public string TinNhan { get; set; } = string.Empty;
    public int? MaPhong { get; set; }
}
