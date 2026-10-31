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
