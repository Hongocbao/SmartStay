import 'package:flutter/material.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../resident_services/resident_services_screen.dart';

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

  void _openTab(BuildContext context, int index) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResidentServicesScreen(initialTab: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '5 Tính Năng Đột Phá Công Nghệ 2026',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Chạm vào từng tính năng để mở và trải nghiệm trực tiếp trên App',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildItem(
              context,
              icon: Icons.pie_chart_rounded,
              color: const Color(0xFF2563EB),
              tag: 'FINTECH & SPLIT VIETQR',
              title: 'Chia Tiền Phòng & Đa Mã VietQR Riêng',
              desc: 'Tự động bóc tách hóa đơn P.305 cho 3 bạn ở ghép, sinh 3 mã QR Napas 247 riêng kèm thanh tiến độ thu nhóm.',
              onTap: () => _openTab(context, 0),
            ),
            _buildItem(
              context,
              icon: Icons.camera_alt_rounded,
              color: const Color(0xFFEF4444),
              tag: 'AI COMPUTER VISION',
              title: 'AI Camera Quét Công Tơ Điện Nước (OCR)',
              desc: 'Nhận diện chữ số công tơ bằng AI Gemini Vision (99.7%), tính bậc thang và cảnh báo rò rỉ bất thường.',
              onTap: () => _openTab(context, 2),
            ),
            _buildItem(
              context,
              icon: Icons.vpn_key_rounded,
              color: const Color(0xFF10B981),
              tag: 'DIGITAL KEYLESS & IOT',
              title: 'Cấp Mã Khách Ghé Thăm & Mở Khóa Từ Xa',
              desc: 'Tạo mã PIN tạm thời (#8821) tự hủy theo giờ cho bạn bè và điều khiển mở khóa cửa MQTT từ xa.',
              onTap: () => _openTab(context, 1),
            ),
            _buildItem(
              context,
              icon: Icons.recycling_rounded,
              color: const Color(0xFFF59E0B),
              tag: 'ECO CO-LIVING',
              title: 'Chợ Đồ Cũ Sinh Viên Nội Khu (Eco-Market)',
              desc: 'Trao đổi, pass lại đồ gia dụng hoặc tặng giáo trình miễn phí (0đ) giữa các phòng trong tòa nhà.',
              onTap: () => _openTab(context, 3),
            ),
            _buildItem(
              context,
              icon: Icons.smart_toy_rounded,
              color: const Color(0xFF8B5CF6),
              tag: 'GEMINI RAG 24/7',
              title: 'Trợ Lý Ảo AI Concierge Đa Nhiệm',
              desc: 'Giải đáp biểu giá điện nước bậc thang, tra cứu công nợ VietQR và hỗ trợ quy định lưu trú 24/7.',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AiChatScreen()),
                );
              },
            ),
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: 10),
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
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
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
}
