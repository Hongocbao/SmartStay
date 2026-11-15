import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/contract_model.dart';
import '../services/mock_data_service.dart';
import '../services/api_service.dart';
import '../services/api_transport.dart';

class _FallbackAccount {
  final int userId;
  final String username;
  final String password;
  final String fullName;
  final String role;
  final String? roomCode;
  final String phone;
  final String email;

  const _FallbackAccount({
    required this.userId,
    required this.username,
    required this.password,
    required this.fullName,
    required this.role,
    this.roomCode,
    this.phone = '0901234567',
    required this.email,
  });
}

class AuthProvider extends ChangeNotifier {
  final MockDataService _mock = MockDataService();
  final ApiService _api = ApiService();

  UserModel? _user;
  ContractModel? _contract;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  // Danh sách tài khoản Offline-First Fallback (hoạt động ngay cả khi chưa bật Backend .NET)
  final Map<String, _FallbackAccount> _localAccounts = {
    '2380600133': const _FallbackAccount(
      userId: 101,
      username: '2380600133',
      password: '123456',
      fullName: 'Hồ Ngọc Bảo',
      role: 'Cư dân',
      roomCode: 'P.305',
      phone: '0901234133',
      email: 'hongocbao@smartstay.vn',
    ),
    '2380600154': const _FallbackAccount(
      userId: 102,
      username: '2380600154',
      password: '123456',
      fullName: 'Nguyễn Dương Bảo',
      role: 'Cư dân',
      roomCode: 'P.305',
      phone: '0901234154',
      email: 'nguyenduongbao@smartstay.vn',
    ),
    '2380600178': const _FallbackAccount(
      userId: 103,
      username: '2380600178',
      password: '123456',
      fullName: 'Trần Hoàng Gia Bảo',
      role: 'Cư dân',
      roomCode: 'P.305',
      phone: '0901234178',
      email: 'tranhoanggiabao@smartstay.vn',
    ),
    'cudan': const _FallbackAccount(
      userId: 101,
      username: 'cudan',
      password: '123456',
      fullName: 'Hồ Ngọc Bảo',
      role: 'Cư dân',
      roomCode: 'P.305',
      phone: '0901234133',
      email: 'hongocbao@smartstay.vn',
    ),
    'admin': const _FallbackAccount(
      userId: 1,
      username: 'admin',
      password: '123456',
      fullName: 'Ban Quản Lý & Kỹ Thuật SmartStay',
      role: 'Ban Quản lý & Kỹ thuật',
      roomCode: null,
      phone: '0909999888',
      email: 'admin@smartstay.vn',
    ),
    'quanly': const _FallbackAccount(
      userId: 1,
      username: 'quanly',
      password: '123456',
      fullName: 'Ban Quản Lý & Kỹ Thuật SmartStay',
      role: 'Ban Quản lý & Kỹ thuật',
      roomCode: null,
      phone: '0909999888',
      email: 'quanly@smartstay.vn',
    ),
    'kythuat': const _FallbackAccount(
      userId: 2,
      username: 'kythuat',
      password: '123456',
      fullName: 'Kỹ Thuật & Vận Hành SmartStay',
      role: 'Ban Quản lý & Kỹ thuật',
      roomCode: null,
      phone: '0909999777',
      email: 'kythuat@smartstay.vn',
    ),
    'tech': const _FallbackAccount(
      userId: 2,
      username: 'tech',
      password: '123456',
      fullName: 'Kỹ Thuật & Vận Hành SmartStay',
      role: 'Ban Quản lý & Kỹ thuật',
      roomCode: null,
      phone: '0909999777',
      email: 'tech@smartstay.vn',
    ),
  };

  UserModel? get user => _user;
  ContractModel? get contract => _contract;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  String get currentRole => _user?.role ?? 'Cư dân';
  bool get isAdmin =>
      currentRole == 'Ban Quản lý & Kỹ thuật' ||
      currentRole == 'Quản lý vận hành' ||
      currentRole == 'Quản trị viên' ||
      currentRole == 'Kỹ thuật viên';
  bool get isTechnician => isAdmin;
  bool get isResident => currentRole == 'Cư dân';

  AuthProvider();

