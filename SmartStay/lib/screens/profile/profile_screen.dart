import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_transport.dart';
import '../../utils/formatters.dart';
import '../../utils/provider_scope.dart';

class _AvatarPreset {
  final String key;
  final String label;
  final IconData icon;
  final List<Color> gradient;

  const _AvatarPreset({
    required this.key,
    required this.label,
    required this.icon,
    required this.gradient,
  });
}

const List<_AvatarPreset> _avatarPresets = [
  _AvatarPreset(
    key: 'preset:indigo',
    label: 'Indigo',
    icon: Icons.person_rounded,
    gradient: [Color(0xFF4F46E5), Color(0xFF2563EB)],
  ),
  _AvatarPreset(
    key: 'preset:emerald',
    label: 'Emerald',
    icon: Icons.eco_rounded,
    gradient: [Color(0xFF059669), Color(0xFF10B981)],
  ),
  _AvatarPreset(
    key: 'preset:amber',
    label: 'Amber',
    icon: Icons.wb_sunny_rounded,
    gradient: [Color(0xFFD97706), Color(0xFFF59E0B)],
  ),
  _AvatarPreset(
    key: 'preset:rose',
    label: 'Rose',
    icon: Icons.favorite_rounded,
    gradient: [Color(0xFFE11D48), Color(0xFFF43F5E)],
  ),
  _AvatarPreset(
    key: 'preset:violet',
    label: 'Violet',
    icon: Icons.auto_awesome_rounded,
    gradient: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
  ),
  _AvatarPreset(
    key: 'preset:cyan',
    label: 'Cyan',
    icon: Icons.waves_rounded,
    gradient: [Color(0xFF0891B2), Color(0xFF06B6D4)],
  ),
];

_AvatarPreset? _findPreset(String? key) {
  if (key == null) return null;
  for (final preset in _avatarPresets) {
    if (preset.key == key) return preset;
  }
  return null;
}

String _safeField(String? value, String fallback) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
    return fallback;
  }
  return trimmed;
}

/// Widget hiển thị Ảnh đại diện dùng chung (Data URL base64, Network URL, Preset, hoặc Chữ cái đầu)
class UserAvatarWidget extends StatelessWidget {
  final UserModel? user;
  final String? avatarUrlOverride;
  final double radius;
  final double? fontSize;
  final String? fallbackText;

  const UserAvatarWidget({
    super.key,
    required this.user,
    this.avatarUrlOverride,
    this.radius = 36,
    this.fontSize,
    this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = _safeField(user?.fullName, 'Hồ Ngọc Bảo');
    final computedInitial =
        fullName.split(RegExp(r'\s+')).last[0].toUpperCase();
    final letter = (fallbackText != null && fallbackText!.isNotEmpty)
        ? fallbackText!
        : computedInitial;

    final defaultAvatar = CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF2563EB),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: fontSize ?? (radius * 0.72),
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );

    final effectiveUrl = (avatarUrlOverride ?? user?.avatarUrl)?.trim();
    if (effectiveUrl == null || effectiveUrl.isEmpty) {
      return defaultAvatar;
    }

