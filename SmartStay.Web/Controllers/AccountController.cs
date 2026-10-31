using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using SmartStay.Web.Models;

namespace SmartStay.Web.Controllers;

public class AccountController : Controller
{
    private readonly ILogger<AccountController> _logger;

    public AccountController(ILogger<AccountController> logger)
    {
        _logger = logger;
    }

    [HttpGet]
    public IActionResult Login(string? returnUrl = null)
    {
        if (User.Identity?.IsAuthenticated == true)
        {
            var currentRole = User.FindFirst(ClaimTypes.Role)?.Value ?? "Admin";
            return RedirectToRoleHome(currentRole);
        }

        var model = new LoginViewModel
        {
            TenDangNhap = "admin",
            MatKhau = "123456",
            VaiTro = "Admin",
            ReturnUrl = returnUrl
        };

        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Login(LoginViewModel model)
    {
        if (!ModelState.IsValid)
        {
            return View(model);
        }

        var cleanUser = (model.TenDangNhap ?? "").Trim().ToLower();
        var cleanPass = (model.MatKhau ?? "").Trim();

        // Danh sách tài khoản mẫu phân quyền
        string role = "Admin";
        string fullName = "Nguyễn Hoàng Nam";
        string email = "admin@smartstay.vn";
        string? roomCode = null;

        if (cleanUser == "admin" || cleanUser == "admin.nam" || model.VaiTro == "Admin")
        {
            role = "Admin";
            fullName = "Nguyễn Hoàng Nam (Admin)";
            email = "nam.nh@smartstay.vn";
        }
        else if (cleanUser == "tech" || cleanUser == "tech.tuan" || model.VaiTro == "KyThuat")
        {
            role = "KyThuat";
            fullName = "Trần Văn Tuấn (Kỹ Thuật)";
            email = "tuan.tv@smartstay.vn";
        }
        else // Cư dân
        {
            role = "CuDan";
            fullName = cleanUser == "2380600133" ? "Hồ Ngọc Bảo" : "Cư Dân SmartStay";
            email = $"{cleanUser}@smartstay.vn";
            roomCode = "P.305";
        }

        // Kiểm tra mật khẩu (hỗ trợ mật khẩu mặc định 123456 hoặc bất kỳ nếu nhập đúng)
        if (cleanPass != "123456" && cleanPass.Length < 4)
        {
            ModelState.AddModelError("", "Mật khẩu không chính xác hoặc quá ngắn!");
            return View(model);
        }

        // Tạo Claims Identity
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, cleanUser),
            new Claim(ClaimTypes.Name, fullName),
            new Claim(ClaimTypes.Role, role),
            new Claim(ClaimTypes.Email, email),
            new Claim("FullName", fullName),
            new Claim("Username", cleanUser),
            new Claim("RoleName", role == "Admin" ? "Quản Trị Viên" : (role == "KyThuat" ? "Kỹ Thuật Viên" : "Cư Dân"))
        };

        if (!string.IsNullOrEmpty(roomCode))
        {
            claims.Add(new Claim("RoomCode", roomCode));
        }

        var claimsIdentity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        var authProperties = new AuthenticationProperties
        {
            IsPersistent = model.GhiNho,
            ExpiresUtc = DateTimeOffset.UtcNow.AddHours(8)
        };

        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(claimsIdentity),
            authProperties);

        _logger.LogInformation("Người dùng {User} đã đăng nhập với vai trò {Role}.", cleanUser, role);

        if (!string.IsNullOrEmpty(model.ReturnUrl) && Url.IsLocalUrl(model.ReturnUrl))
        {
            return Redirect(model.ReturnUrl);
        }

        return RedirectToRoleHome(role);
    }

    [HttpGet]
    public async Task<IActionResult> Logout()
    {
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return RedirectToAction("Login", "Account");
    }

    [HttpGet]
    public IActionResult AccessDenied()
    {
        return View();
    }

    private IActionResult RedirectToRoleHome(string role)
    {
        return role switch
        {
            "KyThuat" => RedirectToAction("Kanban", "SuCo"),
            "CuDan" => RedirectToAction("Index", "CuDan"),
            _ => RedirectToAction("Index", "Home") // Admin
        };
    }
}
