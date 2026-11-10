using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartStay.Web.Data;
using SmartStay.Web.Models;

namespace SmartStay.Web.Controllers;

public class AccountController : Controller
{
    private readonly SmartStayDbContext _db;
    private readonly ILogger<AccountController> _logger;

    public AccountController(SmartStayDbContext db, ILogger<AccountController> logger)
    {
        _db = db;
        _logger = logger;
    }

    #region 1. ĐĂNG NHẬP CHUNG / QUẢN TRỊ VIÊN
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

        var cleanUser = model.TenDangNhap.Trim();
        var cleanPass = model.MatKhau;
        var dbUser = await _db.NguoiDungs
            .Include(u => u.MaVaiTroNavigation)
            .FirstOrDefaultAsync(u => u.DangHoatDong &&
                (u.TenDangNhap == cleanUser || u.SoDienThoai == cleanUser || u.ThuDienTu == cleanUser));

        var passwordMatches = false;
        if (dbUser != null)
        {
            try { passwordMatches = BCrypt.Net.BCrypt.Verify(cleanPass, dbUser.MaBamMatKhau); }
            catch (BCrypt.Net.SaltParseException) { passwordMatches = false; }
        }

        var role = dbUser?.MaVaiTroNavigation?.TenVaiTro ?? string.Empty;
        var requestedRole = model.VaiTro switch
        {
            "CuDan" => "CuDan",
            _ => "Admin"
        };
        var roleMatches = requestedRole == "Admin"
            ? role is "Admin" or "QuanLy" or "KyThuat"
            : role == requestedRole;
        if (!passwordMatches || dbUser == null || !roleMatches)
        {
            ModelState.AddModelError("", "Tài khoản, mật khẩu hoặc nhóm quyền không chính xác.");
            return View(model);
        }

