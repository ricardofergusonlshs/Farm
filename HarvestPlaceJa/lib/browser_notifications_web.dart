// Web-only browser notification implementation.
// This file is selected only when dart.library.html is available.

import 'dart:html' as html;

final Map<String, DateTime> _recentBrowserNotifications =
    <String, DateTime>{};

Future<bool> requestBrowserNotifications() async {
  try {
    if (!html.Notification.supported) {
      html.window.console.log(
        'Browser notification skipped',
      );
      return false;
    }

    final currentPermission =
        html.Notification.permission;

    if (currentPermission == 'granted') {
      html.window.console.log(
        'Browser notifications granted',
      );
      return true;
    }

    if (currentPermission == 'denied') {
      html.window.console.log(
        'Browser notifications denied',
      );
      return false;
    }

    final permission =
        await html.Notification.requestPermission();
    final granted = permission == 'granted';

    html.window.console.log(
      granted
          ? 'Browser notifications granted'
          : 'Browser notifications denied',
    );

    return granted;
  } catch (_) {
    html.window.console.log(
      'Browser notification skipped',
    );
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
      html.window.console.log(
        'Browser notification skipped',
      );
      return;
    }

    if (html.Notification.permission != 'granted') {
      html.window.console.log(
        'Browser notification skipped',
      );
      return;
    }

    final cleanTitle = title.trim().isEmpty
        ? 'The Harvest Place Ja'
        : title.trim();
    final cleanBody = body.trim();
    final cleanTag =
        (tag ?? '$cleanTitle|$cleanBody').trim();

    final now = DateTime.now();

    _recentBrowserNotifications.removeWhere(
      (_, shownAt) =>
          now.difference(shownAt) >
          const Duration(seconds: 30),
    );

    if (_recentBrowserNotifications
        .containsKey(cleanTag)) {
      html.window.console.log(
        'Browser notification skipped',
      );
      return;
    }

    _recentBrowserNotifications[cleanTag] = now;

    final notification = html.Notification(
      cleanTitle,
      <String, dynamic>{
        'body': cleanBody,
        'tag': cleanTag,
        'icon': 'icons/Icon-192.png',
        'badge': 'icons/Icon-192.png',
      },
    );

    notification.onClick.listen((_) {
      html.window.focus();
      notification.close();
    });

    html.window.console.log(
      'Browser notification shown',
    );
  } catch (_) {
    html.window.console.log(
      'Browser notification skipped',
    );
  }
}
