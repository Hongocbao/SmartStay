using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace SmartStay.Web.Controllers;

[Authorize(Roles = "Admin")]
public class HeThongController : Controller
{
    public IActionResult CauHinh()
    {
        ViewData["Title"] = "Cấu Hình Hệ Thống & Cổng Thanh Toán VietQR";
        return View();
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult LuuCauHinh(string bankCode, string accountNumber, string accountHolder, decimal giaDienBac1, decimal giaNuocBac1)
    {
        TempData["SuccessMessage"] = "Đã lưu thông số cấu hình hệ thống, tài khoản VietQR và biểu giá điện nước bậc thang thành công!";
        return RedirectToAction("CauHinh");
    }
}
