using Microsoft.AspNetCore.Mvc;

namespace SmartStay.Web.Controllers;

public class HopDongController : Controller
{
    public IActionResult Index()
    {
        ViewData["Title"] = "Quản lý Cư dân & Hợp đồng lưu trú";
        return View();
    }
}
