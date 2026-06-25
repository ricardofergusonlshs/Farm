// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
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
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = false;

  input.click();
  await input.onChange.first;

  final files = input.files;
  if (files == null || files.isEmpty) return null;

  final file = files.first;
  final reader = html.FileReader();
  final completer = Completer<Uint8List>();

  reader.onError.first.then((_) {
    if (!completer.isCompleted) {
      completer.completeError(Exception('Could not read selected image.'));
    }
  });

  reader.onLoad.first.then((_) {
    final result = reader.result;
    if (result is ByteBuffer) {
      completer.complete(Uint8List.view(result));
      return;
    }
    if (result is Uint8List) {
      completer.complete(result);
      return;
    }
    completer.completeError(Exception('Could not read selected image.'));
  });

  reader.readAsArrayBuffer(file);
  final bytes = await completer.future;

  return PickedProductImage(
    fileName: file.name,
    mimeType: file.type.isEmpty ? 'image/jpeg' : file.type,
    bytes: bytes,
  );
}
