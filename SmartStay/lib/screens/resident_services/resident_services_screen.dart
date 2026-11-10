import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../providers/admin_provider.dart';
import '../../services/supabase_direct_service.dart';
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
  final _waterOldController = TextEditingController(text: '84');
  final _waterNewController = TextEditingController(text: '92');
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

  // State cho AI Camera OCR Tự Kiểm Tra Điện Nước Cá Nhân (/CuDan/AiOcr)
  // 'electric' = Chỉ tính Điện | 'water' = Chỉ tính Nước | 'both' = Tính cả Điện & Nước
  String _ocrMode = 'both';
  String _ocrConfidence = '99.4% (Rất cao)';
  final String _electricPreviewUrl =
      'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?auto=format&fit=crop&w=600&q=80';
  final String _waterPreviewUrl =
      'https://images.unsplash.com/photo-1585338107529-13afc5f02586?auto=format&fit=crop&w=600&q=80';
  bool _isScanningOcr = false;
  bool _showRoiOverlay = true;
  bool _showCalculationDetail = false;
  final int _daysSinceLastPayment = 25; // Từ kỳ thanh toán trước (05/10) đến hôm nay
  Timer? _residentMeterSyncTimer;
  DateTime? _lastLocalMeterEdit;
  final SupabaseDirectService _supabase = SupabaseDirectService();

  final List<_PersonalMeterLog> _personalMeterLogs = [
    const _PersonalMeterLog(
      dateLabel: '20/10/2026 (Kiểm tra giữa tháng)',
      modeLabel: 'Điện + Nước',
      consumptionSummary: '78 kWh điện • 5 m³ nước',
      estimatedCost: 215400,
    ),
    const _PersonalMeterLog(
      dateLabel: '12/10/2026 (Sau 1 tuần lắp máy lạnh)',
      modeLabel: 'Chỉ tính Điện',
      consumptionSummary: '35 kWh điện (chữ điện)',
      estimatedCost: 63000,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
    _pullResidentMeterFromCloud();
    _residentMeterSyncTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _pullResidentMeterFromCloud(),
    );
  }

  Future<void> _pullResidentMeterFromCloud() async {
    if (!mounted) return;
    // Tránh ghi đè khi người dùng vừa gõ phím trong vòng 3 giây
    if (_lastLocalMeterEdit != null &&
        DateTime.now().difference(_lastLocalMeterEdit!).inSeconds < 3) {
      return;
    }
    final snapshot = await _supabase.fetchUnifiedSnapshot();
    if (!mounted || snapshot == null) return;

    bool changed = false;
    final meter = snapshot['chiSoCuDan'];
    if (meter is Map) {
      final mode = (meter['cheDo'] ?? meter['CheDo'] ?? '').toString().trim();
      final elecOld = (meter['dienKyTruoc'] ?? meter['DienKyTruoc'] ?? 1420) as num;
      final elecNew = (meter['dienMoiChup'] ?? meter['DienMoiChup'] ?? 1540) as num;
      final waterOld = (meter['nuocKyTruoc'] ?? meter['NuocKyTruoc'] ?? 84) as num;
      final waterNew = (meter['nuocMoiChup'] ?? meter['NuocMoiChup'] ?? 92) as num;

      if (mode.isNotEmpty && mode != _ocrMode) {
        _ocrMode = mode;
        changed = true;
      }
      if (_meterOldController.text != elecOld.round().toString()) {
        _meterOldController.text = elecOld.round().toString();
        changed = true;
      }
      if (_meterNewController.text != elecNew.round().toString()) {
        _meterNewController.text = elecNew.round().toString();
        changed = true;
      }
      if (_waterOldController.text != waterOld.round().toString()) {
        _waterOldController.text = waterOld.round().toString();
        changed = true;
      }
      if (_waterNewController.text != waterNew.round().toString()) {
        _waterNewController.text = waterNew.round().toString();
        changed = true;
      }
    }

    final cloudLogs = snapshot['soTheoDoiCuDan'];
    if (cloudLogs is List && cloudLogs.isNotEmpty) {
      for (final raw in cloudLogs) {
        if (raw is! Map) continue;
        final timeLabel = (raw['thoiDiem'] ?? raw['ThoiDiem'] ?? '').toString();
        final modeLabel = (raw['cheDo'] ?? raw['CheDo'] ?? '').toString();
        final summary = (raw['tomTatTieuThu'] ?? raw['TomTatTieuThu'] ?? '').toString();
        final cost = (raw['tongTienTamTinh'] ?? raw['TongTienTamTinh'] ?? 0) as num;
        if (summary.isEmpty) continue;
        final exists = _personalMeterLogs.any(
          (l) => l.consumptionSummary == summary && (l.estimatedCost - cost.toDouble()).abs() < 1,
        );
        if (!exists) {
          _personalMeterLogs.insert(
            0,
            _PersonalMeterLog(
              dateLabel: timeLabel.isNotEmpty ? timeLabel : 'Đồng bộ từ thiết bị khác',
              modeLabel: modeLabel.isNotEmpty ? modeLabel : 'Điện + Nước',
              consumptionSummary: summary,
              estimatedCost: cost.toDouble(),
            ),
          );
          changed = true;
        }
      }
    }

    if (changed && mounted) {
      setState(() {});
    }
  }

  void _pushResidentMeterToCloud({
    bool saveToLog = false,
    String? summary,
    String? dateLabel,
    required double totalEstimatedCost,
  }) {
    _lastLocalMeterEdit = DateTime.now();
    _supabase.syncResidentMeterCheck(
      mode: _ocrMode,
      elecOld: double.tryParse(_meterOldController.text) ?? 1420,
      elecNew: double.tryParse(_meterNewController.text) ?? 1540,
      waterOld: double.tryParse(_waterOldController.text) ?? 84,
      waterNew: double.tryParse(_waterNewController.text) ?? 92,
      totalEstimatedCost: totalEstimatedCost,
      consumptionSummary: summary,
      dateLabel: dateLabel,
      saveToPersonalLog: saveToLog,
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
    _residentMeterSyncTimer?.cancel();
    _tabController.dispose();
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    _splitTotalController.dispose();
    _memberCountController.dispose();
    _meterOldController.dispose();
    _meterNewController.dispose();
    _waterOldController.dispose();
    _waterNewController.dispose();
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
  // TAB 3: AI CAMERA TỰ KIỂM TRA & DỰ TOÁN ĐIỆN NƯỚC CÁ NHÂN (/CuDan/AiOcr)
  // Cư dân chụp/tải ảnh công tơ Điện, Nước hoặc Cả Hai -> Tính từ kỳ thanh toán
  // trước đến ảnh mới chụp -> Thông báo số ký điện (kWh) / khối nước (m³) +
  // Xem chi tiết cách tính bậc thang lũy tiến (Riêng tư cho cư dân, KHÔNG gửi Admin)
  // ===========================================================================
  Widget _buildMeterReader() {
    final includeElectric = _ocrMode == 'electric' || _ocrMode == 'both';
    final includeWater = _ocrMode == 'water' || _ocrMode == 'both';

    final elecOld = double.tryParse(_meterOldController.text) ?? 1420;
    final elecNew = double.tryParse(_meterNewController.text) ?? 1540;
    final elecConsumption =
        includeElectric && elecNew >= elecOld ? elecNew - elecOld : 0.0;

    final waterOld = double.tryParse(_waterOldController.text) ?? 84;
    final waterNew = double.tryParse(_waterNewController.text) ?? 92;
    final waterConsumption =
        includeWater && waterNew >= waterOld ? waterNew - waterOld : 0.0;

    final elecResult = TieredUtilityService.calculateElectricity(elecConsumption);
    final waterResult = TieredUtilityService.calculateWater(waterConsumption);

    final totalEstimatedCost =
        (includeElectric ? elecResult.totalAmount : 0.0) +
        (includeWater ? waterResult.totalAmount : 0.0);

    final days = _daysSinceLastPayment.clamp(1, 31);
    final dailyElec = elecConsumption / days;
    final dailyWater = waterConsumption / days;
    final projected30DayElec = dailyElec * 30;
    final projected30DayWater = dailyWater * 30;
    final projected30DayCost =
        (includeElectric
            ? TieredUtilityService.calculateElectricity(projected30DayElec)
                .totalAmount
            : 0.0) +
        (includeWater
            ? TieredUtilityService.calculateWater(projected30DayWater)
                .totalAmount
            : 0.0);
    final perMemberCost = totalEstimatedCost / 3; // Phòng P.305 có 3 thành viên

    final elecAnomaly = includeElectric && elecConsumption > 115.0 * 1.3;
    final waterAnomaly = includeWater && waterConsumption > 7.5 * 1.3;
    final hasAnomaly = elecAnomaly || waterAnomaly;

    void selectMode(String mode) {
      setState(() {
        _ocrMode = mode;
        _showRoiOverlay = true;
        if (mode == 'electric') {
          _ocrConfidence = '99.6% (Đã nhận diện ảnh Điện)';
        } else if (mode == 'water') {
          _ocrConfidence = '99.1% (Đã nhận diện ảnh Nước)';
        } else {
          _ocrConfidence = '99.5% (Đã nhận diện cả Điện & Nước)';
        }
      });
      _pushResidentMeterToCloud(totalEstimatedCost: totalEstimatedCost);
      final modeText = mode == 'electric'
          ? 'Chỉ tính tiền Điện'
          : mode == 'water'
              ? 'Chỉ tính tiền Nước'
              : 'Tính gộp cả Điện & Nước';
      _showMessage(
        'Đã chuyển sang chế độ [$modeText]. Hệ thống tự động tính từ kỳ thanh toán trước (05/10) đến chỉ số ảnh mới chụp!',
      );
    }

    void triggerAiScanSimulation() async {
      setState(() {
        _isScanningOcr = true;
        _showRoiOverlay = true;
      });
      await Future.delayed(const Duration(milliseconds: 750));
      if (!mounted) return;
      setState(() {
        _isScanningOcr = false;
        if (includeElectric && _meterNewController.text.trim().isEmpty) {
          _meterNewController.text = '1540';
        }
        if (includeWater && _waterNewController.text.trim().isEmpty) {
          _waterNewController.text = '92';
        }
        _ocrConfidence = '99.7% (Gemini Vision OCR)';
      });

      _pushResidentMeterToCloud(totalEstimatedCost: totalEstimatedCost);

      final summaryParts = <String>[];
      if (includeElectric) {
        summaryParts.add(
          '${elecConsumption.toStringAsFixed(0)} kWh (ký điện) = ${AppFormatters.currency(elecResult.totalAmount)}',
        );
      }
      if (includeWater) {
        summaryParts.add(
          '${waterConsumption.toStringAsFixed(0)} m³ (khối nước) = ${AppFormatters.currency(waterResult.totalAmount)}',
        );
      }
      _showMessage(
        '🔔 Thông báo tạm tính tháng này: Đã tiêu thụ ${summaryParts.join(' & ')} • Tổng: ${AppFormatters.currency(totalEstimatedCost)} (Chỉ báo trước cho bạn, không gửi Admin).',
      );
    }

    return _page([
      // 1. Header Card + Cam kết Riêng Tư Cư Dân
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
                _buildPillBadge(
                  'TỰ KIỂM TRA & DỰ TOÁN CÁ NHÂN',
                  const Color(0xFFDC2626),
                  Colors.white,
                ),
                _buildPillBadge(
                  'Gemini Vision OCR',
                  const Color(0xFFEFF6FF),
                  const Color(0xFF2563EB),
                  borderColor: const Color(0xFFBFDBFE),
                ),
                _buildPillBadge(
                  '🔒 Riêng tư 100% • KHÔNG gửi về Admin',
                  const Color(0xFFECFDF5),
                  const Color(0xFF047857),
                  borderColor: const Color(0xFFA7F3D0),
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
                    'Chụp / Tải Ảnh Công Tơ — Tự Tính Tiền Điện Nước Tạm Tính Tháng Này',
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
              'Bạn có thể chụp hoặc tải lên ảnh công tơ Điện, đồng hồ Nước hoặc cả hai bất kỳ lúc nào trong tháng. AI sẽ tự động trừ đi chỉ số lần thanh toán trước để báo ngay bạn đã xài hết bao nhiêu ký điện (kWh), bao nhiêu khối nước (m³) và số tiền tương ứng để chủ động chi tiêu.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 14),

            // Bộ chọn 3 chế độ theo ảnh cư dân cung cấp
            const Text(
              'CHỌN LOẠI ẢNH CÔNG TƠ BẠN MUỐN CHỤP / TẢI LÊN ĐỂ TÍNH TIỀN:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _buildModeSelectorButton(
                  mode: 'electric',
                  icon: Icons.bolt_rounded,
                  label: '⚡ Chỉ tính Điện (1 ảnh)',
                  activeColor: const Color(0xFF2563EB),
                  onTap: () => selectMode('electric'),
                ),
                _buildModeSelectorButton(
                  mode: 'water',
                  icon: Icons.water_drop_rounded,
                  label: '💧 Chỉ tính Nước (1 ảnh)',
                  activeColor: const Color(0xFF0284C7),
                  onTap: () => selectMode('water'),
                ),
                _buildModeSelectorButton(
                  mode: 'both',
                  icon: Icons.auto_awesome_motion_rounded,
                  label: '⚡+💧 Tính cả Điện & Nước (2 ảnh)',
                  activeColor: const Color(0xFF7C3AED),
                  onTap: () => selectMode('both'),
                ),
              ],
            ),
          ],
        ),
      ),

      // 2. BANNER THÔNG BÁO KẾT QUẢ TIÊU THỤ THÁNG NÀY CHO NGƯỜI DÙNG BIẾT TRƯỚC
      Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFFFBBF24),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'THÔNG BÁO KẾT QUẢ TẠM TÍNH CHO BẠN (TỪ KỲ THANH TOÁN TRƯỚC 05/10 ĐẾN HÔM NAY)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF93C5FD),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _ocrMode == 'electric'
                            ? 'Tháng này phòng bạn đã dùng ${elecConsumption.toStringAsFixed(0)} ký điện (kWh)'
                            : _ocrMode == 'water'
                                ? 'Tháng này phòng bạn đã dùng ${waterConsumption.toStringAsFixed(0)} khối nước (m³)'
                                : 'Tháng này phòng bạn đã dùng ${elecConsumption.toStringAsFixed(0)} ký điện (kWh) & ${waterConsumption.toStringAsFixed(0)} khối nước (m³)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'TỔNG TIỀN TẠM TÍNH',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFCBD5E1),
                        ),
                      ),
                      Text(
                        AppFormatters.currency(totalEstimatedCost),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                if (includeElectric)
                  _buildNotificationStatChip(
                    icon: Icons.bolt_rounded,
                    iconColor: const Color(0xFFFBBF24),
                    title: 'Tiêu thụ Điện (${elecOld.toInt()} → ${elecNew.toInt()})',
                    value:
                        '${elecConsumption.toStringAsFixed(0)} kWh (ký điện) • ${AppFormatters.currency(elecResult.totalAmount)}',
                  ),
                if (includeWater)
                  _buildNotificationStatChip(
                    icon: Icons.water_drop_rounded,
                    iconColor: const Color(0xFF38BDF8),
                    title: 'Tiêu thụ Nước (${waterOld.toInt()} → ${waterNew.toInt()})',
                    value:
                        '${waterConsumption.toStringAsFixed(0)} m³ (khối nước) • ${AppFormatters.currency(waterResult.totalAmount)}',
                  ),
                _buildNotificationStatChip(
                  icon: Icons.groups_rounded,
                  iconColor: const Color(0xFF4ADE80),
                  title: 'Chia 3 người ở (P.305)',
                  value: '~${AppFormatters.currency(perMemberCost)} / người',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(
                      _showCalculationDetail
                          ? Icons.visibility_off_rounded
                          : Icons.receipt_long_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _showCalculationDetail
                          ? 'ẨN BẢNG CHI TIẾT CÁCH TÍNH TIỀN'
                          : '📊 XEM CHI TIẾT CÁCH TÍNH TIỀN & BẢNG LŨY TIẾN BẬC THANG',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _showCalculationDetail = !_showCalculationDetail;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // 3. BẢNG XEM CHI TIẾT CÁCH TÍNH (HIỂN THỊ KHI CƯ DÂN BẤM "XEM CHI TIẾT CÁCH TÍNH")
      if (_showCalculationDetail)
        Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.calculate_rounded, color: Color(0xFF2563EB), size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Diễn Giải Chi Tiết Cách Tính Tiền Điện / Nước Cho Cư Dân',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildPillBadge(
                    'Đúng biểu giá bậc thang hiện hành',
                    const Color(0xFFEFF6FF),
                    const Color(0xFF1D4ED8),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Công thức gốc: Sản lượng tiêu thụ = [Chỉ số mới trên ảnh vừa chụp/tải lên] − [Chỉ số chốt ở kỳ thanh toán hóa đơn lần trước (05/10/2026)]. Sau đó nhân theo từng bậc thang lũy tiến:',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 14),

              if (includeElectric) ...[
                _buildTierBreakdownSection(
                  title:
                      '⚡ 1. Chi Tiết Cách Tính Tiền Điện (${elecNew.toInt()} − ${elecOld.toInt()} = ${elecConsumption.toStringAsFixed(0)} kWh / ký điện)',
                  unitLabel: 'kWh',
                  result: elecResult,
                  accentColor: const Color(0xFF2563EB),
                ),
                const SizedBox(height: 14),
              ],

              if (includeWater) ...[
                _buildTierBreakdownSection(
                  title:
                      '💧 ${includeElectric ? '2.' : '1.'} Chi Tiết Cách Tính Tiền Nước (${waterNew.toInt()} − ${waterOld.toInt()} = ${waterConsumption.toStringAsFixed(0)} m³ / khối nước)',
                  unitLabel: 'm³',
                  result: waterResult,
                  accentColor: const Color(0xFF0284C7),
                ),
                const SizedBox(height: 14),
              ],

              // Dự báo cuối tháng & Chia đầu người thực tế đời sống
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
                    const Text(
                      '💡 PHÂN TÍCH ĐỜI SỐNG THỰC TẾ & DỰ BÁO ĐẾN CUỐI THÁNG (30 NGÀY):',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Số ngày tính từ lần thanh toán trước (05/10) đến ảnh chụp hôm nay: $days ngày.\n'
                      '${includeElectric ? '• Trung bình mỗi ngày phòng bạn xài: ${dailyElec.toStringAsFixed(1)} kWh/ngày → Dự kiến đủ 30 ngày sẽ hết khoảng ${projected30DayElec.toStringAsFixed(0)} kWh.\n' : ''}'
                      '${includeWater ? '• Trung bình mỗi ngày phòng bạn xài: ${dailyWater.toStringAsFixed(2)} m³/ngày → Dự kiến đủ 30 ngày sẽ hết khoảng ${projected30DayWater.toStringAsFixed(1)} m³.\n' : ''}'
                      '• Ước tính tổng tiền cuối tháng (nếu giữ nguyên thói quen sử dụng): ${AppFormatters.currency(projected30DayCost)} (Chia 3 thành viên P.305 ≈ ${AppFormatters.currency(projected30DayCost / 3)}/người).\n'
                      '• Mẹo tiết kiệm: Hạn chế bật máy lạnh dưới 25°C và tắt bình nóng lạnh sau khi tắm giúp giảm ~18% tiền điện bậc 3 & bậc 4.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF334155),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

      // 4. Hai Cột: Cột Trái (Chụp/Tải Ảnh Công Tơ Điện / Nước) & Cột Phải (Nhập/Chỉnh Chỉ Số & Lưu Sổ Cá Nhân)
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.image_rounded, color: Color(0xFF2563EB), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Ảnh Chụp / Tải Lên Từ Điện Thoại Cư Dân',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    _buildPillBadge(
                      _ocrMode == 'both' ? '2 Ảnh (Điện + Nước)' : '1 Ảnh công tơ',
                      const Color(0xFFF1F5F9),
                      const Color(0xFF334155),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Khung ảnh Công Tơ Điện (hiển thị khi chọn Chỉ Điện hoặc Cả Hai)
                if (includeElectric)
                  _buildMeterPhotoUploadBox(
                    title: '⚡ Ảnh Công Tơ Điện (Đơn vị: kWh - ký/chữ điện)',
                    imageUrl: _electricPreviewUrl,
                    readingBadge: '${elecNew.toInt()} kWh',
                    accentColor: const Color(0xFF2563EB),
                    onCaptureOrUpload: () {
                      setState(() {
                        _showRoiOverlay = true;
                        _meterNewController.text = '1540';
                      });
                      _showMessage(
                        'Đã tải ảnh chụp Công Tơ Điện lên thành công! AI đọc được chỉ số mới: ${_meterNewController.text} kWh.',
                      );
                    },
                  ),

                if (includeElectric && includeWater) const SizedBox(height: 12),

                // Khung ảnh Đồng Hồ Nước (hiển thị khi chọn Chỉ Nước hoặc Cả Hai)
                if (includeWater)
                  _buildMeterPhotoUploadBox(
                    title: '💧 Ảnh Đồng Hồ Nước (Đơn vị: m³ - khối nước)',
                    imageUrl: _waterPreviewUrl,
                    readingBadge: '${waterNew.toInt()} m³',
                    accentColor: const Color(0xFF0284C7),
                    onCaptureOrUpload: () {
                      setState(() {
                        _showRoiOverlay = true;
                        _waterNewController.text = '92';
                      });
                      _showMessage(
                        'Đã tải ảnh chụp Đồng Hồ Nước lên thành công! AI đọc được chỉ số mới: ${_waterNewController.text} m³.',
                      );
                    },
                  ),

                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: _isScanningOcr
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.document_scanner_rounded, size: 18),
                    label: Text(
                      _isScanningOcr
                          ? 'AI ĐANG ĐỌC CHỈ SỐ TRÊN ẢNH & TÍNH TIỀN...'
                          : '🔍 QUÉT AI OCR & BÁO KẾT QUẢ TIỀN TẠM TÍNH NGAY',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _isScanningOcr ? null : triggerAiScanSimulation,
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
                    Icon(Icons.fact_check_rounded, color: Color(0xFF16A34A), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bảng Đối Chiếu Chỉ Số Từ Lần Thanh Toán Trước Đến Nay',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                      ),
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
                          const Text(
                            'CHẾ ĐỘ ĐANG TÍNH:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          _buildPillBadge(
                            _ocrMode == 'electric'
                                ? '⚡ Chỉ tính Điện'
                                : _ocrMode == 'water'
                                    ? '💧 Chỉ tính Nước'
                                    : '⚡+💧 Tính cả Điện & Nước',
                            const Color(0xFF2563EB),
                            Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ĐỘ TIN CẬY AI (CONFIDENCE):',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          _buildPillBadge(
                            _ocrConfidence,
                            const Color(0xFFECFDF5),
                            const Color(0xFF059669),
                          ),
                        ],
                      ),
                      if (includeElectric) ...[
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '⚡ ĐIỆN (Kỳ trước → Ảnh mới chụp):',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                            Text(
                              '${Formatters.formatNumber(elecOld.round())} → ${Formatters.formatNumber(elecNew.round())} kWh',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '   → Đã tiêu thụ Điện tháng này:',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            Text(
                              '${elecConsumption.toStringAsFixed(0)} ký điện (${AppFormatters.currency(elecResult.totalAmount)})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (includeWater) ...[
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '💧 NƯỚC (Kỳ trước → Ảnh mới chụp):',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                            Text(
                              '${Formatters.formatNumber(waterOld.round())} → ${Formatters.formatNumber(waterNew.round())} m³',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '   → Đã tiêu thụ Nước tháng này:',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            Text(
                              '${waterConsumption.toStringAsFixed(0)} khối nước (${AppFormatters.currency(waterResult.totalAmount)})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TỔNG TIỀN TẠM TÍNH ĐẾN HÔM NAY:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                          Text(
                            AppFormatters.currency(totalEstimatedCost),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Ô chỉnh sửa nhanh chỉ số nếu ảnh chụp bị mờ hoặc muốn thử nghiệm
                const Text(
                  'TÙY CHỈNH CHỈ SỐ (NẾU MUỐN TỰ NHẬP HOẶC KIỂM THỬ THÊM):',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                if (includeElectric)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _meterOldController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Điện kỳ trước (kWh)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) {
                              setState(() {});
                              _pushResidentMeterToCloud(
                                totalEstimatedCost: totalEstimatedCost,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _meterNewController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Điện ảnh mới chụp (kWh)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) {
                              setState(() {});
                              _pushResidentMeterToCloud(
                                totalEstimatedCost: totalEstimatedCost,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                if (includeWater)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _waterOldController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Nước kỳ trước (m³)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) {
                              setState(() {});
                              _pushResidentMeterToCloud(
                                totalEstimatedCost: totalEstimatedCost,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _waterNewController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Nước ảnh mới chụp (m³)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) {
                              setState(() {});
                              _pushResidentMeterToCloud(
                                totalEstimatedCost: totalEstimatedCost,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                // Cảnh báo mức tiêu thụ so với trung bình
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasAnomaly
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFD1FAE5).withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        hasAnomaly
                            ? Icons.warning_amber_rounded
                            : Icons.verified_user_outlined,
                        color: hasAnomaly
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF047857),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          hasAnomaly
                              ? 'Cảnh báo cho bạn: Lượng tiêu thụ hiện cao hơn >30% so với trung bình tháng trước. Hãy kiểm tra vòi nước rò rỉ hoặc thiết bị điện công suất lớn!'
                              : 'Mức tiêu thụ hoàn toàn bình thường và ổn định so với trung bình các tháng trước của phòng P.305.',
                          style: TextStyle(
                            fontSize: 11,
                            color: hasAnomaly
                                ? const Color(0xFF991B1B)
                                : const Color(0xFF065F46),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Cam kết không gửi về Admin & Nút Lưu vào Sổ theo dõi cá nhân
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF1D4ED8)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chế độ riêng tư: Kết quả này chỉ hiện để bạn biết trước số tiền, KHÔNG gửi về Admin / Ban Quản Lý.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.calculate_outlined, size: 17),
                        label: Text(
                          _showCalculationDetail
                              ? 'Ẩn chi tiết cách tính'
                              : 'Xem chi tiết cách tính',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _showCalculationDetail = !_showCalculationDetail;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.bookmark_added_rounded, size: 17),
                        label: const Text(
                          'Lưu Sổ cá nhân của tôi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        onPressed: () {
                          final modeLabel = _ocrMode == 'electric'
                              ? 'Chỉ tính Điện'
                              : _ocrMode == 'water'
                                  ? 'Chỉ tính Nước'
                                  : 'Điện + Nước';
                          final summary = _ocrMode == 'electric'
                              ? '${elecConsumption.toStringAsFixed(0)} kWh điện'
                              : _ocrMode == 'water'
                                  ? '${waterConsumption.toStringAsFixed(0)} m³ nước'
                                  : '${elecConsumption.toStringAsFixed(0)} kWh điện • ${waterConsumption.toStringAsFixed(0)} m³ nước';
                          setState(() {
                            _personalMeterLogs.insert(
                              0,
                              _PersonalMeterLog(
                                dateLabel: 'Hôm nay (Tự chụp kiểm tra)',
                                modeLabel: modeLabel,
                                consumptionSummary: summary,
                                estimatedCost: totalEstimatedCost,
                              ),
                            );
                          });
                          _pushResidentMeterToCloud(
                            saveToLog: true,
                            summary: summary,
                            dateLabel: 'Hôm nay (Đồng bộ Giả lập Android & Web)',
                            totalEstimatedCost: totalEstimatedCost,
                          );
                          _showMessage(
                            '📌 Đã lưu kết quả tạm tính (${AppFormatters.currency(totalEstimatedCost)}) vào Sổ theo dõi cá nhân & đồng bộ sang các thiết bị của bạn (Không gửi Admin)!',
                          );
                        },
                      ),
                    ),
                  ],
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

      const SizedBox(height: 16),

      // 5. SỔ THEO DÕI ĐIỆN NƯỚC CÁ NHÂN CỦA CƯ DÂN (LỊCH SỬ TỰ CHỤP KIỂM TRA)
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
                const Row(
                  children: [
                    Icon(Icons.history_edu_rounded, color: Color(0xFF0F766E), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Sổ Theo Dõi Chỉ Số Cá Nhân Của Bạn (Lưu Riêng Trên Thiết Bị)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                _buildPillBadge(
                  '${_personalMeterLogs.length} lần tự kiểm tra',
                  const Color(0xFFF0FDFA),
                  const Color(0xFF0F766E),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._personalMeterLogs.map(
              (log) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.dateLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${log.modeLabel} • Tiêu thụ: ${log.consumptionSummary}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      AppFormatters.currency(log.estimatedCost),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildModeSelectorButton({
    required String mode,
    required IconData icon,
    required String label,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    final isSelected = _ocrMode == mode;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : activeColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationStatChip({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 10, color: Color(0xFFCBD5E1)),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeterPhotoUploadBox({
    required String title,
    required String imageUrl,
    required String readingBadge,
    required Color accentColor,
    required VoidCallback onCaptureOrUpload,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
              _buildPillBadge(
                'AI đọc: $readingBadge',
                accentColor,
                Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl,
                  height: _ocrMode == 'both' ? 135 : 195,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: _ocrMode == 'both' ? 135 : 195,
                    color: const Color(0xFF0F172A),
                    child: const Center(
                      child: Icon(
                        Icons.speed_rounded,
                        size: 56,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
              if (_showRoiOverlay)
                Container(
                  width: 190,
                  height: 74,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFEF4444), width: 2),
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  ),
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(7),
                        bottomRight: Radius.circular(7),
                      ),
                    ),
                    child: Text(
                      'ROI AI: $readingBadge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                side: BorderSide(color: accentColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add_a_photo_outlined, size: 15),
              label: const Text(
                'Chụp ảnh mới / Tải ảnh từ máy lên',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              onPressed: onCaptureOrUpload,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierBreakdownSection({
    required String title,
    required String unitLabel,
    required CalculationResult result,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          if (result.tiers.isEmpty)
            const Text(
              'Chưa phát sinh sản lượng tiêu thụ (Chỉ số mới ≤ Chỉ số kỳ trước).',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            )
          else
            ...result.tiers.map(
              (tier) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '• ${tier.tierName}: ${tier.quantity.toStringAsFixed(0)} $unitLabel × ${Formatters.formatNumber(tier.unitPrice.round())} đ',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Text(
                      AppFormatters.currency(tier.totalAmount),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cộng thành tiền (${result.totalQuantity.toStringAsFixed(0)} $unitLabel):',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                AppFormatters.currency(result.totalAmount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

class _PersonalMeterLog {
  final String dateLabel;
  final String modeLabel;
  final String consumptionSummary;
  final double estimatedCost;

  const _PersonalMeterLog({
    required this.dateLabel,
    required this.modeLabel,
    required this.consumptionSummary,
    required this.estimatedCost,
  });
}
