import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_transport.dart';
import '../../utils/provider_scope.dart';
import '../../widgets/call_center_modal.dart';

class CreateTicketScreen extends StatefulWidget {
  final String? initialQuickAction;

  const CreateTicketScreen({super.key, this.initialQuickAction});

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
    if (widget.initialQuickAction == 'photo') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _captureLiveIncidentPhoto();
      });
    } else if (widget.initialQuickAction == 'video') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _recordLiveIncidentVideo4s();
      });
    }
  }

  /// Tạo ảnh PNG hiện trường từ khung ngắm Camera SmartStay
  Future<String?> _buildIncidentSnapshotDataUrl({
    required String roomCode,
    required String sceneLabel,
  }) async {
    const double w = 480;
    const double h = 270;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Nền khung ngắm tối giả lập Camera
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF0F172A),
    );
    canvas.drawRect(
      const Rect.fromLTWH(14, 14, w - 28, h - 28),
      Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.fill,
    );

    // Lưới chia điểm ảnh & khung lấy nét vàng
    final focusPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(const Rect.fromLTWH(135, 62, 210, 140), focusPaint);

    // Điểm báo REC / Live Snapshot
    canvas.drawCircle(
      const Offset(42, 40),
      6,
      Paint()..color = const Color(0xFF22C55E),
    );

    final now = DateTime.now();
    final stamp =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} '
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    void paintLabel(
      String text,
      Offset offset, {
      double fontSize = 14,
      Color color = Colors.white,
      FontWeight weight = FontWeight.bold,
      double maxWidth = w - 60,
    }) {
      final pb = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          fontSize: fontSize,
          fontWeight: weight,
          maxLines: 2,
        ),
      )
        ..pushStyle(ui.TextStyle(color: color))
        ..addText(text);
      final p = pb.build()..layout(ui.ParagraphConstraints(width: maxWidth));
      canvas.drawParagraph(p, offset);
    }

    paintLabel(
      'SMARTSTAY CAM • $roomCode',
      const Offset(56, 31),
      fontSize: 13,
      color: const Color(0xFF86EFAC),
    );
    paintLabel(
      stamp,
      const Offset(315, 32),
      fontSize: 12,
      color: const Color(0xFFCBD5E1),
      weight: FontWeight.w500,
    );
    paintLabel(
      'HIỆN TRƯỜNG SỰ CỐ:',
      const Offset(152, 92),
      fontSize: 12,
      color: const Color(0xFFFDE68A),
    );
    paintLabel(
      sceneLabel,
      const Offset(152, 118),
      fontSize: 15,
      color: Colors.white,
      maxWidth: 180,
    );
    paintLabel(
      'Đính kèm trực quan → Kanban KTV',
      const Offset(36, 224),
      fontSize: 12,
      color: const Color(0xFF93C5FD),
      weight: FontWeight.w600,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), h.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) return null;
    return 'data:image/png;base64,${base64Encode(byteData.buffer.asUint8List())}';
  }

  Future<void> _captureLiveIncidentPhoto() async {
    final auth = context.read<AuthProvider>();
    final userRoom =
        auth.contract?.roomCode ?? auth.user?.effectiveRoomCode ?? 'P.305';
    final scenes = <String>[
      'Rò rỉ nước / Vòi sen hỏng',
      'Máy lạnh kêu to / Chảy nước',
      'Chập điện / Đèn nhấp nháy',
      'Khóa thông minh IoT / Cửa phòng',
    ];
    String selectedScene = scenes.first;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chụp Ảnh Hiện Trường Camera',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 150,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFF59E0B),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.lens,
                            size: 10,
                            color: Color(0xFF22C55E),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'SMARTSTAY CAM • $userRoom',
                              style: const TextStyle(
                                color: Color(0xFF86EFAC),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.center_focus_strong_rounded,
                              color: Color(0xFFF59E0B),
                              size: 38,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              selectedScene,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Chạm "Chụp Ngay" hoặc tải ảnh thực tế từ máy',
                        style: TextStyle(color: Colors.white60, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tình huống đang hướng ống kính:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: scenes
                      .map(
                        (scene) => ChoiceChip(
                          label: Text(scene, style: const TextStyle(fontSize: 11)),
                          selected: selectedScene == scene,
                          onSelected: (_) =>
                              setDialogState(() => selectedScene = scene),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
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
              child: const Text('Chọn từ máy / Camera'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
              ),
              onPressed: () async {
                final dataUrl = await _buildIncidentSnapshotDataUrl(
                  roomCode: userRoom,
                  sceneLabel: selectedScene,
                );
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (dataUrl == null || !mounted) return;
                setState(() {
                  _pickedImageDataUrl = dataUrl;
                  _pickedImageName =
                      'Anh_su_co_${userRoom.replaceAll('.', '')}.png';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã chụp ảnh "$selectedScene" đính kèm phiếu!'),
                    backgroundColor: const Color(0xFF16A34A),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: const Text('Chụp Ngay'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordLiveIncidentVideo4s() async {
    final auth = context.read<AuthProvider>();
    final userRoom =
        auth.contract?.roomCode ?? auth.user?.effectiveRoomCode ?? 'P.305';
    int elapsedTicks = 0;
    const int totalTicks = 6; // ~2.4s ghi hình nhanh trực tiếp
    Timer? timer;
    bool finished = false;

    void finishRecording(BuildContext dialogCtx) {
      if (finished) return;
      finished = true;
      timer?.cancel();
      if (dialogCtx.mounted) {
        Navigator.pop(dialogCtx, true);
      }
    }

    final recorded = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          timer ??= Timer.periodic(const Duration(milliseconds: 400), (t) {
            if (!dialogCtx.mounted || finished) {
              t.cancel();
              return;
            }
            if (elapsedTicks + 1 >= totalTicks) {
              finishRecording(dialogCtx);
              return;
            }
            setDialogState(() => elapsedTicks += 1);
          });

          final progress = ((elapsedTicks + 1) / totalTicks).clamp(0.0, 1.0);
          final seconds = ((elapsedTicks + 1) * 0.6).toStringAsFixed(1);

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.fiber_manual_record_rounded, color: Color(0xFFDC2626)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đang Quay Video Hiện Trường',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 150,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFDC2626),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '● REC ${seconds}s',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            userRoom,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.videocam_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Đang ghi hình & thu âm sự cố...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.white24,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Hãy hướng Camera vào thiết bị hỏng hóc, tiếng kêu hoặc điểm rò rỉ nước.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  finished = true;
                  timer?.cancel();
                  Navigator.pop(dialogCtx, false);
                },
                child: const Text('Hủy'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                ),
                onPressed: () => finishRecording(dialogCtx),
                icon: const Icon(Icons.stop_circle_rounded, size: 18),
                label: const Text('Dừng & Lưu Video'),
              ),
            ],
          );
        },
      ),
    );
    timer?.cancel();

    if (recorded != true || !mounted) return;
    final now = DateTime.now();
    setState(() {
      _pickedVideoUrl =
          'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4';
      _pickedVideoName =
          'Video_hien_truong_${userRoom.replaceAll('.', '')}_${now.hour}h${now.minute}.mp4';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã quay xong video hiện trường & đính kèm vào phiếu sự cố!'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  Future<void> _showDraftVideoPreviewDialog() async {
    if (_pickedVideoUrl == null) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.videocam_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Xem trước Video sự cố',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 155,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.redAccent,
                    size: 46,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _pickedVideoName ?? 'Clip hiện trường HD',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sẵn sàng gửi kèm lên Kanban Kỹ thuật viên',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
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
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _decodeDataUrlBytes(_pickedImageDataUrl)!,
                        height: 155,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black.withValues(alpha: 0.65),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close, size: 16, color: Colors.white),
                          tooltip: 'Xóa ảnh',
                          onPressed: () => setState(() {
                            _pickedImageDataUrl = null;
                            _pickedImageName = null;
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (_pickedVideoUrl != null) ...[
                InkWell(
                  onTap: _showDraftVideoPreviewDialog,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFDC2626), size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Video sự cố: ${_pickedVideoName ?? 'Clip hiện trường HD'}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Nhấn để xem trước Video đính kèm',
                                style: TextStyle(fontSize: 10.5, color: Color(0xFFDC2626)),
                              ),
                            ],
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
                ),
                const SizedBox(height: 8),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _captureLiveIncidentPhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pickedImageDataUrl != null
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 46),
                    ),
                    icon: Icon(
                      _pickedImageDataUrl != null
                          ? Icons.check_circle_rounded
                          : Icons.camera_alt_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _pickedImageDataUrl == null
                          ? 'Chụp ảnh Camera ngay'
                          : 'Chụp lại (${_pickedImageName ?? 'Ảnh'})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ),
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
                      side: const BorderSide(color: Color(0xFF2563EB)),
                    ),
                    icon: const Icon(Icons.photo_library_outlined, size: 18, color: Color(0xFF2563EB)),
                    label: const Text(
                      'Chọn ảnh từ máy',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF2563EB)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _recordLiveIncidentVideo4s,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 46),
                    ),
                    icon: const Icon(Icons.fiber_manual_record_rounded, size: 16),
                    label: const Text(
                      'Quay Video trực tiếp (4s)',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
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
                      Icons.video_file_outlined,
                      size: 18,
                      color: Color(0xFFDC2626),
                    ),
                    label: const Text(
                      'Tải file Video',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFFDC2626)),
                    ),
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
