import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'api_transport.dart';

/// Dịch vụ kết nối trực tiếp Supabase (Phương án A) kết hợp đồng bộ liên thông với Web Admin (.NET 8)
class SupabaseDirectService {
  static final SupabaseDirectService _instance = SupabaseDirectService._internal();
  factory SupabaseDirectService() => _instance;
  SupabaseDirectService._internal();

  static String get supabaseUrl {
    const envUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://odasdzyuriucofavonjl.supabase.co',
    );
    return envUrl.replaceFirst(RegExp(r'/+$'), '');
  }

  static String get supabaseAnonKey {
    return const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'sb_publishable_GYfWQ4xJCkpgxjI2XBNVmg_6eWoUWP7',
    );
  }

  static const String renderCloudApiUrl = 'https://smartstay-admin.onrender.com/api';

  Future<Map<String, dynamic>?>? _inFlightSnapshot;
  Map<String, dynamic>? _cachedSnapshot;
  DateTime? _cachedAt;
  bool _localSyncUnreachable = false;

  static String get adminPortalUrl {
    const envAdmin = String.fromEnvironment('ADMIN_PORTAL_URL');
    if (envAdmin.isNotEmpty) {
      return envAdmin.replaceFirst(RegExp(r'/+$'), '');
    }
    if (kIsWeb) {
      final base = ApiService.baseUrl;
      if (base.endsWith('/api')) {
        return base.substring(0, base.length - 4);
      }
    }
    return 'https://smartstay-admin.onrender.com';
  }

  bool _isLocalBase(String baseUrl) {
    final host = Uri.tryParse(baseUrl)?.host.toLowerCase() ?? '';
    return host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2';
  }

  /// Danh sách các cổng Sync API (bỏ qua cổng local nếu đã xác định không mở server local)
  List<String> get _syncApiBases {
    final bases = <String>{
      renderCloudApiUrl,
      ApiService.baseUrl,
    };
    return bases
        .where((base) => !(_localSyncUnreachable && _isLocalBase(base)))
        .toList();
  }

  Map<String, String> get _supabaseHeaders => {
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $supabaseAnonKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

  /// Đọc danh sách Phòng trực tiếp từ Supabase PostgREST (Phương án A)
  Future<List<dynamic>?> fetchRoomsDirect() async {
    try {
      final uri = Uri.parse(
        '$supabaseUrl/rest/v1/Phong?select=MaPhong,KyHieuPhong,SoTang,TrangThai,GiaThue,DienTich,SucChua&order=SoTang.asc,KyHieuPhong.asc',
      );
      final res = await sendApiRequest(
        method: 'GET',
        uri: uri,
        headers: _supabaseHeaders,
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) return decoded;
      }
    } catch (e) {
      debugPrint('SupabaseDirectService.fetchRoomsDirect fallback: $e');
    }
    return null;
  }

  /// Đọc danh sách Thông báo trực tiếp từ Supabase PostgREST (Phương án A)
  Future<List<dynamic>?> fetchAnnouncementsDirect() async {
    try {
      final uri = Uri.parse(
        '$supabaseUrl/rest/v1/ThongBao?select=MaThongBao,TieuDe,NoiDung,PhamViNhan,TrangThai,ThoiDiemCongBo&order=ThoiDiemCongBo.desc&limit=15',
      );
      final res = await sendApiRequest(
        method: 'GET',
        uri: uri,
        headers: _supabaseHeaders,
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) return decoded;
      }
    } catch (e) {
      debugPrint('SupabaseDirectService.fetchAnnouncementsDirect fallback: $e');
    }
    return null;
  }

  /// Đọc danh sách Phiếu sự cố trực tiếp từ Supabase PostgREST (Phương án A)
  Future<List<dynamic>?> fetchTicketsDirect() async {
    try {
      final uri = Uri.parse(
        '$supabaseUrl/rest/v1/PhieuSuCo?select=MaPhieuSuCo,SoPhieuSuCo,MaPhong,TieuDe,MoTa,UuTien,TrangThai,ThoiDiemTao,ChiPhiVatTu&order=ThoiDiemTao.desc&limit=25',
      );
      final res = await sendApiRequest(
        method: 'GET',
        uri: uri,
        headers: _supabaseHeaders,
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) return decoded;
      }
    } catch (e) {
      debugPrint('SupabaseDirectService.fetchTicketsDirect fallback: $e');
    }
    return null;
  }

  Future<bool> _postToSyncBases(String path, String payload) async {
    var ok = false;
    for (final base in _syncApiBases) {
      try {
        final res = await sendApiRequest(
          method: 'POST',
          uri: Uri.parse('$base$path'),
          headers: const {'Content-Type': 'application/json'},
          body: payload,
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          ok = true;
        }
      } catch (_) {
        if (_isLocalBase(base)) _localSyncUnreachable = true;
      }
    }
    return ok;
  }

  /// Đồng bộ Snapshot hợp nhất (Ưu tiên API Admin .NET trên Render/Local -> Kết hợp Supabase PostgREST Phương án A)
  Future<Map<String, dynamic>?> fetchUnifiedSnapshot() {
    if (_cachedSnapshot != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < const Duration(seconds: 3)) {
      return Future.value(_cachedSnapshot);
    }
    return _inFlightSnapshot ??= _performFetchUnifiedSnapshot();
  }

  Future<Map<String, dynamic>?> _performFetchUnifiedSnapshot() async {
    try {
      // 1. Thử lấy từ cổng /api/sync/snapshot của Render Cloud hoặc Local Web Admin
      for (final base in _syncApiBases) {
        try {
          final uri = Uri.parse('$base/sync/snapshot');
          final res = await sendApiRequest(
            method: 'GET',
            uri: uri,
            headers: const {'Accept': 'application/json'},
          );
          if (res.statusCode >= 200 && res.statusCode < 300) {
            final decoded = jsonDecode(res.body);
            if (decoded is Map<String, dynamic> && decoded['success'] == true) {
              _cachedSnapshot = decoded;
              _cachedAt = DateTime.now();
              return decoded;
            }
          }
        } catch (_) {
          if (_isLocalBase(base)) _localSyncUnreachable = true;
          // Thử tiếp cổng tiếp theo hoặc fallback sang Supabase PostgREST trực tiếp
        }
      }

      // 2. Gọi trực tiếp vào Supabase qua PostgREST (Phương án A)
      final results = await Future.wait([
        fetchRoomsDirect(),
        fetchTicketsDirect(),
        fetchAnnouncementsDirect(),
      ]);

      final rooms = results[0];
      final tickets = results[1];
      final announcements = results[2];

      if (rooms != null || tickets != null || announcements != null) {
        final snapshot = <String, dynamic>{
          'success': true,
          'source': 'supabase-direct-option-a',
          'phongs': rooms ?? const [],
          'suCos': tickets ?? const [],
          'thongBaos': announcements ?? const [],
        };
        _cachedSnapshot = snapshot;
        _cachedAt = DateTime.now();
        return snapshot;
      }
      return null;
    } finally {
      _inFlightSnapshot = null;
    }
  }

  /// Cập nhật trạng thái phòng lên cả Render Cloud, Local và Supabase để giả lập Android & Web Render đồng bộ 2 chiều
  Future<bool> syncRoomStatus({
    required String roomCode,
    required String status,
    double? price,
  }) async {
    final payload = jsonEncode({
      'KyHieuPhong': roomCode,
      'TrangThai': status,
      'GiaThue': ?price,
    });

    // 1. Ghi qua các cổng API Web Admin (Render Cloud + Local)
    bool ok = await _postToSyncBases('/sync/cap-nhat-phong', payload);

    // 2. Ghi trực tiếp vào bảng Phong trên Supabase (Phương án A)
    try {
      final encodedRoom = Uri.encodeQueryComponent(roomCode);
      final res = await sendApiRequest(
        method: 'PATCH',
        uri: Uri.parse('$supabaseUrl/rest/v1/Phong?KyHieuPhong=eq.$encodedRoom'),
        headers: _supabaseHeaders,
        body: jsonEncode({
          'TrangThai': status,
          'GiaThue': ?price,
        }),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        ok = true;
      }
    } catch (_) {}

    return ok;
  }

  /// Đồng bộ Phiếu sự cố (Tạo mới hoặc đổi trạng thái) sang Render Cloud & Local Sync API
  Future<void> syncTicket({
    required String ticketCode,
    required String roomCode,
    required String title,
    String? description,
    String? priority,
    required String status,
    String? imageUrl,
    String? videoUrl,
  }) async {
    final payload = jsonEncode({
      'SoPhieuSuCo': ticketCode,
      'KyHieuPhong': roomCode,
      'TieuDe': title,
      'MoTa': description ?? title,
      'UuTien': priority ?? 'Cao',
      'TrangThai': status,
      if (imageUrl != null && imageUrl.isNotEmpty) 'HinhAnhUrl': imageUrl,
      if (videoUrl != null && videoUrl.isNotEmpty) 'VideoUrl': videoUrl,
    });

    await _postToSyncBases('/sync/su-co', payload);
  }

  /// Đồng bộ Thông báo mới sang Render Cloud, Local & Supabase
  Future<void> syncNotice({
    required String title,
    required String content,
    required String scope,
    required bool isImportant,
  }) async {
    final effectiveTitle = isImportant && !title.contains('[Quan trọng]')
        ? '[Quan trọng] $title'
        : title;
    final payload = jsonEncode({
      'TieuDe': effectiveTitle,
      'NoiDung': content,
      'PhamViNhan': scope,
      'LaKhanCap': isImportant,
    });

    await _postToSyncBases('/sync/thong-bao', payload);

    // Ghi trực tiếp vào bảng ThongBao trên Supabase (Phương án A)
    try {
      await sendApiRequest(
        method: 'POST',
        uri: Uri.parse('$supabaseUrl/rest/v1/ThongBao'),
        headers: _supabaseHeaders,
        body: jsonEncode({
          'TieuDe': effectiveTitle,
          'NoiDung': content,
          'PhamViNhan': scope,
          'TrangThai': 'Đã công bố',
          'NguoiTao': 1,
          'ThoiDiemTao': DateTime.now().toUtc().toIso8601String(),
          'ThoiDiemCongBo': DateTime.now().toUtc().toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  /// Đồng bộ Chỉ số công tơ tự kiểm tra cá nhân của cư dân giữa Giả lập Android <-> Web Cư Dân trên Render
  /// (Kèm khóa ngoại MaPhong, MaCuDan)
  Future<void> syncResidentMeterCheck({
    required String mode,
    required double elecOld,
    required double elecNew,
    required double waterOld,
    required double waterNew,
    required double totalEstimatedCost,
    int maPhong = 3,
    int maCuDan = 1,
    String? consumptionSummary,
    String? dateLabel,
    bool saveToPersonalLog = false,
  }) async {
    final sourceLabel = kIsWeb ? 'Web Cư Dân (Render)' : 'App Android Cư Dân';
    final payload = jsonEncode({
      'MaPhong': maPhong,
      'MaCuDan': maCuDan,
      'KyHieuPhong': 'P.305',
      'CheDo': mode,
      'DienKyTruoc': elecOld,
      'DienMoiChup': elecNew,
      'NuocKyTruoc': waterOld,
      'NuocMoiChup': waterNew,
      'TongTienTamTinh': totalEstimatedCost,
      'TomTatTieuThu': consumptionSummary ?? '',
      'NhanThoiGian': dateLabel ?? 'Hôm nay ($sourceLabel)',
      'NguonCapNhat': sourceLabel,
      'LuuVaoSoCaNhan': saveToPersonalLog,
    });

    await _postToSyncBases('/sync/chi-so-cu-dan', payload);

    try {
      await sendApiRequest(
        method: 'POST',
        uri: Uri.parse('$supabaseUrl/rest/v1/ChiSoTuKiemTra'),
        headers: _supabaseHeaders,
        body: jsonEncode({
          'MaPhong': maPhong,
          'MaCuDan': maCuDan,
          'KyHieuPhong': 'P.305',
          'CheDo': mode,
          'DienKyTruoc': elecOld,
          'DienMoiChup': elecNew,
          'NuocKyTruoc': waterOld,
          'NuocMoiChup': waterNew,
          'TongTienTamTinh': totalEstimatedCost,
          'TomTatTieuThu': consumptionSummary ?? '',
          'NguonCapNhat': sourceLabel,
        }),
      );
    } catch (_) {}
  }

  /// Upload ảnh hoặc video thực tế lên Supabase Storage (`smartstay-media` public bucket)
  /// và trả về URL công khai vĩnh viễn để không bị mất khi F5 / khởi động lại app.
  Future<String?> uploadMediaBytes({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    String folder = 'marketplace',
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final b64 = base64Encode(bytes);
    final payload = jsonEncode({
      'FileName': safeName,
      'ContentType': contentType,
      'Base64Data': b64,
      'Folder': folder,
    });

    for (final base in _syncApiBases) {
      try {
        final res = await sendApiRequest(
          method: 'POST',
          uri: Uri.parse('$base/sync/upload-media'),
          headers: const {'Content-Type': 'application/json'},
          body: payload,
          timeout: const Duration(seconds: 45),
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final decoded = jsonDecode(res.body);
          if (decoded is Map &&
              decoded['success'] == true &&
              decoded['publicUrl'] != null) {
            return decoded['publicUrl'].toString();
          }
        }
      } catch (_) {
        if (_isLocalBase(base)) _localSyncUnreachable = true;
      }
    }
    return null;
  }

  /// Giữ chỗ / Đặt mua hoặc Xin nhận đồ trên Chợ Đồ Cũ (lưu bền vững xuống Supabase kèm MaCuDanGiuCho)
  Future<bool> claimMarketplaceItem({
    required String maTin,
    required String claimerName,
    int maCuDanGiuCho = 1,
  }) async {
    final payload = jsonEncode({
      'MaTin': maTin,
      'MaCuDanGiuCho': maCuDanGiuCho,
      'NguoiGiuCho': claimerName,
    });
    var ok = await _postToSyncBases('/sync/cho-do-cu/giu-cho', payload);

    try {
      final encodedId = Uri.encodeQueryComponent(maTin);
      final res = await sendApiRequest(
        method: 'PATCH',
        uri: Uri.parse('$supabaseUrl/rest/v1/ChoDoCuTin?MaTin=eq.$encodedId'),
        headers: _supabaseHeaders,
        body: jsonEncode({
          'TrangThai': 'Đã giữ chỗ',
          'MaCuDanGiuCho': maCuDanGiuCho,
          'NguoiGiuCho': claimerName,
        }),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) ok = true;
    } catch (_) {}
    return ok;
  }

  /// Lưu Vé Khách Vãng Lai (IoT) bền vững xuống Supabase kèm khóa ngoại MaPhong, MaCuDan
  Future<bool> syncGuestPass({
    required String maVe,
    required String roomCode,
    required String guestName,
    int maPhong = 3,
    int maCuDan = 1,
    String? phone,
    required String pin,
    required String validUntil,
  }) async {
    final payload = jsonEncode({
      'MaVe': maVe,
      'MaPhong': maPhong,
      'MaCuDan': maCuDan,
      'KyHieuPhong': roomCode,
      'TenKhach': guestName,
      'SoDienThoai': phone ?? '',
      'MaPin': pin,
      'HieuLucDen': validUntil,
    });
    var ok = await _postToSyncBases('/sync/ve-khach', payload);
    try {
      final res = await sendApiRequest(
        method: 'POST',
        uri: Uri.parse('$supabaseUrl/rest/v1/VeKhachVangLai'),
        headers: _supabaseHeaders,
        body: payload,
      );
      if (res.statusCode >= 200 && res.statusCode < 300) ok = true;
    } catch (_) {}
    return ok;
  }

  /// Lưu khoản Chia Tiền Phòng Ở Ghép bền vững xuống Supabase kèm khóa ngoại MaPhong, MaHoaDon, MaCuDanTao
  Future<bool> syncSplitBill({
    required String maChia,
    required String roomCode,
    required String title,
    required double totalAmount,
    required int memberCount,
    int maPhong = 3,
    int maHoaDon = 1,
    int maCuDanTao = 1,
    String status = 'Chờ đóng',
  }) async {
    final payload = jsonEncode({
      'MaChia': maChia,
      'MaPhong': maPhong,
      'MaHoaDon': maHoaDon,
      'MaCuDanTao': maCuDanTao,
      'KyHieuPhong': roomCode,
      'TieuDe': title,
      'TongTien': totalAmount,
      'SoThanhVien': memberCount,
      'MoiNguoi': (totalAmount / (memberCount > 0 ? memberCount : 1)).round(),
      'TrangThai': status,
    });
    var ok = await _postToSyncBases('/sync/chia-tien', payload);
    try {
      final res = await sendApiRequest(
        method: 'POST',
        uri: Uri.parse('$supabaseUrl/rest/v1/ChiaTienPhong'),
        headers: {
          ..._supabaseHeaders,
          'Prefer': 'resolution=merge-duplicates,return=representation',
        },
        body: payload,
      );
      if (res.statusCode >= 200 && res.statusCode < 300) ok = true;
    } catch (_) {}
    return ok;
  }
}
