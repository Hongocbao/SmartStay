using Microsoft.AspNetCore.Mvc;

namespace SmartStay.Web.Controllers;

public class SuCoController : Controller
{
    public IActionResult Kanban()
    {
        ViewData["Title"] = "Điều phối Sự cố & Bảo trì kỹ thuật (Bảng Kanban)";
        return View();
    }
}
