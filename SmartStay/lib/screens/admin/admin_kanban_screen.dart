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

  @override
  Widget build(BuildContext context) {
    final ticketProvider = context.watch<TicketProvider>();
    final admin = context.watch<AdminProvider>();
    final tickets = ticketProvider.tickets;

    final todoTickets = tickets.where((t) => t.status == 'Chờ xử lý').toList();
    final inProgressTickets = tickets.where((t) => t.status == 'Đang sửa').toList();
    final doneTickets = tickets.where((t) => t.status == 'Hoàn thành').toList();

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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2563EB),
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'Chờ Xử Lý (${todoTickets.length})'),
            Tab(text: 'Đang Sửa (${inProgressTickets.length})'),
            Tab(text: 'Hoàn Thành (${doneTickets.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildColumn(todoTickets, 'Chờ xử lý', ticketProvider, admin),
          _buildColumn(inProgressTickets, 'Đang sửa', ticketProvider, admin),
          _buildColumn(doneTickets, 'Hoàn thành', ticketProvider, admin),
        ],
      ),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_turned_in_outlined, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              'Không có sự cố nào ở cột "$status"',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: columnTickets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ticket = columnTickets[index];
        return _buildKanbanCard(ticket, ticketProvider, admin);
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

    // Tính thời gian SLA
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
          // Header: Code & Room & SLA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      ticket.ticketCode,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF475569)),
                    ),
                  ),
                  const SizedBox(width: 8),
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
              Row(
                children: [
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
                  Text(
                    isOverdue
                        ? 'ĐÃ QUÁ HẠN SLA XỬ LÝ (${ticket.remainingTime.abs().inHours}h)'
                        : 'SLA xử lý: Còn ${remainingHours > 0 ? "$remainingHours giờ" : "${ticket.remainingTime.inMinutes} phút"}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Kỹ thuật viên phụ trách & ngày tạo
          Row(
            children: [
              const Icon(Icons.engineering_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                ticket.technicianName != null
                    ? 'KTV: ${ticket.technicianName}'
                    : 'Chưa phân công KTV',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: ticket.technicianName != null ? FontWeight.w600 : FontWeight.normal,
                  color: ticket.technicianName != null ? const Color(0xFF0F172A) : const Color(0xFFEF4444),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _showAuditLogDialog(context, ticket),
                child: Row(
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

          // Kanban Transition Buttons (Chuẩn luồng đặc tả)
          Row(
            children: [
              if (ticket.status == 'Chờ xử lý') ...[
                if (ticket.technicianName == null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.person_add_rounded, size: 15),
                      label: const Text('Phân Công KTV', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => _showAssignDialog(context, ticket, ticketProvider, admin),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                      label: const Text('Nhận & Sửa Ngay', style: TextStyle(fontSize: 11, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () {
                        final defaultTech = admin.staffList.isNotEmpty
                            ? admin.staffList.first.fullName
                            : 'Ban Quản lý & Kỹ thuật';
                        ticketProvider.assignTechnician(ticket.ticketId, defaultTech);
                        ticketProvider.startRepair(ticket.ticketId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã tiếp nhận và bắt đầu sửa chữa ${ticket.ticketCode}!')),
                        );
                      },
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                      label: const Text('Đổi KTV', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => _showAssignDialog(context, ticket, ticketProvider, admin),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                      label: const Text('Bắt Đầu Sửa Chữa', style: TextStyle(fontSize: 12, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () {
                        ticketProvider.startRepair(ticket.ticketId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('KTV ${ticket.technicianName} đã bắt đầu xử lý ${ticket.ticketCode}!')),
                        );
                      },
                    ),
                  ),
                ],
              ] else if (ticket.status == 'Đang sửa') ...[
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                    label: const Text('Đổi KTV', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => _showAssignDialog(context, ticket, ticketProvider, admin),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_rounded, size: 15, color: Colors.white),
                    label: const Text('Nghiệm Thu Xong', style: TextStyle(fontSize: 12, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => _showCompleteDialog(context, ticket, ticketProvider),
                  ),
                ),
              ] else ...[
                // Cột hoàn thành
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF16A34A)),
                        const SizedBox(width: 6),
                        Text(
                          'Đã sửa xong • Chi phí: ${Formatters.formatCurrency(ticket.materialCost ?? 0)} • Đánh giá: ${ticket.rating != null ? "${ticket.rating}★" : "Chờ đánh giá"}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
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
                      SnackBar(content: Text('Đã phân công ${staff.fullName} cho sự cố ${ticket.ticketCode}. Phiếu vẫn ở trạng thái Chờ xử lý cho đến khi KTV bắt đầu.')),
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
    final costCtrl = TextEditingController(text: '0');
    final noteCtrl = TextEditingController(text: 'Đã hoàn tất khắc phục và nghiệm thu');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Nghiệm Thu Hoàn Thành - ${ticket.ticketCode}'),
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
                  SnackBar(content: Text('Đã hoàn thành sự cố ${ticket.ticketCode}!')),
                );
              },
              child: const Text('Xác nhận hoàn thành', style: TextStyle(color: Colors.white)),
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
