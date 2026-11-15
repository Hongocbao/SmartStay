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