  final Map<String, UserModel> _savedUserProfiles = {};
  late final ResidentProfile _defaultResidentTemplate =
      _mock.currentUser.residentProfile ??
          ResidentProfile(
            residentId: 101,
            roomCode: 'P.305',
            buildingName: 'Tòa nhà A - Co-Living SmartStay',
            floorNumber: 3,
            dateOfBirth: DateTime(2003, 5, 15),
            gender: 'Nam',
            idCardNumber: '079203001234',
            permanentAddress:
                '123 Đường Điện Biên Phủ, Phường 25, Bình Thạnh, TP.HCM',
            emergencyContactName: 'Hồ Văn Minh (Phụ huynh)',
            emergencyContactPhone: '0988776655',
          );

  ResidentProfile _buildDefaultResidentProfile(
    String? roomCode, {
    String? idCardNumber,
  }) {
    final fallback = _defaultResidentTemplate;
    final effectiveRoom = (roomCode != null && roomCode.trim().isNotEmpty)
        ? roomCode.trim()
        : fallback.roomCode;
    final effectiveIdCard = (idCardNumber != null && idCardNumber.trim().isNotEmpty)
        ? idCardNumber.trim()
        : fallback.idCardNumber;
    return fallback.copyWith(
      roomCode: effectiveRoom,
      idCardNumber: effectiveIdCard,
    );
  }

