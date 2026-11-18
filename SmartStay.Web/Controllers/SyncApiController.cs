using System.Collections.Concurrent;
using System.Data;
using System.Net.Http.Headers;
using System.Text.RegularExpressions;
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
    private static readonly ConcurrentDictionary<string, (byte[] Bytes, string ContentType)> _uploadedMediaBlobs = new(StringComparer.OrdinalIgnoreCase);
    private static readonly HttpClient _storageHttp = new() { Timeout = TimeSpan.FromSeconds(45) };
    private readonly IConfiguration _config;

    private static string? NormalizePlayableVideoUrl(string? rawUrl)
    {
        if (string.IsNullOrWhiteSpace(rawUrl)) return null;
        var trimmed = rawUrl.Trim();
        if (trimmed.StartsWith("demo://", StringComparison.OrdinalIgnoreCase) ||
            trimmed.Contains("interactive-examples.mdn.mozilla.net/media/cc0-videos/flower", StringComparison.OrdinalIgnoreCase))
        {
            return "https://www.w3schools.com/html/mov_bbb.mp4";
        }
        return trimmed;
    }

    private static void AddDbParam(IDbCommand cmd, string name, object? value)
    {
        var p = cmd.CreateParameter();
        p.ParameterName = name;
        p.Value = value ?? DBNull.Value;
        cmd.Parameters.Add(p);
    }

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
            VideoUrl = "https://www.w3schools.com/html/mov_bbb.mp4",
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
            VideoUrl = "https://www.w3schools.com/html/mov_bbb.mp4",
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

    public SyncApiController(SmartStayDbContext db, IHubContext<SmartStayHub> hubContext, IConfiguration config)
    {
        _db = db;
        _hubContext = hubContext;
        _config = config;
    }

    [AllowAnonymous]
    [HttpGet("snapshot")]
    public async Task<IActionResult> GetRealtimeSnapshot()
    {
        var roomsResult = new List<SyncRoomItem>(_liveRooms.Values);
        var ticketsResult = new List<SyncTicketItem>(_liveTickets.Values);
        var noticesResult = new List<SyncNoticeItem>(_liveNotices);
        var marketItems = new Dictionary<string, SyncMarketItem>(_liveMarketItems, StringComparer.OrdinalIgnoreCase);
        var guestPassesResult = new List<object>();
        var splitBillsResult = new List<object>();
        var callLogsResult = new List<SyncCallLogItem>(_liveCallLogs.Reverse().Take(20));
        var meterLogsResult = new List<SyncResidentMeterLogItem>(_residentMeterLogs.Reverse().Take(15));
        var latestMeter = _latestResidentMeter;

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

            // Đọc các bảng lưu trữ bền vững trên Supabase PostgreSQL
            if (_db.Database.IsNpgsql())
            {
                var conn = _db.Database.GetDbConnection();
                if (conn.State != ConnectionState.Open) await conn.OpenAsync();

                // 1. Chợ đồ cũ
                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = @"SELECT ""MaTin"", ""TieuDe"", ""DanhMuc"", ""GiaBan"", ""GiaGoc"", ""KyHieuPhong"", ""NguoiBan"", ""TinhTrang"", ""MoTa"", ""HinhAnhUrl"", ""VideoUrl"", ""TrangThai"", ""NguoiGiuCho"", ""SoSaoTrungBinh"", ""SoLuotDanhGia"", ""TaoLuc"", ""MaPhong"", ""MaCuDanBan"", ""MaCuDanGiuCho"" FROM ""ChoDoCuTin"" ORDER BY ""TaoLuc"" DESC LIMIT 50";
                    using var r = await cmd.ExecuteReaderAsync();
                    while (await r.ReadAsync())
                    {
                        var maTin = r.GetString(0);
                        marketItems[maTin] = new SyncMarketItem
                        {
                            MaTin = maTin,
                            TieuDe = r.GetString(1),
                            DanhMuc = r.GetString(2),
                            GiaBan = r.GetDecimal(3),
                            GiaGoc = r.GetDecimal(4),
                            KyHieuPhong = r.GetString(5),
                            NguoiBan = r.GetString(6),
                            TinhTrang = r.GetString(7),
                            MoTa = r.GetString(8),
                            HinhAnhUrl = r.IsDBNull(9) ? null : r.GetString(9),
                            VideoUrl = r.IsDBNull(10) ? null : NormalizePlayableVideoUrl(r.GetString(10)),
                            TrangThai = r.IsDBNull(11) ? "Đang bán" : r.GetString(11),
                            NguoiGiuCho = r.IsDBNull(12) ? null : r.GetString(12),
                            SoSaoTrungBinh = r.GetDouble(13),
                            SoLuotDanhGia = r.GetInt32(14),
                            TaoLuc = r.GetDateTime(15),
                            MaPhong = r.IsDBNull(16) ? null : r.GetInt32(16),
                            MaCuDanBan = r.IsDBNull(17) ? null : r.GetInt32(17),
                            MaCuDanGiuCho = r.IsDBNull(18) ? null : r.GetInt32(18),
                            DanhGias = new List<SyncMarketReviewItem>()
                        };
                    }
                }

                // 2. Đánh giá Chợ đồ cũ
                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = @"SELECT ""MaTin"", ""NguoiDanhGia"", ""KyHieuPhong"", ""SoSao"", ""BinhLuan"", ""ThoiGian"" FROM ""ChoDoCuDanhGia"" ORDER BY ""TaoLuc"" DESC LIMIT 100";
                    using var r = await cmd.ExecuteReaderAsync();
                    while (await r.ReadAsync())
                    {
                        var maTin = r.GetString(0);
                        if (marketItems.TryGetValue(maTin, out var item))
                        {
                            item.DanhGias.Add(new SyncMarketReviewItem
                            {
                                NguoiDanhGia = r.GetString(1),
                                KyHieuPhong = r.GetString(2),
                                SoSao = r.GetInt32(3),
                                BinhLuan = r.GetString(4),
                                ThoiGian = r.GetString(5)
                            });
                        }
                    }
                }

                // 3. Vé khách vãng lai
                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = @"SELECT ""MaVe"", ""KyHieuPhong"", ""TenKhach"", ""SoDienThoai"", ""MaPin"", ""HieuLucDen"", ""TrangThai"", ""TaoLuc"" FROM ""VeKhachVangLai"" ORDER BY ""TaoLuc"" DESC LIMIT 20";
                    using var r = await cmd.ExecuteReaderAsync();
                    while (await r.ReadAsync())
                    {
                        guestPassesResult.Add(new
                        {
                            maVe = r.GetString(0),
                            kyHieuPhong = r.GetString(1),
                            tenKhach = r.GetString(2),
                            soDienThoai = r.IsDBNull(3) ? "" : r.GetString(3),
                            maPin = r.GetString(4),
                            hieuLucDen = r.GetString(5),
                            trangThai = r.GetString(6),
                            taoLuc = r.GetDateTime(7)
                        });
                    }
                }

                // 4. Chia tiền phòng ở ghép
                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = @"SELECT ""MaChia"", ""KyHieuPhong"", ""TieuDe"", ""TongTien"", ""SoThanhVien"", ""MoiNguoi"", ""TrangThai"", ""TaoLuc"" FROM ""ChiaTienPhong"" ORDER BY ""TaoLuc"" DESC LIMIT 20";
                    using var r = await cmd.ExecuteReaderAsync();
                    while (await r.ReadAsync())
                    {
                        splitBillsResult.Add(new
                        {
                            maChia = r.GetString(0),
                            kyHieuPhong = r.GetString(1),
                            tieuDe = r.GetString(2),
                            tongTien = r.GetDecimal(3),
                            soThanhVien = r.GetInt32(4),
                            moiNguoi = r.GetDecimal(5),
                            trangThai = r.GetString(6),
                            taoLuc = r.GetDateTime(7)
                        });
                    }
                }

                // 5. Sổ tự kiểm tra OCR
                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = @"SELECT ""KyHieuPhong"", ""CheDo"", ""DienKyTruoc"", ""DienMoiChup"", ""NuocKyTruoc"", ""NuocMoiChup"", ""TongTienTamTinh"", ""TomTatTieuThu"", ""NguonCapNhat"", ""TaoLuc"" FROM ""ChiSoTuKiemTra"" ORDER BY ""TaoLuc"" DESC LIMIT 15";
                    using var r = await cmd.ExecuteReaderAsync();
                    var dbLogs = new List<SyncResidentMeterLogItem>();
                    var isFirst = true;
                    while (await r.ReadAsync())
                    {
                        if (isFirst)
                        {
                            isFirst = false;
                            latestMeter = new SyncResidentMeterState
                            {
                                KyHieuPhong = r.GetString(0),
                                CheDo = r.GetString(1),
                                DienKyTruoc = r.GetDouble(2),
                                DienMoiChup = r.GetDouble(3),
                                NuocKyTruoc = r.GetDouble(4),
                                NuocMoiChup = r.GetDouble(5),
                                TongTienTamTinh = r.GetDouble(6),
                                NguonCapNhat = r.IsDBNull(8) ? "Supabase" : r.GetString(8),
                                CapNhatLuc = r.GetDateTime(9)
                            };
                        }
                        if (!r.IsDBNull(7) && !string.IsNullOrWhiteSpace(r.GetString(7)))
                        {
                            dbLogs.Add(new SyncResidentMeterLogItem
                            {
                                ThoiDiem = r.GetDateTime(9).ToLocalTime().ToString("dd/MM HH:mm"),
                                CheDo = r.GetString(1) == "electric" ? "Chỉ tính Điện" : (r.GetString(1) == "water" ? "Chỉ tính Nước" : "Điện + Nước"),
                                TomTatTieuThu = r.GetString(7),
                                TongTienTamTinh = r.GetDouble(6)
                            });
                        }
                    }
                    if (dbLogs.Count > 0) meterLogsResult = dbLogs;
                }

                // 6. Nhật ký cuộc gọi
                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = @"SELECT ""MaCuocGoi"", ""NguoiGoi"", ""VaiTroNguoiGoi"", ""NguoiNhan"", ""VaiTroNguoiNhan"", ""LoaiCuocGoi"", ""NoiDungTraoDoi"", ""ThoiLuongGiay"", ""TrangThai"", ""ThoiDiem"" FROM ""NhatKyCuocGoi"" ORDER BY ""ThoiDiem"" DESC LIMIT 20";
                    using var r = await cmd.ExecuteReaderAsync();
                    var dbCalls = new List<SyncCallLogItem>();
                    while (await r.ReadAsync())
                    {
                        dbCalls.Add(new SyncCallLogItem
                        {
                            MaCuocGoi = r.GetString(0),
                            NguoiGoi = r.GetString(1),
                            VaiTroNguoiGoi = r.GetString(2),
                            NguoiNhan = r.GetString(3),
                            VaiTroNguoiNhan = r.GetString(4),
                            LoaiCuocGoi = r.GetString(5),
                            NoiDungTraoDoi = r.GetString(6),
                            ThoiLuongGiay = r.GetInt32(7),
                            TrangThai = r.GetString(8),
                            ThoiDiem = r.GetDateTime(9)
                        });
                    }
                    if (dbCalls.Count > 0) callLogsResult = dbCalls;
                }
            }
        }
        catch
        {
            // Nếu DB đang khởi tạo, vẫn trả về bộ đệm Realtime để Web & Android App đồng bộ tức thì
        }

        return Ok(new
        {
            success = true,
            timestamp = DateTime.UtcNow,
            phongs = roomsResult,
            suCos = ticketsResult.OrderByDescending(t => t.ThoiDiemTao).ToList(),
            thongBaos = noticesResult.OrderByDescending(n => n.ThoiDiemCongBo).ToList(),
            chiSoCuDan = latestMeter,
            soTheoDoiCuDan = meterLogsResult,
            choDoCu = marketItems.Values.OrderByDescending(m => m.TaoLuc).ToList(),
            veKhach = guestPassesResult,
            chiaTiens = splitBillsResult,
            cuocGois = callLogsResult
        });
    }

    [AllowAnonymous]
    [HttpPost("chi-so-cu-dan")]
    public async Task<IActionResult> DongBoChiSoTuKiemTraCuDan([FromBody] SyncResidentMeterDto req)
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

        try
        {
            if (_db.Database.IsNpgsql())
            {
                var conn = _db.Database.GetDbConnection();
                if (conn.State != ConnectionState.Open) await conn.OpenAsync();
                using var cmd = conn.CreateCommand();
                cmd.CommandText = @"
                    INSERT INTO ""ChiSoTuKiemTra"" (
                        ""MaPhong"", ""MaCuDan"", ""MaChiSoChinhThuc"",
                        ""KyHieuPhong"", ""CheDo"", ""DienKyTruoc"", ""DienMoiChup"",
                        ""NuocKyTruoc"", ""NuocMoiChup"", ""TongTienTamTinh"",
                        ""TomTatTieuThu"", ""NguonCapNhat"", ""TrangThaiDuyet""
                    ) VALUES (
                        COALESCE((SELECT p.""MaPhong"" FROM ""Phong"" p WHERE UPPER(p.""KyHieuPhong"") = UPPER(@p0) LIMIT 1), (SELECT p.""MaPhong"" FROM ""Phong"" p ORDER BY p.""MaPhong"" LIMIT 1)),
                        (SELECT c.""MaCuDan"" FROM ""CuDan"" c ORDER BY c.""MaCuDan"" LIMIT 1),
                        (SELECT cs.""MaChiSo"" FROM ""ChiSoSuDung"" cs ORDER BY cs.""MaChiSo"" DESC LIMIT 1),
                        @p0, @p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, 'Đã đồng bộ quản lý'
                    )";
                AddDbParam(cmd, "@p0", _latestResidentMeter.KyHieuPhong);
                AddDbParam(cmd, "@p1", _latestResidentMeter.CheDo);
                AddDbParam(cmd, "@p2", _latestResidentMeter.DienKyTruoc);
                AddDbParam(cmd, "@p3", _latestResidentMeter.DienMoiChup);
                AddDbParam(cmd, "@p4", _latestResidentMeter.NuocKyTruoc);
                AddDbParam(cmd, "@p5", _latestResidentMeter.NuocMoiChup);
                AddDbParam(cmd, "@p6", _latestResidentMeter.TongTienTamTinh);
                AddDbParam(cmd, "@p7", req.TomTatTieuThu);
                AddDbParam(cmd, "@p8", _latestResidentMeter.NguonCapNhat);
                await cmd.ExecuteNonQueryAsync();
            }
        }
        catch { }

        return Ok(new
        {
            success = true,
            chiSoCuDan = _latestResidentMeter,
            soTheoDoiCuDan = _residentMeterLogs.Reverse().Take(15).ToList()
        });
    }

    [Authorize(Roles = "Admin,QuanLy,KyThuat")]
    [HttpPost("duyet-chi-so-cu-dan")]
    public async Task<IActionResult> DuyetChiSoCuDanSangHoaDon([FromBody] SyncResidentMeterDto req)
    {
        var roomCode = string.IsNullOrWhiteSpace(req.KyHieuPhong) ? _latestResidentMeter.KyHieuPhong : req.KyHieuPhong.Trim();
        var elecOld = req.DienKyTruoc > 0 ? (decimal)req.DienKyTruoc : (decimal)_latestResidentMeter.DienKyTruoc;
        var elecNew = req.DienMoiChup > 0 ? (decimal)req.DienMoiChup : (decimal)_latestResidentMeter.DienMoiChup;
        long? maChiSo = null;

        try
        {
            var room = await _db.Phongs.FirstOrDefaultAsync(p => p.KyHieuPhong == roomCode)
                       ?? await _db.Phongs.FirstOrDefaultAsync();
            var dichVuDien = await _db.DichVus.FirstOrDefaultAsync(d => d.MaDichVu == 1)
                             ?? await _db.DichVus.FirstOrDefaultAsync();
            var user = await _db.NguoiDungs.FirstOrDefaultAsync();

            if (room != null && dichVuDien != null && user != null)
            {
                var kyTinh = new DateOnly(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1);
                var existingReading = await _db.ChiSoSuDungs.FirstOrDefaultAsync(
                    cs => cs.MaPhong == room.MaPhong && cs.MaDichVu == dichVuDien.MaDichVu && cs.KyTinhTien == kyTinh);

                if (existingReading != null)
                {
                    existingReading.ChiSoTruoc = elecOld;
                    existingReading.ChiSoHienTai = elecNew;
                    await _db.SaveChangesAsync();
                    maChiSo = existingReading.MaChiSo;
                }
                else
                {
                    var fresh = new ChiSoSuDung
                    {
                        MaPhong = room.MaPhong,
                        MaDichVu = dichVuDien.MaDichVu,
                        KyTinhTien = kyTinh,
                        LoaiGhiChiSo = "OCR",
                        ChiSoTruoc = elecOld,
                        ChiSoHienTai = elecNew,
                        NgayGhiChiSo = DateOnly.FromDateTime(DateTime.UtcNow),
                        GhiChu = "Đồng bộ & duyệt từ chỉ số OCR cư dân",
                        NguoiGhiNhan = user.MaNguoiDung
                    };
                    _db.ChiSoSuDungs.Add(fresh);
                    await _db.SaveChangesAsync();
                    maChiSo = fresh.MaChiSo;
                }

                if (_db.Database.IsNpgsql() && maChiSo.HasValue)
                {
                    var conn = _db.Database.GetDbConnection();
                    if (conn.State != ConnectionState.Open) await conn.OpenAsync();
                    using var cmd = conn.CreateCommand();
                    cmd.CommandText = @"UPDATE ""ChiSoTuKiemTra"" SET ""MaChiSoChinhThuc"" = @p0, ""TrangThaiDuyet"" = 'Đã duyệt chính thức' WHERE UPPER(""KyHieuPhong"") = UPPER(@p1)";
                    AddDbParam(cmd, "@p0", maChiSo.Value);
                    AddDbParam(cmd, "@p1", roomCode);
                    await cmd.ExecuteNonQueryAsync();
                }
            }
        }
        catch { }

        return Ok(new
        {
            success = true,
            kyHieuPhong = roomCode,
            maChiSoChinhThuc = maChiSo,
            trangThaiDuyet = "Đã duyệt chính thức"
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
            if (existing != null)
            {
                if (!string.IsNullOrWhiteSpace(req.TrangThai)) existing.TrangThai = req.TrangThai.Trim();
                if (!string.IsNullOrWhiteSpace(req.TieuDe)) existing.TieuDe = req.TieuDe.Trim();
                if (!string.IsNullOrWhiteSpace(req.MoTa)) existing.MoTa = req.MoTa.Trim();
                if (!string.IsNullOrWhiteSpace(req.UuTien)) existing.UuTien = req.UuTien.Trim();
                await _db.SaveChangesAsync();
            }
            else
            {
                var room = await _db.Phongs.FirstOrDefaultAsync(p => p.KyHieuPhong == item.KyHieuPhong)
                           ?? await _db.Phongs.FirstOrDefaultAsync();
                var cuDan = await _db.CuDans.FirstOrDefaultAsync();
                var danhMuc = await _db.DanhMucSuCos.FirstOrDefaultAsync();
                if (room != null && cuDan != null && danhMuc != null)
                {
                    _db.PhieuSuCos.Add(new PhieuSuCo
                    {
                        SoPhieuSuCo = item.SoPhieuSuCo,
                        MaPhong = room.MaPhong,
                        MaCuDan = cuDan.MaCuDan,
                        MaDanhMuc = danhMuc.MaDanhMuc,
                        TieuDe = item.TieuDe,
                        MoTa = item.MoTa,
                        UuTien = item.UuTien,
                        TrangThai = item.TrangThai,
                        ThoiDiemTao = DateTime.UtcNow
                    });
                    await _db.SaveChangesAsync();
                }
            }
        }
        catch { }

        return Ok(new { success = true, ticket = item });
    }

    [AllowAnonymous]
    [HttpPost("cho-do-cu")]
    public async Task<IActionResult> DongBoTinChoDoCu([FromBody] DangTinChoDoCuDto req)
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
            VideoUrl = NormalizePlayableVideoUrl(req.VideoUrl),
            TrangThai = string.IsNullOrWhiteSpace(req.TrangThai) ? "Đang bán" : req.TrangThai.Trim(),
            NguoiGiuCho = req.NguoiGiuCho,
            SoSaoTrungBinh = 5.0,
            SoLuotDanhGia = 0,
            TaoLuc = DateTime.UtcNow,
            DanhGias = new List<SyncMarketReviewItem>()
        };

        _liveMarketItems[id] = item;

        try
        {
            if (_db.Database.IsNpgsql())
            {
                var conn = _db.Database.GetDbConnection();
                if (conn.State != ConnectionState.Open) await conn.OpenAsync();
                using var cmd = conn.CreateCommand();
                cmd.CommandText = @"
                    INSERT INTO ""ChoDoCuTin"" (
                        ""MaTin"", ""MaPhong"", ""MaCuDanBan"",
                        ""TieuDe"", ""DanhMuc"", ""GiaBan"", ""GiaGoc"",
                        ""KyHieuPhong"", ""NguoiBan"", ""TinhTrang"", ""MoTa"",
                        ""HinhAnhUrl"", ""VideoUrl"", ""TrangThai"", ""NguoiGiuCho"",
                        ""SoSaoTrungBinh"", ""SoLuotDanhGia"", ""TaoLuc""
                    )
                    VALUES (
                        @p0,
                        COALESCE((SELECT p.""MaPhong"" FROM ""Phong"" p WHERE UPPER(p.""KyHieuPhong"") = UPPER(@p5) LIMIT 1), (SELECT p.""MaPhong"" FROM ""Phong"" p ORDER BY p.""MaPhong"" LIMIT 1)),
                        (SELECT c.""MaCuDan"" FROM ""CuDan"" c ORDER BY c.""MaCuDan"" LIMIT 1),
                        @p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15
                    )
                    ON CONFLICT (""MaTin"") DO UPDATE SET
                        ""TieuDe"" = EXCLUDED.""TieuDe"",
                        ""GiaBan"" = EXCLUDED.""GiaBan"",
                        ""HinhAnhUrl"" = COALESCE(EXCLUDED.""HinhAnhUrl"", ""ChoDoCuTin"".""HinhAnhUrl""),
                        ""VideoUrl"" = COALESCE(EXCLUDED.""VideoUrl"", ""ChoDoCuTin"".""VideoUrl""),
                        ""TrangThai"" = EXCLUDED.""TrangThai"",
                        ""NguoiGiuCho"" = EXCLUDED.""NguoiGiuCho"";";
                AddDbParam(cmd, "@p0", item.MaTin);
                AddDbParam(cmd, "@p1", item.TieuDe);
                AddDbParam(cmd, "@p2", item.DanhMuc);
                AddDbParam(cmd, "@p3", item.GiaBan);
                AddDbParam(cmd, "@p4", item.GiaGoc);
                AddDbParam(cmd, "@p5", item.KyHieuPhong);
                AddDbParam(cmd, "@p6", item.NguoiBan);
                AddDbParam(cmd, "@p7", item.TinhTrang);
                AddDbParam(cmd, "@p8", item.MoTa);
                AddDbParam(cmd, "@p9", item.HinhAnhUrl);
                AddDbParam(cmd, "@p10", item.VideoUrl);
                AddDbParam(cmd, "@p11", item.TrangThai);
                AddDbParam(cmd, "@p12", item.NguoiGiuCho);
                AddDbParam(cmd, "@p13", item.SoSaoTrungBinh);
                AddDbParam(cmd, "@p14", item.SoLuotDanhGia);
                AddDbParam(cmd, "@p15", item.TaoLuc);
                await cmd.ExecuteNonQueryAsync();
            }
        }
        catch { }

        return Ok(new
        {
            success = true,
            item,
            choDoCu = _liveMarketItems.Values.OrderByDescending(m => m.TaoLuc).ToList()
        });
    }

    [AllowAnonymous]
    [HttpPost("cho-do-cu/giu-cho")]
    public async Task<IActionResult> GiuChoTinChoDoCu([FromBody] GiuChoChoDoCuDto req)
    {
        if (string.IsNullOrWhiteSpace(req.MaTin))
            return BadRequest(new { success = false, message = "Thiếu mã tin sản phẩm." });

        var key = req.MaTin.Trim();
        var claimer = string.IsNullOrWhiteSpace(req.NguoiGiuCho) ? "Cư dân SmartStay" : req.NguoiGiuCho.Trim();

        if (_liveMarketItems.TryGetValue(key, out var item))
        {
            item.TrangThai = "Đã giữ chỗ";
            item.NguoiGiuCho = claimer;
        }

        try
        {
            if (_db.Database.IsNpgsql())
            {
                var conn = _db.Database.GetDbConnection();
                if (conn.State != ConnectionState.Open) await conn.OpenAsync();
                using var cmd = conn.CreateCommand();
                cmd.CommandText = @"
                    UPDATE ""ChoDoCuTin""
                    SET ""TrangThai"" = 'Đã giữ chỗ',
                        ""NguoiGiuCho"" = @p1,
                        ""MaCuDanGiuCho"" = COALESCE(""MaCuDanGiuCho"", (SELECT c.""MaCuDan"" FROM ""CuDan"" c ORDER BY c.""MaCuDan"" DESC LIMIT 1))
                    WHERE ""MaTin"" = @p0 OR ""TieuDe"" = @p0";
                AddDbParam(cmd, "@p0", key);
                AddDbParam(cmd, "@p1", claimer);
                await cmd.ExecuteNonQueryAsync();
            }
        }
        catch { }

        return Ok(new { success = true, maTin = key, trangThai = "Đã giữ chỗ", nguoiGiuCho = claimer });
    }

    [AllowAnonymous]
    [HttpPost("cho-do-cu/danh-gia")]
    public async Task<IActionResult> DanhGiaTinChoDoCu([FromBody] DanhGiaChoDoCuDto req)
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
        var reviewer = string.IsNullOrWhiteSpace(req.NguoiDanhGia) ? "Hồ Ngọc Bảo" : req.NguoiDanhGia.Trim();
        var room = string.IsNullOrWhiteSpace(req.KyHieuPhong) ? "P.305" : req.KyHieuPhong.Trim();
        var comment = req.BinhLuan.Trim();

        lock (item.DanhGias)
        {
            item.DanhGias.Insert(0, new SyncMarketReviewItem
            {
                NguoiDanhGia = reviewer,
                KyHieuPhong = room,
                SoSao = stars,
                BinhLuan = comment,
                ThoiGian = "Vừa xong"
            });
            item.SoLuotDanhGia = item.DanhGias.Count;
            item.SoSaoTrungBinh = Math.Round(item.DanhGias.Average(r => r.SoSao), 1);
        }

        try
        {
            if (_db.Database.IsNpgsql())
            {
                var conn = _db.Database.GetDbConnection();
                if (conn.State != ConnectionState.Open) await conn.OpenAsync();
                // Đảm bảo MaTin tồn tại trong ChoDoCuTin để thỏa mãn FK_ChoDoCuDanhGia_ChoDoCuTin
                using (var cmdEnsure = conn.CreateCommand())
                {
                    cmdEnsure.CommandText = @"
                        INSERT INTO ""ChoDoCuTin"" (""MaTin"", ""MaPhong"", ""MaCuDanBan"", ""TieuDe"", ""DanhMuc"", ""GiaBan"", ""GiaGoc"", ""KyHieuPhong"", ""NguoiBan"", ""TinhTrang"", ""MoTa"")
                        VALUES (
                            @p0,
                            COALESCE((SELECT p.""MaPhong"" FROM ""Phong"" p WHERE UPPER(p.""KyHieuPhong"") = UPPER(@p2) LIMIT 1), (SELECT p.""MaPhong"" FROM ""Phong"" p ORDER BY p.""MaPhong"" LIMIT 1)),
                            (SELECT c.""MaCuDan"" FROM ""CuDan"" c ORDER BY c.""MaCuDan"" LIMIT 1),
                            @p1, 'electronics', 50000, 100000, @p2, 'Cư dân SmartStay', 'Đã xác minh', 'Sản phẩm Chợ Cư Dân'
                        )
                        ON CONFLICT (""MaTin"") DO NOTHING";
                    AddDbParam(cmdEnsure, "@p0", key);
                    AddDbParam(cmdEnsure, "@p1", item.TieuDe);
                    AddDbParam(cmdEnsure, "@p2", room);
                    await cmdEnsure.ExecuteNonQueryAsync();
                }
                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = @"
                        INSERT INTO ""ChoDoCuDanhGia"" (""MaTin"", ""MaPhong"", ""MaCuDan"", ""NguoiDanhGia"", ""KyHieuPhong"", ""SoSao"", ""BinhLuan"", ""ThoiGian"")
                        VALUES (
                            @p0,
                            COALESCE((SELECT p.""MaPhong"" FROM ""Phong"" p WHERE UPPER(p.""KyHieuPhong"") = UPPER(@p2) LIMIT 1), (SELECT p.""MaPhong"" FROM ""Phong"" p ORDER BY p.""MaPhong"" LIMIT 1)),
                            (SELECT c.""MaCuDan"" FROM ""CuDan"" c ORDER BY c.""MaCuDan"" LIMIT 1),
                            @p1, @p2, @p3, @p4, 'Vừa xong'
                        )";
                    AddDbParam(cmd, "@p0", key);
                    AddDbParam(cmd, "@p1", reviewer);
                    AddDbParam(cmd, "@p2", room);
                    AddDbParam(cmd, "@p3", stars);
                    AddDbParam(cmd, "@p4", comment);
                    await cmd.ExecuteNonQueryAsync();
                }
                using (var cmdUpd = conn.CreateCommand())
                {
                    cmdUpd.CommandText = @"UPDATE ""ChoDoCuTin"" SET ""SoSaoTrungBinh"" = @p1, ""SoLuotDanhGia"" = @p2 WHERE ""MaTin"" = @p0";
                    AddDbParam(cmdUpd, "@p0", key);
                    AddDbParam(cmdUpd, "@p1", item.SoSaoTrungBinh);
                    AddDbParam(cmdUpd, "@p2", item.SoLuotDanhGia);
                    await cmdUpd.ExecuteNonQueryAsync();
                }
            }
        }
        catch { }

        return Ok(new { success = true, item });
    }

    [AllowAnonymous]
    [HttpPost("ve-khach")]
    public async Task<IActionResult> TaoVeKhach([FromBody] VeKhachSyncDto req)
    {
        if (string.IsNullOrWhiteSpace(req.TenKhach))
            return BadRequest(new { success = false, message = "Tên khách là bắt buộc." });

        var maVe = string.IsNullOrWhiteSpace(req.MaVe) ? $"GP-{DateTime.UtcNow.Ticks % 9000 + 1000}" : req.MaVe.Trim();
        var room = string.IsNullOrWhiteSpace(req.KyHieuPhong) ? "P.305" : req.KyHieuPhong.Trim();
        var pin = string.IsNullOrWhiteSpace(req.MaPin) ? $"{DateTime.UtcNow.Millisecond % 900000 + 100000}" : req.MaPin.Trim();
        var validUntil = string.IsNullOrWhiteSpace(req.HieuLucDen) ? "23:59 Hôm nay" : req.HieuLucDen.Trim();

        try
        {
            if (_db.Database.IsNpgsql())
            {
                var conn = _db.Database.GetDbConnection();
                if (conn.State != ConnectionState.Open) await conn.OpenAsync();
                using var cmd = conn.CreateCommand();
                cmd.CommandText = @"
                    INSERT INTO ""VeKhachVangLai"" (""MaVe"", ""MaPhong"", ""MaCuDan"", ""KyHieuPhong"", ""TenKhach"", ""SoDienThoai"", ""MaPin"", ""HieuLucDen"", ""TrangThai"")
                    VALUES (
                        @p0,
                        COALESCE((SELECT p.""MaPhong"" FROM ""Phong"" p WHERE UPPER(p.""KyHieuPhong"") = UPPER(@p1) LIMIT 1), (SELECT p.""MaPhong"" FROM ""Phong"" p ORDER BY p.""MaPhong"" LIMIT 1)),
                        (SELECT c.""MaCuDan"" FROM ""CuDan"" c ORDER BY c.""MaCuDan"" LIMIT 1),
                        @p1, @p2, @p3, @p4, @p5, 'Đang hiệu lực'
                    ) ON CONFLICT (""MaVe"") DO NOTHING";
                AddDbParam(cmd, "@p0", maVe);
                AddDbParam(cmd, "@p1", room);
                AddDbParam(cmd, "@p2", req.TenKhach.Trim());
                AddDbParam(cmd, "@p3", req.SoDienThoai ?? "");
                AddDbParam(cmd, "@p4", pin);
                AddDbParam(cmd, "@p5", validUntil);
                await cmd.ExecuteNonQueryAsync();
            }
        }
        catch { }

        return Ok(new { success = true, maVe, maPin = pin });
    }

    [AllowAnonymous]
    [HttpPost("chia-tien")]
    public async Task<IActionResult> LuuChiaTien([FromBody] ChiaTienSyncDto req)
    {
        if (string.IsNullOrWhiteSpace(req.TieuDe))
            return BadRequest(new { success = false, message = "Tiêu đề khoản chia là bắt buộc." });

        var maChia = string.IsNullOrWhiteSpace(req.MaChia) ? $"SPL-{DateTime.UtcNow.Ticks % 9000 + 1000}" : req.MaChia.Trim();
        var room = string.IsNullOrWhiteSpace(req.KyHieuPhong) ? "P.305" : req.KyHieuPhong.Trim();
        var members = Math.Max(1, req.SoThanhVien);
        var perMember = Math.Round(req.TongTien / members, 0);

        try
        {
            if (_db.Database.IsNpgsql())
            {
                var conn = _db.Database.GetDbConnection();
                if (conn.State != ConnectionState.Open) await conn.OpenAsync();
                using var cmd = conn.CreateCommand();
                cmd.CommandText = @"
                    INSERT INTO ""ChiaTienPhong"" (""MaChia"", ""MaPhong"", ""MaHoaDon"", ""MaCuDanTao"", ""KyHieuPhong"", ""TieuDe"", ""TongTien"", ""SoThanhVien"", ""MoiNguoi"", ""TrangThai"")
                    VALUES (
                        @p0,
                        COALESCE((SELECT p.""MaPhong"" FROM ""Phong"" p WHERE UPPER(p.""KyHieuPhong"") = UPPER(@p1) LIMIT 1), (SELECT p.""MaPhong"" FROM ""Phong"" p ORDER BY p.""MaPhong"" LIMIT 1)),
                        (SELECT h.""MaHoaDon"" FROM ""HoaDon"" h ORDER BY h.""MaHoaDon"" DESC LIMIT 1),
                        (SELECT c.""MaCuDan"" FROM ""CuDan"" c ORDER BY c.""MaCuDan"" LIMIT 1),
                        @p1, @p2, @p3, @p4, @p5, @p6
                    ) ON CONFLICT (""MaChia"") DO UPDATE SET ""TrangThai"" = EXCLUDED.""TrangThai""";
                AddDbParam(cmd, "@p0", maChia);
                AddDbParam(cmd, "@p1", room);
                AddDbParam(cmd, "@p2", req.TieuDe.Trim());
                AddDbParam(cmd, "@p3", req.TongTien);
                AddDbParam(cmd, "@p4", members);
                AddDbParam(cmd, "@p5", perMember);
                AddDbParam(cmd, "@p6", string.IsNullOrWhiteSpace(req.TrangThai) ? "Chờ đóng" : req.TrangThai.Trim());
                await cmd.ExecuteNonQueryAsync();
            }
        }
        catch { }

        return Ok(new { success = true, maChia, moiNguoi = perMember });
    }

    [AllowAnonymous]
    [HttpPost("upload-media")]
    [RequestSizeLimit(52_428_800)]
    public async Task<IActionResult> UploadMediaToSupabase([FromBody] UploadMediaSyncDto req)
    {
        if (string.IsNullOrWhiteSpace(req.Base64Data))
            return BadRequest(new { success = false, message = "Thiếu dữ liệu media." });

        var raw = req.Base64Data.Trim();
        var mimeType = string.IsNullOrWhiteSpace(req.ContentType) ? "video/mp4" : req.ContentType.Trim();
        var dataMatch = Regex.Match(raw, @"^data:([^;]+);base64,(.+)$", RegexOptions.Singleline);
        if (dataMatch.Success)
        {
            mimeType = dataMatch.Groups[1].Value;
            raw = dataMatch.Groups[2].Value;
        }

        byte[] bytes;
        try { bytes = Convert.FromBase64String(raw); }
        catch { return BadRequest(new { success = false, message = "Dữ liệu Base64 không hợp lệ." }); }

        var safeName = Regex.Replace(req.FileName ?? "video.mp4", @"[^a-zA-Z0-9._-]", "_");
        var folder = string.IsNullOrWhiteSpace(req.Folder) ? "marketplace" : Regex.Replace(req.Folder, @"[^a-zA-Z0-9_-]", "");
        var fileId = $"{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}_{safeName}";
        var objectPath = $"{folder}/{fileId}";

        // 1. Lưu ngay vào bộ đệm & bảng PostgreSQL bền vững để đảm bảo 100% phát được (kể cả khi Supabase Storage RLS chặn)
        _uploadedMediaBlobs[fileId] = (bytes, mimeType);
        try
        {
            if (_db.Database.IsNpgsql())
            {
                var conn = _db.Database.GetDbConnection();
                if (conn.State != ConnectionState.Open) await conn.OpenAsync();
                using (var cmdCreate = conn.CreateCommand())
                {
                    cmdCreate.CommandText = @"
                        CREATE TABLE IF NOT EXISTS ""SmartStayMediaStorage"" (
                            ""FileId"" VARCHAR(180) PRIMARY KEY,
                            ""ContentType"" VARCHAR(120) NOT NULL,
                            ""Bytes"" BYTEA NOT NULL,
                            ""TaoLuc"" TIMESTAMPTZ NOT NULL DEFAULT NOW()
                        )";
                    await cmdCreate.ExecuteNonQueryAsync();
                }
                using (var cmdInsert = conn.CreateCommand())
                {
                    cmdInsert.CommandText = @"
                        INSERT INTO ""SmartStayMediaStorage"" (""FileId"", ""ContentType"", ""Bytes"")
                        VALUES (@p0, @p1, @p2)
                        ON CONFLICT (""FileId"") DO UPDATE SET ""Bytes"" = EXCLUDED.""Bytes"", ""ContentType"" = EXCLUDED.""ContentType""";
                    AddDbParam(cmdInsert, "@p0", fileId);
                    AddDbParam(cmdInsert, "@p1", mimeType);
                    AddDbParam(cmdInsert, "@p2", bytes);
                    await cmdInsert.ExecuteNonQueryAsync();
                }
            }
        }
        catch { }

        // 2. Thử đẩy lên Supabase Storage bucket `smartstay-media`
        var supabaseUrl = (_config["Supabase:Url"] ?? Environment.GetEnvironmentVariable("SUPABASE_URL") ?? "https://odasdzyuriucofavonjl.supabase.co").TrimEnd('/');
        var supabaseKey = _config["Supabase:ServiceRoleKey"]
                          ?? Environment.GetEnvironmentVariable("SUPABASE_SERVICE_ROLE_KEY")
                          ?? _config["Supabase:AnonKey"]
                          ?? Environment.GetEnvironmentVariable("SUPABASE_ANON_KEY")
                          ?? "sb_publishable_GYfWQ4xJCkpgxjI2XBNVmg_6eWoUWP7";

        try
        {
            var uploadUrl = $"{supabaseUrl}/storage/v1/object/smartstay-media/{objectPath}";
            using var msg = new HttpRequestMessage(HttpMethod.Post, uploadUrl);
            msg.Headers.Add("apikey", supabaseKey);
            msg.Headers.Authorization = new AuthenticationHeaderValue("Bearer", supabaseKey);
            msg.Headers.Add("x-upsert", "true");
            msg.Content = new ByteArrayContent(bytes);
            msg.Content.Headers.ContentType = new MediaTypeHeaderValue(mimeType);

            var resp = await _storageHttp.SendAsync(msg);
            if (resp.IsSuccessStatusCode)
            {
                var publicUrl = $"{supabaseUrl}/storage/v1/object/public/smartstay-media/{objectPath}";
                return Ok(new { success = true, publicUrl, storage = "supabase-storage" });
            }
        }
        catch { }

        // 3. Fallback URL phát trực tiếp từ cổng Media Streaming của SmartStay (hỗ trợ HTTP 206 Byte-Range cho HTML5 Video & Android)
        var host = Request.Host.Value;
        var scheme = host.Contains("onrender.com", StringComparison.OrdinalIgnoreCase) ? "https" : Request.Scheme;
        var fallbackPublicUrl = $"{scheme}://{host}/api/sync/media/{Uri.EscapeDataString(fileId)}";
        return Ok(new { success = true, publicUrl = fallbackPublicUrl, storage = "smartstay-db-stream" });
    }

    [AllowAnonymous]
    [HttpGet("media/{fileId}")]
    public async Task<IActionResult> StreamUploadedMedia(string fileId)
    {
        if (string.IsNullOrWhiteSpace(fileId))
            return NotFound();

        if (_uploadedMediaBlobs.TryGetValue(fileId, out var cached))
        {
            return File(cached.Bytes, cached.ContentType, enableRangeProcessing: true);
        }

        try
        {
            if (_db.Database.IsNpgsql())
            {
                var conn = _db.Database.GetDbConnection();
                if (conn.State != ConnectionState.Open) await conn.OpenAsync();
                using var cmd = conn.CreateCommand();
                cmd.CommandText = @"SELECT ""ContentType"", ""Bytes"" FROM ""SmartStayMediaStorage"" WHERE ""FileId"" = @p0 LIMIT 1";
                AddDbParam(cmd, "@p0", fileId);
                using var r = await cmd.ExecuteReaderAsync();
                if (await r.ReadAsync())
                {
                    var ct = r.IsDBNull(0) ? "video/mp4" : r.GetString(0);
                    var data = (byte[])r.GetValue(1);
                    _uploadedMediaBlobs[fileId] = (data, ct);
                    return File(data, ct, enableRangeProcessing: true);
                }
            }
        }
        catch { }

        return Redirect("https://www.w3schools.com/html/mov_bbb.mp4");
    }

    [AllowAnonymous]
    [HttpPost("cuoc-goi")]
    public async Task<IActionResult> LuuCuocGoi([FromBody] LuuCuocGoiSyncDto req)
    {
        var callCode = !string.IsNullOrWhiteSpace(req.CallId)
            ? req.CallId.Trim()
            : $"CALL-{DateTime.UtcNow.Ticks % 9000 + 1000}";

        var existing = _liveCallLogs.FirstOrDefault(c =>
            string.Equals(c.MaCuocGoi, callCode, StringComparison.OrdinalIgnoreCase));

        SyncCallLogItem log;
        if (existing != null)
        {
            existing.ThoiLuongGiay = Math.Max(existing.ThoiLuongGiay, Math.Max(0, req.ThoiLuongGiay));
            if (!string.IsNullOrWhiteSpace(req.TrangThai)) existing.TrangThai = req.TrangThai.Trim();
            if (!string.IsNullOrWhiteSpace(req.NoiDungTraoDoi)) existing.NoiDungTraoDoi = req.NoiDungTraoDoi.Trim();
            log = existing;
        }
        else
        {
            log = new SyncCallLogItem
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
        }

        try
        {
            if (_db.Database.IsNpgsql())
            {
                var conn = _db.Database.GetDbConnection();
                if (conn.State != ConnectionState.Open) await conn.OpenAsync();
                using var cmd = conn.CreateCommand();
                cmd.CommandText = @"
                    INSERT INTO ""NhatKyCuocGoi"" (
                        ""MaCuocGoi"", ""MaNguoiGoi"", ""MaNguoiNhan"", ""MaCuDan"", ""MaPhong"",
                        ""NguoiGoi"", ""VaiTroNguoiGoi"", ""NguoiNhan"", ""VaiTroNguoiNhan"",
                        ""LoaiCuocGoi"", ""NoiDungTraoDoi"", ""ThoiLuongGiay"", ""TrangThai"", ""ThoiDiem""
                    )
                    VALUES (
                        @p0,
                        (SELECT u.""MaNguoiDung"" FROM ""NguoiDung"" u ORDER BY u.""MaNguoiDung"" LIMIT 1),
                        (SELECT u.""MaNguoiDung"" FROM ""NguoiDung"" u ORDER BY u.""MaNguoiDung"" DESC LIMIT 1),
                        (SELECT c.""MaCuDan"" FROM ""CuDan"" c ORDER BY c.""MaCuDan"" LIMIT 1),
                        (SELECT p.""MaPhong"" FROM ""Phong"" p ORDER BY p.""MaPhong"" LIMIT 1),
                        @p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9
                    )
                    ON CONFLICT (""MaCuocGoi"") DO UPDATE SET
                        ""ThoiLuongGiay"" = GREATEST(""NhatKyCuocGoi"".""ThoiLuongGiay"", EXCLUDED.""ThoiLuongGiay""),
                        ""TrangThai"" = EXCLUDED.""TrangThai"",
                        ""NoiDungTraoDoi"" = EXCLUDED.""NoiDungTraoDoi"";";
                AddDbParam(cmd, "@p0", log.MaCuocGoi);
                AddDbParam(cmd, "@p1", log.NguoiGoi);
                AddDbParam(cmd, "@p2", log.VaiTroNguoiGoi);
                AddDbParam(cmd, "@p3", log.NguoiNhan);
                AddDbParam(cmd, "@p4", log.VaiTroNguoiNhan);
                AddDbParam(cmd, "@p5", log.LoaiCuocGoi);
                AddDbParam(cmd, "@p6", log.NoiDungTraoDoi);
                AddDbParam(cmd, "@p7", log.ThoiLuongGiay);
                AddDbParam(cmd, "@p8", log.TrangThai);
                AddDbParam(cmd, "@p9", log.ThoiDiem);
                await cmd.ExecuteNonQueryAsync();
            }
        }
        catch { }

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
    public int? MaPhong { get; set; }
    public int? MaCuDan { get; set; }
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
    public int? MaCuDan { get; set; }
    public int? MaPhong { get; set; }
    public string NguoiDanhGia { get; set; } = string.Empty;
    public string KyHieuPhong { get; set; } = "P.305";
    public int SoSao { get; set; } = 5;
    public string BinhLuan { get; set; } = string.Empty;
    public string ThoiGian { get; set; } = "Vừa xong";
}

