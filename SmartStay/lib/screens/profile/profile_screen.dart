import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';
import '../../utils/provider_scope.dart';
import '../../utils/formatters.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final profile = user?.residentProfile;
    final contract = auth.contract;

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
        child: Column(
          children: [
            // Header Hồ sơ cá nhân
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF2563EB),
                    child: Text(
                      (user?.fullName.isNotEmpty == true) ? user!.fullName.trim().split(' ').last[0] : 'B',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.fullName ?? 'Hồ Ngọc Bảo',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mã cư dân: ${user?.username} • Vai trò: ${user?.role}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const Divider(height: 24),
                  _buildProfileRow(Icons.phone_outlined, 'Số điện thoại', user?.phone ?? ''),
                  _buildProfileRow(Icons.email_outlined, 'Email', user?.email ?? ''),
                  _buildProfileRow(Icons.badge_outlined, 'Số CCCD', profile?.idCardNumber ?? ''),
                  _buildProfileRow(Icons.home_outlined, 'Phòng lưu trú',
                      '${profile?.roomCode} (${profile?.buildingName})'),
                  _buildProfileRow(Icons.contact_emergency_outlined, 'Liên hệ khẩn cấp',
                      '${profile?.emergencyContactName} - ${profile?.emergencyContactPhone}'),
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
                        Row(
                          children: [
                            const Icon(Icons.description_outlined, color: Color(0xFF2563EB), size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Hợp đồng ${contract.contractCode}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            contract.status,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildContractRow('Thời hạn hợp đồng:',
                        '${AppFormatters.date(contract.startDate)} - ${AppFormatters.date(contract.endDate)}'),
                    _buildContractRow('Giá thuê hàng tháng:', AppFormatters.currency(contract.monthlyRent)),
                    _buildContractRow('Tiền đặt cọc giữ phòng:', AppFormatters.currency(contract.depositAmount)),
                    const SizedBox(height: 8),
                    Text(
                      contract.terms,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
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
                        Icon(Icons.inventory_2_outlined, color: Color(0xFFEA580C), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Danh mục tài sản bàn giao kiểm kê',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text('Kiểm kê bàn giao khi nhận phòng (Check-in):',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const Divider(height: 20),
                    ...contract.assets.map((a) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF16A34A)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${a.assetName} (SL: ${a.quantity})',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Tình trạng: ${a.condition}',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            Text(
                              'Đền bù: ${AppFormatters.currency(a.compensationValue)}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
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
                onPressed: () {
                  auth.logout();
                },
                icon: const Icon(Icons.logout, color: Color(0xFFDC2626)),
                label: const Text('Đăng xuất tài khoản',
                    style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
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
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
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
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}
