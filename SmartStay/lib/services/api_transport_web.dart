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
}) async {
  final completer = Completer<ApiResponse>();
  final xhr = html.HttpRequest();
  xhr.open(method, uri.toString());
  xhr.timeout = 2000;
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
