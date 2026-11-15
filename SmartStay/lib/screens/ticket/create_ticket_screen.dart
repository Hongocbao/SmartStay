import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_transport.dart';
import '../../utils/provider_scope.dart';
import '../../widgets/call_center_modal.dart';

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
  String? _pickedImageDataUrl;
  String? _pickedImageName;
  String? _pickedVideoUrl;
  String? _pickedVideoName;
  String? _aiTriageSuggestion;

  Uint8List? _decodeDataUrlBytes(String? dataUrl) {
    if (dataUrl == null || !dataUrl.startsWith('data:image')) return null;
    final comma = dataUrl.indexOf(',');
    if (comma <= 0 || comma + 1 >= dataUrl.length) return null;
    try {
      return base64Decode(dataUrl.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }

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
      imageUrl: _pickedImageDataUrl,
      videoUrl: _pickedVideoUrl,
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
                initialValue: _selectedCategory,
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

              // Đính kèm hình ảnh & video hiện trường trực quan
              const Text(
                'Hình ảnh & Video hiện trường trực quan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              if (_decodeDataUrlBytes(_pickedImageDataUrl) != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _decodeDataUrlBytes(_pickedImageDataUrl)!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (_pickedVideoUrl != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.videocam_rounded, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Video sự cố: ${_pickedVideoName ?? 'Clip hiện trường HD'}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() {
                          _pickedVideoUrl = null;
                          _pickedVideoName = null;
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await pickMediaFile(
                        acceptVideo: false,
                        useCamera: true,
                      );
                      if (picked == null || !mounted) return;
                      setState(() {
                        _pickedImageDataUrl = picked.dataUrl;
                        _pickedImageName = picked.fileName;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      side: BorderSide(
                        color: _pickedImageDataUrl != null
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF2563EB),
                      ),
                    ),
                    icon: Icon(
                      _pickedImageDataUrl != null
                          ? Icons.check_circle_rounded
                          : Icons.camera_alt_rounded,
                      size: 18,
                      color: _pickedImageDataUrl != null
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF2563EB),
                    ),
                    label: Text(
                      _pickedImageName == null
                          ? 'Chụp / Chọn ảnh'
                          : 'Đổi ảnh (${_pickedImageName!})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await pickMediaFile(
                        acceptVideo: true,
                        useCamera: true,
                      );
                      if (picked == null || !mounted) return;
                      setState(() {
                        _pickedVideoUrl = picked.dataUrl;
                        _pickedVideoName = picked.fileName;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                    ),
                    icon: const Icon(
                      Icons.videocam_rounded,
                      size: 18,
                      color: Color(0xFFDC2626),
                    ),
                    label: const Text(
                      'Quay / Tải Video',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFFDC2626)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _pickedVideoUrl =
                            'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4';
                        _pickedVideoName = 'Su_co_hien_truong.mp4';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã đính kèm video hiện trường mẫu vào phiếu sự cố!'),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
                    icon: const Icon(Icons.fiber_manual_record_rounded, size: 15, color: Colors.red),
                    label: const Text('Quay nhanh (4s)', style: TextStyle(fontSize: 12.5)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => showSmartStayCallModal(
                      context,
                      initialTargetRole: 'QuanLy',
                      initialTargetName: 'Ban Quản Lý (Báo sự cố trực tiếp)',
                      initialVideo: true,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 46),
                    ),
                    icon: const Icon(Icons.video_call_rounded, size: 18),
                    label: const Text('Gọi Video báo Quản Lý', style: TextStyle(fontSize: 12.5)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

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
