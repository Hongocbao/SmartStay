import 'api_transport_io.dart'
    if (dart.library.html) 'api_transport_web.dart' as transport;
import 'api_response.dart';

export 'api_response.dart';

Future<ApiResponse> sendApiRequest({
  required String method,
  required Uri uri,
  required Map<String, String> headers,
  String? body,
  Duration? timeout,
}) => transport.sendApiRequest(
  method: method,
  uri: uri,
  headers: headers,
  body: body,
  timeout: timeout,
);

Future<PickedImageFile?> pickMediaFile({
  bool acceptVideo = false,
  bool useCamera = false,
}) => transport.pickMediaFile(
  acceptVideo: acceptVideo,
  useCamera: useCamera,
);

Future<PickedImageFile?> pickImageFile() => transport.pickImageFile();

Future<String?> pickImageDataUrl() => transport.pickImageDataUrl();

void writeLocalStorage(String key, String value) =>
    transport.writeLocalStorage(key, value);

String? readLocalStorage(String key) => transport.readLocalStorage(key);

void rtcStartRingtone() => transport.rtcStartRingtone();
void rtcStopRingtone() => transport.rtcStopRingtone();
Future<bool> rtcPrepareLocalMedia(bool isVideo, String label) =>
    transport.rtcPrepareLocalMedia(isVideo, label);
Future<void> rtcStartCallerPeer(String metaJson) =>
    transport.rtcStartCallerPeer(metaJson);
Future<void> rtcStartCalleePeer(String metaJson) =>
    transport.rtcStartCalleePeer(metaJson);
Future<void> rtcHandleSignal(String packetJson) =>
    transport.rtcHandleSignal(packetJson);
void rtcSetMic(bool enabled) => transport.rtcSetMic(enabled);
void rtcSetCam(bool enabled) => transport.rtcSetCam(enabled);
void rtcHangup() => transport.rtcHangup();

Future<Map<String, dynamic>?> analyzeMeterImageOcr({
  required String dataUrl,
  required String meterType,
  required int previousReading,
  required String apiBaseUrl,
}) => transport.analyzeMeterImageOcr(
  dataUrl: dataUrl,
  meterType: meterType,
  previousReading: previousReading,
  apiBaseUrl: apiBaseUrl,
);
