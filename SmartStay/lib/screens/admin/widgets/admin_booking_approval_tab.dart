import 'package:flutter/material.dart';
import '../../../models/room_discovery_models.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/room_discovery_provider.dart';
import '../../../theme/smartstay_theme.dart';
import '../../../utils/provider_scope.dart';
import '../../../widgets/call_center_modal.dart';
import '../../../widgets/smartstay_ui.dart';

/// Tab "Duyệt yêu cầu đăng ký phòng" (PhieuDangKyPhong) dành cho Admin / Ban Quản lý.
/// Cho phép bấm Duyệt (tự động chuyển phòng sang Đã đặt + tạo bản nháp Hợp đồng) hoặc Từ chối.
class AdminBookingApprovalTab extends StatefulWidget {
  const AdminBookingApprovalTab({super.key});

  @override
  State<AdminBookingApprovalTab> createState() => _AdminBookingApprovalTabState();
}

class _AdminBookingApprovalTabState extends State<AdminBookingApprovalTab> {
  String _statusFilter = 'Tất cả'; // Tất cả | ChoDuyet | DaDuyet | TuChoi

  @override
  Widget build(BuildContext context) {
    final discovery = context.watch<RoomDiscoveryProvider>();
    final admin = context.read<AdminProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? SmartStayColors.surfaceDark : SmartStayColors.surfaceLight;
    final borderColor =
        isDark ? SmartStayColors.borderDark : SmartStayColors.borderLight;
    final textPrimary =
        isDark ? SmartStayColors.textPrimaryDark : SmartStayColors.textPrimaryLight;
    final textSecondary =
        isDark ? SmartStayColors.textSecondaryDark : SmartStayColors.textSecondaryLight;

    final all = discovery.registrations;
    final filtered = all.where((r) {
      if (_statusFilter == 'Tất cả') return true;
      return r.status == _statusFilter;
    }).toList();

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: surfaceColor,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Tất cả', 'Tất cả (${all.length})', isDark),
                const SizedBox(width: 8),
                _filterChip(
                  'ChoDuyet',
                  'Chờ duyệt (${all.where((e) => e.isPending).length})',
                  isDark,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  'DaDuyet',
                  'Đã duyệt (${all.where((e) => e.isApproved).length})',
                  isDark,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  'TuChoi',
                  'Từ chối (${all.where((e) => e.isRejected).length})',
                  isDark,
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: borderColor),
        Expanded(
          child: RefreshIndicator(
            color: SmartStayColors.primary,
            onRefresh: () => discovery.syncAll(silent: false, emitToasts: false),
            child: filtered.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SmartStayEmptyState(
                        icon: Icons.assignment_turned_in_outlined,
                        title: 'Chưa có yêu cầu đăng ký phòng nào',
                        subtitle:
                            'Khi cư dân hoặc người tìm phòng gửi phiếu từ mục "Khám phá & Thuê phòng", yêu cầu sẽ xuất hiện tại đây.',
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) => _buildRequestCard(
                      context,
                      filtered[idx],
                      discovery,
                      admin,
                      isDark,
                      surfaceColor,
                      borderColor,
                      textPrimary,
                      textSecondary,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String value, String label, bool isDark) {
    final selected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: SmartStayColors.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        color: selected
            ? Colors.white
            : (isDark
                ? SmartStayColors.textPrimaryDark
                : SmartStayColors.textPrimaryLight),
      ),
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => setState(() => _statusFilter = value),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    RoomRegistrationRequest req,
    RoomDiscoveryProvider discovery,
    AdminProvider admin,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final Color statusColor = req.isApproved
        ? SmartStayColors.success
        : (req.isRejected ? SmartStayColors.danger : SmartStayColors.warning);
    final d = req.expectedMoveInDate;
    final moveInStr =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: req.isPending
              ? SmartStayColors.primary.withValues(alpha: 0.4)
              : borderColor,
          width: req.isPending ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: SmartStayColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  req.roomCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: SmartStayColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      '${req.requestTypeLabel} • Mã phiếu: ${req.maPhieu}',
                      style: TextStyle(fontSize: 11.5, color: textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  req.statusLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _metaItem(Icons.phone_rounded, req.phone, textSecondary),
              if (req.nationalId != null && req.nationalId!.isNotEmpty)
                _metaItem(Icons.badge_outlined, 'CCCD: ${req.nationalId}', textSecondary),
              _metaItem(Icons.calendar_month_rounded, 'Dự kiến vào: $moveInStr', textSecondary),
            ],
          ),
          if (req.note != null && req.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Ghi chú: ${req.note}',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
            ),
          ],
          if (req.isApproved && req.draftContractCode != null) ...[
            const SizedBox(height: 10),
            Text(
              '✅ Đã chuyển ${req.roomCode} sang Đã đặt & tạo bản nháp Hợp đồng: ${req.draftContractCode}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: SmartStayColors.success,
              ),
            ),
          ],
          if (req.isRejected && req.rejectReason != null) ...[
            const SizedBox(height: 10),
            Text(
              'Lý do từ chối: ${req.rejectReason}',
              style: const TextStyle(fontSize: 12, color: SmartStayColors.danger),
            ),
          ],
          if (req.isPending) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await discovery.processRegistration(
                      request: req,
                      approve: true,
                    );
                    admin.createDraftContractFromBooking(
                      roomCode: req.roomCode,
                      residentName: req.fullName,
                      residentPhone: req.phone,
                      nationalId: req.nationalId,
                      startDate: req.expectedMoveInDate,
                      contractCode: result.draftContractCode,
                    );
                    if (!context.mounted) return;
                    showSmartStayToast(
                      context,
                      'Đã duyệt ${req.maPhieu} • Phòng ${req.roomCode} chuyển Đã đặt & tạo HĐ nháp ${result.draftContractCode ?? ''}',
                      isSuccess: true,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SmartStayColors.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text(
                    'Duyệt & Tạo HĐ Nháp',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showRejectReasonDialog(context, req, discovery),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SmartStayColors.danger,
                    side: const BorderSide(color: SmartStayColors.danger),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Từ chối', style: TextStyle(fontSize: 12.5)),
                ),
                OutlinedButton.icon(
                  onPressed: () => showSmartStayCallModal(
                    context,
                    initialTargetRole: 'CuDan',
                    initialTargetName: '${req.fullName} (${req.roomCode})',
                    initialVideo: true,
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.videocam_rounded, size: 18),
                  label: const Text('Gọi xác nhận', style: TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metaItem(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: SmartStayColors.primary),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Future<void> _showRejectReasonDialog(
    BuildContext context,
    RoomRegistrationRequest req,
    RoomDiscoveryProvider discovery,
  ) async {
    final reasonCtrl = TextEditingController(
      text: 'Phòng hiện đã có khách đặt cọc trước thời điểm bạn chọn.',
    );
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Từ chối phiếu ${req.maPhieu} (${req.roomCode})'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Lý do từ chối gửi tới người đăng ký',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SmartStayColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await discovery.processRegistration(
                request: req,
                approve: false,
                rejectReason: reasonCtrl.text.trim(),
              );
              if (!context.mounted) return;
              showSmartStayToast(
                context,
                'Đã từ chối phiếu đăng ký ${req.maPhieu}.',
              );
            },
            child: const Text('Xác nhận Từ chối'),
          ),
        ],
      ),
    );
    reasonCtrl.dispose();
  }
}