        var roomCode = role == "CuDan"
            ? await (from cdhd in _db.CuDanHopDongs
                     join hd in _db.HopDongs on cdhd.MaHopDong equals hd.MaHopDong
                     join p in _db.Phongs on hd.MaPhong equals p.MaPhong
                     where cdhd.MaCuDanNavigation.MaNguoiDung == dbUser.MaNguoiDung && cdhd.NgayChuyenRa == null
                     select p.KyHieuPhong).FirstOrDefaultAsync()
            : null;

        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, dbUser.MaNguoiDung.ToString()),
            new Claim(ClaimTypes.Name, dbUser.TenDangNhap),
            new Claim(ClaimTypes.Role, role),
            new Claim(ClaimTypes.Email, dbUser.ThuDienTu ?? string.Empty),
            new Claim("FullName", dbUser.HoTen),
            new Claim("Username", dbUser.TenDangNhap),
            new Claim("RoleName", role)
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

        _logger.LogInformation("Người dùng {User} đã đăng nhập với vai trò {Role}.", dbUser.TenDangNhap, role);

        if (!string.IsNullOrEmpty(model.ReturnUrl) && Url.IsLocalUrl(model.ReturnUrl))
        {
            return Redirect(model.ReturnUrl);
        }

        return RedirectToRoleHome(role);
    }
    #endregion

    #region 2. CỔNG ĐĂNG NHẬP RIÊNG CHO CƯ DÂN
    [HttpGet]
    public IActionResult CuDanLogin(string? returnUrl = null)
    {
        if (User.Identity?.IsAuthenticated == true)
        {
            var currentRole = User.FindFirst(ClaimTypes.Role)?.Value;
            if (currentRole == "CuDan")
            {
                return RedirectToAction("Index", "CuDan");
            }
        }

        var model = new CuDanLoginViewModel
        {
            TenDangNhap = "2380600133",
            MatKhau = "123456",
            ReturnUrl = returnUrl
        };

        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CuDanLogin(CuDanLoginViewModel model)
    {
        if (!ModelState.IsValid)
        {
            return View(model);
        }

        var cleanUser = (model.TenDangNhap ?? "").Trim();
        var cleanPass = (model.MatKhau ?? "").Trim();

        var fullName = string.Empty;
        var email = string.Empty;
        var roomCode = string.Empty;
        var isAuthenticated = false;

        try
        {
            var dbUser = await _db.NguoiDungs
                .Include(u => u.CuDan)
                .Include(u => u.MaVaiTroNavigation)
                .FirstOrDefaultAsync(u => u.TenDangNhap == cleanUser || u.SoDienThoai == cleanUser || (u.CuDan != null && u.CuDan.SoCanCuoc == cleanUser));

            if (dbUser != null)
            {
                var passwordMatch = false;
                try
                {
                    passwordMatch = BCrypt.Net.BCrypt.Verify(cleanPass, dbUser.MaBamMatKhau);
                }
                catch (BCrypt.Net.SaltParseException)
                {
                    passwordMatch = false;
                }

                if (passwordMatch && dbUser.DangHoatDong && dbUser.CuDan != null &&
                    (dbUser.MaVaiTroNavigation?.TenVaiTro == "CuDan" || dbUser.MaVaiTroNavigation?.TenVaiTro == "Cư dân"))
                {
                    isAuthenticated = true;
                    fullName = dbUser.HoTen;
                    email = dbUser.ThuDienTu ?? $"{cleanUser}@smartstay.vn";
                    roomCode = await (from cdhd in _db.CuDanHopDongs
                                      join hd in _db.HopDongs on cdhd.MaHopDong equals hd.MaHopDong
                                      join p in _db.Phongs on hd.MaPhong equals p.MaPhong
                                      where cdhd.MaCuDan == dbUser.CuDan!.MaCuDan && cdhd.NgayChuyenRa == null
                                      select p.KyHieuPhong).FirstOrDefaultAsync() ?? string.Empty;
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Lỗi khi truy vấn tài khoản từ Database, chuyển sang danh sách chuẩn.");
        }

        if (!isAuthenticated)
        {
            ModelState.AddModelError("", "Tài khoản hoặc mật khẩu không chính xác.");
            return View(model);
        }

        // Thiết lập Cookie phiên Cư dân
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, cleanUser),
            new Claim(ClaimTypes.Name, fullName),
            new Claim(ClaimTypes.Role, "CuDan"),
            new Claim(ClaimTypes.Email, email),
            new Claim("FullName", fullName),
            new Claim("Username", cleanUser),
            new Claim("RoleName", "Cư Dân"),
            new Claim("RoomCode", roomCode)
        };

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

        TempData["SuccessMessage"] = $"Chào mừng cư dân {fullName} đã quay trở lại căn hộ {roomCode}!";
        return RedirectToAction("Index", "CuDan");
    }
    #endregion

    #region 3. CỔNG ĐĂNG KÝ TÀI KHOẢN CƯ DÂN
    [HttpGet]
    public IActionResult Register()
    {
        var model = new CuDanRegisterViewModel
        {
            ToaNha = "Tòa A - Sapphire",
            SoPhong = "P.305",
            GioiTinh = "Nam",
            DongYDieuKhoan = true
        };

        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Register(CuDanRegisterViewModel model)
    {
        if (!ModelState.IsValid)
        {
            return View(model);
        }

        var cleanPhone = model.SoDienThoai.Trim();
        var cleanEmail = model.ThuDienTu.Trim();
        var cleanCccd = model.SoCanCuoc.Trim();
        var cleanName = model.HoTen.Trim();
        var cleanRoom = model.SoPhong.Trim();

        try
        {
            var existingUser = await _db.NguoiDungs
                .FirstOrDefaultAsync(u => u.TenDangNhap == cleanPhone || u.SoDienThoai == cleanPhone || u.ThuDienTu == cleanEmail);

            var identityExists = await _db.CuDans.AnyAsync(c => c.SoCanCuoc == cleanCccd);
            if (existingUser != null || identityExists)
            {
                ModelState.AddModelError(string.Empty, "Số điện thoại, email hoặc CCCD này đã được đăng ký.");
                return View(model);
            }

            var vaiTroCuDan = await _db.VaiTros.FirstOrDefaultAsync(v => v.TenVaiTro == "CuDan" || v.TenVaiTro == "Cư dân");
            if (vaiTroCuDan == null)
            {
                ModelState.AddModelError(string.Empty, "Hệ thống chưa cấu hình vai trò cư dân. Vui lòng liên hệ Ban Quản lý.");
                return View(model);
            }

            await using var transaction = await _db.Database.BeginTransactionAsync();

            var newUser = new NguoiDung
            {
                TenDangNhap = cleanPhone,
                MaBamMatKhau = BCrypt.Net.BCrypt.HashPassword(model.MatKhau),
                HoTen = cleanName,
                SoDienThoai = cleanPhone,
                ThuDienTu = cleanEmail,
                MaVaiTro = vaiTroCuDan.MaVaiTro,
                DangHoatDong = true,
                CanDoiMatKhau = false,
                ThoiDiemTao = DateTime.UtcNow
            };

            _db.NguoiDungs.Add(newUser);
            await _db.SaveChangesAsync();

            // Thêm bản ghi Cư dân liên kết
            var newCuDan = new CuDan
            {
                MaNguoiDung = newUser.MaNguoiDung,
                SoCanCuoc = cleanCccd,
                NgaySinh = model.NgaySinh.HasValue ? DateOnly.FromDateTime(model.NgaySinh.Value) : new DateOnly(2000, 1, 1),
                GioiTinh = model.GioiTinh,
                DiaChiThuongTru = $"{cleanRoom}, {model.ToaNha}, Chung cư SmartStay",
                TenNguoiLienHeKhanCap = "Ban Quản Lý Tòa Nhà",
                SoDienThoaiKhanCap = "1900888999"
            };

            _db.CuDans.Add(newCuDan);
            await _db.SaveChangesAsync();
            await transaction.CommitAsync();

            _logger.LogInformation("Đã đăng ký tài khoản cư dân mới thành công: {User} - Phòng: {Room}", cleanPhone, cleanRoom);

            var claims = new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, newUser.MaNguoiDung.ToString()),
                new(ClaimTypes.Name, newUser.TenDangNhap),
                new(ClaimTypes.Role, "CuDan"),
                new(ClaimTypes.Email, cleanEmail),
                new("FullName", cleanName),
                new("Username", cleanPhone),
                new("RoleName", "Cư Dân")
            };

            var claimsIdentity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
            await HttpContext.SignInAsync(
                CookieAuthenticationDefaults.AuthenticationScheme,
                new ClaimsPrincipal(claimsIdentity),
                new AuthenticationProperties { IsPersistent = false, ExpiresUtc = DateTimeOffset.UtcNow.AddHours(8) });

            TempData["SuccessMessage"] = $"Đăng ký tài khoản cư dân {cleanName} thành công. Phòng sẽ được liên kết sau khi Ban Quản lý xác nhận hợp đồng.";
            return RedirectToAction("Index", "CuDan");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Không thể lưu đăng ký cư dân {User}.", cleanPhone);
            ModelState.AddModelError(string.Empty, "Không thể tạo tài khoản lúc này. Vui lòng thử lại sau.");
            return View(model);
        }
    }
    #endregion

    #region 4. ĐĂNG XUẤT & ĐIỀU HƯỚNG
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
    #endregion
}
