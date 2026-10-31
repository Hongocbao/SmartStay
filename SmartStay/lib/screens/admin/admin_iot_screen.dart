import 'package:flutter/material.dart';
import '../../utils/provider_scope.dart';
import '../../providers/admin_provider.dart';
import '../../utils/formatters.dart';

class AdminIotScreen extends StatelessWidget {
  const AdminIotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final rooms = admin.rooms;
    final accessLogs = admin.accessLogs;

    final lowBatteryLocks = rooms.where((r) => r.smartLockBattery < 80).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Khóa Thông Minh IoT & Kiểm Soát Cửa',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status overview card
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
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.router_rounded, color: Color(0xFF2563EB), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cổng Kết Nối IoT Gateway',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Mạng Zigbee 3.0 / WiFi 2.4GHz • 20 Khóa Online',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        const Text('ONLINE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (lowBatteryLocks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.battery_alert_rounded, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cảnh báo: Có ${lowBatteryLocks.length} khóa pin dưới 80% (${lowBatteryLocks.map((l) => l.roomCode).join(', ')}). Cần sạc hoặc thay pin dự phòng.',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Danh sách các phòng và nút mở khóa từ xa
            const Text(
              'Danh Sách Khóa Thông Minh Theo Phòng',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 125,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: rooms.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  return Container(
                    width: 135,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              room.roomCode,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                            Row(
                              children: [
                                Icon(
                                  room.smartLockBattery > 80 ? Icons.battery_full_rounded : Icons.battery_3_bar_rounded,
                                  size: 13,
                                  color: room.smartLockBattery > 80 ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                ),
                                Text('${room.smartLockBattery}%', style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          room.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: room.status == 'Đang ở' ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 30,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              admin.remoteUnlockRoom(room.roomCode);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Đã gửi lệnh mở khóa từ xa cho phòng ${room.roomCode}!')),
                              );
                            },
                            child: const Text('Mở Khóa', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Access Log
            const Text(
              'Nhật Ký Quẹt Thẻ / Vân Tay Mới Nhất',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: accessLogs.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final log = accessLogs[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: log.isSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        log.isSuccess ? Icons.lock_open_rounded : Icons.lock_rounded,
                        size: 18,
                        color: log.isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                    ),
                    title: Text(
                      '${log.roomCode} • ${log.personName}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    subtitle: Text(
                      'Phương thức: ${log.method} • ${log.isSuccess ? "Mở khóa thành công" : "Truy cập bị từ chối"}',
                      style: TextStyle(
                        fontSize: 11,
                        color: log.isSuccess ? const Color(0xFF64748B) : const Color(0xFFDC2626),
                      ),
                    ),
                    trailing: Text(
                      Formatters.formatTime(log.timestamp),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
