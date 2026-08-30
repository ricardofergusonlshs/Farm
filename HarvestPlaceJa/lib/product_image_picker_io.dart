import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<String> uploadImageFromComputer({
  required String bucket,
  required String folder,
  required String fileNamePrefix,
}) async {
  final picker = ImagePicker();

  final picked = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 78,
    maxWidth: 1600,
  );

  if (picked == null) {
    throw Exception('No image selected.');
  }

  final file = File(picked.path);
  final extension = picked.name.split('.').last.toLowerCase();
  final safeExtension = extension.isEmpty ? 'jpg' : extension;

  final safePrefix = fileNamePrefix
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  final filePath =
      '$folder/${safePrefix.isEmpty ? 'product' : safePrefix}-${DateTime.now().millisecondsSinceEpoch}.$safeExtension';

  await Supabase.instance.client.storage.from(bucket).upload(
        filePath,
        file,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

  return Supabase.instance.client.storage.from(bucket).getPublicUrl(filePath);
}
