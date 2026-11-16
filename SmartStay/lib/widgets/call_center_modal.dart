import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/api_transport.dart';
import '../services/webrtc_call_service.dart';
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
  Map<String, dynamic>? incomingSignal,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _SmartStayCallDialog(
      initialTargetRole: initialTargetRole,
      initialTargetName: initialTargetName,
      initialVideo: initialVideo,
      incomingSignal: incomingSignal,
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
  final Map<String, dynamic>? incomingSignal;

  const _SmartStayCallDialog({
    this.initialTargetRole,
    this.initialTargetName,
    required this.initialVideo,
    this.incomingSignal,
  });

  @override
  State<_SmartStayCallDialog> createState() => _SmartStayCallDialogState();
}

class _SmartStayCallDialogState extends State<_SmartStayCallDialog>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  final WebRtcCallService _rtc = WebRtcCallService();
  late final AnimationController _pulseController;
  late final TextEditingController _targetController;
  final TextEditingController _noteController = TextEditingController();

  StreamSubscription<Map<String, dynamic>>? _signalSub;
  Timer? _callTimer;
  bool _inCall = false;
  bool _ringingOutgoing = false;
  bool _connected = false;
  late bool _isVideo;
  bool _micOn = true;
  bool _camOn = true;
  bool _speakerOn = true;
  int _elapsedSeconds = 0;
  String _activeCallId = '';
  String _targetClientId = '';
  late String _targetRole;
  bool _savingLog = false;
  bool _hasSavedCurrentCall = false;
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

    _rtc.addListener(_onRtcChanged);
    unawaited(_rtc.ensureRenderersInitialized());

    _signalSub = _api.callSignalStream.listen(_handleRemoteCallSignal);
    _loadRecentLogs();

    if (widget.incomingSignal != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _acceptIncomingSignal(widget.incomingSignal!);
      });
    }
  }

  void _onRtcChanged() {
    if (!mounted) return;
    setState(() {
      _speakerOn = _rtc.speakerphoneOn;
    });
  }

  @override
  void dispose() {
    _rtc.removeListener(_onRtcChanged);
    _signalSub?.cancel();
    _callTimer?.cancel();
    _api.setActiveCallSessionId('');
    if (_inCall || _ringingOutgoing) {
      rtcHangup();
    }
    _pulseController.dispose();
    _targetController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _myCallerRole(AuthProvider auth) {
    final mode = auth.effectiveAiRoleMode;
    if (mode == 'admin') return 'Admin';
    if (mode == 'manager') {
      final uname = (auth.user?.username ?? '').toLowerCase();
      final roleLower = auth.currentRole.toLowerCase();
      if (uname == 'kythuat' || roleLower.contains('kỹ thuật')) {
        return 'KyThuat';
      }
      return 'QuanLy';
    }
    return 'CuDan';
  }

  Future<void> _acceptIncomingSignal(Map<String, dynamic> pkt) async {
    final auth = context.read<AuthProvider>();
    final myRole = _myCallerRole(auth);
    final myName = auth.user?.fullName ?? myRole;
    final callId = (pkt['callId'] ?? '').toString();
    final peerClientId = (pkt['fromClientId'] ?? '').toString();
    final peerRole = (pkt['fromRole'] ?? 'CuDan').toString();
    final peerName = (pkt['fromName'] ?? 'Người gọi SmartStay').toString();
    final isVid = (pkt['callMode'] ?? 'Video').toString().toLowerCase() != 'thoại';

    _callTimer?.cancel();
    _api.setActiveCallSessionId(callId);
    setState(() {
      _activeCallId = callId;
      _targetClientId = peerClientId;
      _targetRole = peerRole;
      _targetController.text = peerName;
      _inCall = true;
      _ringingOutgoing = false;
      _connected = true;
      _hasSavedCurrentCall = false;
      _isVideo = isVid;
      _camOn = isVid;
      _micOn = true;
      _elapsedSeconds = 0;
      _statusNote = 'Đã nhận máy! Đang thiết lập WebRTC 2 chiều...';
    });

    await rtcPrepareLocalMedia(isVid, '$myName ($myRole)');
    await rtcStartCalleePeer(jsonEncode({
      'callId': callId,
      'apiBase': ApiService.baseUrl,
      'isVideo': isVid,
      'fromClientId': ApiService.callClientId,
      'fromName': myName,
      'fromRole': myRole,
      'peerClientId': peerClientId,
      'peerRole': peerRole,
    }));

    await _api.postCallSignal({
      'callId': callId,
      'signalType': 'call_accepted',
      'fromClientId': ApiService.callClientId,
      'fromName': myName,
      'fromRole': myRole,
      'fromRoom': auth.user?.effectiveRoomCode ?? '',
      'targetClientId': peerClientId,
      'targetRole': peerRole,
      'callMode': isVid ? 'Video' : 'Thoại',
    });

    _startElapsedTimer();
  }

  void _startElapsedTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final iceState = _rtc.iceConnectionStateLabel;
      setState(() {
        _elapsedSeconds += 1;
        _statusNote = _isVideo
            ? 'Đang đàm thoại Video WebRTC 2 chiều (ICE: $iceState)'
            : 'Đang đàm thoại Thoại WebRTC HD (ICE: $iceState)';
      });
    });
  }

  Future<void> _handleRemoteCallSignal(Map<String, dynamic> pkt) async {
    if (!mounted) return;
    final sigType = (pkt['signalType'] ?? '').toString();
    final callId = (pkt['callId'] ?? '').toString();
    if (_activeCallId.isEmpty || callId != _activeCallId) return;

    if (sigType == 'webrtc_offer' ||
        sigType == 'webrtc_answer' ||
        sigType == 'webrtc_ice') {
      await rtcHandleSignal(jsonEncode(pkt));
      return;
    }

    if (sigType == 'call_accepted') {
      final auth = context.read<AuthProvider>();
      final myRole = _myCallerRole(auth);
      final myName = auth.user?.fullName ?? myRole;
      final peerClientId = (pkt['fromClientId'] ?? '').toString();
      final peerRole = (pkt['fromRole'] ?? _targetRole).toString();
      final peerName = (pkt['fromName'] ?? '').toString();

      setState(() {
        _ringingOutgoing = false;
        _inCall = true;
        _connected = true;
        if (peerClientId.isNotEmpty) _targetClientId = peerClientId;
        if (peerName.isNotEmpty) _targetController.text = peerName;
        _statusNote = 'Người nhận đã nghe máy! Đang kết nối WebRTC...';
      });
      _startElapsedTimer();

      await rtcStartCallerPeer(jsonEncode({
        'callId': callId,
        'apiBase': ApiService.baseUrl,
        'isVideo': _isVideo,
        'fromClientId': ApiService.callClientId,
        'fromName': myName,
        'fromRole': myRole,
        'peerClientId': peerClientId,
        'peerRole': peerRole,
      }));
    } else if (sigType == 'call_rejected') {
      _callTimer?.cancel();
      _api.setActiveCallSessionId('');
      rtcHangup();
      setState(() {
        _ringingOutgoing = false;
        _inCall = false;
        _connected = false;
        _statusNote = 'Người nhận đã từ chối cuộc gọi';
      });
      await _persistCallRecord(status: 'Từ chối', duration: 0);
    } else if (sigType == 'call_ended') {
      _callTimer?.cancel();
      _api.setActiveCallSessionId('');
      rtcHangup();
      final wasConnected = _connected;
      final dur = _elapsedSeconds;
      setState(() {
        _ringingOutgoing = false;
        _inCall = false;
        _connected = false;
        _statusNote = 'Đối phương đã kết thúc cuộc gọi (${_formatDuration(dur)})';
      });
      if (wasConnected) {
        Future.delayed(const Duration(milliseconds: 500), _loadRecentLogs);
      }
    }
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

  Future<void> _startCall({required bool video}) async {
    _callTimer?.cancel();
    final auth = context.read<AuthProvider>();
    final myRole = _myCallerRole(auth);
    final myName = auth.user?.fullName ?? 'Người dùng SmartStay';
    final partnerName = _targetController.text.trim().isEmpty
        ? 'Ban Quản Lý'
        : _targetController.text.trim();
    final callId =
        'CALL-${DateTime.now().millisecondsSinceEpoch}-${_elapsedSeconds + 10}';
    _api.setActiveCallSessionId(callId);

    setState(() {
      _activeCallId = callId;
      _inCall = true;
      _ringingOutgoing = true;
      _connected = false;
      _hasSavedCurrentCall = false;
      _isVideo = video;
      _camOn = video;
      _micOn = true;
      _elapsedSeconds = 0;
      _statusNote = 'Đang đổ chuông tới $_targetRole ($partnerName)...';
    });

    final hardwareOk = await rtcPrepareLocalMedia(video, '$myName ($myRole)');
    if (!mounted) return;

    await _api.postCallSignal({
      'callId': callId,
      'signalType': 'initiate_call',
      'fromClientId': ApiService.callClientId,
      'fromName': myName,
      'fromRole': myRole,
      'fromRoom': auth.user?.effectiveRoomCode ?? '',
      'targetClientId': _targetClientId,
      'targetRole': _targetRole,
      'targetName': partnerName,
      'callMode': video ? 'Video' : 'Thoại',
    });

    if (!mounted || !_ringingOutgoing) return;
    setState(() {
      _statusNote = hardwareOk
          ? 'Đang đổ chuông • Mic/Camera đã sẵn sàng, chờ người nhận Chấp nhận...'
          : 'Đang đổ chuông • Chờ thiết bị nhận bấm Chấp nhận (WebRTC Media dự phòng)';
    });
  }

  Future<void> _persistCallRecord({
    required String status,
    required int duration,
  }) async {
    if (_hasSavedCurrentCall) return;
    _hasSavedCurrentCall = true;
    final auth = context.read<AuthProvider>();
    final callerName = auth.user?.fullName ?? 'Người dùng SmartStay';
    final callerRole = _myCallerRole(auth);
    final partnerName = _targetController.text.trim().isEmpty
        ? 'Ban Quản Lý'
        : _targetController.text.trim();
    final note = _noteController.text.trim().isEmpty
        ? 'Cuộc gọi ${_isVideo ? 'Video Call' : 'Thoại'} WebRTC ($status)'
        : _noteController.text.trim();

    setState(() => _savingLog = true);
    final res = await _api.postSyncCallLog({
      'CallId': _activeCallId.isEmpty ? null : _activeCallId,
      'NguoiGoi': '$callerName (${auth.currentRole})',
      'VaiTroNguoiGoi': callerRole,
      'NguoiNhan': partnerName,
      'VaiTroNguoiNhan': _targetRole,
      'LoaiCuocGoi': _isVideo ? 'Video' : 'Thoại',
      'TrangThai': status,
      'ThoiLuongGiay': duration,
      'NoiDungTraoDoi': note,
    });

    if (!mounted) return;
    setState(() {
      _savingLog = false;
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
          'trangThai': status,
          'thoiLuongGiay': duration,
          'noiDungTraoDoi': note,
        });
      }
    });
  }

  Future<void> _endAndSaveCall() async {
    if (!_inCall && !_ringingOutgoing) return;
    _callTimer?.cancel();
    _api.setActiveCallSessionId('');
    final wasConnected = _connected;
    final duration = wasConnected ? (_elapsedSeconds > 0 ? _elapsedSeconds : 1) : 0;
    final auth = context.read<AuthProvider>();
    final callerRole = _myCallerRole(auth);

    rtcHangup();
    setState(() {
      _inCall = false;
      _ringingOutgoing = false;
      _connected = false;
      _statusNote = wasConnected
          ? 'Đã kết thúc & đồng bộ nhật ký (${_formatDuration(duration)})'
          : 'Đã hủy cuộc gọi trước khi nghe máy';
    });

    if (_activeCallId.isNotEmpty) {
      await _api.postCallSignal({
        'callId': _activeCallId,
        'signalType': 'call_ended',
        'fromClientId': ApiService.callClientId,
        'fromName': auth.user?.fullName ?? callerRole,
        'fromRole': callerRole,
        'targetClientId': _targetClientId,
        'targetRole': _targetRole,
        'callMode': _isVideo ? 'Video' : 'Thoại',
        'payload': {'durationSeconds': duration},
      });
    }

    await _persistCallRecord(
      status: wasConnected ? 'Đã kết nối' : 'Hủy cuộc gọi',
      duration: duration,
    );
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
                    if (_api.latestOnlinePeers.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Thiết bị đang trực tuyến (${_api.latestOnlinePeers.length}):',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: Color(0xFF15803D),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _api.latestOnlinePeers.map((peer) {
                          final cid = (peer['clientId'] ?? '').toString();
                          final pRole = (peer['role'] ?? 'CuDan').toString();
                          final pName = (peer['displayName'] ?? pRole).toString();
                          final isSelectedPeer = _targetClientId == cid && cid.isNotEmpty;
                          return InkWell(
                            onTap: _inCall
                                ? null
                                : () {
                                    setState(() {
                                      _targetClientId = cid;
                                      _targetRole = pRole;
                                      _targetController.text = pName;
                                    });
                                  },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelectedPeer
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelectedPeer
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF86EFAC),
                                ),
                              ),
                              child: Text(
                                '● $pName ($pRole)',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
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
                                    _targetClientId = '';
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
    final showRemoteVideo = _inCall &&
        _isVideo &&
        _rtc.isRenderersInitialized &&
        _rtc.remoteRenderer.srcObject != null &&
        _rtc.hasRemoteVideo;
    final showLocalVideo = _inCall &&
        _isVideo &&
        _camOn &&
        _rtc.isRenderersInitialized &&
        _rtc.localRenderer.srcObject != null &&
        _rtc.hasLocalVideo;

    return Container(
      height: 245,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const RadialGradient(
          center: Alignment.topRight,
          radius: 1.4,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF020617)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Remote Video / Audio Renderer (cũng chịu trách nhiệm phát âm thanh từ đối phương)
          if (_inCall &&
              _rtc.isRenderersInitialized &&
              _rtc.remoteRenderer.srcObject != null)
            Positioned.fill(
              child: Opacity(
                opacity: showRemoteVideo ? 1.0 : 0.01,
                child: RTCVideoView(
                  _rtc.remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),

          // 2. Avatar & Trạng thái (hiển thị khi cuộc gọi thoại hoặc chưa có hình camera đối phương)
          if (!showRemoteVideo)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, child) {
                      final glow =
                          _inCall ? (6 + _pulseController.value * 14) : 0.0;
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
                                    color: Colors.blueAccent
                                        .withValues(alpha: 0.55),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _connected
                          ? Colors.green.shade700
                          : (_ringingOutgoing
                              ? Colors.amber.shade800
                              : Colors.blueGrey.shade700),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      _connected
                          ? '${_isVideo ? 'VIDEO WEBRTC' : 'VOICE WEBRTC'} • ${_formatDuration(_elapsedSeconds)}'
                          : (_ringingOutgoing
                              ? 'ĐANG ĐỔ CHUÔNG...'
                              : (_savingLog
                                  ? 'ĐANG LƯU...'
                                  : 'SẴN SÀNG KẾT NỐI')),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_statusNote != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        _statusNote!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.lightBlueAccent,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // 3. Thanh trạng thái nổi trên góc trái khi đang xem Video trực tiếp
          if (showRemoteVideo)
            Positioned(
              left: 12,
              top: 12,
              right: 12,
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.fiber_manual_record,
                          color: Color(0xFF4ADE80),
                          size: 12,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_targetController.text} • ${_formatDuration(_elapsedSeconds)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // 4. Ô Picture-in-Picture (PiP) hiển thị Camera của chính bạn
          if (_isVideo && _camOn)
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                width: 104,
                height: 76,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white70, width: 1.5),
                ),
                child: showLocalVideo
                    ? RTCVideoView(
                        _rtc.localRenderer,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _inCall
                                ? Icons.face_retouching_natural
                                : Icons.videocam_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Cam của bạn',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 10),
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
            onPressed: () {
              setState(() => _micOn = !_micOn);
              rtcSetMic(_micOn);
            },
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
          if (!kIsWeb)
            OutlinedButton.icon(
              onPressed: () async {
                await _rtc.toggleSpeakerphone();
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
              ),
              icon: Icon(
                _speakerOn ? Icons.volume_up_rounded : Icons.phone_in_talk_rounded,
                color: _speakerOn ? Colors.indigo : Colors.orange,
              ),
              label: Text(_speakerOn ? 'Loa ngoài' : 'Loa trong'),
            ),
          if (_isVideo) ...[
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _camOn = !_camOn);
                rtcSetCam(_camOn);
              },
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
            if (!kIsWeb)
              IconButton(
                onPressed: _camOn ? () => _rtc.switchCamera() : null,
                tooltip: 'Đổi camera trước/sau',
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                icon: const Icon(Icons.cameraswitch_rounded, size: 20),
              ),
          ],
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
