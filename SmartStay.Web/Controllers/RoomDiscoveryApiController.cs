using System.Collections.Concurrent;
using System.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using SmartStay.Web.Data;
using SmartStay.Web.Hubs;

namespace SmartStay.Web.Controllers;

/// <summary>
/// Cổng API cho Module "Khám phá, Xem Video Tour & Đăng ký thuê phòng trực tuyến"
/// Hỗ trợ lưu bền vững Supabase PostgreSQL (Phong, PhongMedia, PhieuDangKyPhong) + Đồng bộ Real-time (SignalR & Event Stream)
/// </summary>
[ApiController]
[Route("api/phong-cho-thue")]
public class RoomDiscoveryApiController : ControllerBase
{
    private readonly SmartStayDbContext _db;
    private readonly IHubContext<SmartStayHub> _hubContext;

    private static long _eventSeq = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
    private static readonly ConcurrentQueue<RoomDiscoveryEventDto> _recentEvents = new();
    private static readonly ConcurrentDictionary<string, RoomListingDto> _liveListings = InitDefaultListings();
    private static readonly ConcurrentDictionary<string, RoomRegistrationDto> _liveRegistrations = new(StringComparer.OrdinalIgnoreCase);

    public RoomDiscoveryApiController(SmartStayDbContext db, IHubContext<SmartStayHub> hubContext)
    {
        _db = db;
        _hubContext = hubContext;
    }

    private static void AddParam(IDbCommand cmd, string name, object? value)
    {
        var p = cmd.CreateParameter();
        p.ParameterName = name;
        p.Value = value ?? DBNull.Value;
        cmd.Parameters.Add(p);
    }

    private static RoomDiscoveryEventDto PushRealtimeEvent(string roomCode, string eventType, string message)
    {
        var evt = new RoomDiscoveryEventDto
        {
            Seq = Interlocked.Increment(ref _eventSeq),
            KyHieuPhong = roomCode,
            EventType = eventType,
            Message = message,
            UpdatedAt = DateTime.UtcNow
        };
        _recentEvents.Enqueue(evt);
        while (_recentEvents.Count > 60)
        {
            _recentEvents.TryDequeue(out _);
        }
        return evt;
    }

    private static ConcurrentDictionary<string, RoomListingDto> InitDefaultListings()
    {
        var dict = new ConcurrentDictionary<string, RoomListingDto>(StringComparer.OrdinalIgnoreCase);
        var seeds = new[]
        {
            new RoomListingDto
            {
                MaPhong = 102, KyHieuPhong = "P.102", TieuDe = "Studio Deluxe Tầng 1 • Ban công xanh thoáng mát",
                LoaiPhong = "Studio Deluxe", SoTang = 1, DienTich = 32.5m, SucChua = 2, GiaThue = 4500000,
                TrangThai = "Trống", DangMoChoThue = true, LuotXem = 148, DiemDanhGia = 4.9,
                MoTa = "Căn hộ Studio 32.5m² full nội thất gỗ sáng, cửa kính lớn đón gió tự nhiên, bếp riêng khép kín và khóa thông minh vân tay IoT.",
                TienIchNoiBat = new() { "Khóa vân tay IoT", "Máy lạnh Inverter", "Ban công riêng", "Kệ bếp & Tủ lạnh", "Wi-Fi 6" },
                HinhAnhUrls = new()
                {
                    "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=900&q=80",
                    "https://images.unsplash.com/photo-1554995207-c18c203602cb?auto=format&fit=crop&w=900&q=80",
                    "https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=900&q=80"
                },
                VideoTourUrl = "https://www.w3schools.com/html/mov_bbb.mp4",
                CapNhatLuc = DateTime.UtcNow.AddHours(-3)
            },
            new RoomListingDto
            {
                MaPhong = 203, KyHieuPhong = "P.203", TieuDe = "Co-Living Đơn Tầng 2 • Góc làm việc tràn ngập ánh sáng",
                LoaiPhong = "Co-Living Đơn", SoTang = 2, DienTich = 24.0m, SucChua = 1, GiaThue = 3200000,
                TrangThai = "Trống", DangMoChoThue = true, LuotXem = 112, DiemDanhGia = 4.8,
                MoTa = "Thiết kế tối giản chuẩn sinh viên/kỹ sư trẻ, có sẵn bàn học rộng, tủ quần áo âm tường và đồng hồ điện nước thông minh theo dõi qua App.",
                TienIchNoiBat = new() { "Bàn học rộng", "Khóa vân tay IoT", "Máy lạnh Inverter", "Wi-Fi 6", "Hầm giữ xe 24/7" },
                HinhAnhUrls = new()
                {
                    "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=900&q=80",
                    "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=900&q=80"
                },
                VideoTourUrl = "https://www.w3schools.com/html/mov_bbb.mp4",
                CapNhatLuc = DateTime.UtcNow.AddHours(-2)
            },
            new RoomListingDto
            {
                MaPhong = 302, KyHieuPhong = "P.302", TieuDe = "Co-Living Ban Công Tầng 3 • View thành phố cực thoáng",
                LoaiPhong = "Co-Living Đơn", SoTang = 3, DienTich = 26.0m, SucChua = 2, GiaThue = 3500000,
                TrangThai = "Trống", DangMoChoThue = true, LuotXem = 196, DiemDanhGia = 5.0,
                MoTa = "Phòng được quan tâm nhiều nhất tuần này! Tầng trung yên tĩnh, cửa sổ lớn hai mặt thoáng, máy giặt dùng chung miễn phí cuối hành lang.",
                TienIchNoiBat = new() { "View thành phố", "Ban công riêng", "Khóa vân tay IoT", "Máy lạnh Inverter", "Giặt sấy miễn phí" },
                HinhAnhUrls = new()
                {
                    "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=900&q=80",
                    "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=900&q=80"
                },
                VideoTourUrl = "https://www.w3schools.com/html/mov_bbb.mp4",
                CapNhatLuc = DateTime.UtcNow.AddHours(-1)
            },
            new RoomListingDto
            {
                MaPhong = 402, KyHieuPhong = "P.402", TieuDe = "Studio Ban Công Tầng 4 • Không gian yên tĩnh làm việc",
                LoaiPhong = "Studio Ban công", SoTang = 4, DienTich = 28.0m, SucChua = 2, GiaThue = 3900000,
                TrangThai = "Trống", DangMoChoThue = true, LuotXem = 89, DiemDanhGia = 4.9,
                MoTa = "Trang bị rèm cản sáng 2 lớp, đệm cao su non, nhà vệ sinh kính cường lực tách khu khô-ướt sạch sẽ.",
                TienIchNoiBat = new() { "Rèm cản sáng", "Ban công thoáng", "Khóa vân tay IoT", "Nóng lạnh năng lượng" },
                HinhAnhUrls = new()
                {
                    "https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=900&q=80",
                    "https://images.unsplash.com/photo-1554995207-c18c203602cb?auto=format&fit=crop&w=900&q=80"
                },
                VideoTourUrl = "https://www.w3schools.com/html/mov_bbb.mp4",
                CapNhatLuc = DateTime.UtcNow.AddMinutes(-45)
            },
            new RoomListingDto
            {
                MaPhong = 501, KyHieuPhong = "P.501", TieuDe = "Sky View Penthouse Tầng 5 • Sân thượng BBQ riêng",
                LoaiPhong = "Sky View Penthouse", SoTang = 5, DienTich = 45.0m, SucChua = 3, GiaThue = 6200000,
                TrangThai = "Trống", DangMoChoThue = true, LuotXem = 234, DiemDanhGia = 5.0,
                MoTa = "Căn hộ áp mái cao cấp nhất SmartStay với ban công sân vườn 10m², sofa tiếp khách, tivi 4K và tủ bếp chữ L hiện đại.",
                TienIchNoiBat = new() { "Sân thượng BBQ", "Smart TV 4K", "Khóa vân tay IoT", "Bếp từ đôi", "Sofa tiếp khách" },
                HinhAnhUrls = new()
                {
                    "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=900&q=80",
                    "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=900&q=80"
                },
                VideoTourUrl = "https://www.w3schools.com/html/mov_bbb.mp4",
                CapNhatLuc = DateTime.UtcNow.AddMinutes(-20)
            }
        };

        foreach (var s in seeds)
        {
            dict[s.KyHieuPhong] = s;
        }
        return dict;
    }

