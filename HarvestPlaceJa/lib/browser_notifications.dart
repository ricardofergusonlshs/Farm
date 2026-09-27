// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

final Map<String, DateTime> _recentBrowserNotifications = <String, DateTime>{};

Future<bool> requestBrowserNotifications() async {
  try {
    if (!html.Notification.supported) {
      html.window.console.log('Browser notification skipped');
      return false;
    }

    final permission = html.Notification.permission;

    if (permission == 'granted') {
      html.window.console.log('Browser notifications granted');
      return true;
    }

    if (permission == 'denied') {
      html.window.console.log('Browser notifications denied');
      return false;
    }

    final requested = await html.Notification.requestPermission();

    if (requested == 'granted') {
      html.window.console.log('Browser notifications granted');
      return true;
    }

    html.window.console.log('Browser notifications denied');
    return false;
  } catch (_) {
    html.window.console.log('Browser notification skipped');
    return false;
  }
}

void showBrowserNotification({
  required String title,
  required String body,
  String? tag,
}) {
  try {
    if (!html.Notification.supported) {
      html.window.console.log('Browser notification skipped');
      return;
    }

    if (html.Notification.permission != 'granted') {
      html.window.console.log('Browser notification skipped');
      return;
    }

    final cleanTitle =
        title.trim().isEmpty ? 'The Harvest Place Ja' : title.trim();

    final cleanBody =
        body.trim().isEmpty ? 'You have a new farm update.' : body.trim();

    final cleanTag = (tag == null || tag.trim().isEmpty)
        ? '$cleanTitle|$cleanBody'
        : tag.trim();

    final now = DateTime.now();

    _recentBrowserNotifications.removeWhere(
      (_, shownAt) => now.difference(shownAt) > const Duration(seconds: 30),
    );

    if (_recentBrowserNotifications.containsKey(cleanTag)) {
      html.window.console.log('Browser notification skipped');
      return;
    }

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

    html.window.console.log('Browser notification shown');
  } catch (_) {
    html.window.console.log('Browser notification skipped');
  }
}
