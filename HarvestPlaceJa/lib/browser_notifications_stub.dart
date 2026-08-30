Future<bool> requestBrowserNotifications() async => false;

void showBrowserNotification({
  required String title,
  required String body,
  String? tag,
}) {
  // Browser notifications are intentionally disabled on non-web platforms.
  // Android/iOS push notifications continue to use Firebase Messaging.
}
