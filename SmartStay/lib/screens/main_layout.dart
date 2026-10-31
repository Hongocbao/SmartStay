import 'package:flutter/material.dart';
import '../utils/provider_scope.dart';
import '../providers/auth_provider.dart';
import 'home/home_screen.dart';
import 'invoice/invoice_list_screen.dart';
import 'ticket/ticket_list_screen.dart';
import 'community/community_screen.dart';
import 'profile/profile_screen.dart';

// Admin screens
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_room_matrix_screen.dart';
import 'admin/admin_kanban_screen.dart';
import 'admin/admin_finance_screen.dart';
import 'admin/admin_iot_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showRoleSwitcher(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chuyển Đổi Không Gian Làm Việc (Multi-Role)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hệ thống tích hợp toàn diện trên Android Studio: Cho phép trải nghiệm trọn vẹn cả 3 phân hệ Cư Dân, Quản Lý và Kỹ Thuật.',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              _buildRoleTile(
                ctx,
                auth,
                title: '🎓 Phân Hệ Cư Dân (Resident App)',
                subtitle: 'Hồ Ngọc Bảo (Phòng P.305) • Xem hóa đơn, VietQR, Báo sự cố, AI Chat',
                roleValue: 'Cư dân',
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(height: 8),
              _buildRoleTile(
                ctx,
                auth,
                title: '👔 Phân Hệ Quản Lý Vận Hành (Admin Portal)',
                subtitle: 'Nguyễn Hoàng Nam • Sơ đồ phòng, Kanban sự cố, Đối soát VietQR, Khóa IoT',
                roleValue: 'Quản lý vận hành',
                color: const Color(0xFF8B5CF6),
              ),
              const SizedBox(height: 8),
              _buildRoleTile(
                ctx,
                auth,
                title: '🔧 Phân Hệ Kỹ Thuật Viên (Technician)',
                subtitle: 'Trần Văn Tuấn • Nhận lệnh bảo trì, cập nhật vật tư, xử lý sự cố',
                roleValue: 'Kỹ thuật viên',
                color: const Color(0xFF10B981),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleTile(
    BuildContext ctx,
    AuthProvider auth, {
    required String title,
    required String subtitle,
    required String roleValue,
    required Color color,
  }) {
    final isSelected = auth.currentRole == roleValue;
    return Material(
      color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          auth.switchRole(roleValue);
          setState(() {
            _currentIndex = 0;
          });
          Navigator.pop(ctx);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? color : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Dynamic Navigation screens based on current role
    List<Widget> screens;
    List<BottomNavigationBarItem> navItems;

    if (auth.isAdmin) {
      // Admin / Quản lý vận hành Navigation
      screens = [
        const AdminDashboardScreen(),
        const AdminRoomMatrixScreen(),
        const AdminKanbanScreen(),
        const AdminFinanceScreen(),
        const AdminIotScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard_rounded),
          label: 'Điều hành',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view_outlined),
          activeIcon: Icon(Icons.grid_view_rounded),
          label: 'Sơ đồ phòng',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.view_kanban_outlined),
          activeIcon: Icon(Icons.view_kanban_rounded),
          label: 'Kanban',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long_rounded),
          label: 'Tài chính',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.lock_open_outlined),
          activeIcon: Icon(Icons.lock_open_rounded),
          label: 'Khóa IoT',
        ),
      ];
    } else if (auth.isTechnician) {
      // Kỹ thuật viên Navigation
      screens = [
        const AdminKanbanScreen(),
        const AdminIotScreen(),
        const CommunityScreen(),
        const ProfileScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.build_circle_outlined),
          activeIcon: Icon(Icons.build_circle_rounded),
          label: 'Sự cố bảo trì',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.lock_open_outlined),
          activeIcon: Icon(Icons.lock_open_rounded),
          label: 'Khóa IoT',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.newspaper_outlined),
          activeIcon: Icon(Icons.newspaper_rounded),
          label: 'Bảng tin',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          activeIcon: Icon(Icons.person_rounded),
          label: 'Cá nhân',
        ),
      ];
    } else {
      // Cư dân (Resident) Navigation
      screens = [
        HomeScreen(onNavigateTab: _onTabSelected),
        const InvoiceListScreen(),
        const TicketListScreen(),
        const CommunityScreen(),
        const ProfileScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Trang chủ',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long_rounded),
          label: 'Hóa đơn',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.build_circle_outlined),
          activeIcon: Icon(Icons.build_circle_rounded),
          label: 'Sự cố',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.newspaper_outlined),
          activeIcon: Icon(Icons.newspaper_rounded),
          label: 'Bảng tin',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          activeIcon: Icon(Icons.person_rounded),
          label: 'Cá nhân',
        ),
      ];
    }

    // Safety check index in range
    final safeIndex = _currentIndex < screens.length ? _currentIndex : 0;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: safeIndex,
            children: screens,
          ),
          // Floating Role Switcher Pill at Top Right (Accessible everywhere)
          Positioned(
            top: 48,
            right: 12,
            child: Material(
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              color: auth.isAdmin
                  ? const Color(0xFF8B5CF6)
                  : (auth.isTechnician ? const Color(0xFF10B981) : const Color(0xFF2563EB)),
              child: InkWell(
                onTap: () => _showRoleSwitcher(context, auth),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        auth.isAdmin
                            ? Icons.admin_panel_settings_rounded
                            : (auth.isTechnician ? Icons.engineering_rounded : Icons.person_rounded),
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        auth.currentRole,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: safeIndex,
            onTap: _onTabSelected,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: auth.isAdmin
                ? const Color(0xFF8B5CF6)
                : (auth.isTechnician ? const Color(0xFF10B981) : const Color(0xFF2563EB)),
            unselectedItemColor: const Color(0xFF94A3B8),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            elevation: 0,
            items: navItems,
          ),
        ),
      ),
    );
  }
}
