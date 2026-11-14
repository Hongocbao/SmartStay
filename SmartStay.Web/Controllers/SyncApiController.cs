using System.Collections.Concurrent;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartStay.Web.Data;
using SmartStay.Web.Models;

namespace SmartStay.Web.Controllers;

/// <summary>
/// Cổng đồng bộ dữ liệu liên thông thời gian thực (Realtime Sync) giữa Web Admin, Web App và Android App
/// </summary>
[ApiController]
[Route("api/sync")]
public class SyncApiController : ControllerBase
{
    private readonly SmartStayDbContext _db;

    // Bộ đệm đồng bộ tức thì (In-Memory Realtime State) kết hợp Database Supabase
    private static readonly ConcurrentDictionary<string, SyncRoomItem> _liveRooms = new(StringComparer.OrdinalIgnoreCase);
    private static readonly ConcurrentDictionary<string, SyncTicketItem> _liveTickets = new(StringComparer.OrdinalIgnoreCase);
    private static readonly ConcurrentQueue<SyncNoticeItem> _liveNotices = new();
    private static SyncResidentMeterState _latestResidentMeter = new();
    private static readonly ConcurrentQueue<SyncResidentMeterLogItem> _residentMeterLogs = new();

    public SyncApiController(SmartStayDbContext db)
    {
        _db = db;
    }

    [AllowAnonymous]
    [HttpGet("snapshot")]
    public async Task<IActionResult> GetRealtimeSnapshot()
    {
        var roomsResult = new List<SyncRoomItem>(_liveRooms.Values);
        var ticketsResult = new List<SyncTicketItem>(_liveTickets.Values);
        var noticesResult = new List<SyncNoticeItem>(_liveNotices);

        try
        {
            var dbPhongs = await _db.Phongs
                .AsNoTracking()
                .OrderBy(p => p.SoTang)
                .ThenBy(p => p.KyHieuPhong)
                .Select(p => new SyncRoomItem
                {
                    MaPhong = p.MaPhong,
                    KyHieuPhong = p.KyHieuPhong,
                    SoTang = p.SoTang,
                    TrangThai = p.TrangThai,
                    GiaThue = p.GiaThue,
                    DienTich = p.DienTich,
                    SucChua = p.SucChua
                })
                .ToListAsync();

            foreach (var p in dbPhongs)
            {
                if (_liveRooms.TryGetValue(p.KyHieuPhong, out var overrideRoom))
                {
                    p.TrangThai = overrideRoom.TrangThai;
                    if (overrideRoom.GiaThue > 0) p.GiaThue = overrideRoom.GiaThue;
                }
                if (roomsResult.All(r => !r.KyHieuPhong.Equals(p.KyHieuPhong, StringComparison.OrdinalIgnoreCase)))
                {
                    roomsResult.Add(p);
                }
            }

            var dbSuCos = await _db.PhieuSuCos
                .AsNoTracking()
                .Include(s => s.MaPhongNavigation)
                .OrderByDescending(s => s.ThoiDiemTao)
                .Take(25)
                .Select(s => new SyncTicketItem
                {
                    MaPhieuSuCo = s.MaPhieuSuCo,
                    SoPhieuSuCo = s.SoPhieuSuCo,
                    KyHieuPhong = s.MaPhongNavigation != null ? s.MaPhongNavigation.KyHieuPhong : "P.305",
                    TieuDe = s.TieuDe,
                    MoTa = s.MoTa ?? string.Empty,
                    UuTien = s.UuTien,
                    TrangThai = s.TrangThai,
                    ThoiDiemTao = s.ThoiDiemTao,
                    ChiPhiVatTu = s.ChiPhiVatTu ?? 0
                })
                .ToListAsync();

            foreach (var s in dbSuCos)
            {
                if (_liveTickets.TryGetValue(s.SoPhieuSuCo, out var overrideTicket))
                {
                    s.TrangThai = overrideTicket.TrangThai;
                }
                if (ticketsResult.All(t => !t.SoPhieuSuCo.Equals(s.SoPhieuSuCo, StringComparison.OrdinalIgnoreCase)))
                {
                    ticketsResult.Add(s);
                }
            }

            var dbThongBaos = await _db.ThongBaos
                .AsNoTracking()
                .OrderByDescending(t => t.ThoiDiemCongBo)
                .Take(15)
                .Select(t => new SyncNoticeItem
                {
                    MaThongBao = t.MaThongBao,
                    TieuDe = t.TieuDe,
                    NoiDung = t.NoiDung,
                    PhamViNhan = t.PhamViNhan,
                    LaKhanCap = t.TieuDe.Contains("Khẩn") || t.TieuDe.Contains("Quan trọng"),
                    ThoiDiemCongBo = t.ThoiDiemCongBo ?? t.ThoiDiemTao
                })
                .ToListAsync();

            foreach (var n in dbThongBaos)
            {
                if (noticesResult.All(x => !x.TieuDe.Equals(n.TieuDe, StringComparison.OrdinalIgnoreCase)))
                {
                    noticesResult.Add(n);
                }
            }
        }
        catch
        {
            // Nếu DB đang khởi tạo, vẫn trả về bộ đệm Realtime trong RAM để Web & Android App đồng bộ tức thì
        }

        return Ok(new
        {
            success = true,
            timestamp = DateTime.UtcNow,
            phongs = roomsResult,
            suCos = ticketsResult.OrderByDescending(t => t.ThoiDiemTao).ToList(),
            thongBaos = noticesResult.OrderByDescending(n => n.ThoiDiemCongBo).ToList(),
            chiSoCuDan = _latestResidentMeter,
            soTheoDoiCuDan = _residentMeterLogs.Reverse().Take(15).ToList()
        });
    }

