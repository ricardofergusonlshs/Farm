Future<bool> requestBrowserNotifications() async {
  return false;
}

void showBrowserNotification({
  required String title,
  required String body,
  String? tag,
}) {
  // Browser notifications are only available on web.
  // Android builds use this safe no-op implementation.
}
