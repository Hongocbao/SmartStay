using Microsoft.AspNetCore.Mvc;

namespace SmartStay.Web.Controllers;

public class PhongController : Controller
{
    public IActionResult SoDo()
    {
        ViewData["Title"] = "Sơ đồ Phòng trực quan (Room Matrix)";
        return View();
    }
}
