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
    return 'http://localhost:5096';
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

  /// Đồng bộ Snapshot hợp nhất (Ưu tiên API Admin .NET -> Fallback sang Supabase PostgREST Phương án A)
  Future<Map<String, dynamic>?> fetchUnifiedSnapshot() async {
    // 1. Thử lấy từ cổng /api/sync/snapshot của Web Admin
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/sync/snapshot');
      final res = await sendApiRequest(
        method: 'GET',
        uri: uri,
        headers: const {'Accept': 'application/json'},
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic> && decoded['success'] == true) {
          return decoded;
        }
      }
    } catch (_) {
      // Chuyển sang gọi trực tiếp Supabase (Phương án A) khi Web Admin ngủ đông trên Render Free
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
      return {
        'success': true,
        'source': 'supabase-direct-option-a',
        'phongs': rooms ?? const [],
        'suCos': tickets ?? const [],
        'thongBaos': announcements ?? const [],
      };
    }
    return null;
  }

  /// Cập nhật trạng thái phòng lên cả Supabase và Web Admin để điều khiển song song
  Future<bool> syncRoomStatus({
    required String roomCode,
    required String status,
    double? price,
  }) async {
    bool ok = false;
    // 1. Ghi qua API Web Admin
    try {
      final res = await sendApiRequest(
        method: 'POST',
        uri: Uri.parse('${ApiService.baseUrl}/sync/cap-nhat-phong'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'KyHieuPhong': roomCode,
          'TrangThai': status,
          if (price != null) 'GiaThue': price,
        }),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        ok = true;
      }
    } catch (_) {}

    // 2. Ghi trực tiếp vào bảng Phong trên Supabase (Phương án A)
    try {
      final encodedRoom = Uri.encodeQueryComponent(roomCode);
      final res = await sendApiRequest(
        method: 'PATCH',
        uri: Uri.parse('$supabaseUrl/rest/v1/Phong?KyHieuPhong=eq.$encodedRoom'),
        headers: _supabaseHeaders,
        body: jsonEncode({
          'TrangThai': status,
          if (price != null) 'GiaThue': price,
        }),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        ok = true;
      }
    } catch (_) {}

    return ok;
  }

  /// Đồng bộ Phiếu sự cố (Tạo mới hoặc đổi trạng thái) sang Web Admin & Supabase
  Future<void> syncTicket({
    required String ticketCode,
    required String roomCode,
    required String title,
    String? description,
    String? priority,
    required String status,
  }) async {
    try {
      await sendApiRequest(
        method: 'POST',
        uri: Uri.parse('${ApiService.baseUrl}/sync/su-co'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'SoPhieuSuCo': ticketCode,
          'KyHieuPhong': roomCode,
          'TieuDe': title,
          'MoTa': description ?? title,
          'UuTien': priority ?? 'Cao',
          'TrangThai': status,
        }),
      );
    } catch (_) {}
  }

  /// Đồng bộ Thông báo mới sang Web Admin & Supabase
  Future<void> syncNotice({
    required String title,
    required String content,
    required String scope,
    required bool isImportant,
  }) async {
    try {
      await sendApiRequest(
        method: 'POST',
        uri: Uri.parse('${ApiService.baseUrl}/sync/thong-bao'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'TieuDe': title,
          'NoiDung': content,
          'PhamViNhan': scope,
          'LaKhanCap': isImportant,
        }),
      );
    } catch (_) {}
  }
}
