using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using SmartStay.Web.Data;
using SmartStay.Web.Dtos;
using SmartStay.Web.Models;
using SmartStay.Web.Services;

namespace SmartStay.Web.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly SmartStayDbContext _db;
    private readonly ITokenService _tokenService;

    public AuthController(SmartStayDbContext db, ITokenService tokenService)
    {
        _db = db;
        _tokenService = tokenService;
    }

    [HttpPost("dang-nhap")]
    public async Task<IActionResult> DangNhap([FromBody] LoginRequestDto req)
    {
        if (string.IsNullOrWhiteSpace(req.TenDangNhap) || string.IsNullOrWhiteSpace(req.MatKhau))
            return BadRequest(new { message = "Tên đăng nhập và mật khẩu là bắt buộc." });

        var user = await _db.NguoiDungs
            .Include(u => u.MaVaiTroNavigation)
            .FirstOrDefaultAsync(u => u.DangHoatDong &&
                (u.TenDangNhap == req.TenDangNhap.Trim() || u.SoDienThoai == req.TenDangNhap.Trim()));

        if (user == null)
            return Unauthorized(new { message = "Tài khoản hoặc mật khẩu không chính xác." });

        bool isValid;
        try
        {
            isValid = BCrypt.Net.BCrypt.Verify(req.MatKhau, user.MaBamMatKhau);
        }
        catch
        {
            isValid = false;
        }

        if (!isValid)
            return Unauthorized(new { message = "Tài khoản hoặc mật khẩu không chính xác." });

        var roleName = user.MaVaiTroNavigation?.TenVaiTro ?? "CuDan";
        var jwt = _tokenService.GenerateJwtToken(user, roleName);

        var cuDan = await _db.CuDans.FirstOrDefaultAsync(c => c.MaNguoiDung == user.MaNguoiDung);
        string? soPhong = null;
        if (cuDan != null)
        {
            var phong = await (from cdhd in _db.CuDanHopDongs
                               join hd in _db.HopDongs on cdhd.MaHopDong equals hd.MaHopDong
                               join p in _db.Phongs on hd.MaPhong equals p.MaPhong
                               where cdhd.MaCuDan == cuDan.MaCuDan
                                   && cdhd.NgayChuyenRa == null
                                   && hd.TrangThai == "Đang hiệu lực"
                               select p.KyHieuPhong).FirstOrDefaultAsync();
            soPhong = phong;
        }

        return Ok(new LoginResponseDto
        {
            Token = jwt,
            MaNguoiDung = user.MaNguoiDung,
            TenDangNhap = user.TenDangNhap,
            HoTen = user.HoTen,
            VaiTro = roleName,
            SoPhong = soPhong,
            CanDoiMatKhau = user.CanDoiMatKhau
        });
    }

    [Authorize]
    [HttpPut("doi-mat-khau")]
    public async Task<IActionResult> DoiMatKhau([FromBody] ChangePasswordRequestDto req)
    {
        if (req.MatKhauMoi.Length < 8)
            return BadRequest(new { message = "Mật khẩu mới phải có ít nhất 8 ký tự." });

        if (!int.TryParse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value, out var userId))
            return Unauthorized();

        var user = await _db.NguoiDungs.FirstOrDefaultAsync(u => u.MaNguoiDung == userId && u.DangHoatDong);
        if (user == null)
            return Unauthorized();

        var currentPasswordMatches = false;
        try { currentPasswordMatches = BCrypt.Net.BCrypt.Verify(req.MatKhauHienTai, user.MaBamMatKhau); }
        catch { currentPasswordMatches = false; }

        if (!currentPasswordMatches)
            return BadRequest(new { message = "Mật khẩu hiện tại không chính xác." });

        user.MaBamMatKhau = BCrypt.Net.BCrypt.HashPassword(req.MatKhauMoi);
        user.CanDoiMatKhau = false;
        await _db.SaveChangesAsync();
        return Ok(new { success = true });
    }

    [HttpPost("dang-ky")]
    public async Task<IActionResult> DangKy([FromBody] RegisterRequestDto req)
    {
        if (string.IsNullOrWhiteSpace(req.TenDangNhap) || string.IsNullOrWhiteSpace(req.MatKhau)
            || req.MatKhau.Length < 8 || string.IsNullOrWhiteSpace(req.HoTen)
            || string.IsNullOrWhiteSpace(req.SoDienThoai) || string.IsNullOrWhiteSpace(req.Email)
            || string.IsNullOrWhiteSpace(req.SoCanCuoc) || req.SoCanCuoc.Length is < 9 or > 12
            || !req.SoCanCuoc.All(char.IsDigit))
        {
            return BadRequest(new { message = "Vui lòng nhập đủ thông tin, CCCD từ 9 đến 12 chữ số và mật khẩu ít nhất 8 ký tự." });
        }

        req.TenDangNhap = req.TenDangNhap.Trim();
        req.SoDienThoai = req.SoDienThoai.Trim();
        req.Email = req.Email.Trim();
        req.SoCanCuoc = req.SoCanCuoc.Trim();
        var existingUser = await _db.NguoiDungs
            .FirstOrDefaultAsync(u => u.TenDangNhap == req.TenDangNhap || u.SoDienThoai == req.SoDienThoai || u.ThuDienTu == req.Email);

        if (existingUser != null || await _db.CuDans.AnyAsync(c => c.SoCanCuoc == req.SoCanCuoc))
        {
            return Conflict(new { message = "Tên đăng nhập, số điện thoại, email hoặc CCCD đã được đăng ký." });
        }

        var vaiTroCuDan = await _db.VaiTros.FirstOrDefaultAsync(v => v.TenVaiTro == "CuDan" || v.TenVaiTro == "Cư dân");
        if (vaiTroCuDan == null)
            return Problem("Chưa cấu hình vai trò cư dân trong hệ thống.");

        var hashedPassword = BCrypt.Net.BCrypt.HashPassword(req.MatKhau);

        var newUser = new NguoiDung
        {
            TenDangNhap = req.TenDangNhap,
            MaBamMatKhau = hashedPassword,
            HoTen = string.IsNullOrWhiteSpace(req.HoTen) ? req.TenDangNhap : req.HoTen,
            SoDienThoai = req.SoDienThoai,
            ThuDienTu = req.Email,
            MaVaiTro = vaiTroCuDan.MaVaiTro,
            DangHoatDong = true,
            CanDoiMatKhau = false,
            ThoiDiemTao = DateTime.UtcNow
        };

        await using var transaction = await _db.Database.BeginTransactionAsync();
        _db.NguoiDungs.Add(newUser);
        await _db.SaveChangesAsync();
        _db.CuDans.Add(new CuDan { MaNguoiDung = newUser.MaNguoiDung, SoCanCuoc = req.SoCanCuoc });
        await _db.SaveChangesAsync();
        await transaction.CommitAsync();

        var jwt = _tokenService.GenerateJwtToken(newUser, vaiTroCuDan.TenVaiTro);

        return Ok(new LoginResponseDto
        {
            Token = jwt,
            MaNguoiDung = newUser.MaNguoiDung,
            TenDangNhap = newUser.TenDangNhap,
            HoTen = newUser.HoTen,
            VaiTro = vaiTroCuDan.TenVaiTro,
            SoPhong = null
        });
    }
}

