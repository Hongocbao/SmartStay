import 'package:flutter/foundation.dart';
import '../models/admin_models.dart';
import '../models/invoice_model.dart';
import '../models/managed_contract_model.dart';
import '../services/invoice_data_service.dart';
import '../services/supabase_direct_service.dart';

class AdminProvider extends ChangeNotifier {
  final InvoiceDataService _invoiceDataService = InvoiceDataService();
  final SupabaseDirectService _supabase = SupabaseDirectService();
  DateTime? _lastSyncedAt;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  List<RoomItemModel> _rooms = [];
  List<StaffModel> _staffList = [];
  List<AccessLogModel> _accessLogs = [];
  final List<CheckOutSettlementModel> _settlements = [];
  final List<ManagedContractModel> _contracts = [];
  bool _isLoading = false;

  List<RoomItemModel> get rooms => _rooms;
  List<StaffModel> get staffList => _staffList;
  List<AccessLogModel> get accessLogs => _accessLogs;
  List<InvoiceModel> get allInvoices => _invoiceDataService.allInvoices;
  List<CheckOutSettlementModel> get settlements => _settlements;
  List<ManagedContractModel> get contracts => List.unmodifiable(_contracts);
  bool get isLoading => _isLoading;

  AdminProvider() {
    _invoiceDataService.addListener(_onInvoicesChanged);
    _initMockData();
    syncWithCloudSupabase();
  }

