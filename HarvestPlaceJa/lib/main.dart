library harvest_place_app;

import 'dart:async';
import 'dart:ui';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'browser_notifications.dart' as browser_notifications;
import 'product_image_picker.dart';
import 'share_launcher.dart';

part 'app/app_config.dart';
part 'app/harvest_place_app.dart';
part 'theme/farm_colors.dart';
part 'models/models.dart';
part 'services/services.dart';
part 'screens/customer/customer_screens.dart';
part 'screens/admin/admin_screens.dart';
part 'widgets/shared_widgets.dart';
part 'utils/formatters_and_helpers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installBrowserPreviewKeyboardWorkaround();
  _syncKeyboardStateSafely();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(const FamilyFarmApp());
}
