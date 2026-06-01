// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> requestBrowserNotifications() async {
  try {
    final permission = await html.Notification.requestPermission();
    return permission == 'granted';
  } catch (_) {
    return false;
  }
}

void showBrowserNotification({
  required String title,
  required String body,
  String? tag,
}) {
  try {
    if (html.Notification.permission != 'granted') return;

    html.Notification(
      title,
      body: body,
      tag: tag,
    );
  } catch (_) {
    // Ignore browser notification errors.
  }
}
