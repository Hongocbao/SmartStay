import 'package:flutter/material.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/community_provider.dart';
import '../../utils/provider_scope.dart';
import '../../utils/formatters.dart';
import 'breakthrough_modal.dart';
import '../invoice/invoice_detail_screen.dart';
import '../ticket/ticket_detail_screen.dart';
import '../ticket/create_ticket_screen.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../resident_services/resident_services_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final invoiceProv = context.watch<InvoiceProvider>();
    final ticketProv = context.watch<TicketProvider>();
    final commProv = context.watch<CommunityProvider>();

    final user = auth.user;
    final profile = user?.residentProfile;
    final unpaidInvoice = invoiceProv.currentUnpaidInvoice;
    final activeTicket = ticketProv.activeTicket;
    final roomCode = profile?.roomCode ?? user?.roomCode ?? 'P.305';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            invoiceProv.loadInvoices();
            ticketProv.loadTickets();
            commProv.loadData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: User Greeting & Room badge
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF2563EB),
                      child: Text(
                        (user?.fullName.isNotEmpty == true)
                            ? user!.fullName.trim().split(' ').last[0]
                            : 'B',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Xin chào, ${user?.fullName ?? "Cư dân"}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.waving_hand, color: Colors.amber, size: 16),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$roomCode - ${profile?.buildingName ?? "Tòa nhà A"}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, size: 26),
                      onPressed: () {
                        onNavigateTab?.call(5); // Mở tab Bảng tin
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4 KPI Thẻ Nhanh Cư Dân (tương đương 4 KPI trên /CuDan/Index Web)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.72,
                  children: [
                    _buildResidentKpiCard(
                      title: 'HÓA ĐƠN THÁNG 10',
                      badge: unpaidInvoice?.status ?? 'Chờ đối soát',
                      badgeColor: const Color(0xFFD97706),
                      value: AppFormatters.currency(unpaidInvoice?.remainingAmount ?? 4159000),
                      subtitle: 'Hạn chót: 05/11/2026',
                      valueColor: const Color(0xFFDC2626),
                      onTap: () => onNavigateTab?.call(1),
                    ),
                    _buildResidentKpiCard(
                      title: 'HỢP ĐỒNG THUÊ',
                      badge: 'Hiệu lực',
                      badgeColor: const Color(0xFF16A34A),
                      value: auth.contract?.contractCode ?? 'HĐ-2026-0305',
                      subtitle: 'Hạn: 31/12/2026 (Cọc: 7tr)',
                      valueColor: const Color(0xFF0F172A),
                      onTap: () => onNavigateTab?.call(6),
                    ),
                    _buildResidentKpiCard(
                      title: 'KHÓA THÔNG MINH IOT',
                      badge: 'Pin 92%',
                      badgeColor: const Color(0xFF2563EB),
                      value: '🔒 Khóa An Toàn',
                      subtitle: 'Mã PIN phòng: 305888',
                      valueColor: const Color(0xFF16A34A),
                      onTap: () => _showResidentSmartLockModal(context, roomCode),
                    ),
                    _buildResidentKpiCard(
                      title: 'SỰ CỐ ĐANG XỬ LÝ',
                      badge: activeTicket != null ? '1 phiếu' : 'Ổn định',
                      badgeColor: const Color(0xFF0284C7),
                      value: activeTicket != null ? 'Máy Lạnh $roomCode' : 'Không có sự cố',
                      subtitle: activeTicket?.technicianName != null
                          ? 'KTV ${activeTicket!.technicianName} đang sửa'
                          : 'Bấm để báo hỏng thiết bị',
                      valueColor: const Color(0xFF0F172A),
                      onTap: () => onNavigateTab?.call(4),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Card Hóa đơn nổi bật
                if (unpaidInvoice != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Hóa đơn tháng ${AppFormatters.monthYear(unpaidInvoice.billingMonth)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Cần thanh toán',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Tổng tiền cần đóng:',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.currency(unpaidInvoice.remainingAmount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 14, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              'Hạn chót: ${AppFormatters.date(unpaidInvoice.dueDate)}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InvoiceDetailScreen(
                                    invoiceId: unpaidInvoice.invoiceId,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                            label: const Text(
                              'Thanh toán VietQR ngay',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1E3A8A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 4 Tiện ích nhanh (Quick Actions)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tiện ích nhanh',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    InkWell(
                      onTap: () => BreakthroughFeaturesModal.show(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.rocket_launch, size: 13, color: Color(0xFF2563EB)),
                            SizedBox(width: 4),
                            Text(
                              'Đột phá 2026',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickAction(
                      context,
                      icon: Icons.build_circle_outlined,
                      color: const Color(0xFFEA580C),
                      label: 'Báo sự cố',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateTicketScreen(),
                          ),
                        );
                      },
                    ),
                    _buildQuickAction(
                      context,
                      icon: Icons.grid_view_rounded,
                      color: const Color(0xFF2563EB),
                      label: 'Tiện ích',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ResidentServicesScreen(),
                          ),
                        );
                      },
                    ),
                    _buildQuickAction(
                      context,
                      icon: Icons.celebration_outlined,
                      color: const Color(0xFF16A34A),
                      label: 'Sự kiện',
                      onTap: () {
                        onNavigateTab?.call(5); // Mở tab Bảng tin & Sự kiện
                      },
                    ),
                    _buildQuickAction(
                      context,
                      icon: Icons.auto_awesome,
                      color: const Color(0xFF9333EA),
                      label: 'AI 24/7',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AiChatScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 5 Chức năng Đột phá Cư dân (hiển thị trực tiếp giống menu bên trái của Web)
                const Text(
                  'Hệ Sinh Thái Tiện Ích Cư Dân Đột Phá',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                _buildBreakthroughShortcutTile(
                  context,
                  icon: Icons.pie_chart_rounded,
                  color: const Color(0xFFF59E0B),
                  title: 'Chia Tiền Phòng Ở Ghép (Co-Living Split)',
                  subtitle: 'Tự động chia tiền phòng, điện nước bậc thang & tạo mã VietQR riêng từng thành viên',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ResidentServicesScreen(initialTab: 0)),
                  ),
                ),
                _buildBreakthroughShortcutTile(
                  context,
                  icon: Icons.camera_enhance_rounded,
                  color: const Color(0xFFEF4444),
                  title: 'AI Quét Công Tơ Điện Nước (AI OCR)',
                  subtitle: 'Chụp ảnh đồng hồ điện nước, AI tự nhận diện chỉ số và tính tiền lũy tiến',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ResidentServicesScreen(initialTab: 2)),
                  ),
                ),
                _buildBreakthroughShortcutTile(
                  context,
                  icon: Icons.qr_code_2_rounded,
                  color: const Color(0xFF10B981),
                  title: 'Vé Khách Vãng Lai (IoT Guest Pass)',
                  subtitle: 'Cấp mã QR & PIN mở khóa thông minh có thời hạn cho bạn bè/người thân đến thăm',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ResidentServicesScreen(initialTab: 1)),
                  ),
                ),
                _buildBreakthroughShortcutTile(
                  context,
                  icon: Icons.recycling_rounded,
                  color: const Color(0xFF0284C7),
                  title: 'Chợ Đồ Cũ Sinh Viên (Green Eco-Market)',
                  subtitle: 'Trao đổi, thanh lý hoặc tặng miễn phí 0đ giáo trình, đồ gia dụng nội khu',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ResidentServicesScreen(initialTab: 3)),
                  ),
                ),
                _buildBreakthroughShortcutTile(
                  context,
                  icon: Icons.smart_toy_rounded,
                  color: const Color(0xFF8B5CF6),
                  title: 'Trợ Lý Ảo AI Tự Hành 24/7 (AI Concierge)',
                  subtitle: 'Giải đáp biểu giá điện nước bậc thang, tra cứu công nợ, nội quy & chẩn đoán sự cố',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AiChatScreen()),
                  ),
                ),
                const SizedBox(height: 24),

                // Card Theo dõi tiến độ sự cố đang xử lý
                if (activeTicket != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tiến độ xử lý sự cố',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      TextButton(
                        onPressed: () => onNavigateTab?.call(4),
                        child: const Text('Xem tất cả'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TicketDetailScreen(ticket: activeTicket),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppFormatters.priorityColor(activeTicket.priority)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  activeTicket.priority,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppFormatters.priorityColor(activeTicket.priority),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                activeTicket.ticketCode,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppFormatters.ticketStatusColor(activeTicket.status)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  activeTicket.status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        AppFormatters.ticketStatusColor(activeTicket.status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            activeTicket.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 3-step visual tracker
                          Row(
                            children: [
                              _buildStepIndicator(
                                step: 1,
                                title: 'Chờ xử lý',
                                isPassed: activeTicket.statusStep >= 0,
                                isActive: activeTicket.statusStep == 0,
                              ),
                              _buildStepConnector(isPassed: activeTicket.statusStep >= 1),
                              _buildStepIndicator(
                                step: 2,
                                title: 'Đang sửa',
                                isPassed: activeTicket.statusStep >= 1,
                                isActive: activeTicket.statusStep == 1,
                              ),
                              _buildStepConnector(isPassed: activeTicket.statusStep >= 2),
                              _buildStepIndicator(
                                step: 3,
                                title: 'Hoàn thành',
                                isPassed: activeTicket.statusStep >= 2,
                                isActive: activeTicket.statusStep == 2,
                              ),
                            ],
                          ),
                          if (activeTicket.technicianName != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.person_outline,
                                    size: 15, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text(
                                  'Kỹ thuật: ${activeTicket.technicianName}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Bảng tin thông báo mới nhất
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bảng tin tòa nhà',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    TextButton(
                      onPressed: () => onNavigateTab?.call(5),
                      child: const Text('Xem thêm'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...commProv.announcements.take(2).map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: item.isImportant
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.isImportant
                                ? Icons.campaign_rounded
                                : Icons.info_outline_rounded,
                            color: item.isImportant
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF475569),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                AppFormatters.dateTime(item.createdAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // Hỗ Trợ & Số Khẩn Cấp 24/7 (tương đương khung Hỗ Trợ & Số Khẩn Cấp trên /CuDan/Index Web)
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
                      const Row(
                        children: [
                          Icon(Icons.support_agent_rounded, color: Color(0xFF2563EB), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Hỗ Trợ & Số Khẩn Cấp 24/7',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.phone_in_talk_rounded, color: Color(0xFF2563EB), size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Ban Quản Lý Tòa Nhà', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                        Text('1900 8899 (Nhánh 1)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.security_rounded, color: Color(0xFFDC2626), size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Bảo vệ & Kỹ thuật 24/7', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                        Text('0909 999 888', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                                      ],
                                    ),
                                  ),
                                ],
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
      ),
    );
  }

  Widget _buildResidentKpiCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required String value,
    required String subtitle,
    required Color valueColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor),
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakthroughShortcutTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResidentSmartLockModal(BuildContext context, String roomCode) {
    final admin = context.read<AdminProvider>();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.lock_rounded, color: Color(0xFF16A34A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Khóa Thông Minh IoT - $roomCode',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_rounded, color: Color(0xFF16A34A)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Trạng thái: Đang Khóa An Toàn (Online)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF16A34A))),
                          Text('Mã thiết bị: LOCK-A-305 • Pin: 92% • Mật mã PIN: 305888', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bạn có thể mở khóa cửa từ xa qua WiFi IoT hoặc tạo Vé Khách Vãng Lai (QR/PIN tạm thời) cho bạn bè.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ResidentServicesScreen(initialTab: 2)),
                );
              },
              child: const Text('Cấp Vé Khách QR'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.lock_open_rounded, size: 16, color: Colors.white),
              label: const Text('Mở Khóa Từ Xa Ngay', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
              onPressed: () async {
                Navigator.pop(ctx);
                await admin.remoteUnlockRoom(roomCode);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã gửi lệnh mở khóa cửa từ xa qua WiFi IoT cho phòng $roomCode!'),
                      backgroundColor: const Color(0xFF16A34A),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator({
    required int step,
    required String title,
    required bool isPassed,
    required bool isActive,
  }) {
    final color = isActive
        ? const Color(0xFF2563EB)
        : (isPassed ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1));

    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color,
            child: isPassed && !isActive
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    step.toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector({required bool isPassed}) {
    return Container(
      width: 28,
      height: 2,
      color: isPassed ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
    );
  }
}
