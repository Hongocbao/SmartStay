import 'package:flutter/material.dart';

class BreakthroughFeaturesModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _BreakthroughBottomSheet(),
    );
  }
}

class _BreakthroughBottomSheet extends StatelessWidget {
  const _BreakthroughBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bộ Tính Năng Đột Phá 2026',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    'Đồng bộ dữ liệu thời gian thực giữa Web & Mobile App',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildItem(
            context,
            icon: Icons.pie_chart_rounded,
            color: const Color(0xFF2563EB),
            tag: 'FINTECH & UX',
            title: 'Chia Tiền Phòng & Đa Mã VietQR Riêng',
            desc: 'Tự động bóc tách hóa đơn P.305 cho 3 bạn ở ghép (Bảo 1, Bảo 2, Bảo 3). Sinh 3 mã QR Napas 247 riêng biệt kèm thanh tiến độ 100%.',
            onTap: () {
              Navigator.pop(context);
              _showSplitBillDialog(context);
            },
          ),
          _buildItem(
            context,
            icon: Icons.camera_alt_rounded,
            color: const Color(0xFFEF4444),
            tag: 'AI COMPUTER VISION',
            title: 'AI Camera Quét Công Tơ Điện Nước (OCR)',
            desc: 'Mở camera chụp ảnh đồng hồ công tơ, AI tự động nhận diện chữ số (1.540 kWh) và phát hiện gian lận/rò rỉ bất thường.',
            onTap: () {
              Navigator.pop(context);
              _showAiOcrDialog(context);
            },
          ),
          _buildItem(
            context,
            icon: Icons.vpn_key_rounded,
            color: const Color(0xFF10B981),
            tag: 'DIGITAL KEYLESS',
            title: 'Cấp Mã Khách Vãng Lai & Khóa IoT',
            desc: 'Tạo mã QR hoặc mã PIN tạm thời (#8821) cho bạn bè ghé thăm căn hộ P.305 có hẹn giờ tự hủy và mở cửa từ xa.',
            onTap: () {
              Navigator.pop(context);
              _showGuestPassDialog(context);
            },
          ),
          _buildItem(
            context,
            icon: Icons.recycling_rounded,
            color: const Color(0xFFF59E0B),
            tag: 'ECO CO-LIVING',
            title: 'Sàn Trao Đổi Đồ Cũ Sinh Viên (Eco-Market)',
            desc: 'Cư dân các phòng pass lại quạt, bàn ghế, ấm siêu tốc hoặc tặng miễn phí (0đ) cho các bạn sinh viên trong cùng tòa nhà.',
            onTap: () {
              Navigator.pop(context);
              _showEcoMarketDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String tag,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }

  // Dialog Demo Chia tiền
  void _showSplitBillDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.pie_chart_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Chia Tiền Phòng P.305', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tổng hóa đơn tháng 10: 4.159.000 VNĐ (Chia 3 bạn)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('1. Hồ Ngọc Bảo: 1.386.333 đ (✅ Đã nộp VietQR)'),
            Text('2. Nguyễn Dương Bảo: 1.386.333 đ (✅ Đã nộp VietQR)'),
            Text('3. Trần Hoàng Gia Bảo: 1.386.334 đ (⏳ Chờ nộp)'),
            SizedBox(height: 12),
            Text('👉 Tính năng tương đương trên Web tại: /CuDan/ChiaTien', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  // Dialog Demo AI OCR
  void _showAiOcrDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.camera_alt_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('AI Camera Quét Công Tơ', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📸 AI Gemini Vision đã nhận diện:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Chỉ số điện mới: 1.540 kWh (Độ tin cậy: 99.7%)'),
            Text('• Tiêu thụ tháng: 120 kWh (Bậc 1, 2, 3)'),
            Text('• Đối soát Anomaly: An toàn, không có rò rỉ điện!'),
            SizedBox(height: 12),
            Text('👉 Tính năng tương đương trên Web tại: /CuDan/AiOcr', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  // Dialog Demo Vé Khách
  void _showGuestPassDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Vé Khách Ghé Thăm (Guest Pass)', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔑 Khóa phòng P.305: Đang kết nối WiFi MQTT (Pin 92%)'),
            SizedBox(height: 8),
            Text('• Mã PIN tạm cho khách: #8821'),
            Text('• Hiệu lực: 2 giờ (Tự hủy lúc 18:00)'),
            Text('• Cho phép mở cửa từ xa trực tiếp từ điện thoại.'),
            SizedBox(height: 12),
            Text('👉 Tính năng tương đương trên Web tại: /CuDan/GuestPass', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  // Dialog Demo Chợ Đồ Cũ
  void _showEcoMarketDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.recycling_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text('Chợ Đồ Cũ Sinh Viên Nội Khu', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('♻️ 3 món đồ đang được pass lại tại Co-Living:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('1. Quạt Senko P.305: 120.000 đ'),
            Text('2. Combo giáo trình CNTT P.201: 0đ (Tặng miễn phí)'),
            Text('3. Ấm đun siêu tốc P.401: 70.000 đ'),
            SizedBox(height: 12),
            Text('👉 Tính năng tương đương trên Web tại: /CuDan/ChoDoCu', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }
}
