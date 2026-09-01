import 'dart:typed_data';

enum HpjImageSource {
  gallery,
  camera,
}

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

bool get hpjImagePickerBusy => false;

Future<PickedProductImage?> pickProductImageFromDevice({
  HpjImageSource source = HpjImageSource.gallery,
}) async {
  throw UnsupportedError(
    'Image upload is not available on this platform.',
  );
}
