import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/provider_scope.dart';
import '../providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../providers/ticket_provider.dart';
import '../providers/community_provider.dart';
import 'home/home_screen.dart';
import 'invoice/invoice_list_screen.dart';
import 'ticket/ticket_list_screen.dart';
import 'community/community_screen.dart';
import 'profile/profile_screen.dart';
import 'resident_services/resident_services_screen.dart';
import 'ai_chat/ai_chat_screen.dart';

// Admin screens
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_room_matrix_screen.dart';
import 'admin/admin_kanban_screen.dart';
import 'admin/admin_finance_screen.dart';
import 'admin/admin_iot_screen.dart';
import 'admin/admin_contracts_screen.dart';
import 'admin/admin_system_config_screen.dart';

class _SidebarMenuItem {
  final String title;
  final IconData icon;
  final Color iconColor;
  final int screenIndex;
  final int? residentServiceTab;

  const _SidebarMenuItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.screenIndex,
    this.residentServiceTab,
  });
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  int _residentServiceTab = 2; // Mặc định mở tab AI Quét Công Tơ hoặc tab được chọn
  Timer? _realtimeSyncTimer;

  @override
  void initState() {
    super.initState();
    // Đồng bộ thời gian thực mỗi 4 giây giữa Web Admin, Web App và Android App qua Supabase & Sync API
    _realtimeSyncTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _triggerRealtimeSync(silent: true);
    });
  }

  @override
  void dispose() {
    _realtimeSyncTimer?.cancel();
    super.dispose();
  }

  Future<void> _triggerRealtimeSync({bool silent = false}) async {
    if (!mounted) return;
    final adminProv = context.read<AdminProvider>();
    final ticketProv = context.read<TicketProvider>();
    final commProv = context.read<CommunityProvider>();

    await Future.wait([
      adminProv.syncWithCloudSupabase(),
      ticketProv.syncTicketsFromCloud(),
      commProv.syncAnnouncementsFromCloud(),
    ]);

    if (!silent && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Đã đồng bộ dữ liệu Realtime từ Supabase Cloud & Web Admin!'),
            backgroundColor: Color(0xFF16A34A),
            duration: Duration(seconds: 2),
          ),
        );
    }
  }

  void _onTabSelected(int index, {int? serviceTab}) {
    setState(() {
      _currentIndex = index;
      if (serviceTab != null) {
        _residentServiceTab = serviceTab;
      }
    });
  }

  List<_SidebarMenuItem> _getSidebarItems(bool isAdmin) {
    if (isAdmin) {
      return const [
        _SidebarMenuItem(
          title: 'Trung Tâm Điều Hành',
          icon: Icons.grid_view_rounded,
          iconColor: Color(0xFF60A5FA),
          screenIndex: 0,
        ),
        _SidebarMenuItem(
          title: 'Ma Trận Phòng Trực Quan',
          icon: Icons.apartment_rounded,
          iconColor: Color(0xFF38BDF8),
          screenIndex: 1,
        ),
        _SidebarMenuItem(
          title: 'Bảo Trì & Sự Cố (Kanban)',
          icon: Icons.build_circle_rounded,
          iconColor: Color(0xFFFBBF24),
          screenIndex: 2,
        ),
        _SidebarMenuItem(
          title: 'Khóa Thông Minh & IoT',
          icon: Icons.lock_open_rounded,
          iconColor: Color(0xFF34D399),
          screenIndex: 3,
        ),
        _SidebarMenuItem(
          title: 'Tài Chính & Điện Nước',
          icon: Icons.receipt_long_rounded,
          iconColor: Color(0xFFA78BFA),
          screenIndex: 4,
        ),
        _SidebarMenuItem(
          title: 'Hợp Đồng & Cư Dân',
          icon: Icons.badge_rounded,
          iconColor: Color(0xFFF472B6),
          screenIndex: 5,
        ),
        _SidebarMenuItem(
          title: 'Bảng Tin & Thông Báo',
          icon: Icons.campaign_rounded,
          iconColor: Color(0xFFFB923C),
          screenIndex: 6,
        ),
        _SidebarMenuItem(
          title: 'Cấu Hình Hệ Thống',
          icon: Icons.tune_rounded,
          iconColor: Color(0xFF94A3B8),
          screenIndex: 7,
        ),
      ];
    } else {
      // Cổng Cư Dân (P.305) giống hệt Sidebar bên trái của bản Web (_Layout.cshtml)
      return const [
        _SidebarMenuItem(
          title: 'Tổng Quan Phòng Tôi',
          icon: Icons.home_rounded,
          iconColor: Color(0xFF94A3B8),
          screenIndex: 0,
        ),
        _SidebarMenuItem(
          title: 'Hóa Đơn & Mã VietQR',
          icon: Icons.receipt_long_rounded,
          iconColor: Color(0xFF94A3B8),
          screenIndex: 1,
        ),
        _SidebarMenuItem(
          title: 'Chia Tiền Phòng Ở Ghép',
          icon: Icons.pie_chart_rounded,
          iconColor: Color(0xFFFBBF24),
          screenIndex: 2,
          residentServiceTab: 0,
        ),
        _SidebarMenuItem(
          title: 'AI Quét Công Tơ Điện Nước',
          icon: Icons.camera_alt_rounded,
          iconColor: Color(0xFFF87171),
          screenIndex: 2,
          residentServiceTab: 2,
        ),
        _SidebarMenuItem(
          title: 'Trợ Lý Ảo AI Tự Hành',
          icon: Icons.smart_toy_rounded,
          iconColor: Color(0xFFA78BFA),
          screenIndex: 3,
        ),
        _SidebarMenuItem(
          title: 'Vé Khách Vãng Lai (IoT)',
          icon: Icons.qr_code_2_rounded,
          iconColor: Color(0xFF34D399),
          screenIndex: 2,
          residentServiceTab: 1,
        ),
        _SidebarMenuItem(
          title: 'Chợ Đồ Cũ Sinh Viên',
          icon: Icons.recycling_rounded,
          iconColor: Color(0xFF38BDF8),
          screenIndex: 2,
          residentServiceTab: 3,
        ),
        _SidebarMenuItem(
          title: 'Báo Hỏng Hóc & Sự Cố',
          icon: Icons.handyman_rounded,
          iconColor: Color(0xFF94A3B8),
          screenIndex: 4,
        ),
        _SidebarMenuItem(
          title: 'Thông Báo & Nội Quy',
          icon: Icons.campaign_rounded,
          iconColor: Color(0xFF94A3B8),
          screenIndex: 5,
        ),
        _SidebarMenuItem(
          title: 'Hồ Sơ & Hợp Đồng',
          icon: Icons.person_rounded,
          iconColor: Color(0xFF94A3B8),
          screenIndex: 6,
        ),
      ];
    }
  }

  String _getCurrentPageTitle(bool isAdmin, int safeIndex) {
    final items = _getSidebarItems(isAdmin);
    for (final item in items) {
      if (item.screenIndex == safeIndex) {
        if (!isAdmin &&
            safeIndex == 2 &&
            item.residentServiceTab != null &&
            item.residentServiceTab != _residentServiceTab) {
          continue;
        }
        if (!isAdmin && safeIndex == 2 && _residentServiceTab == 2) {
          return 'AI Camera Quét Công Tơ Điện Nước Tự Động - SmartStay';
        }
        return '${item.title} - SmartStay';
      }
    }
    return 'Hệ Sinh Thái Quản Trị Lưu Trú - SmartStay';
  }

  Widget _buildDarkSidebar(BuildContext context, AuthProvider auth, int safeIndex, {bool isDrawer = false}) {
    final items = _getSidebarItems(auth.isAdmin);
    final sectionTitle = auth.isAdmin
        ? 'BAN QUẢN LÝ & KỸ THUẬT'
        : 'CỔNG CƯ DÂN (${auth.user?.effectiveRoomCode ?? "P.305"})';

    return Container(
      width: 265,
      color: const Color(0xFF0F172A),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand Header giống hệt _Layout.cshtml
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF1E293B), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SmartStay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Hệ sinh thái Quản trị Lưu trú',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Section Label
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 16, 8),
              child: Text(
                sectionTitle,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: items.length,
                itemBuilder: (context, idx) {
                  final item = items[idx];
                  final bool isSelected = item.screenIndex == safeIndex &&
                      (item.residentServiceTab == null || item.residentServiceTab == _residentServiceTab);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          _onTabSelected(item.screenIndex, serviceTab: item.residentServiceTab);
                          if (isDrawer && Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [Color(0xFF4F46E5), Color(0xFF3B82F6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 19,
                                color: isSelected ? Colors.white : item.iconColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                    fontSize: 13.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer Sidebar
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storage_rounded, color: Color(0xFF10B981), size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Supabase / SQL: SmartStayDB',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: auth.logout,
                    child: const Icon(Icons.logout_rounded, color: Color(0xFFF87171), size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebTopbar(BuildContext context, AuthProvider auth, int safeIndex, bool isDesktop) {
    final fullName = auth.user?.fullName ?? 'Hồ Ngọc Bảo';
    final initials = fullName.trim().isNotEmpty
        ? fullName.trim().split(' ').first.toUpperCase()
        : 'HB';
    final roleBadge = auth.isAdmin ? 'QuanLy_KyThuat' : 'CuDan';
    final isCompact = MediaQuery.of(context).size.width < 600;
    final rawTitle = _getCurrentPageTitle(auth.isAdmin, safeIndex);
    final displayTitle = isCompact ? rawTitle.replaceAll(' - SmartStay', '') : rawTitle;

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          if (!isDesktop) ...[
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A)),
                tooltip: 'Mở danh mục tính năng',
              ),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              displayTitle,
              style: TextStyle(
                fontSize: isCompact ? 14 : 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isDesktop) ...[
            InkWell(
              onTap: () => _triggerRealtimeSync(silent: false),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync_rounded, size: 14, color: Color(0xFF16A34A)),
                    SizedBox(width: 6),
                    Text(
                      'Supabase Realtime: SmartStayDB',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF15803D),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          // User Pill
          Container(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 10, vertical: isCompact ? 4 : 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: isCompact ? 12 : 14,
                  backgroundColor: const Color(0xFF2563EB),
                  child: Text(
                    initials.length > 3 ? initials.substring(0, 3) : initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isCompact ? 92 : 160),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isCompact ? 11 : 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isCompact ? (auth.isAdmin ? 'Admin' : 'Cư dân') : roleBadge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isCompact ? 6 : 10),
          // Nút Đăng xuất giống bản Web (40x40 IconButton gọn trên mobile 375px)
          if (isCompact)
            Tooltip(
              message: 'Đăng xuất',
              child: InkWell(
                onTap: auth.logout,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFDC2626)),
                ),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: auth.logout,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.logout_rounded, size: 15),
              label: const Text(
                'Đăng xuất',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    List<Widget> screens;
    List<BottomNavigationBarItem> navItems;

    if (auth.isAdmin) {
      screens = const [
        AdminDashboardScreen(),
        AdminRoomMatrixScreen(),
        AdminKanbanScreen(),
        AdminIotScreen(),
        AdminFinanceScreen(),
        AdminContractsScreen(),
        CommunityScreen(),
        AdminSystemConfigScreen(),
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
          icon: Icon(Icons.build_circle_outlined),
          activeIcon: Icon(Icons.build_circle_rounded),
          label: 'Bảo trì KT',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.lock_open_outlined),
          activeIcon: Icon(Icons.lock_open_rounded),
          label: 'Khóa IoT',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long_rounded),
          label: 'Tài chính',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_ind_outlined),
          activeIcon: Icon(Icons.assignment_ind_rounded),
          label: 'Hợp đồng',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.campaign_outlined),
          activeIcon: Icon(Icons.campaign_rounded),
          label: 'Thông báo',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.tune_outlined),
          activeIcon: Icon(Icons.tune_rounded),
          label: 'Cấu hình',
        ),
      ];
    } else {
      screens = [
        HomeScreen(onNavigateTab: (idx) => _onTabSelected(idx)),
        const InvoiceListScreen(),
        ResidentServicesScreen(initialTab: _residentServiceTab),
        const AiChatScreen(),
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
          icon: Icon(Icons.apps_outlined),
          activeIcon: Icon(Icons.apps_rounded),
          label: 'Tiện ích Đột phá',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.smart_toy_outlined),
          activeIcon: Icon(Icons.smart_toy_rounded),
          label: 'Trợ lý AI',
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

    final safeIndex = _currentIndex < screens.length ? _currentIndex : 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    final List<int> mobileScreenMap = auth.isAdmin ? const [0, 1, 2, 4] : const [0, 1, 2, 3];
    final List<BottomNavigationBarItem> mobileNavItems = auth.isAdmin
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Điều hành',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Phòng',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build_circle_outlined),
              activeIcon: Icon(Icons.build_circle_rounded),
              label: 'Kanban',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Tài chính',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_open_rounded),
              activeIcon: Icon(Icons.menu_open_rounded),
              label: 'Danh mục',
            ),
          ]
        : const [
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
              icon: Icon(Icons.apps_outlined),
              activeIcon: Icon(Icons.apps_rounded),
              label: 'Tiện ích',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy_outlined),
              activeIcon: Icon(Icons.smart_toy_rounded),
              label: 'Trợ lý AI',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_open_rounded),
              activeIcon: Icon(Icons.menu_open_rounded),
              label: 'Danh mục',
            ),
          ];

    final mappedMobileIdx = mobileScreenMap.indexOf(safeIndex);
    final mobileNavCurrentIdx = mappedMobileIdx != -1 ? mappedMobileIdx : 4;
    assert(navItems.length >= mobileNavItems.length);

    return Scaffold(
      key: _scaffoldKey,
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: const Color(0xFF0F172A),
              child: _buildDarkSidebar(context, auth, safeIndex, isDrawer: true),
            ),
      body: Row(
        children: [
          if (isDesktop) _buildDarkSidebar(context, auth, safeIndex),
          Expanded(
            child: Column(
              children: [
                _buildWebTopbar(context, auth, safeIndex, isDesktop),
                Expanded(
                  child: IndexedStack(
                    index: safeIndex,
                    children: screens,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : Container(
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
                  currentIndex: mobileNavCurrentIdx,
                  onTap: (idx) {
                    if (idx == 4) {
                      _scaffoldKey.currentState?.openDrawer();
                    } else {
                      _onTabSelected(mobileScreenMap[idx]);
                    }
                  },
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.white,
                  selectedItemColor: auth.isAdmin
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFF2563EB),
                  unselectedItemColor: const Color(0xFF94A3B8),
                  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  unselectedLabelStyle: const TextStyle(fontSize: 11),
                  elevation: 0,
                  items: mobileNavItems,
                ),
              ),
            ),
    );
  }
}