    final preset = _findPreset(effectiveUrl);
    if (preset != null) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: preset.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          preset.icon,
          size: radius * 1.05,
          color: Colors.white,
        ),
      );
    }

    if (effectiveUrl.startsWith('data:image/')) {
      final commaIndex = effectiveUrl.indexOf(',');
      if (commaIndex != -1 && commaIndex + 1 < effectiveUrl.length) {
        try {
          final bytes = base64Decode(effectiveUrl.substring(commaIndex + 1));
          return CircleAvatar(
            radius: radius,
            backgroundColor: const Color(0xFFE2E8F0),
            child: ClipOval(
              child: Image.memory(
                bytes,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => defaultAvatar,
              ),
            ),
          );
        } catch (_) {
          return defaultAvatar;
        }
      }
      return defaultAvatar;
    }

    if (effectiveUrl.startsWith('http://') ||
        effectiveUrl.startsWith('https://')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFE2E8F0),
        child: ClipOval(
          child: Image.network(
            effectiveUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => defaultAvatar,
          ),
        ),
      );
    }

    return defaultAvatar;
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _openAvatarPicker(BuildContext context, UserModel? user) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AvatarPickerDialog(user: user),
    );
  }

  Future<void> _openEditProfile(BuildContext context, UserModel? user) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _EditProfileDialog(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final profile = user?.residentProfile;
    final contract = auth.contract;

    final fullName = _safeField(user?.fullName, 'Hồ Ngọc Bảo');
    final username = _safeField(user?.username, '2380600133');
    final role = _safeField(user?.role, 'Cư dân');
    final phone = _safeField(user?.phone, '0901234567');
    final email = _safeField(user?.email, 'hongocbao@smartstay.vn');
    final idCard = _safeField(profile?.idCardNumber, '079203001234');
    final gender = _safeField(profile?.gender, 'Nam');
    final dob = profile?.dateOfBirth ?? DateTime(2003, 5, 15);
    final roomCode = _safeField(profile?.roomCode ?? user?.roomCode, 'P.305');
    final buildingName =
        _safeField(profile?.buildingName, 'Tòa nhà A - Co-Living SmartStay');
    final permanentAddress = _safeField(
      profile?.permanentAddress,
      '123 Đường Điện Biên Phủ, Phường 25, Bình Thạnh, TP.HCM',
    );
    final emergencyName =
        _safeField(profile?.emergencyContactName, 'Hồ Văn Minh (Phụ huynh)');
    final emergencyPhone =
        _safeField(profile?.emergencyContactPhone, '0988776655');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Cá nhân & Hợp đồng'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              children: [
                // Header Hồ sơ cá nhân
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Semantics(
                            button: true,
                            label: 'Đổi ảnh đại diện',
                            child: InkWell(
                              onTap: () => _openAvatarPicker(context, user),
                              borderRadius: BorderRadius.circular(56),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: UserAvatarWidget(user: user, radius: 42),
                              ),
                            ),
                          ),
                          Material(
                            color: const Color(0xFF2563EB),
                            shape: const CircleBorder(
                              side: BorderSide(color: Colors.white, width: 2.5),
                            ),
                            elevation: 2,
                            child: InkWell(
                              onTap: () => _openAvatarPicker(context, user),
                              customBorder: const CircleBorder(),
                              child: const SizedBox(
                                width: 32,
                                height: 32,
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mã cư dân: $username • Vai trò: $role',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _openAvatarPicker(context, user),
                            icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                            label: const Text('Đổi ảnh đại diện'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1E293B),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              minimumSize: const Size(0, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _openEditProfile(context, user),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Chỉnh sửa hồ sơ'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size(0, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28),
                      _buildProfileRow(
                        Icons.phone_outlined,
                        'Số điện thoại',
                        phone,
                      ),
                      _buildProfileRow(
                        Icons.email_outlined,
                        'Email',
                        email,
                      ),
                      _buildProfileRow(
                        Icons.badge_outlined,
                        'Số CCCD',
                        idCard,
                      ),
                      _buildProfileRow(
                        Icons.cake_outlined,
                        'Giới tính & Ngày sinh',
                        '$gender • ${AppFormatters.date(dob)}',
                      ),
                      _buildProfileRow(
                        Icons.home_outlined,
                        'Phòng lưu trú',
                        '$roomCode ($buildingName)',
                      ),
                      _buildProfileRow(
                        Icons.location_on_outlined,
                        'Địa chỉ thường trú',
                        permanentAddress,
                      ),
                      _buildProfileRow(
                        Icons.contact_emergency_outlined,
                        'Liên hệ khẩn cấp',
                        '$emergencyName - $emergencyPhone',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Thông tin Hợp đồng điện tử
                if (contract != null) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.description_outlined,
                                    color: Color(0xFF2563EB),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Hợp đồng ${contract.contractCode}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                contract.status,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _buildContractRow(
                          'Thời hạn hợp đồng:',
                          '${AppFormatters.date(contract.startDate)} - ${AppFormatters.date(contract.endDate)}',
                        ),
                        _buildContractRow(
                          'Giá thuê hàng tháng:',
                          AppFormatters.currency(contract.monthlyRent),
                        ),
                        _buildContractRow(
                          'Tiền đặt cọc giữ phòng:',
                          AppFormatters.currency(contract.depositAmount),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          contract.terms,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Danh mục tài sản bàn giao trong phòng
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              color: Color(0xFFEA580C),
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Danh mục tài sản bàn giao kiểm kê',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Kiểm kê bàn giao khi nhận phòng (Check-in):',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const Divider(height: 20),
                        ...contract.assets.map((a) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 18,
                                  color: Color(0xFF16A34A),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${a.assetName} (SL: ${a.quantity})',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Tình trạng: ${a.condition}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Đền bù: ${AppFormatters.currency(a.compensationValue)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Nút Đăng xuất
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: auth.logout,
                    icon: const Icon(Icons.logout, color: Color(0xFFDC2626)),
                    label: const Text(
                      'Đăng xuất tài khoản',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          SizedBox(
            width: 124,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPickerDialog extends StatefulWidget {
  final UserModel? user;

  const _AvatarPickerDialog({required this.user});

  @override
  State<_AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends State<_AvatarPickerDialog> {
  late String? _selectedAvatarUrl;
  late final TextEditingController _urlController;
  String? _urlError;

  @override
  void initState() {
    super.initState();
    _selectedAvatarUrl = widget.user?.avatarUrl;
    final initialUrl = _selectedAvatarUrl;
    _urlController = TextEditingController(
      text: (initialUrl != null &&
              (initialUrl.startsWith('http://') ||
                  initialUrl.startsWith('https://')))
          ? initialUrl
          : '',
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickDeviceImage() async {
    final dataUrl = await pickImageDataUrl();
    if (!mounted) return;
    if (dataUrl == null || dataUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Thiết bị chưa hỗ trợ chọn tệp trực tiếp; vui lòng chọn mẫu Avatar hoặc nhập URL ảnh.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _selectedAvatarUrl = dataUrl;
      _urlError = null;
    });
  }

  void _applyImageUrl() {
    final trimmed = _urlController.text.trim();
    if (trimmed.isEmpty ||
        (!trimmed.startsWith('http://') && !trimmed.startsWith('https://'))) {
      setState(() {
        _urlError = 'URL ảnh phải bắt đầu bằng http:// hoặc https://';
      });
      return;
    }
    setState(() {
      _selectedAvatarUrl = trimmed;
      _urlError = null;
    });
  }

  void _saveAndClose() {
    final auth = context.read<AuthProvider>();
    final chosen = _selectedAvatarUrl;
    auth.updateAvatar(chosen, clear: chosen == null);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          chosen == null
              ? 'Đã khôi phục ảnh đại diện mặc định.'
              : 'Đã cập nhật ảnh đại diện thành công!',
        ),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewUser = widget.user?.copyWith(
      avatarUrl: _selectedAvatarUrl,
      clearAvatar: _selectedAvatarUrl == null,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_circle_outlined,
                    color: Color(0xFF2563EB),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Cập nhật ảnh đại diện',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    UserAvatarWidget(
                      user: previewUser,
                      avatarUrlOverride: _selectedAvatarUrl,
                      radius: 34,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _safeField(widget.user?.fullName, 'Hồ Ngọc Bảo'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Hỗ trợ PNG, JPG, WEBP từ thiết bị hoặc chọn mẫu bên dưới.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _pickDeviceImage,
                  icon: const Icon(Icons.upload_file_rounded, size: 19),
                  label: const Text(
                    'Tải ảnh từ thiết bị',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEEF2FF),
                    foregroundColor: const Color(0xFF4F46E5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFC7D2FE)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hoặc chọn mẫu Avatar SmartStay',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: _avatarPresets.map((preset) {
                  final isSelected = _selectedAvatarUrl == preset.key;
                  return Tooltip(
                    message: preset.label,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedAvatarUrl = preset.key;
                          _urlError = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0F172A)
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: preset.gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            isSelected ? Icons.check_rounded : preset.icon,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hoặc nhập đường dẫn ảnh (URL)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        hintText: 'https://example.com/avatar.jpg',
                        errorText: _urlError,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: _applyImageUrl,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Thử URL'),
                    ),
                  ),
                ],
              ),
              if (_selectedAvatarUrl != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedAvatarUrl = null;
                        _urlError = null;
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Dùng chữ cái tên mặc định'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      minimumSize: const Size(0, 44),
                    ),
                  ),
                ),
              ],
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _saveAndClose,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Lưu ảnh đại diện'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final UserModel? user;

  const _EditProfileDialog({required this.user});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _idCardCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _emergencyNameCtrl;
  late final TextEditingController _emergencyPhoneCtrl;
  late String _gender;
  late DateTime _dateOfBirth;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    final profile = user?.residentProfile;

    _fullNameCtrl = TextEditingController(
      text: _safeField(user?.fullName, 'Hồ Ngọc Bảo'),
    );
    _phoneCtrl = TextEditingController(
      text: _safeField(user?.phone, '0901234567'),
    );
    _emailCtrl = TextEditingController(
      text: _safeField(user?.email, 'hongocbao@smartstay.vn'),
    );
    _idCardCtrl = TextEditingController(
      text: _safeField(profile?.idCardNumber, '079203001234'),
    );
    _addressCtrl = TextEditingController(
      text: _safeField(
        profile?.permanentAddress,
        '123 Đường Điện Biên Phủ, Phường 25, Bình Thạnh, TP.HCM',
      ),
    );
    _emergencyNameCtrl = TextEditingController(
      text: _safeField(
        profile?.emergencyContactName,
        'Hồ Văn Minh (Phụ huynh)',
      ),
    );
    _emergencyPhoneCtrl = TextEditingController(
      text: _safeField(profile?.emergencyContactPhone, '0988776655'),
    );

    const allowedGenders = ['Nam', 'Nữ', 'Khác'];
    final currentGender = _safeField(profile?.gender, 'Nam');
    _gender = allowedGenders.contains(currentGender) ? currentGender : 'Nam';
    _dateOfBirth = profile?.dateOfBirth ?? DateTime(2003, 5, 15);
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _idCardCtrl.dispose();
    _addressCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      helpText: 'Chọn ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (picked != null && mounted) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthProvider>().updateUserProfile(
          fullName: _fullNameCtrl.text,
          phone: _phoneCtrl.text,
          email: _emailCtrl.text,
          idCardNumber: _idCardCtrl.text,
          gender: _gender,
          dateOfBirth: _dateOfBirth,
          permanentAddress: _addressCtrl.text,
          emergencyContactName: _emergencyNameCtrl.text,
          emergencyContactPhone: _emergencyPhoneCtrl.text,
        );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu thông tin hồ sơ cá nhân thành công!'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19, color: const Color(0xFF64748B)),
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.manage_accounts_outlined,
                    color: Color(0xFF2563EB),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Chỉnh sửa hồ sơ cá nhân',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _fullNameCtrl,
                        decoration:
                            _inputDecoration('Họ và tên *', Icons.person_outline),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Vui lòng nhập họ và tên'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          'Số điện thoại *',
                          Icons.phone_outlined,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Vui lòng nhập số điện thoại'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration:
                            _inputDecoration('Email *', Icons.email_outlined),
                        validator: (v) {
                          final clean = v?.trim() ?? '';
                          if (clean.isEmpty || !clean.contains('@')) {
                            return 'Vui lòng nhập email hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _idCardCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          'Số CCCD / Định danh',
                          Icons.badge_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final genderField = DropdownButtonFormField<String>(
                            initialValue: _gender,
                            decoration: _inputDecoration(
                              'Giới tính',
                              Icons.wc_outlined,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                              DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                              DropdownMenuItem(
                                value: 'Khác',
                                child: Text('Khác'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _gender = value);
                              }
                            },
                          );

                          final dobField = InkWell(
                            onTap: _pickDateOfBirth,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: _inputDecoration(
                                'Ngày sinh',
                                Icons.cake_outlined,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppFormatters.date(_dateOfBirth),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 16,
                                    color: Color(0xFF64748B),
                                  ),
                                ],
                              ),
                            ),
                          );

                          if (constraints.maxWidth >= 380) {
                            return Row(
                              children: [
                                Expanded(child: genderField),
                                const SizedBox(width: 12),
                                Expanded(child: dobField),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              genderField,
                              const SizedBox(height: 12),
                              dobField,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressCtrl,
                        maxLines: 2,
                        decoration: _inputDecoration(
                          'Địa chỉ thường trú',
                          Icons.location_on_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emergencyNameCtrl,
                        decoration: _inputDecoration(
                          'Người liên hệ khẩn cấp',
                          Icons.contact_emergency_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emergencyPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          'SĐT liên hệ khẩn cấp',
                          Icons.phone_in_talk_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Lưu thay đổi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