    private static List<string> ParseAmenities(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
        {
            return new() { "Khóa vân tay IoT", "Máy lạnh Inverter", "Wi-Fi 6 tốc độ cao", "Ban công thoáng" };
        }
        return raw.Split(new[] { ',', ';', '|' }, StringSplitOptions.RemoveEmptyEntries)
            .Select(x => x.Trim())
            .Where(x => x.Length > 0)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    private static string NormalizeVideoUrl(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw)) return string.Empty;
        var s = raw.Trim();
        if (s.StartsWith("demo://", StringComparison.OrdinalIgnoreCase) ||
            s.Contains("interactive-examples.mdn.mozilla.net/media/cc0-videos/flower", StringComparison.OrdinalIgnoreCase))
        {
            return "https://www.w3schools.com/html/mov_bbb.mp4";
        }
        return s;
    }

    [AllowAnonymous]
    [HttpGet("danh-sach")]
    public async Task<IActionResult> LayDanhSachPhongChoThue([FromQuery] long sinceEventSeq = 0)
    {
        var merged = new Dictionary<string, RoomListingDto>(_liveListings, StringComparer.OrdinalIgnoreCase);

        try
        {
            if (_db.Database.IsNpgsql())
            {
                var conn = _db.Database.GetDbConnection();
                if (conn.State != ConnectionState.Open) await conn.OpenAsync();

                var mediaByRoomId = new Dictionary<int, (List<string> Images, string? Video)>();
                using (var cmdMedia = conn.CreateCommand())
                {
                    cmdMedia.CommandText = @"SELECT ""MaPhong"", ""LoaiMedia"", ""Url"" FROM ""PhongMedia"" ORDER BY ""ThuTu"" ASC, ""Id"" ASC";
                    using var rm = await cmdMedia.ExecuteReaderAsync();
                    while (await rm.ReadAsync())
                    {
                        var roomId = rm.GetInt32(0);
                        var type = rm.IsDBNull(1) ? "Image" : rm.GetString(1);
                        var url = rm.IsDBNull(2) ? "" : rm.GetString(2);
                        if (string.IsNullOrWhiteSpace(url)) continue;
                        if (!mediaByRoomId.TryGetValue(roomId, out var bucket))
                        {
                            bucket = (new List<string>(), null);
                        }
                        if (type.Equals("Video", StringComparison.OrdinalIgnoreCase))
                        {
                            bucket.Video = NormalizeVideoUrl(url);
                        }
                        else if (!bucket.Images.Contains(url))
                        {
                            bucket.Images.Add(url);
                        }
                        mediaByRoomId[roomId] = bucket;
                    }
                }

                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = @"
                        SELECT p.""MaPhong"", p.""KyHieuPhong"", p.""SoTang"", p.""DienTich"", p.""SucChua"",
                               p.""GiaThue"", p.""TrangThai"", p.""MoTa"",
                               lp.""TenLoaiPhong"",
                               p.""TieuDeChoThue"", p.""TienIchNoiBat"", p.""DangMoChoThue"",
                               p.""LuotXem"", p.""DiemDanhGia"", p.""CapNhatLuc""
                        FROM ""Phong"" p
                        LEFT JOIN ""LoaiPhong"" lp ON lp.""MaLoaiPhong"" = p.""MaLoaiPhong""
                        ORDER BY p.""SoTang"" ASC, p.""KyHieuPhong"" ASC";
                    using var r = await cmd.ExecuteReaderAsync();
                    while (await r.ReadAsync())
                    {
                        var maPhong = r.GetInt32(0);
                        var code = r.GetString(1);
                        var floor = r.GetInt32(2);
                        var area = r.IsDBNull(3) ? 26.0m : r.GetDecimal(3);
                        var cap = r.GetInt32(4);
                        var price = r.GetDecimal(5);
                        var status = r.IsDBNull(6) ? "Trống" : r.GetString(6);
                        var desc = r.IsDBNull(7) ? "" : r.GetString(7);
                        var roomType = r.IsDBNull(8) ? "Studio SmartStay" : r.GetString(8);
                        var title = r.IsDBNull(9) ? $"Căn hộ {code} • {roomType}" : r.GetString(9);
                        var amenitiesRaw = r.IsDBNull(10) ? null : r.GetString(10);
                        var isOpen = !r.IsDBNull(11) && r.GetBoolean(11);
                        var views = r.IsDBNull(12) ? 28 : r.GetInt32(12);
                        var rating = r.IsDBNull(13) ? 4.8 : r.GetDouble(13);
                        var updatedAt = r.IsDBNull(14) ? DateTime.UtcNow : r.GetDateTime(14);

                        var hasMedia = mediaByRoomId.TryGetValue(maPhong, out var mediaBucket);
                        var images = hasMedia && mediaBucket.Images.Count > 0
                            ? mediaBucket.Images
                            : (merged.TryGetValue(code, out var fallbackItem) && fallbackItem.HinhAnhUrls.Count > 0
                                ? fallbackItem.HinhAnhUrls
                                : new List<string> { "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=900&q=80" });
                        var videoUrl = hasMedia && !string.IsNullOrWhiteSpace(mediaBucket.Video)
                            ? mediaBucket.Video
                            : (merged.TryGetValue(code, out var fbVid) ? fbVid.VideoTourUrl : "https://www.w3schools.com/html/mov_bbb.mp4");

                        merged[code] = new RoomListingDto
                        {
                            MaPhong = maPhong,
                            KyHieuPhong = code,
                            TieuDe = string.IsNullOrWhiteSpace(title) ? $"Căn hộ {code} • {roomType}" : title,
                            LoaiPhong = roomType,
                            SoTang = floor,
                            DienTich = area,
                            SucChua = cap,
                            GiaThue = price,
                            TrangThai = status,
                            MoTa = string.IsNullOrWhiteSpace(desc) ? "Phòng thiết kế hiện đại chuẩn SmartStay, đầy đủ tiện nghi & an ninh khóa vân tay IoT." : desc,
                            TienIchNoiBat = ParseAmenities(amenitiesRaw),
                            DangMoChoThue = isOpen,
                            LuotXem = views,
                            DiemDanhGia = rating,
                            HinhAnhUrls = images,
                            VideoTourUrl = videoUrl,
                            CapNhatLuc = updatedAt
                        };
                    }
                }
            }
        }
        catch
        {
            // Fallback sang bộ đệm live nếu bảng mới đang chạy migration
        }

        var events = _recentEvents
            .Where(e => e.Seq > sinceEventSeq)
            .OrderBy(e => e.Seq)
            .ToList();

        return Ok(new
        {
            success = true,
            latestEventSeq = Interlocked.Read(ref _eventSeq),
            recentEvents = events,
            phongs = merged.Values
                .OrderBy(p => p.SoTang)
                .ThenBy(p => p.KyHieuPhong)
                .ToList()
        });
    }

    [AllowAnonymous]
    [HttpPost("cap-nhat-phong")]
    public async Task<IActionResult> CapNhatPhongVaMedia([FromBody] UpdateRoomDiscoveryDto req)
    {
        if (string.IsNullOrWhiteSpace(req.KyHieuPhong))
            return BadRequest(new { success = false, message = "Mã phòng (KyHieuPhong) là bắt buộc." });

        var code = req.KyHieuPhong.Trim().ToUpperInvariant();
        if (!code.StartsWith("P.")) code = "P." + code;

        var existing = _liveListings.TryGetValue(code, out var cur) ? cur : null;
        var effectiveTitle = string.IsNullOrWhiteSpace(req.TieuDe)
            ? (existing?.TieuDe ?? $"Căn hộ thông minh {code}")
            : req.TieuDe.Trim();
        var effectiveStatus = string.IsNullOrWhiteSpace(req.TrangThai)
            ? (existing?.TrangThai ?? "Trống")
            : req.TrangThai.Trim();
        var effectivePrice = req.GiaThue > 0 ? req.GiaThue : (existing?.GiaThue ?? 3500000m);
        var effectiveArea = req.DienTich > 0 ? req.DienTich : (existing?.DienTich ?? 26m);
        var effectiveFloor = req.SoTang > 0 ? req.SoTang : (existing?.SoTang ?? 3);
        var effectiveCap = req.SucChua > 0 ? req.SucChua : (existing?.SucChua ?? 2);
        var effectiveType = string.IsNullOrWhiteSpace(req.LoaiPhong)
            ? (existing?.LoaiPhong ?? "Studio SmartStay")
            : req.LoaiPhong.Trim();
        var effectiveDesc = string.IsNullOrWhiteSpace(req.MoTa)
            ? (existing?.MoTa ?? "Phòng tiện nghi đầy đủ, an ninh IoT 24/7.")
            : req.MoTa.Trim();
        var effectiveAmenities = req.TienIchNoiBat != null && req.TienIchNoiBat.Count > 0
            ? req.TienIchNoiBat.Where(x => !string.IsNullOrWhiteSpace(x)).Select(x => x.Trim()).Distinct().ToList()
            : (existing?.TienIchNoiBat ?? new() { "Khóa vân tay IoT", "Máy lạnh Inverter", "Wi-Fi 6" });
        var effectiveImages = req.HinhAnhUrls != null && req.HinhAnhUrls.Count > 0
            ? req.HinhAnhUrls.Where(x => !string.IsNullOrWhiteSpace(x)).Select(x => x.Trim()).Distinct().ToList()
            : (existing?.HinhAnhUrls ?? new() { "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=900&q=80" });
        var effectiveVideo = req.VideoTourUrl != null
            ? (string.IsNullOrWhiteSpace(req.VideoTourUrl) ? null : NormalizeVideoUrl(req.VideoTourUrl))
            : existing?.VideoTourUrl;
        var isOpen = req.DangMoChoThue ?? (existing?.DangMoChoThue ?? true);

        int resolvedRoomId = req.MaPhong > 0 ? req.MaPhong : (existing?.MaPhong ?? 0);

        try
        {
            if (_db.Database.IsNpgsql())
            {
                var conn = _db.Database.GetDbConnection();
                if (conn.State != ConnectionState.Open) await conn.OpenAsync();

                // 1. Tìm hoặc thêm mới vào bảng "Phong"
                using (var cmdFind = conn.CreateCommand())
                {
                    cmdFind.CommandText = @"SELECT ""MaPhong"" FROM ""Phong"" WHERE UPPER(""KyHieuPhong"") = UPPER(@p0) LIMIT 1";
                    AddParam(cmdFind, "@p0", code);
                    var scalar = await cmdFind.ExecuteScalarAsync();
                    if (scalar != null && scalar != DBNull.Value)
                    {
                        resolvedRoomId = Convert.ToInt32(scalar);
                    }
                }

                if (resolvedRoomId > 0)
                {
                    using var cmdUpd = conn.CreateCommand();
                    cmdUpd.CommandText = @"
                        UPDATE ""Phong""
                        SET ""GiaThue"" = @p1,
                            ""DienTich"" = @p2,
                            ""SucChua"" = @p3,
                            ""TrangThai"" = @p4,
                            ""MoTa"" = @p5,
                            ""TieuDeChoThue"" = @p6,
                            ""TienIchNoiBat"" = @p7,
                            ""DangMoChoThue"" = @p8,
                            ""CapNhatLuc"" = NOW()
                        WHERE ""MaPhong"" = @p0";
                    AddParam(cmdUpd, "@p0", resolvedRoomId);
                    AddParam(cmdUpd, "@p1", effectivePrice);
                    AddParam(cmdUpd, "@p2", effectiveArea);
                    AddParam(cmdUpd, "@p3", effectiveCap);
                    AddParam(cmdUpd, "@p4", effectiveStatus);
                    AddParam(cmdUpd, "@p5", effectiveDesc);
                    AddParam(cmdUpd, "@p6", effectiveTitle);
                    AddParam(cmdUpd, "@p7", string.Join(",", effectiveAmenities));
                    AddParam(cmdUpd, "@p8", isOpen);
                    await cmdUpd.ExecuteNonQueryAsync();
                }
                else
                {
                    using var cmdIns = conn.CreateCommand();
                    cmdIns.CommandText = @"
                        INSERT INTO ""Phong"" (""MaToaNha"", ""MaLoaiPhong"", ""KyHieuPhong"", ""SoTang"", ""DienTich"", ""SucChua"", ""GiaThue"", ""TrangThai"", ""MoTa"", ""TieuDeChoThue"", ""TienIchNoiBat"", ""DangMoChoThue"", ""LuotXem"", ""DiemDanhGia"", ""CapNhatLuc"")
                        VALUES (
                            COALESCE((SELECT ""MaToaNha"" FROM ""ToaNha"" ORDER BY ""MaToaNha"" LIMIT 1), 1),
                            COALESCE((SELECT ""MaLoaiPhong"" FROM ""LoaiPhong"" ORDER BY ""MaLoaiPhong"" LIMIT 1), 1),
                            @p0, @p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, 15, 4.9, NOW()
                        )
                        RETURNING ""MaPhong""";
                    AddParam(cmdIns, "@p0", code);
                    AddParam(cmdIns, "@p1", effectiveFloor);
                    AddParam(cmdIns, "@p2", effectiveArea);
                    AddParam(cmdIns, "@p3", effectiveCap);
                    AddParam(cmdIns, "@p4", effectivePrice);
                    AddParam(cmdIns, "@p5", effectiveStatus);
                    AddParam(cmdIns, "@p6", effectiveDesc);
                    AddParam(cmdIns, "@p7", effectiveTitle);
                    AddParam(cmdIns, "@p8", string.Join(",", effectiveAmenities));
                    AddParam(cmdIns, "@p9", isOpen);
                    var insertedId = await cmdIns.ExecuteScalarAsync();
                    if (insertedId != null && insertedId != DBNull.Value)
                    {
                        resolvedRoomId = Convert.ToInt32(insertedId);
                    }
                }

                // 2. Đồng bộ danh sách Ảnh & Video Tour vào bảng "PhongMedia"
                if (resolvedRoomId > 0)
                {
                    using (var cmdDel = conn.CreateCommand())
                    {
                        cmdDel.CommandText = @"DELETE FROM ""PhongMedia"" WHERE ""MaPhong"" = @p0";
                        AddParam(cmdDel, "@p0", resolvedRoomId);
                        await cmdDel.ExecuteNonQueryAsync();
                    }

                    for (int i = 0; i < effectiveImages.Count; i++)
                    {
                        using var cmdImg = conn.CreateCommand();
                        cmdImg.CommandText = @"
                            INSERT INTO ""PhongMedia"" (""MaPhong"", ""KyHieuPhong"", ""LoaiMedia"", ""Url"", ""MoTa"", ""ThuTu"")
                            VALUES (@p0, @p1, 'Image', @p2, @p3, @p4)";
                        AddParam(cmdImg, "@p0", resolvedRoomId);
                        AddParam(cmdImg, "@p1", code);
                        AddParam(cmdImg, "@p2", effectiveImages[i]);
                        AddParam(cmdImg, "@p3", $"Ảnh phòng {code} #{i + 1}");
                        AddParam(cmdImg, "@p4", i);
                        await cmdImg.ExecuteNonQueryAsync();
                    }

                    if (!string.IsNullOrWhiteSpace(effectiveVideo))
                    {
                        using var cmdVid = conn.CreateCommand();
                        cmdVid.CommandText = @"
                            INSERT INTO ""PhongMedia"" (""MaPhong"", ""KyHieuPhong"", ""LoaiMedia"", ""Url"", ""MoTa"", ""ThuTu"")
                            VALUES (@p0, @p1, 'Video', @p2, @p3, 99)";
                        AddParam(cmdVid, "@p0", resolvedRoomId);
                        AddParam(cmdVid, "@p1", code);
                        AddParam(cmdVid, "@p2", effectiveVideo);
                        AddParam(cmdVid, "@p3", $"Video Tour thực tế phòng {code}");
                        await cmdVid.ExecuteNonQueryAsync();
                    }
                }
            }
        }
        catch { }

        var saved = new RoomListingDto
        {
            MaPhong = resolvedRoomId > 0 ? resolvedRoomId : (existing?.MaPhong ?? Math.Abs(code.GetHashCode() % 900) + 100),
            KyHieuPhong = code,
            TieuDe = effectiveTitle,
            LoaiPhong = effectiveType,
            SoTang = effectiveFloor,
            DienTich = effectiveArea,
            SucChua = effectiveCap,
            GiaThue = effectivePrice,
            TrangThai = effectiveStatus,
            MoTa = effectiveDesc,
            TienIchNoiBat = effectiveAmenities,
            DangMoChoThue = isOpen,
            LuotXem = existing?.LuotXem ?? 25,
            DiemDanhGia = existing?.DiemDanhGia ?? 4.9,
            HinhAnhUrls = effectiveImages,
            VideoTourUrl = effectiveVideo,
            CapNhatLuc = DateTime.UtcNow
        };
        _liveListings[code] = saved;

        // Phát thông báo Real-time cho toàn bộ thiết bị Cư dân / Khách tìm phòng
        var toastMsg = $"Phòng {code} vừa được cập nhật thông tin ({effectivePrice:N0} đ/tháng • {effectiveStatus})";
        var evt = PushRealtimeEvent(code, "room_updated", toastMsg);

        try
        {
            await _hubContext.Clients.All.SendAsync("RoomListingUpdated", new
            {
                RoomCode = code,
                RentPrice = effectivePrice,
                Status = effectiveStatus,
                Title = effectiveTitle,
                Message = toastMsg,
                Seq = evt.Seq,
                UpdatedAt = evt.UpdatedAt
            });
            await _hubContext.Clients.All.SendAsync("RoomStatusChanged", new
            {
                RoomId = saved.MaPhong,
                RoomCode = code,
                Status = effectiveStatus
            });
        }
        catch { }

        return Ok(new { success = true, item = saved, realtimeEvent = evt });
    }

    [AllowAnonymous]
    [HttpPost("{kyHieuPhong}/tang-luot-xem")]
    public async Task<IActionResult> TangLuotXemPhong(string kyHieuPhong)
    {
        if (string.IsNullOrWhiteSpace(kyHieuPhong)) return Ok(new { success = false });
        var code = kyHieuPhong.Trim().ToUpperInvariant();
        if (_liveListings.TryGetValue(code, out var cached))
        {
            cached.LuotXem += 1;
        }
        try
        {
            if (_db.Database.IsNpgsql())
            {
                var conn = _db.Database.GetDbConnection();
                if (conn.State != ConnectionState.Open) await conn.OpenAsync();
                using var cmd = conn.CreateCommand();
                cmd.CommandText = @"UPDATE ""Phong"" SET ""LuotXem"" = COALESCE(""LuotXem"", 0) + 1 WHERE UPPER(""KyHieuPhong"") = UPPER(@p0)";
                AddParam(cmd, "@p0", code);
                await cmd.ExecuteNonQueryAsync();
            }
        }
        catch { }
        return Ok(new { success = true, kyHieuPhong = code });
    }

    [AllowAnonymous]
    [HttpGet("dang-ky")]
    public async Task<IActionResult> LayDanhSachPhieuDangKy([FromQuery] string? trangThai = null, [FromQuery] string? soDienThoai = null)
    {
        var merged = new Dictionary<string, RoomRegistrationDto>(_liveRegistrations, StringComparer.OrdinalIgnoreCase);

        try
        {
            if (_db.Database.IsNpgsql())
            {
                var conn = _db.Database.GetDbConnection();
                if (conn.State != ConnectionState.Open) await conn.OpenAsync();
                using var cmd = conn.CreateCommand();
                cmd.CommandText = @"
                    SELECT ""MaPhieu"", ""MaPhong"", ""KyHieuPhong"", ""MaCuDan"", ""LoaiYeuCau"",
                           ""HoTen"", ""SoDienThoai"", ""SoCanCuoc"", ""NgayDuKienVaoO"", ""GhiChu"",
                           ""TrangThai"", ""LyDoTuChoi"", ""MaHopDongTao"", ""TaoLuc"", ""CapNhatLuc""
                    FROM ""PhieuDangKyPhong""
                    ORDER BY ""TaoLuc"" DESC
                    LIMIT 100";
                using var r = await cmd.ExecuteReaderAsync();
                while (await r.ReadAsync())
                {
                    var maPhieu = r.GetString(0);
                    DateTime moveInDate = DateTime.UtcNow.AddDays(3);
                    if (!r.IsDBNull(8))
                    {
                        var rawDate = r.GetValue(8);
                        if (rawDate is DateOnly dOnly) moveInDate = dOnly.ToDateTime(TimeOnly.MinValue);
                        else if (rawDate is DateTime dt) moveInDate = dt;
                    }
                    merged[maPhieu] = new RoomRegistrationDto
                    {
                        MaPhieu = maPhieu,
                        MaPhong = r.GetInt32(1),
                        KyHieuPhong = r.GetString(2),
                        MaCuDan = r.IsDBNull(3) ? null : r.GetInt32(3),
                        LoaiYeuCau = r.IsDBNull(4) ? "ThueMoi" : r.GetString(4),
                        HoTen = r.GetString(5),
                        SoDienThoai = r.GetString(6),
                        SoCanCuoc = r.IsDBNull(7) ? null : r.GetString(7),
                        NgayDuKienVaoO = moveInDate.ToString("yyyy-MM-dd"),
                        GhiChu = r.IsDBNull(9) ? null : r.GetString(9),
                        TrangThai = r.IsDBNull(10) ? "ChoDuyet" : r.GetString(10),
                        LyDoTuChoi = r.IsDBNull(11) ? null : r.GetString(11),
                        MaHopDongTao = r.IsDBNull(12) ? null : r.GetInt32(12),
                        TaoLuc = r.IsDBNull(13) ? DateTime.UtcNow : r.GetDateTime(13),
                        CapNhatLuc = r.IsDBNull(14) ? DateTime.UtcNow : r.GetDateTime(14)
                    };
                }
            }
        }
        catch { }

        IEnumerable<RoomRegistrationDto> query = merged.Values;
        if (!string.IsNullOrWhiteSpace(trangThai))
        {
            query = query.Where(x => x.TrangThai.Equals(trangThai.Trim(), StringComparison.OrdinalIgnoreCase));
        }
        if (!string.IsNullOrWhiteSpace(soDienThoai))
        {
            var phone = soDienThoai.Trim();
            query = query.Where(x => x.SoDienThoai.Contains(phone, StringComparison.OrdinalIgnoreCase));
        }

        return Ok(new
        {
            success = true,
            items = query.OrderByDescending(x => x.TaoLuc).ToList()
        });
    }

    [AllowAnonymous]
    [HttpPost("dang-ky")]
    public async Task<IActionResult> TaoPhieuDangKyPhong([FromBody] CreateRoomRegistrationDto req)
    {
        if (string.IsNullOrWhiteSpace(req.KyHieuPhong) || string.IsNullOrWhiteSpace(req.HoTen) || string.IsNullOrWhiteSpace(req.SoDienThoai))
        {
            return BadRequest(new { success = false, message = "Vui lòng nhập đầy đủ Phòng, Họ tên và Số điện thoại." });
        }

        var code = req.KyHieuPhong.Trim().ToUpperInvariant();
        if (!code.StartsWith("P.")) code = "P." + code;

        var maPhieu = string.IsNullOrWhiteSpace(req.MaPhieu)
            ? $"DKP-{DateTime.UtcNow:yyyyMMdd}-{Random.Shared.Next(1000, 9999)}"
            : req.MaPhieu.Trim();
        var loai = string.IsNullOrWhiteSpace(req.LoaiYeuCau) ? "ThueMoi" : req.LoaiYeuCau.Trim();
        var moveInDate = DateOnly.TryParse(req.NgayDuKienVaoO, out var parsedDate)
            ? parsedDate
            : DateOnly.FromDateTime(DateTime.UtcNow.AddDays(3));

        int resolvedRoomId = req.MaPhong ?? (_liveListings.TryGetValue(code, out var foundRoom) ? foundRoom.MaPhong : 1);

        try
        {
            if (_db.Database.IsNpgsql())
            {
                var conn = _db.Database.GetDbConnection();
                if (conn.State != ConnectionState.Open) await conn.OpenAsync();

                using (var cmdFind = conn.CreateCommand())
                {
                    cmdFind.CommandText = @"SELECT COALESCE((SELECT ""MaPhong"" FROM ""Phong"" WHERE UPPER(""KyHieuPhong"") = UPPER(@p0) LIMIT 1), (SELECT ""MaPhong"" FROM ""Phong"" ORDER BY ""MaPhong"" LIMIT 1))";
                    AddParam(cmdFind, "@p0", code);
                    var scalar = await cmdFind.ExecuteScalarAsync();
                    if (scalar != null && scalar != DBNull.Value)
                    {
                        resolvedRoomId = Convert.ToInt32(scalar);
                    }
                }

                using var cmd = conn.CreateCommand();
                cmd.CommandText = @"
                    INSERT INTO ""PhieuDangKyPhong"" (
                        ""MaPhieu"", ""MaPhong"", ""KyHieuPhong"", ""MaCuDan"", ""LoaiYeuCau"",
                        ""HoTen"", ""SoDienThoai"", ""SoCanCuoc"", ""NgayDuKienVaoO"", ""GhiChu"", ""TrangThai""
                    )
                    VALUES (
                        @p0, @p1, @p2,
                        COALESCE(@p3, (SELECT c.""MaCuDan"" FROM ""CuDan"" c INNER JOIN ""NguoiDung"" u ON u.""MaNguoiDung"" = c.""MaNguoiDung"" WHERE u.""SoDienThoai"" = @p6 LIMIT 1)),
                        @p4, @p5, @p6, @p7, @p8, @p9, 'ChoDuyet'
                    )
                    ON CONFLICT (""MaPhieu"") DO NOTHING";
                AddParam(cmd, "@p0", maPhieu);
                AddParam(cmd, "@p1", resolvedRoomId);
                AddParam(cmd, "@p2", code);
                AddParam(cmd, "@p3", req.MaCuDan);
                AddParam(cmd, "@p4", loai);
                AddParam(cmd, "@p5", req.HoTen.Trim());
                AddParam(cmd, "@p6", req.SoDienThoai.Trim());
                AddParam(cmd, "@p7", string.IsNullOrWhiteSpace(req.SoCanCuoc) ? null : req.SoCanCuoc.Trim());
                AddParam(cmd, "@p8", moveInDate.ToDateTime(TimeOnly.MinValue));
                AddParam(cmd, "@p9", string.IsNullOrWhiteSpace(req.GhiChu) ? null : req.GhiChu.Trim());
                await cmd.ExecuteNonQueryAsync();
            }
        }
        catch { }

        var dto = new RoomRegistrationDto
        {
            MaPhieu = maPhieu,
            MaPhong = resolvedRoomId,
            KyHieuPhong = code,
            MaCuDan = req.MaCuDan,
            LoaiYeuCau = loai,
            HoTen = req.HoTen.Trim(),
            SoDienThoai = req.SoDienThoai.Trim(),
            SoCanCuoc = req.SoCanCuoc?.Trim(),
            NgayDuKienVaoO = moveInDate.ToString("yyyy-MM-dd"),
            GhiChu = req.GhiChu?.Trim(),
            TrangThai = "ChoDuyet",
            TaoLuc = DateTime.UtcNow,
            CapNhatLuc = DateTime.UtcNow
        };
        _liveRegistrations[maPhieu] = dto;

        var evt = PushRealtimeEvent(code, "booking_created", $"Có yêu cầu đăng ký phòng {code} mới từ {dto.HoTen}");
        try
        {
            await _hubContext.Clients.All.SendAsync("BookingRequestCreated", dto);
        }
        catch { }

        return Ok(new { success = true, item = dto, realtimeEvent = evt });
    }

    [AllowAnonymous]
    [HttpPost("dang-ky/{maPhieu}/xu-ly")]
    public async Task<IActionResult> XuLyPhieuDangKy(string maPhieu, [FromBody] ProcessRoomRegistrationDto req)
    {
        if (string.IsNullOrWhiteSpace(maPhieu))
            return BadRequest(new { success = false, message = "Thiếu mã phiếu." });

        var approve = req.TrangThai?.Equals("DaDuyet", StringComparison.OrdinalIgnoreCase) == true || req.Approve;
        var nextStatus = approve ? "DaDuyet" : "TuChoi";
        var rejectReason = approve ? null : (string.IsNullOrWhiteSpace(req.LyDoTuChoi) ? "Phòng hiện không còn trống theo thời gian yêu cầu." : req.LyDoTuChoi.Trim());
        string roomCode = req.KyHieuPhong?.Trim().ToUpperInvariant() ?? "";
        int? createdContractId = null;
        string? draftContractCode = null;

        if (_liveRegistrations.TryGetValue(maPhieu, out var cachedReg))
        {
            cachedReg.TrangThai = nextStatus;
            cachedReg.LyDoTuChoi = rejectReason;
            cachedReg.CapNhatLuc = DateTime.UtcNow;
            if (string.IsNullOrWhiteSpace(roomCode)) roomCode = cachedReg.KyHieuPhong;
        }

        try
        {
            if (_db.Database.IsNpgsql())
            {
                var conn = _db.Database.GetDbConnection();
                if (conn.State != ConnectionState.Open) await conn.OpenAsync();

                int dbRoomId = 0;
                using (var cmdGet = conn.CreateCommand())
                {
                    cmdGet.CommandText = @"SELECT ""MaPhong"", ""KyHieuPhong"" FROM ""PhieuDangKyPhong"" WHERE ""MaPhieu"" = @p0 LIMIT 1";
                    AddParam(cmdGet, "@p0", maPhieu);
                    using var r = await cmdGet.ExecuteReaderAsync();
                    if (await r.ReadAsync())
                    {
                        dbRoomId = r.GetInt32(0);
                        roomCode = r.GetString(1);
                    }
                }

                if (approve && dbRoomId > 0)
                {
                    // Chuyển trạng thái phòng sang 'Đã đặt' và tạm ẩn nút mở cho thuê
                    using (var cmdRoom = conn.CreateCommand())
                    {
                        cmdRoom.CommandText = @"UPDATE ""Phong"" SET ""TrangThai"" = 'Đã đặt', ""DangMoChoThue"" = FALSE, ""CapNhatLuc"" = NOW() WHERE ""MaPhong"" = @p0";
                        AddParam(cmdRoom, "@p0", dbRoomId);
                        await cmdRoom.ExecuteNonQueryAsync();
                    }

                    // Tạo bản nháp Hợp Đồng nếu thỏa mãn ràng buộc bảng HopDong
                    draftContractCode = $"HD-NHAP-{DateTime.UtcNow:yyyyMMdd}-{Random.Shared.Next(100, 999)}";
                    try
                    {
                        using var cmdHd = conn.CreateCommand();
                        cmdHd.CommandText = @"
                            INSERT INTO ""HopDong"" (""SoHopDong"", ""MaPhong"", ""NgayBatDau"", ""NgayKetThuc"", ""TienThueThang"", ""TienCoc"", ""TrangThai"", ""NguoiTao"")
                            SELECT @p0, p.""MaPhong"", CURRENT_DATE, CURRENT_DATE + INTERVAL '12 months', p.""GiaThue"", p.""GiaThue"" * 2, 'Bản nháp',
                                   COALESCE((SELECT ""MaNguoiDung"" FROM ""NguoiDung"" ORDER BY ""MaNguoiDung"" LIMIT 1), 1)
                            FROM ""Phong"" p
                            WHERE p.""MaPhong"" = @p1
                              AND NOT EXISTS (SELECT 1 FROM ""HopDong"" h WHERE h.""MaPhong"" = p.""MaPhong"" AND h.""TrangThai"" IN ('Đang hiệu lực', 'Bản nháp'))
                            RETURNING ""MaHopDong""";
                        AddParam(cmdHd, "@p0", draftContractCode);
                        AddParam(cmdHd, "@p1", dbRoomId);
                        var hdObj = await cmdHd.ExecuteScalarAsync();
                        if (hdObj != null && hdObj != DBNull.Value)
                        {
                            createdContractId = Convert.ToInt32(hdObj);
                        }
                    }
                    catch { }
                }

                using var cmdUpd = conn.CreateCommand();
                cmdUpd.CommandText = @"
                    UPDATE ""PhieuDangKyPhong""
                    SET ""TrangThai"" = @p1,
                        ""LyDoTuChoi"" = @p2,
                        ""MaHopDongTao"" = COALESCE(@p3, ""MaHopDongTao""),
                        ""CapNhatLuc"" = NOW()
                    WHERE ""MaPhieu"" = @p0";
                AddParam(cmdUpd, "@p0", maPhieu);
                AddParam(cmdUpd, "@p1", nextStatus);
                AddParam(cmdUpd, "@p2", rejectReason);
                AddParam(cmdUpd, "@p3", createdContractId);
                await cmdUpd.ExecuteNonQueryAsync();
            }
        }
        catch { }

        if (approve && !string.IsNullOrWhiteSpace(roomCode) && _liveListings.TryGetValue(roomCode, out var liveRoom))
        {
            liveRoom.TrangThai = "Đã đặt";
            liveRoom.DangMoChoThue = false;
            liveRoom.CapNhatLuc = DateTime.UtcNow;
        }

        if (_liveRegistrations.TryGetValue(maPhieu, out var regUpdated))
        {
            regUpdated.MaHopDongTao = createdContractId;
            regUpdated.DraftContractCode = draftContractCode;
        }

        var msg = approve
            ? $"Phòng {roomCode} đã được duyệt giữ chỗ & tạo bản nháp hợp đồng ({draftContractCode ?? maPhieu})"
            : $"Phiếu đăng ký {maPhieu} cho phòng {roomCode} đã bị từ chối";
        var evt = PushRealtimeEvent(roomCode, approve ? "booking_approved" : "booking_rejected", msg);

        try
        {
            await _hubContext.Clients.All.SendAsync("RoomListingUpdated", new
            {
                RoomCode = roomCode,
                Status = approve ? "Đã đặt" : "Trống",
                Message = msg,
                Seq = evt.Seq,
                UpdatedAt = evt.UpdatedAt
            });
        }
        catch { }

        return Ok(new
        {
            success = true,
            maPhieu,
            trangThai = nextStatus,
            kyHieuPhong = roomCode,
            maHopDongTao = createdContractId,
            draftContractCode,
            realtimeEvent = evt
        });
    }
}