[ApiController]
[Authorize(Roles = "Admin,QuanLy")]
[Route("api/phong")]
public class PhongApiController : ControllerBase
{
    private readonly SmartStayDbContext _db;

    public PhongApiController(SmartStayDbContext db)
    {
        _db = db;
    }

    [HttpGet("so-do-tang")]
    public async Task<IActionResult> LaySoDoPhongTheoTang()
    {
        var phongs = await _db.Phongs
            .Include(p => p.MaLoaiPhongNavigation)
            .OrderBy(p => p.SoTang)
            .ThenBy(p => p.KyHieuPhong)
            .ToListAsync();

        if (!phongs.Any())
        {
            return Ok(new object[]
            {
                new { Tang = 3, Phongs = new object[] {
                    new { MaPhong = 1, KyHieuPhong = "P.301", TrangThai = "Đang ở", GiaThue = 3500000, CuDan = (string?)null },
                    new { MaPhong = 2, KyHieuPhong = "P.302", TrangThai = "Trống", GiaThue = 3500000, CuDan = (string?)null },
                    new { MaPhong = 3, KyHieuPhong = "P.305", TrangThai = "Đang ở", GiaThue = 3500000, CuDan = (string?)"Hồ Ngọc Bảo" },
                    new { MaPhong = 4, KyHieuPhong = "P.306", TrangThai = "Bảo trì", GiaThue = 3500000, CuDan = (string?)null }
                }},
                new { Tang = 4, Phongs = new object[] {
                    new { MaPhong = 5, KyHieuPhong = "P.401", TrangThai = "Đang ở", GiaThue = 5000000, CuDan = (string?)null },
                    new { MaPhong = 6, KyHieuPhong = "P.402", TrangThai = "Đã đặt", GiaThue = 5000000, CuDan = (string?)null }
                }}
            });
        }

        var grouped = phongs.GroupBy(p => p.SoTang)
            .Select(g => new
            {
                Tang = g.Key,
                Phongs = g.Select(p => new
                {
                    p.MaPhong,
                    p.KyHieuPhong,
                    p.TrangThai,
                    p.GiaThue,
                    p.DienTich,
                    p.SucChua,
                    LoaiPhong = p.MaLoaiPhongNavigation?.TenLoaiPhong
                })
            });

        return Ok(grouped);
    }
}

