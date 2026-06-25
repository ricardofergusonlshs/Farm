import 'dart:typed_data';

class PickedProductImage {
  final String fileName;
  final String mimeType;
  final Uint8List bytes;

  const PickedProductImage({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });
}

Future<PickedProductImage?> pickProductImageFromDevice() async {
  return null;
}
