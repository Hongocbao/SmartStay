import 'package:flutter/material.dart';
import '../../utils/provider_scope.dart';
import '../../theme/smartstay_theme.dart';
import '../../widgets/smartstay_ui.dart';
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
  int _selectedMonthIndex = 5;
  bool _isRefreshing = false;

  static const List<({String month, double collected, double debt})> _sixMonthStats = [
    (month: 'T5', collected: 98.0, debt: 8.0),
    (month: 'T6', collected: 105.0, debt: 5.0),
    (month: 'T7', collected: 110.0, debt: 4.0),
    (month: 'T8', collected: 115.0, debt: 3.0),
    (month: 'T9', collected: 114.0, debt: 2.0),
    (month: 'T10', collected: 102.0, debt: 16.4),
  ];

  Future<void> _refreshDashboard() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final ok = await context.read<AdminProvider>().syncWithCloudSupabase();
      if (!mounted) return;
      showSmartStayToast(
        context,
        ok
            ? 'Đã đồng bộ dữ liệu Realtime từ Supabase & Web Admin!'
            : 'Đang hiển thị dữ liệu cục bộ (Chưa kết nối được Cloud).',
        isSuccess: ok,
      );
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final auth = context.watch<AuthProvider>();
    final themeCtrl = context.watch<ThemeController>();
    final summary = admin.summary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? SmartStayColors.surfaceDark : SmartStayColors.surfaceLight;
    final borderColor = isDark ? SmartStayColors.borderDark : SmartStayColors.borderLight;
    final textPrimary = isDark ? SmartStayColors.textPrimaryDark : SmartStayColors.textPrimaryLight;
    final textSecondary = isDark ? SmartStayColors.textSecondaryDark : SmartStayColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bàn Điều Hành SmartStay',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textPrimary),
            ),
            Text(
              'Vai trò: ${auth.currentRole} • ${auth.user?.fullName ?? ""}',
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeCtrl.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: themeCtrl.isDark ? Colors.amber : SmartStayColors.textSecondaryLight,
            ),
            tooltip: themeCtrl.isDark ? 'Chuyển giao diện Sáng' : 'Chuyển giao diện Tối',
            onPressed: themeCtrl.toggle,
          ),
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
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, color: SmartStayColors.primary),
            tooltip: 'Làm mới dữ liệu Cloud',
            onPressed: _isRefreshing ? null : _refreshDashboard,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: _isRefreshing && admin.rooms.isEmpty
            ? const SingleChildScrollView(child: SmartStayDashboardSkeleton())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            // KPI Summary Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final kpiCards = [
                  _buildKpiCard(
                    title: 'Tỷ lệ lấp đầy',
                    value: '${summary.occupancyRate.toStringAsFixed(1)}%',
                    subtitle: '${summary.occupiedRooms}/${summary.totalRooms} phòng đang ở',
                    icon: Icons.pie_chart_rounded,
                    color: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFEFF6FF),
                  ),
                  _buildKpiCard(
                    title: 'Doanh thu tháng 10',
                    value: Formatters.formatCurrency(summary.monthlyRevenue),
                    subtitle: '20 phòng căn hộ Co-Living',
                    icon: Icons.monetization_on_rounded,
                    color: const Color(0xFF16A34A),
                    bgColor: const Color(0xFFF0FDF4),
                  ),
                  _buildKpiCard(
                    title: 'Sự cố cần sửa',
                    value: '${summary.pendingTickets}',
                    subtitle: 'Kanban kỹ thuật viên',
                    icon: Icons.engineering_rounded,
                    color: const Color(0xFFF59E0B),
                    bgColor: const Color(0xFFFFFBEB),
                  ),
                  _buildKpiCard(
                    title: 'Chưa thanh toán',
                    value: '${summary.uncollectedInvoices} phòng',
                    subtitle: Formatters.formatCurrency(summary.uncollectedAmount),
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFFDC2626),
                    bgColor: const Color(0xFFFEF2F2),
                  ),
                ];

                if (constraints.maxWidth >= 660) {
                  return Row(
                    children: [
                      for (var i = 0; i < kpiCards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(child: kpiCards[i]),
                      ],
                    ],
                  );
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: kpiCards[0]),
                        const SizedBox(width: 12),
                        Expanded(child: kpiCards[1]),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: kpiCards[2]),
                        const SizedBox(width: 12),
                        Expanded(child: kpiCards[3]),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Biểu đồ Thống kê Doanh thu & Công nợ 6 tháng gần nhất (tương đương #revenueChart trên Web /Home/Index)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thống Kê Doanh Thu & Công Nợ (6 Tháng)',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Đơn vị: Triệu đồng • Chạm cột để xem chi tiết tháng',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? SmartStayColors.bgDark : SmartStayColors.bgLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedBuilding,
                            isDense: true,
                            dropdownColor: surfaceColor,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary),
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
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildStatusLegend('Đã thu (triệu đ)', SmartStayColors.primary),
                      _buildStatusLegend('Công nợ (triệu đ)', const Color(0xFFF87171)),
                      Builder(
                        builder: (_) {
                          final sel = _sixMonthStats[_selectedMonthIndex];
                          final factor = _selectedBuilding == 'Tòa nhà B' ? 0.45 : (_selectedBuilding == 'Tòa nhà A' ? 0.65 : 1.0);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: SmartStayColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '${sel.month}: Thu ${(sel.collected * factor).toStringAsFixed(1)}tr • Nợ ${(sel.debt * factor).toStringAsFixed(1)}tr',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: SmartStayColors.primary,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 154,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(_sixMonthStats.length, (idx) {
                        final stat = _sixMonthStats[idx];
                        final isSelected = idx == _selectedMonthIndex;
                        final factor = _selectedBuilding == 'Tòa nhà B' ? 0.45 : (_selectedBuilding == 'Tòa nhà A' ? 0.65 : 1.0);
                        final colVal = stat.collected * factor;
                        final debtVal = stat.debt * factor;
                        final colHeight = (colVal / 125.0) * 105.0;
                        final debtHeight = (debtVal / 125.0) * 105.0;
                        return InkWell(
                          onTap: () => setState(() => _selectedMonthIndex = idx),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? SmartStayColors.primary.withValues(alpha: 0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${colVal.toStringAsFixed(0)}tr',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? SmartStayColors.primary : textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: 14,
                                      height: colHeight.clamp(8.0, 105.0),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? SmartStayColors.primary
                                            : SmartStayColors.primary.withValues(alpha: 0.72),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
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
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? SmartStayColors.primary : textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
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
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width >= 840 ? 4 : (width >= 540 ? 3 : 2);
                return GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 106,
                  ),
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
                );
              },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? SmartStayColors.surfaceDark : SmartStayColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? SmartStayColors.borderDark : SmartStayColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.02),
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? SmartStayColors.textSecondaryDark : SmartStayColors.textSecondaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? color.withValues(alpha: 0.18) : bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
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
            style: TextStyle(
              fontSize: 10,
              color: isDark ? SmartStayColors.textSecondaryDark : const Color(0xFF94A3B8),
            ),
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        height: 1.15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.25),
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
