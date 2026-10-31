import 'dart:convert';
import 'dart:io' if (dart.library.html) 'dart:html' as io_or_html;
import 'package:flutter/foundation.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Android Emulator: 10.0.2.2:5000, Windows Desktop / Web: localhost:5000
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000/api';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  String? authToken;
  bool isConnectedToBackend = false;

  /// Helper thực hiện POST request an toàn đa nền tảng
  Future<Map<String, dynamic>?> _post(String endpoint, Map<String, dynamic> body) async {
    if (kIsWeb) {
      // Trên Web: nếu không có HTTP client bên ngoài, fallback offline an toàn
      return null;
    }

    try {
      final client = io_or_html.HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);
      final request = await client.postUrl(Uri.parse('$baseUrl$endpoint'));
      request.headers.set('content-type', 'application/json');
      if (authToken != null) {
        request.headers.set('authorization', 'Bearer $authToken');
      }
      request.write(jsonEncode(body));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        isConnectedToBackend = true;
        return jsonDecode(responseBody) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      isConnectedToBackend = false;
      debugPrint('ApiService._post error on $endpoint: $e');
      return null;
    }
  }

  /// Helper thực hiện GET request
  Future<dynamic> _get(String endpoint) async {
    if (kIsWeb) return null;

    try {
      final client = io_or_html.HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);
      final request = await client.getUrl(Uri.parse('$baseUrl$endpoint'));
      if (authToken != null) {
        request.headers.set('authorization', 'Bearer $authToken');
      }
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        isConnectedToBackend = true;
        return jsonDecode(responseBody);
      }
      return null;
    } catch (e) {
      isConnectedToBackend = false;
      return null;
    }
  }

  /// Kiểm tra trạng thái Backend .NET 8 (Health Check)
  Future<bool> checkBackendHealth() async {
    if (kIsWeb) {
      isConnectedToBackend = false;
      return false;
    }
    try {
      final client = io_or_html.HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);
      final request = await client.getUrl(Uri.parse('$baseUrl/phong/so-do-tang'));
      final response = await request.close();
      client.close();
      isConnectedToBackend = (response.statusCode == 200);
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

  /// Đăng ký tài khoản cư dân mới qua Backend API
  Future<Map<String, dynamic>?> register({
    required String username,
    required String password,
    required String fullName,
    required String phone,
    required String email,
    String? roomCode,
  }) async {
    final res = await _post('/auth/dang-ky', {
      'TenDangNhap': username,
      'MatKhau': password,
      'HoTen': fullName,
      'SoDienThoai': phone,
      'Email': email,
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
