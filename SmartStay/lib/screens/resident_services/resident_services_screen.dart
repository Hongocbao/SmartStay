import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/api_transport.dart';
import '../../services/supabase_direct_service.dart';
import '../../services/system_config.dart';
import '../../services/tiered_utility_service.dart';
import '../../utils/formatters.dart';
import '../../utils/provider_scope.dart';
import '../../widgets/call_center_modal.dart';

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
  bool _isDoorUnlockedTemporarily = false;
  final Set<String> _claimedListings = {};

  final List<_RoommateShare> _roommates = [
    _RoommateShare(
      name: 'Hồ Ngọc Bảo',
      roleBadge: 'Trưởng phòng',
      mssv: '2380600133',
      code: 'BAO1',
      isPaid: true,
      stayDays: 30,
      customRatio: 0.40,
    ),
    _RoommateShare(
      name: 'Nguyễn Dương Bảo',
      roleBadge: 'Thành viên 2',
      mssv: '2380600154',
      code: 'BAO2',
      isPaid: true,
      stayDays: 28,
      customRatio: 0.30,
    ),
    _RoommateShare(
      name: 'Trần Hoàng Gia Bảo',
      roleBadge: 'Thành viên 3',
      mssv: '2380600178',
      code: 'BAO3',
      isPaid: false,
      stayDays: 20,
      customRatio: 0.30,
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
    _MarketListing(
      'Quạt đứng Senko 3 tốc độ gió có hẹn giờ',
      'Điện gia dụng',
      120000,
      350000,
      'P.305',
      'Hồ Ngọc Bảo (P.305)',
      'Còn rất mới 95%',
      'Dùng được 4 tháng, chạy êm ru, có remote điều khiển. Pass lại do phòng đã có máy lạnh.',
      'https://images.unsplash.com/photo-1585338107529-13afc5f02586?auto=format&fit=crop&w=600&q=80',
      id: 'MKT-001',
      videoUrl: 'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4',
      rating: 5.0,
      reviews: [
        const _MarketReview(
          reviewer: 'Minh Anh',
          room: 'P.201',
          stars: 5,
          comment: 'Quạt chạy rất êm, bạn Bảo bàn giao cẩn thận kèm remote zin!',
          time: 'Hôm qua',
        ),
      ],
    ),
    _MarketListing(
      'Combo 5 cuốn giáo trình Cấu trúc dữ liệu & Giải thuật',
      'Tặng miễn phí',
      0,
      0,
      'P.201',
      'Nguyễn Dương Bảo (P.201)',
      'TẶNG MIỄN PHÍ 0Đ',
      'Mình đã học xong môn, tặng lại cho các bạn khóa dưới cần ôn thi cuối kỳ.',
      'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?auto=format&fit=crop&w=600&q=80',
      id: 'MKT-002',
      rating: 4.9,
      reviews: [
        const _MarketReview(
          reviewer: 'Khánh Linh',
          room: 'P.104',
          stars: 5,
          comment: 'Sách sạch sẽ không rách trang, cảm ơn anh nhiều!',
          time: '2 ngày trước',
        ),
      ],
    ),
    _MarketListing(
      'Ấm đun nước siêu tốc Sunhouse Inox 1.8L',
      'Điện gia dụng',
      70000,
      180000,
      'P.401',
      'Trần Hoàng Gia Bảo (P.401)',
      'Inox 304',
      'Đun sôi siêu nhanh trong 3 phút, tự ngắt điện an toàn khi sôi, còn nguyên hộp.',
      'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=600&q=80',
      id: 'MKT-003',
      videoUrl: 'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4',
      rating: 4.8,
      reviews: const [],
    ),
  ];

  String _guestDuration = '2 giờ';
  String _marketFilter = 'Tất cả';
  String _listingCategory = 'Điện gia dụng';

  // State cho AI Camera OCR Tự Kiểm Tra Điện Nước Cá Nhân (/CuDan/AiOcr)
  // 'electric' = Chỉ tính Điện | 'water' = Chỉ tính Nước | 'both' = Tính cả Điện & Nước
  String _ocrMode = 'both';
  String _ocrConfidence = 'Sẵn sàng quét AI Vision OCR';
  String? _uploadedElectricDataUrl;
  String? _uploadedWaterDataUrl;
  String _electricPhotoLabel = 'Mặt đồng hồ công tơ điện tử P.305';
  String _waterPhotoLabel = 'Mặt đồng hồ nước sinh hoạt P.305';
  bool _isScanningOcr = false;
  bool _showRoiOverlay = true;
  bool _showCalculationDetail = false;
  final int _daysSinceLastPayment = 25; // Từ kỳ thanh toán trước (05/10) đến hôm nay
  Timer? _residentMeterSyncTimer;
  bool _isPullingMeter = false;
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
      const Duration(seconds: 8),
      (_) => _pullResidentMeterFromCloud(),
    );
  }

  Future<void> _pullResidentMeterFromCloud() async {
    if (!mounted || _isPullingMeter) return;
    // Tránh ghi đè khi người dùng vừa gõ phím trong vòng 3 giây
    if (_lastLocalMeterEdit != null &&
        DateTime.now().difference(_lastLocalMeterEdit!).inSeconds < 3) {
      return;
    }
    _isPullingMeter = true;
    try {
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
    } finally {
      _isPullingMeter = false;
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
    // Liên thông trực tiếp với chỉ số Điện/Nước tạm tính từ Tab AI Quét Công Tơ
    final elecOld = double.tryParse(_meterOldController.text) ?? 1420;
    final elecNew = double.tryParse(_meterNewController.text) ?? 1540;
    final elecUsed = elecNew >= elecOld ? elecNew - elecOld : 0.0;
    final elecCost = TieredUtilityService.calculateElectricity(elecUsed).totalAmount;

    final waterOld = double.tryParse(_waterOldController.text) ?? 84;
    final waterNew = double.tryParse(_waterNewController.text) ?? 92;
    final waterUsed = waterNew >= waterOld ? waterNew - waterOld : 0.0;
    final waterCost = TieredUtilityService.calculateWater(waterUsed).totalAmount;

    const fixedRoomRent = 3500000.0;
    const commonServiceFee = 300000.0;
    const fixedSharedTotal = fixedRoomRent + commonServiceFee; // 3.800.000 đ cố định
    final utilityTotal = elecCost + waterCost;
    final total = fixedSharedTotal + utilityTotal;

    final members = _roommates.length;
    final totalStayDays = _roommates
        .fold<int>(0, (sum, m) => sum + m.stayDays)
        .clamp(1, 999);

    // Tính số tiền hợp lý theo đời sống cho từng thành viên:
    // - 'equal': Chia đều 100% hóa đơn cho 3 người
    // - 'days': Tiền phòng + dịch vụ cố định chia đều 3 người, riêng Tiền Điện + Nước chia theo số ngày ở thực tế!
    // - 'custom': Chia theo tỷ lệ % thỏa thuận (ví dụ 40% - 30% - 30%)
    final List<int> memberAmounts = List.generate(members, (idx) {
      final m = _roommates[idx];
      if (_splitMethod == 'days') {
        final fixedPerPerson = fixedSharedTotal / members;
        final utilityByDays = utilityTotal * (m.stayDays / totalStayDays);
        return (fixedPerPerson + utilityByDays).round();
      } else if (_splitMethod == 'custom') {
        return (total * m.customRatio).round();
      } else {
        return (total / members).floor();
      }
    });
    // Cân bằng số tiền lẻ vào thành viên cuối để tổng khớp 100% hóa đơn
    final sumFirst = memberAmounts.take(members - 1).fold<int>(0, (a, b) => a + b);
    memberAmounts[members - 1] = (total.round() - sumFirst).clamp(0, total.round());

    final perPerson = (total / members).round();
    final paidCount = _roommates.where((m) => m.isPaid).length;
    final progress = _roommates.isEmpty ? 0.0 : paidCount / _roommates.length;
    double collectedAmount = 0;
    for (var i = 0; i < members; i++) {
      if (_roommates[i].isPaid) {
        collectedAmount += memberAmounts[i];
      }
    }
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
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 16, color: Colors.white),
                  label: const Text('📷 Mở Máy Quét QR Nội Khu (Quét Thử QR)', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                  onPressed: () {
                    final unpaidIdx = _roommates.indexWhere((r) => !r.isPaid);
                    final targetIdx = unpaidIdx != -1 ? unpaidIdx : _roommates.length - 1;
                    final targetMember = _roommates[targetIdx];
                    final targetAmount = memberAmounts[targetIdx];
                    final targetQr = SystemConfig().vietQrUrl(
                      amount: targetAmount.toDouble(),
                      content: 'HD1026 P305 ${targetMember.code}',
                    );
                    _showQrScannerSimulatorDialog(
                      scannerTitle: 'Máy Quét QR Thanh Toán Sandbox Nội Khu',
                      qrImageUrl: targetQr,
                      decodedHeader: 'ĐÃ GIẢI MÃ TOKEN QR THANH TOÁN SANDBOX',
                      decodedLines: [
                        '• Cổng xử lý: SmartStay FinTech Sandbox (Ẩn STK thật 100%)',
                        '• Tài khoản Định danh Ảo (VA): VA-P305-${targetMember.code}',
                        '• Thành viên nộp: ${targetMember.name} (MSSV: ${targetMember.mssv})',
                        '• Số tiền giải mã từ QR: ${AppFormatters.currency(targetAmount.toDouble())}',
                        '• Nội dung đối soát: HD1026 P305 ${targetMember.code}',
                      ],
                      confirmButtonLabel: '✓ XÁC NHẬN THANH TOÁN QUA MÃ QR VỪA QUÉT',
                      onConfirm: () {
                        setState(() => targetMember.isPaid = true);
                        _showMessage(
                          '📷 Quét QR Sandbox thành công! Đã gạch nợ ${AppFormatters.currency(targetAmount.toDouble())} cho [${targetMember.name}] qua TK Định danh Ảo VA-P305-${targetMember.code}.',
                        );
                      },
                    );
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.notifications_active_rounded, size: 16, color: Colors.white),
                  label: const Text('Nhắc nhở cả phòng nộp tiền', style: TextStyle(fontSize: 12, color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                  onPressed: () {
                    _showMessage('Đã gửi thông báo nhắc nợ Push Notification và Email kèm link QR Sandbox cá nhân tới các thành viên chưa nộp!');
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
            Builder(
              builder: (context) {
                final feeBoxes = [
                  _buildMiniFeeBox('Tiền phòng cố định', '3.500.000 đ', const Color(0xFF0F172A)),
                  _buildMiniFeeBox('Điện (${elecUsed.toStringAsFixed(0)} kWh)', AppFormatters.currency(elecCost), const Color(0xFF2563EB)),
                  _buildMiniFeeBox('Nước (${waterUsed.toStringAsFixed(0)} m³)', AppFormatters.currency(waterCost), const Color(0xFF0284C7)),
                  _buildMiniFeeBox('Dịch vụ chung', '300.000 đ', const Color(0xFF475569)),
                ];
                if (MediaQuery.of(context).size.width > 700) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: feeBoxes[0]),
                        const SizedBox(width: 10),
                        Expanded(child: feeBoxes[1]),
                        const SizedBox(width: 10),
                        Expanded(child: feeBoxes[2]),
                        const SizedBox(width: 10),
                        Expanded(child: feeBoxes[3]),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: feeBoxes[0]),
                          const SizedBox(width: 10),
                          Expanded(child: feeBoxes[1]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: feeBoxes[2]),
                          const SizedBox(width: 10),
                          Expanded(child: feeBoxes[3]),
                        ],
                      ),
                    ),
                  ],
                );
              },
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
                      const Expanded(
                        child: Text(
                          'TIẾN ĐỘ HOÀN TẤT HÓA ĐƠN PHÒNG P.305:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '$paidCount / $members Bạn đã thanh toán (${(progress * 100).toStringAsFixed(1)}%)',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: paidCount == members ? const Color(0xFF16A34A) : const Color(0xFF4F46E5),
                          ),
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
                    isExpanded: true,
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
            final shareAmount = memberAmounts[idx];
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
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
                      ),
                      const SizedBox(width: 8),
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
                        if (_splitMethod == 'days') ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: () {
                                  if (m.stayDays > 1) {
                                    setState(() => m.stayDays -= 1);
                                  }
                                },
                                child: const Icon(Icons.remove_circle_outline, size: 16, color: Color(0xFF4F46E5)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'Ở thực tế: ${m.stayDays}/30 ngày',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  if (m.stayDays < 30) {
                                    setState(() => m.stayDays += 1);
                                  }
                                },
                                child: const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF4F46E5)),
                              ),
                            ],
                          ),
                        ] else if (_splitMethod == 'custom') ...[
                          const SizedBox(height: 4),
                          Text(
                            'Tỷ lệ thỏa thuận: ${(m.customRatio * 100).round()}% tổng hóa đơn',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                          ),
                        ],
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
                    child: InkWell(
                      onTap: () {
                        _showQrScannerSimulatorDialog(
                          scannerTitle: 'Máy Quét QR Thanh Toán — ${m.name}',
                          qrImageUrl: qrUrl,
                          decodedHeader: 'ĐÃ QUÉT & GIẢI MÃ QR TOKEN CỦA ${m.name.toUpperCase()}',
                          decodedLines: [
                            '• Cổng xử lý: SmartStay FinTech Sandbox (Bảo mật STK 100%)',
                            '• Tài khoản Định danh Ảo: VA-P305-${m.code}',
                            '• Thành viên: ${m.name} (${m.roleBadge})',
                            '• Số tiền trong QR: ${AppFormatters.currency(shareAmount.toDouble())}',
                            '• Nội dung tham chiếu: HD1026 P305 ${m.code}',
                          ],
                          confirmButtonLabel: m.isPaid
                              ? '✓ MÃ QR NÀY ĐÃ ĐỐI SOÁT HOÀN TẤT (ĐÓNG)'
                              : '✓ XÁC NHẬN THANH TOÁN QUA MÃ QR VỪA QUÉT',
                          onConfirm: () {
                            if (!m.isPaid) {
                              setState(() => m.isPaid = true);
                              _showMessage(
                                '📷 Quét QR Sandbox thành công! ${m.name} đã hoàn tất nộp ${AppFormatters.currency(shareAmount.toDouble())} qua mã QR VA-P305-${m.code}.',
                              );
                            }
                          },
                        );
                      },
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
                            m.isPaid
                                ? '🛡️ TK Định danh Ảo: VA-P305-${m.code} (Chạm vào QR để quét kiểm tra)'
                                : '📷 Chạm vào mã QR này để mở Máy Quét QR Giả Lập',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: m.isPaid ? const Color(0xFF16A34A) : const Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: m.isPaid
                        ? OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF16A34A)),
                            label: const Text('Đã Đối Soát Qua Cổng Sandbox', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A))),
                          )
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                            icon: const Icon(Icons.check_circle_outline, size: 15, color: Colors.white),
                            label: const Text('⚡ Giả Lập Thanh Toán Sandbox 1 Chạm', style: TextStyle(fontSize: 11, color: Colors.white)),
                            onPressed: () {
                              setState(() => m.isPaid = true);
                              _showMessage('Webhook Sandbox báo có: ${m.name} đã nộp ${AppFormatters.currency(shareAmount.toDouble())} qua TK Định danh Ảo (VA-P305-${m.code})! Không lộ STK thật — Hóa đơn P.305 đã hoàn tất 100%.');
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
      _buildSectionHeaderCard(
        badges: [
          _buildPillBadge('DIGITAL KEYLESS', const Color(0xFF16A34A), Colors.white),
          _buildPillBadge('Smart IoT Pass', const Color(0xFFEEF2FF), const Color(0xFF4F46E5)),
        ],
        title: 'Cấp Mã Khách Vãng Lai & Vé Điện Tử Tạm Thời (Digital Guest Pass)',
        subtitle:
            'Cư dân P.305 tự tạo mã QR hoặc mã PIN tạm thời có giới hạn giờ cho bạn bè/người thân đến thăm. Hệ thống tự động ghi nhật ký ra vào bảo đảm an ninh.',
        actionButton: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
          icon: const Icon(Icons.add, size: 16, color: Colors.white),
          label: const Text('Tạo Vé Khách Mới', style: TextStyle(fontSize: 12, color: Colors.white)),
          onPressed: _showCreateGuestPassDialog,
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
                Expanded(
                  child: Text('Khóa Cửa Căn Hộ P.305', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
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
                  Icon(
                    _isDoorUnlockedTemporarily
                        ? Icons.lock_open_rounded
                        : Icons.lock_rounded,
                    size: 42,
                    color: _isDoorUnlockedTemporarily
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isDoorUnlockedTemporarily
                        ? '🔓 LOCK-A-305 (ĐANG MỞ CỬA — Tự khóa chốt sau 5 giây)'
                        : '🔒 LOCK-A-305 (Trạng Thái: Đang Khóa An Toàn)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _isDoorUnlockedTemporarily
                          ? const Color(0xFFD97706)
                          : const Color(0xFF0F172A),
                    ),
                  ),
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
                label: Text(
                  _isDoorUnlockedTemporarily
                      ? 'Cửa Đang Mở (Sẽ tự khóa sau 5 giây...)'
                      : 'Mở Cửa Ngay Từ Xa (Remote Unlock)',
                  style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF16A34A))),
                onPressed: admin.isLoading || _isDoorUnlockedTemporarily
                    ? null
                    : () async {
                        await admin.remoteUnlockRoom('P.305');
                        if (!mounted) return;
                        setState(() => _isDoorUnlockedTemporarily = true);
                        _showMessage('Đã gửi lệnh mở khóa qua giao thức MQTT tới khóa phòng P.305! Khóa sẽ tự động chốt lại sau 5 giây.');
                        Future.delayed(const Duration(seconds: 5), () {
                          if (mounted) {
                            setState(() => _isDoorUnlockedTemporarily = false);
                          }
                        });
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
                Expanded(
                  child: Text(
                    '🎫 Mã Khách Vãng Lai Đang Có Hiệu Lực (${_passes.length} Vé)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Tự động hủy khi hết hạn',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPillBadge(pass.duration, const Color(0xFF16A34A), Colors.white),
                              const SizedBox(height: 4),
                              Text(pass.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
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
                      child: InkWell(
                        onTap: () {
                          _showQrScannerSimulatorDialog(
                            scannerTitle: 'Đầu Đọc QR Cổng An Ninh Sảnh A (IoT Gate)',
                            qrImageUrl: qrImg,
                            decodedHeader: 'XÁC THỰC MÃ QR VÉ KHÁCH VÃNG LAI HỢP LỆ',
                            decodedLines: [
                              '• Khách ghé thăm: ${pass.name}',
                              '• Phòng mời: Căn hộ P.305 (Tầng 3 - Tòa A)',
                              '• Mã PIN định danh: #${pass.pin}',
                              '• Loại hiệu lực: ${pass.duration}',
                              '• Trạng thái cổng từ: CHO PHÉP MỞ CỬA SẢNH A',
                            ],
                            confirmButtonLabel: '🔓 XÁC NHẬN QUÉT QR & MỞ CỔNG CHO KHÁCH',
                            onConfirm: () {
                              final isSingleUse = pass.duration.contains('1 lần');
                              if (isSingleUse) {
                                setState(() => _passes.remove(pass));
                                _showMessage(
                                  '📷 Đầu đọc QR Sảnh A đã mở cửa cho [${pass.name}]! Vì đây là Vé 1 lần nên hệ thống đã tự động hủy vé sau khi khách qua cổng.',
                                );
                              } else {
                                _showMessage(
                                  '📷 Đầu đọc QR Sảnh A đã xác thực mã QR #${pass.pin} và mở cửa cho [${pass.name}]!',
                                );
                              }
                            },
                          );
                        },
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
                              const Text(
                                '📷 Chạm vào QR để giả lập Quét tại Cổng Sảnh A',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.qr_code_scanner_rounded, size: 14),
                            label: const Text('Quét Thử QR Cổng Sảnh', style: TextStyle(fontSize: 11)),
                            onPressed: () {
                              _showQrScannerSimulatorDialog(
                                scannerTitle: 'Đầu Đọc QR Cổng An Ninh Sảnh A (IoT Gate)',
                                qrImageUrl: qrImg,
                                decodedHeader: 'XÁC THỰC MÃ QR VÉ KHÁCH VÃNG LAI HỢP LỆ',
                                decodedLines: [
                                  '• Khách ghé thăm: ${pass.name}',
                                  '• Phòng mời: Căn hộ P.305 (Tầng 3 - Tòa A)',
                                  '• Mã PIN định danh: #${pass.pin}',
                                  '• Loại hiệu lực: ${pass.duration}',
                                  '• Trạng thái cổng từ: CHO PHÉP MỞ CỬA SẢNH A',
                                ],
                                confirmButtonLabel: '🔓 XÁC NHẬN QUÉT QR & MỞ CỔNG CHO KHÁCH',
                                onConfirm: () {
                                  final isSingleUse = pass.duration.contains('1 lần');
                                  if (isSingleUse) {
                                    setState(() => _passes.remove(pass));
                                    _showMessage(
                                      '📷 Đầu đọc QR Sảnh A đã mở cửa cho [${pass.name}]! Vì đây là Vé 1 lần nên hệ thống đã tự động hủy vé sau khi khách qua cổng.',
                                    );
                                  } else {
                                    _showMessage(
                                      '📷 Đầu đọc QR Sảnh A đã xác thực mã QR #${pass.pin} và mở cửa cho [${pass.name}]!',
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.share_rounded, size: 14),
                            label: const Text('Gửi link Zalo/SMS', style: TextStyle(fontSize: 11)),
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
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ]);
  }

  void _showQrScannerSimulatorDialog({
    required String scannerTitle,
    required String qrImageUrl,
    required String decodedHeader,
    required List<String> decodedLines,
    required String confirmButtonLabel,
    required VoidCallback onConfirm,
  }) {
    bool isScanningLaser = true;
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            if (isScanningLaser) {
              Future.delayed(const Duration(milliseconds: 650), () {
                if (ctx.mounted && isScanningLaser) {
                  setDialogState(() => isScanningLaser = false);
                }
              });
            }
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              titlePadding: const EdgeInsets.fromLTRB(18, 16, 12, 0),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Color(0xFF0F766E),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            scannerTitle,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(dialogCtx),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Khung ngắm Camera Quét QR (Viewfinder)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isScanningLaser
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF22C55E),
                                    width: 3,
                                  ),
                                ),
                                child: Image.network(
                                  qrImageUrl,
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const SizedBox(
                                    width: 150,
                                    height: 150,
                                    child: Icon(Icons.qr_code_2_rounded, size: 110),
                                  ),
                                ),
                              ),
                              if (isScanningLaser)
                                Container(
                                  width: 165,
                                  height: 3,
                                  color: const Color(0xFFEF4444),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isScanningLaser)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFFBBF24),
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF4ADE80),
                                  size: 16,
                                ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  isScanningLaser
                                      ? 'Camera đang quét & giải mã QR Token...'
                                      : '✓ Đã quét và giải mã QR thành công (100%)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isScanningLaser
                                        ? const Color(0xFFFBBF24)
                                        : const Color(0xFF4ADE80),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Kết quả giải mã từ mã QR
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            decodedHeader,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF166534),
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...decodedLines.map(
                            (line) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                line,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Đóng'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.verified_rounded, size: 16),
                  label: Text(
                    confirmButtonLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: isScanningLaser
                      ? null
                      : () {
                          Navigator.pop(dialogCtx);
                          onConfirm();
                        },
                ),
              ],
            );
          },
        );
      },
    );
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
          _ocrConfidence = 'Chế độ: Chỉ quét Công Tơ Điện (AI Vision)';
        } else if (mode == 'water') {
          _ocrConfidence = 'Chế độ: Chỉ quét Đồng Hồ Nước (AI Vision)';
        } else {
          _ocrConfidence = 'Chế độ: Quét cả Điện & Nước (AI Vision)';
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
        _ocrConfidence = 'Đang phân tích ảnh thực tế bằng AI Vision OCR...';
      });

      final api = ApiService();
      final notes = <String>[];
      var scannedConfidence = '';

      if (includeElectric && _uploadedElectricDataUrl != null) {
        final elecOldVal = int.tryParse(_meterOldController.text.trim()) ?? 1420;
        final eRes = await api.analyzeMeterOcr(
          dataUrl: _uploadedElectricDataUrl!,
          meterType: 'electric',
          previousReading: elecOldVal,
        );
        if (eRes != null && eRes['reading'] is num) {
          final r = (eRes['reading'] as num).toInt();
          _meterNewController.text = '$r';
          final conf = (eRes['confidence'] as num?)?.toStringAsFixed(1);
          if (conf != null) scannedConfidence = '$conf% (${eRes['provider'] ?? 'AI Vision OCR'})';
          if ((eRes['note'] ?? '').toString().isNotEmpty) notes.add(eRes['note'].toString());
        }
      }

      if (includeWater && _uploadedWaterDataUrl != null) {
        final waterOldVal = int.tryParse(_waterOldController.text.trim()) ?? 84;
        final wRes = await api.analyzeMeterOcr(
          dataUrl: _uploadedWaterDataUrl!,
          meterType: 'water',
          previousReading: waterOldVal,
        );
        if (wRes != null && wRes['reading'] is num) {
          final r = (wRes['reading'] as num).toInt();
          _waterNewController.text = '$r';
          final conf = (wRes['confidence'] as num?)?.toStringAsFixed(1);
          if (conf != null && scannedConfidence.isEmpty) {
            scannedConfidence = '$conf% (${wRes['provider'] ?? 'AI Vision OCR'})';
          }
          if ((wRes['note'] ?? '').toString().isNotEmpty) notes.add(wRes['note'].toString());
        }
      }

      if (!mounted) return;
      setState(() {
        _isScanningOcr = false;
        _showCalculationDetail = true;
        _ocrConfidence = scannedConfidence.isNotEmpty
            ? scannedConfidence
            : 'Tính trực tiếp từ chỉ số đồng hồ hiện tại';
      });

      final updatedElecOld = double.tryParse(_meterOldController.text) ?? 1420;
      final updatedElecNew = double.tryParse(_meterNewController.text) ?? 1540;
      final updatedElecUsed = includeElectric && updatedElecNew >= updatedElecOld
          ? updatedElecNew - updatedElecOld
          : 0.0;
      final updatedElecRes =
          TieredUtilityService.calculateElectricity(updatedElecUsed);

      final updatedWaterOld = double.tryParse(_waterOldController.text) ?? 84;
      final updatedWaterNew = double.tryParse(_waterNewController.text) ?? 92;
      final updatedWaterUsed =
          includeWater && updatedWaterNew >= updatedWaterOld
              ? updatedWaterNew - updatedWaterOld
              : 0.0;
      final updatedWaterRes = TieredUtilityService.calculateWater(updatedWaterUsed);
      final updatedTotal = (includeElectric ? updatedElecRes.totalAmount : 0.0) +
          (includeWater ? updatedWaterRes.totalAmount : 0.0);

      _pushResidentMeterToCloud(totalEstimatedCost: updatedTotal);

      final summaryParts = <String>[];
      if (includeElectric) {
        summaryParts.add(
          '${updatedElecUsed.toStringAsFixed(0)} kWh (ký điện) = ${AppFormatters.currency(updatedElecRes.totalAmount)}',
        );
      }
      if (includeWater) {
        summaryParts.add(
          '${updatedWaterUsed.toStringAsFixed(0)} m³ (khối nước) = ${AppFormatters.currency(updatedWaterRes.totalAmount)}',
        );
      }
      _showMessage(
        '🔔 Thông báo tạm tính tháng này: Đã tiêu thụ ${summaryParts.join(' & ')} • Tổng: ${AppFormatters.currency(updatedTotal)} (Chỉ báo trước cho bạn, không gửi Admin).',
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
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.image_rounded, color: Color(0xFF2563EB), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ảnh Chụp / Tải Lên Từ Điện Thoại Cư Dân',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
                    meterType: 'electric',
                    customDataUrl: _uploadedElectricDataUrl,
                    photoLabel: _electricPhotoLabel,
                    readingValueText: '${elecNew.toInt()}',
                    unitLabel: 'kWh',
                    accentColor: const Color(0xFF2563EB),
                    onCaptureOrUpload: () => _handlePickMeterPhoto('electric'),
                    onResetPhoto: _uploadedElectricDataUrl == null
                        ? null
                        : () {
                            setState(() {
                              _uploadedElectricDataUrl = null;
                              _electricPhotoLabel =
                                  'Mặt đồng hồ công tơ điện tử P.305';
                            });
                          },
                  ),

                if (includeElectric && includeWater) const SizedBox(height: 12),

                // Khung ảnh Đồng Hồ Nước (hiển thị khi chọn Chỉ Nước hoặc Cả Hai)
                if (includeWater)
                  _buildMeterPhotoUploadBox(
                    title: '💧 Ảnh Đồng Hồ Nước (Đơn vị: m³ - khối nước)',
                    meterType: 'water',
                    customDataUrl: _uploadedWaterDataUrl,
                    photoLabel: _waterPhotoLabel,
                    readingValueText: '${waterNew.toInt()}',
                    unitLabel: 'm³',
                    accentColor: const Color(0xFF0284C7),
                    onCaptureOrUpload: () => _handlePickMeterPhoto('water'),
                    onResetPhoto: _uploadedWaterDataUrl == null
                        ? null
                        : () {
                            setState(() {
                              _uploadedWaterDataUrl = null;
                              _waterPhotoLabel =
                                  'Mặt đồng hồ nước sinh hoạt P.305';
                            });
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
                      _buildComparisonRow(
                        label: 'CHẾ ĐỘ ĐANG TÍNH:',
                        labelStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                        trailing: _buildPillBadge(
                          _ocrMode == 'electric'
                              ? '⚡ Chỉ tính Điện'
                              : _ocrMode == 'water'
                                  ? '💧 Chỉ tính Nước'
                                  : '⚡+💧 Tính cả Điện & Nước',
                          const Color(0xFF2563EB),
                          Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildComparisonRow(
                        label: 'ĐỘ TIN CẬY AI (CONFIDENCE):',
                        labelStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                        trailing: _buildPillBadge(
                          _ocrConfidence,
                          const Color(0xFFECFDF5),
                          const Color(0xFF059669),
                        ),
                      ),
                      if (includeElectric) ...[
                        const Divider(height: 18),
                        _buildComparisonRow(
                          label: '⚡ ĐIỆN (Kỳ trước → Ảnh mới chụp):',
                          labelStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                          trailing: Text(
                            '${Formatters.formatNumber(elecOld.round())} → ${Formatters.formatNumber(elecNew.round())} kWh',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildComparisonRow(
                          label: '   → Đã tiêu thụ Điện tháng này:',
                          labelStyle: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          trailing: Text(
                            '${elecConsumption.toStringAsFixed(0)} ký điện (${AppFormatters.currency(elecResult.totalAmount)})',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                      if (includeWater) ...[
                        const Divider(height: 18),
                        _buildComparisonRow(
                          label: '💧 NƯỚC (Kỳ trước → Ảnh mới chụp):',
                          labelStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                          trailing: Text(
                            '${Formatters.formatNumber(waterOld.round())} → ${Formatters.formatNumber(waterNew.round())} m³',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildComparisonRow(
                          label: '   → Đã tiêu thụ Nước tháng này:',
                          labelStyle: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          trailing: Text(
                            '${waterConsumption.toStringAsFixed(0)} khối nước (${AppFormatters.currency(waterResult.totalAmount)})',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ),
                      ],
                      const Divider(height: 20),
                      _buildComparisonRow(
                        label: 'TỔNG TIỀN TẠM TÍNH ĐẾN HÔM NAY:',
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                        trailing: Text(
                          AppFormatters.currency(totalEstimatedCost),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                          ),
                        ),
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

                // Cảnh báo nếu nhập nhầm Chỉ số mới < Chỉ số kỳ trước (Đồng hồ không quay ngược)
                if ((includeElectric && elecNew < elecOld) ||
                    (includeWater && waterNew < waterOld))
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '⚠️ Lưu ý: Chỉ số ảnh mới đang nhỏ hơn chỉ số kỳ thanh toán trước! Đồng hồ công tơ chạy lũy kế một chiều (không quay ngược) — vui lòng kiểm tra lại số vừa nhập.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF991B1B),
                            ),
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
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.history_edu_rounded, color: Color(0xFF0F766E), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sổ Theo Dõi Chỉ Số Cá Nhân Của Bạn (Lưu Riêng Trên Thiết Bị)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                ),
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
          Flexible(
            child: Column(
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
          ),
        ],
      ),
    );
  }

  Uint8List? _decodeDataUrlBytes(String? dataUrl) {
    if (dataUrl == null || dataUrl.isEmpty) return null;
    final commaIndex = dataUrl.indexOf(',');
    if (commaIndex < 0 || commaIndex + 1 >= dataUrl.length) return null;
    try {
      return base64Decode(dataUrl.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }

  Future<void> _handlePickMeterPhoto(String meterType) async {
    final picked = await pickImageFile();
    if (!mounted) return;

    if (picked == null) {
      await _showManualOrSampleOcrDialog(meterType);
      return;
    }

    final isElec = meterType == 'electric';
    final bytes = _decodeDataUrlBytes(picked.dataUrl);
    final oldVal = int.tryParse(
          isElec ? _meterOldController.text.trim() : _waterOldController.text.trim(),
        ) ??
        (isElec ? 1420 : 84);

    setState(() {
      if (isElec) {
        _uploadedElectricDataUrl = picked.dataUrl;
        _electricPhotoLabel = picked.fileName;
      } else {
        _uploadedWaterDataUrl = picked.dataUrl;
        _waterPhotoLabel = picked.fileName;
      }
      _isScanningOcr = true;
      _showRoiOverlay = true;
      _ocrConfidence = 'Đang phân tích ảnh "${picked.fileName}" bằng AI Vision OCR...';
    });

    final nav = Navigator.of(context, rootNavigator: true);
    var loaderOpen = true;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(strokeWidth: 3),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'AI Vision OCR đang đọc chỉ số thực tế trên ảnh "${picked.fileName}"...',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ).whenComplete(() {
        loaderOpen = false;
      }),
    );

    Map<String, dynamic>? ocrRes;
    try {
      ocrRes = await ApiService().analyzeMeterOcr(
        dataUrl: picked.dataUrl,
        meterType: meterType,
        previousReading: oldVal,
      );
    } finally {
      if (mounted && loaderOpen && nav.canPop()) {
        nav.pop();
      }
    }

    if (!mounted) return;
    setState(() => _isScanningOcr = false);

    final suggestedReading =
        ocrRes != null && ocrRes['reading'] is num
            ? (ocrRes['reading'] as num).toInt()
            : null;
    final altReading =
        ocrRes != null && ocrRes['alternativeReading'] is num
            ? (ocrRes['alternativeReading'] as num).toInt()
            : null;
    final confNum =
        ocrRes != null && ocrRes['confidence'] is num
            ? (ocrRes['confidence'] as num).toDouble()
            : null;
    final providerName = (ocrRes?['provider'] ?? 'AI Vision OCR').toString();
    final confText = confNum != null
        ? '${confNum.toStringAsFixed(1)}% ($providerName)'
        : providerName;
    final ocrNote = (ocrRes?['note'] ?? '').toString();
    final ocrRawText = (ocrRes?['rawText'] ?? '').toString();

    await _showMeterOcrConfirmDialog(
      meterType: meterType,
      suggestedReading: suggestedReading,
      alternativeReading: altReading,
      ocrConfidenceLabel: confText,
      ocrNote: ocrNote,
      ocrRawText: ocrRawText,
      photoName: picked.fileName,
      imageBytes: bytes,
      isUnreadableImage: suggestedReading == null,
    );
  }

  Future<void> _showManualOrSampleOcrDialog(String meterType) async {
    final isElec = meterType == 'electric';
    final oldVal = int.tryParse(
          isElec ? _meterOldController.text : _waterOldController.text,
        ) ??
        (isElec ? 1420 : 84);
    final curVal = int.tryParse(
          isElec ? _meterNewController.text : _waterNewController.text,
        ) ??
        (oldVal + (isElec ? 120 : 8));

    await _showMeterOcrConfirmDialog(
      meterType: meterType,
      suggestedReading: curVal > oldVal ? curVal : oldVal + (isElec ? 120 : 8),
      photoName: isElec
          ? 'Mặt công tơ điện P.305'
          : 'Mặt đồng hồ nước P.305',
      imageBytes: _decodeDataUrlBytes(
        isElec ? _uploadedElectricDataUrl : _uploadedWaterDataUrl,
      ),
      isDirectEntry: true,
    );
  }

  Future<void> _showMeterOcrConfirmDialog({
    required String meterType,
    required int? suggestedReading,
    required String photoName,
    required Uint8List? imageBytes,
    int? alternativeReading,
    String? ocrConfidenceLabel,
    String? ocrNote,
    String? ocrRawText,
    bool isDirectEntry = false,
    bool isUnreadableImage = false,
  }) async {
    final isElec = meterType == 'electric';
    final unit = isElec ? 'kWh' : 'm³';
    final accentColor =
        isElec ? const Color(0xFF2563EB) : const Color(0xFF0284C7);
    final oldVal = double.tryParse(
          isElec ? _meterOldController.text : _waterOldController.text,
        ) ??
        (isElec ? 1420 : 84);
    final confirmController = TextEditingController(
      text: suggestedReading?.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final parsedNew = double.tryParse(confirmController.text.trim()) ??
              (suggestedReading?.toDouble() ?? oldVal);
          final used = parsedNew >= oldVal ? parsedNew - oldVal : 0.0;
          final cost = isElec
              ? TieredUtilityService.calculateElectricity(used).totalAmount
              : TieredUtilityService.calculateWater(used).totalAmount;

          final statusMessage = isDirectEntry
              ? 'Chưa chọn tệp ảnh từ thiết bị — bạn có thể kiểm tra hoặc nhập trực tiếp chỉ số trên mặt đồng hồ để tính tiền ngay.'
              : isUnreadableImage
                  ? 'Ảnh "$photoName" hơi mờ hoặc chưa lộ rõ dãy số đồng hồ. Vui lòng chụp sát khung số hơn hoặc nhập trực tiếp chỉ số bên dưới:'
                  : (ocrNote != null && ocrNote.isNotEmpty
                      ? '$ocrNote (${ocrConfidenceLabel ?? 'AI Vision OCR'})'
                      : 'AI Vision OCR đã phân tích ảnh "$photoName"${ocrRawText != null && ocrRawText.isNotEmpty ? ' → Raw: "$ocrRawText"' : ''} (${ocrConfidenceLabel ?? 'AI Vision OCR'}). Vui lòng kiểm tra trước khi xác nhận:');

          return AlertDialog(
            title: Text(
              isElec
                  ? '⚡ Xác nhận chỉ số Công Tơ Điện'
                  : '💧 Xác nhận chỉ số Đồng Hồ Nước',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageBytes != null
                        ? Image.memory(
                            imageBytes,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : _buildDigitalMeterMockDisplay(
                            meterType: meterType,
                            readingValueText: confirmController.text.trim().isEmpty
                                ? (suggestedReading?.toString() ?? '${oldVal.toInt()}')
                                : confirmController.text.trim(),
                            unitLabel: unit,
                            photoLabel: photoName,
                            accentColor: accentColor,
                            height: 120,
                          ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isUnreadableImage
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isUnreadableImage
                            ? const Color(0xFFFECACA)
                            : const Color(0xFFBBF7D0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isUnreadableImage
                              ? Icons.warning_amber_rounded
                              : Icons.auto_awesome_rounded,
                          size: 16,
                          color: isUnreadableImage
                              ? const Color(0xFFB91C1C)
                              : const Color(0xFF15803D),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            statusMessage,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isUnreadableImage
                                  ? const Color(0xFF991B1B)
                                  : const Color(0xFF166534),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (alternativeReading != null &&
                      suggestedReading != null &&
                      alternativeReading != suggestedReading) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.looks_4_rounded, size: 15),
                          label: Text(
                            'Phần nguyên: $suggestedReading $unit',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onPressed: () {
                            setDialogState(() {
                              confirmController.text = '$suggestedReading';
                            });
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.palette_rounded, size: 15, color: Color(0xFFDC2626)),
                          label: Text(
                            'Gồm cả ô đỏ: $alternativeReading',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onPressed: () {
                            setDialogState(() {
                              confirmController.text = '$alternativeReading';
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Chỉ số mới đọc được ($unit)',
                      helperText:
                          'Chỉ số kỳ trước (05/10): ${oldVal.toInt()} $unit',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tiêu thụ tạm tính: ${used.toStringAsFixed(0)} $unit',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tiền ${isElec ? 'điện' : 'nước'} tạm tính: ${AppFormatters.currency(cost)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Hủy'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                icon: const Icon(Icons.check_circle_outline,
                    size: 16, color: Colors.white),
                label: const Text(
                  'Xác nhận & Tính tiền',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  final rawText = confirmController.text.trim();
                  final finalVal = int.tryParse(rawText) ?? suggestedReading ?? oldVal.toInt();
                  setState(() {
                    _lastLocalMeterEdit = DateTime.now();
                    if (isElec) {
                      _meterNewController.text = '$finalVal';
                    } else {
                      _waterNewController.text = '$finalVal';
                    }
                    _showCalculationDetail = true;
                    _showRoiOverlay = true;
                    _ocrConfidence = (ocrConfidenceLabel != null && ocrConfidenceLabel.isNotEmpty)
                        ? ocrConfidenceLabel
                        : (isDirectEntry
                            ? 'Chỉ số đồng hồ đã xác nhận thủ công'
                            : 'Đã xác nhận chỉ số từ ảnh');
                  });

                  final includeElectric =
                      _ocrMode == 'electric' || _ocrMode == 'both';
                  final includeWater =
                      _ocrMode == 'water' || _ocrMode == 'both';
                  final elecOld =
                      double.tryParse(_meterOldController.text) ?? 1420;
                  final elecNew =
                      double.tryParse(_meterNewController.text) ?? 1540;
                  final waterOld =
                      double.tryParse(_waterOldController.text) ?? 84;
                  final waterNew =
                      double.tryParse(_waterNewController.text) ?? 92;
                  final elecUsed =
                      includeElectric && elecNew >= elecOld ? elecNew - elecOld : 0.0;
                  final waterUsed = includeWater && waterNew >= waterOld
                      ? waterNew - waterOld
                      : 0.0;
                  final totalEstimatedCost = (includeElectric
                          ? TieredUtilityService.calculateElectricity(elecUsed)
                              .totalAmount
                          : 0.0) +
                      (includeWater
                          ? TieredUtilityService.calculateWater(waterUsed)
                              .totalAmount
                          : 0.0);

                  _pushResidentMeterToCloud(
                    totalEstimatedCost: totalEstimatedCost,
                  );
                  Navigator.pop(dialogCtx);
                  _showMessage(
                    'Đã cập nhật chỉ số ${isElec ? "Công Tơ Điện" : "Đồng Hồ Nước"}: $finalVal $unit • Tổng tiền tạm tính hiện tại: ${AppFormatters.currency(totalEstimatedCost)}.',
                  );
                },
              ),
            ],
          );
        },
      ),
    );
    confirmController.dispose();
  }

  Widget _buildDigitalMeterMockDisplay({
    required String meterType,
    required String readingValueText,
    required String unitLabel,
    required String photoLabel,
    required Color accentColor,
    required double height,
  }) {
    final isElec = meterType == 'electric';
    final paddedDigits = readingValueText.padLeft(5, '0');
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isElec
              ? const [Color(0xFF0F172A), Color(0xFF1E293B)]
              : const [Color(0xFF0C4A6E), Color(0xFF0369A1)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isElec ? Icons.electric_meter_rounded : Icons.water_drop_rounded,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  photoLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isElec ? 'SMART METER 220V' : 'DN15 FLOW METER',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isElec
                      ? const Color(0xFF14532D)
                      : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < paddedDigits.length; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isElec
                              ? const Color(0xFF166534)
                              : (i == paddedDigits.length - 1
                                  ? const Color(0xFFB91C1C)
                                  : const Color(0xFF1E293B)),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white24, width: 0.7),
                        ),
                        child: Text(
                          paddedDigits[i],
                          style: const TextStyle(
                            color: Color(0xFFECFDF5),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      unitLabel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Chế độ mô phỏng số • Bấm nút dưới để tải ảnh thật',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white60, fontSize: 9.5),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$readingValueText $unitLabel',
                style: const TextStyle(
                  color: Color(0xFF86EFAC),
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarketplaceImage(String imageUrl, {double height = 170}) {
    if (imageUrl.startsWith('data:image')) {
      final bytes = _decodeDataUrlBytes(imageUrl);
      if (bytes != null) {
        return Image.memory(
          bytes,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    }
    return Image.network(
      imageUrl,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        height: 140,
        color: const Color(0xFFF1F5F9),
        child: const Center(child: Icon(Icons.shopping_bag_outlined, size: 48)),
      ),
    );
  }

  Widget _buildMeterPhotoUploadBox({
    required String title,
    required String meterType,
    required String? customDataUrl,
    required String photoLabel,
    required String readingValueText,
    required String unitLabel,
    required Color accentColor,
    required VoidCallback onCaptureOrUpload,
    VoidCallback? onResetPhoto,
  }) {
    final readingBadge = '$readingValueText $unitLabel';
    final previewHeight = _ocrMode == 'both' ? 140.0 : 195.0;
    final customBytes = _decodeDataUrlBytes(customDataUrl);

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
              const SizedBox(width: 6),
              _buildPillBadge(
                'AI đọc: $readingBadge',
                accentColor,
                Colors.white,
              ),
              if (onResetPhoto != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: onResetPhoto,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: customBytes != null
                    ? Image.memory(
                        customBytes,
                        height: previewHeight,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _buildDigitalMeterMockDisplay(
                          meterType: meterType,
                          readingValueText: readingValueText,
                          unitLabel: unitLabel,
                          photoLabel: photoLabel,
                          accentColor: accentColor,
                          height: previewHeight,
                        ),
                      )
                    : _buildDigitalMeterMockDisplay(
                        meterType: meterType,
                        readingValueText: readingValueText,
                        unitLabel: unitLabel,
                        photoLabel: photoLabel,
                        accentColor: accentColor,
                        height: previewHeight,
                      ),
              ),
              if (_showRoiOverlay && customBytes != null)
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
              label: Text(
                customBytes != null
                    ? 'Đổi ảnh mới ($photoLabel)'
                    : 'Chụp ảnh mới / Tải ảnh từ máy lên',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
              Expanded(
                child: Text(
                  'Cộng thành tiền (${result.totalQuantity.toStringAsFixed(0)} $unitLabel):',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  AppFormatters.currency(result.totalAmount),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
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
      _buildSectionHeaderCard(
        badges: [
          _buildPillBadge('ECO-COMMUNITY', const Color(0xFF16A34A), Colors.white),
          _buildPillBadge('Nội Khu Co-Living', const Color(0xFFEEF2FF), const Color(0xFF4F46E5)),
        ],
        title: 'Sàn Trao Đổi Đồ Dùng & Đồ Cũ Sinh Viên (Eco-Marketplace)',
        subtitle:
            'Nơi cư dân các phòng pass lại đồ gia dụng, bàn học, quạt, giáo trình còn mới với giá rẻ hoặc tặng miễn phí (0đ). 100% người bán là cư dân đã xác minh.',
        actionButton: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
          icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
          label: const Text('Đăng Bán / Tặng Đồ Cũ', style: TextStyle(fontSize: 12, color: Colors.white)),
          onPressed: _showCreateListing,
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
        final hasVideo = item.videoUrl != null && item.videoUrl!.isNotEmpty;
        final avgRating = item.reviews.isEmpty
            ? item.rating
            : item.reviews.fold<int>(0, (sum, r) => sum + r.stars) /
                item.reviews.length;
        final latestReview = item.reviews.isNotEmpty ? item.reviews.first : null;
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
                  _buildMarketplaceImage(item.imageUrl),
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
                  if (hasVideo)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: InkWell(
                        onTap: () =>
                            _showVideoPreviewDialog(item.title, item.videoUrl!),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.78),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_circle_fill_rounded,
                                color: Colors.redAccent,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Xem Video',
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
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ...List.generate(5, (i) {
                          return Icon(
                            i < avgRating.round()
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 16,
                            color: const Color(0xFFF59E0B),
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          avgRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '(${item.reviews.length} đánh giá)',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    if (latestReview != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          '💬 ${latestReview.reviewer} (${latestReview.room}): "${latestReview.comment}"',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isFree ? 'Giá trao đổi:' : 'Giá pass lại:',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Wrap(
                                spacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    isFree
                                        ? '0 VNĐ (Miễn Phí)'
                                        : AppFormatters.currency(
                                            item.price.toDouble(),
                                          ),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isFree
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFDC2626),
                                    ),
                                  ),
                                  if (!isFree && item.originalPrice > 0)
                                    Text(
                                      AppFormatters.currency(
                                        item.originalPrice.toDouble(),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            backgroundColor: _claimedListings.contains(item.title)
                                ? const Color(0xFF64748B)
                                : const Color(0xFF16A34A),
                          ),
                          icon: Icon(
                            _claimedListings.contains(item.title)
                                ? Icons.check_circle_rounded
                                : (isFree
                                    ? Icons.card_giftcard_rounded
                                    : Icons.add_shopping_cart_rounded),
                            size: 15,
                            color: Colors.white,
                          ),
                          label: Text(
                            _claimedListings.contains(item.title)
                                ? '✓ Đã Giữ Chỗ'
                                : (isFree ? 'Xin Nhận' : 'Nhắn Mua'),
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                          ),
                          onPressed: _claimedListings.contains(item.title)
                              ? null
                              : () {
                                  setState(() => _claimedListings.add(item.title));
                                  _showMessage(
                                    isFree
                                        ? 'Đã đặt giữ chỗ nhận miễn phí "${item.title}" từ bạn ${item.sellerName}!'
                                        : 'Đã đặt giữ chỗ & kết nối chat trực tiếp với ${item.sellerName}!',
                                  );
                                },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showMarketplaceReviewDialog(item),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            side: const BorderSide(color: Color(0xFFF59E0B)),
                          ),
                          icon: const Icon(
                            Icons.star_rate_rounded,
                            size: 17,
                            color: Color(0xFFD97706),
                          ),
                          label: const Text(
                            'Đánh giá & Bình luận',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB45309),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => showSmartStayCallModal(
                            context,
                            initialTargetRole: 'CuDan',
                            initialTargetName: item.sellerName,
                            initialVideo: true,
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            side: const BorderSide(color: Color(0xFF4F46E5)),
                          ),
                          icon: const Icon(
                            Icons.videocam_rounded,
                            size: 17,
                            color: Color(0xFF4F46E5),
                          ),
                          label: const Text(
                            'Gọi / Video',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4F46E5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (hasVideo)
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showVideoPreviewDialog(item.title, item.videoUrl!),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              side: const BorderSide(color: Color(0xFFDC2626)),
                            ),
                            icon: const Icon(
                              Icons.play_circle_outline_rounded,
                              size: 17,
                              color: Color(0xFFDC2626),
                            ),
                            label: const Text(
                              'Xem Video',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.w600,
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

  Future<void> _showVideoPreviewDialog(String title, String videoUrl) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Video thực tế: $title',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_rounded, color: Colors.lightBlueAccent, size: 42),
                  SizedBox(height: 8),
                  Text(
                    'Video HD kiểm tra sản phẩm đã đồng bộ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Sẵn sàng phát luồng media kiểm tra tình trạng thực tế',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Nguồn Video: ${videoUrl.length > 52 ? '${videoUrl.substring(0, 52)}...' : videoUrl}',
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _showMarketplaceReviewDialog(_MarketListing item) async {
    int selectedStars = 5;
    final commentCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            'Đánh giá: ${item.title}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (item.reviews.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Chưa có bình luận nào. Hãy để lại đánh giá đầu tiên!',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  )
                else
                  ...item.reviews.map(
                    (rev) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${rev.reviewer} (${rev.room})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${'★' * rev.stars} • ${rev.time}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFD97706),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(rev.comment, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                const Divider(),
                const Text(
                  'Chọn số sao của bạn:',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return InkWell(
                      onTap: () => setDialogState(() => selectedStars = star),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          star <= selectedStars
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFF59E0B),
                          size: 30,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bình luận chi tiết *',
                    hintText: 'Đồ còn mới, đúng mô tả, người bán thân thiện...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Đóng'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                minimumSize: const Size(0, 44),
              ),
              icon: const Icon(Icons.send_rounded, size: 15, color: Colors.white),
              label: const Text('Gửi Đánh Giá', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                final text = commentCtrl.text.trim();
                if (text.isEmpty) return;
                final auth = context.read<AuthProvider>();
                final reviewer = auth.user?.fullName ?? 'Hồ Ngọc Bảo';
                final room = auth.user?.effectiveRoomCode ?? 'P.305';
                final idx = _listings.indexOf(item);
                if (idx >= 0) {
                  final updatedReviews = [
                    _MarketReview(
                      reviewer: reviewer,
                      room: room,
                      stars: selectedStars,
                      comment: text,
                      time: 'Vừa xong',
                    ),
                    ...item.reviews,
                  ];
                  final newAvg = updatedReviews.fold<int>(0, (s, r) => s + r.stars) /
                      updatedReviews.length;
                  setState(() {
                    _listings[idx] = item.copyWith(
                      rating: newAvg,
                      reviews: updatedReviews,
                    );
                  });
                }
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                _showMessage('Đã gửi đánh giá $selectedStars sao & bình luận chi tiết!');
                await ApiService().postSyncMarketplaceReview({
                  'MaTin': item.id ?? 'MKT-001',
                  'TieuDeFallback': item.title,
                  'NguoiDanhGia': reviewer,
                  'KyHieuPhong': room,
                  'SoSao': selectedStars,
                  'BinhLuan': text,
                });
              },
            ),
          ],
        ),
      ),
    );
    commentCtrl.dispose();
  }

  Future<void> _showCreateListing() async {
    _listingTitleController.clear();
    _listingDescriptionController.clear();
    _listingPriceController.text = '50000';
    _listingCategory = 'Điện gia dụng';
    String? pickedDataUrl;
    String? pickedFileName;
    String? pickedVideoUrl;
    String? pickedVideoName;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final previewBytes = _decodeDataUrlBytes(pickedDataUrl);
          return AlertDialog(
            title: const Text(
              'Đăng Đồ Cũ Kèm Ảnh & Video',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  const SizedBox(height: 12),
                  if (previewBytes != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        previewBytes,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await pickMediaFile(
                        acceptVideo: false,
                        useCamera: true,
                      );
                      if (picked == null || !dialogCtx.mounted) return;
                      setDialogState(() {
                        pickedDataUrl = picked.dataUrl;
                        pickedFileName = picked.fileName;
                      });
                    },
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 17),
                    label: Text(
                      pickedFileName == null
                          ? 'Chụp / Tải ảnh sản phẩm'
                          : 'Đổi ảnh ($pickedFileName)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (pickedVideoUrl != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.videocam_rounded, color: Color(0xFFDC2626), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Đã gắn Video: ${pickedVideoName ?? 'Clip sản phẩm HD'}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await pickMediaFile(
                            acceptVideo: true,
                            useCamera: true,
                          );
                          if (picked == null || !dialogCtx.mounted) return;
                          setDialogState(() {
                            pickedVideoUrl = picked.dataUrl;
                            pickedVideoName = picked.fileName;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          side: const BorderSide(color: Color(0xFFDC2626)),
                        ),
                        icon: const Icon(Icons.video_library_rounded, size: 17, color: Color(0xFFDC2626)),
                        label: const Text(
                          'Tải / Quay Video',
                          style: TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            pickedVideoUrl =
                                'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4';
                            pickedVideoName = 'Quay_kiem_tra_thuc_te.mp4';
                          });
                        },
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                        icon: const Icon(Icons.fiber_manual_record_rounded, size: 15, color: Colors.red),
                        label: const Text(
                          'Gắn Video mẫu (4s)',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Hủy')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  minimumSize: const Size(0, 44),
                ),
                icon: const Icon(Icons.sell_rounded, size: 15, color: Colors.white),
                label: const Text('Đăng Lên Chợ Cư Dân', style: TextStyle(color: Colors.white)),
                onPressed: () async {
                  final title = _listingTitleController.text.trim();
                  final desc = _listingDescriptionController.text.trim();
                  final price = int.tryParse(_listingPriceController.text.replaceAll('.', '')) ?? 0;
                  if (title.isEmpty) return;

                  final auth = context.read<AuthProvider>();
                  final room = auth.user?.effectiveRoomCode ?? 'P.305';
                  final seller = '${auth.user?.fullName ?? 'Hồ Ngọc Bảo'} ($room)';
                  final effectiveImg = pickedDataUrl ??
                      'https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?auto=format&fit=crop&w=600&q=80';
                  final effectiveDesc = desc.isEmpty
                      ? 'Còn mới tốt, liên hệ nhận tại sảnh tòa nhà.'
                      : desc;
                  final newId = 'MKT-${DateTime.now().millisecondsSinceEpoch % 9000 + 1000}';

                  setState(() {
                    _listings.insert(
                      0,
                      _MarketListing(
                        title,
                        _listingCategory,
                        price,
                        0,
                        room,
                        seller,
                        'Mới đăng',
                        effectiveDesc,
                        effectiveImg,
                        id: newId,
                        videoUrl: pickedVideoUrl,
                      ),
                    );
                  });
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  _showMessage('Đã đăng món đồ "$title" lên sàn trao đổi nội khu!');

                  await ApiService().postSyncMarketplaceItem({
                    'MaTin': newId,
                    'TieuDe': title,
                    'DanhMuc': _listingCategory == 'Tặng miễn phí'
                        ? 'free'
                        : (_listingCategory == 'Bàn ghế & sách' ? 'study' : 'electronics'),
                    'GiaBan': price,
                    'GiaGoc': price > 0 ? (price * 1.8).round() : 0,
                    'KyHieuPhong': room,
                    'NguoiBan': seller,
                    'TinhTrang': 'Mới đăng',
                    'MoTa': effectiveDesc,
                    'HinhAnhUrl': effectiveImg,
                    'VideoUrl': pickedVideoUrl,
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeaderCard({
    required List<Widget> badges,
    required String title,
    required String subtitle,
    required Widget actionButton,
  }) {
    final isCompact = MediaQuery.of(context).size.width < 600;
    final infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 8, runSpacing: 6, children: badges),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoColumn,
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: actionButton),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: infoColumn),
                const SizedBox(width: 12),
                actionButton,
              ],
            ),
    );
  }

  Widget _buildComparisonRow({
    required String label,
    required TextStyle labelStyle,
    required Widget trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: labelStyle)),
        const SizedBox(width: 8),
        Flexible(child: trailing),
      ],
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
  int stayDays;
  double customRatio;

  _RoommateShare({
    required this.name,
    required this.roleBadge,
    required this.mssv,
    required this.code,
    required this.isPaid,
    this.stayDays = 30,
    this.customRatio = 0.333,
  });
}

class _GuestPass {
  final String name;
  final String phone;
  final String duration;
  final String pin;
  const _GuestPass(this.name, this.phone, this.duration, this.pin);
}

class _MarketReview {
  final String reviewer;
  final String room;
  final int stars;
  final String comment;
  final String time;

  const _MarketReview({
    required this.reviewer,
    required this.room,
    required this.stars,
    required this.comment,
    required this.time,
  });
}

class _MarketListing {
  final String? id;
  final String title;
  final String category;
  final int price;
  final int originalPrice;
  final String room;
  final String sellerName;
  final String conditionBadge;
  final String description;
  final String imageUrl;
  final String? videoUrl;
  final double rating;
  final List<_MarketReview> reviews;

  const _MarketListing(
    this.title,
    this.category,
    this.price,
    this.originalPrice,
    this.room,
    this.sellerName,
    this.conditionBadge,
    this.description,
    this.imageUrl, {
    this.id,
    this.videoUrl,
    this.rating = 5.0,
    this.reviews = const [],
  });

  _MarketListing copyWith({
    double? rating,
    List<_MarketReview>? reviews,
    String? videoUrl,
  }) {
    return _MarketListing(
      title,
      category,
      price,
      originalPrice,
      room,
      sellerName,
      conditionBadge,
      description,
      imageUrl,
      id: id,
      videoUrl: videoUrl ?? this.videoUrl,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
    );
  }
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
