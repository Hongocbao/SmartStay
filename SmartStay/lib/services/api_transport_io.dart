import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'api_response.dart';

final Map<String, String> _memoryStorage = {};

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
}) async => null;

Future<PickedImageFile?> pickImageFile() async => null;

Future<String?> pickImageDataUrl() async => null;

void writeLocalStorage(String key, String value) {
  _memoryStorage[key] = value;
}

String? readLocalStorage(String key) => _memoryStorage[key];
