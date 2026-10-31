import 'package:flutter/material.dart';
import '../../providers/community_provider.dart';
import '../../utils/provider_scope.dart';
import '../../utils/formatters.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final commProv = context.watch<CommunityProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Bảng tin & Sự kiện'),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
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
        body: TabBarView(
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
                        color: a.isImportant ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: a.isImportant
                                    ? const Color(0xFFDC2626).withValues(alpha: 0.12)
                                    : const Color(0xFF2563EB).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                a.scope,
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
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
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
                          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.45),
                        ),
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
                        // Header sự kiện
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_available, color: Colors.white, size: 24),
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
                              Text(ev.description,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(ev.location,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${AppFormatters.dateTime(ev.startTime)} - ${AppFormatters.date(ev.endTime)}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.group_outlined, size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Đã đăng ký: ${ev.currentParticipants}/${ev.maxParticipants} cư dân',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    commProv.toggleEventRegistration(ev.eventId);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(ev.isRegistered
                                            ? 'Đã hủy đăng ký tham gia'
                                            : 'Đã đăng ký tham gia thành công!'),
                                        backgroundColor: ev.isRegistered ? Colors.grey : const Color(0xFF16A34A),
                                      ),
                                    );
                                  },
                                  icon: Icon(ev.isRegistered ? Icons.check_circle : Icons.how_to_reg_outlined),
                                  label: Text(
                                    ev.isRegistered ? 'Đã đăng ký (Chạm để hủy)' : 'Đăng ký tham gia ngay',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ev.isRegistered ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
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
    );
  }
}
