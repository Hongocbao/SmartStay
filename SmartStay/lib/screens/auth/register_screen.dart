import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';
import '../../utils/provider_scope.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRoom = 'P.305';
  final List<String> _availableRooms = ['P.101', 'P.102', 'P.201', 'P.202', 'P.301', 'P.305', 'P.401', 'P.402', 'P.501', 'P.502'];

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đồng ý với Nội quy và Điều khoản dịch vụ!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      nationalId: _nationalIdController.text.trim(),
      roomCode: _selectedRoom,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Đăng ký thành công! Chào mừng ${_fullNameController.text.trim()} đến với SmartStay.'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Đăng ký xong tự động đăng nhập luôn (hoặc quay lại login nếu cần)
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Đăng ký không thành công. Vui lòng thử lại!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Đăng Ký Tài Khoản',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header giới thiệu
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          color: Color(0xFF2563EB),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cổng Cư Dân SmartStay',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tạo tài khoản để theo dõi hóa đơn, tiền điện nước, dịch vụ IoT và gửi phiếu sự cố.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Card biểu mẫu đăng ký
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Họ và tên
                      _buildFieldLabel('Họ và tên cư dân *'),
                      TextFormField(
                        controller: _fullNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration(
                          hintText: 'Ví dụ: Nguyễn Văn An',
                          prefixIcon: Icons.badge_outlined,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Vui lòng nhập họ và tên';
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildFieldLabel('Số CCCD/CMND *'),
                      TextFormField(
                        controller: _nationalIdController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          hintText: 'Nhập từ 9 đến 12 chữ số',
                          prefixIcon: Icons.credit_card_outlined,
                        ),
                        validator: (value) {
                          final id = value?.trim() ?? '';
                          if (!RegExp(r'^\d{9,12}$').hasMatch(id)) {
                            return 'CCCD/CMND phải gồm từ 9 đến 12 chữ số';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Tên đăng nhập / MSSV
                      _buildFieldLabel('Tên đăng nhập (hoặc MSSV) *'),
                      TextFormField(
                        controller: _usernameController,
                        decoration: _inputDecoration(
                          hintText: 'Ví dụ: 2380600999 hoặc nguyenvana',
                          prefixIcon: Icons.account_circle_outlined,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tên đăng nhập';
                          if (v.trim().length < 4) return 'Tên đăng nhập tối thiểu 4 ký tự';
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Số điện thoại & Phòng
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Số điện thoại *'),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: _inputDecoration(
                                    hintText: '0901234567',
                                    prefixIcon: Icons.phone_android_rounded,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Nhập số điện thoại';
                                    if (v.trim().length < 9) return 'SĐT chưa hợp lệ';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Phòng *'),
                                DropdownButtonFormField<String>(
                                  value: _selectedRoom,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                    ),
                                  ),
                                  items: _availableRooms.map((room) {
                                    return DropdownMenuItem(
                                      value: room,
                                      child: Text(room, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedRoom = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Email
                      _buildFieldLabel('Email liên hệ *'),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(
                          hintText: 'nguyenvanan@smartstay.vn',
                          prefixIcon: Icons.email_outlined,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                          if (!v.contains('@')) return 'Email không hợp lệ';
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Mật khẩu
                      _buildFieldLabel('Mật khẩu *'),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: _inputDecoration(
                          hintText: 'Tối thiểu 8 ký tự',
                          prefixIcon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                              color: const Color(0xFF64748B),
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Vui lòng nhập mật khẩu';
                          if (v.trim().length < 8) return 'Mật khẩu phải từ 8 ký tự trở lên';
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Nhập lại mật khẩu
                      _buildFieldLabel('Xác nhận mật khẩu *'),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: _inputDecoration(
                          hintText: 'Nhập lại mật khẩu vừa tạo',
                          prefixIcon: Icons.lock_reset_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                              color: const Color(0xFF64748B),
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Vui lòng xác nhận mật khẩu';
                          if (v != _passwordController.text) return 'Mật khẩu xác nhận không khớp!';
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Checkbox điều khoản
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _agreedToTerms,
                              activeColor: const Color(0xFF2563EB),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Tôi đồng ý với Nội quy lưu trú & Điều khoản sử dụng SmartStay.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Nút Submit Đăng Ký
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleRegister,
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
                                  'Đăng Ký Tài Khoản Cư Dân',
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

                const SizedBox(height: 20),

                // Link quay lại Đăng nhập
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Đã có tài khoản cư dân?',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Đăng nhập ngay',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      prefixIcon: Icon(prefixIcon, size: 20, color: const Color(0xFF64748B)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }
}