[ApiController]
[Authorize]
[Route("api/hoadon")]
public class HoaDonApiController : ControllerBase
{
    private readonly SmartStayDbContext _db;
    private readonly IInvoiceCalculationService _invoiceService;

    public HoaDonApiController(SmartStayDbContext db, IInvoiceCalculationService invoiceService)
    {
        _db = db;
        _invoiceService = invoiceService;
    }

    [Authorize(Roles = "Admin,QuanLy")]
    [HttpPost("tinh-nhap-bac-thang")]
    public async Task<IActionResult> TinhNhapBacThang([FromBody] TinhBacThangRequestDto req)
    {
        decimal sanLuongDien = Math.Max(0, req.ChiSoDienCuoi - req.ChiSoDienDau);
        decimal sanLuongNuoc = Math.Max(0, req.ChiSoNuocCuoi - req.ChiSoNuocDau);

        var bacDien = await _db.BacGia.Where(b => b.MaDichVu == 1).ToListAsync();
        var bacNuoc = await _db.BacGia.Where(b => b.MaDichVu == 2).ToListAsync();

        if (!bacDien.Any())
        {
            bacDien = new List<BacGium>
            {
                new() { ThuTuBac = 1, SoLuongTu = 0, SoLuongDen = 50, DonGia = 1800 },
                new() { ThuTuBac = 2, SoLuongTu = 51, SoLuongDen = 100, DonGia = 2200 },
                new() { ThuTuBac = 3, SoLuongTu = 101, SoLuongDen = 200, DonGia = 2700 },
                new() { ThuTuBac = 4, SoLuongTu = 201, SoLuongDen = null, DonGia = 3200 },
            };
        }

        if (!bacNuoc.Any())
        {
            bacNuoc = new List<BacGium>
            {
                new() { ThuTuBac = 1, SoLuongTu = 0, SoLuongDen = 5, DonGia = 12000 },
                new() { ThuTuBac = 2, SoLuongTu = 6, SoLuongDen = 10, DonGia = 15000 },
                new() { ThuTuBac = 3, SoLuongTu = 11, SoLuongDen = null, DonGia = 18000 },
            };
        }

        var cauHinh = await _db.CauHinhToChucs.FirstOrDefaultAsync();

        var ketQua = _invoiceService.TinhHoaDonBacThang(
            sanLuongDien,
            sanLuongNuoc,
            tienPhong: 3500000,
            tienDichVuCoDinh: 300000,
            bacDien,
            bacNuoc,
            kyHieuPhong: "P.305",
            tenCuDan: "Hồ Ngọc Bảo",
            cauHinh
        );

        return Ok(ketQua);
    }

