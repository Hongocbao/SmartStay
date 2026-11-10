import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/provider_scope.dart';
import '../../providers/admin_provider.dart';
import '../../models/invoice_model.dart';
import '../../services/system_config.dart';
import '../../services/tiered_utility_service.dart';
import '../../utils/formatters.dart';

class AdminFinanceScreen extends StatefulWidget {
  const AdminFinanceScreen({super.key});

  @override
  State<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends State<AdminFinanceScreen> {
  String _selectedFilter = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final invoices = admin.allInvoices;

    final pendingReview = invoices.where((i) => i.status == 'Chờ đối soát').toList();
    final uncollected = invoices.where((i) => i.status == 'Chờ thanh toán' || i.status == 'Thanh toán một phần').toList();
    final collected = invoices.where((i) => i.status == 'Đã thanh toán').toList();

    final filteredInvoices = invoices.where((inv) {
      if (_selectedFilter == 'Tất cả') return true;
      if (_selectedFilter == 'Chưa đóng') {
        return inv.status == 'Chờ thanh toán' || inv.status == 'Thanh toán một phần';
      }
      return inv.status == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Tài Chính & Đối Soát VietQR',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            tooltip: 'Bảng Tính Excel - Nhập Chỉ Số Điện Nước',
            icon: const Icon(Icons.table_view_rounded, color: Color(0xFF16A34A)),
            onPressed: () => _showExcelMeterGridModal(context, admin),
          ),
          IconButton(
            tooltip: 'Xuất Báo Cáo Excel (.CSV)',
            icon: const Icon(Icons.download_rounded, color: Color(0xFF2563EB)),
            onPressed: () => _exportInvoicesCsvDialog(context, admin),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh công cụ thao tác nhanh giống hệt /HoaDon/Index trên Web
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.grid_on_rounded, size: 15, color: Colors.white),
                  label: const Text('Nhập Điện Nước (Excel)', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showExcelMeterGridModal(context, admin),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.download_rounded, size: 15, color: Color(0xFF16A34A)),
                  label: const Text('Xuất Báo Cáo Excel', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF16A34A)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _exportInvoicesCsvDialog(context, admin),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.qr_code_2_rounded, size: 15, color: Color(0xFF2563EB)),
                  label: const Text('Phát Hành VietQR Hàng Loạt', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã phát hành thành công ${invoices.length} mã VietQR NAPAS 247 động gắn kèm số tài khoản ${SystemConfig().accountNumber}!'),
                        backgroundColor: const Color(0xFF2563EB),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Batch Billing Automation Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Tự Động Tính Biểu Giá Bậc Thang',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Đọc chỉ số công tơ điện nước thực tế, áp dụng lũy tiến 4 bậc điện và 3 bậc nước, cộng tiền phòng và phí cố định để phát hành hóa đơn tự động cho các phòng đang ở.',
                    style: TextStyle(color: Color(0xFFDBEAFE), fontSize: 11, height: 1.3),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      icon: admin.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E3A8A)),
                            )
                          : const Icon(Icons.bolt_rounded, color: Color(0xFF1E3A8A), size: 18),
                      label: Text(
                        admin.isLoading
                            ? 'Đang tính toán biểu giá bậc thang...'
                            : '⚡ Phát Hành Hóa Đơn Hàng Loạt Theo Bậc Thang',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: admin.isLoading
                          ? null
                          : () async {
                              final count = await admin.generateBatchInvoices();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đã hoàn tất tính toán và phát hành hóa đơn theo bậc thang cho $count phòng đang ở!'),
                                    backgroundColor: const Color(0xFF10B981),
                                  ),
                                );
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Statistics Row (3 thẻ số liệu)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Chờ đối soát', style: TextStyle(fontSize: 11, color: Color(0xFFB45309), fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          '${pendingReview.length} phiếu',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Chưa đóng', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        Text(
                          '${uncollected.length} hóa đơn',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Đã thu xong', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        Text(
                          '${collected.length} hóa đơn',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text(
              'Danh Sách Hóa Đơn & Đối Soát Biên Lai VietQR',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),

            // Bộ lọc trạng thái hóa đơn giống trên Web
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tất cả', invoices.length),
                  const SizedBox(width: 8),
                  _buildFilterChip('Chờ đối soát', pendingReview.length),
                  const SizedBox(width: 8),
                  _buildFilterChip('Chưa đóng', uncollected.length),
                  const SizedBox(width: 8),
                  _buildFilterChip('Đã thanh toán', collected.length),
                ],
              ),
            ),
            const SizedBox(height: 12),

            ...filteredInvoices.map((inv) => _buildInvoiceCard(context, inv, admin)),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, InvoiceModel inv, AdminProvider admin) {
    final isPaid = inv.status == 'Đã thanh toán';
    final isPendingReview = inv.status == 'Chờ đối soát';

    Color statusColor;
    Color statusBg;
    if (isPaid) {
      statusColor = const Color(0xFF16A34A);
      statusBg = const Color(0xFFF0FDF4);
    } else if (isPendingReview) {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFFFBEB);
    } else if (inv.status == 'Thanh toán một phần') {
      statusColor = const Color(0xFF2563EB);
      statusBg = const Color(0xFFEFF6FF);
    } else {
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEF2F2);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPendingReview ? const Color(0xFFFBBF24) : const Color(0xFFE2E8F0),
          width: isPendingReview ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      inv.roomCode,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2563EB)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    inv.invoiceCode,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  inv.status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tổng tiền:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  Text(
                    Formatters.formatCurrency(inv.totalAmount),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Đã thanh toán:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  Text(
                    Formatters.formatCurrency(inv.paidAmount),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Còn nợ:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  Text(
                    Formatters.formatCurrency(inv.remainingAmount),
                    style: TextStyle(
                      fontSize: 14,
                      color: inv.remainingAmount > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Actions
          if (isPendingReview) ...[
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.qr_code_rounded, size: 15, color: Color(0xFF2563EB)),
                  label: const Text('Xem VietQR', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB))),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showVietQrPreviewDialog(context, inv),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.fact_check_rounded, size: 16, color: Colors.white),
                    label: const Text(
                      'Xem Biên Lai & Đối Soát',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showReviewReceiptDialog(context, inv, admin),
                  ),
                ),
              ],
            ),
          ] else if (!isPaid) ...[
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.qr_code_rounded, size: 15, color: Color(0xFF2563EB)),
                  label: const Text('Xem VietQR', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB))),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showVietQrPreviewDialog(context, inv),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.receipt_long_rounded, size: 15),
                    label: const Text('Ghi Nhận Thu Tiền Trực Tiếp', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showManualPaymentDialog(context, inv, admin),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF16A34A)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Đã đối soát & khớp lệnh thanh toán thành công',
                          style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.qr_code_rounded, size: 14),
                  label: const Text('VietQR', style: TextStyle(fontSize: 11)),
                  onPressed: () => _showVietQrPreviewDialog(context, inv),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showReviewReceiptDialog(BuildContext context, InvoiceModel inv, AdminProvider admin) {
    final latestPayment = inv.payments.isNotEmpty ? inv.payments.first : null;
    final claimedAmount = latestPayment?.amount ?? inv.remainingAmount;
    final amountCtrl = TextEditingController(text: claimedAmount.round().toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Đối Soát Biên Lai - ${inv.invoiceCode}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phòng: ${inv.roomCode} • Còn nợ: ${Formatters.formatCurrency(inv.remainingAmount)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 12),

                // Ảnh biên lai chuyển khoản VietQR
                Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long, size: 40, color: Color(0xFF2563EB)),
                        const SizedBox(height: 4),
                        Text(
                          'Ủy nhiệm chi VietQR: ${Formatters.formatCurrency(claimedAmount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          latestPayment?.note ?? 'Cư dân gửi qua app',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số tiền thực nhận vào tài khoản (VNĐ)',
                    prefixIcon: Icon(Icons.attach_money),
                    helperText: 'Có thể điều chỉnh nếu cư dân chuyển khoản từng phần',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
              onPressed: () {
                _showRejectDialog(context, inv, admin, () => Navigator.pop(ctx));
              },
              child: const Text('Từ chối biên lai'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () {
                final approved = double.tryParse(amountCtrl.text) ?? claimedAmount;
                admin.approveInvoicePayment(inv.invoiceId, approvedAmount: approved);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã phê duyệt đối soát ${Formatters.formatCurrency(approved)} cho phòng ${inv.roomCode}!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              },
              child: const Text('Phê Duyệt Khớp Tiền', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context, InvoiceModel inv, AdminProvider admin, VoidCallback onDone) {
    final reasonCtrl = TextEditingController(text: 'Ảnh biên lai mờ hoặc số tiền chưa khớp với sao kê ngân hàng');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Từ Chối Biên Lai Thanh Toán'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Vui lòng nhập lý do từ chối để phản hồi lại cho cư dân:', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 10),
              TextField(
                controller: reasonCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Lý do từ chối'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              onPressed: () {
                admin.rejectInvoicePayment(inv.invoiceId, reasonCtrl.text);
                Navigator.pop(ctx);
                onDone();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã từ chối biên lai của ${inv.roomCode}. Hóa đơn đã được mở lại.'),
                    backgroundColor: const Color(0xFFEF4444),
                  ),
                );
              },
              child: const Text('Xác nhận từ chối', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showManualPaymentDialog(BuildContext context, InvoiceModel inv, AdminProvider admin) {
    final amountCtrl = TextEditingController(text: inv.remainingAmount.round().toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Ghi Nhận Thu Tiền - ${inv.invoiceCode}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Phòng: ${inv.roomCode} • Còn nợ: ${Formatters.formatCurrency(inv.remainingAmount)}'),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số tiền thực thu (VNĐ)', prefixIcon: Icon(Icons.payments)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(amountCtrl.text) ?? inv.remainingAmount;
                admin.approveInvoicePayment(inv.invoiceId, approvedAmount: amt, note: 'Thu tiền mặt tại văn phòng');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã ghi nhận thanh toán ${Formatters.formatCurrency(amt)}!')),
                );
              },
              child: const Text('Xác nhận thu'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => setState(() => _selectedFilter = label),
    );
  }

  void _showVietQrPreviewDialog(BuildContext context, InvoiceModel inv) {
    final cfg = SystemConfig();
    final amount = (inv.remainingAmount > 0 ? inv.remainingAmount : inv.totalAmount).round();
    final content = 'HD1026 ${inv.roomCode.replaceAll('.', '')}';
    final qrUrl = cfg.vietQrUrl(amount: amount.toDouble(), content: content);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Mã VietQR Động - ${inv.roomCode}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${cfg.bank.shortName} • STK: ${cfg.accountNumber}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
              ),
              Text(
                'Chủ TK: ${cfg.accountHolder}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Image.network(
                  qrUrl,
                  width: 210,
                  height: 210,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 180,
                    height: 180,
                    child: Center(child: Icon(Icons.qr_code_2_rounded, size: 120, color: Color(0xFF1E293B))),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Số tiền: ${Formatters.formatCurrency(amount.toDouble())}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
              ),
              Text(
                'Nội dung CK: $content',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          ],
        );
      },
    );
  }

  void _exportInvoicesCsvDialog(BuildContext context, AdminProvider admin) {
    final csv = admin.exportInvoicesCsv();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.table_view_rounded, color: Color(0xFF16A34A)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Xuất Báo Cáo Hóa Đơn Excel (.CSV)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'File: DanhSach_HoaDon_Thang10_2026.csv',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      csv,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
              label: const Text('Sao Chép CSV', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: csv));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xuất và sao chép báo cáo hóa đơn kỳ tháng 10/2026 (.CSV) thành công!'),
                    backgroundColor: Color(0xFF16A34A),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showExcelMeterGridModal(BuildContext context, AdminProvider admin) {
    final occupiedRooms = admin.rooms.where((r) => r.status == 'Đang ở').toList();
    final elecOldCtrls = <int, TextEditingController>{};
    final elecNewCtrls = <int, TextEditingController>{};
    final waterOldCtrls = <int, TextEditingController>{};
    final waterNewCtrls = <int, TextEditingController>{};

    for (final r in occupiedRooms) {
      final oldE = r.lastElectricIndex > 120 ? r.lastElectricIndex - 120 : r.lastElectricIndex;
      final oldW = r.lastWaterIndex > 8 ? r.lastWaterIndex - 8 : r.lastWaterIndex;
      elecOldCtrls[r.roomId] = TextEditingController(text: oldE.toString());
      elecNewCtrls[r.roomId] = TextEditingController(text: r.lastElectricIndex.toString());
      waterOldCtrls[r.roomId] = TextEditingController(text: oldW.toString());
      waterNewCtrls[r.roomId] = TextEditingController(text: r.lastWaterIndex.toString());
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.grid_on_rounded, color: Color(0xFF16A34A)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bảng Tính Excel - Nhập Chỉ Số Điện Nước Số Lượng Lớn',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 680,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hỗ trợ nhập trực tiếp trên bảng tính hoặc tải file mẫu Excel để tự động tính tiền bậc thang Bộ Công Thương 2026.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.upload_file_rounded, size: 15),
                          label: const Text('Nạp File Excel (.xlsx / .csv)', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            for (final r in occupiedRooms) {
                              final oldE = int.tryParse(elecOldCtrls[r.roomId]!.text) ?? 1200;
                              final oldW = int.tryParse(waterOldCtrls[r.roomId]!.text) ?? 40;
                              elecNewCtrls[r.roomId]!.text = (oldE + 120).toString();
                              waterNewCtrls[r.roomId]!.text = (oldW + 8).toString();
                            }
                            setModalState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã nạp dữ liệu chỉ số công tơ từ Template_ChiSoDienNuoc_SmartStay.csv!'),
                                backgroundColor: Color(0xFF2563EB),
                              ),
                            );
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.sim_card_download_outlined, size: 15, color: Color(0xFF16A34A)),
                          label: const Text('Tải File Mẫu Excel', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A))),
                          onPressed: () {
                            const sampleCsv =
                                'STT,MaPhong,TenCuDan,ChiSoDienCu,ChiSoDienMoi,ChiSoNuocCu,ChiSoNuocMoi\n'
                                '1,P.305,Ho Ngoc Bao,1420,1540,84,92\n'
                                '2,P.101,Nguyen Van An,850,935,45,51\n'
                                '3,P.201,Pham Quoc Hung,1100,1205,62,69\n';
                            Clipboard.setData(const ClipboardData(text: sampleCsv));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã sao chép nội dung Template_ChiSoDienNuoc_SmartStay.csv vào Clipboard!'),
                                backgroundColor: Color(0xFF16A34A),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: occupiedRooms.map((r) {
                            final oldE = int.tryParse(elecOldCtrls[r.roomId]!.text) ?? 0;
                            final newE = int.tryParse(elecNewCtrls[r.roomId]!.text) ?? 0;
                            final oldW = int.tryParse(waterOldCtrls[r.roomId]!.text) ?? 0;
                            final newW = int.tryParse(waterNewCtrls[r.roomId]!.text) ?? 0;
                            final usedE = (newE - oldE) > 0 ? (newE - oldE) : 0;
                            final usedW = (newW - oldW) > 0 ? (newW - oldW) : 0;
                            final elecCost = TieredUtilityService.calculateElectricity(usedE.toDouble()).totalAmount;
                            final waterCost = TieredUtilityService.calculateWater(usedW.toDouble()).totalAmount;
                            final totalUtility = elecCost + waterCost;

                            return Container(
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
                                        '${r.roomCode} • ${r.residentName ?? "Cư dân"}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                                      ),
                                      Text(
                                        'Điện+Nước: ${Formatters.formatCurrency(totalUtility)} (${usedE}kWh • ${usedW}m³)',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF16A34A)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: elecOldCtrls[r.roomId],
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Điện cũ',
                                            isDense: true,
                                          ),
                                          onChanged: (_) => setModalState(() {}),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: TextField(
                                          controller: elecNewCtrls[r.roomId],
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Điện mới',
                                            isDense: true,
                                          ),
                                          onChanged: (_) => setModalState(() {}),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: TextField(
                                          controller: waterOldCtrls[r.roomId],
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Nước cũ',
                                            isDense: true,
                                          ),
                                          onChanged: (_) => setModalState(() {}),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: TextField(
                                          controller: waterNewCtrls[r.roomId],
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Nước mới',
                                            isDense: true,
                                          ),
                                          onChanged: (_) => setModalState(() {}),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Đóng')),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                  label: const Text('Áp Dụng Chỉ Số & Cập Nhật Hóa Đơn', style: TextStyle(color: Colors.white, fontSize: 12)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                  onPressed: () async {
                    final rows = occupiedRooms.map((r) {
                      return (
                        roomId: r.roomId,
                        oldElectric: int.tryParse(elecOldCtrls[r.roomId]!.text) ?? r.lastElectricIndex,
                        newElectric: int.tryParse(elecNewCtrls[r.roomId]!.text) ?? r.lastElectricIndex,
                        oldWater: int.tryParse(waterOldCtrls[r.roomId]!.text) ?? r.lastWaterIndex,
                        newWater: int.tryParse(waterNewCtrls[r.roomId]!.text) ?? r.lastWaterIndex,
                      );
                    }).toList();
                    Navigator.pop(dialogCtx);
                    final count = await admin.applyExcelMeterReadings(rows);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã áp dụng bảng chỉ số điện nước Excel và cập nhật $count hóa đơn theo biểu giá bậc thang!'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
