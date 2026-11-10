/// Hợp đồng lưu trú do Ban Quản lý quản trị (tương đương trang /HopDong/Index trên Web).
class ManagedContractModel {
  final String contractCode;
  final int roomId;
  final String roomCode;
  final String residentName;
  final String residentPhone;
  final String nationalId;
  final DateTime startDate;
  final DateTime endDate;
  final double monthlyRent;
  final double depositAmount;
  final String status; // Đang hiệu lực, Đã thanh lý
  final bool isSigned;

  const ManagedContractModel({
    required this.contractCode,
    required this.roomId,
    required this.roomCode,
    required this.residentName,
    required this.residentPhone,
    this.nationalId = '',
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.depositAmount,
    this.status = 'Đang hiệu lực',
    this.isSigned = true,
  });

  int get durationMonths =>
      (endDate.year - startDate.year) * 12 + endDate.month - startDate.month;

  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  bool get isActive => status == 'Đang hiệu lực';

  /// Còn ≤ 30 ngày là sắp hết hạn (khớp nhãn "Sắp hết hạn" trên Web).
  bool get isExpiringSoon => isActive && daysRemaining <= 30;

  String get displayStatus {
    if (!isActive) return status;
    if (daysRemaining < 0) return 'Quá hạn';
    if (isExpiringSoon) return 'Sắp hết hạn';
    return 'Đang hiệu lực';
  }

  ManagedContractModel copyWith({
    DateTime? endDate,
    double? monthlyRent,
    String? status,
  }) {
    return ManagedContractModel(
      contractCode: contractCode,
      roomId: roomId,
      roomCode: roomCode,
      residentName: residentName,
      residentPhone: residentPhone,
      nationalId: nationalId,
      startDate: startDate,
      endDate: endDate ?? this.endDate,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      depositAmount: depositAmount,
      status: status ?? this.status,
      isSigned: isSigned,
    );
  }
}

