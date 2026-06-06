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

  final completer = Completer<PickedProductImage?>();

  input.onChange.listen((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    final file = files.first;
    final reader = html.FileReader();

    reader.onError.listen((_) {
      if (!completer.isCompleted) completer.complete(null);
    });

    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is Uint8List) {
        if (!completer.isCompleted) {
          completer.complete(
            PickedProductImage(
              fileName: file.name,
              mimeType: file.type.isEmpty ? 'image/jpeg' : file.type,
              bytes: result,
            ),
          );
        }
        return;
      }

      final bytes = reader.result;
      if (bytes is List<int>) {
        if (!completer.isCompleted) {
          completer.complete(
            PickedProductImage(
              fileName: file.name,
              mimeType: file.type.isEmpty ? 'image/jpeg' : file.type,
              bytes: Uint8List.fromList(bytes),
            ),
          );
        }
        return;
      }

      if (!completer.isCompleted) completer.complete(null);
    });

    reader.readAsArrayBuffer(file);
  });

  input.click();
  return completer.future;
}
