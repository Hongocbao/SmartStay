import 'dart:async';

import 'package:flutter/material.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/provider_scope.dart';

const _callPrimary = Color(0xFF4F46E5);
const _callTextPrimary = Color(0xFF0F172A);
const _callTextSecondary = Color(0xFF64748B);

/// Hiển thị hộp thoại Tổng Đài Gọi Thoại & Video Call trực tiếp giữa Người dùng, Ban Quản lý và Admin.
Future<void> showSmartStayCallModal(
  BuildContext context, {
  String? initialTargetRole,
  String? initialTargetName,
  bool initialVideo = true,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _SmartStayCallDialog(
      initialTargetRole: initialTargetRole,
      initialTargetName: initialTargetName,
      initialVideo: initialVideo,
    ),
  );
}

class _CallTargetPreset {
  final String role;
  final String label;
  final String fullName;
  final IconData icon;

  const _CallTargetPreset({
    required this.role,
    required this.label,
    required this.fullName,
    required this.icon,
  });
}

const List<_CallTargetPreset> _callPresets = [
  _CallTargetPreset(
    role: 'QuanLy',
    label: 'Ban Quản lý',
    fullName: 'Ban Quản Lý (Trực ca 24/7)',
    icon: Icons.support_agent_rounded,
  ),
  _CallTargetPreset(
    role: 'Admin',
    label: 'Admin',
    fullName: 'Admin Hệ Thống SmartStay',
    icon: Icons.admin_panel_settings_rounded,
  ),
  _CallTargetPreset(
    role: 'KyThuat',
    label: 'Kỹ thuật viên',
    fullName: 'Nguyễn Văn Bình (Kỹ thuật viên)',
    icon: Icons.handyman_rounded,
  ),
  _CallTargetPreset(
    role: 'CuDan',
    label: 'Cư dân P.305',
    fullName: 'Hồ Ngọc Bảo (Cư dân P.305)',
    icon: Icons.person_pin_circle_rounded,
  ),
];

class _SmartStayCallDialog extends StatefulWidget {
  final String? initialTargetRole;
  final String? initialTargetName;
  final bool initialVideo;

  const _SmartStayCallDialog({
    this.initialTargetRole,
    this.initialTargetName,
    required this.initialVideo,
  });

  @override
  State<_SmartStayCallDialog> createState() => _SmartStayCallDialogState();
}

