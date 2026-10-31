import 'package:flutter/foundation.dart';
import '../models/admin_models.dart';
import '../models/invoice_model.dart';
import '../services/invoice_data_service.dart';

class AdminProvider extends ChangeNotifier {
  final InvoiceDataService _invoiceDataService = InvoiceDataService();

  List<RoomItemModel> _rooms = [];
  List<StaffModel> _staffList = [];
  List<AccessLogModel> _accessLogs = [];
  final List<CheckOutSettlementModel> _settlements = [];
  bool _isLoading = false;

  List<RoomItemModel> get rooms => _rooms;
  List<StaffModel> get staffList => _staffList;
  List<AccessLogModel> get accessLogs => _accessLogs;
  List<InvoiceModel> get allInvoices => _invoiceDataService.allInvoices;
  List<CheckOutSettlementModel> get settlements => _settlements;
  bool get isLoading => _isLoading;

  AdminProvider() {
    _invoiceDataService.addListener(_onInvoicesChanged);
    _initMockData();
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
        roomType: 'Co-Living Ban Công',
        area: 28.0,
        capacity: 2,
        rentPrice: 3500000,
        status: 'Đang ở',
        residentName: 'Hồ Ngọc Bảo',
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

  // Cập nhật trạng thái phòng
  void updateRoomStatus(int roomId, String newStatus) {
    final index = _rooms.indexWhere((r) => r.roomId == roomId);
    if (index != -1) {
      _rooms[index] = _rooms[index].copyWith(status: newStatus);
      notifyListeners();
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
}