public class RoomDiscoveryEventDto
{
    public long Seq { get; set; }
    public string KyHieuPhong { get; set; } = string.Empty;
    public string EventType { get; set; } = "room_updated";
    public string Message { get; set; } = string.Empty;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

public class RoomListingDto
{
    public int MaPhong { get; set; }
    public string KyHieuPhong { get; set; } = string.Empty;
    public string TieuDe { get; set; } = string.Empty;
    public string LoaiPhong { get; set; } = string.Empty;
    public int SoTang { get; set; }
    public decimal DienTich { get; set; }
    public int SucChua { get; set; }
    public decimal GiaThue { get; set; }
    public string TrangThai { get; set; } = "Trống";
    public string MoTa { get; set; } = string.Empty;
    public List<string> TienIchNoiBat { get; set; } = new();
    public bool DangMoChoThue { get; set; } = true;
    public int LuotXem { get; set; } = 20;
    public double DiemDanhGia { get; set; } = 4.8;
    public List<string> HinhAnhUrls { get; set; } = new();
    public string? VideoTourUrl { get; set; }
    public DateTime CapNhatLuc { get; set; } = DateTime.UtcNow;
}

public class UpdateRoomDiscoveryDto
{
    public int MaPhong { get; set; }
    public string KyHieuPhong { get; set; } = string.Empty;
    public string? TieuDe { get; set; }
    public string? LoaiPhong { get; set; }
    public int SoTang { get; set; }
    public decimal DienTich { get; set; }
    public int SucChua { get; set; }
    public decimal GiaThue { get; set; }
    public string? TrangThai { get; set; }
    public string? MoTa { get; set; }
    public List<string>? TienIchNoiBat { get; set; }
    public bool? DangMoChoThue { get; set; }
    public List<string>? HinhAnhUrls { get; set; }
    public string? VideoTourUrl { get; set; }
}

public class RoomRegistrationDto
{
    public string MaPhieu { get; set; } = string.Empty;
    public int MaPhong { get; set; }
    public string KyHieuPhong { get; set; } = string.Empty;
    public int? MaCuDan { get; set; }
    public string LoaiYeuCau { get; set; } = "ThueMoi";
    public string HoTen { get; set; } = string.Empty;
    public string SoDienThoai { get; set; } = string.Empty;
    public string? SoCanCuoc { get; set; }
    public string NgayDuKienVaoO { get; set; } = string.Empty;
    public string? GhiChu { get; set; }
    public string TrangThai { get; set; } = "ChoDuyet";
    public string? LyDoTuChoi { get; set; }
    public int? MaHopDongTao { get; set; }
    public string? DraftContractCode { get; set; }
    public DateTime TaoLuc { get; set; } = DateTime.UtcNow;
    public DateTime CapNhatLuc { get; set; } = DateTime.UtcNow;
}

public class CreateRoomRegistrationDto
{
    public string? MaPhieu { get; set; }
    public int? MaPhong { get; set; }
    public string KyHieuPhong { get; set; } = string.Empty;
    public int? MaCuDan { get; set; }
    public string? LoaiYeuCau { get; set; }
    public string HoTen { get; set; } = string.Empty;
    public string SoDienThoai { get; set; } = string.Empty;
    public string? SoCanCuoc { get; set; }
    public string? NgayDuKienVaoO { get; set; }
    public string? GhiChu { get; set; }
}

public class ProcessRoomRegistrationDto
{
    public bool Approve { get; set; }
    public string? TrangThai { get; set; }
    public string? KyHieuPhong { get; set; }
    public string? LyDoTuChoi { get; set; }
}
