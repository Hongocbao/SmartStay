import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/announcement_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/provider_scope.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final commProv = context.watch<CommunityProvider>();
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            isAdmin ? 'Truyền Thông Nội Bộ & Sự Kiện' : 'Bảng tin & Sự kiện',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          centerTitle: !isAdmin,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          actions: [
            if (isAdmin) ...[
              IconButton(
                tooltip: 'Soạn thông báo phát sóng mới',
                icon: const Icon(Icons.campaign_rounded, color: Color(0xFF2563EB)),
                onPressed: () => _showBroadcastModal(context, commProv),
              ),
              IconButton(
                tooltip: 'Tạo sự kiện cộng đồng mới',
                icon: const Icon(Icons.event_rounded, color: Color(0xFF16A34A)),
                onPressed: () => _showCreateEventModal(context, commProv),
              ),
            ],
          ],
          bottom: const TabBar(
            labelColor: Color(0xFF2563EB),
            unselectedLabelColor: Color(0xFF64748B),
            indicatorColor: Color(0xFF2563EB),
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Thông báo nội khu'),
              Tab(text: 'Sự kiện cộng đồng'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (isAdmin)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF16A34A)),
                          SizedBox(width: 4),
                          Text(
                            'Firebase FCM: Hoạt động',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF166534),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () => _showBroadcastModal(context, commProv),
                      icon: const Icon(Icons.send_rounded, size: 14),
                      label: const Text('Soạn thông báo mới', style: TextStyle(fontSize: 12)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Thông báo
                  RefreshIndicator(
                    onRefresh: () async => commProv.loadData(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: commProv.announcements.length,
                      itemBuilder: (context, index) {
                        final a = commProv.announcements[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: a.isImportant
                                  ? const Color(0xFFFECACA)
                                  : const Color(0xFFE2E8F0),
                              width: a.isImportant ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
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
                                      color: a.isImportant
                                          ? const Color(0xFFDC2626).withValues(alpha: 0.12)
                                          : const Color(0xFF2563EB).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      a.isImportant ? 'Quan trọng • ${a.scope}' : a.scope,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: a.isImportant
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    AppFormatters.dateTime(a.createdAt),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  if (isAdmin) ...[
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () => commProv.deleteAnnouncement(a.announcementId),
                                      child: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                a.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                a.content,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF475569),
                                  height: 1.45,
                                ),
                              ),
                              if (isAdmin) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  '• Đã gửi qua Firebase FCM đến toàn bộ thiết bị cư dân',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF16A34A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Tab 2: Sự kiện
                  RefreshIndicator(
                    onRefresh: () async => commProv.loadData(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: commProv.events.length,
                      itemBuilder: (context, index) {
                        final ev = commProv.events[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.event_available,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        ev.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ev.description,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          size: 16,
                                          color: Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            ev.location,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${AppFormatters.dateTime(ev.startTime)} - ${AppFormatters.date(ev.endTime)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF334155),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.group_outlined,
                                          size: 16,
                                          color: Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Đã đăng ký: ${ev.currentParticipants}/${ev.maxParticipants} cư dân',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 42,
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                commProv.toggleEventRegistration(ev.eventId);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      ev.isRegistered
                                                          ? 'Đã hủy đăng ký tham gia'
                                                          : 'Đã đăng ký tham gia thành công!',
                                                    ),
                                                    backgroundColor: ev.isRegistered
                                                        ? Colors.grey
                                                        : const Color(0xFF16A34A),
                                                  ),
                                                );
                                              },
                                              icon: Icon(
                                                ev.isRegistered
                                                    ? Icons.check_circle
                                                    : Icons.how_to_reg_outlined,
                                              ),
                                              label: Text(
                                                ev.isRegistered
                                                    ? 'Đã đăng ký (Chạm để hủy)'
                                                    : 'Đăng ký tham gia ngay',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: ev.isRegistered
                                                    ? const Color(0xFF16A34A)
                                                    : const Color(0xFF2563EB),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (isAdmin) ...[
                                          const SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            onPressed: () =>
                                                _showAttendanceCsvDialog(context, commProv, ev),
                                            icon: const Icon(
                                              Icons.download_rounded,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'Điểm danh (Excel)',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Modal Soạn Thông Báo Phát Sóng Mới (giống /ThongBao/Index trên Web)
  void _showBroadcastModal(BuildContext context, CommunityProvider commProv) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedScope = 'Toàn hệ sinh thái';
    String selectedPriority = 'Quan trọng';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Soạn Thông Báo Phát Sóng Mới',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Gửi thông báo đẩy tức thì qua Firebase FCM tới điện thoại cư dân',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề thông báo *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedScope,
                      decoration: const InputDecoration(
                        labelText: 'Phạm vi gửi',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Toàn hệ sinh thái',
                          child: Text('Toàn hệ sinh thái', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: 'Tòa nhà A',
                          child: Text('Tòa nhà A', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: 'Tòa nhà B',
                          child: Text('Tòa nhà B', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setModalState(() => selectedScope = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Mức độ ưu tiên',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Quan trọng',
                          child: Text('Quan trọng', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: 'Tài chính',
                          child: Text('Tài chính', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: 'Thông thường',
                          child: Text('Thông thường', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setModalState(() => selectedPriority = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Nội dung chi tiết thông báo *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) {
                    return;
                  }
                  commProv.broadcastAnnouncement(
                    title: titleCtrl.text,
                    content: contentCtrl.text,
                    scope: selectedScope,
                    isImportant: selectedPriority == 'Quan trọng',
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã phát sóng thông báo qua Firebase FCM thành công!'),
                      backgroundColor: Color(0xFF16A34A),
                    ),
                  );
                },
                icon: const Icon(Icons.campaign_rounded),
                label: const Text('Phát Sóng Thông Báo Ngay'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateEventModal(BuildContext context, CommunityProvider commProv) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locCtrl = TextEditingController(text: 'Sảnh Co-Living Tầng Thượng - Tòa A');
    final maxCtrl = TextEditingController(text: '60');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tạo Sự Kiện Cộng Đồng Nội Khu',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên sự kiện *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: locCtrl,
              decoration: const InputDecoration(
                labelText: 'Địa điểm tổ chức',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: maxCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số lượng cư dân tối đa',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mô tả sự kiện',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                commProv.createEvent(
                  title: titleCtrl.text,
                  description: descCtrl.text,
                  location: locCtrl.text,
                  startTime: DateTime.now().add(const Duration(days: 3)),
                  maxParticipants: int.tryParse(maxCtrl.text) ?? 60,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã tạo sự kiện cộng đồng mới!'),
                    backgroundColor: Color(0xFF16A34A),
                  ),
                );
              },
              icon: const Icon(Icons.event_available_rounded),
              label: const Text('Đăng Sự Kiện'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttendanceCsvDialog(
    BuildContext context,
    CommunityProvider commProv,
    EventModel ev,
  ) {
    final csv = commProv.exportEventAttendanceCsv(ev);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Danh Sách Điểm Danh - ${ev.title}', style: const TextStyle(fontSize: 15)),
        content: SizedBox(
          width: 480,
          child: SelectableText(
            csv,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csv));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã sao chép danh sách điểm danh (CSV/Excel)!'),
                  backgroundColor: Color(0xFF2563EB),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Sao chép CSV'),
          ),
        ],
      ),
    );
  }
}