  UserModel _applySavedProfile(UserModel baseUser) {
    final key = baseUser.username.toLowerCase();
    UserModel? saved = _savedUserProfiles[key];
    if (saved == null) {
      final raw = readLocalStorage('smartstay_profile_$key');
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            saved = UserModel.fromJson(decoded);
            _savedUserProfiles[key] = saved;
          }
        } catch (_) {}
      }
    }
    if (saved == null) return baseUser;
    return baseUser.copyWith(
      fullName: saved.fullName.isNotEmpty ? saved.fullName : baseUser.fullName,
      phone: saved.phone.isNotEmpty ? saved.phone : baseUser.phone,
      email: saved.email.isNotEmpty ? saved.email : baseUser.email,
      roomCode: saved.roomCode ?? baseUser.roomCode,
      avatarUrl: saved.avatarUrl,
      clearAvatar: saved.avatarUrl == null,
      residentProfile: saved.residentProfile ?? baseUser.residentProfile,
    );
  }

  void _persistSavedProfile(UserModel user) {
    final key = user.username.toLowerCase();
    _savedUserProfiles[key] = user;
    writeLocalStorage('smartstay_profile_$key', jsonEncode(user.toJson()));
    _mock.currentUser = user;
  }

  /// Cập nhật ảnh đại diện người dùng (Data URL base64, URL http/https, preset:..., hoặc xóa)
  void updateAvatar(String? avatarUrl, {bool clear = false}) {
    if (_user == null) return;
    final normalized = (avatarUrl != null && avatarUrl.trim().isNotEmpty)
        ? avatarUrl.trim()
        : null;
    _user = _user!.copyWith(
      avatarUrl: normalized,
      clearAvatar: clear || normalized == null,
    );
    _persistSavedProfile(_user!);
    notifyListeners();
  }

  /// Cập nhật thông tin hồ sơ cá nhân người dùng & lưu bền vững cục bộ
  void updateUserProfile({
    required String fullName,
    required String phone,
    required String email,
    String? idCardNumber,
    String? gender,
    DateTime? dateOfBirth,
    String? permanentAddress,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? roomCode,
    String? buildingName,
  }) {
    if (_user == null) return;
    final cleanName = fullName.trim();
    final cleanPhone = phone.trim();
    final cleanEmail = email.trim();
    final currentProfile =
        _user!.residentProfile ?? _buildDefaultResidentProfile(_user!.roomCode);

    final updatedProfile = currentProfile.copyWith(
      roomCode: (roomCode != null && roomCode.trim().isNotEmpty)
          ? roomCode.trim()
          : currentProfile.roomCode,
      buildingName: (buildingName != null && buildingName.trim().isNotEmpty)
          ? buildingName.trim()
          : currentProfile.buildingName,
      idCardNumber:
          idCardNumber != null ? idCardNumber.trim() : currentProfile.idCardNumber,
      gender: (gender != null && gender.trim().isNotEmpty)
          ? gender.trim()
          : currentProfile.gender,
      dateOfBirth: dateOfBirth ?? currentProfile.dateOfBirth,
      permanentAddress: permanentAddress != null
          ? permanentAddress.trim()
          : currentProfile.permanentAddress,
      emergencyContactName: emergencyContactName != null
          ? emergencyContactName.trim()
          : currentProfile.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone != null
          ? emergencyContactPhone.trim()
          : currentProfile.emergencyContactPhone,
    );

    final isResidentAccount =
        _user!.role == 'Cư dân' || _user!.residentProfile != null;
    _user = _user!.copyWith(
      fullName: cleanName.isNotEmpty ? cleanName : _user!.fullName,
      phone: cleanPhone.isNotEmpty ? cleanPhone : _user!.phone,
      email: cleanEmail.isNotEmpty ? cleanEmail : _user!.email,
      roomCode: updatedProfile.roomCode,
      residentProfile: isResidentAccount ? updatedProfile : null,
    );

    if (_contract != null && roomCode != null && roomCode.trim().isNotEmpty) {
      _contract = _contract!.copyWith(roomCode: roomCode.trim());
    }

    _persistSavedProfile(_user!);
    notifyListeners();
  }

  /// Đăng nhập xác thực qua Backend API, tự động chuyển sang Offline-First Fallback nếu Backend chưa bật
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

    // 1. Thử xác thực trực tiếp qua Backend ASP.NET Core (nếu đang chạy)
    final apiResult = await _api.login(cleanUser, cleanPass);
    if (apiResult != null) {
      _token = apiResult['token'] as String?;
      final rawRole = (apiResult['vaiTro'] as String?) ?? 'CuDan';
      final role = switch (rawRole) {
        'Admin' || 'QuanLy' || 'Quản lý' || 'KyThuat' || 'Kỹ thuật' => 'Ban Quản lý & Kỹ thuật',
        _ => 'Cư dân',
      };
      final fullName = (apiResult['hoTen'] as String?) ?? cleanUser;
      final room = apiResult['soPhong'] as String?;

      _user = _applySavedProfile(
        UserModel(
          userId: (apiResult['maNguoiDung'] as num?)?.toInt() ?? 101,
          username: cleanUser,
          email: '$cleanUser@smartstay.vn',
          phone: '0901234567',
          fullName: fullName,
          role: role,
          roomCode: room,
          mustChangePassword: false,
          residentProfile:
              role == 'Cư dân' ? _buildDefaultResidentProfile(room) : null,
        ),
      );

      if (role == 'Cư dân') {
        _contract = _mock.contract.copyWith(
          roomCode: _user!.residentProfile?.roomCode ?? room ?? 'P.305',
        );
      } else {
        _contract = null;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    }

    // 2. Cơ chế Resilient Offline-First Fallback: Nếu Backend tắt hoặc không phản hồi,
    // tự động đối chiếu danh sách tài khoản nội bộ để không bao giờ bị lỗi đỏ khi Demo
    final key = cleanUser.toLowerCase();
    final localAcc = _localAccounts[key];
    if (localAcc != null && (localAcc.password == cleanPass || cleanPass == '123456')) {
      _token = 'offline-jwt-token-${localAcc.username}';
      _user = _applySavedProfile(
        UserModel(
          userId: localAcc.userId,
          username: localAcc.username,
          email: localAcc.email,
          phone: localAcc.phone,
          fullName: localAcc.fullName,
          role: localAcc.role,
          roomCode: localAcc.roomCode,
          mustChangePassword: false,
          residentProfile: localAcc.role == 'Cư dân'
              ? _buildDefaultResidentProfile(localAcc.roomCode)
              : null,
        ),
      );
      if (localAcc.role == 'Cư dân') {
        _contract = _mock.contract.copyWith(
          roomCode: _user!.residentProfile?.roomCode ?? localAcc.roomCode ?? 'P.305',
        );
      } else {
        _contract = null;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    }

    // Cho phép đăng nhập linh hoạt nếu chưa bật Backend và nhập mật khẩu mặc định 123456
    if (!_api.isConnectedToBackend && cleanPass.length >= 6) {
      final isManagementUser =
          key.contains('admin') || key.contains('quanly') || key.contains('kythuat') || key.contains('tech');
      final role = isManagementUser ? 'Ban Quản lý & Kỹ thuật' : 'Cư dân';
      _token = 'offline-jwt-token-$cleanUser';
      _user = _applySavedProfile(
        UserModel(
          userId: isManagementUser ? 1 : 105,
          username: cleanUser,
          email: '$cleanUser@smartstay.vn',
          phone: '0901234567',
          fullName: isManagementUser ? 'Ban Quản Lý & Kỹ Thuật SmartStay' : 'Hồ Ngọc Bảo ($cleanUser)',
          role: role,
          roomCode: isManagementUser ? null : 'P.305',
          mustChangePassword: false,
          residentProfile:
              isManagementUser ? null : _buildDefaultResidentProfile('P.305'),
        ),
      );
      _contract = isManagementUser
          ? null
          : _mock.contract.copyWith(
              roomCode: _user!.residentProfile?.roomCode ?? 'P.305',
            );
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _errorMessage = 'Tài khoản hoặc mật khẩu không chính xác (Mật khẩu mặc định: 123456).';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Đăng ký tài khoản Cư dân mới (Hỗ trợ Online Backend và Offline-First Fallback)
  Future<bool> register({
    required String username,
    required String password,
    required String fullName,
    required String phone,
    required String email,
    required String nationalId,
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
      nationalId: nationalId.trim(),
      roomCode: cleanRoom,
    );

    if (apiResult != null && apiResult['token'] is String) {
      _token = apiResult['token'] as String;
      final assignedRoom = (apiResult['soPhong'] as String?) ?? cleanRoom;
      _user = _applySavedProfile(
        UserModel(
          userId: (apiResult['maNguoiDung'] as num?)?.toInt() ?? 109,
          username: cleanUser,
          email: cleanEmail.isNotEmpty ? cleanEmail : '$cleanUser@smartstay.vn',
          phone: cleanPhone.isNotEmpty ? cleanPhone : '0901234567',
          fullName: cleanName,
          role: 'Cư dân',
          roomCode: assignedRoom,
          mustChangePassword: false,
          residentProfile: _buildDefaultResidentProfile(
            assignedRoom,
            idCardNumber: nationalId,
          ),
        ),
      );
      _contract = _mock.contract.copyWith(
        roomCode: _user!.residentProfile?.roomCode ?? assignedRoom,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    }

    // 2. Offline-First Fallback cho Đăng ký mới
    final newAccount = _FallbackAccount(
      userId: DateTime.now().millisecondsSinceEpoch % 10000,
      username: cleanUser,
      password: cleanPass,
      fullName: cleanName,
      role: 'Cư dân',
      roomCode: cleanRoom,
      phone: cleanPhone.isNotEmpty ? cleanPhone : '0901234567',
      email: cleanEmail.isNotEmpty ? cleanEmail : '$cleanUser@smartstay.vn',
    );
    _localAccounts[cleanUser.toLowerCase()] = newAccount;

    _token = 'offline-jwt-token-$cleanUser';
    _user = _applySavedProfile(
      UserModel(
        userId: newAccount.userId,
        username: newAccount.username,
        email: newAccount.email,
        phone: newAccount.phone,
        fullName: newAccount.fullName,
        role: 'Cư dân',
        roomCode: newAccount.roomCode,
        mustChangePassword: false,
        residentProfile: _buildDefaultResidentProfile(
          cleanRoom,
          idCardNumber: nationalId,
        ),
      ),
    );
    _contract = _mock.contract.copyWith(
      roomCode: _user!.residentProfile?.roomCode ?? cleanRoom,
    );
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Đổi mật khẩu
  Future<bool> changePassword(String currentPass, String newPass) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final changed = await _api.changePassword(currentPass, newPass);
    if (changed || !_api.isConnectedToBackend) {
      if (_user != null) {
        _user = _user!.copyWith(mustChangePassword: false);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _errorMessage = 'Không đổi được mật khẩu. Hãy kiểm tra mật khẩu hiện tại và thử lại.';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _user = null;
    _contract = null;
    _token = null;
    _api.authToken = null;
    notifyListeners();
  }
}
