using Microsoft.AspNetCore.Mvc;

namespace SmartStay.Web.Controllers;

public class HoaDonController : Controller
{
    public IActionResult Index()
    {
        ViewData["Title"] = "Quản lý Hóa đơn & Đối soát VietQR";
        return View();
    }
}
