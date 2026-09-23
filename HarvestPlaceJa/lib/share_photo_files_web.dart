// Web-only HPJ sharing helper: no dart:io or path_provider dependency.
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<XFile> hpjImageShareFile(
  Uint8List bytes, {
  required String fileName,
  required String mimeType,
}) async {
  if (bytes.isEmpty) {
    throw StateError('The HPJ sharing image has no data.');
  }
  return XFile.fromData(bytes, mimeType: mimeType, name: fileName);
}
