// HPJ non-web browser-notification stub.
//
// Android/iOS use Firebase/native notifications instead.

Future<bool> requestBrowserNotifications() async {
  return false;
}

void showBrowserNotification({
  required String title,
  required String body,
  String? tag,
}) {}
