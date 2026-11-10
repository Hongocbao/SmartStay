import 'api_transport_io.dart'
    if (dart.library.html) 'api_transport_web.dart' as transport;
import 'api_response.dart';

export 'api_response.dart';

Future<ApiResponse> sendApiRequest({
  required String method,
  required Uri uri,
  required Map<String, String> headers,
  String? body,
}) => transport.sendApiRequest(
  method: method,
  uri: uri,
  headers: headers,
  body: body,
);