    [Authorize(Roles = "CuDan")]
    [HttpPost("{id}/xac-nhan-thanh-toan")]
    public async Task<IActionResult> XacNhanThanhToan(int id, [FromBody] XacNhanThanhToanDto req)
    {
        if (req.SoTien <= 0 || string.IsNullOrWhiteSpace(req.DuongDanBienLai))
            return BadRequest(new { success = false, message = "Số tiền phải lớn hơn 0 và cần đính kèm biên lai." });

        if (!int.TryParse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value, out var userId))
            return Unauthorized();

        var hoaDon = await _db.HoaDons
            .Include(h => h.MaHopDongNavigation)
                .ThenInclude(h => h.CuDanHopDong)
            .FirstOrDefaultAsync(h => h.MaHoaDon == id);
        if (hoaDon == null)
            return NotFound(new { success = false, message = "Không tìm thấy hóa đơn." });

        var cuDan = await _db.CuDans.FirstOrDefaultAsync(c => c.MaNguoiDung == userId);
        var isOwner = cuDan != null && hoaDon.MaHopDongNavigation.CuDanHopDong != null
            && hoaDon.MaHopDongNavigation.CuDanHopDong.MaCuDan == cuDan.MaCuDan;
        if (!isOwner)
            return Forbid();

        var hasPendingPayment = await _db.ThanhToans.AnyAsync(t => t.MaHoaDon == id && t.TrangThai == "Chờ xác nhận");
        if (hasPendingPayment)
            return Conflict(new { success = false, message = "Hóa đơn đã có yêu cầu thanh toán đang chờ đối soát." });

        var thanhToan = new ThanhToan
        {
            MaHoaDon = id,
            SoTien = req.SoTien,
            PhuongThucThanhToan = "VietQR",
            DuongDanBienLai = req.DuongDanBienLai,
            GhiChu = req.GhiChu,
            TrangThai = "Chờ xác nhận",
            ThoiDiemThanhToan = DateTime.UtcNow,
            NguoiGuiThanhToan = userId
        };

        _db.ThanhToans.Add(thanhToan);
        await _db.SaveChangesAsync();

        return Ok(new { success = true, message = "Đã gửi thông tin thanh toán để Ban Quản lý đối soát!" });
    }
}

[ApiController]
[Authorize]
[Route("api/suco")]
public class SuCoApiController : ControllerBase
{
    private readonly SmartStayDbContext _db;

    public SuCoApiController(SmartStayDbContext db)
    {
        _db = db;
    }

    [Authorize(Roles = "CuDan")]
    [HttpPost("tao-moi")]
    public async Task<IActionResult> TaoPhieuSuCo([FromBody] TaoPhieuSuCoDto req)
    {
        if (string.IsNullOrWhiteSpace(req.TieuDe) || string.IsNullOrWhiteSpace(req.MoTa))
            return BadRequest(new { success = false, message = "Tiêu đề và mô tả sự cố là bắt buộc." });

        if (!int.TryParse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value, out var userId))
            return Unauthorized();

        var cuDan = await _db.CuDans.FirstOrDefaultAsync(c => c.MaNguoiDung == userId);
        if (cuDan == null)
            return Forbid();

        var hopDongHienTai = await _db.CuDanHopDongs
            .Where(cdhd => cdhd.MaCuDan == cuDan.MaCuDan
                && cdhd.MaHopDongNavigation.TrangThai == "Đang hiệu lực"
                && cdhd.NgayChuyenRa == null)
            .Select(cdhd => new { cdhd.MaHopDongNavigation.MaPhong })
            .FirstOrDefaultAsync();
        if (hopDongHienTai == null)
            return Conflict(new { success = false, message = "Tài khoản chưa có hợp đồng lưu trú đang hiệu lực." });

        var categoryExists = await _db.DanhMucSuCos.AnyAsync(c => c.MaDanhMuc == req.MaDanhMuc);
        if (!categoryExists)
            return BadRequest(new { success = false, message = "Danh mục sự cố không hợp lệ." });

        var maSo = $"SC-2026-{DateTime.UtcNow.Ticks % 900 + 100}";
        var phieu = new PhieuSuCo
        {
            SoPhieuSuCo = maSo,
            MaPhong = hopDongHienTai.MaPhong,
            MaCuDan = cuDan.MaCuDan,
            MaDanhMuc = req.MaDanhMuc,
            TieuDe = req.TieuDe,
            MoTa = req.MoTa,
            UuTien = req.MucDoUuTien,
            TrangThai = "Chờ xử lý",
            ThoiDiemTao = DateTime.UtcNow
        };

