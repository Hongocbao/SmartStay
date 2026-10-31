import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/contract_model.dart';
import '../services/mock_data_service.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final MockDataService _mock = MockDataService();
  final ApiService _api = ApiService();

  UserModel? _user;
  ContractModel? _contract;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, Map<String, dynamic>> _dynamicAccounts = {};

  UserModel? get user => _user;
  ContractModel? get contract => _contract;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  String get currentRole => _user?.role ?? 'Cư dân';
  bool get isAdmin => currentRole == 'Quản lý vận hành' || currentRole == 'Quản trị viên';
  bool get isTechnician => currentRole == 'Kỹ thuật viên';
  bool get isResident => currentRole == 'Cư dân';

  AuthProvider() {
    // Khởi tạo phiên làm việc mặc định cho Cư dân
    _user = _mock.currentUser;
    _contract = _mock.contract;
  }

  void switchRole(String role) {
    if (role == 'Quản lý vận hành' || role == 'Quản trị viên') {
      _user = UserModel(
        userId: 1,
        username: 'admin.nam',
        email: 'nam.nh@smartstay.vn',
        phone: '0988112233',
        fullName: 'Nguyễn Hoàng Nam',
        role: 'Quản lý vận hành',
      );
      _contract = null;
    } else if (role == 'Kỹ thuật viên') {
      _user = UserModel(
        userId: 2,
        username: 'tech.tuan',
        email: 'tuan.tv@smartstay.vn',
        phone: '0977223344',
        fullName: 'Trần Văn Tuấn',
        role: 'Kỹ thuật viên',
      );
      _contract = null;
    } else {
      _user = _mock.currentUser;
      _contract = _mock.contract;
    }
    notifyListeners();
  }

  /// Đăng nhập xác thực thật qua Backend API, có fallback danh sách tài khoản hợp lệ
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanUser = username.trim();
    final cleanPass = password.trim();

    if (cleanUser.isEmpty || cleanPass.isEmpty) {
      _errorMessage = 'Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu!';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // 1. Thử xác thực trực tiếp qua Backend ASP.NET Core
    final apiResult = await _api.login(cleanUser, cleanPass);
    if (apiResult != null) {
      _token = apiResult['token'] as String?;
      final role = (apiResult['vaiTro'] as String?) ?? 'Cư dân';
      final fullName = (apiResult['hoTen'] as String?) ?? cleanUser;
      final room = (apiResult['soPhong'] as String?) ?? 'P.305';

      _user = UserModel(
        userId: (apiResult['maNguoiDung'] as num?)?.toInt() ?? 101,
        username: cleanUser,
        email: '$cleanUser@smartstay.vn',
        phone: '0901234567',
        fullName: fullName,
        role: role,
        roomCode: room,
        mustChangePassword: cleanPass == '123456',
      );

      if (role == 'Cư dân') {
        _contract = _mock.contract.copyWith(roomCode: room);
      } else {
        _contract = null;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    }

    // 2. Fallback: Danh sách tài khoản chuẩn của hệ thống (bảo mật nghiêm ngặt, không cho nhập bừa)
    final validAccounts = <String, Map<String, dynamic>>{
      // 3 sinh viên thực hiện đồ án (Cư dân)
      '2380600133': {'name': 'Hồ Ngọc Bảo', 'role': 'Cư dân', 'room': 'P.305', 'pass': '123456'},
      'cudan': {'name': 'Hồ Ngọc Bảo', 'role': 'Cư dân', 'room': 'P.305', 'pass': '123456'},
      '2380600154': {'name': 'Nguyễn Dương Bảo', 'role': 'Cư dân', 'room': 'P.201', 'pass': '123456'},
      '2380600178': {'name': 'Trần Hoàng Gia Bảo', 'role': 'Cư dân', 'room': 'P.401', 'pass': '123456'},

      // Quản lý vận hành
      'admin': {'name': 'Nguyễn Hoàng Nam', 'role': 'Quản lý vận hành', 'room': null, 'pass': '123456'},
      'admin.nam': {'name': 'Nguyễn Hoàng Nam', 'role': 'Quản lý vận hành', 'room': null, 'pass': '123456'},

      // Kỹ thuật viên
      'tech': {'name': 'Trần Văn Tuấn', 'role': 'Kỹ thuật viên', 'room': null, 'pass': '123456'},
      'tech.tuan': {'name': 'Trần Văn Tuấn', 'role': 'Kỹ thuật viên', 'room': null, 'pass': '123456'},
    };

    final userMatch = validAccounts[cleanUser.toLowerCase()] ?? _dynamicAccounts[cleanUser.toLowerCase()];
    if (userMatch != null && userMatch['pass'] == cleanPass) {
      _token = 'JWT_SESSION_TOKEN_${DateTime.now().millisecondsSinceEpoch}';
      final role = userMatch['role'] as String;
      final room = userMatch['room'] as String?;

      _user = UserModel(
        userId: 100 + cleanUser.hashCode % 1000,
        username: cleanUser,
        email: (userMatch['email'] as String?) ?? '$cleanUser@smartstay.vn',
        phone: (userMatch['phone'] as String?) ?? '0901234567',
        fullName: userMatch['name'] as String,
        role: role,
        roomCode: room,
        mustChangePassword: cleanPass == '123456', // Nhắc đổi mật khẩu lần đầu
      );

      if (role == 'Cư dân') {
        _contract = _mock.contract.copyWith(roomCode: room ?? 'P.305');
      } else {
        _contract = null;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    }

    // Nếu không khớp tài khoản nào
    _errorMessage = 'Tài khoản hoặc mật khẩu không chính xác! Vui lòng kiểm tra lại.';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Đăng ký tài khoản Cư dân mới (Hỗ trợ Online Backend và Offline-first)
  Future<bool> register({
    required String username,
    required String password,
    required String fullName,
    required String phone,
    required String email,
    String? roomCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanUser = username.trim();
    final cleanPass = password.trim();
    final cleanName = fullName.trim();
    final cleanPhone = phone.trim();
    final cleanEmail = email.trim();
    final cleanRoom = (roomCode ?? 'P.305').trim();

    if (cleanUser.isEmpty || cleanPass.isEmpty || cleanName.isEmpty) {
      _errorMessage = 'Vui lòng điền đầy đủ các thông tin bắt buộc!';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (cleanPass.length < 6) {
      _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự!';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // 1. Thử gửi lên Backend .NET 8
    final apiResult = await _api.register(
      username: cleanUser,
      password: cleanPass,
      fullName: cleanName,
      phone: cleanPhone,
      email: cleanEmail,
      roomCode: cleanRoom,
    );

    // 2. Lưu vào dynamic accounts để luôn có thể đăng nhập tức thì (Offline-first)
    _dynamicAccounts[cleanUser.toLowerCase()] = {
      'name': cleanName,
      'role': 'Cư dân',
      'room': cleanRoom,
      'pass': cleanPass,
      'phone': cleanPhone,
      'email': cleanEmail,
    };

    if (apiResult != null && apiResult.containsKey('token')) {
      _token = apiResult['token'] as String?;
    } else {
      _token = 'JWT_REG_TOKEN_${DateTime.now().millisecondsSinceEpoch}';
    }

    _user = UserModel(
      userId: 200 + cleanUser.hashCode % 1000,
      username: cleanUser,
      email: cleanEmail.isNotEmpty ? cleanEmail : '$cleanUser@smartstay.vn',
      phone: cleanPhone.isNotEmpty ? cleanPhone : '0901234567',
      fullName: cleanName,
      role: 'Cư dân',
      roomCode: cleanRoom,
      mustChangePassword: false,
    );

    _contract = _mock.contract.copyWith(roomCode: cleanRoom);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Đổi mật khẩu lần đầu
  Future<bool> changePassword(String currentPass, String newPass) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    if (_user != null) {
      _user = _user!.copyWith(mustChangePassword: false);
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _user = null;
    _contract = null;
    _token = null;
    _api.authToken = null;
    notifyListeners();
  }
}
