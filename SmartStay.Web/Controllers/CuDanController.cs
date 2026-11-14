using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartStay.Web.Data;

namespace SmartStay.Web.Controllers;

[Authorize(Roles = "CuDan")]
public class CuDanController : Controller
{
    private readonly SmartStayDbContext _db;
    private readonly ILogger<CuDanController> _logger;

    public CuDanController(SmartStayDbContext db, ILogger<CuDanController> logger)
    {
        _db = db;
        _logger = logger;
    }

    [AllowAnonymous]
    [HttpGet("CuDan/Login")]
    public IActionResult LoginRedirect()
    {
        return RedirectToAction("CuDanLogin", "Account");
    }

    [AllowAnonymous]
    [HttpGet("CuDan/Register")]
    public IActionResult RegisterRedirect()
    {
        return RedirectToAction("Register", "Account");
    }

    public IActionResult Index()
    {
        ViewData["Title"] = "Cổng Cư Dân - Tổng Quan Phòng P.305";
        return View();
    }

    public IActionResult HoaDon()
    {
        ViewData["Title"] = "Hóa Đơn Tiền Phòng & Quét Mã VietQR";
        return View();
    }

    public IActionResult SuCo()
    {
        ViewData["Title"] = "Báo Cáo Sự Cố & Lịch Sử Bảo Trì";
        return View();
    }

    public IActionResult ChiaTien()
    {
        ViewData["Title"] = "Chia Tiền Phòng Ở Ghép & Đa Mã VietQR Động";
        return View();
    }

    public IActionResult AiOcr()
    {
        ViewData["Title"] = "AI Camera Quét Công Tơ Điện Nước Tự Động";
        return View();
    }

    public IActionResult AiConcierge()
    {
        ViewData["Title"] = "Trợ Lý Ảo AI Tự Hành (AI Agentic Concierge)";
        return View();
    }

    public IActionResult GuestPass()
    {
        ViewData["Title"] = "Cấp Mã Khách Vãng Lai & Khóa Thông Minh IoT";
        return View();
    }

    public IActionResult ChoDoCu()
    {
        ViewData["Title"] = "Chợ Trao Đổi Đồ Cũ Sinh Viên Co-Living";
        return View();
    }

    [HttpPost]
    public IActionResult NopBienLai(string maHoaDon, string maGiaoDich, string ghiChu)
    {
        TempData["SuccessMessage"] = $"Đã gửi biên lai cho hóa đơn {maHoaDon} (Mã GD: {maGiaoDich}) thành công! Trạng thái đã chuyển sang [Chờ đối soát]. Ban Quản Lý sẽ kiểm tra và xác nhận sớm.";
        return RedirectToAction("HoaDon");
    }

    [HttpPost]
    public async Task<IActionResult> GuiYeuCauSuCo(string danhMuc, string moTa, string mucDoUuTien)
    {
        var ticketCode = $"SC-2026-{Random.Shared.Next(100, 999)}";
        var title = $"[{danhMuc}] {(string.IsNullOrWhiteSpace(moTa) ? danhMuc : (moTa.Length > 60 ? moTa[..60] + "..." : moTa))}";
        var roomCode = "P.305";

        SyncApiController.UpsertLiveTicket(
            ticketCode,
            roomCode,
            title,
            moTa ?? danhMuc,
            mucDoUuTien ?? "Trung bình",
            "Chờ xử lý");

        try
        {
            var phong = await _db.Phongs.FirstOrDefaultAsync(p => p.KyHieuPhong == roomCode);
            if (phong != null)
            {
                _db.PhieuSuCos.Add(new Models.PhieuSuCo
                {
                    SoPhieuSuCo = ticketCode,
                    MaPhong = phong.MaPhong,
                    TieuDe = title,
                    MoTa = moTa ?? danhMuc,
                    UuTien = mucDoUuTien ?? "Trung bình",
                    TrangThai = "Chờ xử lý",
                    ThoiDiemTao = DateTime.UtcNow
                });
                await _db.SaveChangesAsync();
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Offline fallback sync ticket {Code}", ticketCode);
        }

        TempData["SuccessMessage"] = $"Đã gửi phiếu báo hỏng {ticketCode} [{danhMuc}] thành công & đồng bộ sang Bảng Kanban Kỹ thuật!";
        return RedirectToAction("SuCo");
    }
}
