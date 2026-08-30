library harvest_place_app;

import 'dart:async';
import 'dart:ui';

import 'package:app_links/app_links.dart';
import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import 'browser_notifications.dart' as browser_notifications;
import 'product_image_picker.dart';
import 'share_launcher.dart';

part 'app/app_config.dart';
part 'app/harvest_place_app.dart';
part 'theme/farm_colors.dart';
part 'models/models.dart';
part 'services/services.dart';
part 'services/push_notification_service.dart';
part 'screens/customer/customer_screens.dart';
part 'screens/settings/user_preferences.dart';
part 'screens/reels/fresh_reels.dart';
part 'screens/admin/admin_screens.dart';
part 'screens/admin/driver_delivery_management.dart';
part 'screens/farmer/farmer_partner_tools.dart';
part 'screens/wholesale/wholesale_management.dart';
part 'screens/warehouse/procurement_command_center.dart';
part 'screens/warehouse/collection_planning.dart';
part 'screens/warehouse/warehouse_inventory.dart';
part 'screens/warehouse/warehouse_picking.dart';
part 'screens/warehouse/warehouse_cycle_counts.dart';
part 'screens/warehouse/warehouse_packing_waves.dart';
part 'screens/warehouse/warehouse_dispatch_staging.dart';
part 'screens/warehouse/warehouse_exceptions.dart';
part 'screens/warehouse/warehouse_dispatch_command_center.dart';
part 'screens/warehouse/warehouse_driver_handover.dart';
part 'screens/warehouse/warehouse_delivery_runs.dart';
part 'screens/warehouse/warehouse_delivery_proof.dart';
part 'screens/warehouse/warehouse_returns.dart';
part 'screens/warehouse/warehouse_traceability.dart';
part 'screens/warehouse/warehouse_supplier_performance.dart';
part 'screens/warehouse/warehouse_procurement_intelligence.dart';
part 'screens/warehouse/warehouse_inventory_intelligence.dart';
part 'screens/warehouse/warehouse_expiry_waste_control.dart';
part 'screens/warehouse/warehouse_stockout_forecast.dart';
part 'screens/warehouse/warehouse_demand_forecasting.dart';
part 'screens/warehouse/warehouse_supply_gap_forecast.dart';
part 'screens/warehouse/warehouse_procurement_suggestions.dart';
part 'screens/finance/wholesale_finance.dart';
part 'screens/finance/farmer_settlements.dart';
part 'screens/finance/margin_control.dart';
part 'screens/finance/wholesale_credit_notes.dart';
part 'screens/finance/wholesale_return_finance.dart';
part 'screens/finance/supplier_claims.dart';
part 'screens/finance/wholesale_cash_flow.dart';
part 'screens/finance/farmer_payout_schedule.dart';
part 'screens/finance/bank_reconciliation.dart';
part 'screens/finance/wholesale_profitability_intelligence.dart';
part 'screens/finance/wholesale_pricing_control.dart';
part 'screens/finance/wholesale_commercial_recommendations.dart';
part 'screens/finance/finance_integrity.dart';
part 'screens/finance/finance_reconciliation.dart';
part 'screens/finance/finance_audit_center.dart';
part 'screens/executive/executive_intelligence.dart';
part 'screens/executive/business_forecasting.dart';
part 'screens/executive/executive_decision_center.dart';
part 'screens/executive/advanced_forecasting.dart';
part 'screens/executive/scenario_planning.dart';
part 'screens/executive/business_alerts.dart';
part 'screens/executive/release_validation.dart';
part 'screens/executive/forecast_calibration.dart';
part 'screens/executive/release_readiness.dart';
part 'widgets/shared_widgets.dart';
part 'utils/formatters_and_helpers.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();

  debugPrint(
    'Background notification received: ${message.messageId}',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isAndroidApp =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  if (isAndroidApp) {
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );
  }

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF4F9F2),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Text(
                'APP ERROR:\n\n${details.exceptionAsString()}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('UNCAUGHT PLATFORM ERROR: $error');
    debugPrintStack(stackTrace: stack);
    return true;
  };

  runApp(const FarmBootstrapApp());
}

class FarmBootstrapApp extends StatefulWidget {
  const FarmBootstrapApp({super.key});

  @override
  State<FarmBootstrapApp> createState() => _FarmBootstrapAppState();
}

class _FarmBootstrapAppState extends State<FarmBootstrapApp> {
  bool _ready = false;
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    unawaited(_startApp());
  }

  Future<void> _startApp() async {
    try {
      _installBrowserPreviewKeyboardWorkaround();
      _syncKeyboardStateSafely();

      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception(
            'Supabase took too long to start. Check internet, Supabase URL, anon key, or FlutLab preview connection.',
          );
        },
      );
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await PushNotificationService.initialise();
      }

      if (!mounted) return;

      setState(() {
        _ready = true;
        _error = null;
        _stackTrace = null;
      });
    } catch (error, stackTrace) {
      debugPrint('STARTUP ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _ready = false;
        _error = error;
        _stackTrace = stackTrace;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return const FamilyFarmApp();
    }

    return MaterialApp(
      title: 'The Harvest Place Ja',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF4F9F2),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _error == null
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 18),
                        Text(
                          'Starting The Harvest Place Ja...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Connecting to the farm marketplace.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 44,
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'The app could not start',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SelectableText(
                            _error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _error = null;
                                _stackTrace = null;
                              });

                              unawaited(_startApp());
                            },
                            child: const Text('Try again'),
                          ),
                          if (kDebugMode && _stackTrace != null) ...[
                            const SizedBox(height: 18),
                            SelectableText(
                              _stackTrace.toString(),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
