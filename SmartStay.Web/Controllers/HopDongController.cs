using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

namespace SmartStay.Web.Controllers;

[Authorize(Roles = "Admin,QuanLy")]
public class HopDongController : Controller
{
    public IActionResult Index()
    {
        ViewData["Title"] = "Quản lý Cư dân & Hợp đồng lưu trú";
        return View();
    }
}
