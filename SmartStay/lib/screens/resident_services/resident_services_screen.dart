import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../providers/admin_provider.dart';
import '../../services/system_config.dart';
import '../../services/tiered_utility_service.dart';
import '../../utils/formatters.dart';
import '../../utils/provider_scope.dart';

class ResidentServicesScreen extends StatefulWidget {
  final int initialTab;

  const ResidentServicesScreen({super.key, this.initialTab = 0});

  @override
  State<ResidentServicesScreen> createState() => _ResidentServicesScreenState();
}

class _ResidentServicesScreenState extends State<ResidentServicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _guestNameController = TextEditingController();
  final _guestPhoneController = TextEditingController();
  final _splitTotalController = TextEditingController(text: '4159000');
  final _memberCountController = TextEditingController(text: '3');
  final _meterOldController = TextEditingController(text: '1420');
  final _meterNewController = TextEditingController(text: '1540');
  final _listingTitleController = TextEditingController();
  final _listingPriceController = TextEditingController(text: '50000');
  final _listingDescriptionController = TextEditingController();

  String _splitMethod = 'equal'; // equal, days, custom

  final List<_RoommateShare> _roommates = [
    _RoommateShare(
      name: 'Hồ Ngọc Bảo',
      roleBadge: 'Trưởng phòng',
      mssv: '2380600133',
      code: 'BAO1',
      isPaid: true,
    ),
    _RoommateShare(
      name: 'Nguyễn Dương Bảo',
      roleBadge: 'Thành viên 2',
      mssv: '2380600154',
      code: 'BAO2',
      isPaid: true,
    ),
    _RoommateShare(
      name: 'Trần Hoàng Gia Bảo',
      roleBadge: 'Thành viên 3',
      mssv: '2380600178',
      code: 'BAO3',
      isPaid: false,
    ),
  ];

  final List<_GuestPass> _passes = [
    const _GuestPass(
      'Lê Minh Tuấn (Bạn ĐH)',
      '0919888777',
      'Còn 1 giờ 45 phút',
      '8821',
    ),
    const _GuestPass(
      'Shipper Giao Hàng',
      '0908111222',
      'Vé 1 lần (Single-use)',
      '4902',
    ),
  ];

  final List<_MarketListing> _listings = [
    const _MarketListing(
      'Quạt đứng Senko 3 tốc độ gió có hẹn giờ',
      'Điện gia dụng',
      120000,
      350000,
      'P.305',
      'Hồ Ngọc Bảo (P.305)',
      'Còn rất mới 95%',
      'Dùng được 4 tháng, chạy êm ru, có remote điều khiển. Pass lại do phòng đã có máy lạnh.',
      'https://images.unsplash.com/photo-1585338107529-13afc5f02586?auto=format&fit=crop&w=600&q=80',
    ),
    const _MarketListing(
      'Combo 5 cuốn giáo trình Cấu trúc dữ liệu & Giải thuật',
      'Tặng miễn phí',
      0,
      0,
      'P.201',
      'Nguyễn Dương Bảo (P.201)',
      'TẶNG MIỄN PHÍ 0Đ',
      'Mình đã học xong môn, tặng lại cho các bạn khóa dưới cần ôn thi cuối kỳ.',
      'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?auto=format&fit=crop&w=600&q=80',
    ),
    const _MarketListing(
      'Ấm đun nước siêu tốc Sunhouse Inox 1.8L',
      'Điện gia dụng',
      70000,
      180000,
      'P.401',
      'Trần Hoàng Gia Bảo (P.401)',
      'Inox 304',
      'Đun sôi siêu nhanh trong 3 phút, tự ngắt điện an toàn khi sôi, còn nguyên hộp.',
      'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=600&q=80',
    ),
  ];

  String _guestDuration = '2 giờ';
  String _marketFilter = 'Tất cả';
  String _listingCategory = 'Điện gia dụng';

  // State cho AI Camera OCR (/CuDan/AiOcr)
  String _meterType = 'Điện';
  String _ocrConfidence = '99.4% (Rất cao)';
  String _ocrPreviewUrl =
      'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?auto=format&fit=crop&w=600&q=80';
  bool _isScanningOcr = false;
  bool _showRoiOverlay = false;
  int? _savedMeterConsumption;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
  }

  @override
  void didUpdateWidget(covariant ResidentServicesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = widget.initialTab.clamp(0, 3);
    if (_tabController.index != target) {
      _tabController.animateTo(target);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    _splitTotalController.dispose();
    _memberCountController.dispose();
    _meterOldController.dispose();
    _meterNewController.dispose();
    _listingTitleController.dispose();
    _listingPriceController.dispose();
    _listingDescriptionController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Hệ Sinh Thái Tiện Ích Đột Phá Cư Dân - SmartStay',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF4F46E5),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF4F46E5),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.pie_chart_rounded, size: 18), text: 'Chia Tiền Phòng Ở Ghép'),
            Tab(icon: Icon(Icons.qr_code_2_rounded, size: 18), text: 'Vé Khách Vãng Lai (IoT)'),
            Tab(icon: Icon(Icons.camera_alt_rounded, size: 18), text: 'AI Quét Công Tơ Điện Nước'),
            Tab(icon: Icon(Icons.recycling_rounded, size: 18), text: 'Chợ Đồ Cũ Sinh Viên'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSplitBill(),
          _buildGuestPasses(),
          _buildMeterReader(),
          _buildMarketplace(),
        ],
      ),
    );
  }

  Widget _page(List<Widget> children) => ListView(
        padding: const EdgeInsets.all(18),
        children: children,
      );

  // ===========================================================================
  // TAB 1: CHIA TIỀN PHÒNG Ở GHÉP & ĐA MÃ VIETQR (/CuDan/ChiaTien)
  // ===========================================================================
  Widget _buildSplitBill() {
    final total = double.tryParse(_splitTotalController.text) ?? 4159000;
    final members = _roommates.length;
    final perPerson = (total / members).floor();
    final remainder = total.round() - perPerson * members;

    final paidCount = _roommates.where((m) => m.isPaid).length;
    final progress = _roommates.isEmpty ? 0.0 : paidCount / _roommates.length;
    final collectedAmount = paidCount == members
        ? total
        : paidCount * perPerson.toDouble();
    final remainingAmount = (total - collectedAmount).clamp(0.0, total);

    return _page([
      // Header Card giống /CuDan/ChiaTien
      Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildPillBadge('ĐỘT PHÁ UX', const Color(0xFF4F46E5), Colors.white),
                _buildPillBadge('Co-Living Split-Bill', const Color(0xFFECFDF5), const Color(0xFF059669), borderColor: const Color(0xFFA7F3D0)),
              ],
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.pie_chart_rounded, color: Color(0xFF4F46E5), size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chia Tiền Phòng Ở Ghép & Đa Mã VietQR Riêng Từng Thành Viên',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Tự động bóc tách hóa đơn tổng phòng P.305, sinh mã QR VietQR riêng cho từng bạn cùng phòng kèm thanh tiến độ thanh toán thời gian thực',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Tính lại tiền', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    setState(() {});
                    _showMessage('Đã tính toán lại công thức chia tiền điện nước và tiền phòng theo quy chế Co-Living 2026.');
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.notifications_active_rounded, size: 16, color: Colors.white),
                  label: const Text('Nhắc nhở cả phòng nộp tiền', style: TextStyle(fontSize: 12, color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                  onPressed: () {
                    _showMessage('Đã gửi thông báo nhắc nợ Push Notification và Email kèm link VietQR cá nhân tới các thành viên chưa nộp!');
                  },
                ),
              ],
            ),
          ],
        ),
      ),

      // Thống kê tổng hóa đơn phòng + Thiết lập cách chia
      Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 16),
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
                    'HÓA ĐƠN THÁNG 10/2026 - PHÒNG P.305 (3 THÀNH VIÊN Ở GHÉP)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                  ),
                ),
                _buildPillBadge('HĐ-2026-10-305', const Color(0xFFEEF2FF), const Color(0xFF4F46E5)),
              ],
            ),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.3,
              children: [
                _buildMiniFeeBox('Tiền phòng cố định', '3.500.000 đ', const Color(0xFF0F172A)),
                _buildMiniFeeBox('Điện (120 kWh)', '254.000 đ', const Color(0xFF2563EB)),
                _buildMiniFeeBox('Nước (8 m³)', '105.000 đ', const Color(0xFF0284C7)),
                _buildMiniFeeBox('Dịch vụ chung', '300.000 đ', const Color(0xFF475569)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TIẾN ĐỘ HOÀN TẤT HÓA ĐƠN PHÒNG P.305:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      Text(
                        '$paidCount / $members Bạn đã thanh toán (${(progress * 100).toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: paidCount == members ? const Color(0xFF16A34A) : const Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text('Đã thu: ${AppFormatters.currency(collectedAmount)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                      Text('Tổng hóa đơn: ${AppFormatters.currency(total)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                      Text('Còn thiếu: ${AppFormatters.currency(remainingAmount)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _splitMethod,
                    decoration: const InputDecoration(
                      labelText: 'Phương thức phân bổ tiền',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'equal', child: Text('Chia đều 3 người (Mỗi bạn 1/3)')),
                      DropdownMenuItem(value: 'days', child: Text('Chia theo số ngày ở thực tế')),
                      DropdownMenuItem(value: 'custom', child: Text('Tùy chỉnh tỷ lệ cá nhân')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _splitMethod = v);
                      if (v == 'days') {
                        _showMessage('Đã chuyển sang chế độ tính theo số ngày ở thực tế: Bảo 1 (30 ngày), Bảo 2 (30 ngày), Bảo 3 (28 ngày).');
                      } else {
                        _showMessage('Đã chuyển sang chế độ chia đều 3 thành viên trong phòng.');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Column(
                    children: [
                      const Text('Mỗi bạn đóng:', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      Text(
                        AppFormatters.currency(perPerson.toDouble()),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // Danh sách 3 thành viên & 3 Mã VietQR Động Riêng Biệt (hiển thị trực tiếp giống /CuDan/ChiaTien)
      LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 760;
          final cards = _roommates.asMap().entries.map((entry) {
            final idx = entry.key;
            final m = entry.value;
            final shareAmount = idx == _roommates.length - 1 ? perPerson + remainder : perPerson;
            final qrUrl = SystemConfig().vietQrUrl(
              amount: shareAmount.toDouble(),
              content: 'HD1026 P305 ${m.code}',
            );

            return Container(
              width: isWide ? (constraints.maxWidth - 24) / 3 : double.infinity,
              margin: EdgeInsets.only(bottom: isWide ? 0 : 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: m.isPaid ? Colors.white : const Color(0xFFFFFDF5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: m.isPaid ? const Color(0xFFBBF7D0) : const Color(0xFFF59E0B),
                  width: m.isPaid ? 1 : 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPillBadge(
                            m.roleBadge,
                            idx == 0 ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
                            idx == 0 ? Colors.white : const Color(0xFF475569),
                          ),
                          const SizedBox(height: 4),
                          Text(m.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          Text('MSSV: ${m.mssv}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                      _buildPillBadge(
                        m.isPaid ? '✓ Đã nộp' : '⏳ Chưa nộp',
                        m.isPaid ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
                        m.isPaid ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Text('Số tiền cần đóng:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        Text(
                          AppFormatters.currency(shareAmount.toDouble()),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: m.isPaid ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          ),
                        ),
                        Text('Cú pháp: HD1026 P305 ${m.code}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Image.network(
                          qrUrl,
                          height: 155,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const SizedBox(
                            height: 155,
                            child: Center(child: Icon(Icons.qr_code_2_rounded, size: 110)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          m.isPaid ? '🛡️ VietQR NAPAS 247 chính chủ' : '📲 Quét mã này để nộp phần của mình',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: m.isPaid ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: m.isPaid
                        ? OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF16A34A)),
                            label: const Text('Đã Đối Soát Chuyển Khoản', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A))),
                          )
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                            icon: const Icon(Icons.check_circle_outline, size: 15, color: Colors.white),
                            label: const Text('Giả Lập Quét VietQR Thanh Toán Ngay', style: TextStyle(fontSize: 11, color: Colors.white)),
                            onPressed: () {
                              setState(() => m.isPaid = true);
                              _showMessage('Ngân hàng báo có: ${m.name} đã chuyển khoản ${AppFormatters.currency(shareAmount.toDouble())} qua VietQR Napas 247! Hóa đơn phòng P.305 đã hoàn tất 100%.');
                            },
                          ),
                  ),
                ],
              ),
            );
          }).toList();

          return isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: cards,
                )
              : Column(children: cards);
        },
      ),
    ]);
  }

  // ===========================================================================
  // TAB 2: VÉ KHÁCH VÃNG LAI & KHÓA THÔNG MINH IOT (/CuDan/GuestPass)
  // ===========================================================================
  Widget _buildGuestPasses() {
    final admin = context.watch<AdminProvider>();

    return _page([
      Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildPillBadge('DIGITAL KEYLESS', const Color(0xFF16A34A), Colors.white),
                      _buildPillBadge('Smart IoT Pass', const Color(0xFFEEF2FF), const Color(0xFF4F46E5)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cấp Mã Khách Vãng Lai & Vé Điện Tử Tạm Thời (Digital Guest Pass)',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cư dân P.305 tự tạo mã QR hoặc mã PIN tạm thời có giới hạn giờ cho bạn bè/người thân đến thăm. Hệ thống tự động ghi nhật ký ra vào bảo đảm an ninh.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('Tạo Vé Khách Mới', style: TextStyle(fontSize: 12, color: Colors.white)),
              onPressed: _showCreateGuestPassDialog,
            ),
          ],
        ),
      ),

      // Khóa Cửa Căn Hộ P.305 + Danh sách vé khách
      Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 16),
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
                Icon(Icons.door_front_door_rounded, color: Color(0xFF4F46E5)),
                SizedBox(width: 8),
                Text('Khóa Cửa Căn Hộ P.305', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.lock_rounded, size: 42, color: Color(0xFF16A34A)),
                  const SizedBox(height: 6),
                  const Text('LOCK-A-305 (Trạng Thái: Đang Khóa)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Text('Mức pin: 92% (Tốt) • WiFi: Mạnh', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  _buildPillBadge('Mã PIN Thường Trực: 305888', const Color(0xFFECFDF5), const Color(0xFF059669)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.lock_open_rounded, color: Color(0xFF16A34A)),
                label: const Text('Mở Cửa Ngay Từ Xa (Remote Unlock)', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF16A34A))),
                onPressed: admin.isLoading
                    ? null
                    : () async {
                        await admin.remoteUnlockRoom('P.305');
                        if (mounted) {
                          _showMessage('Đã gửi lệnh mở khóa qua giao thức MQTT tới khóa phòng P.305! Cửa đã được mở thành công.');
                        }
                      },
              ),
            ),
          ],
        ),
      ),

      // Danh sách vé khách đang có hiệu lực
      Container(
        padding: const EdgeInsets.all(18),
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
                Text(
                  '🎫 Mã Khách Vãng Lai Đang Có Hiệu Lực (${_passes.length} Vé)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Text('Tự động hủy khi hết hạn', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
            const SizedBox(height: 14),
            ..._passes.map((pass) {
              final qrImg = 'https://api.qrserver.com/v1/create-qr-code/?size=140x140&data=SMARTSTAY_GUEST_PASS_P305_${pass.pin}';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPillBadge(pass.duration, const Color(0xFF16A34A), Colors.white),
                            const SizedBox(height: 4),
                            Text(pass.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.cancel_outlined, size: 14, color: Color(0xFFDC2626)),
                          label: const Text('Hủy vé', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626))),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFFECACA))),
                          onPressed: () {
                            setState(() => _passes.remove(pass));
                            _showMessage('Đã hủy vé của [${pass.name}] thành công! Cổng sảnh sẽ từ chối mã này.');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Mã PIN cửa sảnh: #${pass.pin}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Image.network(
                              qrImg,
                              width: 110,
                              height: 110,
                              errorBuilder: (_, _, _) => const Icon(Icons.qr_code_2_rounded, size: 90),
                            ),
                            const SizedBox(height: 4),
                            const Text('Quét tại đầu đọc RFID sảnh A', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share_rounded, size: 14),
                        label: const Text('Gửi link mã qua Zalo / SMS', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: 'https://smartstay.vn/pass?room=P305&pin=${pass.pin}'),
                          );
                          _showMessage('Đã sao chép link chia sẻ vé khách cho [${pass.name}]!');
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ]);
  }

  void _showCreateGuestPassDialog() {
    _guestNameController.clear();
    _guestPhoneController.clear();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Tạo Mã Vé Khách Ghé Thăm Mới', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _guestNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên khách ghé thăm hoặc đơn vị',
                  hintText: 'Ví dụ: Nguyễn Văn Cường (Bạn thân)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _guestPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Số điện thoại khách'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _guestDuration,
                decoration: const InputDecoration(labelText: 'Thời hạn hiệu lực của vé'),
                items: const [
                  DropdownMenuItem(value: '2 giờ', child: Text('2 giờ (Bạn bè ghé chơi)')),
                  DropdownMenuItem(value: '1 lần duy nhất', child: Text('1 lần duy nhất (Shipper)')),
                  DropdownMenuItem(value: 'Trong ngày (Hết 23:59)', child: Text('Trong ngày (Hết 23:59)')),
                  DropdownMenuItem(value: '3 ngày cuối tuần', child: Text('3 ngày cuối tuần')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => _guestDuration = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Hủy')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
              icon: const Icon(Icons.qr_code_rounded, size: 16, color: Colors.white),
              label: const Text('Tạo Vé & Sinh Mã QR', style: TextStyle(color: Colors.white)),
              onPressed: () {
                final name = _guestNameController.text.trim().isEmpty
                    ? 'Khách ghé thăm P.305'
                    : _guestNameController.text.trim();
                final pin = (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();
                setState(() {
                  _passes.insert(0, _GuestPass(name, _guestPhoneController.text.trim(), _guestDuration, pin));
                });
                Navigator.pop(dialogCtx);
                _showMessage('Đã tạo thành công vé khách cho [$name] với mã PIN #$pin!');
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 3: AI CAMERA QUÉT CÔNG TƠ ĐIỆN NƯỚC TỰ ĐỘNG (/CuDan/AiOcr)
  // Giao diện giống hệt 100% ảnh chụp màn hình Web của người dùng!
  // ===========================================================================
  Widget _buildMeterReader() {
    final oldIndex = double.tryParse(_meterOldController.text) ?? 1420;
    final newIndex = double.tryParse(_meterNewController.text) ?? 1540;
    final consumption = newIndex >= oldIndex ? newIndex - oldIndex : 0.0;
    final averageConsumption = _meterType == 'Điện' ? 115.0 : 7.5;
    final unit = _meterType == 'Điện' ? 'kWh' : 'm³';
    final anomaly = consumption > averageConsumption * 1.3;

    final calcResult = _meterType == 'Điện'
        ? TieredUtilityService.calculateElectricity(consumption)
        : TieredUtilityService.calculateWater(consumption);

    void selectSample(String type) {
      setState(() {
        _meterType = type;
        _showRoiOverlay = false;
        if (type == 'Điện') {
          _ocrPreviewUrl =
              'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?auto=format&fit=crop&w=600&q=80';
          _meterOldController.text = '1420';
          _meterNewController.text = '1540';
          _ocrConfidence = '99.4% (Rất cao)';
        } else {
          _ocrPreviewUrl =
              'https://images.unsplash.com/photo-1585338107529-13afc5f02586?auto=format&fit=crop&w=600&q=80';
          _meterOldController.text = '84';
          _meterNewController.text = '92';
          _ocrConfidence = '98.9% (Rất cao)';
        }
      });
      _showMessage(
        'Đã tải ảnh mẫu ${type == 'Điện' ? 'công tơ điện' : 'đồng hồ nước'} vào khung quét AI.',
      );
    }

    return _page([
      // 1. Header Card giống hệt /CuDan/AiOcr
      Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildPillBadge('AI COMPUTER VISION', const Color(0xFFDC2626), Colors.white),
                _buildPillBadge(
                  'Gemini Vision OCR',
                  const Color(0xFFEFF6FF),
                  const Color(0xFF2563EB),
                  borderColor: const Color(0xFFBFDBFE),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.camera_alt_rounded, color: Color(0xFFDC2626), size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Camera Quét Chỉ Số Công Tơ Điện & Nước Tự Động',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Chụp ảnh đồng hồ công tơ thực tế bằng camera điện thoại, AI tự động phát hiện viền màn hình, bóc tách chỉ số kWh / m³ và đối chiếu gian lận',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF2563EB)),
                  label: const Text(
                    'Ảnh mẫu Công Tơ Điện',
                    style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => selectSample('Điện'),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.water_drop_outlined, size: 16, color: Color(0xFF0284C7)),
                  label: const Text(
                    'Ảnh mẫu Đồng Hồ Nước',
                    style: TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0284C7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => selectSample('Nước'),
                ),
              ],
            ),
          ],
        ),
      ),

      // 2. Hai Cột (Khu Vực Quét Ảnh Camera + Kết Quả Phân Tích & Đối Soát Tự Động) giống hệt ảnh Web
      LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 720;

          final leftCameraCard = Container(
            padding: const EdgeInsets.all(18),
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
                    Icon(Icons.image_rounded, color: Color(0xFF2563EB), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Khu Vực Quét Ảnh Camera',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _ocrPreviewUrl,
                              height: 210,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                height: 210,
                                color: const Color(0xFF0F172A),
                                child: const Center(
                                  child: Icon(Icons.electric_meter_rounded, size: 72, color: Colors.white70),
                                ),
                              ),
                            ),
                          ),
                          if (_showRoiOverlay)
                            Container(
                              width: 220,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFEF4444), width: 2.5),
                                borderRadius: BorderRadius.circular(12),
                                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                              ),
                              alignment: Alignment.topLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(9),
                                    bottomRight: Radius.circular(9),
                                  ),
                                ),
                                child: const Text(
                                  'VÙNG NHẬN DIỆN AI (ROI)',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.camera_alt_outlined, size: 16),
                        label: const Text(
                          'Chụp ảnh bằng Camera / Chọn file',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          selectSample(_meterType);
                          _showMessage('Đã tải ảnh chụp công tơ từ thiết bị thành công! Bấm "KÍCH HOẠT QUÉT AI OCR" để nhận diện.');
                        },
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: _isScanningOcr
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.memory_rounded, size: 16),
                        label: Text(
                          _isScanningOcr ? 'AI ĐANG BÓC TÁCH CHỮ SỐ...' : 'KÍCH HOẠT QUÉT AI OCR',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isScanningOcr
                            ? null
                            : () async {
                                setState(() {
                                  _isScanningOcr = true;
                                  _showRoiOverlay = true;
                                });
                                await Future.delayed(const Duration(milliseconds: 800));
                                if (!mounted) return;
                                setState(() {
                                  _isScanningOcr = false;
                                  if (_meterType == 'Điện') {
                                    _meterOldController.text = '1420';
                                    _meterNewController.text = '1540';
                                    _ocrConfidence = '99.7% (Cực chính xác)';
                                  } else {
                                    _meterOldController.text = '84';
                                    _meterNewController.text = '92';
                                    _ocrConfidence = '98.9% (Cực chính xác)';
                                  }
                                });
                                _showMessage('AI OCR hoàn tất nhận diện! Các con số đã được đọc tự động với độ tin cậy > 98%.');
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          final rightResultCard = Container(
            padding: const EdgeInsets.all(18),
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
                    Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF16A34A), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Kết Quả Phân Tích & Đối Soát Tự Động',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('LOẠI THIẾT BỊ:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          _buildPillBadge(
                            _meterType == 'Điện' ? 'Công Tơ Điện Tử 1 Pha' : 'Đồng Hồ Đo Nước Sinh Hoạt',
                            const Color(0xFF2563EB),
                            Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ĐỘ TIN CẬY AI (CONFIDENCE):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          _buildPillBadge(_ocrConfidence, const Color(0xFFECFDF5), const Color(0xFF059669)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('CHỈ SỐ CŨ THÁNG 09:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          Text(
                            '${Formatters.formatNumber(oldIndex.round())} $unit',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('CHỈ SỐ AI BÓC TÁCH ĐƯỢC:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                          Text(
                            '${Formatters.formatNumber(newIndex.round())} $unit',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('LƯỢNG TIÊU THỤ THÁNG 10:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          Text(
                            '${consumption.toStringAsFixed(0)} $unit (${AppFormatters.currency(calcResult.totalAmount)})',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Cho phép chỉnh tay chỉ số nếu cần kiểm thử Anomaly
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _meterOldController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Chỉ số cũ ($unit)',
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _meterNewController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Chỉ số AI đọc ($unit)',
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Cảnh báo Anomaly Detection giống hệt ảnh Web
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: anomaly ? const Color(0xFFFEF2F2) : const Color(0xFFD1FAE5).withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        anomaly ? Icons.warning_amber_rounded : Icons.verified_user_outlined,
                        color: anomaly ? const Color(0xFFDC2626) : const Color(0xFF047857),
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              anomaly
                                  ? 'Cảnh báo tiêu thụ tăng đột biến!'
                                  : 'Không phát hiện gian lận hoặc bất thường!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: anomaly ? const Color(0xFFDC2626) : const Color(0xFF065F46),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              anomaly
                                  ? 'Chỉ số tăng cao hơn 30% so với trung bình 3 tháng (${averageConsumption.toStringAsFixed(0)} $unit). Đề nghị kiểm tra rò rỉ thiết bị!'
                                  : 'Chỉ số tăng đều so với mức tiêu thụ trung bình 3 tháng gần nhất (${averageConsumption.toStringAsFixed(0)} $unit). Không có dấu hiệu can thiệp đồng hồ hoặc rò rỉ bất thường.',
                              style: TextStyle(
                                fontSize: 11,
                                color: anomaly ? const Color(0xFF991B1B) : const Color(0xFF065F46),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Nút xác nhận & lưu chỉ số màu xanh lá giống hệt ảnh Web
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.storage_rounded, size: 18),
                    label: const Text(
                      'XÁC NHẬN & LƯU CHỈ SỐ VÀO HỆ THỐNG PHÒNG P.305',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: () {
                      final admin = context.read<AdminProvider>();
                      if (_meterType == 'Điện') {
                        admin.recordMeters(305, newIndex.round(), 92);
                      } else {
                        admin.recordMeters(305, 1540, newIndex.round());
                      }
                      setState(() => _savedMeterConsumption = consumption.round());
                      _showMessage(
                        'Đã lưu chỉ số được đọc bởi AI (${newIndex.round()} $unit) vào Cơ Sở Dữ Liệu Supabase Cloud! Hệ thống đã tính toán hóa đơn phòng P.305 tháng 10.',
                      );
                    },
                  ),
                ),
                if (_savedMeterConsumption != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '✓ Đã đồng bộ lên Supabase: $_savedMeterConsumption $unit (${AppFormatters.currency(calcResult.totalAmount)})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                    ),
                  ),
              ],
            ),
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: leftCameraCard),
                const SizedBox(width: 16),
                Expanded(child: rightResultCard),
              ],
            );
          }
          return Column(
            children: [
              leftCameraCard,
              const SizedBox(height: 16),
              rightResultCard,
            ],
          );
        },
      ),
    ]);
  }

  // ===========================================================================
  // TAB 4: CHỢ TRAO ĐỔI ĐỒ CŨ SINH VIÊN (/CuDan/ChoDoCu)
  // ===========================================================================
  Widget _buildMarketplace() {
    final visible = _listings
        .where((item) => _marketFilter == 'Tất cả' || item.category == _marketFilter)
        .toList();

    return _page([
      Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildPillBadge('ECO-COMMUNITY', const Color(0xFF16A34A), Colors.white),
                      _buildPillBadge('Nội Khu Co-Living', const Color(0xFFEEF2FF), const Color(0xFF4F46E5)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sàn Trao Đổi Đồ Dùng & Đồ Cũ Sinh Viên (Eco-Marketplace)',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Nơi cư dân các phòng pass lại đồ gia dụng, bàn học, quạt, giáo trình còn mới với giá rẻ hoặc tặng miễn phí (0đ). 100% người bán là cư dân đã xác minh.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
              icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
              label: const Text('Đăng Bán / Tặng Đồ Cũ', style: TextStyle(fontSize: 12, color: Colors.white)),
              onPressed: _showCreateListing,
            ),
          ],
        ),
      ),

      // Bộ lọc danh mục
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildFilterChip('Tất cả', 'Tất cả (${_listings.length} món)'),
          _buildFilterChip('Tặng miễn phí', '🎁 Tặng miễn phí (0đ)'),
          _buildFilterChip('Điện gia dụng', 'Thiết bị điện gia dụng'),
          _buildFilterChip('Bàn ghế & sách', 'Bàn ghế & Giáo trình'),
        ],
      ),
      const SizedBox(height: 16),

      if (visible.isEmpty) _emptyState('Chưa có món đồ trong danh mục này.'),
      ...visible.map((item) {
        final isFree = item.price == 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFree ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
              width: isFree ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Image.network(
                    item.imageUrl,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 140,
                      color: const Color(0xFFF1F5F9),
                      child: const Center(child: Icon(Icons.shopping_bag_outlined, size: 48)),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _buildPillBadge(
                      isFree ? 'TẶNG MIỄN PHÍ 0Đ' : 'Phòng ${item.room}',
                      isFree ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                      Colors.white,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _buildPillBadge(
                      isFree ? 'Phòng ${item.room}' : item.conditionBadge,
                      const Color(0xFFECFDF5),
                      const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text(item.description, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isFree ? 'Giá trao đổi:' : 'Giá pass lại:', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            Row(
                              children: [
                                Text(
                                  isFree ? '0 VNĐ (Miễn Phí)' : AppFormatters.currency(item.price.toDouble()),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isFree ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                  ),
                                ),
                                if (!isFree && item.originalPrice > 0) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    AppFormatters.currency(item.originalPrice.toDouble()),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                          icon: Icon(isFree ? Icons.card_giftcard_rounded : Icons.add_shopping_cart_rounded, size: 15, color: Colors.white),
                          label: Text(
                            isFree ? 'Xin Nhận Sách' : 'Nhắn Mua Ngay',
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                          ),
                          onPressed: () {
                            _showMessage(
                              isFree
                                  ? 'Đã gửi yêu cầu xin nhận "${item.title}" tới bạn ${item.sellerName}! Bạn có thể ghé phòng ${item.room} để nhận đồ.'
                                  : 'Đã kết nối chat trực tiếp với người bán ${item.sellerName} để mua "${item.title}" (${AppFormatters.currency(item.price.toDouble())})!',
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    ]);
  }

  Widget _buildFilterChip(String value, String label) {
    final selected = _marketFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFF4F46E5),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        color: selected ? Colors.white : const Color(0xFF475569),
      ),
      onSelected: (_) => setState(() => _marketFilter = value),
    );
  }

  Future<void> _showCreateListing() async {
    _listingTitleController.clear();
    _listingDescriptionController.clear();
    _listingPriceController.text = '50000';
    _listingCategory = 'Điện gia dụng';
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Đăng Đồ Cũ Trao Đổi Nội Khu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _listingTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Tên đồ dùng cần pass',
                    hintText: 'Ví dụ: Bàn học gấp gọn thông minh',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _listingCategory,
                  decoration: const InputDecoration(labelText: 'Danh mục'),
                  items: const [
                    DropdownMenuItem(value: 'Điện gia dụng', child: Text('Đồ điện gia dụng')),
                    DropdownMenuItem(value: 'Bàn ghế & sách', child: Text('Bàn ghế & Giáo trình')),
                    DropdownMenuItem(value: 'Tặng miễn phí', child: Text('Tặng miễn phí (0đ)')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() {
                        _listingCategory = v;
                        if (v == 'Tặng miễn phí') _listingPriceController.text = '0';
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _listingPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Giá thanh lý (VNĐ)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _listingDescriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Mô tả tình trạng món đồ'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Hủy')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
              icon: const Icon(Icons.sell_rounded, size: 15, color: Colors.white),
              label: const Text('Đăng Lên Chợ Cư Dân', style: TextStyle(color: Colors.white)),
              onPressed: () {
                final title = _listingTitleController.text.trim();
                final desc = _listingDescriptionController.text.trim();
                final price = int.tryParse(_listingPriceController.text.replaceAll('.', '')) ?? 0;
                if (title.isEmpty) return;
                setState(() {
                  _listings.insert(
                    0,
                    _MarketListing(
                      title,
                      _listingCategory,
                      price,
                      0,
                      'P.305',
                      'Hồ Ngọc Bảo (P.305)',
                      'Mới đăng',
                      desc.isEmpty ? 'Còn mới tốt, liên hệ nhận tại sảnh tòa nhà.' : desc,
                      'https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?auto=format&fit=crop&w=600&q=80',
                    ),
                  );
                });
                Navigator.pop(dialogCtx);
                _showMessage('Đã đăng món đồ "$title" lên sàn trao đổi nội khu Co-Living thành công!');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillBadge(String text, Color bg, Color fg, {Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildMiniFeeBox(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  Widget _emptyState(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(text, style: const TextStyle(color: Color(0xFF64748B))),
        ),
      );
}

class _RoommateShare {
  final String name;
  final String roleBadge;
  final String mssv;
  final String code;
  bool isPaid;

  _RoommateShare({
    required this.name,
    required this.roleBadge,
    required this.mssv,
    required this.code,
    required this.isPaid,
  });
}

class _GuestPass {
  final String name;
  final String phone;
  final String duration;
  final String pin;
  const _GuestPass(this.name, this.phone, this.duration, this.pin);
}

class _MarketListing {
  final String title;
  final String category;
  final int price;
  final int originalPrice;
  final String room;
  final String sellerName;
  final String conditionBadge;
  final String description;
  final String imageUrl;
  const _MarketListing(
    this.title,
    this.category,
    this.price,
    this.originalPrice,
    this.room,
    this.sellerName,
    this.conditionBadge,
    this.description,
    this.imageUrl,
  );
}
