import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../models/admin_models.dart';
import '../../../models/room_discovery_models.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/room_discovery_provider.dart';
import '../../../services/api_transport.dart';
import '../../../theme/smartstay_theme.dart';
import '../../../utils/provider_scope.dart';
import '../../../widgets/smartstay_ui.dart';
import '../../../widgets/smartstay_video_player_dialog.dart';

/// Hộp thoại cho Admin/Quản lý chỉnh sửa giá, mô tả, tiện nghi, bật/tắt mở cho thuê
/// và Upload nhiều ảnh + Video Tour thực tế lên Supabase Storage (đồng bộ Real-time).
Future<void> showAdminRoomMediaEditorDialog(
  BuildContext context, {
  required RoomItemModel room,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _AdminRoomMediaEditorDialog(room: room),
  );
}

class _AdminRoomMediaEditorDialog extends StatefulWidget {
  final RoomItemModel room;

  const _AdminRoomMediaEditorDialog({required this.room});

  @override
  State<_AdminRoomMediaEditorDialog> createState() =>
      _AdminRoomMediaEditorDialogState();
}

class _AdminRoomMediaEditorDialogState
    extends State<_AdminRoomMediaEditorDialog> {
  static const List<String> _presetAmenities = [
    'Khóa vân tay IoT',
    'Máy lạnh Inverter',
    'Ban công riêng',
    'Wi-Fi 6 tốc độ cao',
    'Kệ bếp & Tủ lạnh',
    'Bàn học rộng',
    'Giặt sấy miễn phí',
    'View thành phố',
    'Hầm giữ xe 24/7',
    'Smart TV 4K',
  ];

  late final TextEditingController _titleCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _areaCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _customAmenityCtrl;

  late String _status;
  late bool _isOpenForRent;
  late List<String> _selectedAmenities;
  late List<String> _imageUrls;
  String? _videoTourUrl;

  bool _uploadingPhoto = false;
  bool _uploadingVideo = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final discovery = context.read<RoomDiscoveryProvider>();
    final existing = discovery.findByRoomCode(widget.room.roomCode);

    _titleCtrl = TextEditingController(
      text: existing?.title ??
          'Căn hộ ${widget.room.roomCode} • ${widget.room.roomType}',
    );
    _priceCtrl = TextEditingController(
      text: (existing?.rentPrice ?? widget.room.rentPrice).round().toString(),
    );
    _areaCtrl = TextEditingController(
      text: (existing?.area ?? widget.room.area).toStringAsFixed(1),
    );
    _descCtrl = TextEditingController(
      text: existing?.description ??
          'Không gian hiện đại chuẩn SmartStay, ánh sáng tự nhiên, an ninh khóa vân tay IoT 24/7.',
    );
    _customAmenityCtrl = TextEditingController();

    _status = existing?.status ?? widget.room.status;
    _isOpenForRent = existing?.isOpenForRent ?? (widget.room.status == 'Trống');
    _selectedAmenities = List<String>.from(
      existing?.amenities ??
          const ['Khóa vân tay IoT', 'Máy lạnh Inverter', 'Wi-Fi 6 tốc độ cao'],
    );
    _imageUrls = List<String>.from(
      existing?.imageUrls ??
          const [
            'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=900&q=80',
          ],
    );
    _videoTourUrl = existing?.videoTourUrl;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _areaCtrl.dispose();
    _descCtrl.dispose();
    _customAmenityCtrl.dispose();
    super.dispose();
  }

  Uint8List? _extractBytesFromPicked(PickedImageFile picked) {
    if (picked.bytes != null && picked.bytes!.isNotEmpty) return picked.bytes;
    final raw = picked.dataUrl;
    if (raw.startsWith('data:') && raw.contains(';base64,')) {
      try {
        return base64Decode(raw.split(';base64,').last);
      } catch (_) {}
    }
    return null;
  }

  Future<void> _pickAndUploadPhoto({required bool useCamera}) async {
    final picked = await pickMediaFile(
      acceptVideo: false,
      useCamera: useCamera,
    );
    if (picked == null || !mounted) return;
    setState(() => _uploadingPhoto = true);

    try {
      final bytes = _extractBytesFromPicked(picked);
      String? url;
      if (bytes != null) {
        url = await context.read<RoomDiscoveryProvider>().uploadRoomMedia(
              bytes: bytes,
              fileName: picked.fileName,
              contentType: picked.mimeType,
              isVideo: false,
            );
      }
      if (!mounted) return;
      final finalUrl = (url != null && url.isNotEmpty) ? url : picked.dataUrl;
      setState(() {
        if (!_imageUrls.contains(finalUrl)) {
          _imageUrls.insert(0, finalUrl);
        }
      });
      showSmartStayToast(
        context,
        url != null
            ? 'Đã tải ảnh "${picked.fileName}" lên Supabase Storage!'
            : 'Đã gắn ảnh "${picked.fileName}" vào phòng.',
        isSuccess: true,
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _pickAndUploadVideo({required bool useCamera}) async {
    final picked = await pickMediaFile(
      acceptVideo: true,
      useCamera: useCamera,
    );
    if (picked == null || !mounted) return;
    setState(() => _uploadingVideo = true);

    try {
      final bytes = _extractBytesFromPicked(picked);
      String? url;
      if (bytes != null) {
        url = await context.read<RoomDiscoveryProvider>().uploadRoomMedia(
              bytes: bytes,
              fileName: picked.fileName,
              contentType: picked.mimeType,
              isVideo: true,
            );
      }
      if (!mounted) return;
      if (url != null && url.isNotEmpty) {
        setState(() => _videoTourUrl = url);
        showSmartStayToast(
          context,
          'Đã tải Video Tour "${picked.fileName}" lên Supabase Storage thành công!',
          isSuccess: true,
        );
      } else {
        setState(() => _videoTourUrl = picked.dataUrl);
        showSmartStayToast(
          context,
          'Không kết nối được Cloud Storage, đã gắn tạm video cục bộ.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingVideo = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final discovery = context.read<RoomDiscoveryProvider>();
    final admin = context.read<AdminProvider>();

    final parsedPrice =
        double.tryParse(_priceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
            widget.room.rentPrice;
    final parsedArea =
        double.tryParse(_areaCtrl.text.replaceAll(',', '.')) ?? widget.room.area;

    final RoomDiscoveryListing? saved = await discovery.saveRoomListing(
      roomId: widget.room.roomId,
      roomCode: widget.room.roomCode,
      title: _titleCtrl.text,
      roomType: widget.room.roomType,
      floor: widget.room.floor,
      area: parsedArea,
      capacity: widget.room.capacity,
      rentPrice: parsedPrice,
      status: _status,
      description: _descCtrl.text,
      amenities: _selectedAmenities,
      isOpenForRent: _isOpenForRent,
      imageUrls: _imageUrls,
      videoTourUrl: _videoTourUrl,
    );

    admin.updateRoomDetails(
      roomCode: widget.room.roomCode,
      rentPrice: parsedPrice,
      area: parsedArea,
      status: _status,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    showSmartStayToast(
      context,
      saved != null
          ? 'Đã cập nhật & đồng bộ Real-time phòng ${widget.room.roomCode} lên toàn hệ thống!'
          : 'Đã lưu cập nhật phòng ${widget.room.roomCode}.',
      isSuccess: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? SmartStayColors.surfaceDark : SmartStayColors.surfaceLight;
    final borderColor =
        isDark ? SmartStayColors.borderDark : SmartStayColors.borderLight;
    final textPrimary =
        isDark ? SmartStayColors.textPrimaryDark : SmartStayColors.textPrimaryLight;
    final textSecondary =
        isDark ? SmartStayColors.textSecondaryDark : SmartStayColors.textSecondaryLight;
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: surfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: size.width > 680 ? 640 : size.width - 24,
          maxHeight: size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF4F46E5)],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.photo_camera_front_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quản lý Thông tin, Ảnh & Video Tour • ${widget.room.roomCode}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const Text(
                          'Lưu vĩnh viễn trên Supabase & đồng bộ Real-time tới Cư dân',
                          style: TextStyle(color: Colors.white70, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: _saving ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Switch Mở cho thuê
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : SmartStayColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: SmartStayColors.primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Đang mở cho thuê (Hiển thị trên trang Khám phá)',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Tự động đồng bộ trạng thái & phát Toast tới người tìm phòng',
                          style: TextStyle(fontSize: 11.5, color: textSecondary),
                        ),
                        activeThumbColor: SmartStayColors.primary,
                        value: _isOpenForRent,
                        onChanged: (v) => setState(() => _isOpenForRent = v),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề hiển thị cho thuê *',
                        prefixIcon: Icon(Icons.title_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Giá thuê (VNĐ/tháng)',
                              prefixIcon: Icon(Icons.payments_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _areaCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Diện tích (m²)',
                              prefixIcon: Icon(Icons.square_foot_rounded),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái phòng',
                        prefixIcon: Icon(Icons.door_front_door_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Trống', child: Text('Trống (Sẵn sàng đón khách)')),
                        DropdownMenuItem(value: 'Đã đặt', child: Text('Đã đặt (Đang giữ chỗ)')),
                        DropdownMenuItem(value: 'Đang ở', child: Text('Đang ở')),
                        DropdownMenuItem(value: 'Bảo trì', child: Text('Bảo trì')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _status = v;
                            if (v == 'Trống') _isOpenForRent = true;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả chi tiết căn hộ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tiện nghi nổi bật
                    Text(
                      'Tiện nghi nổi bật',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _presetAmenities.map((item) {
                        final selected = _selectedAmenities.contains(item);
                        return FilterChip(
                          label: Text(item, style: const TextStyle(fontSize: 11.5)),
                          selected: selected,
                          selectedColor:
                              SmartStayColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: SmartStayColors.primary,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedAmenities.add(item);
                              } else {
                                _selectedAmenities.remove(item);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customAmenityCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Thêm tiện ích khác (VD: Bồn tắm, Lò vi sóng)...',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            final txt = _customAmenityCtrl.text.trim();
                            if (txt.isEmpty) return;
                            setState(() {
                              if (!_selectedAmenities.contains(txt)) {
                                _selectedAmenities.add(txt);
                              }
                              _customAmenityCtrl.clear();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                          ),
                          child: const Text('Thêm'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Ảnh thực tế của phòng
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Thư viện Ảnh phòng (${_imageUrls.length} ảnh)',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        if (_uploadingPhoto)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_imageUrls.isNotEmpty)
                      SizedBox(
                        height: 92,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imageUrls.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (_, idx) {
                            final url = _imageUrls[idx];
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    url,
                                    width: 120,
                                    height: 90,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 120,
                                      height: 90,
                                      color: borderColor,
                                      child: const Icon(Icons.image_outlined),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() => _imageUrls.removeAt(idx));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.65),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _uploadingPhoto
                              ? null
                              : () => _pickAndUploadPhoto(useCamera: false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                          ),
                          icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                          label: const Text('Tải ảnh từ máy (Supabase)'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _uploadingPhoto
                              ? null
                              : () => _pickAndUploadPhoto(useCamera: true),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                          ),
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('Chụp ảnh trực tiếp'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Video Tour thực tế
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Video Tour thực tế phòng ${widget.room.roomCode}',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        if (_uploadingVideo)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_videoTourUrl != null && _videoTourUrl!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: SmartStayColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: SmartStayColors.success.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.video_file_rounded,
                              color: SmartStayColors.success,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Đã đồng bộ Video Tour HD',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Text(
                                    _videoTourUrl!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => showSmartStayVideoPlayerDialog(
                                context,
                                title: widget.room.roomCode,
                                videoUrl: _videoTourUrl!,
                                headerPrefix: 'Video Tour phòng',
                              ),
                              icon: const Icon(Icons.play_arrow_rounded, size: 18),
                              label: const Text('Xem'),
                            ),
                            IconButton(
                              tooltip: 'Xóa Video Tour',
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: SmartStayColors.danger,
                                size: 18,
                              ),
                              onPressed: () => setState(() => _videoTourUrl = null),
                            ),
                          ],
                        ),
                      ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _uploadingVideo
                              ? null
                              : () => _pickAndUploadVideo(useCamera: true),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            foregroundColor: SmartStayColors.primary,
                            side: const BorderSide(color: SmartStayColors.primary),
                          ),
                          icon: const Icon(Icons.videocam_rounded, size: 18),
                          label: const Text('Quay Video Tour Camera'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _uploadingVideo
                              ? null
                              : () => _pickAndUploadVideo(useCamera: false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                          ),
                          icon: const Icon(Icons.video_library_rounded, size: 18),
                          label: const Text('Tải Video Tour lên Supabase'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: (_saving || _uploadingPhoto || _uploadingVideo)
                        ? null
                        : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SmartStayColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_done_rounded, size: 18),
                    label: Text(
                      _saving ? 'Đang lưu...' : 'Lưu & Đồng Bộ Real-time',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
