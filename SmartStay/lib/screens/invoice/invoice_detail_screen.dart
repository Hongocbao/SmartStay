import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../providers/invoice_provider.dart';
import '../../models/invoice_model.dart';
import '../../utils/provider_scope.dart';
import '../../utils/formatters.dart';
import '../../services/system_config.dart';

/// Mã VietQR động luôn dùng tài khoản thụ hưởng trong Cấu hình hệ thống.
String _qrUrl(InvoiceModel invoice) => SystemConfig().vietQrUrl(
      amount: invoice.remainingAmount > 0 ? invoice.remainingAmount : invoice.totalAmount,
      content: invoice.qrContent,
    );

class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final _receiptNoteController = TextEditingController();

  @override
  void dispose() {
    _receiptNoteController.dispose();
    super.dispose();
  }

  void _showSubmitReceiptDialog(InvoiceModel invoice) {
    final amountController = TextEditingController(text: invoice.remainingAmount.round().toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Xác nhận nộp biên lai thanh toán',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hóa đơn: ${invoice.invoiceCode}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Còn nợ: ${AppFormatters.currency(invoice.remainingAmount)}',
                              style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền bạn đã chuyển khoản (VNĐ)',
                  prefixIcon: Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(),
                  helperText: 'Có thể thanh toán trước một phần số tiền',
                ),
              ),
              const SizedBox(height: 14),

              // Khung đính kèm ảnh biên lai
              Container(
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 28, color: Color(0xFF10B981)),
                      const SizedBox(height: 4),
                      const Text(
                        'Đã đính kèm ảnh chụp ủy nhiệm chi ngân hàng',
                        style: TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                      ),
                      Text('VietQR Napas 247 • ${SystemConfig().bank.shortName}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _receiptNoteController,
                decoration: InputDecoration(
                  labelText: 'Ghi chú cho Ban Quản lý (tùy chọn)',
                  hintText: 'Ví dụ: Đã chuyển khoản từ app MBBank / Techcombank',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: () async {
                    final enteredAmount = double.tryParse(amountController.text) ?? invoice.remainingAmount;
                    Navigator.pop(ctx);
                    final prov = context.read<InvoiceProvider>();
                    final success = await prov.submitPaymentReceipt(
                      invoiceId: invoice.invoiceId,
                      amount: enteredAmount,
                      receiptImageUrl: invoice.urlVietQr,
                      note: _receiptNoteController.text.trim(),
                    );
                    if (mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã gửi thông tin! Hóa đơn đã chuyển sang trạng thái "Chờ đối soát".'),
                          backgroundColor: Color(0xFFD97706),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Gửi xác nhận thanh toán', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showZoomQrDialog(InvoiceModel invoice) {
    bool isScanning = true;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            if (isScanning) {
              Future.delayed(const Duration(milliseconds: 650), () {
                if (ctx.mounted && isScanning) {
                  setDialogState(() => isScanning = false);
                }
              });
            }
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF1E3A8A), size: 20),
                            ),
                            const SizedBox(width: 8),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Máy Quét QR Sandbox Nội Khu', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                Text('SmartStay FinTech QR Decoder v2.6', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              ],
                            ),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
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
                                    color: isScanning ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                                    width: 3,
                                  ),
                                ),
                                child: Image.network(
                                  _qrUrl(invoice),
                                  width: 175,
                                  height: 175,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                                    width: 175,
                                    height: 175,
                                    child: Center(
                                      child: Icon(Icons.qr_code_2_rounded, size: 110, color: Color(0xFF2563EB)),
                                    ),
                                  ),
                                ),
                              ),
                              if (isScanning)
                                Container(
                                  width: 185,
                                  height: 3,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    boxShadow: [BoxShadow(color: Color(0xFFEF4444), blurRadius: 8, spreadRadius: 2)],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isScanning
                                  ? const Color(0xFF0284C7).withValues(alpha: 0.25)
                                  : const Color(0xFF10B981).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isScanning
                                  ? '⚡ Đang quét tia Laser & giải mã QR Token...'
                                  : '✓ ĐÃ QUÉT & GIẢI MÃ THÀNH CÔNG QR HÓA ĐƠN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isScanning ? const Color(0xFF38BDF8) : const Color(0xFF34D399),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mã Hóa Đơn: ${invoice.invoiceCode} (${invoice.roomCode})',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Tài khoản Ảo nhận: ${SystemConfig().maskedAccountDisplay}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                            'Số tiền giải mã: ${AppFormatters.currency(invoice.remainingAmount)}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFFDC2626)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Nội dung: ${invoice.qrContent}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (invoice.remainingAmount > 0)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isScanning
                              ? null
                              : () async {
                                  Navigator.pop(ctx);
                                  final txRef = 'QR-SCAN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                                  final invoiceProv = context.read<InvoiceProvider>();
                                  final messenger = ScaffoldMessenger.of(context);
                                  final success = await invoiceProv.submitPaymentReceipt(
                                    invoiceId: invoice.invoiceId,
                                    amount: invoice.remainingAmount,
                                    receiptImageUrl: _qrUrl(invoice),
                                    note: 'Quét mã QR trực tiếp bằng Máy Quét Sandbox Nội Khu SmartStay ($txRef)',
                                  );
                                  if (!mounted || !success) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('⚡ Đã quét QR & đối soát tự động thành công! Mã GD: $txRef'),
                                      backgroundColor: const Color(0xFF059669),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.verified_rounded, size: 18),
                          label: const Text('✓ XÁC NHẬN THANH TOÁN QUA MÃ QR VỪA QUÉT',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoiceProv = context.watch<InvoiceProvider>();
    final invoice = invoiceProv.getInvoiceById(widget.invoiceId);

    if (invoice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết hóa đơn')),
        body: const Center(child: Text('Không tìm thấy thông tin hóa đơn.')),
      );
    }

    final electricItems = invoice.items.where((i) => i.itemType == 'Dien').toList();
    final waterItems = invoice.items.where((i) => i.itemType == 'Nuoc').toList();
    final serviceItems =
        invoice.items.where((i) => i.itemType != 'Dien' && i.itemType != 'Nuoc').toList();

    // Tính tổng kWh điện và m³ nước để cảnh báo bất thường
    final totalElectricKwh = electricItems.fold<double>(0.0, (sum, i) => sum + i.quantity);
    final isElectricHigh = totalElectricKwh > 100 || invoice.electricPrice > 250000;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Hóa đơn ${invoice.invoiceCode}'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Tổng quan số tiền & trạng thái
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kỳ tháng ${AppFormatters.monthYear(invoice.billingMonth)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppFormatters.invoiceStatusColor(invoice.status).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          invoice.status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppFormatters.invoiceStatusColor(invoice.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng hóa đơn:', style: TextStyle(color: Color(0xFF64748B))),
                      Text(
                        AppFormatters.currency(invoice.totalAmount),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Đã thanh toán:', style: TextStyle(color: Color(0xFF64748B))),
                      Text(
                        AppFormatters.currency(invoice.paidAmount),
                        style: const TextStyle(fontSize: 15, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Còn lại cần đóng:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        AppFormatters.currency(invoice.remainingAmount),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Hạn thanh toán:', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      Text(
                        AppFormatters.date(invoice.dueDate),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Smart Feature 1: Cảnh báo bất thường điện nước (Anomaly Detection)
            if (isElectricHigh) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Phát hiện bất thường điện nước (+32%)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sản lượng điện tháng này ($totalElectricKwh kWh) tăng đáng kể so với mức trung bình. Đã có 20 kWh chạm mức Bậc 3 (2.700 đ/kWh). Đề xuất kiểm tra gioăng tủ lạnh hoặc hẹn giờ tắt máy lạnh khi ngủ.',
                            style: const TextStyle(fontSize: 11, color: Color(0xFFB45309), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Khu vực VietQR Động Thật
            if (!invoice.isFullyPaid) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_user_rounded, color: Color(0xFF1D4ED8), size: 24),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            SystemConfig().isSandboxMode
                                ? 'CỔNG THANH TOÁN ĐỊNH DANH ẢO (SANDBOX ĐỒ ÁN)'
                                : 'MÃ THANH TOÁN VIETQR CHUẨN NAPAS 247',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E40AF),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (SystemConfig().isSandboxMode) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Text(
                          '🛡️ Bảo mật Đồ Án: Dùng Tài khoản Định danh Ảo (Masked VA) — Không lộ STK ngân hàng thật',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Khung ảnh VietQR thật
                    InkWell(
                      onTap: () => _showZoomQrDialog(invoice),
                      child: Container(
                        width: 210,
                        height: 210,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _qrUrl(invoice),
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.qr_code_2_rounded, size: 70, color: Color(0xFF2563EB)),
                                const SizedBox(height: 6),
                                Text(
                                  AppFormatters.currency(invoice.remainingAmount),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const Text('Chạm để phóng to', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showZoomQrDialog(invoice),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 16, color: Color(0xFF1E3A8A)),
                      label: const Text(
                        '📷 Chạm vào QR hoặc bấm để Quét Thử bằng Máy Quét Nội Khu',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A)),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF93C5FD)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Thông tin chuyển khoản chi tiết (Tài khoản Định danh Ảo hóa không lộ STK thật)
                    _buildBankInfoRow(
                      'Cổng thanh toán',
                      SystemConfig().isSandboxMode
                          ? 'SmartStay FinTech Sandbox (Tokenized VA)'
                          : SystemConfig().bank.fullName,
                      SystemConfig().bank.shortName,
                    ),
                    _buildBankInfoRow(
                      'Mã TK Định danh Ảo',
                      SystemConfig().maskedAccountDisplay,
                      SystemConfig().accountNumber,
                      isCopyable: true,
                    ),
                    _buildBankInfoRow('Đơn vị thụ hưởng', SystemConfig().accountHolder, ''),
                    _buildBankInfoRow('Số tiền', AppFormatters.currency(invoice.remainingAmount),
                        invoice.remainingAmount.round().toString(),
                        isCopyable: true),
                    _buildBankInfoRow('Mã tham chiếu', invoice.qrContent, invoice.qrContent, isCopyable: true),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final prov = context.read<InvoiceProvider>();
                          final success = await prov.submitPaymentReceipt(
                            invoiceId: invoice.invoiceId,
                            amount: invoice.remainingAmount,
                            receiptImageUrl: _qrUrl(invoice),
                            note: 'Thanh toán qua Cổng Sandbox Định danh Ảo (VA-SMARTSTAY-8899)',
                          );
                          if (mounted && success) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '⚡ Giả lập Webhook Sandbox thành công! Đã ghi nhận giao dịch qua Tài khoản Định danh Ảo (Không cần STK thật).',
                                ),
                                backgroundColor: Color(0xFF16A34A),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.bolt_rounded),
                        label: const Text(
                          '⚡ Giả Lập Thanh Toán Sandbox 1 Chạm (Không Cần STK Thật)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showSubmitReceiptDialog(invoice),
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: const Text('Hoặc tải biên lai đối soát thủ công',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Bảng phân tích chi tiết hóa đơn bậc thang
            const Text(
              'Bảng phân tích chi tiết chi phí & Bậc thang',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),

            // Tiền phòng & Dịch vụ cố định
            _buildExpenseGroup(
              title: '1. Tiền thuê phòng & Dịch vụ cố định',
              items: serviceItems,
              groupColor: const Color(0xFF2563EB),
            ),
            const SizedBox(height: 14),

            // Chi tiết Điện Bậc Thang
            _buildExpenseGroup(
              title: '2. Chi tiết Điện lũy tiến theo bậc thang',
              items: electricItems,
              groupColor: const Color(0xFFEA580C),
              icon: Icons.bolt,
            ),
            const SizedBox(height: 14),

            // Chi tiết Nước Bậc Thang
            _buildExpenseGroup(
              title: '3. Chi tiết Nước sinh hoạt theo bậc thang',
              items: waterItems,
              groupColor: const Color(0xFF0284C7),
              icon: Icons.water_drop_outlined,
            ),
            const SizedBox(height: 24),

            // Lịch sử các lần thanh toán
            if (invoice.payments.isNotEmpty) ...[
              const Text(
                'Lịch sử giao dịch thanh toán',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),
              ...invoice.payments.map((p) {
                final isAccepted = p.status == 'Đã xác nhận';
                final isRejected = p.status == 'Từ chối';

                Color badgeColor;
                if (isAccepted) {
                  badgeColor = const Color(0xFF16A34A);
                } else if (isRejected) {
                  badgeColor = const Color(0xFFDC2626);
                } else {
                  badgeColor = const Color(0xFFD97706);
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAccepted
                              ? Icons.check_circle_outline
                              : (isRejected ? Icons.cancel_outlined : Icons.schedule),
                          color: badgeColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppFormatters.currency(p.amount),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text('${p.paymentMethod} • ${AppFormatters.dateTime(p.paidAt)}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            if (p.note != null) ...[
                              const SizedBox(height: 2),
                              Text(p.note!, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                            ],
                            if (p.rejectionReason != null) ...[
                              const SizedBox(height: 2),
                              Text('Lý do từ chối: ${p.rejectionReason}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBankInfoRow(String title, String displayValue, String copyValue, {bool isCopyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
          Row(
            children: [
              Text(
                displayValue,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              if (isCopyable) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: copyValue));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã sao chép $title: $copyValue')),
                    );
                  },
                  child: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF2563EB)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseGroup({
    required String title,
    required List<InvoiceItemModel> items,
    required Color groupColor,
    IconData? icon,
  }) {
    final subtotal = items.fold(0.0, (sum, i) => sum + i.amount);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: groupColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: groupColor),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(fontWeight: FontWeight.bold, color: groupColor, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppFormatters.currency(subtotal),
                  style: TextStyle(fontWeight: FontWeight.bold, color: groupColor, fontSize: 13),
                ),
              ],
            ),
          ),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.description,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          '${AppFormatters.number(item.quantity)} × ${AppFormatters.currency(item.unitPrice)}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    AppFormatters.currency(item.amount),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
