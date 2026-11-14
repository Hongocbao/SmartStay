import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';
import '../../utils/provider_scope.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _selectedRole = 'Cư dân';
  final _usernameController = TextEditingController(text: '2380600133');
  final _passwordController = TextEditingController(text: '123456');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRoleChanged(String role) {
    setState(() {
      _selectedRole = role;
      if (role == 'Ban Quản lý & Kỹ thuật') {
        _usernameController.text = 'admin';
        _passwordController.text = '123456';
      } else {
        _usernameController.text = '2380600133';
        _passwordController.text = '123456';
      }
    });
  }

  void _handleLogin() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Đăng nhập không thành công'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      if (auth.user?.mustChangePassword == true) {
        _showFirstLoginPasswordChangeDialog();
      }
    }
  }

  void _showFirstLoginPasswordChangeDialog() {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.security_rounded, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text('Đổi Mật Khẩu Lần Đầu', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tài khoản của bạn đang dùng mật khẩu khởi tạo mặc định (123456). Vui lòng cập nhật mật khẩu mới để tăng cường an toàn thông tin.',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: newPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  prefixIcon: Icon(Icons.lock_reset),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Để sau'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              onPressed: () async {
                if (newPassCtrl.text.trim().length < 8) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mật khẩu mới phải có ít nhất 8 ký tự!')),
                  );
                  return;
                }
                if (newPassCtrl.text != confirmPassCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mật khẩu xác nhận không khớp!')),
                  );
                  return;
                }

                final changed = await context.read<AuthProvider>().changePassword(
                  _passwordController.text,
                  newPassCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(changed
                          ? 'Đổi mật khẩu thành công.'
                          : context.read<AuthProvider>().errorMessage ?? 'Không thể đổi mật khẩu.'),
                      backgroundColor: changed ? const Color(0xFF10B981) : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Cập nhật mật khẩu', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _fillQuickAccount(String username, String password) {
    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
      if (username == 'admin' || username == 'kythuat') {
        _selectedRole = 'Ban Quản lý & Kỹ thuật';
      } else {
        _selectedRole = 'Cư dân';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo & Brand
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'SmartStay',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quản Trị Hệ Sinh Thái Lưu Trú Thông Minh Đa Nền Tảng',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 28),

                // Card Đăng nhập
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Đăng nhập tài khoản',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Phân Quyền',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Tabs chọn phân quyền (Cư dân, Ban Quản lý & Kỹ thuật)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildRoleTab('Cư dân', '🎓 Cư Dân', const Color(0xFF2563EB)),
                            _buildRoleTab('Ban Quản lý & Kỹ thuật', '🛡️ Ban Quản Lý & Kỹ Thuật', const Color(0xFF8B5CF6)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Banner mô tả quyền hạn của vai trò đang chọn
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _roleBannerColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _roleBannerColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(_roleIcon, size: 15, color: _roleBannerColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _roleDescription,
                                style: TextStyle(fontSize: 11, color: _roleBannerColor, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tên đăng nhập
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Tên đăng nhập / MSSV / Số điện thoại',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Mật khẩu
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng liên hệ Ban Quản lý tòa nhà để cấp lại mật khẩu.'),
                              ),
                            );
                          },
                          child: const Text('Quên mật khẩu?', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Nút Đăng nhập
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Đăng nhập ngay',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Điều hướng sang trang Đăng ký Cư dân mới
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Chưa có tài khoản cư dân?',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Đăng ký ngay',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Khu vực chọn nhanh tài khoản Demo khi chấm đồ án
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.touch_app_rounded, size: 16, color: Color(0xFF2563EB)),
                          SizedBox(width: 6),
                          Text(
                            'Chọn nhanh tài khoản Demo (1-chạm):',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _fillQuickAccount('2380600133', '123456'),
                              child: const Text('Cư dân\n(P.305)', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _fillQuickAccount('admin', '123456'),
                              child: const Text('Quản lý\n(Admin)', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _fillQuickAccount('kythuat', '123456'),
                              child: const Text('Kỹ thuật\n(KTV)', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(String role, String label, Color color) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onRoleChanged(role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? color : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Color get _roleBannerColor {
    switch (_selectedRole) {
      case 'Ban Quản lý & Kỹ thuật':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF2563EB);
    }
  }

  IconData get _roleIcon {
    switch (_selectedRole) {
      case 'Ban Quản lý & Kỹ thuật':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.home_work_rounded;
    }
  }

  String get _roleDescription {
    switch (_selectedRole) {
      case 'Ban Quản lý & Kỹ thuật':
        return 'Không gian Ban Quản Lý & Kỹ Thuật: Điều hành sơ đồ phòng, đối soát VietQR, hợp đồng, xử lý Kanban bảo trì, vật tư & khóa IoT.';
      default:
        return 'Không gian Cư Dân (P.305): Quản lý tiền điện nước bậc thang, thanh toán VietQR, báo sự cố và hỏi trợ lý AI.';
    }
  }
}
