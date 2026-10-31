import 'package:flutter/foundation.dart';
import '../models/invoice_model.dart';
import '../services/invoice_data_service.dart';

class InvoiceProvider extends ChangeNotifier {
  final InvoiceDataService _dataService = InvoiceDataService();

  bool _isLoading = false;
  String _activeRoomCode = 'P.305';

  bool get isLoading => _isLoading;

  List<InvoiceModel> get invoices {
    final list = _dataService.getInvoicesForRoom(_activeRoomCode);
    return list.isNotEmpty ? list : _dataService.allInvoices;
  }

  InvoiceModel? get currentUnpaidInvoice {
    try {
      return invoices.firstWhere((inv) => !inv.isFullyPaid);
    } catch (_) {
      return null;
    }
  }

  InvoiceProvider() {
    _dataService.addListener(_onDataServiceChanged);
  }

  void _onDataServiceChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataServiceChanged);
    super.dispose();
  }

  void loadInvoices() {
    notifyListeners();
  }

  void setActiveRoom(String roomCode) {
    if (_activeRoomCode != roomCode) {
      _activeRoomCode = roomCode;
      notifyListeners();
    }
  }

  InvoiceModel? getInvoiceById(int id) {
    return _dataService.getInvoiceById(id);
  }

  /// Cư dân gửi biên lai: Chuyển sang "Chờ đối soát" (chuẩn đặc tả)
  Future<bool> submitPaymentReceipt({
    required int invoiceId,
    required double amount,
    required String receiptImageUrl,
    String? note,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final success = _dataService.submitReceipt(
      invoiceId: invoiceId,
      amount: amount,
      receiptImageUrl: receiptImageUrl,
      note: note,
    );

    _isLoading = false;
    notifyListeners();
    return success;
  }
}
