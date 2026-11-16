import 'package:flutter/material.dart';
import '../../theme/smartstay_theme.dart';
import '../../widgets/smartstay_ui.dart';
import '../../providers/invoice_provider.dart';
import '../../utils/provider_scope.dart';
import '../../utils/formatters.dart';
import 'invoice_detail_screen.dart';

class InvoiceListScreen extends StatelessWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final invoiceProv = context.watch<InvoiceProvider>();
    final invoices = invoiceProv.invoices;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? SmartStayColors.surfaceDark : SmartStayColors.surfaceLight;
    final borderColor =
        isDark ? SmartStayColors.borderDark : SmartStayColors.borderLight;
    final textPrimary = isDark
        ? SmartStayColors.textPrimaryDark
        : SmartStayColors.textPrimaryLight;
    final textSecondary = isDark
        ? SmartStayColors.textSecondaryDark
        : SmartStayColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hóa đơn & Thanh toán'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          invoiceProv.loadInvoices();
          showSmartStayToast(
            context,
            'Đã cập nhật danh sách hóa đơn!',
            isSuccess: true,
          );
        },
        child: invoices.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SmartStayEmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'Chưa có hóa đơn nào',
                    subtitle:
                        'Các hóa đơn tiền phòng và điện nước hàng tháng sẽ hiển thị tại đây.',
                    actionLabel: 'Tải lại',
                    onAction: invoiceProv.loadInvoices,
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: invoices.length,
                itemBuilder: (context, index) {
                  final inv = invoices[index];
                  final isUnpaid = !inv.isFullyPaid;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUnpaid
                            ? SmartStayColors.primary.withValues(alpha: 0.45)
                            : borderColor,
                        width: isUnpaid ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.16 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                InvoiceDetailScreen(invoiceId: inv.invoiceId),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tháng ${AppFormatters.monthYear(inv.billingMonth)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppFormatters.invoiceStatusColor(
                                            inv.status)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    inv.status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppFormatters.invoiceStatusColor(
                                          inv.status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Mã: ${inv.invoiceCode} • Phòng: ${inv.roomCode}',
                              style:
                                  TextStyle(fontSize: 12, color: textSecondary),
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Số tiền:',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: textSecondary)),
                                    const SizedBox(height: 2),
                                    Text(
                                      AppFormatters.currency(inv.totalAmount),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isUnpaid
                                            ? SmartStayColors.primary
                                            : textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => InvoiceDetailScreen(
                                            invoiceId: inv.invoiceId),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isUnpaid
                                        ? SmartStayColors.primary
                                        : (isDark
                                            ? SmartStayColors.bgDark
                                            : const Color(0xFFF1F5F9)),
                                    foregroundColor:
                                        isUnpaid ? Colors.white : textPrimary,
                                    elevation: 0,
                                    minimumSize: const Size(0, 44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                      isUnpaid ? 'Thanh toán' : 'Xem chi tiết'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