        _db.PhieuSuCos.Add(phieu);
        await _db.SaveChangesAsync();

        return Ok(new { success = true, maSoPhieu = maSo, message = "Đã tạo phiếu sự cố thành công!" });
    }

    [Authorize(Roles = "Admin,QuanLy,KyThuat")]
    [HttpPut("{id}/chuyen-trang-thai")]
    public async Task<IActionResult> ChuyenTrangThai(int id, [FromBody] DoiTrangThaiSuCoDto req)
    {
        var allowedStatuses = new[] { "Chờ xử lý", "Đã tiếp nhận", "Đang xử lý", "Hoàn thành", "Từ chối" };
        if (!allowedStatuses.Contains(req.TrangThaiMoi))
            return BadRequest(new { success = false, message = "Trạng thái sự cố không hợp lệ." });

        var phieu = await _db.PhieuSuCos.FindAsync(id);
        if (phieu == null)
            return NotFound(new { success = false, message = "Không tìm thấy phiếu sự cố." });

        var isTechnician = User.IsInRole("KyThuat");
        if (isTechnician && phieu.NguoiDuocGiao.HasValue
            && int.TryParse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value, out var currentUserId)
            && phieu.NguoiDuocGiao.Value != currentUserId)
            return Forbid();

        phieu.TrangThai = req.TrangThaiMoi;
        if (isTechnician && int.TryParse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value, out var technicianId))
            phieu.NguoiDuocGiao = technicianId;
        else if (req.MaNhanVienKyThuat.HasValue)
            phieu.NguoiDuocGiao = req.MaNhanVienKyThuat.Value;
        if (req.ChiPhiVatTu > 0) phieu.ChiPhiVatTu = req.ChiPhiVatTu;
        if (req.TrangThaiMoi == "Hoàn thành") phieu.ThoiDiemHoanThanh = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        return Ok(new { success = true, message = $"Phiếu {phieu.SoPhieuSuCo} đã chuyển sang {req.TrangThaiMoi}" });
    }
}

[ApiController]
[Route("api/tro-ly")]
public class TroLyAiController : ControllerBase
{
    [HttpPost("chat")]
    public IActionResult ChatVoiAi([FromBody] TroLyChatRequestDto req)
    {
        var q = req.TinNhan.ToLower();
        string reply;

        if (q.Contains("điện") || q.Contains("nước") || q.Contains("bậc thang"))
        {
            reply = "⚡ Biểu giá Điện bậc thang:\n" +
                    "• Bậc 1 (0 - 50 kWh): 1.800 đ/kWh\n" +
                    "• Bậc 2 (51 - 100 kWh): 2.200 đ/kWh\n" +
                    "• Bậc 3 (101 - 200 kWh): 2.700 đ/kWh\n" +
                    "• Bậc 4 (> 200 kWh): 3.200 đ/kWh\n\n" +
                    "💧 Biểu giá Nước:\n" +
                    "• Bậc 1 (0 - 5 m³): 12.000 đ/m³\n" +
                    "• Bậc 2 (6 - 10 m³): 15.000 đ/m³\n" +
                    "• Bậc 3 (> 10 m³): 18.000 đ/m³\n" +
                    "Hóa đơn tháng này của bạn được hệ thống tự động tính lũy tiến đúng theo từng bậc giá trên.";
        }
        else if (q.Contains("thanh toán") || q.Contains("vietqr"))
        {
            reply = "Bạn có thể thanh toán trực tiếp qua mã VietQR động được tạo sẵn trong tab 'Hóa đơn'. Sau khi chuyển khoản, chụp biên lai gửi lên để được tự động duyệt nhanh.";
        }
        else
        {
            reply = "Trợ lý AI SmartStay luôn sẵn sàng hỗ trợ bạn 24/7! Bạn có thể đặt câu hỏi về hóa đơn, sự cố thiết bị, hoặc các quy định lưu trú tại tòa nhà.";
        }

        return Ok(new { TraLoi = reply, ThoiGian = DateTime.UtcNow });
    }
}
