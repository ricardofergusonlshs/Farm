// HPJ Repair 034D
// Platform-safe browser notification entry point.
//
// Android/iOS/desktop use the stub implementation.
// Flutter Web uses the browser Notification API implementation.

export 'browser_notifications_stub.dart'
    if (dart.library.html) 'browser_notifications_web.dart';
