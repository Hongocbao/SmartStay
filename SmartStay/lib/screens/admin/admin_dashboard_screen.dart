import 'package:flutter/material.dart';
import '../../utils/provider_scope.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/formatters.dart';
import 'admin_room_matrix_screen.dart';
import 'admin_kanban_screen.dart';
import 'admin_finance_screen.dart';
import 'admin_iot_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final auth = context.watch<AuthProvider>();
    final summary = admin.summary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bàn Điều Hành SmartStay',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A)),
            ),
            Text(
              'Vai trò: ${auth.currentRole} • ${auth.user?.fullName ?? ""}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Làm mới',
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Tỷ lệ lấp đầy',
                    value: '${summary.occupancyRate.toStringAsFixed(1)}%',
                    subtitle: '${summary.occupiedRooms}/${summary.totalRooms} phòng đang ở',
                    icon: Icons.pie_chart_rounded,
                    color: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFEFF6FF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Doanh thu tháng 10',
                    value: Formatters.formatCurrency(summary.monthlyRevenue),
                    subtitle: '20 phòng căn hộ Co-Living',
                    icon: Icons.monetization_on_rounded,
                    color: const Color(0xFF16A34A),
                    bgColor: const Color(0xFFF0FDF4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Sự cố cần sửa',
                    value: '${summary.pendingTickets}',
                    subtitle: 'Kanban kỹ thuật viên',
                    icon: Icons.engineering_rounded,
                    color: const Color(0xFFF59E0B),
                    bgColor: const Color(0xFFFFFBEB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Chưa thanh toán',
                    value: '${summary.uncollectedInvoices} phòng',
                    subtitle: Formatters.formatCurrency(summary.uncollectedAmount),
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFFDC2626),
                    bgColor: const Color(0xFFFEF2F2),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sơ đồ phòng Mini Visual Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Phân Bổ Trạng Thái Phòng',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminRoomMatrixScreen()),
                          );
                        },
                        child: const Text('Xem sơ đồ lưới >', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 16,
                      child: Row(
                        children: [
                          Expanded(
                            flex: summary.occupiedRooms > 0 ? summary.occupiedRooms : 1,
                            child: Container(color: const Color(0xFF2563EB)),
                          ),
                          Expanded(
                            flex: summary.emptyRooms > 0 ? summary.emptyRooms : 1,
                            child: Container(color: const Color(0xFF10B981)),
                          ),
                          Expanded(
                            flex: summary.reservedRooms > 0 ? summary.reservedRooms : 1,
                            child: Container(color: const Color(0xFFF59E0B)),
                          ),
                          Expanded(
                            flex: summary.maintenanceRooms > 0 ? summary.maintenanceRooms : 1,
                            child: Container(color: const Color(0xFFEF4444)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildStatusLegend('Đang ở (${summary.occupiedRooms})', const Color(0xFF2563EB)),
                      _buildStatusLegend('Trống (${summary.emptyRooms})', const Color(0xFF10B981)),
                      _buildStatusLegend('Đã đặt (${summary.reservedRooms})', const Color(0xFFF59E0B)),
                      _buildStatusLegend('Bảo trì (${summary.maintenanceRooms})', const Color(0xFFEF4444)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Modules Phân Hệ Quản Lý (Quick Access Grid)
            const Text(
              'Phân Hệ Quản Lý Vận Hành',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _buildActionCard(
                  context,
                  title: 'Sơ Đồ Phòng',
                  desc: 'Ma trận phòng 5 tầng, Check-in / Check-out',
                  icon: Icons.grid_view_rounded,
                  color: const Color(0xFF2563EB),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRoomMatrixScreen()));
                  },
                ),
                _buildActionCard(
                  context,
                  title: 'Kanban Sự Cố',
                  desc: 'Phân công kỹ thuật & xử lý bảo trì',
                  icon: Icons.view_kanban_rounded,
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminKanbanScreen()));
                  },
                ),
                _buildActionCard(
                  context,
                  title: 'Tài Chính & VietQR',
                  desc: 'Đối soát chuyển khoản & hóa đơn bậc thang',
                  icon: Icons.qr_code_scanner_rounded,
                  color: const Color(0xFF10B981),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFinanceScreen()));
                  },
                ),
                _buildActionCard(
                  context,
                  title: 'Khóa IoT & Ra Vào',
                  desc: 'Nhật ký thẻ/vân tay, mở khóa từ xa',
                  icon: Icons.lock_open_rounded,
                  color: const Color(0xFF0284C7),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminIotScreen()));
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Nhật Ký Truy Cập Gần Nhất
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Nhật Ký Cửa Khóa IoT',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminIotScreen()));
                        },
                        child: const Text('Xem tất cả >', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...admin.accessLogs.take(4).map((log) => _buildLogItem(log)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLegend(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogItem(dynamic log) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: log.isSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              log.isSuccess ? Icons.check_circle_outline_rounded : Icons.highlight_off_rounded,
              size: 16,
              color: log.isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.roomCode} • ${log.personName}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Phương thức: ${log.method}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            Formatters.formatTime(log.timestamp),
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