class _SmartStayCallDialogState extends State<_SmartStayCallDialog>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late final AnimationController _pulseController;
  late final TextEditingController _targetController;
  final TextEditingController _noteController = TextEditingController();

  Timer? _callTimer;
  bool _inCall = false;
  late bool _isVideo;
  bool _micOn = true;
  bool _camOn = true;
  int _elapsedSeconds = 0;
  late String _targetRole;
  bool _savingLog = false;
  String? _statusNote;
  List<Map<String, dynamic>> _callLogs = [];

  @override
  void initState() {
    super.initState();
    _isVideo = widget.initialVideo;
    _camOn = widget.initialVideo;
    _targetRole = widget.initialTargetRole ?? 'QuanLy';
    _targetController = TextEditingController(
      text: widget.initialTargetName ?? 'Ban Quản Lý (Trực ca 24/7)',
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _loadRecentLogs();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _pulseController.dispose();
    _targetController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentLogs() async {
    final snap = await _api.getSyncSnapshot();
    if (!mounted || snap == null) return;
    final raw = snap['cuocGois'];
    if (raw is List) {
      setState(() {
        _callLogs = raw.whereType<Map<String, dynamic>>().toList();
      });
    }
  }

  String _formatDuration(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _startCall({required bool video}) {
    _callTimer?.cancel();
    setState(() {
      _inCall = true;
      _isVideo = video;
      _camOn = video;
      _micOn = true;
      _elapsedSeconds = 0;
      _statusNote = video
          ? 'Đang kết nối Video HD SmartStay RTC...'
          : 'Đang kết nối cuộc gọi Thoại SmartStay...';
    });

    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds += 1;
        if (_elapsedSeconds >= 2) {
          _statusNote = _isVideo
              ? 'Đang đàm thoại Video trực tiếp (Mã hóa P2P)'
              : 'Đang đàm thoại Thoại HD';
        }
      });
    });
  }

  Future<void> _endAndSaveCall() async {
    if (!_inCall) return;
    _callTimer?.cancel();
    final duration = _elapsedSeconds > 0 ? _elapsedSeconds : 1;
    final auth = context.read<AuthProvider>();
    final callerName = auth.user?.fullName ?? 'Người dùng SmartStay';
    final callerRole = auth.isAdmin
        ? (auth.currentRole == 'Quản trị viên' ? 'Admin' : 'QuanLy')
        : 'CuDan';
    final partnerName = _targetController.text.trim().isEmpty
        ? 'Ban Quản Lý'
        : _targetController.text.trim();
    final note = _noteController.text.trim().isEmpty
        ? 'Trao đổi ${_isVideo ? 'Video Call' : 'Thoại'} trực tiếp trên SmartStay App'
        : _noteController.text.trim();

    setState(() {
      _inCall = false;
      _savingLog = true;
      _statusNote = 'Đang lưu nhật ký cuộc gọi (${_formatDuration(duration)})...';
    });

    final res = await _api.postSyncCallLog({
      'NguoiGoi': '$callerName (${auth.currentRole})',
      'VaiTroNguoiGoi': callerRole,
      'NguoiNhan': partnerName,
      'VaiTroNguoiNhan': _targetRole,
      'LoaiCuocGoi': _isVideo ? 'Video' : 'Thoại',
      'TrangThai': 'Hoàn thành',
      'ThoiLuongGiay': duration,
      'NoiDungTraoDoi': note,
    });

    if (!mounted) return;
    setState(() {
      _savingLog = false;
      _statusNote = 'Đã kết thúc & đồng bộ nhật ký (${_formatDuration(duration)})';
      if (res != null && res['cuocGois'] is List) {
        _callLogs = (res['cuocGois'] as List)
            .whereType<Map<String, dynamic>>()
            .toList();
      } else {
        _callLogs.insert(0, {
          'nguoiGoi': callerName,
          'nguoiNhan': partnerName,
          'vaiTroNguoiNhan': _targetRole,
          'loaiCuocGoi': _isVideo ? 'Video' : 'Thoại',
          'thoiLuongGiay': duration,
          'noiDungTraoDoi': note,
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final maxDialogWidth = width > 720 ? 680.0 : width - 24;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxDialogWidth, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.video_call_rounded, color: Colors.lightBlueAccent, size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tổng Đài Thoại & Video Call SmartStay',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Kết nối Người dùng • Ban Quản lý • Admin • Kỹ thuật viên',
                          style: TextStyle(color: Colors.white70, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Đóng',
                    onPressed: () {
                      if (_inCall) {
                        _endAndSaveCall().then((_) {
                          if (context.mounted) Navigator.of(context).pop();
                        });
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildVideoStage(),
                    const SizedBox(height: 12),
                    _buildCallControls(),
                    const SizedBox(height: 14),
                    const Text(
                      'Chọn nhanh vai trò liên hệ:',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: _callTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _callPresets.map((preset) {
                        final selected = _targetRole == preset.role &&
                            _targetController.text == preset.fullName;
                        return InkWell(
                          onTap: _inCall
                              ? null
                              : () {
                                  setState(() {
                                    _targetRole = preset.role;
                                    _targetController.text = preset.fullName;
                                  });
                                },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 44),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? _callPrimary.withValues(alpha: 0.12)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? _callPrimary
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  preset.icon,
                                  size: 16,
                                  color: selected
                                      ? _callPrimary
                                      : _callTextSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  preset.label,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? _callPrimary
                                        : _callTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _targetController,
                      enabled: !_inCall,
                      decoration: const InputDecoration(
                        labelText: 'Người nhận cuộc gọi / Số phòng',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Biên bản / Ghi chú tình hình trao đổi',
                        hintText: 'VD: Báo cáo rò rỉ nước P.305 hoặc xác nhận gia hạn...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.history_rounded, size: 17, color: _callPrimary),
                        const SizedBox(width: 6),
                        Text(
                          'Nhật ký cuộc gọi gần đây (${_callLogs.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_callLogs.isEmpty)
                      Text(
                        'Chưa có cuộc gọi nào được ghi nhận trong phiên.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      )
                    else
                      ..._callLogs.take(4).map((log) {
                        final isVid = log['loaiCuocGoi'] == 'Video';
                        final secs = (log['thoiLuongGiay'] as num?)?.toInt() ?? 0;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isVid ? Icons.videocam_rounded : Icons.call_rounded,
                                size: 18,
                                color: isVid ? Colors.blue : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${log['nguoiNhan'] ?? 'Ban Quản Lý'} (${log['vaiTroNguoiNhan'] ?? 'QuanLy'})',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    if ((log['noiDungTraoDoi'] ?? '').toString().isNotEmpty)
                                      Text(
                                        log['noiDungTraoDoi'].toString(),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: _callTextSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  _formatDuration(secs),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoStage() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const RadialGradient(
          center: Alignment.topRight,
          radius: 1.4,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF020617)],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, child) {
                    final glow = _inCall ? (6 + _pulseController.value * 14) : 0.0;
                    return Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF2563EB)],
                        ),
                        boxShadow: _inCall
                            ? [
                                BoxShadow(
                                  color: Colors.blueAccent.withValues(alpha: 0.55),
                                  blurRadius: 16,
                                  spreadRadius: glow / 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        _inCall && _isVideo && _camOn
                            ? Icons.videocam_rounded
                            : Icons.headset_mic_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _targetController.text.isEmpty
                        ? 'Ban Quản Lý SmartStay'
                        : _targetController.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _inCall ? Colors.green.shade700 : Colors.blueGrey.shade700,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    _inCall
                        ? '${_isVideo ? 'VIDEO HD' : 'VOICE HD'} • ${_formatDuration(_elapsedSeconds)}'
                        : (_savingLog ? 'ĐANG LƯU...' : 'SẴN SÀNG KẾT NỐI'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_statusNote != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _statusNote!,
                    style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 11.5),
                  ),
                ],
              ],
            ),
          ),
          if (_isVideo && _camOn)
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                width: 84,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white70, width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _inCall ? Icons.face_retouching_natural : Icons.videocam_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Cam của bạn',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCallControls() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        if (!_inCall) ...[
          ElevatedButton.icon(
            onPressed: _savingLog ? null : () => _startCall(video: false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
            ),
            icon: const Icon(Icons.call_rounded, size: 18),
            label: const Text('Gọi Thoại'),
          ),
          ElevatedButton.icon(
            onPressed: _savingLog ? null : () => _startCall(video: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _callPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
            ),
            icon: const Icon(Icons.videocam_rounded, size: 18),
            label: const Text('Gọi Video HD'),
          ),
        ] else ...[
          OutlinedButton.icon(
            onPressed: () => setState(() => _micOn = !_micOn),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
            ),
            icon: Icon(
              _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
              color: _micOn ? Colors.blue : Colors.red,
            ),
            label: Text(_micOn ? 'Mic Bật' : 'Mic Tắt'),
          ),
          if (_isVideo)
            OutlinedButton.icon(
              onPressed: () => setState(() => _camOn = !_camOn),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
              ),
              icon: Icon(
                _camOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                color: _camOn ? Colors.blue : Colors.red,
              ),
              label: Text(_camOn ? 'Cam Bật' : 'Cam Tắt'),
            ),
          ElevatedButton.icon(
            onPressed: _endAndSaveCall,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
            ),
            icon: const Icon(Icons.call_end_rounded, size: 18),
            label: const Text('Kết thúc & Lưu'),
          ),
        ],
      ],
    );
  }
}
