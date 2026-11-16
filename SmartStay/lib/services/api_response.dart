import 'dart:typed_data';

class ApiResponse {
  const ApiResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

class PickedImageFile {
  const PickedImageFile({
    required this.fileName,
    required this.dataUrl,
    this.bytes,
    this.mimeType = 'application/octet-stream',
  });

  final String fileName;
  final String dataUrl;
  final Uint8List? bytes;
  final String mimeType;
}
