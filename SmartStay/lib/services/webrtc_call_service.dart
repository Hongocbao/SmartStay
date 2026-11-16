import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'api_service.dart';

/// Dịch vụ WebRTC đa nền tảng (Flutter Android, iOS, Web, Desktop) cho SmartStay.
/// Hỗ trợ STUN + TURN Relay (UDP/TCP/TLS), hàng đợi ICE Candidate an toàn,
/// kiểm tra quyền Camera/Mic runtime và quản lý RTCVideoRenderer trực tiếp.
class WebRtcCallService extends ChangeNotifier {
  static final WebRtcCallService _instance = WebRtcCallService._internal();
  factory WebRtcCallService() => _instance;
  WebRtcCallService._internal();

  /// Cấu hình ICE Servers đầy đủ gồm Google/Cloudflare STUN và TURN Relay (UDP + TCP + TLS 443)
  /// giúp xuyên NAT/Firewall khi gọi giữa mạng 4G, Wi-Fi khác nhau hoặc qua Render Cloud.
  static const Map<String, dynamic> rtcConfiguration = {
    'sdpSemantics': 'unified-plan',
    'iceCandidatePoolSize': 4,
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
          'stun:stun.cloudflare.com:3478',
        ],
      },
      {
        'urls': [
          'turn:openrelay.metered.ca:80',
          'turn:openrelay.metered.ca:443',
          'turn:openrelay.metered.ca:443?transport=tcp',
        ],
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': [
          'turn:standard.relay.metered.ca:80',
          'turn:standard.relay.metered.ca:80?transport=tcp',
          'turn:standard.relay.metered.ca:443',
          'turns:standard.relay.metered.ca:443?transport=tcp',
        ],
        'username': 'e8dd65b92f64d0936f14a81b',
        'credential': '2/37530315284e5O',
      },
    ],
  };

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  bool _renderersInitialized = false;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final List<RTCIceCandidate> _pendingRemoteCandidates = <RTCIceCandidate>[];
  final Set<int> _handledSignalSeqs = <int>{};
  bool _remoteDescriptionSet = false;
  bool _makingOffer = false;

  Map<String, dynamic>? _activeMeta;
  String iceConnectionStateLabel = 'new';
  String peerConnectionStateLabel = 'new';
  bool hasLocalVideo = false;
  bool hasRemoteVideo = false;
  bool hasRemoteAudio = false;
  bool speakerphoneOn = true;

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  bool get isRenderersInitialized => _renderersInitialized;

  /// Khởi tạo `localRenderer` và `remoteRenderer` trước khi gán `srcObject`.
  Future<void> ensureRenderersInitialized() async {
    if (_renderersInitialized) return;
    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
      _renderersInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[SmartStay WebRTC] Renderer initialize error: $e');
    }
  }

  /// Xin quyền Microphone và Camera runtime trên Android / iOS.
  Future<bool> requestMediaPermissions({required bool isVideo}) async {
    if (kIsWeb) return true;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return true;
    }

    try {
      final permissions = <Permission>[
        Permission.microphone,
        if (isVideo) Permission.camera,
      ];
      final statuses = await permissions.request();
      final micGranted = statuses[Permission.microphone]?.isGranted ?? false;
      final camGranted =
          !isVideo || (statuses[Permission.camera]?.isGranted ?? false);
      return micGranted && camGranted;
    } catch (e) {
      debugPrint('[SmartStay WebRTC] Permission request warning: $e');
      return true;
    }
  }

  /// Cấu hình chế độ âm thanh đàm thoại & bật loa ngoài trên Android/iOS.
  Future<void> configureAudioRouting({bool enableSpeaker = true}) async {
    speakerphoneOn = enableSpeaker;
    if (kIsWeb) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await Helper.setAndroidAudioConfiguration(
          AndroidAudioConfiguration.communication,
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        await Helper.ensureAudioSession();
      }
      await Helper.setSpeakerphoneOn(enableSpeaker);
      notifyListeners();
    } catch (e) {
      debugPrint('[SmartStay WebRTC] Audio routing configuration note: $e');
    }
  }

  /// Mở Microphone & Camera thực tế qua `navigator.mediaDevices.getUserMedia`
  /// và gắn vào `localRenderer.srcObject`.
  Future<bool> prepareLocalMedia(bool isVideo, String label) async {
    await ensureRenderersInitialized();
    await stopLocalMediaOnly();

    final permOk = await requestMediaPermissions(isVideo: isVideo);
    if (!permOk) {
      debugPrint('[SmartStay WebRTC] Media permissions denied by user.');
    }

    await configureAudioRouting(enableSpeaker: true);

    final mediaConstraints = <String, dynamic>{
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': isVideo
          ? {
              'facingMode': 'user',
              'width': {'ideal': 640},
              'height': {'ideal': 480},
              'frameRate': {'ideal': 24},
            }
          : false,
    };

    try {
      final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localStream = stream;
      hasLocalVideo = isVideo && stream.getVideoTracks().isNotEmpty;
      localRenderer.srcObject = stream;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[SmartStay WebRTC] getUserMedia primary failed ($e), trying audio-only fallback...');
      if (isVideo) {
        try {
          final audioOnlyStream = await navigator.mediaDevices.getUserMedia({
            'audio': true,
            'video': false,
          });
          _localStream = audioOnlyStream;
          hasLocalVideo = false;
          localRenderer.srcObject = audioOnlyStream;
          notifyListeners();
          return true;
        } catch (audioErr) {
          debugPrint('[SmartStay WebRTC] Audio-only fallback failed: $audioErr');
        }
      }
      hasLocalVideo = false;
      notifyListeners();
      return false;
    }
  }

  Future<RTCPeerConnection> _createOrResetPeerConnection(
    Map<String, dynamic> meta,
  ) async {
    await ensureRenderersInitialized();
    await _closePeerConnectionOnly();

    _activeMeta = Map<String, dynamic>.from(meta);
    _remoteDescriptionSet = false;
    _pendingRemoteCandidates.clear();
    iceConnectionStateLabel = 'checking';
    peerConnectionStateLabel = 'connecting';

    final pc = await createPeerConnection(rtcConfiguration, {
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    });
    _peerConnection = pc;

    // Gắn toàn bộ local tracks (audio + video) vào RTCPeerConnection trước khi tạo Offer/Answer
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    }

    pc.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate == null || candidate.candidate!.isEmpty) return;
      final currentMeta = _activeMeta;
      if (currentMeta == null) return;

      ApiService().postCallSignal({
        'callId': (currentMeta['callId'] ?? '').toString(),
        'signalType': 'webrtc_ice',
        'fromClientId':
            (currentMeta['fromClientId'] ?? ApiService.callClientId).toString(),
        'fromName': (currentMeta['fromName'] ?? 'SmartStay').toString(),
        'fromRole': (currentMeta['fromRole'] ?? 'CuDan').toString(),
        'targetClientId': (currentMeta['peerClientId'] ?? '').toString(),
        'targetRole': (currentMeta['peerRole'] ?? '').toString(),
        'payload': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    pc.onIceConnectionState = (RTCIceConnectionState state) {
      iceConnectionStateLabel = state.name
          .replaceAll('RTCIceConnectionState', '')
          .toLowerCase();
      debugPrint(
        '[SmartStay WebRTC] onIceConnectionState -> $iceConnectionStateLabel',
      );
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        // Đảm bảo loa ngoài được bật khi luồng RTP bắt đầu chảy
        if (!kIsWeb) {
          Helper.setSpeakerphoneOn(speakerphoneOn);
        }
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        debugPrint(
          '[SmartStay WebRTC] ICE Connection failed - attempting restartIce()',
        );
        try {
          pc.restartIce();
        } catch (_) {}
      }
      notifyListeners();
    };

    pc.onConnectionState = (RTCPeerConnectionState state) {
      peerConnectionStateLabel = state.name
          .replaceAll('RTCPeerConnectionState', '')
          .toLowerCase();
      debugPrint(
        '[SmartStay WebRTC] onConnectionState -> $peerConnectionStateLabel',
      );
      notifyListeners();
    };

    pc.onTrack = (RTCTrackEvent event) async {
      debugPrint(
        '[SmartStay WebRTC] onTrack kind=${event.track.kind}, streams=${event.streams.length}',
      );
      event.track.enabled = true;

      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
      } else {
        _remoteStream ??= await createLocalMediaStream('remote_peer_stream');
        await _remoteStream!.addTrack(event.track);
      }

      if (_remoteStream != null) {
        for (final audioTrack in _remoteStream!.getAudioTracks()) {
          audioTrack.enabled = true;
          if (!kIsWeb) {
            try {
              await Helper.setVolume(1.0, audioTrack);
            } catch (_) {}
          }
        }
        hasRemoteAudio = _remoteStream!.getAudioTracks().isNotEmpty;
        hasRemoteVideo = _remoteStream!.getVideoTracks().isNotEmpty;
        remoteRenderer.srcObject = _remoteStream;
      }

      if (event.track.kind == 'video') {
        hasRemoteVideo = true;
      } else if (event.track.kind == 'audio') {
        hasRemoteAudio = true;
      }
      notifyListeners();
    };

    pc.onAddStream = (MediaStream stream) {
      debugPrint('[SmartStay WebRTC] onAddStream id=${stream.id}');
      _remoteStream = stream;
      for (final audioTrack in stream.getAudioTracks()) {
        audioTrack.enabled = true;
      }
      hasRemoteAudio = stream.getAudioTracks().isNotEmpty;
      hasRemoteVideo = stream.getVideoTracks().isNotEmpty;
      remoteRenderer.srcObject = stream;
      notifyListeners();
    };

    notifyListeners();
    return pc;
  }

  /// Khởi tạo PeerConnection phía người gọi (Caller) và gửi SDP Offer sau khi người nhận bấm Chấp nhận.
  Future<void> startCallerPeer(String metaJson) async {
    if (_makingOffer) return;
    _makingOffer = true;
    try {
      final meta = jsonDecode(metaJson) as Map<String, dynamic>;
      final isVideo = meta['isVideo'] == true;
      if (_localStream == null) {
        await prepareLocalMedia(
          isVideo,
          (meta['fromName'] ?? 'SmartStay').toString(),
        );
      }

      final pc = await _createOrResetPeerConnection(meta);
      final offer = await pc.createOffer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': isVideo ? 1 : 0,
      });
      await pc.setLocalDescription(offer);

      await ApiService().postCallSignal({
        'callId': (meta['callId'] ?? '').toString(),
        'signalType': 'webrtc_offer',
        'fromClientId':
            (meta['fromClientId'] ?? ApiService.callClientId).toString(),
        'fromName': (meta['fromName'] ?? 'SmartStay').toString(),
        'fromRole': (meta['fromRole'] ?? 'CuDan').toString(),
        'targetClientId': (meta['peerClientId'] ?? '').toString(),
        'targetRole': (meta['peerRole'] ?? '').toString(),
        'payload': {
          'type': offer.type,
          'sdp': offer.sdp,
        },
      });
    } catch (e) {
      debugPrint('[SmartStay WebRTC] startCallerPeer error: $e');
    } finally {
      _makingOffer = false;
    }
  }

  /// Khởi tạo PeerConnection phía người nhận (Callee) trước khi gửi `call_accepted`.
  Future<void> startCalleePeer(String metaJson) async {
    try {
      final meta = jsonDecode(metaJson) as Map<String, dynamic>;
      final isVideo = meta['isVideo'] == true;
      if (_localStream == null) {
        await prepareLocalMedia(
          isVideo,
          (meta['fromName'] ?? 'SmartStay').toString(),
        );
      }
      await _createOrResetPeerConnection(meta);
    } catch (e) {
      debugPrint('[SmartStay WebRTC] startCalleePeer error: $e');
    }
  }

  /// Xử lý tín hiệu WebRTC (`webrtc_offer`, `webrtc_answer`, `webrtc_ice`) theo đúng thứ tự.
  /// Nếu ICE Candidate đến trước khi `setRemoteDescription` hoàn tất, hệ thống xếp vào hàng đợi `_pendingRemoteCandidates`.
  Future<void> handleRemoteSignal(String packetJson) async {
    try {
      final pkt = jsonDecode(packetJson) as Map<String, dynamic>;
      final seq = (pkt['seq'] as num?)?.toInt() ?? 0;
      if (seq > 0 && !_handledSignalSeqs.add(seq)) return;
      final sigType = (pkt['signalType'] ?? '').toString();
      final callId = (pkt['callId'] ?? '').toString();
      if (_activeMeta == null || callId.isEmpty) return;
      final activeCallId = (_activeMeta!['callId'] ?? '').toString();
      if (activeCallId != callId) return;

      final fromClientId = (pkt['fromClientId'] ?? '').toString();
      if (fromClientId.isNotEmpty) {
        _activeMeta!['peerClientId'] = fromClientId;
      }
      final fromRole = (pkt['fromRole'] ?? '').toString();
      if (fromRole.isNotEmpty) {
        _activeMeta!['peerRole'] = fromRole;
      }

      final rawPayload = pkt['payload'];
      final payload = rawPayload is Map
          ? Map<String, dynamic>.from(rawPayload)
          : (rawPayload is String
              ? Map<String, dynamic>.from(jsonDecode(rawPayload) as Map)
              : null);
      if (payload == null) return;

      if (sigType == 'webrtc_offer') {
        final sdp = (payload['sdp'] ?? '').toString();
        final type = (payload['type'] ?? 'offer').toString();
        if (sdp.isEmpty) return;

        final pc =
            _peerConnection ?? await _createOrResetPeerConnection(_activeMeta!);
        if (_remoteDescriptionSet &&
            pc.signalingState == RTCSignalingState.RTCSignalingStateStable) {
          return;
        }

        await pc.setRemoteDescription(RTCSessionDescription(sdp, type));
        _remoteDescriptionSet = true;
        await _flushPendingIceCandidates();

        final answer = await pc.createAnswer({
          'offerToReceiveAudio': 1,
          'offerToReceiveVideo': _activeMeta!['isVideo'] == true ? 1 : 0,
        });
        await pc.setLocalDescription(answer);

        await ApiService().postCallSignal({
          'callId': activeCallId,
          'signalType': 'webrtc_answer',
          'fromClientId':
              (_activeMeta!['fromClientId'] ?? ApiService.callClientId)
                  .toString(),
          'fromName': (_activeMeta!['fromName'] ?? 'SmartStay').toString(),
          'fromRole': (_activeMeta!['fromRole'] ?? 'CuDan').toString(),
          'targetClientId':
              fromClientId.isNotEmpty
                  ? fromClientId
                  : (_activeMeta!['peerClientId'] ?? '').toString(),
          'targetRole':
              fromRole.isNotEmpty
                  ? fromRole
                  : (_activeMeta!['peerRole'] ?? '').toString(),
          'payload': {
            'type': answer.type,
            'sdp': answer.sdp,
          },
        });
      } else if (sigType == 'webrtc_answer') {
        final pc = _peerConnection;
        if (pc == null) return;
        final sdp = (payload['sdp'] ?? '').toString();
        final type = (payload['type'] ?? 'answer').toString();
        if (sdp.isEmpty || _remoteDescriptionSet) return;

        await pc.setRemoteDescription(RTCSessionDescription(sdp, type));
        _remoteDescriptionSet = true;
        await _flushPendingIceCandidates();
      } else if (sigType == 'webrtc_ice') {
        final candStr = (payload['candidate'] ?? '').toString();
        if (candStr.isEmpty) return;
        final sdpMid = payload['sdpMid']?.toString();
        final sdpMLineIndex = payload['sdpMLineIndex'] is num
            ? (payload['sdpMLineIndex'] as num).toInt()
            : int.tryParse(payload['sdpMLineIndex']?.toString() ?? '');

        final iceCandidate = RTCIceCandidate(candStr, sdpMid, sdpMLineIndex);
        if (_peerConnection != null && _remoteDescriptionSet) {
          try {
            await _peerConnection!.addCandidate(iceCandidate);
          } catch (e) {
            debugPrint('[SmartStay WebRTC] addCandidate warning: $e');
          }
        } else {
          _pendingRemoteCandidates.add(iceCandidate);
        }
      }
    } catch (e) {
      debugPrint('[SmartStay WebRTC] handleRemoteSignal error: $e');
    }
  }

  Future<void> _flushPendingIceCandidates() async {
    final pc = _peerConnection;
    if (pc == null || !_remoteDescriptionSet) return;
    while (_pendingRemoteCandidates.isNotEmpty) {
      final candidate = _pendingRemoteCandidates.removeAt(0);
      try {
        await pc.addCandidate(candidate);
      } catch (e) {
        debugPrint('[SmartStay WebRTC] flush addCandidate warning: $e');
      }
    }
  }

  void setMicEnabled(bool enabled) {
    final stream = _localStream;
    if (stream == null) return;
    for (final track in stream.getAudioTracks()) {
      track.enabled = enabled;
      if (!kIsWeb) {
        Helper.setMicrophoneMute(!enabled, track);
      }
    }
    notifyListeners();
  }

  void setCamEnabled(bool enabled) {
    final stream = _localStream;
    if (stream == null) return;
    for (final track in stream.getVideoTracks()) {
      track.enabled = enabled;
    }
    hasLocalVideo = enabled && stream.getVideoTracks().isNotEmpty;
    notifyListeners();
  }

  Future<void> toggleSpeakerphone() async {
    await configureAudioRouting(enableSpeaker: !speakerphoneOn);
  }

  Future<void> switchCamera() async {
    final stream = _localStream;
    if (stream == null) return;
    final videoTracks = stream.getVideoTracks();
    if (videoTracks.isEmpty) return;
    try {
      await Helper.switchCamera(videoTracks.first);
    } catch (e) {
      debugPrint('[SmartStay WebRTC] switchCamera error: $e');
    }
  }

  Future<void> _closePeerConnectionOnly() async {
    _pendingRemoteCandidates.clear();
    _handledSignalSeqs.clear();
    _remoteDescriptionSet = false;
    final pc = _peerConnection;
    _peerConnection = null;
    if (pc != null) {
      try {
        pc.onIceCandidate = null;
        pc.onTrack = null;
        pc.onAddStream = null;
        pc.onIceConnectionState = null;
        pc.onConnectionState = null;
        await pc.close();
      } catch (_) {}
    }
    if (_renderersInitialized) {
      remoteRenderer.srcObject = null;
    }
    _remoteStream = null;
    hasRemoteVideo = false;
    hasRemoteAudio = false;
  }

  Future<void> stopLocalMediaOnly() async {
    final stream = _localStream;
    _localStream = null;
    hasLocalVideo = false;
    if (_renderersInitialized) {
      localRenderer.srcObject = null;
    }
    if (stream != null) {
      try {
        for (final t in stream.getTracks()) {
          await t.stop();
        }
        await stream.dispose();
      } catch (_) {}
    }
  }

  Future<void> hangup() async {
    _activeMeta = null;
    iceConnectionStateLabel = 'closed';
    peerConnectionStateLabel = 'closed';
    await _closePeerConnectionOnly();
    await stopLocalMediaOnly();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await Helper.clearAndroidCommunicationDevice();
      } catch (_) {}
    }
    notifyListeners();
  }
}