    [AllowAnonymous]
    [HttpPost("chi-so-cu-dan")]
    public IActionResult DongBoChiSoTuKiemTraCuDan([FromBody] SyncResidentMeterDto req)
    {
        _latestResidentMeter = new SyncResidentMeterState
        {
            KyHieuPhong = string.IsNullOrWhiteSpace(req.KyHieuPhong) ? "P.305" : req.KyHieuPhong.Trim(),
            CheDo = string.IsNullOrWhiteSpace(req.CheDo) ? "both" : req.CheDo.Trim(),
            DienKyTruoc = req.DienKyTruoc > 0 ? req.DienKyTruoc : 1420,
            DienMoiChup = req.DienMoiChup > 0 ? req.DienMoiChup : 1540,
            NuocKyTruoc = req.NuocKyTruoc > 0 ? req.NuocKyTruoc : 84,
            NuocMoiChup = req.NuocMoiChup > 0 ? req.NuocMoiChup : 92,
            TongTienTamTinh = req.TongTienTamTinh,
            NguonCapNhat = string.IsNullOrWhiteSpace(req.NguonCapNhat) ? "Android/Web" : req.NguonCapNhat.Trim(),
            CapNhatLuc = DateTime.UtcNow
        };

        if (req.LuuVaoSoCaNhan && !string.IsNullOrWhiteSpace(req.TomTatTieuThu))
        {
            _residentMeterLogs.Enqueue(new SyncResidentMeterLogItem
            {
                ThoiDiem = string.IsNullOrWhiteSpace(req.NhanThoiGian)
                    ? $"Vừa xong ({_latestResidentMeter.NguonCapNhat})"
                    : req.NhanThoiGian.Trim(),
                CheDo = _latestResidentMeter.CheDo == "electric"
                    ? "Chỉ tính Điện"
                    : (_latestResidentMeter.CheDo == "water" ? "Chỉ tính Nước" : "Điện + Nước"),
                TomTatTieuThu = req.TomTatTieuThu.Trim(),
                TongTienTamTinh = req.TongTienTamTinh
            });
        }

        return Ok(new
        {
            success = true,
            chiSoCuDan = _latestResidentMeter,
            soTheoDoiCuDan = _residentMeterLogs.Reverse().Take(15).ToList()
        });
    }

    [AllowAnonymous]
    [HttpPost("cap-nhat-phong")]
    public async Task<IActionResult> CapNhatTrangThaiPhong([FromBody] CapNhatPhongSyncDto req)
    {
        if (string.IsNullOrWhiteSpace(req.KyHieuPhong) || string.IsNullOrWhiteSpace(req.TrangThai))
            return BadRequest(new { success = false, message = "Thiếu mã phòng hoặc trạng thái." });

        var code = req.KyHieuPhong.Trim();
        _liveRooms[code] = new SyncRoomItem
        {
            MaPhong = int.TryParse(new string(code.Where(char.IsDigit).ToArray()), out var num) ? num : 305,
            KyHieuPhong = code,
            SoTang = req.SoTang ?? 3,
            TrangThai = req.TrangThai.Trim(),
            GiaThue = req.GiaThue ?? 3500000,
            DienTich = req.DienTich ?? 25,
            SucChua = 3
        };

        try
        {
            var phong = await _db.Phongs.FirstOrDefaultAsync(p => p.KyHieuPhong == code);
            if (phong != null)
            {
                phong.TrangThai = req.TrangThai.Trim();
                if (req.GiaThue.HasValue && req.GiaThue.Value > 0)
                {
                    phong.GiaThue = req.GiaThue.Value;
                }
                await _db.SaveChangesAsync();
            }
        }
        catch { }

        return Ok(new { success = true, kyHieuPhong = code, trangThai = req.TrangThai });
    }

