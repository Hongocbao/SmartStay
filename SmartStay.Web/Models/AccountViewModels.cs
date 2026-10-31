using System.ComponentModel.DataAnnotations;

namespace SmartStay.Web.Models;

public class LoginViewModel
{
    [Required(ErrorMessage = "Vui lòng nhập tên đăng nhập hoặc số điện thoại")]
    [Display(Name = "Tên đăng nhập")]
    public string TenDangNhap { get; set; } = string.Empty;

    [Required(ErrorMessage = "Vui lòng nhập mật khẩu")]
    [DataType(DataType.Password)]
    [Display(Name = "Mật khẩu")]
    public string MatKhau { get; set; } = string.Empty;

    public string VaiTro { get; set; } = "Admin"; // "Admin", "KyThuat", "CuDan"

    public bool GhiNho { get; set; } = true;

    public string? ReturnUrl { get; set; }
}

public class CuDanLoginViewModel
{
    [Required(ErrorMessage = "Vui lòng nhập số điện thoại hoặc CCCD hoặc tên đăng nhập")]
    [Display(Name = "Tài khoản cư dân")]
    public string TenDangNhap { get; set; } = string.Empty;

    [Required(ErrorMessage = "Vui lòng nhập mật khẩu")]
    [DataType(DataType.Password)]
    [Display(Name = "Mật khẩu")]
    public string MatKhau { get; set; } = string.Empty;

    public bool GhiNho { get; set; } = true;

    public string? ReturnUrl { get; set; }
}

public class CuDanRegisterViewModel
{
    [Required(ErrorMessage = "Vui lòng nhập họ và tên cư dân")]
    [Display(Name = "Họ và tên")]
    [StringLength(100, MinimumLength = 3, ErrorMessage = "Họ tên từ 3 đến 100 ký tự")]
    public string HoTen { get; set; } = string.Empty;

    [Required(ErrorMessage = "Vui lòng nhập số điện thoại liên lạc")]
    [Display(Name = "Số điện thoại")]
    [RegularExpression(@"^0\d{9,10}$", ErrorMessage = "Số điện thoại không hợp lệ (gồm 10 số, bắt đầu bằng số 0)")]
    public string SoDienThoai { get; set; } = string.Empty;

    [Required(ErrorMessage = "Vui lòng nhập email nhận hóa đơn")]
    [EmailAddress(ErrorMessage = "Địa chỉ email không hợp lệ")]
    [Display(Name = "Email")]
    public string ThuDienTu { get; set; } = string.Empty;

    [Required(ErrorMessage = "Vui lòng nhập số CCCD / CMND")]
    [Display(Name = "Số CCCD/CMND")]
    [StringLength(20, MinimumLength = 9, ErrorMessage = "Số CCCD từ 9 đến 12 số")]
    public string SoCanCuoc { get; set; } = string.Empty;

    [Required(ErrorMessage = "Vui lòng chọn hoặc nhập số phòng")]
    [Display(Name = "Căn hộ / Số phòng")]
    public string SoPhong { get; set; } = "P.305";

    [Display(Name = "Tòa nhà")]
    public string ToaNha { get; set; } = "Tòa A - Sapphire";

    [Display(Name = "Ngày sinh")]
    [DataType(DataType.Date)]
    public DateTime? NgaySinh { get; set; }

    [Display(Name = "Giới tính")]
    public string GioiTinh { get; set; } = "Nam";

    [Required(ErrorMessage = "Vui lòng tạo mật khẩu cho tài khoản")]
    [DataType(DataType.Password)]
    [StringLength(50, MinimumLength = 6, ErrorMessage = "Mật khẩu phải có ít nhất 6 ký tự")]
    [Display(Name = "Mật khẩu")]
    public string MatKhau { get; set; } = string.Empty;

    [Required(ErrorMessage = "Vui lòng nhập lại mật khẩu")]
    [DataType(DataType.Password)]
    [Compare("MatKhau", ErrorMessage = "Mật khẩu xác nhận không khớp")]
    [Display(Name = "Xác nhận mật khẩu")]
    public string XacNhanMatKhau { get; set; } = string.Empty;

    [Range(typeof(bool), "true", "true", ErrorMessage = "Bạn phải đồng ý với Nội quy chung cư & Điều khoản cư dân")]
    [Display(Name = "Đồng ý điều khoản")]
    public bool DongYDieuKhoan { get; set; } = true;
}
