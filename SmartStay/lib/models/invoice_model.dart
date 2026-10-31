class InvoiceModel {
  final int invoiceId;
  final String invoiceCode;
  final String roomCode;
  final DateTime billingMonth;
  final DateTime issueDate;
  final DateTime dueDate;
  final double roomPrice;
  final double electricPrice;
  final double waterPrice;
  final double servicePrice;
  final double discountPrice;
  final double totalAmount;
  final double paidAmount;
  final String qrContent;
  final String urlVietQr;
  final String status; // Chờ thanh toán, Chờ đối soát, Thanh toán một phần, Đã thanh toán, Quá hạn
  final List<InvoiceItemModel> items;
  final List<PaymentModel> payments;

  InvoiceModel({
    required this.invoiceId,
    required this.invoiceCode,
    required this.roomCode,
    required this.billingMonth,
    required this.issueDate,
    required this.dueDate,
    required this.roomPrice,
    required this.electricPrice,
    required this.waterPrice,
    required this.servicePrice,
    this.discountPrice = 0.0,
    required this.totalAmount,
    this.paidAmount = 0.0,
    required this.qrContent,
    required this.urlVietQr,
    required this.status,
    this.items = const [],
    this.payments = const [],
  });

  double get remainingAmount {
    final diff = totalAmount - paidAmount;
    return diff > 0 ? diff : 0.0;
  }

  bool get isFullyPaid => status == 'Đã thanh toán' || remainingAmount <= 0;

  InvoiceModel copyWith({
    int? invoiceId,
    String? invoiceCode,
    String? roomCode,
    DateTime? billingMonth,
    DateTime? issueDate,
    DateTime? dueDate,
    double? roomPrice,
    double? electricPrice,
    double? waterPrice,
    double? servicePrice,
    double? discountPrice,
    double? totalAmount,
    double? paidAmount,
    String? qrContent,
    String? urlVietQr,
    String? status,
    List<InvoiceItemModel>? items,
    List<PaymentModel>? payments,
  }) {
    return InvoiceModel(
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceCode: invoiceCode ?? this.invoiceCode,
      roomCode: roomCode ?? this.roomCode,
      billingMonth: billingMonth ?? this.billingMonth,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      roomPrice: roomPrice ?? this.roomPrice,
      electricPrice: electricPrice ?? this.electricPrice,
      waterPrice: waterPrice ?? this.waterPrice,
      servicePrice: servicePrice ?? this.servicePrice,
      discountPrice: discountPrice ?? this.discountPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      qrContent: qrContent ?? this.qrContent,
      urlVietQr: urlVietQr ?? this.urlVietQr,
      status: status ?? this.status,
      items: items ?? this.items,
      payments: payments ?? this.payments,
    );
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      invoiceId: json['invoiceId'] ?? 0,
      invoiceCode: json['invoiceCode'] ?? '',
      roomCode: json['roomCode'] ?? '',
      billingMonth: DateTime.tryParse(json['billingMonth'] ?? '') ?? DateTime.now(),
      issueDate: DateTime.tryParse(json['issueDate'] ?? '') ?? DateTime.now(),
      dueDate: DateTime.tryParse(json['dueDate'] ?? '') ?? DateTime.now(),
      roomPrice: (json['roomPrice'] as num?)?.toDouble() ?? 0.0,
      electricPrice: (json['electricPrice'] as num?)?.toDouble() ?? 0.0,
      waterPrice: (json['waterPrice'] as num?)?.toDouble() ?? 0.0,
      servicePrice: (json['servicePrice'] as num?)?.toDouble() ?? 0.0,
      discountPrice: (json['discountPrice'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      qrContent: json['qrContent'] ?? '',
      urlVietQr: json['urlVietQr'] ?? '',
      status: json['status'] ?? 'Chờ thanh toán',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => InvoiceItemModel.fromJson(e))
              .toList() ??
          [],
      payments: (json['payments'] as List<dynamic>?)
              ?.map((e) => PaymentModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoiceId': invoiceId,
      'invoiceCode': invoiceCode,
      'roomCode': roomCode,
      'billingMonth': billingMonth.toIso8601String(),
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'roomPrice': roomPrice,
      'electricPrice': electricPrice,
      'waterPrice': waterPrice,
      'servicePrice': servicePrice,
      'discountPrice': discountPrice,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'qrContent': qrContent,
      'urlVietQr': urlVietQr,
      'status': status,
      'items': items.map((e) => e.toJson()).toList(),
      'payments': payments.map((e) => e.toJson()).toList(),
    };
  }
}

class InvoiceItemModel {
  final int itemId;
  final String itemType; // TienPhong, Dien, Nuoc, DichVu, GiamTru
  final String description;
  final double quantity;
  final double unitPrice;
  final double amount;

  InvoiceItemModel({
    required this.itemId,
    required this.itemType,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
  });

  InvoiceItemModel copyWith({
    int? itemId,
    String? itemType,
    String? description,
    double? quantity,
    double? unitPrice,
    double? amount,
  }) {
    return InvoiceItemModel(
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      amount: amount ?? this.amount,
    );
  }

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      itemId: json['itemId'] ?? 0,
      itemType: json['itemType'] ?? 'DichVu',
      description: json['description'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemType': itemType,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'amount': amount,
    };
  }
}

class PaymentModel {
  final int paymentId;
  final double amount;
  final String paymentMethod;
  final DateTime paidAt;
  final String receiptImageUrl;
  final String status; // Chờ xác nhận, Đã xác nhận, Từ chối
  final String? note;
  final String? rejectionReason;

  PaymentModel({
    required this.paymentId,
    required this.amount,
    required this.paymentMethod,
    required this.paidAt,
    required this.receiptImageUrl,
    required this.status,
    this.note,
    this.rejectionReason,
  });

  PaymentModel copyWith({
    int? paymentId,
    double? amount,
    String? paymentMethod,
    DateTime? paidAt,
    String? receiptImageUrl,
    String? status,
    String? note,
    String? rejectionReason,
  }) {
    return PaymentModel(
      paymentId: paymentId ?? this.paymentId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAt: paidAt ?? this.paidAt,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      status: status ?? this.status,
      note: note ?? this.note,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      paymentId: json['paymentId'] ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] ?? 'VietQR',
      paidAt: DateTime.tryParse(json['paidAt'] ?? '') ?? DateTime.now(),
      receiptImageUrl: json['receiptImageUrl'] ?? '',
      status: json['status'] ?? 'Chờ xác nhận',
      note: json['note'],
      rejectionReason: json['rejectionReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paidAt': paidAt.toIso8601String(),
      'receiptImageUrl': receiptImageUrl,
      'status': status,
      'note': note,
      'rejectionReason': rejectionReason,
    };
  }
}
