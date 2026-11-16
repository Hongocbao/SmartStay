import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'api_response.dart';
import 'webrtc_call_service.dart';

final Map<String, String> _memoryStorage = {};
Timer? _nativeRingTimer;

final HttpClient _localClient = HttpClient()
  ..connectionTimeout = const Duration(seconds: 5);

final HttpClient _cloudClient = HttpClient()
  ..connectionTimeout = const Duration(seconds: 15);

bool _isLocalHost(String host) {
  final lower = host.toLowerCase();
  return lower == 'localhost' || lower == '127.0.0.1' || lower == '10.0.2.2';
}

Future<ApiResponse> sendApiRequest({
  required String method,
  required Uri uri,
  required Map<String, String> headers,
  String? body,
  Duration? timeout,
}) async {
  final isLocal = _isLocalHost(uri.host);
  final client = isLocal ? _localClient : _cloudClient;
  final effectiveTimeout = timeout ??
      (isLocal ? const Duration(seconds: 10) : const Duration(seconds: 15));

  Future<ApiResponse> execute() async {
    final request = await client.openUrl(method, uri);
    headers.forEach(request.headers.set);
    if (body != null) request.write(body);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    return ApiResponse(response.statusCode, responseBody);
  }

  return execute().timeout(effectiveTimeout);
}

Future<PickedImageFile?> pickMediaFile({
  bool acceptVideo = false,
  bool useCamera = false,
}) async {
  try {
    final picker = ImagePicker();
    final source = useCamera ? ImageSource.camera : ImageSource.gallery;
    final XFile? file = acceptVideo
        ? await picker.pickVideo(
            source: source,
            maxDuration: const Duration(seconds: 60),
          )
        : await picker.pickImage(
            source: source,
            imageQuality: 85,
            maxWidth: 1600,
          );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final lowerName = file.name.toLowerCase();
    final mime = acceptVideo
        ? (lowerName.endsWith('.webm') ? 'video/webm' : 'video/mp4')
        : (lowerName.endsWith('.png') ? 'image/png' : 'image/jpeg');
    final dataUrl = acceptVideo
        ? file.path
        : 'data:$mime;base64,${base64Encode(bytes)}';
    return PickedImageFile(
      fileName: file.name,
      dataUrl: dataUrl,
      bytes: bytes,
      mimeType: mime,
    );
  } catch (_) {
    return null;
  }
}

Future<PickedImageFile?> pickImageFile() => pickMediaFile(acceptVideo: false);

Future<String?> pickImageDataUrl() async => (await pickImageFile())?.dataUrl;

void writeLocalStorage(String key, String value) {
  _memoryStorage[key] = value;
}

String? readLocalStorage(String key) => _memoryStorage[key];

void rtcStartRingtone() {
  rtcStopRingtone();
  SystemSound.play(SystemSoundType.alert);
  HapticFeedback.vibrate();
  _nativeRingTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.vibrate();
  });
}

void rtcStopRingtone() {
  _nativeRingTimer?.cancel();
  _nativeRingTimer = null;
}

Future<bool> rtcPrepareLocalMedia(bool isVideo, String label) =>
    WebRtcCallService().prepareLocalMedia(isVideo, label);

Future<void> rtcStartCallerPeer(String metaJson) =>
    WebRtcCallService().startCallerPeer(metaJson);

Future<void> rtcStartCalleePeer(String metaJson) =>
    WebRtcCallService().startCalleePeer(metaJson);

Future<void> rtcHandleSignal(String packetJson) =>
    WebRtcCallService().handleRemoteSignal(packetJson);

void rtcSetMic(bool enabled) => WebRtcCallService().setMicEnabled(enabled);

void rtcSetCam(bool enabled) => WebRtcCallService().setCamEnabled(enabled);

void rtcHangup() => unawaited(WebRtcCallService().hangup());

Future<Map<String, dynamic>?> analyzeMeterImageOcr({
  required String dataUrl,
  required String meterType,
  required int previousReading,
  required String apiBaseUrl,
}) async => null;
