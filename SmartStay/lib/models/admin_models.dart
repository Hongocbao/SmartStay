class RoomItemModel {
  final int roomId;
  final String roomCode;
  final String buildingName;
  final int floor;
  final String roomType;
  final double area;
  final int capacity;
  final double rentPrice;
  final String status; // Trống, Đang ở, Bảo trì, Đã đặt
  final String? residentName;
  final String? residentPhone;
  final String? contractCode;
  final double depositAmount;
  final int lastElectricIndex;
  final int lastWaterIndex;
  final bool smartLockOnline;
  final int smartLockBattery;

  RoomItemModel({
    required this.roomId,
    required this.roomCode,
    required this.buildingName,
    required this.floor,
    required this.roomType,
    required this.area,
    required this.capacity,
    required this.rentPrice,
    required this.status,
    this.residentName,
    this.residentPhone,
    this.contractCode,
    this.depositAmount = 0,
    this.lastElectricIndex = 1200,
    this.lastWaterIndex = 40,
    this.smartLockOnline = true,
    this.smartLockBattery = 92,
  });

  RoomItemModel copyWith({
    int? roomId,
    String? roomCode,
    String? buildingName,
    int? floor,
    String? roomType,
    double? area,
    int? capacity,
    double? rentPrice,
    String? status,
    String? residentName,
    bool clearResidentName = false,
    String? residentPhone,
    bool clearResidentPhone = false,
    String? contractCode,
    bool clearContractCode = false,
    double? depositAmount,
    int? lastElectricIndex,
    int? lastWaterIndex,
    bool? smartLockOnline,
    int? smartLockBattery,
  }) {
    return RoomItemModel(
      roomId: roomId ?? this.roomId,
      roomCode: roomCode ?? this.roomCode,
      buildingName: buildingName ?? this.buildingName,
      floor: floor ?? this.floor,
      roomType: roomType ?? this.roomType,
      area: area ?? this.area,
      capacity: capacity ?? this.capacity,
      rentPrice: rentPrice ?? this.rentPrice,
      status: status ?? this.status,
      residentName: clearResidentName ? null : (residentName ?? this.residentName),
      residentPhone: clearResidentPhone ? null : (residentPhone ?? this.residentPhone),
      contractCode: clearContractCode ? null : (contractCode ?? this.contractCode),
      depositAmount: depositAmount ?? this.depositAmount,
      lastElectricIndex: lastElectricIndex ?? this.lastElectricIndex,
      lastWaterIndex: lastWaterIndex ?? this.lastWaterIndex,
      smartLockOnline: smartLockOnline ?? this.smartLockOnline,
      smartLockBattery: smartLockBattery ?? this.smartLockBattery,
    );
  }
}

class AccessLogModel {
  final int logId;
  final String roomCode;
  final String personName;
  final String method; // Vân tay, Thẻ từ RFID, Mở từ xa qua App, Mã PIN
  final DateTime timestamp;
  final bool isSuccess;

  AccessLogModel({
    required this.logId,
    required this.roomCode,
    required this.personName,
    required this.method,
    required this.timestamp,
    this.isSuccess = true,
  });

  AccessLogModel copyWith({
    int? logId,
    String? roomCode,
    String? personName,
    String? method,
    DateTime? timestamp,
    bool? isSuccess,
  }) {
    return AccessLogModel(
      logId: logId ?? this.logId,
      roomCode: roomCode ?? this.roomCode,
      personName: personName ?? this.personName,
      method: method ?? this.method,
      timestamp: timestamp ?? this.timestamp,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class StaffModel {
  final int staffId;
  final String fullName;
  final String role; // Quản trị viên, Kỹ thuật viên, Lễ tân
  final String phone;
  final String email;
  final bool isAvailable;

  StaffModel({
    required this.staffId,
    required this.fullName,
    required this.role,
    required this.phone,
    required this.email,
    this.isAvailable = true,
  });

  StaffModel copyWith({
    int? staffId,
    String? fullName,
    String? role,
    String? phone,
    String? email,
    bool? isAvailable,
  }) {
    return StaffModel(
      staffId: staffId ?? this.staffId,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

class DashboardSummaryModel {
  final int totalRooms;
  final int occupiedRooms;
  final int emptyRooms;
  final int maintenanceRooms;
  final int reservedRooms;
  final double occupancyRate;
  final double monthlyRevenue;
  final int pendingTickets;
  final int uncollectedInvoices;
  final double uncollectedAmount;

  DashboardSummaryModel({
    required this.totalRooms,
    required this.occupiedRooms,
    required this.emptyRooms,
    required this.maintenanceRooms,
    required this.reservedRooms,
    required this.occupancyRate,
    required this.monthlyRevenue,
    required this.pendingTickets,
    required this.uncollectedInvoices,
    required this.uncollectedAmount,
  });
}

class CheckOutSettlementModel {
  final String settlementCode;
  final String roomCode;
  final String residentName;
  final String contractCode;
  final DateTime checkOutDate;
  final double initialDeposit;
  final double unpaidInvoicesDebt;
  final double propertyDamageDeduction;
  final double finalRefundAmount;
  final String inspectorName;
  final String note;

  CheckOutSettlementModel({
    required this.settlementCode,
    required this.roomCode,
    required this.residentName,
    required this.contractCode,
    required this.checkOutDate,
    required this.initialDeposit,
    required this.unpaidInvoicesDebt,
    required this.propertyDamageDeduction,
    required this.finalRefundAmount,
    required this.inspectorName,
    required this.note,
  });
}
