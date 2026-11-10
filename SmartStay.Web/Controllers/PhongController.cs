using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

namespace SmartStay.Web.Controllers;

[Authorize(Roles = "Admin,QuanLy")]
public class PhongController : Controller
{
    public IActionResult SoDo()
    {
        ViewData["Title"] = "Sơ đồ Phòng trực quan (Room Matrix)";
        return View();
    }
}