  /// Đồng bộ dữ liệu thời gian thực từ Supabase (Phương án A) & Web Admin (smartstay-admin)
  Future<bool> syncWithCloudSupabase() async {
    final snapshot = await _supabase.fetchUnifiedSnapshot();
    if (snapshot == null) return false;

    final rawRooms = snapshot['phongs'];
    if (rawRooms is List && rawRooms.isNotEmpty) {
      bool changed = false;
      for (final item in rawRooms) {
        if (item is! Map) continue;
        final code = (item['kyHieuPhong'] ?? item['KyHieuPhong'] ?? '').toString().trim();
        final status = (item['trangThai'] ?? item['TrangThai'] ?? '').toString().trim();
        final priceRaw = item['giaThue'] ?? item['GiaThue'];
        if (code.isEmpty || status.isEmpty) continue;

        final idx = _rooms.indexWhere((r) => r.roomCode.toUpperCase() == code.toUpperCase());
        if (idx != -1) {
          final current = _rooms[idx];
          final newPrice = priceRaw is num ? priceRaw.toDouble() : current.rentPrice;
          if (current.status != status || current.rentPrice != newPrice) {
            _rooms[idx] = current.copyWith(status: status, rentPrice: newPrice);
            changed = true;
          }
        }
      }
      _lastSyncedAt = DateTime.now();
      if (changed) {
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  void _onInvoicesChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _invoiceDataService.removeListener(_onInvoicesChanged);
    super.dispose();
  }

  void _initMockData() {
    // 20 phòng mẫu trải dài 5 tầng
    _rooms = [
      // Tầng 1 (Shophouse / Studio)
      RoomItemModel(
        roomId: 101,
        roomCode: 'P.101',
        buildingName: 'Tòa nhà A',
        floor: 1,
        roomType: 'Studio Deluxe',
        area: 32.5,
        capacity: 2,
        rentPrice: 4500000,
        status: 'Đang ở',
        residentName: 'Nguyễn Văn An',
        residentPhone: '0912345678',
        contractCode: 'HD-2026-0101',
        depositAmount: 9000000,
        lastElectricIndex: 1450,
        lastWaterIndex: 52,
        smartLockBattery: 95,
      ),
      RoomItemModel(
        roomId: 102,
        roomCode: 'P.102',
        buildingName: 'Tòa nhà A',
        floor: 1,
        roomType: 'Studio Deluxe',
        area: 32.5,
        capacity: 2,
        rentPrice: 4500000,
        status: 'Trống',
        smartLockBattery: 88,
      ),
      RoomItemModel(
        roomId: 103,
        roomCode: 'P.103',
        buildingName: 'Tòa nhà A',
        floor: 1,
        roomType: 'Co-Living Đơn',
        area: 25.0,
        capacity: 1,
        rentPrice: 3200000,
        status: 'Đang ở',
        residentName: 'Lê Thị Thu',
        residentPhone: '0934567890',
        contractCode: 'HD-2026-0103',
        depositAmount: 6400000,
        lastElectricIndex: 980,
        lastWaterIndex: 38,
        smartLockBattery: 90,
      ),
      RoomItemModel(
        roomId: 104,
        roomCode: 'P.104',
        buildingName: 'Tòa nhà A',
        floor: 1,
        roomType: 'Co-Living Đơn',
        area: 25.0,
        capacity: 1,
        rentPrice: 3200000,
        status: 'Bảo trì',
        smartLockBattery: 78,
      ),

      // Tầng 2
      RoomItemModel(
        roomId: 201,
        roomCode: 'P.201',
        buildingName: 'Tòa nhà A',
        floor: 2,
        roomType: 'Co-Living Đôi',
        area: 28.0,
        capacity: 2,
        rentPrice: 3800000,
        status: 'Đang ở',
        residentName: 'Phạm Quốc Hùng',
        residentPhone: '0945678901',
        contractCode: 'HD-2026-0201',
        depositAmount: 7600000,
        lastElectricIndex: 1120,
        lastWaterIndex: 45,
        smartLockBattery: 94,
      ),
      RoomItemModel(
        roomId: 202,
        roomCode: 'P.202',
        buildingName: 'Tòa nhà A',
        floor: 2,
        roomType: 'Co-Living Đôi',
        area: 28.0,
        capacity: 2,
        rentPrice: 3800000,
        status: 'Đã đặt',
        residentName: 'Hoàng Kim Yến',
        residentPhone: '0967890123',
        contractCode: 'DC-2026-0202',
        depositAmount: 2000000,
        smartLockBattery: 91,
      ),
      RoomItemModel(
        roomId: 203,
        roomCode: 'P.203',
        buildingName: 'Tòa nhà A',
        floor: 2,
        roomType: 'Co-Living Đơn',
        area: 24.0,
        capacity: 1,
        rentPrice: 3200000,
        status: 'Trống',
        smartLockBattery: 85,
      ),
      RoomItemModel(
        roomId: 204,
        roomCode: 'P.204',
        buildingName: 'Tòa nhà A',
        floor: 2,
        roomType: 'Co-Living Đôi',
        area: 28.0,
        capacity: 2,
        rentPrice: 3800000,
        status: 'Đang ở',
        residentName: 'Đặng Thanh Bình',
        residentPhone: '0978901234',
        contractCode: 'HD-2026-0204',
        depositAmount: 7600000,
        lastElectricIndex: 1340,
        lastWaterIndex: 49,
        smartLockBattery: 89,
      ),

      // Tầng 3
      RoomItemModel(
        roomId: 301,
        roomCode: 'P.301',
        buildingName: 'Tòa nhà A',
        floor: 3,
        roomType: 'Studio VIP',
        area: 35.0,
        capacity: 2,
        rentPrice: 5000000,
        status: 'Đang ở',
        residentName: 'Vũ Minh Đức',
        residentPhone: '0989012345',
        contractCode: 'HD-2026-0301',
        depositAmount: 10000000,
        lastElectricIndex: 1600,
        lastWaterIndex: 60,
        smartLockBattery: 96,
      ),
      RoomItemModel(
        roomId: 302,
        roomCode: 'P.302',
        buildingName: 'Tòa nhà A',
        floor: 3,
        roomType: 'Co-Living Đơn',
        area: 24.0,
        capacity: 1,
        rentPrice: 3200000,
        status: 'Trống',
        smartLockBattery: 82,
      ),
      RoomItemModel(
        roomId: 305,
        roomCode: 'P.305',
        buildingName: 'Tòa nhà A',
        floor: 3,
        roomType: 'Co-Living 3 Giường (Nam)',
        area: 28.0,
        capacity: 3,
        rentPrice: 3500000,
        status: 'Đang ở',
        residentName: 'Hồ Ngọc Bảo + 2 bạn',
        residentPhone: '0901234567',
        contractCode: 'HD-2026-0305',
        depositAmount: 7000000,
        lastElectricIndex: 1200,
        lastWaterIndex: 40,
        smartLockBattery: 92,
      ),
      RoomItemModel(
        roomId: 306,
        roomCode: 'P.306',
        buildingName: 'Tòa nhà A',
        floor: 3,
        roomType: 'Co-Living Ban Công',
        area: 28.0,
        capacity: 2,
        rentPrice: 3500000,
        status: 'Bảo trì',
        smartLockBattery: 74,
      ),

      // Tầng 4
      RoomItemModel(
        roomId: 401,
        roomCode: 'P.401',
        buildingName: 'Tòa nhà A',
        floor: 4,
        roomType: 'Co-Living Đơn',
        area: 24.0,
        capacity: 1,
        rentPrice: 3200000,
        status: 'Đang ở',
        residentName: 'Bùi Thị Hà',
        residentPhone: '0919123456',
        contractCode: 'HD-2026-0401',
        depositAmount: 6400000,
        lastElectricIndex: 890,
        lastWaterIndex: 32,
        smartLockBattery: 97,
      ),
      RoomItemModel(
        roomId: 402,
        roomCode: 'P.402',
        buildingName: 'Tòa nhà A',
        floor: 4,
        roomType: 'Co-Living Đơn',
        area: 24.0,
        capacity: 1,
        rentPrice: 3200000,
        status: 'Trống',
        smartLockBattery: 90,
      ),
      RoomItemModel(
        roomId: 403,
        roomCode: 'P.403',
        buildingName: 'Tòa nhà A',
        floor: 4,
        roomType: 'Studio Ban Công',
        area: 32.0,
        capacity: 2,
        rentPrice: 4600000,
        status: 'Đang ở',
        residentName: 'Mai Văn Dũng',
        residentPhone: '0928234567',
        contractCode: 'HD-2026-0403',
        depositAmount: 9200000,
        lastElectricIndex: 1310,
        lastWaterIndex: 44,
        smartLockBattery: 89,
      ),
      RoomItemModel(
        roomId: 404,
        roomCode: 'P.404',
        buildingName: 'Tòa nhà A',
        floor: 4,
        roomType: 'Studio Ban Công',
        area: 32.0,
        capacity: 2,
        rentPrice: 4600000,
        status: 'Đã đặt',
        residentName: 'Trịnh Cẩm Tú',
        residentPhone: '0937345678',
        contractCode: 'DC-2026-0404',
        depositAmount: 2000000,
        smartLockBattery: 93,
      ),

      // Tầng 5 (Penthouse / Sky Garden)
      RoomItemModel(
        roomId: 501,
        roomCode: 'P.501',
        buildingName: 'Tòa nhà A',
        floor: 5,
        roomType: 'Sky View Penthouse',
        area: 48.0,
        capacity: 3,
        rentPrice: 7500000,
        status: 'Đang ở',
        residentName: 'Đoàn Hải Nam',
        residentPhone: '0946456789',
        contractCode: 'HD-2026-0501',
        depositAmount: 15000000,
        lastElectricIndex: 2100,
        lastWaterIndex: 85,
        smartLockBattery: 98,
      ),
      RoomItemModel(
        roomId: 502,
        roomCode: 'P.502',
        buildingName: 'Tòa nhà A',
        floor: 5,
        roomType: 'Sky View Penthouse',
        area: 48.0,
        capacity: 3,
        rentPrice: 7500000,
        status: 'Trống',
        smartLockBattery: 91,
      ),
      RoomItemModel(
        roomId: 503,
        roomCode: 'P.503',
        buildingName: 'Tòa nhà A',
        floor: 5,
        roomType: 'Co-Living Sky View',
        area: 30.0,
        capacity: 2,
        rentPrice: 4200000,
        status: 'Đang ở',
        residentName: 'Lý Quốc Cường',
        residentPhone: '0955567890',
        contractCode: 'HD-2026-0503',
        depositAmount: 8400000,
        lastElectricIndex: 1250,
        lastWaterIndex: 42,
        smartLockBattery: 86,
      ),
      RoomItemModel(
        roomId: 504,
        roomCode: 'P.504',
        buildingName: 'Tòa nhà A',
        floor: 5,
        roomType: 'Co-Living Sky View',
        area: 30.0,
        capacity: 2,
        rentPrice: 4200000,
        status: 'Bảo trì',
        smartLockBattery: 65,
      ),
    ];

    _staffList = [
      StaffModel(
        staffId: 1,
        fullName: 'Nguyễn Hoàng Nam',
        role: 'Quản trị viên',
        phone: '0988112233',
        email: 'nam.nh@smartstay.vn',
      ),
      StaffModel(
        staffId: 2,
        fullName: 'Trần Văn Tuấn',
        role: 'Kỹ thuật viên',
        phone: '0977223344',
        email: 'tuan.tv@smartstay.vn',
      ),
      StaffModel(
        staffId: 3,
        fullName: 'Lê Minh Khang',
        role: 'Kỹ thuật viên',
        phone: '0966334455',
        email: 'khang.lm@smartstay.vn',
      ),
      StaffModel(
        staffId: 4,
        fullName: 'Đỗ Thị Ngọc Mai',
        role: 'Lễ tân & Chăm sóc cư dân',
        phone: '0955445566',
        email: 'mai.dtn@smartstay.vn',
      ),
    ];

    _accessLogs = [
      AccessLogModel(
        logId: 1,
        roomCode: 'P.305',
        personName: 'Hồ Ngọc Bảo',
        method: 'Vân tay',
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
        isSuccess: true,
      ),
      AccessLogModel(
        logId: 2,
        roomCode: 'P.305',
        personName: 'Trần Văn Tuấn (Kỹ thuật)',
        method: 'Thẻ từ RFID Master',
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
        isSuccess: true,
      ),
      AccessLogModel(
        logId: 3,
        roomCode: 'P.101',
        personName: 'Nguyễn Văn An',
        method: 'Mở từ xa qua App',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        isSuccess: true,
      ),
      AccessLogModel(
        logId: 4,
        roomCode: 'P.501',
        personName: 'Đoàn Hải Nam',
        method: 'Mã PIN cá nhân',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isSuccess: true,
      ),
      AccessLogModel(
        logId: 5,
        roomCode: 'P.201',
        personName: 'Người lạ (Sai vân tay)',
        method: 'Vân tay',
        timestamp: DateTime.now().subtract(const Duration(hours: 7)),
        isSuccess: false,
      ),
    ];

    _initContractsFromRooms();
  }

  void _initContractsFromRooms() {
    _contracts.clear();
    final now = DateTime.now();
    int i = 0;
    for (final r in _rooms.where((rm) => rm.status == 'Đang ở')) {
      final isExpiringDemo = r.roomCode == 'P.303' || r.roomCode == 'P.203';
      final start = isExpiringDemo
          ? now.subtract(const Duration(days: 358))
          : DateTime(now.year, (now.month - (i % 5) - 1).clamp(1, 12), 1);
      final end = isExpiringDemo
          ? now.add(const Duration(days: 7))
          : DateTime(start.year + 1, start.month, start.day);
      _contracts.add(
        ManagedContractModel(
          contractCode: r.contractCode ?? 'HD-2026-0${r.roomId}',
          roomId: r.roomId,
          roomCode: r.roomCode,
          residentName: r.residentName ?? 'Cư dân',
          residentPhone: r.residentPhone ?? '0901234567',
          nationalId: '07920300${(1234 + i).toString().padLeft(4, '0')}',
          startDate: start,
          endDate: end,
          monthlyRent: r.rentPrice,
          depositAmount: r.depositAmount > 0 ? r.depositAmount : r.rentPrice * 2,
          status: 'Đang hiệu lực',
        ),
      );
      i++;
    }
  }

  DashboardSummaryModel get summary {
    final total = _rooms.length;
    final occupied = _rooms.where((r) => r.status == 'Đang ở').length;
    final empty = _rooms.where((r) => r.status == 'Trống').length;
    final maintenance = _rooms.where((r) => r.status == 'Bảo trì').length;
    final reserved = _rooms.where((r) => r.status == 'Đã đặt').length;
    final rate = total > 0 ? (occupied / total) * 100 : 0.0;

    double rev = 0;
    for (var r in _rooms.where((r) => r.status == 'Đang ở')) {
      rev += r.rentPrice;
    }

    final uncollected = allInvoices.where((i) => i.status == 'Chờ thanh toán' || i.status == 'Chờ đối soát' || i.status == 'Thanh toán một phần').toList();
    final double uncollectedTotal = uncollected.fold(0, (sum, i) => sum + (i.totalAmount - i.paidAmount));

    return DashboardSummaryModel(
      totalRooms: total,
      occupiedRooms: occupied,
      emptyRooms: empty,
      maintenanceRooms: maintenance,
      reservedRooms: reserved,
      occupancyRate: rate,
      monthlyRevenue: rev,
      pendingTickets: 3,
      uncollectedInvoices: uncollected.length,
      uncollectedAmount: uncollectedTotal,
    );
  }

  List<RoomItemModel> getRoomsByFloor(int floor) {
    return _rooms.where((r) => r.floor == floor).toList();
  }

  // Cập nhật trạng thái phòng & đồng bộ ngay lên Supabase / Web Admin
  void updateRoomStatus(int roomId, String newStatus) {
    final index = _rooms.indexWhere((r) => r.roomId == roomId);
    if (index != -1) {
      final code = _rooms[index].roomCode;
      _rooms[index] = _rooms[index].copyWith(status: newStatus);
      notifyListeners();
      _supabase.syncRoomStatus(roomCode: code, status: newStatus);
    }
  }

  // Nhận phòng mới (Check-in)
  void checkInResident({
    required int roomId,
    required String residentName,
    required String residentPhone,
    required double depositAmount,
  }) {
    final index = _rooms.indexWhere((r) => r.roomId == roomId);
    if (index != -1) {
      final code = 'HD-2026-0$roomId';
      _rooms[index] = _rooms[index].copyWith(
        status: 'Đang ở',
        residentName: residentName,
        residentPhone: residentPhone,
        contractCode: code,
        depositAmount: depositAmount,
      );
      final now = DateTime.now();
      _contracts.removeWhere((c) => c.roomId == roomId && c.isActive);
      _contracts.insert(
        0,
        ManagedContractModel(
          contractCode: code,
          roomId: roomId,
          roomCode: _rooms[index].roomCode,
          residentName: residentName,
          residentPhone: residentPhone,
          nationalId: '079203009999',
          startDate: now,
          endDate: DateTime(now.year + 1, now.month, now.day),
          monthlyRent: _rooms[index].rentPrice,
          depositAmount: depositAmount,
        ),
      );
      notifyListeners();
    }
  }

  // Trả phòng (Check-out) cơ bản
  void checkOutResident(int roomId) {
    final index = _rooms.indexWhere((r) => r.roomId == roomId);
    if (index != -1) {
      _rooms[index] = _rooms[index].copyWith(
        status: 'Trống',
        clearResidentName: true,
        clearResidentPhone: true,
        clearContractCode: true,
        depositAmount: 0,
      );
      for (var i = 0; i < _contracts.length; i++) {
        if (_contracts[i].roomId == roomId && _contracts[i].isActive) {
          _contracts[i] = _contracts[i].copyWith(status: 'Đã thanh lý');
        }
      }
      notifyListeners();
    }
  }

  // Trả phòng đầy đủ kèm Biên bản nghiệm thu và Quyết toán hoàn cọc
  CheckOutSettlementModel? checkOutResidentWithSettlement({
    required int roomId,
    required double propertyDamageDeduction,
    required double unpaidDebt,
    required String inspectorName,
    String? note,
  }) {
    final index = _rooms.indexWhere((r) => r.roomId == roomId);
    if (index == -1) return null;

    final room = _rooms[index];
    final initialDeposit = room.depositAmount;
    final finalRefund = (initialDeposit - propertyDamageDeduction - unpaidDebt);
    final refundAmount = finalRefund > 0 ? finalRefund : 0.0;

    final settlement = CheckOutSettlementModel(
      settlementCode: 'BB-TLHD-${room.roomCode.replaceAll('.', '')}-${DateTime.now().millisecondsSinceEpoch % 1000}',
      roomCode: room.roomCode,
      residentName: room.residentName ?? 'Cư dân',
      contractCode: room.contractCode ?? 'HD-001',
      checkOutDate: DateTime.now(),
      initialDeposit: initialDeposit,
      unpaidInvoicesDebt: unpaidDebt,
      propertyDamageDeduction: propertyDamageDeduction,
      finalRefundAmount: refundAmount,
      inspectorName: inspectorName,
      note: note ?? 'Đã nghiệm thu hiện trạng phòng và bàn giao chìa khóa/khóa IoT.',
    );

    _settlements.insert(0, settlement);

    // Chuyển phòng sang Trống và xóa thông tin hợp đồng cũ
    _rooms[index] = room.copyWith(
      status: 'Trống',
      clearResidentName: true,
      clearResidentPhone: true,
      clearContractCode: true,
      depositAmount: 0,
    );
    for (var i = 0; i < _contracts.length; i++) {
      if (_contracts[i].roomId == roomId && _contracts[i].isActive) {
        _contracts[i] = _contracts[i].copyWith(status: 'Đã thanh lý');
      }
    }

    notifyListeners();
    return settlement;
  }

  // Ghi chỉ số điện nước mới
  void recordMeters(int roomId, int newElectric, int newWater) {
    final index = _rooms.indexWhere((r) => r.roomId == roomId);
    if (index != -1) {
      _rooms[index] = _rooms[index].copyWith(
        lastElectricIndex: newElectric,
        lastWaterIndex: newWater,
      );
      notifyListeners();
    }
  }

  // Mở khóa từ xa qua App (IoT Smart Lock)
  Future<bool> remoteUnlockRoom(String roomCode) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 700));

