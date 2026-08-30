import 'package:url_launcher/url_launcher.dart';

Future<bool> openExternalShareUrl(String url) async {
  final cleanUrl = url.trim();
  if (cleanUrl.isEmpty) return false;

  final uri = Uri.tryParse(cleanUrl);
  if (uri == null) return false;

  try {
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (opened) return true;
  } catch (_) {
    // Try the platform default below.
  }

  try {
    return await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
    );
  } catch (_) {
    return false;
  }
}
