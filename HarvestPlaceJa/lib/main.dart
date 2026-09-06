library harvest_place_app;

import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:app_links/app_links.dart';
import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
part 'screens/farmer/farm_public_profile.dart';
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

bool _hpjFirebaseMessagingReady = false;
bool _hpjBackgroundHandlerRegistered = false;
Future<bool>? _hpjFirebasePreparation;
Future<void>? _hpjSupabasePreparation;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  try {
    await Firebase.initializeApp();

    debugPrint(
      'Background notification received: ${message.messageId}',
    );
  } catch (error, stackTrace) {
    debugPrint('Background Firebase initialisation failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<bool> _initialiseHpjFirebaseMessaging() async {
  try {
    await Firebase.initializeApp();

    if (!_hpjBackgroundHandlerRegistered) {
      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );
      _hpjBackgroundHandlerRegistered = true;
    }

    _hpjFirebaseMessagingReady = true;
    debugPrint('HPJ Firebase Messaging ready.');
    return true;
  } catch (error, stackTrace) {
    _hpjFirebasePreparation = null;
    debugPrint('Firebase Messaging startup unavailable: $error');
    debugPrintStack(stackTrace: stackTrace);
    return false;
  }
}

Future<bool> _prepareHpjFirebaseMessaging() {
  final isAndroidApp =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  if (!isAndroidApp) return Future<bool>.value(false);
  if (_hpjFirebaseMessagingReady) return Future<bool>.value(true);

  return _hpjFirebasePreparation ??= _initialiseHpjFirebaseMessaging();
}

Future<void> _initialiseHpjSupabase() async {
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  } catch (_) {
    _hpjSupabasePreparation = null;
    rethrow;
  }
}

Future<void> _prepareHpjSupabase() {
  return _hpjSupabasePreparation ??= _initialiseHpjSupabase();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFFF4F9F2),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Something went wrong on this screen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 12),
                    SelectableText(
                      details.exceptionAsString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
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

  // Register Firebase Messaging before the first widget is mounted so Android
  // background notification handling is ready before HPJ can be backgrounded.
  // This remains fail-soft: Firebase must never prevent the marketplace opening.
  try {
    await _prepareHpjFirebaseMessaging().timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        debugPrint(
          'Initial Firebase Messaging preparation timed out. HPJ will continue.',
        );
        return false;
      },
    );
  } catch (error, stackTrace) {
    debugPrint('Initial Firebase Messaging preparation skipped: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(const FarmBootstrapApp());
}

class FarmBootstrapApp extends StatefulWidget {
  const FarmBootstrapApp({super.key});

  @override
  State<FarmBootstrapApp> createState() => _FarmBootstrapAppState();
}

class _FarmBootstrapAppState extends State<FarmBootstrapApp> {
  bool _ready = false;
  bool _starting = false;
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    unawaited(_startApp());
  }

  Future<void> _startApp() async {
    if (_starting) return;

    setState(() {
      _starting = true;
      _error = null;
      _stackTrace = null;
    });

    try {
      try {
        _installBrowserPreviewKeyboardWorkaround();
        _syncKeyboardStateSafely();
      } catch (error, stackTrace) {
        // Preview keyboard helpers are non-essential to marketplace startup.
        debugPrint('Keyboard preview setup skipped: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      await _prepareHpjSupabase().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException(
            'HPJ could not connect to Supabase within 20 seconds.',
          );
        },
      );

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final firebaseReady = await _prepareHpjFirebaseMessaging().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint(
              'Firebase Messaging startup timed out. HPJ will continue without push for this startup.',
            );
            return false;
          },
        );

        if (firebaseReady) {
          try {
            await PushNotificationService.initialise().timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                debugPrint(
                  'Push notification service startup timed out. HPJ will continue.',
                );
              },
            );
          } catch (error, stackTrace) {
            // Push failure must never stop ordering, farmer, warehouse, or admin work.
            debugPrint('Push notification service startup skipped: $error');
            debugPrintStack(stackTrace: stackTrace);
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _ready = true;
        _starting = false;
        _error = null;
        _stackTrace = null;
      });
    } catch (error, stackTrace) {
      debugPrint('STARTUP ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _ready = false;
        _starting = false;
        _error = error;
        _stackTrace = stackTrace;
      });
    }
  }

  String _startupMessage() {
    final errorText = _error?.toString().toLowerCase() ?? '';

    if (errorText.contains('timeout') ||
        errorText.contains('supabase') ||
        errorText.contains('socket') ||
        errorText.contains('network')) {
      return 'HPJ could not connect to the marketplace service. Check your internet connection and try again.';
    }

    return 'HPJ could not finish starting. Please try again.';
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
                          Text(
                            _startupMessage(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (kDebugMode && _error != null) ...[
                            const SizedBox(height: 14),
                            SelectableText(
                              _error.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _starting ? null : _startApp,
                            child: Text(
                              _starting ? 'Starting...' : 'Try again',
                            ),
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
