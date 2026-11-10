using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

namespace SmartStay.Web.Controllers;

[Authorize(Roles = "Admin,QuanLy,KyThuat")]
public class SuCoController : Controller
{
    public IActionResult Kanban()
    {
        ViewData["Title"] = "Điều phối Sự cố & Bảo trì kỹ thuật (Bảng Kanban)";
        return View();
    }
}
