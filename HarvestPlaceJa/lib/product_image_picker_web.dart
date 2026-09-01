// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
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

String _mimeTypeFromName(String fileName) {
  final lower = fileName.toLowerCase().trim();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  return 'image/jpeg';
}

bool _hpjImagePickerBusy = false;

bool get hpjImagePickerBusy => _hpjImagePickerBusy;

Future<PickedProductImage?> pickProductImageFromDevice({
  HpjImageSource source = HpjImageSource.gallery,
}) async {
  // Web intentionally uses the browser's native file chooser for both
  // gallery and camera requests. This is reliable inside FlutLab/browser
  // previews and avoids embedded-user-agent camera failures.
  //
  // Keep a shared busy signal while the browser owns focus. Staff/Wholesale
  // workspace lifecycle observers use this to avoid rebuilding the entire
  // navigation shell while the native chooser is closing.
  if (_hpjImagePickerBusy) return null;

  _hpjImagePickerBusy = true;

  StreamSubscription<html.Event>? changeSubscription;
  StreamSubscription<html.Event>? focusSubscription;

  try {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..multiple = false;

    final selection = Completer<html.File?>();

    void finishSelection(html.File? file) {
      if (!selection.isCompleted) {
        selection.complete(file);
      }
    }

    changeSubscription = input.onChange.listen((_) {
      final files = input.files;
      finishSelection(
        files != null && files.isNotEmpty ? files.first : null,
      );
    });

    // Some browsers do not dispatch a change event when the chooser is
    // cancelled. When browser focus returns, give the input a moment to
    // populate, then finish safely with null if no file was chosen.
    focusSubscription = html.window.onFocus.listen((_) {
      Future<void>.delayed(
        const Duration(milliseconds: 280),
        () {
          if (selection.isCompleted) return;

          final files = input.files;
          finishSelection(
            files != null && files.isNotEmpty ? files.first : null,
          );
        },
      );
    });

    input.click();

    final file = await selection.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () => null,
    );

    if (file == null) return null;

    final reader = html.FileReader();
    final completer = Completer<Uint8List>();

    reader.onError.first.then((_) {
      if (!completer.isCompleted) {
        completer.completeError(
          Exception('Could not read selected image.'),
        );
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
      completer.completeError(
        Exception('Could not read selected image.'),
      );
    });

    reader.readAsArrayBuffer(file);

    final bytes = await completer.future;
    if (bytes.isEmpty) return null;

    final fileName = file.name.trim().isEmpty
        ? 'harvest-image-${DateTime.now().millisecondsSinceEpoch}.jpg'
        : file.name.trim();
    final cleanMime = file.type.trim();

    return PickedProductImage(
      fileName: fileName,
      mimeType: cleanMime.isEmpty ? _mimeTypeFromName(fileName) : cleanMime,
      bytes: bytes,
    );
  } finally {
    await changeSubscription?.cancel();
    await focusSubscription?.cancel();
    _hpjImagePickerBusy = false;
  }
}
