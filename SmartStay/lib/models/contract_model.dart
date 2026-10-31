class ContractModel {
  final int contractId;
  final String contractCode;
  final String roomCode;
  final String buildingName;
  final DateTime startDate;
  final DateTime endDate;
  final double monthlyRent;
  final double depositAmount;
  final String terms;
  final String status;
  final List<RoomAssetModel> assets;

  ContractModel({
    required this.contractId,
    required this.contractCode,
    required this.roomCode,
    required this.buildingName,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.depositAmount,
    required this.terms,
    required this.status,
    this.assets = const [],
  });

  ContractModel copyWith({
    int? contractId,
    String? contractCode,
    String? roomCode,
    String? buildingName,
    DateTime? startDate,
    DateTime? endDate,
    double? monthlyRent,
    double? depositAmount,
    String? terms,
    String? status,
    List<RoomAssetModel>? assets,
  }) {
    return ContractModel(
      contractId: contractId ?? this.contractId,
      contractCode: contractCode ?? this.contractCode,
      roomCode: roomCode ?? this.roomCode,
      buildingName: buildingName ?? this.buildingName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      depositAmount: depositAmount ?? this.depositAmount,
      terms: terms ?? this.terms,
      status: status ?? this.status,
      assets: assets ?? this.assets,
    );
  }

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    return ContractModel(
      contractId: json['contractId'] ?? 0,
      contractCode: json['contractCode'] ?? '',
      roomCode: json['roomCode'] ?? '',
      buildingName: json['buildingName'] ?? '',
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] ?? '') ?? DateTime.now(),
      monthlyRent: (json['monthlyRent'] as num?)?.toDouble() ?? 0.0,
      depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0.0,
      terms: json['terms'] ?? '',
      status: json['status'] ?? 'Đang hiệu lực',
      assets: (json['assets'] as List<dynamic>?)
              ?.map((e) => RoomAssetModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contractId': contractId,
      'contractCode': contractCode,
      'roomCode': roomCode,
      'buildingName': buildingName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'monthlyRent': monthlyRent,
      'depositAmount': depositAmount,
      'terms': terms,
      'status': status,
      'assets': assets.map((e) => e.toJson()).toList(),
    };
  }
}

class RoomAssetModel {
  final int assetId;
  final String assetName;
  final int quantity;
  final String condition;
  final double compensationValue;

  RoomAssetModel({
    required this.assetId,
    required this.assetName,
    required this.quantity,
    required this.condition,
    required this.compensationValue,
  });

  RoomAssetModel copyWith({
    int? assetId,
    String? assetName,
    int? quantity,
    String? condition,
    double? compensationValue,
  }) {
    return RoomAssetModel(
      assetId: assetId ?? this.assetId,
      assetName: assetName ?? this.assetName,
      quantity: quantity ?? this.quantity,
      condition: condition ?? this.condition,
      compensationValue: compensationValue ?? this.compensationValue,
    );
  }

  factory RoomAssetModel.fromJson(Map<String, dynamic> json) {
    return RoomAssetModel(
      assetId: json['assetId'] ?? 0,
      assetName: json['assetName'] ?? '',
      quantity: json['quantity'] ?? 1,
      condition: json['condition'] ?? 'Tốt',
      compensationValue: (json['compensationValue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assetId': assetId,
      'assetName': assetName,
      'quantity': quantity,
      'condition': condition,
      'compensationValue': compensationValue,
    };
  }
}
