using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartStay.Web.Data;

namespace SmartStay.Web.Controllers;

[Authorize]
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
    public IActionResult GuiYeuCauSuCo(string danhMuc, string moTa, string mucDoUuTien)
    {
        TempData["SuccessMessage"] = $"Đã gửi phiếu báo hỏng [{danhMuc}] thành công! Kỹ thuật viên tòa nhà đã nhận được yêu cầu và sẽ liên hệ hỗ trợ.";
        return RedirectToAction("SuCo");
    }
}
