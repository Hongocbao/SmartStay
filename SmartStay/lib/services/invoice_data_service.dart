import 'package:flutter/foundation.dart';
import '../models/invoice_model.dart';
import '../models/admin_models.dart';
import '../services/mock_data_service.dart';
import '../services/tiered_utility_service.dart';

/// Single Source of Truth cho toàn bộ dữ liệu Hóa đơn trong hệ thống SmartStay
class InvoiceDataService extends ChangeNotifier {
  static final InvoiceDataService _instance = InvoiceDataService._internal();
  factory InvoiceDataService() => _instance;

  final MockDataService _mock = MockDataService();
  final List<InvoiceModel> _invoices = [];

  InvoiceDataService._internal() {
    _invoices.addAll(_mock.invoices);
  }

  List<InvoiceModel> get allInvoices => List.unmodifiable(_invoices);

  List<InvoiceModel> getInvoicesForRoom(String roomCode) {
    return _invoices.where((i) => i.roomCode == roomCode).toList();
  }

  InvoiceModel? getInvoiceById(int id) {
    try {
      return _invoices.firstWhere((i) => i.invoiceId == id);
    } catch (_) {
      return null;
    }
  }

  /// Cư dân nộp biên lai thanh toán VietQR
  /// Đúng đặc tả: Hóa đơn chuyển sang trạng thái "Chờ đối soát" (KHÔNG PHẢI "Thanh toán một phần")
  bool submitReceipt({
    required int invoiceId,
    required double amount,
    required String receiptImageUrl,
    String? note,
  }) {
    final index = _invoices.indexWhere((i) => i.invoiceId == invoiceId);
    if (index == -1) return false;

    final old = _invoices[index];
    final payment = PaymentModel(
      paymentId: DateTime.now().millisecondsSinceEpoch % 100000,
      amount: amount,
      paymentMethod: 'VietQR - Chuyển khoản Napas 247',
      paidAt: DateTime.now(),
      receiptImageUrl: receiptImageUrl.isEmpty
          ? 'https://smartstay.vn/receipts/demo_receipt.png'
          : receiptImageUrl,
      status: 'Chờ xác nhận',
      note: note ?? 'Cư dân đã gửi ủy nhiệm chi qua app',
    );

    final updatedPayments = List<PaymentModel>.from(old.payments)..insert(0, payment);

    _invoices[index] = old.copyWith(
      status: 'Chờ đối soát',
      payments: updatedPayments,
    );

    notifyListeners();
    return true;
  }

  /// Quản lý vận hành Phê duyệt đối soát biên lai
  /// Xét số tiền biên lai thực nhận, hỗ trợ thanh toán từng phần
  bool approvePayment({
    required int invoiceId,
    required double approvedAmount,
    String? note,
  }) {
    final index = _invoices.indexWhere((i) => i.invoiceId == invoiceId);
    if (index == -1) return false;

    final old = _invoices[index];
    final newPaidAmount = old.paidAmount + approvedAmount;
    final isFully = newPaidAmount >= old.totalAmount;

    // Cập nhật trạng thái của payment gần nhất sang "Đã xác nhận"
    final updatedPayments = old.payments.map((p) {
      if (p.status == 'Chờ xác nhận') {
        return p.copyWith(
          status: 'Đã xác nhận',
          amount: approvedAmount,
          note: note ?? p.note,
        );
      }
      return p;
    }).toList();

    _invoices[index] = old.copyWith(
      paidAmount: newPaidAmount,
      status: isFully ? 'Đã thanh toán' : 'Thanh toán một phần',
      payments: updatedPayments,
    );

    notifyListeners();
    return true;
  }

  /// Quản lý vận hành Từ chối biên lai thanh toán
  bool rejectPayment({
    required int invoiceId,
    required String rejectionReason,
  }) {
    final index = _invoices.indexWhere((i) => i.invoiceId == invoiceId);
    if (index == -1) return false;

    final old = _invoices[index];

    // Cập nhật payment sang "Từ chối"
    final updatedPayments = old.payments.map((p) {
      if (p.status == 'Chờ xác nhận') {
        return p.copyWith(
          status: 'Từ chối',
          rejectionReason: rejectionReason,
        );
      }
      return p;
    }).toList();

    // Hóa đơn quay lại "Thanh toán một phần" nếu đã từng trả 1 phần, hoặc "Chờ thanh toán" nếu chưa
    final rollbackStatus = old.paidAmount > 0 ? 'Thanh toán một phần' : 'Chờ thanh toán';

    _invoices[index] = old.copyWith(
      status: rollbackStatus,
      payments: updatedPayments,
    );

    notifyListeners();
    return true;
  }

  /// Phát hành hóa đơn hàng loạt theo bậc thang thực tế cho tất cả các phòng đang ở
  int generateBatchInvoices(List<RoomItemModel> rooms) {
    final occupiedRooms = rooms.where((r) => r.status == 'Đang ở').toList();
    int count = 0;

    for (var room in occupiedRooms) {
      // Giả lập mức tiêu thụ tháng này dựa trên chỉ số điện nước thực tế
      // Nếu chỉ số bằng nhau thì sinh mức tiêu thụ trung bình (120-160 kWh điện, 6-9 m³ nước)
      final electricKwh = 135.0;
      final waterM3 = 8.0;

      final electricResult = TieredUtilityService.calculateElectricity(electricKwh);
      final waterResult = TieredUtilityService.calculateWater(waterM3);
      final fixedService = 300000.0;
      final totalAmount = room.rentPrice + electricResult.totalAmount + waterResult.totalAmount + fixedService;

      final now = DateTime.now();
      final invoiceCode = 'HD-${now.year}-${now.month.toString().padLeft(2, '0')}-${room.roomCode.replaceAll('.', '')}';

      // Kiểm tra xem phòng này đã có hóa đơn kỳ này chưa
      final existingIndex = _invoices.indexWhere((i) => i.invoiceCode == invoiceCode);

      final items = TieredUtilityService.buildInvoiceItems(
        baseItemId: DateTime.now().millisecondsSinceEpoch % 10000 + count * 10,
        roomRentPrice: room.rentPrice,
        electricResult: electricResult,
        waterResult: waterResult,
        fixedServicePrice: fixedService,
      );

      final encodedInfo = Uri.encodeComponent('$invoiceCode ${room.roomCode}');
      final vietQrUrl =
          'https://img.vietqr.io/image/970422-0987654321-compact2.png?amount=${totalAmount.round()}&addInfo=$encodedInfo&accountName=SMARTSTAY%20MANAGEMENT';

      final newInvoice = InvoiceModel(
        invoiceId: DateTime.now().millisecondsSinceEpoch % 100000 + count,
        invoiceCode: invoiceCode,
        roomCode: room.roomCode,
        billingMonth: DateTime(now.year, now.month, 1),
        issueDate: now,
        dueDate: now.add(const Duration(days: 10)),
        roomPrice: room.rentPrice,
        electricPrice: electricResult.totalAmount,
        waterPrice: waterResult.totalAmount,
        servicePrice: fixedService,
        totalAmount: totalAmount,
        paidAmount: 0.0,
        qrContent: '$invoiceCode ${room.roomCode}',
        urlVietQr: vietQrUrl,
        status: 'Chờ thanh toán',
        items: items,
        payments: [],
      );

      if (existingIndex != -1) {
        _invoices[existingIndex] = newInvoice;
      } else {
        _invoices.insert(0, newInvoice);
      }
      count++;
    }

    notifyListeners();
    return count;
  }
}