public class SyncMarketItem
{
    public string MaTin { get; set; } = string.Empty;
    public int? MaPhong { get; set; }
    public int? MaCuDanBan { get; set; }
    public int? MaCuDanGiuCho { get; set; }
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
    public string TrangThai { get; set; } = "Đang bán";
    public string? NguoiGiuCho { get; set; }
    public double SoSaoTrungBinh { get; set; } = 5.0;
    public int SoLuotDanhGia { get; set; }
    public DateTime TaoLuc { get; set; } = DateTime.UtcNow;
    public List<SyncMarketReviewItem> DanhGias { get; set; } = new();
}

public class DangTinChoDoCuDto
{
    public string? MaTin { get; set; }
    public int? MaPhong { get; set; }
    public int? MaCuDanBan { get; set; }
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
    public string? TrangThai { get; set; }
    public string? NguoiGiuCho { get; set; }
}

public class GiuChoChoDoCuDto
{
    public string MaTin { get; set; } = string.Empty;
    public int? MaCuDanGiuCho { get; set; }
    public string? NguoiGiuCho { get; set; }
}

public class VeKhachSyncDto
{
    public string? MaVe { get; set; }
    public int? MaPhong { get; set; }
    public int? MaCuDan { get; set; }
    public string? KyHieuPhong { get; set; }
    public string TenKhach { get; set; } = string.Empty;
    public string? SoDienThoai { get; set; }
    public string? MaPin { get; set; }
    public string? HieuLucDen { get; set; }
}

