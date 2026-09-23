// Platform-selecting HPJ image sharing helper.
// Android and iOS receive XFile objects backed by REAL image files.
// Web keeps XFile.fromData, where the web implementation supports it.
export 'share_photo_files_web.dart'
    if (dart.library.io) 'share_photo_files_io.dart';
