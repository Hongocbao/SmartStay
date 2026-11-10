import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/admin_models.dart';
import '../../models/managed_contract_model.dart';
import '../../providers/admin_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/provider_scope.dart';

class AdminContractsScreen extends StatefulWidget {
  const AdminContractsScreen({super.key});

  @override
  State<AdminContractsScreen> createState() => _AdminContractsScreenState();
}

class _AdminContractsScreenState extends State<AdminContractsScreen> {
  String _selectedFilter = 'Tất cả';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final allContracts = admin.contracts;

    final activeCount = allContracts.where((c) => c.isActive).length;
    final expiringCount = allContracts.where((c) => c.isExpiringSoon).length;

    final filtered = allContracts.where((c) {
      if (_selectedFilter == 'Đang hiệu lực' && !c.isActive) return false;
      if (_selectedFilter == 'Sắp hết hạn' && !c.isExpiringSoon) return false;
      if (_selectedFilter == 'Đã thanh lý' && c.isActive) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return c.contractCode.toLowerCase().contains(q) ||
            c.roomCode.toLowerCase().contains(q) ||
            c.residentName.toLowerCase().contains(q) ||
            c.residentPhone.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Quản Lý Cư Dân & Hợp Đồng Lưu Trú',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Nhập Cư Dân Hàng Loạt (Excel)',
            icon: const Icon(Icons.upload_file_rounded, color: Color(0xFF16A34A)),
            onPressed: () => _showBulkExcelModal(context, admin),
          ),
          IconButton(
            tooltip: 'Xuất Excel Hợp Đồng',
            icon: const Icon(Icons.download_rounded, color: Color(0xFF2563EB)),
            onPressed: () => _showExportCsvModal(context, admin),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        onPressed: () => _showCreateContractModal(context, admin),
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text(
          'Lập hợp đồng mới',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Top Summary & Action Bar (giống /HopDong/Index trên Web)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildStatBadge(
                      label: 'Đang hiệu lực',
                      count: activeCount,
                      color: const Color(0xFF16A34A),
                      bgColor: const Color(0xFFF0FDF4),
                    ),
                    const SizedBox(width: 8),
                    _buildStatBadge(
                      label: 'Sắp hết hạn',
                      count: expiringCount,
                      color: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFFFBEB),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () => _showBulkExcelModal(context, admin),
                      icon: const Icon(Icons.table_view_rounded, size: 16),
                      label: const Text('Nhập Excel', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF16A34A),
                        side: const BorderSide(color: Color(0xFF16A34A)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton.icon(
                      onPressed: () => _showExportCsvModal(context, admin),
                      icon: const Icon(Icons.file_download_outlined, size: 16),
                      label: const Text('Xuất Excel', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo mã HĐ, số phòng (P.305), tên cư dân, SĐT...',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final tab in [
                        'Tất cả',
                        'Đang hiệu lực',
                        'Sắp hết hạn',
                        'Đã thanh lý',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(tab, style: const TextStyle(fontSize: 12)),
                            selected: _selectedFilter == tab,
                            onSelected: (_) => setState(() => _selectedFilter = tab),
                            selectedColor: const Color(0xFFDBEAFE),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Không có hợp đồng nào khớp bộ lọc.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final contract = filtered[index];
                      return _buildContractCard(context, admin, contract);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractCard(
    BuildContext context,
    AdminProvider admin,
    ManagedContractModel c,
  ) {
    final statusLabel = c.displayStatus;
    final isExpiring = statusLabel == 'Sắp hết hạn' || statusLabel == 'Quá hạn';
    final statusColor = !c.isActive
        ? const Color(0xFF64748B)
        : (isExpiring ? const Color(0xFFD97706) : const Color(0xFF16A34A));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpiring ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
          width: isExpiring ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  c.roomCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  c.contractCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${c.residentName} • ${c.residentPhone}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Thời hạn: ${AppFormatters.date(c.startDate)} - ${AppFormatters.date(c.endDate)}'
                  '${c.isExpiringSoon ? ' (Còn ${c.daysRemaining} ngày)' : ''}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Giá thuê/tháng', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  Text(
                    AppFormatters.currency(c.monthlyRent),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tiền cọc đảm bảo', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  Text(
                    AppFormatters.currency(c.depositAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showElectronicContractPdfModal(context, c),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 15),
                    label: const Text('Xem PDF', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                  if (c.isActive) ...[
                    const SizedBox(width: 6),
                    FilledButton.tonalIcon(
                      onPressed: () => _showRenewDialog(context, admin, c),
                      icon: const Icon(Icons.autorenew_rounded, size: 15),
                      label: const Text('Gia hạn', style: TextStyle(fontSize: 12)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Modal xem Bản Hợp Đồng Điện Tử Lưu Trú PDF (CA + OTP) giống hệt /HopDong/Index trên Web
  void _showElectronicContractPdfModal(BuildContext context, ManagedContractModel c) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hợp Đồng Điện Tử ${c.contractCode}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                const Text(
                  'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM\nĐộc lập - Tự do - Hạnh phúc\n***',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Text(
                  'HỢP ĐỒNG THUÊ PHÒNG LƯU TRÚ CO-LIVING\nSố: ${c.contractCode}/HĐT-SMARTSTAY',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BÊN CHO THUÊ (BÊN A): BAN QUẢN LÝ TÒA NHÀ SMARTSTAY',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const Text(
                        'Đại diện: Ông Nguyễn Hoàng Nam • Hotline: 1900 888 999',
                        style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'BÊN THUÊ (BÊN B): ${c.residentName.toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        'SĐT: ${c.residentPhone} • CCCD: ${c.nationalId.isEmpty ? "079203001234" : c.nationalId}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),
                      Text(
                        'Căn hộ/Phòng thuê: ${c.roomCode} • Thời hạn: ${AppFormatters.date(c.startDate)} đến ${AppFormatters.date(c.endDate)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ĐIỀU KHOẢN TÀI CHÍNH:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Giá thuê hàng tháng: ${AppFormatters.currency(c.monthlyRent)}/tháng (thanh toán từ ngày 01 đến ngày 05 qua VietQR).\n'
                  '• Tiền cọc thế chân: ${AppFormatters.currency(c.depositAmount)} (hoàn trả khi thanh lý hợp đồng và nghiệm thu tài sản).\n'
                  '• Điện nước: Thanh toán theo chỉ số công tơ thực tế áp dụng biểu giá bậc thang Bộ Công Thương.',
                  style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'ĐẠI DIỆN BÊN A',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            SizedBox(height: 4),
                            Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 22),
                            SizedBox(height: 2),
                            Text(
                              'ĐÃ KÝ SỐ CA:\nBAN QUẢN LÝ',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'ĐẠI DIỆN BÊN B',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            const Icon(Icons.fingerprint_rounded, color: Color(0xFF2563EB), size: 22),
                            const SizedBox(height: 2),
                            Text(
                              'XÁC THỰC OTP:\n${c.residentName.toUpperCase()}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Đóng'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã xuất bản in PDF hợp đồng ${c.contractCode}!'),
                            backgroundColor: const Color(0xFF16A34A),
                          ),
                        );
                      },
                      icon: const Icon(Icons.print_rounded, size: 16),
                      label: const Text('In / Lưu Hợp Đồng PDF'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRenewDialog(
    BuildContext context,
    AdminProvider admin,
    ManagedContractModel c,
  ) {
    int selectedMonths = 12;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Gia Hạn Hợp Đồng ${c.contractCode}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phòng: ${c.roomCode} • Cư dân: ${c.residentName}'),
              const SizedBox(height: 12),
              const Text(
                'Chọn thời gian gia hạn thêm:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: selectedMonths,
                items: const [
                  DropdownMenuItem(value: 6, child: Text('6 tháng')),
                  DropdownMenuItem(value: 12, child: Text('12 tháng (1 năm)')),
                  DropdownMenuItem(value: 24, child: Text('24 tháng (2 năm)')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedMonths = v);
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                admin.renewContract(c.contractCode, additionalMonths: selectedMonths);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Đã gia hạn hợp đồng ${c.contractCode} thêm $selectedMonths tháng!',
                    ),
                    backgroundColor: const Color(0xFF16A34A),
                  ),
                );
              },
              child: const Text('Xác nhận gia hạn'),
            ),
          ],
        ),
      ),
    );
  }

  /// Modal Lập Hợp Đồng Lưu Trú Mới & Ký Điện Tử
  void _showCreateContractModal(BuildContext context, AdminProvider admin) {
    final emptyRooms = admin.rooms.where((r) => r.status == 'Trống').toList();
    final selectableRooms = emptyRooms.isNotEmpty ? emptyRooms : admin.rooms;
    RoomItemModel selectedRoom = selectableRooms.first;
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final cccdCtrl = TextEditingController();
    final rentCtrl = TextEditingController(text: selectedRoom.rentPrice.round().toString());
    final depositCtrl = TextEditingController(text: (selectedRoom.rentPrice * 2).round().toString());
    int durationMonths = 12;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Lập Hợp Đồng Lưu Trú Mới',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Tạo hồ sơ cư trú, kích hoạt phòng và ký số điện tử',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: selectedRoom.roomId,
                  decoration: const InputDecoration(
                    labelText: 'Chọn phòng cho thuê',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: selectableRooms
                      .map(
                        (r) => DropdownMenuItem<int>(
                          value: r.roomId,
                          child: Text(
                            '${r.roomCode} (${r.roomType} - Tầng ${r.floor}) • ${r.status}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (roomId) {
                    if (roomId == null) return;
                    final found = selectableRooms.firstWhere((r) => r.roomId == roomId);
                    setModalState(() {
                      selectedRoom = found;
                      rentCtrl.text = found.rentPrice.round().toString();
                      depositCtrl.text = (found.rentPrice * 2).round().toString();
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên cư dân đại diện *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: cccdCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Số CCCD / CMND',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: durationMonths,
                  decoration: const InputDecoration(
                    labelText: 'Thời hạn hợp đồng',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 6, child: Text('6 tháng')),
                    DropdownMenuItem(value: 12, child: Text('12 tháng (1 năm)')),
                    DropdownMenuItem(value: 24, child: Text('24 tháng (2 năm)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setModalState(() => durationMonths = v);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: rentCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Giá thuê/tháng (VNĐ)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: depositCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tiền cọc đảm bảo (VNĐ)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập đầy đủ họ tên và số điện thoại cư dân!'),
                        ),
                      );
                      return;
                    }
                    final created = admin.createNewContract(
                      roomId: selectedRoom.roomId,
                      residentName: nameCtrl.text,
                      residentPhone: phoneCtrl.text,
                      nationalId: cccdCtrl.text.isEmpty ? '079203009876' : cccdCtrl.text,
                      startDate: DateTime.now(),
                      durationMonths: durationMonths,
                      monthlyRent: double.tryParse(rentCtrl.text) ?? selectedRoom.rentPrice,
                      depositAmount:
                          double.tryParse(depositCtrl.text) ?? (selectedRoom.rentPrice * 2),
                    );
                    Navigator.pop(ctx);
                    if (created != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Đã tạo & ký điện tử hợp đồng ${created.contractCode} cho phòng ${created.roomCode}!',
                          ),
                          backgroundColor: const Color(0xFF16A34A),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.verified_user_rounded),
                  label: const Text('Tạo Hợp Đồng & Ký Điện Tử'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Modal Nhập Danh Sách Cư Dân & Hợp Đồng Bằng Excel (giống /HopDong/Index trên Web)
  void _showBulkExcelModal(BuildContext context, AdminProvider admin) {
    final rows = <Map<String, TextEditingController>>[
      {
        'name': TextEditingController(text: 'Phạm Minh Tuấn'),
        'phone': TextEditingController(text: '0918223344'),
        'cccd': TextEditingController(text: '079203005511'),
        'room': TextEditingController(text: 'P.102'),
        'rent': TextEditingController(text: '4500000'),
        'deposit': TextEditingController(text: '9000000'),
      },
      {
        'name': TextEditingController(text: 'Đặng Ngọc Ánh'),
        'phone': TextEditingController(text: '0987112233'),
        'cccd': TextEditingController(text: '079203006622'),
        'room': TextEditingController(text: 'P.202'),
        'rent': TextEditingController(text: '3800000'),
        'deposit': TextEditingController(text: '7600000'),
      },
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.table_chart_rounded, color: Color(0xFF16A34A)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nhập Cư Dân & Hợp Đồng Bằng Excel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.cloud_done_rounded, color: Color(0xFF16A34A), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Hỗ trợ nhập bảng tính hàng loạt cư dân mới • Tự động đồng bộ Supabase Cloud',
                            style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (int i = 0; i < rows.length; i++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dòng #${i + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: rows[i]['name'],
                                  decoration: const InputDecoration(
                                    labelText: 'Họ và tên',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: rows[i]['room'],
                                  decoration: const InputDecoration(
                                    labelText: 'Mã phòng',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: rows[i]['phone'],
                                  decoration: const InputDecoration(
                                    labelText: 'SĐT',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: rows[i]['rent'],
                                  decoration: const InputDecoration(
                                    labelText: 'Giá thuê',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () {
                      setModalState(() {
                        rows.add({
                          'name': TextEditingController(),
                          'phone': TextEditingController(),
                          'cccd': TextEditingController(text: '079203009900'),
                          'room': TextEditingController(text: 'P.302'),
                          'rent': TextEditingController(text: '3500000'),
                          'deposit': TextEditingController(text: '7000000'),
                        });
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm dòng cư dân'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
              onPressed: () {
                final payload = rows
                    .map(
                      (r) => {
                        'name': r['name']!.text,
                        'phone': r['phone']!.text,
                        'cccd': r['cccd']!.text,
                        'room': r['room']!.text,
                        'rent': r['rent']!.text,
                        'deposit': r['deposit']!.text,
                      },
                    )
                    .toList();
                final count = admin.bulkImportContracts(payload);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã lưu $count cư dân & tạo hợp đồng hàng loạt thành công!'),
                    backgroundColor: const Color(0xFF16A34A),
                  ),
                );
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Lưu Cư Dân & Tạo HĐ Hàng Loạt'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportCsvModal(BuildContext context, AdminProvider admin) {
    final csv = admin.exportContractsCsv();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xuất Báo Cáo Hợp Đồng (Excel / CSV)'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: SelectableText(
              csv,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csv));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã sao chép dữ liệu CSV Hợp Đồng vào bộ nhớ tạm!'),
                  backgroundColor: Color(0xFF2563EB),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Sao chép CSV'),
          ),
        ],
      ),
    );
  }
}
