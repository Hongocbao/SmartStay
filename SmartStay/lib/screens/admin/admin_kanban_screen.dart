import 'package:flutter/material.dart';
import '../../utils/provider_scope.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/ticket_model.dart';
import '../../utils/formatters.dart';
import 'admin_iot_screen.dart';

class AdminKanbanScreen extends StatefulWidget {
  const AdminKanbanScreen({super.key});

  @override
  State<AdminKanbanScreen> createState() => _AdminKanbanScreenState();
}

class _AdminKanbanScreenState extends State<AdminKanbanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _resolveDefaultTechnician(AdminProvider admin) {
    final techs = admin.staffList.where((s) => s.role == 'Kỹ thuật viên').toList();
    if (techs.isNotEmpty) return techs.first.fullName;
    if (admin.staffList.isNotEmpty) return admin.staffList.first.fullName;
    return 'Nguyễn Văn Bình';
  }

  void _handleTicketDrop(
    BuildContext context,
    TicketModel ticket,
    String targetStatus,
    TicketProvider ticketProvider,
    AdminProvider admin,
  ) {
    if (ticket.status == targetStatus) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    if (targetStatus == 'Đang sửa') {
      if (ticket.technicianName == null || ticket.technicianName!.trim().isEmpty) {
        ticketProvider.assignTechnician(
          ticket.ticketId,
          _resolveDefaultTechnician(admin),
        );
      }
      ticketProvider.startRepair(ticket.ticketId);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Đã chuyển ${ticket.ticketCode} sang Đang sửa & đồng bộ Kanban!'),
          backgroundColor: const Color(0xFF4F46E5),
        ),
      );
    } else if (targetStatus == 'Hoàn thành') {
      ticketProvider.completeRepair(
        ticket.ticketId,
        materialCost: ticket.materialCost ?? 0.0,
        note: 'Đã hoàn thành & đồng bộ trên bảng Kanban',
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text('Đã hoàn thành sự cố ${ticket.ticketCode}!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else {
      ticketProvider.updateTicketStatus(
        ticket.ticketId,
        'Chờ xử lý',
        actorName: 'Quản lý vận hành',
        note: 'Chuyển trạng thái về Chờ xử lý trên Kanban',
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text('Đã chuyển ${ticket.ticketCode} về cột Chờ xử lý!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = context.watch<TicketProvider>();
    final admin = context.watch<AdminProvider>();
    final tickets = ticketProvider.tickets;

    final todoTickets = tickets.where((t) => t.status == 'Chờ xử lý').toList();
    final inProgressTickets = tickets.where((t) => t.status == 'Đang sửa').toList();
    final doneTickets = tickets.where((t) => t.status == 'Hoàn thành').toList();

    final isWide = MediaQuery.sizeOf(context).width >= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Kanban Quản Lý & Kỹ Thuật Bảo Trì',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            tooltip: 'Tạo phiếu sự cố kỹ thuật mới',
            icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF2563EB)),
            onPressed: () => _showCreateTicketModal(context, ticketProvider, admin),
          ),
          IconButton(
            tooltip: 'Điều khiển Khóa IoT & Nhật ký ra vào',
            icon: const Icon(Icons.lock_open_rounded, color: Color(0xFF0284C7)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminIotScreen()),
              );
            },
          ),
        ],
        bottom: isWide
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF4F46E5),
                labelColor: const Color(0xFF4F46E5),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: [
                  _buildDraggableTabTarget(
                    label: 'Chờ Xử Lý',
                    count: todoTickets.length,
                    targetStatus: 'Chờ xử lý',
                    accentColor: const Color(0xFFF59E0B),
                    ticketProvider: ticketProvider,
                    admin: admin,
                  ),
                  _buildDraggableTabTarget(
                    label: 'Đang Sửa',
                    count: inProgressTickets.length,
                    targetStatus: 'Đang sửa',
                    accentColor: const Color(0xFF4F46E5),
                    ticketProvider: ticketProvider,
                    admin: admin,
                  ),
                  _buildDraggableTabTarget(
                    label: 'Hoàn Thành',
                    count: doneTickets.length,
                    targetStatus: 'Hoàn thành',
                    accentColor: const Color(0xFF10B981),
                    ticketProvider: ticketProvider,
                    admin: admin,
                  ),
                ],
              ),
      ),
      body: isWide
          ? _buildWideBoard(
              context,
              todoTickets,
              inProgressTickets,
              doneTickets,
              ticketProvider,
              admin,
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildColumn(todoTickets, 'Chờ xử lý', ticketProvider, admin),
                _buildColumn(inProgressTickets, 'Đang sửa', ticketProvider, admin),
                _buildColumn(doneTickets, 'Hoàn thành', ticketProvider, admin),
              ],
            ),
    );
  }

  Widget _buildDraggableTabTarget({
    required String label,
    required int count,
    required String targetStatus,
    required Color accentColor,
    required TicketProvider ticketProvider,
    required AdminProvider admin,
  }) {
    return DragTarget<TicketModel>(
      onWillAcceptWithDetails: (details) => details.data.status != targetStatus,
      onAcceptWithDetails: (details) =>
          _handleTicketDrop(context, details.data, targetStatus, ticketProvider, admin),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Tab(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isHovering ? accentColor.withValues(alpha: 0.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isHovering ? Border.all(color: accentColor, width: 1.5) : null,
            ),
            child: Text(
              '$label ($count)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWideBoard(
    BuildContext context,
    List<TicketModel> todoTickets,
    List<TicketModel> inProgressTickets,
    List<TicketModel> doneTickets,
    TicketProvider ticketProvider,
    AdminProvider admin,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.view_kanban_rounded, size: 17, color: Color(0xFF4F46E5)),
                    SizedBox(width: 6),
                    Text(
                      'QUY TRÌNH 3 BƯỚC:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                _buildStepPill('1. Chờ xử lý', const Color(0xFFF1F5F9), const Color(0xFF475569)),
                const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF94A3B8)),
                _buildStepPill('2. Đang sửa', const Color(0xFFEEF2FF), const Color(0xFF4F46E5)),
                const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF94A3B8)),
                _buildStepPill('3. Hoàn thành', const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_with_rounded, size: 13, color: Color(0xFF4F46E5)),
                      SizedBox(width: 4),
                      Text(
                        'Kéo thả thẻ giữa các cột để chuyển trạng thái',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildWideKanbanColumn(
                    context: context,
                    stepNumber: '1',
                    title: 'CHỜ XỬ LÝ',
                    status: 'Chờ xử lý',
                    accentColor: const Color(0xFFF59E0B),
                    columnBg: const Color(0xFFF1F5F9),
                    columnTickets: todoTickets,
                    ticketProvider: ticketProvider,
                    admin: admin,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildWideKanbanColumn(
                    context: context,
                    stepNumber: '2',
                    title: 'ĐANG SỬA CHỮA',
                    status: 'Đang sửa',
                    accentColor: const Color(0xFF4F46E5),
                    columnBg: const Color(0xFFEEF2FF),
                    columnTickets: inProgressTickets,
                    ticketProvider: ticketProvider,
                    admin: admin,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildWideKanbanColumn(
                    context: context,
                    stepNumber: '3',
                    title: 'ĐÃ HOÀN THÀNH',
                    status: 'Hoàn thành',
                    accentColor: const Color(0xFF10B981),
                    columnBg: const Color(0xFFF0FDF4),
                    columnTickets: doneTickets,
                    ticketProvider: ticketProvider,
                    admin: admin,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _buildWideKanbanColumn({
    required BuildContext context,
    required String stepNumber,
    required String title,
    required String status,
    required Color accentColor,
    required Color columnBg,
    required List<TicketModel> columnTickets,
    required TicketProvider ticketProvider,
    required AdminProvider admin,
  }) {
    return DragTarget<TicketModel>(
      onWillAcceptWithDetails: (details) => details.data.status != status,
      onAcceptWithDetails: (details) =>
          _handleTicketDrop(context, details.data, status, ticketProvider, admin),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isHovering ? const Color(0xFFE0E7FF) : columnBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isHovering ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
              width: isHovering ? 2 : 1,
            ),
            boxShadow: isHovering
                ? [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.14),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            stepNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: status == 'Chờ xử lý' ? const Color(0xFF1E293B) : accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      '${columnTickets.length} Ticket${columnTickets.length > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: columnTickets.isEmpty
                    ? Center(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isHovering ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.open_with_rounded,
                                size: 30,
                                color: isHovering ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Kéo thả phiếu sự cố vào cột này',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isHovering ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: columnTickets.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildDraggableCard(
                            columnTickets[index],
                            ticketProvider,
                            admin,
                            isWide: true,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColumn(
    List<TicketModel> columnTickets,
    String status,
    TicketProvider ticketProvider,
    AdminProvider admin,
  ) {
    if (columnTickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.assignment_turned_in_outlined, size: 48, color: Color(0xFFCBD5E1)),
              const SizedBox(height: 12),
              Text(
                'Không có sự cố nào ở cột "$status"\nNhấn giữ thẻ và kéo vào tiêu đề tab để chuyển cột',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: columnTickets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ticket = columnTickets[index];
        return _buildDraggableCard(ticket, ticketProvider, admin, isWide: false);
      },
    );
  }

  Widget _buildDraggableCard(
    TicketModel ticket,
    TicketProvider ticketProvider,
    AdminProvider admin, {
    required bool isWide,
  }) {
    final cardWidget = _buildKanbanCard(ticket, ticketProvider, admin);
    return LayoutBuilder(
      builder: (context, constraints) {
        final feedbackWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(240.0, 360.0)
            : 300.0;
        final feedback = Material(
          color: Colors.transparent,
          elevation: 10,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: feedbackWidth,
            child: Transform.rotate(
              angle: 0.02,
              child: Opacity(opacity: 0.92, child: cardWidget),
            ),
          ),
        );
        final childWhenDragging = Opacity(opacity: 0.35, child: cardWidget);

        if (isWide) {
          return Draggable<TicketModel>(
            data: ticket,
            feedback: feedback,
            childWhenDragging: childWhenDragging,
            child: cardWidget,
          );
        }

        return LongPressDraggable<TicketModel>(
          data: ticket,
          delay: const Duration(milliseconds: 220),
          feedback: feedback,
          childWhenDragging: childWhenDragging,
          child: cardWidget,
        );
      },
    );
  }

  Widget _buildKanbanCard(TicketModel ticket, TicketProvider ticketProvider, AdminProvider admin) {
    Color priorityColor;
    switch (ticket.priority) {
      case 'Khẩn cấp':
        priorityColor = const Color(0xFFDC2626);
        break;
      case 'Cao':
        priorityColor = const Color(0xFFF59E0B);
        break;
      default:
        priorityColor = const Color(0xFF10B981);
    }

    final isOverdue = ticket.isOverdue;
    final remainingHours = ticket.remainingTime.inHours;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: isOverdue ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Grip, Code, Room & Priority
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(Icons.drag_indicator_rounded, size: 16, color: Color(0xFF94A3B8)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        ticket.ticketCode,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF475569)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        ticket.roomCode,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF2563EB)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ticket.priority,
                  style: TextStyle(color: priorityColor, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Text(
            ticket.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            ticket.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
          ),

          // Cảnh báo SLA
          if (ticket.status != 'Hoàn thành') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isOverdue ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isOverdue ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOverdue ? Icons.timer_off_outlined : Icons.timer_outlined,
                    size: 13,
                    color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      isOverdue
                          ? 'ĐÃ QUÁ HẠN SLA XỬ LÝ (${ticket.remainingTime.abs().inHours}h)'
                          : 'SLA xử lý: Còn ${remainingHours > 0 ? "$remainingHours giờ" : "${ticket.remainingTime.inMinutes} phút"}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Kỹ thuật viên phụ trách & lịch sử
          Row(
            children: [
              const Icon(Icons.engineering_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  ticket.technicianName != null
                      ? 'KTV: ${ticket.technicianName}'
                      : 'Chưa phân công KTV',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: ticket.technicianName != null ? FontWeight.w600 : FontWeight.normal,
                    color: ticket.technicianName != null ? const Color(0xFF0F172A) : const Color(0xFFEF4444),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showAuditLogDialog(context, ticket),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history_rounded, size: 14, color: Color(0xFF2563EB)),
                    const SizedBox(width: 2),
                    Text(
                      'Lịch sử (${ticket.activityLogs.length})',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Nút chuyển nhanh 1 chạm (không qua hộp thoại xác nhận) + nút phụ đổi KTV / sửa chi phí
          Row(
            children: [
              if (ticket.status == 'Chờ xử lý') ...[
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(
                      ticket.technicianName == null ? Icons.person_add_rounded : Icons.swap_horiz_rounded,
                      size: 14,
                    ),
                    label: Text(
                      ticket.technicianName == null ? 'Chọn KTV' : 'Đổi KTV',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    ),
                    onPressed: () => _showAssignDialog(context, ticket, ticketProvider, admin),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                    label: const Text(
                      'Bắt Đầu Sửa',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      backgroundColor: const Color(0xFFF59E0B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    ),
                    onPressed: () => _handleTicketDrop(context, ticket, 'Đang sửa', ticketProvider, admin),
                  ),
                ),
              ] else if (ticket.status == 'Đang sửa') ...[
                SizedBox(
                  width: 44,
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _handleTicketDrop(context, ticket, 'Chờ xử lý', ticketProvider, admin),
                    child: const Icon(Icons.arrow_back_rounded, size: 16),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                    label: const Text(
                      'Đổi KTV',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    ),
                    onPressed: () => _showAssignDialog(context, ticket, ticketProvider, admin),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_rounded, size: 15, color: Colors.white),
                    label: const Text(
                      'Hoàn Thành',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    ),
                    onPressed: () => _handleTicketDrop(context, ticket, 'Hoàn thành', ticketProvider, admin),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF16A34A)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Đã xong • Chi phí: ${Formatters.formatCurrency(ticket.materialCost ?? 0)} • ${ticket.rating != null ? "${ticket.rating}★" : "Chờ đánh giá"}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Sửa chi phí vật tư',
                  icon: const Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF4F46E5)),
                  onPressed: () => _showCompleteDialog(context, ticket, ticketProvider),
                ),
                IconButton(
                  tooltip: 'Chuyển lại Đang sửa',
                  icon: const Icon(Icons.replay_rounded, size: 18, color: Color(0xFF64748B)),
                  onPressed: () => _handleTicketDrop(context, ticket, 'Đang sửa', ticketProvider, admin),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(
    BuildContext context,
    TicketModel ticket,
    TicketProvider ticketProvider,
    AdminProvider admin,
  ) {
    final staffList = admin.staffList.where((s) => s.role == 'Kỹ thuật viên').toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Phân Công Xử Lý - ${ticket.ticketCode}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sự cố: ${ticket.title}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('Phòng: ${ticket.roomCode} • Mức ưu tiên: ${ticket.priority}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              const Text('Chọn Kỹ thuật viên phụ trách:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...staffList.map((staff) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Icon(Icons.person, color: Color(0xFF2563EB)),
                  ),
                  title: Text(staff.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text(staff.phone, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    ticketProvider.assignTechnician(ticket.ticketId, staff.fullName);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã phân công ${staff.fullName} cho sự cố ${ticket.ticketCode}.')),
                    );
                  },
                );
              }),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          ],
        );
      },
    );
  }

  void _showCompleteDialog(BuildContext context, TicketModel ticket, TicketProvider ticketProvider) {
    final costCtrl = TextEditingController(text: (ticket.materialCost ?? 0).round().toString());
    final noteCtrl = TextEditingController(text: 'Đã hoàn tất khắc phục và nghiệm thu');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Cập Nhật Nghiệm Thu - ${ticket.ticketCode}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: costCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Chi phí vật tư / phụ tùng thay thế (VNĐ)',
                  prefixIcon: Icon(Icons.build_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú nghiệm thu',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () {
                final cost = double.tryParse(costCtrl.text) ?? 0.0;
                ticketProvider.completeRepair(ticket.ticketId, materialCost: cost, note: noteCtrl.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã cập nhật chi phí vật tư cho ${ticket.ticketCode}!')),
                );
              },
              child: const Text('Lưu cập nhật', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showAuditLogDialog(BuildContext context, TicketModel ticket) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Nhật Ký Xử Lý - ${ticket.ticketCode}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ticket.activityLogs.isEmpty
                ? const Text('Chưa có ghi nhận lịch sử xử lý.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: ticket.activityLogs.length,
                    separatorBuilder: (_, _) => const Divider(height: 12),
                    itemBuilder: (context, i) {
                      final log = ticket.activityLogs[i];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.radio_button_checked, size: 14, color: Color(0xFF2563EB)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.action,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                Text(
                                  'Người thực hiện: ${log.actorName} • ${Formatters.formatDateTime(log.timestamp)}',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                ),
                                if (log.note != null && log.note!.isNotEmpty)
                                  Text(
                                    log.note!,
                                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          ],
        );
      },
    );
  }

  void _showCreateTicketModal(BuildContext context, TicketProvider ticketProvider, AdminProvider admin) {
    final descCtrl = TextEditingController();
    final occupiedRooms = admin.rooms.where((r) => r.status == 'Đang ở').toList();
    String selectedRoom = occupiedRooms.isNotEmpty ? occupiedRooms.first.roomCode : 'P.305';
    String selectedCategory = 'Thiết bị điện (Máy lạnh, đèn, ổ cắm)';
    String selectedPriority = 'Cao';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.build_circle_rounded, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tạo Phiếu Sự Cố Kỹ Thuật Mới',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedRoom,
                      decoration: const InputDecoration(
                        labelText: 'Căn hộ / Số phòng',
                        prefixIcon: Icon(Icons.meeting_room_outlined),
                      ),
                      items: occupiedRooms.map((r) {
                        return DropdownMenuItem(
                          value: r.roomCode,
                          child: Text('${r.roomCode} (${r.residentName ?? "Cư dân"})', style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => selectedRoom = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục hỏng hóc',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Thiết bị điện (Máy lạnh, đèn, ổ cắm)',
                          child: Text('Thiết bị điện (Máy lạnh, đèn, ổ cắm)', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'Đường ống nước & Vòi sen',
                          child: Text('Đường ống nước & Vòi sen', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'Khóa cửa thông minh & Thẻ từ',
                          child: Text('Khóa cửa thông minh & Thẻ từ', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'Nội thất gỗ & Cửa sổ',
                          child: Text('Nội thất gỗ & Cửa sổ', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => selectedCategory = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Mức độ ưu tiên',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Khẩn cấp', child: Text('Khẩn cấp (Xử lý trong 2h)')),
                        DropdownMenuItem(value: 'Cao', child: Text('Ưu tiên Cao (Trong ngày)')),
                        DropdownMenuItem(value: 'Trung bình', child: Text('Trung bình (Trong 48h)')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => selectedPriority = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả tình trạng sự cố',
                        hintText: 'Nhập chi tiết triệu chứng hỏng hóc...',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Hủy')),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded, size: 15, color: Colors.white),
                  label: const Text('Phát Hành Phiếu Sự Cố', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  onPressed: () async {
                    final desc = descCtrl.text.trim().isEmpty
                        ? 'Báo hỏng $selectedCategory tại phòng $selectedRoom'
                        : descCtrl.text.trim();
                    await ticketProvider.createTicket(
                      categoryName: selectedCategory,
                      title: desc,
                      description: '$selectedCategory • Phòng $selectedRoom',
                      priority: selectedPriority,
                      roomCode: selectedRoom,
                      authorName: 'Ban Quản lý & Kỹ thuật',
                    );
                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã tạo thành công phiếu sự cố cho phòng $selectedRoom! Phiếu đã đưa vào cột Chờ Xử Lý.'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
