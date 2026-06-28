export 'share_launcher_stub.dart'
    if (dart.library.html) 'share_launcher_web.dart'
    if (dart.library.io) 'share_launcher_mobile.dart';
