using System.Collections.Concurrent;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using SmartStay.Web.Data;
using SmartStay.Web.Hubs;
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
    private readonly IHubContext<SmartStayHub> _hubContext;

    // Bộ đệm đồng bộ tức thì (In-Memory Realtime State) kết hợp Database Supabase
    private static readonly ConcurrentDictionary<string, SyncRoomItem> _liveRooms = new(StringComparer.OrdinalIgnoreCase);
    private static readonly ConcurrentDictionary<string, SyncTicketItem> _liveTickets = new(StringComparer.OrdinalIgnoreCase);
    private static readonly ConcurrentQueue<SyncNoticeItem> _liveNotices = new();
    private static SyncResidentMeterState _latestResidentMeter = new();
    private static readonly ConcurrentQueue<SyncResidentMeterLogItem> _residentMeterLogs = new();
    private static readonly ConcurrentDictionary<string, SyncMarketItem> _liveMarketItems = InitDefaultMarketItems();
    private static readonly ConcurrentQueue<SyncCallLogItem> _liveCallLogs = new();

    private static ConcurrentDictionary<string, SyncMarketItem> InitDefaultMarketItems()
    {
        var dict = new ConcurrentDictionary<string, SyncMarketItem>(StringComparer.OrdinalIgnoreCase);
        dict["MKT-001"] = new SyncMarketItem
        {
            MaTin = "MKT-001",
            TieuDe = "Quạt đứng Senko 3 tốc độ gió có hẹn giờ",
            DanhMuc = "electronics",
            GiaBan = 120000,
            GiaGoc = 350000,
            KyHieuPhong = "P.305",
            NguoiBan = "Hồ Ngọc Bảo (P.305)",
            TinhTrang = "Còn rất mới 95%",
            MoTa = "Dùng được 4 tháng, chạy êm ru, có remote điều khiển. Pass lại do phòng đã có máy lạnh.",
            HinhAnhUrl = "https://images.unsplash.com/photo-1585338107529-13afc5f02586?auto=format&fit=crop&w=600&q=80",
            VideoUrl = "demo://video-quat-senko-p305.mp4",
            SoSaoTrungBinh = 4.9,
            SoLuotDanhGia = 2,
            TaoLuc = DateTime.UtcNow.AddHours(-6),
            DanhGias = new List<SyncMarketReviewItem>
            {
                new() { NguoiDanhGia = "Trần Minh Quân", KyHieuPhong = "P.302", SoSao = 5, BinhLuan = "Quạt chạy cực êm, chủ phòng giao đồ đúng hẹn ngay sảnh!", ThoiGian = "Hôm qua 19:20" },
                new() { NguoiDanhGia = "Lê Thảo Vy", KyHieuPhong = "P.204", SoSao = 5, BinhLuan = "Video quay test gió rất thật, ngoại hình còn mới tinh 95%.", ThoiGian = "Hôm nay 08:45" }
            }
        };
        dict["MKT-002"] = new SyncMarketItem
        {
            MaTin = "MKT-002",
            TieuDe = "Combo 5 cuốn giáo trình Cấu trúc dữ liệu & Giải thuật",
            DanhMuc = "free",
            GiaBan = 0,
            GiaGoc = 0,
            KyHieuPhong = "P.201",
            NguoiBan = "Nguyễn Dương Bảo (P.201)",
            TinhTrang = "TẶNG MIỄN PHÍ 0Đ",
            MoTa = "Mình đã học xong môn, tặng lại cho các bạn khóa dưới cần ôn thi cuối kỳ.",
            HinhAnhUrl = "https://images.unsplash.com/photo-1497633762265-9d179a990aa6?auto=format&fit=crop&w=600&q=80",
            VideoUrl = null,
            SoSaoTrungBinh = 5.0,
            SoLuotDanhGia = 1,
            TaoLuc = DateTime.UtcNow.AddHours(-4),
            DanhGias = new List<SyncMarketReviewItem>
            {
                new() { NguoiDanhGia = "Phạm Anh Khoa", KyHieuPhong = "P.105", SoSao = 5, BinhLuan = "Sách sạch đẹp như mới, cảm ơn bạn P.201 rất nhiệt tình!", ThoiGian = "Hôm nay 10:15" }
            }
        };
        dict["MKT-003"] = new SyncMarketItem
        {
            MaTin = "MKT-003",
            TieuDe = "Ấm đun nước siêu tốc Sunhouse Inox 1.8L",
            DanhMuc = "electronics",
            GiaBan = 70000,
            GiaGoc = 180000,
            KyHieuPhong = "P.401",
            NguoiBan = "Trần Hoàng Gia Bảo (P.401)",
            TinhTrang = "Inox 304",
            MoTa = "Đun sôi siêu nhanh trong 3 phút, tự ngắt điện an toàn khi sôi, còn nguyên hộp.",
            HinhAnhUrl = "https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=600&q=80",
            VideoUrl = "demo://video-am-sieu-toc-p401.mp4",
            SoSaoTrungBinh = 4.8,
            SoLuotDanhGia = 1,
            TaoLuc = DateTime.UtcNow.AddHours(-2),
            DanhGias = new List<SyncMarketReviewItem>
            {
                new() { NguoiDanhGia = "Hoàng Gia Huy", KyHieuPhong = "P.403", SoSao = 5, BinhLuan = "Đã kiểm tra đun thử, sôi rất nhanh và sạch sẽ.", ThoiGian = "Hôm nay 13:05" }
            }
        };
        return dict;
    }

    public SyncApiController(SmartStayDbContext db, IHubContext<SmartStayHub> hubContext)
    {
        _db = db;
        _hubContext = hubContext;
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
            soTheoDoiCuDan = _residentMeterLogs.Reverse().Take(15).ToList(),
            choDoCu = _liveMarketItems.Values.OrderByDescending(m => m.TaoLuc).ToList(),
            cuocGois = _liveCallLogs.Reverse().Take(20).ToList()
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

    [Authorize(Roles = "Admin,QuanLy,KyThuat")]
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
        string? trangThai,
        string? hinhAnhUrl = null,
        string? videoUrl = null)
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
            HinhAnhUrl = hinhAnhUrl,
            VideoUrl = videoUrl,
            ThoiDiemTao = DateTime.UtcNow
        });

        if (!string.IsNullOrWhiteSpace(trangThai)) item.TrangThai = trangThai.Trim();
        if (!string.IsNullOrWhiteSpace(tieuDe)) item.TieuDe = tieuDe.Trim();
        if (!string.IsNullOrWhiteSpace(moTa)) item.MoTa = moTa.Trim();
        if (!string.IsNullOrWhiteSpace(uuTien)) item.UuTien = uuTien.Trim();
        if (!string.IsNullOrWhiteSpace(kyHieuPhong)) item.KyHieuPhong = kyHieuPhong.Trim();
        if (!string.IsNullOrWhiteSpace(hinhAnhUrl)) item.HinhAnhUrl = hinhAnhUrl;
        if (!string.IsNullOrWhiteSpace(videoUrl)) item.VideoUrl = videoUrl;
        return item;
    }

    [AllowAnonymous]
    [HttpPost("su-co")]
    public async Task<IActionResult> DongBoPhieuSuCo([FromBody] DongBoSuCoSyncDto req)
    {
        var item = UpsertLiveTicket(
            req.SoPhieuSuCo,
            req.KyHieuPhong,
            req.TieuDe,
            req.MoTa,
            req.UuTien,
            req.TrangThai,
            req.HinhAnhUrl,
            req.VideoUrl);

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
    [HttpPost("cho-do-cu")]
    public IActionResult DongBoTinChoDoCu([FromBody] DangTinChoDoCuDto req)
    {
        if (string.IsNullOrWhiteSpace(req.TieuDe))
            return BadRequest(new { success = false, message = "Tiêu đề món đồ là bắt buộc." });

        var id = string.IsNullOrWhiteSpace(req.MaTin)
            ? $"MKT-{DateTime.UtcNow.Ticks % 9000 + 1000}"
            : req.MaTin.Trim();

        var item = new SyncMarketItem
        {
            MaTin = id,
            TieuDe = req.TieuDe.Trim(),
            DanhMuc = string.IsNullOrWhiteSpace(req.DanhMuc) ? "electronics" : req.DanhMuc.Trim(),
            GiaBan = req.GiaBan,
            GiaGoc = req.GiaGoc,
            KyHieuPhong = string.IsNullOrWhiteSpace(req.KyHieuPhong) ? "P.305" : req.KyHieuPhong.Trim(),
            NguoiBan = string.IsNullOrWhiteSpace(req.NguoiBan) ? "Hồ Ngọc Bảo (P.305)" : req.NguoiBan.Trim(),
            TinhTrang = string.IsNullOrWhiteSpace(req.TinhTrang) ? "Mới đăng" : req.TinhTrang.Trim(),
            MoTa = string.IsNullOrWhiteSpace(req.MoTa) ? "Còn mới tốt, liên hệ trao đổi trực tiếp tại sảnh tòa nhà." : req.MoTa.Trim(),
            HinhAnhUrl = req.HinhAnhUrl,
            VideoUrl = req.VideoUrl,
            SoSaoTrungBinh = 5.0,
            SoLuotDanhGia = 0,
            TaoLuc = DateTime.UtcNow,
            DanhGias = new List<SyncMarketReviewItem>()
        };

        _liveMarketItems[id] = item;
        return Ok(new
        {
            success = true,
            item,
            choDoCu = _liveMarketItems.Values.OrderByDescending(m => m.TaoLuc).ToList()
        });
    }

    [AllowAnonymous]
    [HttpPost("cho-do-cu/danh-gia")]
    public IActionResult DanhGiaTinChoDoCu([FromBody] DanhGiaChoDoCuDto req)
    {
        if (string.IsNullOrWhiteSpace(req.MaTin) || string.IsNullOrWhiteSpace(req.BinhLuan))
            return BadRequest(new { success = false, message = "Thiếu mã tin hoặc nội dung bình luận." });

        var key = req.MaTin.Trim();
        var item = _liveMarketItems.GetOrAdd(key, _ => new SyncMarketItem
        {
            MaTin = key,
            TieuDe = req.TieuDeFallback ?? "Sản phẩm Chợ Cư Dân",
            DanhMuc = "electronics",
            KyHieuPhong = "P.305",
            NguoiBan = "Cư dân SmartStay",
            TinhTrang = "Đã xác minh",
            TaoLuc = DateTime.UtcNow
        });

        var stars = Math.Clamp(req.SoSao, 1, 5);
        lock (item.DanhGias)
        {
            item.DanhGias.Insert(0, new SyncMarketReviewItem
            {
                NguoiDanhGia = string.IsNullOrWhiteSpace(req.NguoiDanhGia) ? "Hồ Ngọc Bảo" : req.NguoiDanhGia.Trim(),
                KyHieuPhong = string.IsNullOrWhiteSpace(req.KyHieuPhong) ? "P.305" : req.KyHieuPhong.Trim(),
                SoSao = stars,
                BinhLuan = req.BinhLuan.Trim(),
                ThoiGian = "Vừa xong"
            });
            item.SoLuotDanhGia = item.DanhGias.Count;
            item.SoSaoTrungBinh = Math.Round(item.DanhGias.Average(r => r.SoSao), 1);
        }

        return Ok(new { success = true, item });
    }

    [AllowAnonymous]
    [HttpPost("cuoc-goi")]
    public IActionResult LuuCuocGoi([FromBody] LuuCuocGoiSyncDto req)
    {
        var callCode = !string.IsNullOrWhiteSpace(req.CallId)
            ? req.CallId.Trim()
            : $"CALL-{DateTime.UtcNow.Ticks % 9000 + 1000}";

        var existing = _liveCallLogs.FirstOrDefault(c =>
            string.Equals(c.MaCuocGoi, callCode, StringComparison.OrdinalIgnoreCase));

        if (existing != null)
        {
            existing.ThoiLuongGiay = Math.Max(existing.ThoiLuongGiay, Math.Max(0, req.ThoiLuongGiay));
            if (!string.IsNullOrWhiteSpace(req.TrangThai)) existing.TrangThai = req.TrangThai.Trim();
            if (!string.IsNullOrWhiteSpace(req.NoiDungTraoDoi)) existing.NoiDungTraoDoi = req.NoiDungTraoDoi.Trim();
            return Ok(new
            {
                success = true,
                call = existing,
                cuocGois = _liveCallLogs.Reverse().Take(20).ToList()
            });
        }

        var log = new SyncCallLogItem
        {
            MaCuocGoi = callCode,
            NguoiGoi = string.IsNullOrWhiteSpace(req.NguoiGoi) ? "Người dùng SmartStay" : req.NguoiGoi.Trim(),
            VaiTroNguoiGoi = string.IsNullOrWhiteSpace(req.VaiTroNguoiGoi) ? "CuDan" : req.VaiTroNguoiGoi.Trim(),
            NguoiNhan = string.IsNullOrWhiteSpace(req.NguoiNhan) ? "Ban Quản Lý Vận Hành" : req.NguoiNhan.Trim(),
            VaiTroNguoiNhan = string.IsNullOrWhiteSpace(req.VaiTroNguoiNhan) ? "QuanLy" : req.VaiTroNguoiNhan.Trim(),
            LoaiCuocGoi = string.IsNullOrWhiteSpace(req.LoaiCuocGoi) ? "Video" : req.LoaiCuocGoi.Trim(),
            NoiDungTraoDoi = string.IsNullOrWhiteSpace(req.NoiDungTraoDoi) ? "Trao đổi trực tiếp trên hệ thống" : req.NoiDungTraoDoi.Trim(),
            ThoiLuongGiay = Math.Max(0, req.ThoiLuongGiay),
            TrangThai = string.IsNullOrWhiteSpace(req.TrangThai) ? "Đã kết nối" : req.TrangThai.Trim(),
            ThoiDiem = DateTime.UtcNow
        };
        _liveCallLogs.Enqueue(log);

        return Ok(new
        {
            success = true,
            call = log,
            cuocGois = _liveCallLogs.Reverse().Take(20).ToList()
        });
    }

    [AllowAnonymous]
    [HttpPost("call-signal")]
    public async Task<IActionResult> DispatchCallSignalRest([FromBody] CallSignalPacket req)
    {
        if (string.IsNullOrWhiteSpace(req.SignalType) || string.IsNullOrWhiteSpace(req.FromClientId))
        {
            return BadRequest(new { success = false, message = "Thiếu signalType hoặc fromClientId." });
        }

        CallSignalingEngine.UpsertPresence(req.FromClientId, req.FromRole, req.FromName, req.FromRoom);
        var saved = CallSignalingEngine.EnqueueSignal(req);
        await CallSignalingEngine.BroadcastPacketAsync(_hubContext.Clients, saved);

        return Ok(new
        {
            success = true,
            signal = saved,
            latestSeq = CallSignalingEngine.CurrentSeq
        });
    }

    [AllowAnonymous]
    [HttpGet("call-signal/poll")]
    public IActionResult PollCallSignals(
        [FromQuery] string clientId,
        [FromQuery] string? role = "CuDan",
        [FromQuery] string? displayName = null,
        [FromQuery] string? roomCode = null,
        [FromQuery] long sinceSeq = 0,
        [FromQuery] string? activeCallId = null)
    {
        if (string.IsNullOrWhiteSpace(clientId))
        {
            return BadRequest(new { success = false, message = "Thiếu clientId." });
        }

        CallSignalingEngine.UpsertPresence(clientId, role, displayName, roomCode);
        var items = CallSignalingEngine.PollSignals(clientId, role, sinceSeq);
        if (!string.IsNullOrWhiteSpace(activeCallId))
        {
            var sessionSignals = CallSignalingEngine.GetSessionHandshakes(activeCallId, clientId);
            foreach (var sig in sessionSignals)
            {
                if (sig.Seq > sinceSeq && items.All(x => x.Seq != sig.Seq))
                {
                    items.Add(sig);
                }
            }
            items = items.OrderBy(x => x.Seq).ToList();
        }
        var currentSeq = CallSignalingEngine.CurrentSeq;

        return Ok(new
        {
            success = true,
            latestSeq = items.Count > 0 ? Math.Max(currentSeq, items.Max(x => x.Seq)) : currentSeq,
            signals = items,
            onlinePeers = CallSignalingEngine.GetOnlinePeers(clientId)
        });
    }

    [AllowAnonymous]
    [HttpGet("call-presence")]
    public IActionResult GetCallPresence([FromQuery] string? excludeClientId = null)
    {
        return Ok(new
        {
            success = true,
            peers = CallSignalingEngine.GetOnlinePeers(excludeClientId)
        });
    }

    [Authorize(Roles = "Admin,QuanLy")]
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
    public string? HinhAnhUrl { get; set; }
    public string? VideoUrl { get; set; }
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
    public string? HinhAnhUrl { get; set; }
    public string? VideoUrl { get; set; }
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

public class SyncMarketReviewItem
{
    public string NguoiDanhGia { get; set; } = string.Empty;
    public string KyHieuPhong { get; set; } = "P.305";
    public int SoSao { get; set; } = 5;
    public string BinhLuan { get; set; } = string.Empty;
    public string ThoiGian { get; set; } = "Vừa xong";
}

public class SyncMarketItem
{
    public string MaTin { get; set; } = string.Empty;
    public string TieuDe { get; set; } = string.Empty;
    public string DanhMuc { get; set; } = "electronics";
    public decimal GiaBan { get; set; }
    public decimal GiaGoc { get; set; }
    public string KyHieuPhong { get; set; } = "P.305";
    public string NguoiBan { get; set; } = string.Empty;
    public string TinhTrang { get; set; } = "Mới đăng";
    public string MoTa { get; set; } = string.Empty;
    public string? HinhAnhUrl { get; set; }
    public string? VideoUrl { get; set; }
    public double SoSaoTrungBinh { get; set; } = 5.0;
    public int SoLuotDanhGia { get; set; }
    public DateTime TaoLuc { get; set; } = DateTime.UtcNow;
    public List<SyncMarketReviewItem> DanhGias { get; set; } = new();
}

public class DangTinChoDoCuDto
{
    public string? MaTin { get; set; }
    public string TieuDe { get; set; } = string.Empty;
    public string? DanhMuc { get; set; }
    public decimal GiaBan { get; set; }
    public decimal GiaGoc { get; set; }
    public string? KyHieuPhong { get; set; }
    public string? NguoiBan { get; set; }
    public string? TinhTrang { get; set; }
    public string? MoTa { get; set; }
    public string? HinhAnhUrl { get; set; }
    public string? VideoUrl { get; set; }
}

public class DanhGiaChoDoCuDto
{
    public string MaTin { get; set; } = string.Empty;
    public string? TieuDeFallback { get; set; }
    public string? NguoiDanhGia { get; set; }
    public string? KyHieuPhong { get; set; }
    public int SoSao { get; set; } = 5;
    public string BinhLuan { get; set; } = string.Empty;
}

public class SyncCallLogItem
{
    public string MaCuocGoi { get; set; } = string.Empty;
    public string NguoiGoi { get; set; } = string.Empty;
    public string VaiTroNguoiGoi { get; set; } = "CuDan";
    public string NguoiNhan { get; set; } = string.Empty;
    public string VaiTroNguoiNhan { get; set; } = "QuanLy";
    public string LoaiCuocGoi { get; set; } = "Video";
    public string NoiDungTraoDoi { get; set; } = string.Empty;
    public int ThoiLuongGiay { get; set; }
    public string TrangThai { get; set; } = "Đã kết nối";
    public DateTime ThoiDiem { get; set; } = DateTime.UtcNow;
}

public class LuuCuocGoiSyncDto
{
    public string? CallId { get; set; }
    public string? NguoiGoi { get; set; }
    public string? VaiTroNguoiGoi { get; set; }
    public string? NguoiNhan { get; set; }
    public string? VaiTroNguoiNhan { get; set; }
    public string? LoaiCuocGoi { get; set; }
    public string? NoiDungTraoDoi { get; set; }
    public int ThoiLuongGiay { get; set; }
    public string? TrangThai { get; set; }
}
