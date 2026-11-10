import 'package:flutter/material.dart';
import '../../services/system_config.dart';
import '../../utils/formatters.dart';

class AdminSystemConfigScreen extends StatefulWidget {
  const AdminSystemConfigScreen({super.key});

  @override
  State<AdminSystemConfigScreen> createState() => _AdminSystemConfigScreenState();
}

class _AdminSystemConfigScreenState extends State<AdminSystemConfigScreen> {
  final SystemConfig _cfg = SystemConfig();

  late String _selectedBankBin;
  late TextEditingController _accountNumberCtrl;
  late TextEditingController _accountHolderCtrl;

  late List<TextEditingController> _electricCtrls;
  late List<TextEditingController> _waterCtrls;

  late TextEditingController _mqttCtrl;
  late TextEditingController _supabaseCtrl;
  late TextEditingController _heartbeatCtrl;

  @override
  void initState() {
    super.initState();
    _selectedBankBin = _cfg.bankBin;
    _accountNumberCtrl = TextEditingController(text: _cfg.accountNumber);
    _accountHolderCtrl = TextEditingController(text: _cfg.accountHolder);

    _electricCtrls = _cfg.electricPrices
        .map((p) => TextEditingController(text: p.round().toString()))
        .toList();
    _waterCtrls = _cfg.waterPrices
        .map((p) => TextEditingController(text: p.round().toString()))
        .toList();

    _mqttCtrl = TextEditingController(text: _cfg.mqttHost);
    _supabaseCtrl = TextEditingController(text: _cfg.supabaseHost);
    _heartbeatCtrl = TextEditingController(text: _cfg.heartbeatSeconds.toString());
  }

  @override
  void dispose() {
    _accountNumberCtrl.dispose();
    _accountHolderCtrl.dispose();
    for (final c in _electricCtrls) {
      c.dispose();
    }
    for (final c in _waterCtrls) {
      c.dispose();
    }
    _mqttCtrl.dispose();
    _supabaseCtrl.dispose();
    _heartbeatCtrl.dispose();
    super.dispose();
  }

  void _saveConfig() {
    final ePrices = _electricCtrls
        .map((c) => double.tryParse(c.text.trim()) ?? 1800.0)
        .toList();
    final wPrices = _waterCtrls
        .map((c) => double.tryParse(c.text.trim()) ?? 12000.0)
        .toList();

    _cfg.save(
      bankBin: _selectedBankBin,
      accountNumber: _accountNumberCtrl.text,
      accountHolder: _accountHolderCtrl.text,
      electricPrices: ePrices,
      waterPrices: wPrices,
      mqttHost: _mqttCtrl.text,
      supabaseHost: _supabaseCtrl.text,
      heartbeatSeconds: int.tryParse(_heartbeatCtrl.text.trim()) ?? 30,
    );

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Đã lưu cấu hình hệ thống! Mã VietQR và biểu giá điện nước bậc thang đã được cập nhật.',
        ),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sampleQrUrl = _cfg.vietQrUrl(
      amount: 3500000,
      content: 'HD1126 P305 SMARTSTAY',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Cấu Hình Hệ Thống & Cổng VietQR',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner trạng thái Supabase Cloud
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_rounded, color: Color(0xFF16A34A)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Supabase Cloud PostgreSQL (${_cfg.supabaseHost}): Đã kết nối',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 1. Cổng Thanh Toán VietQR NAPAS 247
            _buildSectionCard(
              icon: Icons.qr_code_2_rounded,
              iconColor: const Color(0xFF2563EB),
              title: '1. Cổng Thanh Toán VietQR NAPAS 247',
              subtitle: 'Tự động gắn mã QR động vào hóa đơn tiền phòng từng căn hộ',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBankBin,
                    decoration: const InputDecoration(
                      labelText: 'Ngân hàng thụ hưởng',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: SystemConfig.banks
                        .map(
                          (b) => DropdownMenuItem(
                            value: b.bin,
                            child: Text('${b.fullName} (${b.bin})', style: const TextStyle(fontSize: 13)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedBankBin = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _accountNumberCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Số tài khoản nhận tiền',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _accountHolderCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên chủ tài khoản (In hoa không dấu)',
                      border: OutlineInputBorder(),
                      isDense: true,
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
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            sampleQrUrl,
                            width: 96,
                            height: 96,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const SizedBox(
                              width: 96,
                              height: 96,
                              child: Icon(Icons.qr_code_2, size: 48),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Xem trước mã QR mẫu (compact2)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ngân hàng: ${_cfg.bank.shortName}\nSTK: ${_accountNumberCtrl.text}\nChủ TK: ${_accountHolderCtrl.text}\nMẫu thử: ${AppFormatters.currency(3500000)}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Biểu Giá Điện & Nước Bậc Thang
            _buildSectionCard(
              icon: Icons.bolt_rounded,
              iconColor: const Color(0xFFD97706),
              title: '2. Biểu Giá Điện & Nước Bậc Thang',
              subtitle: 'Áp dụng công thức lũy tiến tự động khi chốt chỉ số công tơ',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Biểu giá Điện sinh hoạt (đ/kWh):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPriceField('Bậc 1 (0-50 kWh)', _electricCtrls[0], 'đ/kWh'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPriceField('Bậc 2 (51-100 kWh)', _electricCtrls[1], 'đ/kWh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPriceField('Bậc 3 (101-200 kWh)', _electricCtrls[2], 'đ/kWh'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPriceField('Bậc 4 (> 200 kWh)', _electricCtrls[3], 'đ/kWh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Biểu giá Nước sinh hoạt (đ/m³):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPriceField('Bậc 1 (0-5 m³)', _waterCtrls[0], 'đ/m³'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPriceField('Bậc 2 (6-10 m³)', _waterCtrls[1], 'đ/m³'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPriceField('Bậc 3 (> 10 m³)', _waterCtrls[2], 'đ/m³'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Cổng Kết Nối IoT Gateway & Supabase Cloud
            _buildSectionCard(
              icon: Icons.router_rounded,
              iconColor: const Color(0xFF10B981),
              title: '3. Cổng Kết Nối IoT Gateway & Supabase Cloud',
              subtitle: 'Giám sát trạng thái 20 khóa phòng RFID & CSDL đám mây PostgreSQL',
              child: Column(
                children: [
                  TextField(
                    controller: _mqttCtrl,
                    decoration: const InputDecoration(
                      labelText: 'MQTT Broker Host',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _supabaseCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Supabase Host',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _heartbeatCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Chu kỳ nhịp tim Heartbeat IoT (giây)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _saveConfig,
                icon: const Icon(Icons.save_rounded),
                label: const Text(
                  'LƯU THAY ĐỔI CẤU HÌNH',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceField(String label, TextEditingController ctrl, String suffix) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          child,
        ],
      ),
    );
  }
}
