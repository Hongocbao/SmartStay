using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

namespace SmartStay.Web.Controllers;

[Authorize(Roles = "Admin,QuanLy")]
public class ThongBaoController : Controller
{
    public IActionResult Index()
    {
        ViewData["Title"] = "Quản lý Truyền thông, Bảng tin & Sự kiện";
        return View();
    }
}
