import 'dart:async';
// Conditional-import web transport uses dart:html until migrated to package:web, plus dart:js_interop for WASM-safe JS bridges.
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'api_response.dart';

Future<ApiResponse> sendApiRequest({
  required String method,
  required Uri uri,
  required Map<String, String> headers,
  String? body,
  Duration? timeout,
}) async {
  final completer = Completer<ApiResponse>();
  final xhr = html.HttpRequest();
  xhr.open(method, uri.toString());
  final effectiveTimeout = timeout ?? const Duration(seconds: 15);
  xhr.timeout = effectiveTimeout.inMilliseconds;
  headers.forEach(xhr.setRequestHeader);

  xhr.onLoad.listen((_) {
    if (!completer.isCompleted) {
      completer.complete(ApiResponse(xhr.status ?? 0, xhr.responseText ?? ''));
    }
  });

  xhr.onError.listen((_) {
    if (!completer.isCompleted) {
      completer.completeError(StateError('Network error'));
    }
  });

  xhr.onTimeout.listen((_) {
    if (!completer.isCompleted) {
      completer.completeError(TimeoutException('Request timeout'));
    }
  });

  xhr.send(body);
  return completer.future;
}

Future<PickedImageFile?> pickMediaFile({
  bool acceptVideo = false,
  bool useCamera = false,
}) async {
  final input = html.FileUploadInputElement()
    ..accept = acceptVideo
        ? 'video/*'
        : 'image/png,image/jpeg,image/webp,image/gif';
  if (useCamera) {
    input.setAttribute('capture', 'environment');
  }
  input.click();
  await input.onChange.first;
  final files = input.files;
  if (files == null || files.isEmpty) return null;

  final file = files.first;
  if (acceptVideo && file.size > 4500000) {
    final objectUrl = html.Url.createObjectUrlFromBlob(file);
    return PickedImageFile(fileName: file.name, dataUrl: objectUrl);
  }

  final completer = Completer<PickedImageFile?>();
  final reader = html.FileReader();
  reader.onLoadEnd.listen((_) {
    if (!completer.isCompleted) {
      final result = reader.result;
      completer.complete(
        result is String
            ? PickedImageFile(fileName: file.name, dataUrl: result)
            : null,
      );
    }
  });
  reader.onError.listen((_) {
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  });
  reader.readAsDataUrl(file);
  return completer.future;
}

Future<PickedImageFile?> pickImageFile() => pickMediaFile(acceptVideo: false);

Future<String?> pickImageDataUrl() async => (await pickImageFile())?.dataUrl;

void writeLocalStorage(String key, String value) {
  try {
    html.window.localStorage[key] = value;
  } catch (_) {}
}

String? readLocalStorage(String key) {
  try {
    return html.window.localStorage[key];
  } catch (_) {
    return null;
  }
}

JSObject? _windowGlobalObj(String propName) {
  try {
    final val = globalContext.getProperty<JSAny?>(propName.toJS);
    return (val != null && val.isA<JSObject>()) ? val as JSObject : null;
  } catch (_) {
    return null;
  }
}

void rtcStartRingtone() {
  final rtc = _windowGlobalObj('SmartStayFlutterWebRTC');
  rtc?.callMethod<JSAny?>('startRingtone'.toJS);
}

void rtcStopRingtone() {
  final rtc = _windowGlobalObj('SmartStayFlutterWebRTC');
  rtc?.callMethod<JSAny?>('stopRingtone'.toJS);
}

Future<bool> rtcPrepareLocalMedia(bool isVideo, String label) async {
  final rtc = _windowGlobalObj('SmartStayFlutterWebRTC');
  if (rtc == null) return false;
  try {
    final promise = rtc.callMethod<JSPromise<JSAny?>>(
      'prepareLocalMedia'.toJS,
      isVideo.toJS,
      label.toJS,
    );
    final res = await promise.toDart;
    return res?.dartify() == true;
  } catch (_) {
    return false;
  }
}

Future<void> rtcStartCallerPeer(String metaJson) async {
  final rtc = _windowGlobalObj('SmartStayFlutterWebRTC');
  if (rtc == null) return;
  try {
    final promise = rtc.callMethod<JSPromise<JSAny?>>(
      'startCallerPeer'.toJS,
      metaJson.toJS,
    );
    await promise.toDart;
  } catch (_) {}
}

Future<void> rtcStartCalleePeer(String metaJson) async {
  final rtc = _windowGlobalObj('SmartStayFlutterWebRTC');
  if (rtc == null) return;
  try {
    final promise = rtc.callMethod<JSPromise<JSAny?>>(
      'startCalleePeer'.toJS,
      metaJson.toJS,
    );
    await promise.toDart;
  } catch (_) {}
}

Future<void> rtcHandleSignal(String packetJson) async {
  final rtc = _windowGlobalObj('SmartStayFlutterWebRTC');
  if (rtc == null) return;
  try {
    final promise = rtc.callMethod<JSPromise<JSAny?>>(
      'handleRemoteSignal'.toJS,
      packetJson.toJS,
    );
    await promise.toDart;
  } catch (_) {}
}

void rtcSetMic(bool enabled) {
  final rtc = _windowGlobalObj('SmartStayFlutterWebRTC');
  rtc?.callMethod<JSAny?>('setMic'.toJS, enabled.toJS);
}

void rtcSetCam(bool enabled) {
  final rtc = _windowGlobalObj('SmartStayFlutterWebRTC');
  rtc?.callMethod<JSAny?>('setCam'.toJS, enabled.toJS);
}

void rtcHangup() {
  final rtc = _windowGlobalObj('SmartStayFlutterWebRTC');
  rtc?.callMethod<JSAny?>('hangup'.toJS);
}

Future<Map<String, dynamic>?> analyzeMeterImageOcr({
  required String dataUrl,
  required String meterType,
  required int previousReading,
  required String apiBaseUrl,
}) async {
  try {
    final ocrObj = _windowGlobalObj('SmartStayMeterOcr');
    if (ocrObj == null) return null;
    final promise = ocrObj.callMethod<JSPromise<JSAny?>>(
      'analyzeMeterImage'.toJS,
      dataUrl.toJS,
      meterType.toJS,
      previousReading.toJS,
      apiBaseUrl.toJS,
    );
    final dartRes = (await promise.toDart)?.dartify();
    if (dartRes is! Map) return null;
    final map = Map<String, dynamic>.from(dartRes);
    final readingProp = map['reading'];
    if (readingProp is! num) return null;
    final altProp = map['alternativeReading'];
    final confProp = map['confidence'];
    return <String, dynamic>{
      'success': map['success'] == true,
      'provider': map['provider']?.toString() ?? '',
      'meterType': map['meterType']?.toString() ?? meterType,
      'rawText': map['rawText']?.toString() ?? '',
      'reading': readingProp.toInt(),
      'alternativeReading': altProp is num ? altProp.toInt() : null,
      'hasRedDecimalDigit': map['hasRedDecimalDigit'] == true,
      'meterStyle': map['meterStyle']?.toString() ?? '',
      'confidence': confProp is num ? confProp.toDouble() : null,
      'note': map['note']?.toString() ?? '',
    };
  } catch (_) {
    return null;
  }
}
