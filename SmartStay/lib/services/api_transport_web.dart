import 'dart:async';
// Conditional-import web transport intentionally uses dart:html until migrated to package:web.
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

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