    public static SyncTicketItem UpsertLiveTicket(
        string? soPhieuSuCo,
        string? kyHieuPhong,
        string? tieuDe,
        string? moTa,
        string? uuTien,
        string? trangThai)
    {
        var code = string.IsNullOrWhiteSpace(soPhieuSuCo)
            ? $"SC-2026-{DateTime.UtcNow.Ticks % 900 + 100}"
            : soPhieuSuCo.Trim();

        var item = _liveTickets.GetOrAdd(code, _ => new SyncTicketItem
        {
            MaPhieuSuCo = (int)(DateTime.UtcNow.Ticks % 10000),
            SoPhieuSuCo = code,
            KyHieuPhong = string.IsNullOrWhiteSpace(kyHieuPhong) ? "P.305" : kyHieuPhong.Trim(),
            TieuDe = string.IsNullOrWhiteSpace(tieuDe) ? "Sự cố kỹ thuật" : tieuDe.Trim(),
            MoTa = string.IsNullOrWhiteSpace(moTa) ? (tieuDe ?? "") : moTa.Trim(),
            UuTien = string.IsNullOrWhiteSpace(uuTien) ? "Cao" : uuTien.Trim(),
            TrangThai = string.IsNullOrWhiteSpace(trangThai) ? "Chờ xử lý" : trangThai.Trim(),
            ThoiDiemTao = DateTime.UtcNow
        });

        if (!string.IsNullOrWhiteSpace(trangThai)) item.TrangThai = trangThai.Trim();
        if (!string.IsNullOrWhiteSpace(tieuDe)) item.TieuDe = tieuDe.Trim();
        if (!string.IsNullOrWhiteSpace(moTa)) item.MoTa = moTa.Trim();
        if (!string.IsNullOrWhiteSpace(uuTien)) item.UuTien = uuTien.Trim();
        if (!string.IsNullOrWhiteSpace(kyHieuPhong)) item.KyHieuPhong = kyHieuPhong.Trim();
        return item;
    }

    [AllowAnonymous]
    [HttpPost("su-co")]
    public async Task<IActionResult> DongBoPhieuSuCo([FromBody] DongBoSuCoSyncDto req)
    {
        var item = UpsertLiveTicket(req.SoPhieuSuCo, req.KyHieuPhong, req.TieuDe, req.MoTa, req.UuTien, req.TrangThai);

        try
        {
            var existing = await _db.PhieuSuCos.FirstOrDefaultAsync(p => p.SoPhieuSuCo == item.SoPhieuSuCo);
            if (existing != null && !string.IsNullOrWhiteSpace(req.TrangThai))
            {
                existing.TrangThai = req.TrangThai.Trim();
                await _db.SaveChangesAsync();
            }
        }
        catch { }

        return Ok(new { success = true, ticket = item });
    }

    [AllowAnonymous]
    [HttpPost("thong-bao")]
    public async Task<IActionResult> DangThongBaoMoi([FromBody] DangThongBaoSyncDto req)
    {
        if (string.IsNullOrWhiteSpace(req.TieuDe) || string.IsNullOrWhiteSpace(req.NoiDung))
            return BadRequest(new { success = false, message = "Thiếu tiêu đề hoặc nội dung thông báo." });

        var notice = new SyncNoticeItem
        {
            MaThongBao = (int)(DateTime.UtcNow.Ticks % 100000),
            TieuDe = req.TieuDe.Trim(),
            NoiDung = req.NoiDung.Trim(),
            PhamViNhan = string.IsNullOrWhiteSpace(req.PhamViNhan) ? "Toàn tòa nhà" : req.PhamViNhan.Trim(),
            LaKhanCap = req.LaKhanCap,
            ThoiDiemCongBo = DateTime.UtcNow
        };
        _liveNotices.Enqueue(notice);

        try
        {
            var tb = new ThongBao
            {
                TieuDe = notice.TieuDe,
                NoiDung = notice.NoiDung,
                PhamViNhan = notice.PhamViNhan,
                TrangThai = "Đã công bố",
                ThoiDiemCongBo = DateTime.UtcNow,
                ThoiDiemTao = DateTime.UtcNow,
                NguoiTao = 1
            };
            _db.ThongBaos.Add(tb);
            await _db.SaveChangesAsync();
        }
        catch { }

        return Ok(new { success = true, maThongBao = notice.MaThongBao, tieuDe = notice.TieuDe });
    }
}

