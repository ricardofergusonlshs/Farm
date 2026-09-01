// HPJ Repair 034D
// Non-web implementation.
//
// Android/iOS use Firebase/native notifications instead.
// These no-op functions preserve the shared API without importing dart:html.

Future<bool> requestBrowserNotifications() async {
  return false;
}

void showBrowserNotification({
  required String title,
  required String body,
  String? tag,
}) {}
