using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

namespace SmartStay.Web.Controllers;

[Authorize(Roles = "Admin,QuanLy")]
public class HoaDonController : Controller
{
    public IActionResult Index()
    {
        ViewData["Title"] = "Quản lý Hóa đơn & Đối soát VietQR";
        return View();
    }
}
