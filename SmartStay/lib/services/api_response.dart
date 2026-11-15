class ApiResponse {
  const ApiResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

class PickedImageFile {
  const PickedImageFile({
    required this.fileName,
    required this.dataUrl,
  });

  final String fileName;
  final String dataUrl;
}
