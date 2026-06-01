Future<bool> requestBrowserNotifications() async {
  return false;
}

void showBrowserNotification({
  required String title,
  required String body,
  String? tag,
}) {
  // Browser notifications are web-only.
  // This empty version allows Android release builds to compile safely.
}
