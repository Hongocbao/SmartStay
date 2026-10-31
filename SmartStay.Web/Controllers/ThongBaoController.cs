using Microsoft.AspNetCore.Mvc;

namespace SmartStay.Web.Controllers;

public class ThongBaoController : Controller
{
    public IActionResult Index()
    {
        ViewData["Title"] = "Quản lý Truyền thông, Bảng tin & Sự kiện";
        return View();
    }
}
