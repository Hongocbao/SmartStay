import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../providers/admin_provider.dart';
import '../providers/ai_chat_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/community_provider.dart';
import '../providers/ticket_provider.dart';
import '../utils/formatters.dart';
import '../utils/provider_scope.dart';
import 'call_center_modal.dart';

class AiToolExecutionResult {
  final String toolBadge;
  final Color toolColor;
  final List<String> details;
  final String statusSummary;
  final String? liveReplySummary;
  final String? snackbarMessage;

  const AiToolExecutionResult({
    required this.toolBadge,
    required this.toolColor,
    required this.details,
    required this.statusSummary,
    this.liveReplySummary,
    this.snackbarMessage,
  });
}

Future<AiToolExecutionResult?> executeSmartStayAiTools({
  required BuildContext context,
  required String query,
  required bool isAdminMode,
}) async {
  final auth = context.read<AuthProvider>();
  final ticketProv = context.read<TicketProvider>();
  final adminProv = context.read<AdminProvider>();
  final commProv = context.read<CommunityProvider>();
  final q = query.trim().toLowerCase();
  final roomCode = auth.user?.effectiveRoomCode ?? 'P.305';
  final userName =
      auth.user?.fullName ?? (isAdminMode ? 'Quản Trị Viên' : 'Hồ Ngọc Bảo');

  if (isAdminMode) {
    if ((q.contains('phát thông báo') || q.contains('gửi thông báo')) &&
        (q.contains('nhắc') || q.contains('phí') || q.contains('tiền'))) {
      commProv.broadcastAnnouncement(
        title: 'Nhắc lịch thanh toán hóa đơn dịch vụ tháng này',
        content:
            'Ban Quản Lý kính đề nghị Quý cư dân kiểm tra chỉ số điện nước và hoàn tất thanh toán qua VietQR trước ngày 05 hàng tháng.',
        scope: 'Toàn tòa nhà',
        isImportant: true,
      );
      return const AiToolExecutionResult(
        toolBadge: 'Kích hoạt Tool: broadcast_notice()',
        toolColor: Color(0xFF7C3AED),
        details: [
          'Phạm vi: Toàn tòa nhà (Khẩn cấp)',
          'Tiêu đề: Nhắc lịch thanh toán hóa đơn dịch vụ tháng này',
          'Kênh đồng bộ: Supabase & Bảng tin Cư dân Realtime',
        ],
        statusSummary: 'Đã phát thông báo nhắc đóng tiền lên Bảng tin cư dân!',
        liveReplySummary:
            '📢 AI Copilot đã tự động phát thông báo nhắc đóng phí toàn tòa nhà lên Bảng tin Cư dân & đồng bộ Supabase Realtime thành công!',
        snackbarMessage:
            'AI Copilot đã phát thông báo nhắc đóng phí lên Bảng tin!',
      );
    }

    if (q.contains('doanh thu') ||
        q.contains('công nợ') ||
        q.contains('hóa đơn') ||
        q.contains('tài chính') ||
        q.contains('chưa thu')) {
      final summary = adminProv.summary;
      final revenue = AppFormatters.currency(summary.monthlyRevenue);
      final uncollected = AppFormatters.currency(summary.uncollectedAmount);
      return AiToolExecutionResult(
        toolBadge: 'Kích hoạt Tool: query_financial_kpi()',
        toolColor: const Color(0xFF2563EB),
        details: [
          'Phòng đang thuê: ${summary.occupiedRooms}/${summary.totalRooms} phòng (${summary.occupancyRate.toStringAsFixed(1)}%)',
          'Doanh thu tiền phòng dự kiến: $revenue',
          'Hóa đơn chưa hoàn tất: ${summary.uncollectedInvoices} hóa đơn ($uncollected)',
        ],
        statusSummary: 'Đã truy xuất số liệu Tài chính Realtime từ AdminProvider!',
        liveReplySummary: '📊 Báo cáo Tài chính Realtime ($userName):\n'
            '• Phòng đang ở: ${summary.occupiedRooms}/${summary.totalRooms} phòng (Tỷ lệ lấp đầy ${summary.occupancyRate.toStringAsFixed(1)}%).\n'
            '• Doanh thu tiền phòng dự kiến: $revenue.\n'
            '• Hóa đơn chờ thanh toán / chờ đối soát: ${summary.uncollectedInvoices} hóa đơn ($uncollected).\n'
            '💡 Bạn có thể mở mục "Tài Chính & Điện Nước" để đối soát biên lai hoặc gõ "Phát thông báo nhắc đóng phí" để AI gửi nhắc nhở tự động.',
      );
    }

    if (q.contains('phòng trống') ||
        q.contains('lấp đầy') ||
        q.contains('sơ đồ') ||
        q.contains('ma trận') ||
        q.contains('hợp đồng')) {
      final summary = adminProv.summary;
      final emptyRoomCodes = adminProv.rooms
          .where((r) => r.status == 'Trống')
          .map((r) => r.roomCode)
          .take(8)
          .join(', ');
      final emptyListText =
          emptyRoomCodes.isEmpty ? 'Không còn phòng trống' : emptyRoomCodes;
      return AiToolExecutionResult(
        toolBadge: 'Kích hoạt Tool: inspect_room_matrix()',
        toolColor: const Color(0xFF0284C7),
        details: [
          'Tổng phòng: ${summary.totalRooms} | Đang ở: ${summary.occupiedRooms}',
          'Phòng trống (${summary.emptyRooms}): $emptyListText',
          'Bảo trì: ${summary.maintenanceRooms} | Đã đặt: ${summary.reservedRooms}',
        ],
        statusSummary: 'Đã thống kê Ma trận Phòng trực quan!',
        liveReplySummary: '🏢 Báo cáo Ma trận Phòng SmartStay ($userName):\n'
            '• Đang ở: ${summary.occupiedRooms}/${summary.totalRooms} phòng (${summary.occupancyRate.toStringAsFixed(1)}%).\n'
            '• Phòng trống (${summary.emptyRooms}): $emptyListText.\n'
            '• Phòng đang bảo trì: ${summary.maintenanceRooms} • Đã đặt cọc: ${summary.reservedRooms}.\n'
            '💡 Mở "Ma Trận Phòng Trực Quan" để bấm lọc theo trạng thái và check-in nhanh.',
      );
    }

    if (q.contains('sự cố') ||
        q.contains('kanban') ||
        q.contains('bảo trì') ||
        q.contains('kỹ thuật')) {
      final allTickets = ticketProv.tickets;
      final waiting = allTickets.where((t) => t.status == 'Chờ xử lý').length;
      final inProgress =
          allTickets.where((t) => t.status == 'Đang sửa').length;
      final done = allTickets.where((t) => t.status == 'Hoàn thành').length;
      final urgentPreview = allTickets
          .where((t) => t.status != 'Hoàn thành')
          .take(3)
          .map((t) => '${t.ticketCode} (${t.roomCode}): ${t.title}')
          .join('\n• ');
      return AiToolExecutionResult(
        toolBadge: 'Kích hoạt Tool: inspect_kanban_queue()',
        toolColor: const Color(0xFFD97706),
        details: [
          'Chờ xử lý: $waiting phiếu',
          'Đang sửa chữa: $inProgress phiếu',
          'Đã hoàn thành: $done phiếu',
        ],
        statusSummary: 'Đã quét hàng đợi Kanban Kỹ thuật!',
        liveReplySummary: '🛠️ Tình trạng Bảo trì & Sự cố Kanban ($userName):\n'
            '• Chờ xử lý: $waiting phiếu | Đang sửa: $inProgress phiếu | Hoàn thành: $done phiếu.\n'
            '${urgentPreview.isNotEmpty ? "• Các phiếu đang mở:\n• $urgentPreview\n" : ""}'
            '💡 Bạn có thể kéo thả thẻ trực tiếp trên Bảng Kanban để điều phối KTV.',
      );
    }

    if (q.contains('mở khóa') || q.contains('cửa') || q.contains('iot')) {
      await adminProv.remoteUnlockRoom('P.305');
      return AiToolExecutionResult(
        toolBadge: 'Kích hoạt Tool: admin_iot_lock_control()',
        toolColor: const Color(0xFF16A34A),
        details: [
          'Người thực hiện: $userName (Admin/Quản lý)',
          'Cửa phòng mục tiêu: P.305 (SmartLock MQTT TLS)',
          'Hành động: UNLOCK_TEMPORARY (5s) + Ghi log kiểm toán',
        ],
        statusSummary: 'Đã gửi xung mở khóa IoT & lưu nhật ký truy cập!',
        liveReplySummary:
            '🔐 Đã thực thi lệnh mở khóa thông minh IoT từ xa cho cửa phòng P.305 (5 giây) dưới quyền $userName và ghi nhận vào nhật ký truy cập.',
        snackbarMessage: 'Đã gửi lệnh mở khóa IoT từ xa cho phòng P.305!',
      );
    }

    return null;
  }

  // Chế độ Cư dân (Resident Agentic Concierge)
  if (q.contains('rỉ nước') ||
      q.contains('vòi sen') ||
      q.contains('sửa') ||
      q.contains('hỏng') ||
      q.contains('máy lạnh')) {
    await ticketProv.createTicket(
      roomCode: roomCode,
      authorName: userName,
      title: query.length > 55 ? '${query.substring(0, 55)}...' : query,
      description:
          'Tự động khởi tạo bởi Agentic AI Concierge từ yêu cầu chat: "$query"',
      categoryName: q.contains('nước') || q.contains('vòi')
          ? 'Hệ thống nước'
          : 'Điện - Điện lạnh',
      priority: 'Khẩn cấp',
    );
    return AiToolExecutionResult(
      toolBadge: 'Kích hoạt Tool: create_kanban_ticket()',
      toolColor: const Color(0xFFDC2626),
      details: [
        'Phòng: $roomCode ($userName)',
        'Vấn đề: $query',
        'Mức độ: Khẩn cấp (Xử lý trong 2h)',
        'Kỹ thuật phụ trách: Nguyễn Văn Bình',
      ],
      statusSummary: 'Phiếu sự cố mới đã được đẩy lên Bảng Kanban!',
      snackbarMessage:
          'AI Agent đã tự động tạo thành công 1 Ticket sự cố mới trên bảng Kanban!',
    );
  }

  if (q.contains('tiền điện') || q.contains('hóa đơn') || q.contains('cao')) {
    return AiToolExecutionResult(
      toolBadge: 'Kích hoạt Tool: query_invoice_breakdown()',
      toolColor: const Color(0xFF2563EB),
      details: [
        'Phòng: $roomCode',
        'Tháng 10: 120 kWh (254.000 đ)',
        'Tháng 09: 90 kWh (162.000 đ)',
        'Chênh lệch: +30 kWh (+92.000 đ)',
      ],
      statusSummary: 'Đã phân tích biểu đồ lũy tiến Bậc 3',
    );
  }

  if (q.contains('vietqr') || q.contains('thanh toán')) {
    return const AiToolExecutionResult(
      toolBadge: 'Kích hoạt Tool: generate_vietqr_link()',
      toolColor: Color(0xFFD97706),
      details: [
        'Ngân hàng: MB Bank - 0389999888',
        'Số tiền: 3.924.000 đ',
        'Nội dung: SMARTSTAY P305 T10',
      ],
      statusSummary: 'Đã sinh mã động VietQR Napas247 thành công!',
    );
  }

  if (q.contains('mở khóa') || q.contains('cửa')) {
    return AiToolExecutionResult(
      toolBadge: 'Kích hoạt Tool: remote_iot_lock_control()',
      toolColor: const Color(0xFF8B5CF6),
      details: [
        'Thiết bị: SmartLock-P305 (MQTT TLS)',
        'Lệnh: UNLOCK_TEMPORARY (5s)',
        'Người yêu cầu: $userName',
      ],
      statusSummary: 'Đã gửi xung mở khóa từ xa thành công!',
    );
  }

  return null;
}

