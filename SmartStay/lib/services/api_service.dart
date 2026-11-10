import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_transport.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Override at build time for Render with --dart-define=API_BASE_URL=https://.../api.
  // Local defaults remain useful for the emulator and local web development.
  static String get baseUrl {
    const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    }
    if (kIsWeb) return 'http://localhost:5096/api';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5096/api';
    }
    return 'http://localhost:5096/api';
  }

  String? authToken;
  bool isConnectedToBackend = false;

  /// Helper thực hiện POST request an toàn đa nền tảng
  Future<Map<String, dynamic>?> _post(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = <String, String>{'content-type': 'application/json'};
      if (authToken != null) {
        headers['authorization'] = 'Bearer $authToken';
      }
      final response = await sendApiRequest(
        method: 'POST',
        uri: Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        isConnectedToBackend = true;
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      isConnectedToBackend = true;
      return null;
    } catch (e) {
      isConnectedToBackend = false;
      debugPrint('ApiService._post error on $endpoint: $e');
      return null;
    }
  }

  /// Helper thực hiện GET request
  Future<dynamic> _get(String endpoint) async {
    try {
      final headers = <String, String>{};
      if (authToken != null) {
        headers['authorization'] = 'Bearer $authToken';
      }
      final response = await sendApiRequest(
        method: 'GET',
        uri: Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        isConnectedToBackend = true;
        return jsonDecode(response.body);
      }
      isConnectedToBackend = true;
      return null;
    } catch (e) {
      isConnectedToBackend = false;
      return null;
    }
  }

  /// Kiểm tra trạng thái Backend .NET 8 (Health Check)
  Future<bool> checkBackendHealth() async {
    try {
      final response = await sendApiRequest(
        method: 'GET',
        uri: Uri.parse('${baseUrl.replaceFirst('/api', '')}/api/health'),
        headers: const {},
      );
      isConnectedToBackend = response.statusCode == 200;
      return isConnectedToBackend;
    } catch (_) {
      isConnectedToBackend = false;
      return false;
    }
  }

  /// Đăng nhập thật qua Backend API (khớp AuthController .NET)
  Future<Map<String, dynamic>?> login(String username, String password) async {
    final res = await _post('/auth/dang-nhap', {
      'TenDangNhap': username,
      'MatKhau': password,
    });

    if (res != null && res.containsKey('token')) {
      authToken = res['token'];
      return res;
    }
    return null;
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final result = await _put('/auth/doi-mat-khau', {
      'MatKhauHienTai': currentPassword,
      'MatKhauMoi': newPassword,
    });
    return result?['success'] == true;
  }

  Future<Map<String, dynamic>?> _put(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = <String, String>{
        'content-type': 'application/json',
        if (authToken != null) 'authorization': 'Bearer $authToken',
      };
      final response = await sendApiRequest(
        method: 'PUT',
        uri: Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      isConnectedToBackend = true;
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (error) {
      isConnectedToBackend = false;
      debugPrint('ApiService._put error on $endpoint: $error');
      return null;
    }
  }

  /// Đăng ký tài khoản cư dân mới qua Backend API
  Future<Map<String, dynamic>?> register({
    required String username,
    required String password,
    required String fullName,
    required String phone,
    required String email,
    required String nationalId,
    String? roomCode,
  }) async {
    final res = await _post('/auth/dang-ky', {
      'TenDangNhap': username,
      'MatKhau': password,
      'HoTen': fullName,
      'SoDienThoai': phone,
      'Email': email,
      'SoCanCuoc': nationalId,
      'SoPhong': roomCode ?? 'P.305',
    });

    if (res != null && res.containsKey('token')) {
      authToken = res['token'];
      return res;
    }
    return res;
  }

  /// Chat trợ lý ảo AI qua Backend RAG (.NET TroLyAiController)
  Future<String?> askAi(String question) async {
    final res = await _post('/tro-ly/chat', {
      'TinNhan': question,
    });

    if (res != null && res.containsKey('traLoi')) {
      return res['traLoi'] as String;
    }
    return null;
  }

  /// Lấy sơ đồ phòng thực tế từ cơ sở dữ liệu SQL Server
  Future<List<dynamic>?> getRoomMatrix() async {
    final res = await _get('/phong/so-do-tang');
    if (res is List) return res;
    return null;
  }

  /// Gửi xác nhận thanh toán sang Backend
  Future<bool> submitPaymentConfirmation(int invoiceId, double amount, String receiptUrl, String? note) async {
    final res = await _post('/hoadon/$invoiceId/xac-nhan-thanh-toan', {
      'SoTien': amount,
      'DuongDanBienLai': receiptUrl,
      'GhiChu': note ?? 'Cư dân gửi thanh toán qua VietQR Mobile App',
    });
    return res != null && res['success'] == true;
  }
}
