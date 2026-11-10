import 'package:flutter/material.dart';
import '../../utils/provider_scope.dart';
import '../../providers/admin_provider.dart';
import '../../models/admin_models.dart';
import '../../utils/formatters.dart';
import 'admin_finance_screen.dart';
import 'admin_kanban_screen.dart';

class AdminRoomMatrixScreen extends StatefulWidget {
  const AdminRoomMatrixScreen({super.key});

  @override
  State<AdminRoomMatrixScreen> createState() => _AdminRoomMatrixScreenState();
}

class _AdminRoomMatrixScreenState extends State<AdminRoomMatrixScreen> {
  int _selectedFloor = 0; // 0 = Tất cả
  String _selectedStatus = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final allRooms = admin.rooms;

    final filteredRooms = allRooms.where((room) {
      final matchFloor = _selectedFloor == 0 || room.floor == _selectedFloor;
      final matchStatus = _selectedStatus == 'Tất cả' || room.status == _selectedStatus;
      return matchFloor && matchStatus;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Sơ Đồ Phòng Trực Quan (Room Matrix)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_home_work_rounded, size: 16, color: Colors.white),
              label: const Text('Thêm phòng mới', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _showAddRoomDialog(context, admin),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Floor Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFloorChip('Tất cả tầng', 0),
                  const SizedBox(width: 8),
                  _buildFloorChip('Tầng 1 (Studio)', 1),
                  const SizedBox(width: 8),
                  _buildFloorChip('Tầng 2 (Co-Living)', 2),
                  const SizedBox(width: 8),
                  _buildFloorChip('Tầng 3 (Co-Living)', 3),
                  const SizedBox(width: 8),
                  _buildFloorChip('Tầng 4 (Ban công)', 4),
                  const SizedBox(width: 8),
                  _buildFloorChip('Tầng 5 (Penthouse)', 5),
                ],
              ),
            ),
          ),

          // Status Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChip('Tất cả', null),
                  const SizedBox(width: 8),
                  _buildStatusChip('Đang ở', const Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  _buildStatusChip('Trống', const Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  _buildStatusChip('Đã đặt', const Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  _buildStatusChip('Bảo trì', const Color(0xFFEF4444)),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Rooms Grid
          Expanded(
            child: filteredRooms.isEmpty
                ? const Center(
                    child: Text('Không tìm thấy phòng phù hợp bộ lọc.', style: TextStyle(color: Color(0xFF64748B))),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: filteredRooms.length,
                    itemBuilder: (context, index) {
                      final room = filteredRooms[index];
                      return _buildRoomCard(room, admin);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorChip(String title, int floor) {
    final isSelected = _selectedFloor == floor;
    return ChoiceChip(
      label: Text(title),
      selected: isSelected,
      selectedColor: const Color(0xFF2563EB),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (val) {
        setState(() {
          _selectedFloor = floor;
        });
      },
    );
  }

  Widget _buildStatusChip(String title, Color? color) {
    final isSelected = _selectedStatus == title;
    return ChoiceChip(
      avatar: color != null
          ? Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle))
          : null,
      label: Text(title),
      selected: isSelected,
      selectedColor: const Color(0xFF0F172A),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (val) {
        setState(() {
          _selectedStatus = title;
        });
      },
    );
  }

  Widget _buildRoomCard(RoomItemModel room, AdminProvider admin) {
    Color statusColor;
    Color statusBgColor;
    switch (room.status) {
      case 'Đang ở':
        statusColor = const Color(0xFF2563EB);
        statusBgColor = const Color(0xFFEFF6FF);
        break;
      case 'Trống':
        statusColor = const Color(0xFF10B981);
        statusBgColor = const Color(0xFFF0FDF4);
        break;
      case 'Đã đặt':
        statusColor = const Color(0xFFF59E0B);
        statusBgColor = const Color(0xFFFFFBEB);
        break;
      default:
        statusColor = const Color(0xFFEF4444);
        statusBgColor = const Color(0xFFFEF2F2);
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _showRoomDetailsModal(context, room, admin),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: room.status == 'Đang ở' ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
              width: room.status == 'Đang ở' ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    room.roomCode,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      room.status,
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Text(
                room.roomType,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Divider(height: 12, color: Color(0xFFF1F5F9)),
              if (room.status == 'Đang ở' && room.residentName != null) ...[
                Row(
                  children: [
                    const Icon(Icons.person_rounded, size: 14, color: Color(0xFF2563EB)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        room.residentName!,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${Formatters.formatCurrency(room.rentPrice)}/tháng',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              ] else if (room.status == 'Trống') ...[
                const Text(
                  'Sẵn sàng đón khách mới',
                  style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w500),
                ),
                Text(
                  'Giá: ${Formatters.formatCurrency(room.rentPrice)}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              ] else if (room.status == 'Đã đặt') ...[
                Text(
                  'Đã cọc: ${room.residentName ?? "Khách hẹn"}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.w500),
                ),
                Text(
                  Formatters.formatCurrency(room.depositAmount),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              ] else ...[
                const Text(
                  'Đang xử lý kỹ thuật',
                  style: TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.w500),
                ),
                const Text('Bảo trì định kỳ', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFFF59E0B)),
                      Text('${room.lastElectricIndex}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      const SizedBox(width: 6),
                      const Icon(Icons.water_drop_rounded, size: 12, color: Color(0xFF0284C7)),
                      Text('${room.lastWaterIndex}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        room.smartLockBattery > 20 ? Icons.battery_charging_full_rounded : Icons.battery_alert_rounded,
                        size: 13,
                        color: room.smartLockBattery > 20 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                      Text('${room.smartLockBattery}%', style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoomDetailsModal(BuildContext context, RoomItemModel room, AdminProvider admin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phòng ${room.roomCode} - ${room.roomType}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        '${room.buildingName} • Tầng ${room.floor} • ${room.area}m²',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      room.status,
                      style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              if (room.status == 'Đang ở') ...[
                _buildInfoRow('Cư dân thuê:', room.residentName ?? 'N/A'),
                _buildInfoRow('Số điện thoại:', room.residentPhone ?? 'N/A'),
                _buildInfoRow('Mã hợp đồng:', room.contractCode ?? 'N/A'),
                _buildInfoRow('Tiền cọc giữ chỗ:', Formatters.formatCurrency(room.depositAmount)),
                _buildInfoRow('Chỉ số điện kỳ gần nhất:', '${room.lastElectricIndex} kWh'),
                _buildInfoRow('Chỉ số nước kỳ gần nhất:', '${room.lastWaterIndex} m³'),
                _buildInfoRow('Pin khóa cửa thông minh:', '${room.smartLockBattery}% (Đang kết nối WiFi 2.4GHz)'),
              ] else if (room.status == 'Trống') ...[
                _buildInfoRow('Trạng thái:', 'Phòng trống, đã vệ sinh và kiểm tra trang thiết bị đầy đủ.'),
                _buildInfoRow('Đơn giá niêm yết:', '${Formatters.formatCurrency(room.rentPrice)} / tháng'),
                _buildInfoRow('Sức chứa tối đa:', '${room.capacity} người'),
                _buildInfoRow('Chỉ số điện chốt giao:', '${room.lastElectricIndex} kWh'),
                _buildInfoRow('Chỉ số nước chốt giao:', '${room.lastWaterIndex} m³'),
              ],

              const SizedBox(height: 20),

              // Action Buttons
              if (room.status == 'Trống') ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                    label: const Text('Làm Thủ Tục Nhận Phòng (Check-in)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showCheckInDialog(context, room, admin);
                    },
                  ),
                ),
              ] else if (room.status == 'Đang ở') ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.electric_meter_rounded, size: 16),
                        label: const Text('Ghi Điện Nước', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showRecordMeterDialog(context, room, admin);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.lock_open_rounded, size: 16, color: Color(0xFF0284C7)),
                        label: const Text('Mở Khóa', style: TextStyle(fontSize: 12, color: Color(0xFF0284C7))),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          admin.remoteUnlockRoom(room.roomCode);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Đã gửi lệnh mở khóa từ xa cho phòng ${room.roomCode}')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.white),
                        label: const Text('Trả Phòng', style: TextStyle(fontSize: 12, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmCheckOutDialog(context, room, admin);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.receipt_long_rounded, size: 15, color: Color(0xFF16A34A)),
                        label: const Text('Lập Hóa Đơn', style: TextStyle(fontSize: 12, color: Color(0xFF16A34A))),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFinanceScreen()));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.build_circle_outlined, size: 15, color: Color(0xFFD97706)),
                        label: const Text('Báo Sự Cố', style: TextStyle(fontSize: 12, color: Color(0xFFD97706))),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminKanbanScreen()));
                        },
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),
              // Đổi trạng thái trực tiếp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Chuyển trạng thái nhanh:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  DropdownButton<String>(
                    value: room.status,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'Trống', child: Text('Trống', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'Đang ở', child: Text('Đang ở', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'Đã đặt', child: Text('Đã đặt', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'Bảo trì', child: Text('Bảo trì', style: TextStyle(fontSize: 12))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        admin.updateRoomStatus(room.roomId, val);
                        Navigator.pop(ctx);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  void _showCheckInDialog(BuildContext context, RoomItemModel room, AdminProvider admin) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final depositCtrl = TextEditingController(text: (room.rentPrice * 2).toInt().toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Thủ Tục Nhận Phòng ${room.roomCode}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Họ và tên cư dân', prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Số điện thoại', prefixIcon: Icon(Icons.phone)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: depositCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tiền cọc (VNĐ)', prefixIcon: Icon(Icons.attach_money)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                  final dep = double.tryParse(depositCtrl.text) ?? (room.rentPrice * 2);
                  admin.checkInResident(
                    roomId: room.roomId,
                    residentName: nameCtrl.text,
                    residentPhone: phoneCtrl.text,
                    depositAmount: dep,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã nhận phòng thành công cho cư dân ${nameCtrl.text}!')),
                  );
                }
              },
              child: const Text('Xác nhận Check-in', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showRecordMeterDialog(BuildContext context, RoomItemModel room, AdminProvider admin) {
    final elecCtrl = TextEditingController(text: (room.lastElectricIndex + 85).toString());
    final waterCtrl = TextEditingController(text: (room.lastWaterIndex + 6).toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Ghi Chỉ Số Điện Nước - ${room.roomCode}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: elecCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Chỉ số điện mới (kWh)', prefixIcon: Icon(Icons.bolt)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: waterCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Chỉ số nước mới (m³)', prefixIcon: Icon(Icons.water_drop)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () {
                final e = int.tryParse(elecCtrl.text) ?? room.lastElectricIndex;
                final w = int.tryParse(waterCtrl.text) ?? room.lastWaterIndex;
                admin.recordMeters(room.roomId, e, w);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã ghi chỉ số mới cho phòng ${room.roomCode}!')),
                );
              },
              child: const Text('Lưu Chỉ Số'),
            ),
          ],
        );
      },
    );
  }

  void _confirmCheckOutDialog(BuildContext context, RoomItemModel room, AdminProvider admin) {
    // Tính tổng nợ hóa đơn chưa thanh toán của phòng này
    final unpaidInvoices = admin.allInvoices.where((i) => i.roomCode == room.roomCode && !i.isFullyPaid).toList();
    final totalUnpaidDebt = unpaidInvoices.fold<double>(0.0, (sum, i) => sum + i.remainingAmount);

    final damageCostCtrl = TextEditingController(text: '0');
    final inspectorCtrl = TextEditingController(text: 'Nguyễn Hoàng Nam (QLVH)');
    final noteCtrl = TextEditingController(text: 'Bàn giao đầy đủ 5 tài sản nguyên vẹn, thẻ từ và chìa khóa.');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setState) {
            final damageCost = double.tryParse(damageCostCtrl.text) ?? 0.0;
            final deposit = room.depositAmount;
            final refund = (deposit - totalUnpaidDebt - damageCost);
            final refundDisplay = refund > 0 ? refund : 0.0;

            return AlertDialog(
              title: Text('Biên Bản Thanh Lý & Trả Phòng - ${room.roomCode}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cư dân: ${room.residentName ?? "Cư dân"} • HĐ: ${room.contractCode ?? "Chưa rõ"}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 12),

                    // Bảng chiết tính tài chính
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tiền cọc ban đầu:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              Text(Formatters.formatCurrency(deposit),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Nợ hóa đơn chưa đóng:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              Text(
                                '- ${Formatters.formatCurrency(totalUnpaidDebt)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFDC2626)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Khấu trừ hư hao cơ sở vật chất:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              Text(
                                '- ${Formatters.formatCurrency(damageCost)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFDC2626)),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tiền cọc thực hoàn trả:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              Text(
                                Formatters.formatCurrency(refundDisplay),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    TextField(
                      controller: damageCostCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Chi phí khấu trừ đền bù tài sản (VNĐ)',
                        prefixIcon: Icon(Icons.handyman_rounded),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: inspectorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Người lập biên bản nghiệm thu',
                        prefixIcon: Icon(Icons.badge_rounded),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú hiện trạng bàn giao',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Hủy')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                  onPressed: () {
                    final dCost = double.tryParse(damageCostCtrl.text) ?? 0.0;
                    final settlement = admin.checkOutResidentWithSettlement(
                      roomId: room.roomId,
                      propertyDamageDeduction: dCost,
                      unpaidDebt: totalUnpaidDebt,
                      inspectorName: inspectorCtrl.text,
                      note: noteCtrl.text,
                    );
                    Navigator.pop(dialogCtx);
                    if (settlement != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã hoàn tất thanh lý phòng ${room.roomCode}. Tiền cọc hoàn trả cư dân: ${Formatters.formatCurrency(settlement.finalRefundAmount)}'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                  child: const Text('Xác nhận Thanh lý & Check-out', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddRoomDialog(BuildContext context, AdminProvider admin) {
    final codeCtrl = TextEditingController(text: 'P.308');
    final areaCtrl = TextEditingController(text: '25');
    final priceCtrl = TextEditingController(text: '3500000');
    int selectedFloor = 3;
    String selectedType = 'Studio 1 giường Co-Living';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.add_home_work_rounded, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Thêm Căn Hộ / Phòng Mới',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Mã số phòng (VD: P.308)',
                        prefixIcon: Icon(Icons.meeting_room_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: selectedFloor,
                      decoration: const InputDecoration(
                        labelText: 'Tầng',
                        prefixIcon: Icon(Icons.layers_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Tầng 1 (Studio)')),
                        DropdownMenuItem(value: 2, child: Text('Tầng 2 (Co-Living)')),
                        DropdownMenuItem(value: 3, child: Text('Tầng 3 (Co-Living)')),
                        DropdownMenuItem(value: 4, child: Text('Tầng 4 (Ban công)')),
                        DropdownMenuItem(value: 5, child: Text('Tầng 5 (Penthouse)')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => selectedFloor = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Loại phòng',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Studio 1 giường Co-Living', child: Text('Studio 1 giường Co-Living')),
                        DropdownMenuItem(value: 'Studio Ban công View Thoáng', child: Text('Studio Ban công View Thoáng')),
                        DropdownMenuItem(value: 'Deluxe 2 giường tầng', child: Text('Deluxe 2 giường tầng')),
                        DropdownMenuItem(value: 'Sky View Penthouse', child: Text('Sky View Penthouse')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => selectedType = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: areaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Diện tích (m²)',
                        prefixIcon: Icon(Icons.square_foot_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Giá thuê hàng tháng (VNĐ)',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Hủy')),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 16, color: Colors.white),
                  label: const Text('Lưu Phòng Mới', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  onPressed: () {
                    final newRoom = admin.addNewRoom(
                      roomCode: codeCtrl.text,
                      buildingName: 'Tòa nhà A',
                      floor: selectedFloor,
                      roomType: selectedType,
                      area: double.tryParse(areaCtrl.text) ?? 25.0,
                      capacity: selectedType.contains('2') ? 2 : 1,
                      rentPrice: double.tryParse(priceCtrl.text.replaceAll('.', '')) ?? 3500000,
                    );
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã thêm thành công căn hộ mới ${newRoom.roomCode} vào sơ đồ phòng Tầng $selectedFloor!'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
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