class AiFloatingBubble extends StatefulWidget {
  final VoidCallback? onOpenFullScreen;

  const AiFloatingBubble({super.key, this.onOpenFullScreen});

  @override
  State<AiFloatingBubble> createState() => _AiFloatingBubbleState();
}

class _AiFloatingBubbleState extends State<AiFloatingBubble> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isOpen = false;
  String? _roleModeOverride;

  static const List<String> _adminQuickPrompts = [
    'Báo cáo doanh thu & công nợ tháng này',
    'Kiểm tra cấu hình ngân hàng VietQR & hệ thống',
    'Thống kê phòng trống & tỷ lệ lấp đầy',
    'Phát thông báo nhắc đóng phí toàn tòa nhà',
  ];

  static const List<String> _managerQuickPrompts = [
    'Kiểm tra sự cố Kanban khẩn cấp',
    'Điều phối kỹ thuật viên xử lý phòng P.305',
    'Mở khóa cửa IoT từ xa P.305',
    'Giám sát công tơ điện nước bất thường',
  ];

  static const List<String> _residentQuickPrompts = [
    'Tại sao tháng này tiền điện phòng tôi cao vậy?',
    'Phòng tôi bị rỉ nước vòi sen, gọi thợ sửa gấp!',
    'Bảng giá điện nước bậc thang',
    'Hướng dẫn thanh toán VietQR',
    'Quy định gửi xe qua đêm của tòa nhà',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendBubbleMessage(
    String roleMode, [
    String? overrideText,
  ]) async {
    final text = (overrideText ?? _inputController.text).trim();
    if (text.isEmpty) return;

    if (overrideText == null) {
      _inputController.clear();
    }

    final auth = context.read<AuthProvider>();
    final aiProv = context.read<AiChatProvider>();
    final isAdminLike = roleMode != 'resident';

    final toolResult = await executeSmartStayAiTools(
      context: context,
      query: text,
      isAdminMode: isAdminLike,
    );
    if (!mounted) return;

    if (toolResult?.snackbarMessage != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(toolResult!.snackbarMessage!),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
    }

    await aiProv.sendMessage(
      text,
      currentUser: auth.user,
      forceAdminMode: isAdminLike,
      roleMode: roleMode,
      adminContextSummary: toolResult?.liveReplySummary,
    );
    _scrollToBottom();
  }

  List<Color> _roleGradient(String roleMode) {
    return switch (roleMode) {
      'admin' => const [Color(0xFF6D28D9), Color(0xFF2563EB)],
      'manager' => const [Color(0xFF0F766E), Color(0xFF2563EB)],
      _ => const [Color(0xFF4F46E5), Color(0xFF0EA5E9)],
    };
  }

  Widget _buildLauncherButton(String roleMode, bool isCompactScreen) {
    final gradColors = _roleGradient(roleMode);
    final labelText = _isOpen
        ? 'Thu gọn AI'
        : (isCompactScreen
            ? 'AI 24/7'
            : switch (roleMode) {
                'admin' => 'AI Hỗ Trợ Admin',
                'manager' => 'AI Ban Quản Lý',
                _ => 'AI Hỗ Trợ Cư Dân',
              });

    return Material(
      color: Colors.transparent,
      elevation: 8,
      shadowColor: const Color(0xFF4F46E5).withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () {
          final auth = context.read<AuthProvider>();
          final aiProv = context.read<AiChatProvider>();
          aiProv.syncRoleGreeting(
            isAdmin: roleMode != 'resident',
            roleMode: roleMode,
            userName: auth.user?.fullName,
            roomCode: auth.user?.effectiveRoomCode,
          );
          setState(() => _isOpen = !_isOpen);
          if (_isOpen) _scrollToBottom();
        },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: EdgeInsets.symmetric(
            horizontal: isCompactScreen ? 14 : 18,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradColors),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFF34D399),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                _isOpen ? Icons.close_rounded : Icons.smart_toy_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                labelText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? const Color(0xFF4338CA) : Colors.white,
          ),
        ),
      ),
    );
  }

  void _selectRoleMode(String mode) {
    final auth = context.read<AuthProvider>();
    final aiProv = context.read<AiChatProvider>();
    setState(() => _roleModeOverride = mode);
    aiProv.clearChat(
      isAdmin: mode != 'resident',
      roleMode: mode,
      userName: auth.user?.fullName,
      roomCode: auth.user?.effectiveRoomCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final aiProv = context.watch<AiChatProvider>();
    final effectiveRoleMode = AiChatProvider.resolveRoleMode(
      isAdmin: auth.isAdmin,
      explicitRoleMode: _roleModeOverride,
      userRole: auth.currentRole,
    );
    final isAdminLike = effectiveRoleMode != 'resident';
    final size = MediaQuery.of(context).size;
    final isCompactScreen = size.width < 520;
    final popupWidth = math.min(385.0, math.max(240.0, size.width - 24));
    final popupHeight = math.min(500.0, math.max(280.0, size.height - 150));
    final quickPrompts = switch (effectiveRoleMode) {
      'admin' => _adminQuickPrompts,
      'manager' => _managerQuickPrompts,
      _ => _residentQuickPrompts,
    };
    final headerTitleText = switch (effectiveRoleMode) {
      'admin' => 'AI Copilot Admin Hệ Thống',
      'manager' => 'AI Điều Hành Ban Quản Lý',
      _ => 'SmartStay AI Người Dùng',
    };
    final headerSubText = switch (effectiveRoleMode) {
      'admin' => 'Doanh thu, cấu hình VietQR & toàn tòa nhà',
      'manager' => 'Điều phối Kanban, khóa IoT & cư dân',
      _ => 'Hỗ trợ hóa đơn, VietQR & báo sự cố',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isOpen)
          Container(
            width: popupWidth,
            height: popupHeight,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFCBD5E1)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.2),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _roleGradient(effectiveRoleMode),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  headerTitleText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  headerSubText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() => _isOpen = false);
                              showSmartStayCallModal(
                                context,
                                initialTargetRole: effectiveRoleMode == 'resident'
                                    ? 'QuanLy'
                                    : 'CuDan',
                                initialTargetName: effectiveRoleMode == 'resident'
                                    ? 'Ban Quản Lý (Trực ca 24/7)'
                                    : 'Hồ Ngọc Bảo (Cư dân P.305)',
                                initialVideo: true,
                              );
                            },
                            tooltip: 'Gọi Thoại / Video trực tiếp',
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.videocam_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          if (widget.onOpenFullScreen != null)
                            IconButton(
                              onPressed: () {
                                setState(() => _isOpen = false);
                                widget.onOpenFullScreen?.call();
                              },
                              tooltip: 'Mở toàn màn hình',
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.open_in_full_rounded,
                                color: Colors.white,
                                size: 17,
                              ),
                            ),
                          IconButton(
                            onPressed: () {
                              aiProv.clearChat(
                                isAdmin: isAdminLike,
                                roleMode: effectiveRoleMode,
                                userName: auth.user?.fullName,
                                roomCode: auth.user?.effectiveRoomCode,
                              );
                            },
                            tooltip: 'Làm mới hội thoại',
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _isOpen = false),
                            tooltip: 'Thu gọn',
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildModeChip(
                            label: 'Người dùng',
                            selected: effectiveRoleMode == 'resident',
                            onTap: () => _selectRoleMode('resident'),
                          ),
                          _buildModeChip(
                            label: 'Ban Quản lý',
                            selected: effectiveRoleMode == 'manager',
                            onTap: () => _selectRoleMode('manager'),
                          ),
                          _buildModeChip(
                            label: 'Admin',
                            selected: effectiveRoleMode == 'admin',
                            onTap: () => _selectRoleMode('admin'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Messages list
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount:
                          aiProv.messages.length + (aiProv.isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == aiProv.messages.length &&
                            aiProv.isTyping) {
                          return const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                '⏳ AI đang phân tích dữ liệu...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          );
                        }

                        final msg = aiProv.messages[index];
                        final isMe = msg.isUser;
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            constraints:
                                BoxConstraints(maxWidth: popupWidth * 0.84),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? const Color(0xFF4F46E5)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(13),
                              border: isMe
                                  ? null
                                  : Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                            ),
                            child: Text(
                              msg.content,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.4,
                                color: isMe
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Quick prompts
                Container(
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    scrollDirection: Axis.horizontal,
                    itemCount: quickPrompts.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (context, idx) {
                      final prompt = quickPrompts[idx];
                      return OutlinedButton(
                        onPressed: () =>
                            _sendBubbleMessage(effectiveRoleMode, prompt),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          prompt,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF334155),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Input bar
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          onSubmitted: (_) =>
                              _sendBubbleMessage(effectiveRoleMode),
                          style: const TextStyle(fontSize: 12.5),
                          decoration: InputDecoration(
                            hintText: isAdminLike
                                ? 'Hỏi AI về doanh thu, Kanban, IoT...'
                                : 'Hỏi AI về hóa đơn, sự cố, nội quy...',
                            isDense: true,
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () =>
                              _sendBubbleMessage(effectiveRoleMode),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Icon(Icons.send_rounded, size: 17),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        _buildLauncherButton(effectiveRoleMode, isCompactScreen),
      ],
    );
  }
}
