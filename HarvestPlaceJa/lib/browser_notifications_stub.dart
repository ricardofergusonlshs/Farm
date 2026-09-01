// Non-web implementation.
//
// Android/iOS/desktop use native push notifications instead.
// Browser notification APIs do not exist on these platforms.

Future<bool> requestBrowserNotifications() async {
  return false;
}

void showBrowserNotification({
  required String title,
  required String body,
  String? tag,
}) {}
