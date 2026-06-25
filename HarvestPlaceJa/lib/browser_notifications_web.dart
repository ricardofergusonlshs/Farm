// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

final Map<String, DateTime> _recentBrowserNotifications = <String, DateTime>{};

Future<bool> requestBrowserNotifications() async {
  try {
    if (!html.Notification.supported) return false;

    final permission = html.Notification.permission;
    if (permission == 'granted') return true;
    if (permission == 'denied') return false;

    final requested = await html.Notification.requestPermission();
    return requested == 'granted';
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
    if (!html.Notification.supported) return;
    if (html.Notification.permission != 'granted') return;

    final cleanTitle = title.trim().isEmpty ? 'The Harvest Place Ja' : title.trim();
    final cleanBody = body.trim().isEmpty ? 'You have a new farm update.' : body.trim();
    final cleanTag = (tag == null || tag.trim().isEmpty)
        ? '$cleanTitle|$cleanBody'
        : tag.trim();

    final now = DateTime.now();
    _recentBrowserNotifications.removeWhere(
      (_, shownAt) => now.difference(shownAt) > const Duration(seconds: 30),
    );

    if (_recentBrowserNotifications.containsKey(cleanTag)) return;
    _recentBrowserNotifications[cleanTag] = now;

    final notification = html.Notification(
      cleanTitle,
      body: cleanBody,
      tag: cleanTag,
      icon: 'icons/Icon-192.png',
    );

    notification.onClick.listen((_) {
      notification.close();
    });
  } catch (_) {
    // Ignore browser notification failures.
  }
}
