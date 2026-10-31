import 'package:flutter/material.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/provider_scope.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = 'Máy lạnh';
  String _selectedPriority = 'Trung bình';
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _hasAttachedImage = false;
  String? _aiTriageSuggestion;

  final List<String> _categories = [
    'Máy lạnh',
    'Điện',
    'Nước',
    'Nội thất',
    'Khóa từ / Cửa',
    'Khác',
  ];

  final List<String> _priorities = ['Thấp', 'Trung bình', 'Cao', 'Khẩn cấp'];

  @override
  void initState() {
    super.initState();
    _descController.addListener(_analyzeTextForAiTriage);
    _titleController.addListener(_analyzeTextForAiTriage);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  /// Tính năng thông minh: AI Triage phân loại mức độ khẩn cấp tự động
  void _analyzeTextForAiTriage() {
    final text = '${_titleController.text} ${_descController.text}'.toLowerCase();
    String? suggestion;
    String? newCat;
    String? newPriority;

    if (text.contains('cháy') || text.contains('chập') || text.contains('nổ') || text.contains('khói')) {
      newCat = 'Điện';
      newPriority = 'Khẩn cấp';
      suggestion = '🤖 AI Triage: Phát hiện dấu hiệu cháy chập điện nguy hiểm! Tự động chọn Danh mục Điện & Ưu tiên Khẩn cấp (SLA 4h).';
    } else if (text.contains('tràn nước') || text.contains('ngập') || text.contains('vỡ ống') || text.contains('rò rỉ')) {
      newCat = 'Nước';
      newPriority = 'Khẩn cấp';
      suggestion = '🤖 AI Triage: Phát hiện sự cố rò rỉ/ngập nước! Tự động nâng ưu tiên Khẩn cấp để tránh hư hại sàn gỗ.';
    } else if (text.contains('kẹt cửa') || text.contains('không mở được') || text.contains('khóa hết pin')) {
      newCat = 'Khóa từ / Cửa';
      newPriority = 'Cao';
      suggestion = '🤖 AI Triage: Phát hiện sự cố khóa cửa IoT không mở được! Đề xuất Ưu tiên Cao.';
    }

    if (suggestion != null && suggestion != _aiTriageSuggestion) {
      setState(() {
        _aiTriageSuggestion = suggestion;
        if (newCat != null) _selectedCategory = newCat;
        if (newPriority != null) _selectedPriority = newPriority;
      });
    }
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final userRoom = auth.contract?.roomCode ?? auth.user?.effectiveRoomCode ?? 'P.101';
    final userName = auth.user?.fullName ?? 'Cư dân';

    final prov = context.read<TicketProvider>();
    final success = await prov.createTicket(
      categoryName: _selectedCategory,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      priority: _selectedPriority,
      roomCode: userRoom,
      authorName: userName,
      imageUrl: _hasAttachedImage
          ? 'https://img.vietqr.io/image/970422-0987654321-compact2.png'
          : null,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi yêu cầu sự cố! Kỹ thuật viên sẽ phản hồi sớm theo cam kết SLA.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketProv = context.watch<TicketProvider>();
    final auth = context.watch<AuthProvider>();
    final userRoom = auth.contract?.roomCode ?? auth.user?.effectiveRoomCode ?? 'P.101';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Báo sự cố mới'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông tin phòng lấy động từ phiên đăng nhập
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Color(0xFF2563EB), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Địa điểm: Phòng $userRoom - ${auth.contract?.buildingName ?? "Tòa nhà A"}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8), fontSize: 13),
                    ),
                  ],
                ),
              ),

              // Banner AI Triage gợi ý
              if (_aiTriageSuggestion != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD8B4FE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF9333EA), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _aiTriageSuggestion!,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF6B21A8), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // Danh mục sự cố
              const Text('Phân loại sự cố *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCategory = v);
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.category_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 18),

              // Tiêu đề sự cố
              const Text('Tiêu đề sự cố *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tiêu đề sự cố' : null,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Máy lạnh chảy nước, chập ổ cắm điện',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 18),

              // Mô tả chi tiết
              const Text('Mô tả chi tiết tình trạng *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng mô tả chi tiết để kỹ thuật chuẩn bị' : null,
                decoration: InputDecoration(
                  hintText: 'Mô tả hiện tượng, thời gian xảy ra, tần suất...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 18),

              // Mức độ ưu tiên
              const Text('Mức độ khẩn cấp (SLA cam kết)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _priorities.map((p) {
                  final isSelected = _selectedPriority == p;
                  return ChoiceChip(
                    label: Text(p == 'Khẩn cấp' ? 'Khẩn cấp (4h)' : (p == 'Cao' ? 'Cao (12h)' : (p == 'Trung bình' ? 'Trung bình (24h)' : 'Thấp (48h)'))),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedPriority = p);
                    },
                    selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Đính kèm hình ảnh
              const Text('Hình ảnh hiện trường (Khuyến nghị)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  setState(() {
                    _hasAttachedImage = !_hasAttachedImage;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_hasAttachedImage ? 'Đã đính kèm ảnh chụp hiện trường' : 'Đã bỏ đính kèm ảnh'),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _hasAttachedImage ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                      width: _hasAttachedImage ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _hasAttachedImage ? Icons.check_circle : Icons.camera_alt_outlined,
                          color: _hasAttachedImage ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _hasAttachedImage
                              ? 'Đã đính kèm 1 ảnh chụp thiết bị hỏng (Chạm để đổi)'
                              : 'Chạm để chụp hoặc chọn ảnh từ thư viện',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _hasAttachedImage ? FontWeight.bold : FontWeight.normal,
                            color: _hasAttachedImage ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Nút Gửi
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: ticketProv.isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: ticketProv.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Gửi phiếu sự cố ngay',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
