import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/room_discovery_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/room_discovery_provider.dart';
import '../../theme/smartstay_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/provider_scope.dart';
import '../../widgets/smartstay_ui.dart';
import '../../widgets/smartstay_video_player_dialog.dart';

/// Màn hình "Khám Phá, Xem Video Tour & Đăng Ký Thuê Phòng Trực Tuyến"
/// Thiết kế hoàn toàn theo SmartStay Design System (Indigo / Slate, hỗ trợ Light & Dark Mode).
class RoomDiscoveryScreen extends StatefulWidget {
  const RoomDiscoveryScreen({super.key});

  @override
  State<RoomDiscoveryScreen> createState() => _RoomDiscoveryScreenState();
}

class _RoomDiscoveryScreenState extends State<RoomDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _quickFilter = 'Tất cả'; // Tất cả | Phòng trống | Nổi bật | Có Video Tour
  int _selectedFloor = 0; // 0 = Tất cả tầng
  String _priceRange = 'Tất cả'; // Tất cả | <3.5tr | 3.5-4.5tr | >4.5tr

  StreamSubscription<String>? _toastSub;
  Timer? _livePollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prov = context.read<RoomDiscoveryProvider>();
      _toastSub = prov.realtimeToastStream.listen((msg) {
        if (!mounted) return;
        showSmartStayToast(context, '🔄 $msg', isSuccess: true);
      });
      prov.syncAll(silent: prov.listings.isNotEmpty, emitToasts: false);
      _livePollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
        if (!mounted) return;
        prov.syncAll(silent: true, emitToasts: true);
      });
    });
  }

  @override
  void dispose() {
    _toastSub?.cancel();
    _livePollTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<RoomDiscoveryListing> _applyFilters(List<RoomDiscoveryListing> source) {
    final q = _searchQuery.trim().toLowerCase();
    final filtered = source.where((room) {
      if (_selectedFloor != 0 && room.floor != _selectedFloor) return false;

      if (_quickFilter == 'Phòng trống' && room.status != 'Trống') return false;
      if (_quickFilter == 'Có Video Tour' && !room.hasVideoTour) return false;
      if (_quickFilter == 'Nổi bật' && room.viewCount < 60 && room.rating < 4.9) {
        return false;
      }

      if (_priceRange == '<3.5tr' && room.rentPrice >= 3500000) return false;
      if (_priceRange == '3.5-4.5tr' &&
          (room.rentPrice < 3500000 || room.rentPrice > 4500000)) {
        return false;
      }
      if (_priceRange == '>4.5tr' && room.rentPrice <= 4500000) return false;

      if (q.isNotEmpty) {
        final haystack =
            '${room.roomCode} ${room.title} ${room.roomType} ${room.description} ${room.amenities.join(' ')} tầng ${room.floor}'
                .toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();

    if (_quickFilter == 'Nổi bật') {
      filtered.sort((a, b) => b.viewCount.compareTo(a.viewCount));
    } else {
      filtered.sort((a, b) {
        final aAvail = a.status == 'Trống' && a.isOpenForRent ? 0 : 1;
        final bAvail = b.status == 'Trống' && b.isOpenForRent ? 0 : 1;
        if (aAvail != bAvail) return aAvail.compareTo(bAvail);
        return a.roomCode.compareTo(b.roomCode);
      });
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RoomDiscoveryProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? SmartStayColors.bgDark : SmartStayColors.bgLight;
    final surfaceColor =
        isDark ? SmartStayColors.surfaceDark : SmartStayColors.surfaceLight;
    final borderColor =
        isDark ? SmartStayColors.borderDark : SmartStayColors.borderLight;
    final textPrimary =
        isDark ? SmartStayColors.textPrimaryDark : SmartStayColors.textPrimaryLight;
    final textSecondary =
        isDark ? SmartStayColors.textSecondaryDark : SmartStayColors.textSecondaryLight;

    final allListings = prov.listings;
    final filtered = _applyFilters(allListings);
    final featured = prov.featuredListings;
    final availableCount =
        allListings.where((r) => r.status == 'Trống' && r.isOpenForRent).length;

    final myPhone = (auth.user?.phone ?? '').trim();
    final myRegistrations = myPhone.isEmpty
        ? prov.registrations
        : prov.registrations
            .where((r) => r.phone.contains(myPhone) || r.fullName == auth.user?.fullName)
            .toList();
    final displayedRegs =
        myRegistrations.isNotEmpty ? myRegistrations : prov.registrations;

    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        color: SmartStayColors.primary,
        onRefresh: () async {
          final ok = await prov.syncAll(silent: false, emitToasts: true);
          if (!context.mounted) return;
          showSmartStayToast(
            context,
            ok
                ? 'Đã đồng bộ danh sách phòng & Video Tour mới nhất!'
                : 'Đang hiển thị dữ liệu cục bộ.',
            isSuccess: ok,
          );
        },
        child: prov.isLoading && allListings.isEmpty
            ? _buildShimmerLoading(isDark)
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // 1. Hero Header Banner chuẩn SmartStay Indigo/Slate
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: _buildHeroHeader(
                        context,
                        availableCount: availableCount,
                        totalCount: allListings.length,
                        myRegCount: displayedRegs.length,
                        onOpenMyRequests: () =>
                            _showMyRegistrationsSheet(context, displayedRegs),
                        onManualSync: () async {
                          final ok = await prov.syncAll(silent: false, emitToasts: true);
                          if (!context.mounted) return;
                          showSmartStayToast(
                            context,
                            ok ? 'Đã làm mới dữ liệu phòng Real-time!' : 'Không kết nối được máy chủ.',
                            isSuccess: ok,
                          );
                        },
                      ),
                    ),
                  ),

                  // 2. Thanh tìm kiếm & Bộ lọc nhanh
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(SmartStaySpacing.radiusLg),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _searchController,
                              onChanged: (v) => setState(() => _searchQuery = v),
                              style: TextStyle(color: textPrimary, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Tìm theo mã phòng (P.302), tiện ích (ban công, máy lạnh)...',
                                hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: SmartStayColors.primary,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.close_rounded, color: textSecondary),
                                        tooltip: 'Xóa tìm kiếm',
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: SmartStayColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildQuickChip('Tất cả', Icons.apps_rounded, isDark),
                                  const SizedBox(width: 8),
                                  _buildQuickChip('Phòng trống', Icons.check_circle_outline_rounded, isDark),
                                  const SizedBox(width: 8),
                                  _buildQuickChip('Nổi bật', Icons.local_fire_department_rounded, isDark),
                                  const SizedBox(width: 8),
                                  _buildQuickChip('Có Video Tour', Icons.play_circle_outline_rounded, isDark),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _buildCompactDropdown<int>(
                                  isDark: isDark,
                                  borderColor: borderColor,
                                  textPrimary: textPrimary,
                                  icon: Icons.layers_outlined,
                                  value: _selectedFloor,
                                  items: const [
                                    DropdownMenuItem(value: 0, child: Text('Tất cả tầng')),
                                    DropdownMenuItem(value: 1, child: Text('Tầng 1')),
                                    DropdownMenuItem(value: 2, child: Text('Tầng 2')),
                                    DropdownMenuItem(value: 3, child: Text('Tầng 3')),
                                    DropdownMenuItem(value: 4, child: Text('Tầng 4')),
                                    DropdownMenuItem(value: 5, child: Text('Tầng 5')),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) setState(() => _selectedFloor = v);
                                  },
                                ),
                                _buildCompactDropdown<String>(
                                  isDark: isDark,
                                  borderColor: borderColor,
                                  textPrimary: textPrimary,
                                  icon: Icons.payments_outlined,
                                  value: _priceRange,
                                  items: const [
                                    DropdownMenuItem(value: 'Tất cả', child: Text('Mọi mức giá')),
                                    DropdownMenuItem(value: '<3.5tr', child: Text('Dưới 3.5 triệu')),
                                    DropdownMenuItem(value: '3.5-4.5tr', child: Text('3.5 - 4.5 triệu')),
                                    DropdownMenuItem(value: '>4.5tr', child: Text('Trên 4.5 triệu')),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) setState(() => _priceRange = v);
                                  },
                                ),
                                if (_selectedFloor != 0 ||
                                    _priceRange != 'Tất cả' ||
                                    _quickFilter != 'Tất cả' ||
                                    _searchQuery.isNotEmpty)
                                  TextButton.icon(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                        _quickFilter = 'Tất cả';
                                        _selectedFloor = 0;
                                        _priceRange = 'Tất cả';
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(0, 44),
                                    ),
                                    icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                                    label: const Text('Đặt lại lọc', style: TextStyle(fontSize: 12.5)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Mục "Phòng nổi bật & Được xem nhiều"
                  if (featured.isNotEmpty && _searchQuery.isEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: SmartStayColors.primary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 17,
                                color: SmartStayColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Phòng nổi bật & Được xem nhiều',
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Đề xuất căn hộ thoáng sáng có Video Tour HD thực tế',
                                    style: TextStyle(fontSize: 12, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 222,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: featured.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, idx) => _buildFeaturedCard(
                            context,
                            featured[idx],
                            prov,
                            isDark,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // 4. Tiêu đề danh sách chính
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Danh sách phòng (${filtered.length})',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: SmartStayColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '● $availableCount phòng sẵn sàng',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: SmartStayColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 5. Lưới danh sách phòng Responsive
                  if (filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: SmartStayEmptyState(
                        icon: Icons.travel_explore_rounded,
                        title: 'Chưa tìm thấy phòng phù hợp',
                        subtitle:
                            'Thử thay đổi bộ lọc tầng, mức giá hoặc xóa từ khóa tìm kiếm để xem toàn bộ phòng trống.',
                        actionLabel: 'Xem tất cả phòng',
                        onAction: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _quickFilter = 'Tất cả';
                            _selectedFloor = 0;
                            _priceRange = 'Tất cả';
                          });
                        },
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.crossAxisExtent;
                          final cols = width >= 1040
                              ? 3
                              : (width >= 640 ? 2 : 1);
                          return SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              mainAxisExtent: cols == 1 ? 372 : 386,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildRoomListingCard(
                                context,
                                filtered[index],
                                prov,
                                isDark,
                              ),
                              childCount: filtered.length,
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

  Widget _buildShimmerLoading(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SmartStayShimmerBox(height: 118, borderRadius: 18),
        SizedBox(height: 14),
        SmartStayShimmerBox(height: 110, borderRadius: 16),
        SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: SmartStayShimmerBox(height: 210, borderRadius: 16)),
            SizedBox(width: 12),
            Expanded(child: SmartStayShimmerBox(height: 210, borderRadius: 16)),
          ],
        ),
        SizedBox(height: 16),
        SmartStayShimmerBox(height: 320, borderRadius: 16),
      ],
    );
  }

  Widget _buildHeroHeader(
    BuildContext context, {
    required int availableCount,
    required int totalCount,
    required int myRegCount,
    required VoidCallback onOpenMyRequests,
    required VoidCallback onManualSync,
  }) {
    final isCompact = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SmartStaySpacing.radiusXl),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: SmartStayColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sensors_rounded, color: Color(0xFF34D399), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'REALTIME • VIDEO TOUR HD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$availableCount / $totalCount phòng đang mở thuê',
                  style: const TextStyle(
                    color: Color(0xFFA7F3D0),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Khám Phá Phòng Trống & Xem Video Tour Trực Tuyến',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Xem ảnh sắc nét, trải nghiệm Video Tour thực tế có âm thanh và gửi phiếu đăng ký thuê / chuyển phòng trực tiếp tới Ban Quản Lý.',
            style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: onOpenMyRequests,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: SmartStayColors.primaryDark,
                  minimumSize: const Size(0, 44),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
                label: Text(
                  'Phiếu đăng ký của tôi ($myRegCount)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onManualSync,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.sync_rounded, size: 17),
                label: const Text(
                  'Cập nhật ngay',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, IconData icon, bool isDark) {
    final selected = _quickFilter == label;
    return InkWell(
      onTap: () => setState(() => _quickFilter = label),
      borderRadius: BorderRadius.circular(99),
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? SmartStayColors.primary
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected
                ? SmartStayColors.primary
                : (isDark ? SmartStayColors.borderDark : SmartStayColors.borderLight),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? Colors.white
                  : (isDark
                      ? SmartStayColors.textSecondaryDark
                      : SmartStayColors.textSecondaryLight),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected
                    ? Colors.white
                    : (isDark
                        ? SmartStayColors.textPrimaryDark
                        : SmartStayColors.textPrimaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactDropdown<T>({
    required bool isDark,
    required Color borderColor,
    required Color textPrimary,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: SmartStayColors.primary),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              dropdownColor:
                  isDark ? SmartStayColors.surfaceDark : SmartStayColors.surfaceLight,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(
    BuildContext context,
    RoomDiscoveryListing room,
    RoomDiscoveryProvider prov,
    bool isDark,
  ) {
    return SizedBox(
      width: 286,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openRoomDetail(context, room, prov),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                room.coverImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFF1E293B),
                  child: const Icon(Icons.apartment_rounded, color: Colors.white38, size: 48),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.15),
                      const Color(0xFF0F172A).withValues(alpha: 0.92),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: SmartStayColors.primary.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${room.roomCode} • Tầng ${room.floor}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (room.hasVideoTour) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_circle_fill_rounded,
                                color: Color(0xFF38BDF8), size: 13),
                            SizedBox(width: 4),
                            Text(
                              'Tour',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFBBF24), size: 14),
                        const SizedBox(width: 3),
                        Text(
                          room.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.visibility_rounded,
                            color: Colors.white70, size: 13),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${room.viewCount} lượt',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${Formatters.formatCurrency(room.rentPrice)}/th',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomListingCard(
    BuildContext context,
    RoomDiscoveryListing room,
    RoomDiscoveryProvider prov,
    bool isDark,
  ) {
    final surfaceColor =
        isDark ? SmartStayColors.surfaceDark : SmartStayColors.surfaceLight;
    final borderColor =
        isDark ? SmartStayColors.borderDark : SmartStayColors.borderLight;
    final textPrimary =
        isDark ? SmartStayColors.textPrimaryDark : SmartStayColors.textPrimaryLight;
    final textSecondary =
        isDark ? SmartStayColors.textSecondaryDark : SmartStayColors.textSecondaryLight;

    final isVacant = room.status == 'Trống' && room.isOpenForRent;
    final Color statusColor = isVacant
        ? SmartStayColors.success
        : (room.status == 'Đã đặt'
            ? SmartStayColors.warning
            : SmartStayColors.info);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cover photo + badges + Video Tour button
          SizedBox(
            height: 168,
            child: Stack(
              fit: StackFit.expand,
              children: [
                InkWell(
                  onTap: () => _openRoomDetail(context, room, prov),
                  child: Image.network(
                    room.coverImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                      child: const Icon(Icons.apartment_rounded, size: 44),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      isVacant ? 'Phòng trống • Mở thuê' : room.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_outlined,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${room.imageUrls.length} ảnh',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (room.hasVideoTour)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          prov.incrementViewCount(room.roomCode);
                          showSmartStayVideoPlayerDialog(
                            context,
                            title: '${room.roomCode} - ${room.title}',
                            videoUrl: room.videoTourUrl!,
                            headerPrefix: 'Video Tour phòng',
                          );
                        },
                        borderRadius: BorderRadius.circular(99),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 34),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: SmartStayColors.primary.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: Colors.white38),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 3),
                              Text(
                                'Xem Video Tour',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Body info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? SmartStayColors.primary.withValues(alpha: 0.22)
                              : SmartStayColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          room.roomCode,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? const Color(0xFFA5B4FC)
                                : SmartStayColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tầng ${room.floor} • ${room.area.toStringAsFixed(0)}m² • ${room.capacity} người',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: textSecondary),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.visibility_outlined,
                          size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 3),
                      Text(
                        '${room.viewCount}',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    room.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    room.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: textSecondary, height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: room.amenities.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Giá thuê niêm yết',
                              style: TextStyle(fontSize: 10.5, color: textSecondary),
                            ),
                            Text(
                              '${Formatters.formatCurrency(room.rentPrice)}/tháng',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: SmartStayColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _openRoomDetail(context, room, prov),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SmartStayColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Chi tiết & Thuê',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openRoomDetail(
    BuildContext context,
    RoomDiscoveryListing room,
    RoomDiscoveryProvider prov,
  ) {
    prov.incrementViewCount(room.roomCode);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _RoomDetailSheet(
        room: room,
        onBookPressed: () {
          Navigator.pop(sheetCtx);
          _showRegistrationDialog(context, room, prov);
        },
      ),
    );
  }

  Future<void> _showRegistrationDialog(
    BuildContext context,
    RoomDiscoveryListing room,
    RoomDiscoveryProvider prov,
  ) async {
    final auth = context.read<AuthProvider>();
    final nameCtrl = TextEditingController(text: auth.user?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: auth.user?.phone ?? '');
    final cccdCtrl = TextEditingController(text: '');
    final noteCtrl = TextEditingController();
    String requestType = auth.isAuthenticated && !auth.isAdmin
        ? 'ChuyenPhong'
        : 'ThueMoi';
    DateTime moveInDate = DateTime.now().add(const Duration(days: 3));
    bool submitting = false;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? SmartStayColors.surfaceDark : SmartStayColors.surfaceLight;
    final textPrimary =
        isDark ? SmartStayColors.textPrimaryDark : SmartStayColors.textPrimaryLight;
    final textSecondary =
        isDark ? SmartStayColors.textSecondaryDark : SmartStayColors.textSecondaryLight;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final formattedDate =
              '${moveInDate.day.toString().padLeft(2, '0')}/${moveInDate.month.toString().padLeft(2, '0')}/${moveInDate.year}';
          return AlertDialog(
            backgroundColor: surfaceColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: SmartStayColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.assignment_add,
                    color: SmartStayColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đăng Ký Phòng ${room.roomCode}',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        '${Formatters.formatCurrency(room.rentPrice)}/tháng • Tầng ${room.floor}',
                        style: TextStyle(fontSize: 11.5, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'ThueMoi',
                          label: Text('Thuê phòng mới'),
                          icon: Icon(Icons.key_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: 'ChuyenPhong',
                          label: Text('Xin chuyển phòng'),
                          icon: Icon(Icons.swap_horiz_rounded, size: 16),
                        ),
                      ],
                      selected: {requestType},
                      onSelectionChanged: (sel) =>
                          setDialogState(() => requestType = sel.first),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên người đăng ký *',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại liên hệ *',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cccdCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số CCCD (tùy chọn - dùng tạo sẵn HĐ nháp)',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: moveInDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 180)),
                        );
                        if (picked != null) {
                          setDialogState(() => moveInDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày dự kiến vào ở',
                          prefixIcon: Icon(Icons.calendar_today_rounded),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          formattedDate,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú cho Ban Quản Lý',
                        hintText: 'VD: Dự kiến ở 2 người, hẹn xem phòng trực tiếp lúc 17h...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.pop(dialogCtx),
                style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
                child: const Text('Hủy'),
              ),
              ElevatedButton.icon(
                onPressed: submitting
                    ? null
                    : () async {
                        if (nameCtrl.text.trim().isEmpty ||
                            phoneCtrl.text.trim().isEmpty) {
                          showSmartStayToast(
                            context,
                            'Vui lòng nhập đầy đủ Họ tên và Số điện thoại!',
                            isError: true,
                          );
                          return;
                        }
                        setDialogState(() => submitting = true);
                        final created = await prov.submitRegistration(
                          room: room,
                          fullName: nameCtrl.text,
                          phone: phoneCtrl.text,
                          nationalId: cccdCtrl.text,
                          requestType: requestType,
                          expectedMoveInDate: moveInDate,
                          note: noteCtrl.text,
                        );
                        if (!dialogCtx.mounted) return;
                        Navigator.pop(dialogCtx);
                        if (mounted) {
                          showSmartStayToast(
                            context,
                            'Đã gửi phiếu ${created?.maPhieu ?? ''} cho phòng ${room.roomCode}! Ban Quản Lý sẽ duyệt sớm.',
                            isSuccess: true,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: SmartStayColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 17),
                label: Text(submitting ? 'Đang gửi...' : 'Gửi Phiếu Đăng Ký'),
              ),
            ],
          );
        },
      ),
    );
    nameCtrl.dispose();
    phoneCtrl.dispose();
    cccdCtrl.dispose();
    noteCtrl.dispose();
  }

  void _showMyRegistrationsSheet(
    BuildContext context,
    List<RoomRegistrationRequest> items,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? SmartStayColors.surfaceDark : SmartStayColors.surfaceLight;
    final borderColor =
        isDark ? SmartStayColors.borderDark : SmartStayColors.borderLight;
    final textPrimary =
        isDark ? SmartStayColors.textPrimaryDark : SmartStayColors.textPrimaryLight;
    final textSecondary =
        isDark ? SmartStayColors.textSecondaryDark : SmartStayColors.textSecondaryLight;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.78,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
              child: Row(
                children: [
                  const Icon(Icons.assignment_turned_in_rounded,
                      color: SmartStayColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Theo dõi Phiếu Đăng Ký Phòng (${items.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textPrimary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderColor),
            Expanded(
              child: items.isEmpty
                  ? const SmartStayEmptyState(
                      icon: Icons.inbox_rounded,
                      title: 'Chưa có phiếu đăng ký nào',
                      subtitle:
                          'Chọn một phòng trống và nhấn "Chi tiết & Thuê" để gửi yêu cầu trực tuyến tới Ban Quản Lý.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, idx) {
                        final req = items[idx];
                        final statusColor = req.isApproved
                            ? SmartStayColors.success
                            : (req.isRejected
                                ? SmartStayColors.danger
                                : SmartStayColors.warning);
                        final d = req.expectedMoveInDate;
                        final dateStr =
                            '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: SmartStayColors.primary
                                          .withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      req.roomCode,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: SmartStayColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${req.requestTypeLabel} • ${req.maPhieu}',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      req.statusLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Người đăng ký: ${req.fullName} (${req.phone})',
                                style: TextStyle(fontSize: 12.5, color: textPrimary),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Ngày dự kiến vào ở: $dateStr',
                                style: TextStyle(fontSize: 12, color: textSecondary),
                              ),
                              if (req.note != null && req.note!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Ghi chú: ${req.note}',
                                  style: TextStyle(fontSize: 12, color: textSecondary),
                                ),
                              ],
                              if (req.isApproved && req.draftContractCode != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '✅ Đã tạo sẵn bản nháp hợp đồng: ${req.draftContractCode}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: SmartStayColors.success,
                                  ),
                                ),
                              ],
                              if (req.isRejected && req.rejectReason != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Lý do từ chối: ${req.rejectReason}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: SmartStayColors.danger,
                                  ),
                                ),
                              ],
                            ],
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

class _RoomDetailSheet extends StatefulWidget {
  final RoomDiscoveryListing room;
  final VoidCallback onBookPressed;

  const _RoomDetailSheet({
    required this.room,
    required this.onBookPressed,
  });

  @override
  State<_RoomDetailSheet> createState() => _RoomDetailSheetState();
}

class _RoomDetailSheetState extends State<_RoomDetailSheet> {
  final PageController _pageController = PageController();
  int _currentImageIdx = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? SmartStayColors.surfaceDark : SmartStayColors.surfaceLight;
    final borderColor =
        isDark ? SmartStayColors.borderDark : SmartStayColors.borderLight;
    final textPrimary =
        isDark ? SmartStayColors.textPrimaryDark : SmartStayColors.textPrimaryLight;
    final textSecondary =
        isDark ? SmartStayColors.textSecondaryDark : SmartStayColors.textSecondaryLight;

    final images = room.imageUrls;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Slider ảnh sắc nét + điều hướng
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      height: 240,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: images.length,
                            onPageChanged: (i) =>
                                setState(() => _currentImageIdx = i),
                            itemBuilder: (_, idx) => Image.network(
                              images[idx],
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: const Color(0xFF1E293B),
                                child: const Icon(
                                  Icons.apartment_rounded,
                                  color: Colors.white54,
                                  size: 52,
                                ),
                              ),
                            ),
                          ),
                          if (images.length > 1) ...[
                            Positioned(
                              left: 10,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: IconButton(
                                  onPressed: () {
                                    final prev = (_currentImageIdx - 1 + images.length) %
                                        images.length;
                                    _pageController.animateToPage(
                                      prev,
                                      duration: const Duration(milliseconds: 260),
                                      curve: Curves.easeOut,
                                    );
                                  },
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        Colors.black.withValues(alpha: 0.5),
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.chevron_left_rounded),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 10,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: IconButton(
                                  onPressed: () {
                                    final next =
                                        (_currentImageIdx + 1) % images.length;
                                    _pageController.animateToPage(
                                      next,
                                      duration: const Duration(milliseconds: 260),
                                      curve: Curves.easeOut,
                                    );
                                  },
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        Colors.black.withValues(alpha: 0.5),
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.chevron_right_rounded),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(images.length, (i) {
                                  final active = i == _currentImageIdx;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: active ? 20 : 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? SmartStayColors.primary
                                          : Colors.white70,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '${_currentImageIdx + 1}/${images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Thumbnail Strip
                  if (images.length > 1) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 54,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, idx) {
                          final active = idx == _currentImageIdx;
                          return GestureDetector(
                            onTap: () => _pageController.animateToPage(
                              idx,
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOut,
                            ),
                            child: Container(
                              width: 76,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: active
                                      ? SmartStayColors.primary
                                      : borderColor,
                                  width: active ? 2 : 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.network(images[idx], fit: BoxFit.cover),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // 2. Nút phát Video Tour thực tế (có âm thanh & nút toàn màn hình)
                  if (room.hasVideoTour) ...[
                    const SizedBox(height: 14),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => showSmartStayVideoPlayerDialog(
                          context,
                          title: '${room.roomCode} - ${room.title}',
                          videoUrl: room.videoTourUrl!,
                          headerPrefix: 'Video Tour phòng',
                        ),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: [
                                SmartStayColors.primary.withValues(alpha: 0.14),
                                SmartStayColors.accent.withValues(alpha: 0.12),
                              ],
                            ),
                            border: Border.all(
                              color: SmartStayColors.primary.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: SmartStayColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Xem Video Tour Thực Tế Phòng ${room.roomCode}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Hỗ trợ âm thanh HD, thanh tua & phóng to toàn màn hình',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.fullscreen_rounded,
                                color: SmartStayColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.title,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${room.roomCode} • ${room.roomType} • Tầng ${room.floor}',
                              style: TextStyle(fontSize: 12.5, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Formatters.formatCurrency(room.rentPrice),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: SmartStayColors.primary,
                            ),
                          ),
                          Text(
                            '/ tháng',
                            style: TextStyle(fontSize: 11.5, color: textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  // Spec grid
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _specPill(Icons.square_foot_rounded, '${room.area.toStringAsFixed(1)} m²', isDark, borderColor, textPrimary),
                      _specPill(Icons.people_outline_rounded, 'Tối đa ${room.capacity} người', isDark, borderColor, textPrimary),
                      _specPill(Icons.visibility_outlined, '${room.viewCount} lượt xem', isDark, borderColor, textPrimary),
                      _specPill(Icons.star_rounded, '${room.rating.toStringAsFixed(1)} / 5.0', isDark, borderColor, textPrimary),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Mô tả không gian',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    room.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Tiện nghi nổi bật',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: room.amenities.map((a) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? SmartStayColors.primary.withValues(alpha: 0.16)
                              : SmartStayColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: SmartStayColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              a,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFC7D2FE)
                                    : SmartStayColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom sticky CTA bar
          Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Đóng'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onBookPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SmartStayColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.assignment_turned_in_rounded, size: 19),
                      label: const Text(
                        'Đăng ký thuê / Xin chuyển phòng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _specPill(
    IconData icon,
    String text,
    bool isDark,
    Color borderColor,
    Color textPrimary,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: SmartStayColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
