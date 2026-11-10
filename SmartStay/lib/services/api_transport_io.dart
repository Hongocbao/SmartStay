import 'dart:convert';
import 'dart:io';

import 'api_response.dart';

Future<ApiResponse> sendApiRequest({
  required String method,
  required Uri uri,
  required Map<String, String> headers,
  String? body,
}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
  try {
    final request = await client.openUrl(method, uri);
    headers.forEach(request.headers.set);
    if (body != null) request.write(body);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    return ApiResponse(response.statusCode, responseBody);
  } finally {
    client.close(force: true);
  }
}
