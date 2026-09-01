// Non-web implementation.
// Android/iOS/desktop use native push notifications instead.

Future<bool> requestBrowserNotifications() async {
  return false;
}

void showBrowserNotification({
  required String title,
  required String body,
  String? tag,
}) {}
