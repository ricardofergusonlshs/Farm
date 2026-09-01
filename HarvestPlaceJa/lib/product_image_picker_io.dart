import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

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

String _safeFileName(String path, String fallback) {
  final clean = path.trim();
  if (clean.isEmpty) return fallback;

  final parts = clean.split(RegExp(r'[\\/]'));
  final name = parts.isEmpty ? fallback : parts.last.trim();
  return name.isEmpty ? fallback : name;
}

String _contentTypeForFileName(String fileName) {
  final lower = fileName.toLowerCase().trim();

  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.heic')) return 'image/heic';
  if (lower.endsWith('.heif')) return 'image/heif';

  return 'image/jpeg';
}

bool _hpjImagePickerBusy = false;

bool get hpjImagePickerBusy => _hpjImagePickerBusy;

Future<PickedProductImage?> pickProductImageFromDevice({
  HpjImageSource source = HpjImageSource.gallery,
}) async {
  // Prevent overlapping camera/gallery requests and let workspace lifecycle
  // observers know that a media picker is temporarily controlling focus.
  if (_hpjImagePickerBusy) return null;

  _hpjImagePickerBusy = true;

  try {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: source == HpjImageSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: source == HpjImageSource.camera ? 82 : 88,
      maxWidth: 1800,
    );

    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) return null;

    final fileName = _safeFileName(
      picked.name.isNotEmpty ? picked.name : picked.path,
      'harvest-image-${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    return PickedProductImage(
      fileName: fileName,
      mimeType: picked.mimeType ?? _contentTypeForFileName(fileName),
      bytes: bytes,
    );
  } finally {
    _hpjImagePickerBusy = false;
  }
}
