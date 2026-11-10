import 'package:flutter/material.dart';
import '../../utils/provider_scope.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/formatters.dart';
import 'admin_room_matrix_screen.dart';
import 'admin_kanban_screen.dart';
import 'admin_finance_screen.dart';
import 'admin_iot_screen.dart';
import 'admin_contracts_screen.dart';
import 'admin_system_config_screen.dart';
import '../community/community_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _selectedBuilding = 'Tất cả tòa nhà';

  static const List<({String month, double collected, double debt})> _sixMonthStats = [
    (month: 'T5', collected: 98.0, debt: 8.0),
    (month: 'T6', collected: 105.0, debt: 5.0),
    (month: 'T7', collected: 110.0, debt: 4.0),
    (month: 'T8', collected: 115.0, debt: 3.0),
    (month: 'T9', collected: 114.0, debt: 2.0),
    (month: 'T10', collected: 102.0, debt: 16.4),
  ];

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
            icon: const Icon(Icons.settings_suggest_rounded, color: Color(0xFF8B5CF6)),
            tooltip: 'Cấu hình Hệ thống & VietQR',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminSystemConfigScreen()),
              );
            },
          ),
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

            // Biểu đồ Thống kê Doanh thu & Công nợ 6 tháng gần nhất (tương đương #revenueChart trên Web /Home/Index)
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thống Kê Doanh Thu & Công Nợ (6 Tháng)',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Đơn vị: Triệu đồng • Tiền phòng, điện nước & dịch vụ',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedBuilding,
                            isDense: true,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            items: const [
                              DropdownMenuItem(value: 'Tất cả tòa nhà', child: Text('Tất cả tòa nhà')),
                              DropdownMenuItem(value: 'Tòa nhà A', child: Text('Tòa nhà A')),
                              DropdownMenuItem(value: 'Tòa nhà B', child: Text('Tòa nhà B')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedBuilding = v);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatusLegend('Đã thu (triệu đ)', const Color(0xFF4F46E5)),
                      const SizedBox(width: 16),
                      _buildStatusLegend('Công nợ (triệu đ)', const Color(0xFFF87171)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 150,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _sixMonthStats.map((stat) {
                        final factor = _selectedBuilding == 'Tòa nhà B' ? 0.45 : (_selectedBuilding == 'Tòa nhà A' ? 0.65 : 1.0);
                        final colVal = stat.collected * factor;
                        final debtVal = stat.debt * factor;
                        final colHeight = (colVal / 125.0) * 105.0;
                        final debtHeight = (debtVal / 125.0) * 105.0;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${colVal.toStringAsFixed(0)}tr',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  width: 14,
                                  height: colHeight.clamp(8.0, 105.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4F46E5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 10,
                                  height: debtHeight.clamp(4.0, 105.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF87171),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              stat.month,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
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
                _buildActionCard(
                  context,
                  title: 'Hợp Đồng & Cư Dân',
                  desc: 'Ký điện tử PDF, nhập/xuất Excel cư dân',
                  icon: Icons.assignment_ind_rounded,
                  color: const Color(0xFFEA580C),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminContractsScreen()));
                  },
                ),
                _buildActionCard(
                  context,
                  title: 'Truyền Thông & Sự Kiện',
                  desc: 'Phát sóng Firebase FCM, điểm danh sự kiện',
                  icon: Icons.campaign_rounded,
                  color: const Color(0xFFDB2777),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityScreen()));
                  },
                ),
                _buildActionCard(
                  context,
                  title: 'Cấu Hình & VietQR',
                  desc: 'Ngân hàng Napas 247, giá điện nước bậc thang',
                  icon: Icons.tune_rounded,
                  color: const Color(0xFF4F46E5),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSystemConfigScreen()));
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Nhiệm vụ cần Ban Quản lý xử lý ngay (tương đương bảng việc cấp bách trên /Home/Index Web)
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
                    children: [
                      const Icon(Icons.notification_important_rounded, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Nhiệm Vụ Cần Ban Quản Lý Xử Lý Ngay',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '3 việc cấp bách',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildUrgentTaskRow(
                    badge: 'Sự cố khẩn cấp',
                    badgeColor: const Color(0xFFDC2626),
                    title: 'SC-2026-089: Máy lạnh chảy nước dàn lạnh',
                    subtitle: 'P.305 • Hồ Ngọc Bảo (0901234567) • Hạn: Hôm nay 17:00',
                    actionLabel: 'Xem Kanban',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminKanbanScreen())),
                  ),
                  const Divider(height: 16),
                  _buildUrgentTaskRow(
                    badge: 'Đối soát VietQR',
                    badgeColor: const Color(0xFFD97706),
                    title: 'Biên lai chuyển khoản: 4.159.000 đ',
                    subtitle: 'P.305 • Hồ Ngọc Bảo • Chờ xác nhận 15 phút trước',
                    actionLabel: 'Duyệt ngay',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFinanceScreen())),
                  ),
                  const Divider(height: 16),
                  _buildUrgentTaskRow(
                    badge: 'Sắp hết hạn HĐ',
                    badgeColor: const Color(0xFF2563EB),
                    title: 'Hợp đồng HD-2026-0303 sắp hết hạn thuê',
                    subtitle: 'P.303 • Còn 7 ngày • Cần gia hạn hoặc thanh lý',
                    actionLabel: 'Gia hạn',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminContractsScreen())),
                  ),
                ],
              ),
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

  Widget _buildUrgentTaskRow({
    required String badge,
    required Color badgeColor,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(actionLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