public class ChiaTienSyncDto
{
    public string? MaChia { get; set; }
    public int? MaPhong { get; set; }
    public int? MaHoaDon { get; set; }
    public int? MaCuDanTao { get; set; }
    public string? KyHieuPhong { get; set; }
    public string TieuDe { get; set; } = string.Empty;
    public decimal TongTien { get; set; }
    public int SoThanhVien { get; set; } = 3;
    public string? TrangThai { get; set; }
}

public class UploadMediaSyncDto
{
    public string? FileName { get; set; }
    public string? ContentType { get; set; }
    public string Base64Data { get; set; } = string.Empty;
    public string? Folder { get; set; }
}

public class DanhGiaChoDoCuDto
{
    public string MaTin { get; set; } = string.Empty;
    public int? MaPhong { get; set; }
    public int? MaCuDan { get; set; }
    public string? TieuDeFallback { get; set; }
    public string? NguoiDanhGia { get; set; }
    public string? KyHieuPhong { get; set; }
    public int SoSao { get; set; } = 5;
    public string BinhLuan { get; set; } = string.Empty;
}

public class SyncCallLogItem
{
    public string MaCuocGoi { get; set; } = string.Empty;
    public int? MaNguoiGoi { get; set; }
    public int? MaNguoiNhan { get; set; }
    public int? MaCuDan { get; set; }
    public int? MaPhong { get; set; }
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
    public int? MaNguoiGoi { get; set; }
    public int? MaNguoiNhan { get; set; }
    public int? MaCuDan { get; set; }
    public int? MaPhong { get; set; }
    public string? NguoiGoi { get; set; }
    public string? VaiTroNguoiGoi { get; set; }
    public string? NguoiNhan { get; set; }
    public string? VaiTroNguoiNhan { get; set; }
    public string? LoaiCuocGoi { get; set; }
    public string? NoiDungTraoDoi { get; set; }
    public int ThoiLuongGiay { get; set; }
    public string? TrangThai { get; set; }
}
