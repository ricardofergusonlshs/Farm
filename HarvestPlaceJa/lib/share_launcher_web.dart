// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

Future<bool> openExternalShareUrl(String url) async {
  try {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return false;
    html.window.open(cleanUrl, '_blank');
    return true;
  } catch (_) {
    return false;
  }
}
