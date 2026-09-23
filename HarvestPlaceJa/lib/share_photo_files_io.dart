// Native (Android/iOS/desktop) HPJ image sharing helper.
// A real file path prevents share_plus from reading a temporary directory
// as if it were the image (FileSystemException: errno = 21).
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<XFile> hpjImageShareFile(
  Uint8List bytes, {
  required String fileName,
  required String mimeType,
}) async {
  if (bytes.isEmpty) {
    throw StateError('The HPJ sharing image has no data.');
  }

  // Keep only a filename; never accept a path supplied by a remote source.
  final sanitized = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  final name = sanitized.isEmpty || sanitized == '.' || sanitized == '..'
      ? 'hpj-share.png'
      : sanitized;

  final temporary = await getTemporaryDirectory();
  final shareDirectory = Directory(
    '${temporary.path}${Platform.pathSeparator}hpj_share_images',
  );
  await shareDirectory.create(recursive: true);

  // Each tap gets a unique physical file. Keep it until the OS has consumed
  // the sharing intent; do NOT delete immediately after share() completes.
  final image = File(
    '${shareDirectory.path}${Platform.pathSeparator}'
    '${DateTime.now().microsecondsSinceEpoch}_$name',
  );
  await image.writeAsBytes(bytes, flush: true);

  if (!await image.exists() || await image.length() != bytes.length) {
    throw FileSystemException('The HPJ image could not be saved', image.path);
  }
  return XFile(image.path, mimeType: mimeType);
}