    _accessLogs.insert(
      0,
      AccessLogModel(
        logId: DateTime.now().millisecondsSinceEpoch % 10000,
        roomCode: roomCode,
        personName: 'Ban Quản trị (Mở từ xa)',
        method: 'Mở từ xa qua App',
        timestamp: DateTime.now(),
        isSuccess: true,
      ),
    );

    _isLoading = false;
    notifyListeners();
    return true;
  }

  // Phê duyệt biên lai thanh toán VietQR (xét số tiền thực nhận, hỗ trợ thanh toán từng phần)
  bool approveInvoicePayment(int invoiceId, {double? approvedAmount, String? note}) {
    final inv = allInvoices.firstWhere((i) => i.invoiceId == invoiceId, orElse: () => allInvoices.first);
    final amountToApprove = approvedAmount ?? (inv.remainingAmount > 0 ? inv.remainingAmount : inv.totalAmount);

    final success = _invoiceDataService.approvePayment(
      invoiceId: invoiceId,
      approvedAmount: amountToApprove,
      note: note,
    );
    notifyListeners();
    return success;
  }

  // Từ chối biên lai thanh toán VietQR
  bool rejectInvoicePayment(int invoiceId, String reason) {
    final success = _invoiceDataService.rejectPayment(
      invoiceId: invoiceId,
      rejectionReason: reason,
    );
    notifyListeners();
    return success;
  }

  // Phát hành hóa đơn hàng loạt theo bậc thang thực tế cho tất cả phòng đang ở
  Future<int> generateBatchInvoices() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));

    final count = _invoiceDataService.generateBatchInvoices(_rooms);

    _isLoading = false;
    notifyListeners();
    return count;
  }

  /// Lập hợp đồng mới & ký điện tử (tương đương /HopDong/Index trên Web)
  ManagedContractModel? createNewContract({
    required int roomId,
    required String residentName,
    required String residentPhone,
    required String nationalId,
    required DateTime startDate,
    required int durationMonths,
    required double monthlyRent,
    required double depositAmount,
  }) {
    final index = _rooms.indexWhere((r) => r.roomId == roomId);
    if (index == -1) return null;

    final room = _rooms[index];
    final code = 'HD-${startDate.year}-0${room.roomId}';
    final endDate = DateTime(
      startDate.year,
      startDate.month + durationMonths,
      startDate.day,
    );

    _rooms[index] = room.copyWith(
      status: 'Đang ở',
      residentName: residentName.trim(),
      residentPhone: residentPhone.trim(),
      contractCode: code,
      rentPrice: monthlyRent,
      depositAmount: depositAmount,
    );

    _contracts.removeWhere((c) => c.roomId == roomId && c.isActive);
    final created = ManagedContractModel(
      contractCode: code,
      roomId: roomId,
      roomCode: room.roomCode,
      residentName: residentName.trim(),
      residentPhone: residentPhone.trim(),
      nationalId: nationalId.trim(),
      startDate: startDate,
      endDate: endDate,
      monthlyRent: monthlyRent,
      depositAmount: depositAmount,
      status: 'Đang hiệu lực',
      isSigned: true,
    );
    _contracts.insert(0, created);
    notifyListeners();
    return created;
  }

  /// Gia hạn hợp đồng thêm [additionalMonths] tháng
  bool renewContract(String contractCode, {int additionalMonths = 12}) {
    final idx = _contracts.indexWhere((c) => c.contractCode == contractCode);
    if (idx == -1) return false;
    final old = _contracts[idx];
    final base = old.endDate.isAfter(DateTime.now()) ? old.endDate : DateTime.now();
    _contracts[idx] = old.copyWith(
      endDate: DateTime(base.year, base.month + additionalMonths, base.day),
      status: 'Đang hiệu lực',
    );
    notifyListeners();
    return true;
  }

  /// Nhập cư dân & hợp đồng hàng loạt từ bảng tính Excel (tương đương Modal Excel trên Web)
  int bulkImportContracts(List<Map<String, String>> rows) {
    int imported = 0;
    for (final row in rows) {
      final name = (row['name'] ?? '').trim();
      final phone = (row['phone'] ?? '').trim();
      final cccd = (row['cccd'] ?? '079203008888').trim();
      final roomCodeRaw = (row['room'] ?? '').trim().toUpperCase();
      if (name.isEmpty || roomCodeRaw.isEmpty) continue;

      final normalizedCode =
          roomCodeRaw.startsWith('P.') ? roomCodeRaw : 'P.$roomCodeRaw';
      final roomIndex = _rooms.indexWhere(
        (r) => r.roomCode.toUpperCase() == normalizedCode,
      );
      if (roomIndex == -1) continue;

      final room = _rooms[roomIndex];
      final rent = double.tryParse((row['rent'] ?? '').replaceAll('.', '')) ??
          room.rentPrice;
      final deposit =
          double.tryParse((row['deposit'] ?? '').replaceAll('.', '')) ??
              (rent * 2);

      createNewContract(
        roomId: room.roomId,
        residentName: name,
        residentPhone: phone.isEmpty ? '0901234567' : phone,
        nationalId: cccd,
        startDate: DateTime.now(),
        durationMonths: 12,
        monthlyRent: rent,
        depositAmount: deposit,
      );
      imported++;
    }
    return imported;
  }

  /// Xuất danh sách hợp đồng ra định dạng CSV/Excel (tương đương nút Xuất Excel Hợp Đồng trên Web)
  String exportContractsCsv() {
    final sb = StringBuffer();
    sb.writeln(
      'Mã Hợp Đồng,Phòng,Cư Dân Đại Diện,Số Điện Thoại,CCCD,Ngày Bắt Đầu,Ngày Kết Thúc,Giá Thuê (VNĐ),Tiền Cọc (VNĐ),Trạng Thái',
    );
    for (final c in _contracts) {
      final start =
          '${c.startDate.day.toString().padLeft(2, '0')}/${c.startDate.month.toString().padLeft(2, '0')}/${c.startDate.year}';
      final end =
          '${c.endDate.day.toString().padLeft(2, '0')}/${c.endDate.month.toString().padLeft(2, '0')}/${c.endDate.year}';
      sb.writeln(
        '${c.contractCode},${c.roomCode},"${c.residentName}",${c.residentPhone},${c.nationalId},$start,$end,${c.monthlyRent.round()},${c.depositAmount.round()},"${c.displayStatus}"',
      );
    }
    return sb.toString();
  }

  /// Thêm căn hộ / phòng mới vào sơ đồ phòng (tương đương #modalAddRoom trên Web /Phong/SoDo)
  RoomItemModel addNewRoom({
    required String roomCode,
    required String buildingName,
    required int floor,
    required String roomType,
    required double area,
    required int capacity,
    required double rentPrice,
  }) {
    final cleanCode = roomCode.trim().toUpperCase().startsWith('P.')
        ? roomCode.trim().toUpperCase()
        : 'P.${roomCode.trim().toUpperCase()}';
    final numericId = int.tryParse(cleanCode.replaceAll(RegExp(r'[^0-9]'), '')) ??
        (floor * 100 + _rooms.where((r) => r.floor == floor).length + 1);

    final newRoom = RoomItemModel(
      roomId: numericId,
      roomCode: cleanCode,
      buildingName: buildingName,
      floor: floor,
      roomType: roomType,
      area: area,
      capacity: capacity,
      rentPrice: rentPrice,
      status: 'Trống',
      smartLockBattery: 98,
    );
    _rooms.add(newRoom);
    _rooms.sort((a, b) => a.roomCode.compareTo(b.roomCode));
    notifyListeners();
    return newRoom;
  }

  /// Áp dụng bảng chỉ số điện nước Excel hàng loạt & tính lại hóa đơn bậc thang (tương đương #modalImportExcel trên Web /HoaDon/Index)
  Future<int> applyExcelMeterReadings(
    List<({int roomId, int oldElectric, int newElectric, int oldWater, int newWater})> rows,
  ) async {
    for (final row in rows) {
      final idx = _rooms.indexWhere((r) => r.roomId == row.roomId);
      if (idx != -1) {
        _rooms[idx] = _rooms[idx].copyWith(
          lastElectricIndex: row.newElectric,
          lastWaterIndex: row.newWater,
        );
      }
    }
    return generateBatchInvoices();
  }

  /// Xuất báo cáo danh sách hóa đơn kỳ ra CSV/Excel (tương đương exportToExcel() trên Web /HoaDon/Index)
  String exportInvoicesCsv() {
    final sb = StringBuffer();
    sb.writeln(
      'Mã Hóa Đơn,Phòng,Tiền Phòng (VNĐ),Tổng Tiền (VNĐ),Đã Thu (VNĐ),Còn Nợ (VNĐ),Trạng Thái',
    );
    for (final inv in allInvoices) {
      sb.writeln(
        '${inv.invoiceCode},${inv.roomCode},${inv.roomPrice.round()},${inv.totalAmount.round()},${inv.paidAmount.round()},${inv.remainingAmount.round()},"${inv.status}"',
      );
    }
    return sb.toString();
  }
}