public class SyncRoomItem
{
    public int MaPhong { get; set; }
    public string KyHieuPhong { get; set; } = string.Empty;
    public int SoTang { get; set; }
    public string TrangThai { get; set; } = string.Empty;
    public decimal GiaThue { get; set; }
    public decimal? DienTich { get; set; }
    public int SucChua { get; set; }
}

public class SyncTicketItem
{
    public int MaPhieuSuCo { get; set; }
    public string SoPhieuSuCo { get; set; } = string.Empty;
    public string KyHieuPhong { get; set; } = "P.305";
    public string TieuDe { get; set; } = string.Empty;
    public string MoTa { get; set; } = string.Empty;
    public string UuTien { get; set; } = "Cao";
    public string TrangThai { get; set; } = "Chờ xử lý";
    public DateTime ThoiDiemTao { get; set; } = DateTime.UtcNow;
    public decimal ChiPhiVatTu { get; set; }
}

public class SyncNoticeItem
{
    public int MaThongBao { get; set; }
    public string TieuDe { get; set; } = string.Empty;
    public string NoiDung { get; set; } = string.Empty;
    public string PhamViNhan { get; set; } = "Toàn tòa nhà";
    public bool LaKhanCap { get; set; }
    public DateTime ThoiDiemCongBo { get; set; } = DateTime.UtcNow;
}

public class CapNhatPhongSyncDto
{
    public string KyHieuPhong { get; set; } = string.Empty;
    public string TrangThai { get; set; } = string.Empty;
    public int? SoTang { get; set; }
    public decimal? DienTich { get; set; }
    public decimal? GiaThue { get; set; }
}

public class DongBoSuCoSyncDto
{
    public string? SoPhieuSuCo { get; set; }
    public string? KyHieuPhong { get; set; }
    public string? TieuDe { get; set; }
    public string? MoTa { get; set; }
    public string? UuTien { get; set; }
    public string? TrangThai { get; set; }
}

public class DangThongBaoSyncDto
{
    public string TieuDe { get; set; } = string.Empty;
    public string NoiDung { get; set; } = string.Empty;
    public string PhamViNhan { get; set; } = "Toàn tòa nhà";
    public bool LaKhanCap { get; set; }
}

public class SyncResidentMeterState
{
    public string KyHieuPhong { get; set; } = "P.305";
    public string CheDo { get; set; } = "both";
    public double DienKyTruoc { get; set; } = 1420;
    public double DienMoiChup { get; set; } = 1540;
    public double NuocKyTruoc { get; set; } = 84;
    public double NuocMoiChup { get; set; } = 92;
    public double TongTienTamTinh { get; set; } = 359000;
    public string NguonCapNhat { get; set; } = "Khởi tạo";
    public DateTime CapNhatLuc { get; set; } = DateTime.UtcNow;
}

public class SyncResidentMeterLogItem
{
    public string ThoiDiem { get; set; } = string.Empty;
    public string CheDo { get; set; } = string.Empty;
    public string TomTatTieuThu { get; set; } = string.Empty;
    public double TongTienTamTinh { get; set; }
}

public class SyncResidentMeterDto
{
    public string? KyHieuPhong { get; set; }
    public string? CheDo { get; set; }
    public double DienKyTruoc { get; set; }
    public double DienMoiChup { get; set; }
    public double NuocKyTruoc { get; set; }
    public double NuocMoiChup { get; set; }
    public double TongTienTamTinh { get; set; }
    public string? TomTatTieuThu { get; set; }
    public string? NhanThoiGian { get; set; }
    public string? NguonCapNhat { get; set; }
    public bool LuuVaoSoCaNhan { get; set; }
}
