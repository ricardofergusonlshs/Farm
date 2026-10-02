part of harvest_place_app;

// ============================================================================
// HPJ 9/10 MVP PRODUCTION SERVICES
// Audience analytics, operational health, substitutions and release control.
// ============================================================================

String _hpjMvpClean(String? value, {int max = 180}) {
  final clean = (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
  return clean.length <= max ? clean : clean.substring(0, max);
}

int _hpjMvpInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? fallback;
}

double _hpjMvpDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString()) ?? fallback;
}

bool _hpjMvpBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  final text = (value ?? '').toString().trim().toLowerCase();
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return fallback;
}

DateTime? _hpjMvpDate(dynamic value) {
  final text = (value ?? '').toString().trim();
  return text.isEmpty ? null : DateTime.tryParse(text);
}

class HpjRuntimePackageInfo {
  final String version;
  final int build;

  const HpjRuntimePackageInfo({required this.version, required this.build});

  static HpjRuntimePackageInfo? _cache;

  static Future<HpjRuntimePackageInfo> load() async {
    final cached = _cache;
    if (cached != null) return cached;

    try {
      final info = await PackageInfo.fromPlatform();
      final value = HpjRuntimePackageInfo(
        version: info.version.trim().isEmpty ? AppConfig.appVersion : info.version.trim(),
        build: int.tryParse(info.buildNumber.trim()) ??
            int.tryParse(AppConfig.appBuildNumber) ??
            0,
      );
      _cache = value;
      return value;
    } catch (_) {
      final value = HpjRuntimePackageInfo(
        version: AppConfig.appVersion,
        build: int.tryParse(AppConfig.appBuildNumber) ?? 0,
      );
      _cache = value;
      return value;
    }
  }
}

class HpjAudienceAnalytics {
  static const _visitorKey = 'hpj_audience_visitor_id_v1';
  static String? _sessionId;
  static String? _visitorId;
  static Timer? _heartbeat;
  static bool _starting = false;

  static String get _platform {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'other';
  }

  static String _newId(String prefix) {
    final random = Random.secure();
    final bytes = List<int>.generate(12, (_) => random.nextInt(256));
    final tail = base64UrlEncode(bytes).replaceAll('=', '');
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$tail';
  }

  static Future<String> _ensureVisitorId() async {
    if (_visitorId != null) return _visitorId!;
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = (prefs.getString(_visitorKey) ?? '').trim();
      if (existing.length >= 8) {
        _visitorId = existing;
        return existing;
      }
      final created = _newId('visitor');
      await prefs.setString(_visitorKey, created);
      _visitorId = created;
      return created;
    } catch (_) {
      return _visitorId ??= _newId('visitor');
    }
  }

  static String _trafficSource() {
    final uri = Uri.base;
    for (final key in const ['utm_source', 'source', 'ref']) {
      final value = uri.queryParameters[key]?.trim() ?? '';
      if (value.isNotEmpty) return _hpjMvpClean(value, max: 120);
    }
    return 'direct';
  }

  static Future<void> startSession() async {
    if (_sessionId != null || _starting) return;
    _starting = true;
    try {
      _sessionId = _newId('session');
      await track(
        'session_start',
        screenName: kIsWeb ? 'website' : 'app',
        metadata: <String, dynamic>{'presentation': kIsWeb ? 'web' : 'native'},
      );
      _heartbeat?.cancel();
      _heartbeat = Timer.periodic(const Duration(minutes: 2), (_) {
        unawaited(track('heartbeat', screenName: 'active_session'));
      });
    } finally {
      _starting = false;
    }
  }

  static Future<void> track(
    String eventName, {
    String screenName = '',
    String entityType = '',
    String entityId = '',
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    try {
      final visitorId = await _ensureVisitorId();
      _sessionId ??= _newId('session');
      final package = await HpjRuntimePackageInfo.load();
      await supabase.rpc(
        'hpj_record_analytics_event',
        params: <String, dynamic>{
          'p_visitor_id': visitorId,
          'p_session_id': _sessionId,
          'p_platform': _platform,
          'p_app_version': package.version,
          'p_app_build': package.build,
          'p_traffic_source': _trafficSource(),
          'p_event_name': _hpjMvpClean(eventName, max: 60).toLowerCase(),
          'p_screen_name': _hpjMvpClean(screenName, max: 120),
          'p_entity_type': _hpjMvpClean(entityType, max: 60),
          'p_entity_id': _hpjMvpClean(entityId, max: 160),
          'p_metadata': metadata,
        },
      );
    } catch (error) {
      farmDebugLog('Audience analytics skipped safely: $error');
    }
  }

  static Future<void> trackFromCustomerActivity({
    required String eventType,
    Product? product,
    String query = '',
    int? quantity,
    String source = 'customer',
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    const map = <String, String>{
      'session_start': 'session_start',
      'search': 'search',
      'product_view': 'product_view',
      'favorite_add': 'favorite_add',
      'favorite_remove': 'favorite_remove',
      'cart_add': 'my_box_add',
      'cart_remove': 'my_box_remove',
      'checkout_start': 'checkout_start',
      'purchase': 'order_complete',
    };
    final mapped = map[eventType];
    if (mapped == null) return Future<void>.value();

    final merged = <String, dynamic>{
      ...metadata,
      'source': source,
      if (query.trim().isNotEmpty) 'query': _hpjMvpClean(query, max: 180),
      if (quantity != null) 'quantity': quantity,
      if (product != null) 'product_name': product.name,
      if (product != null) 'category': product.category,
    };

    final orderId = mapped == 'order_complete'
        ? _hpjMvpClean(metadata['order_id']?.toString(), max: 160)
        : '';

    return track(
      mapped,
      screenName: source,
      entityType: product != null ? 'product' : mapped == 'order_complete' ? 'order' : '',
      entityId: product?.id ?? orderId,
      metadata: merged,
    );
  }
}

class _HpjAudienceNavigatorObserver extends NavigatorObserver {
  void _record(Route<dynamic>? route) {
    if (route == null) return;
    final name = route.settings.name?.trim();
    final screen = name != null && name.isNotEmpty ? name : route.runtimeType.toString();
    unawaited(HpjAudienceAnalytics.track('screen_view', screenName: screen));
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _record(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _record(newRoute);
  }
}

final NavigatorObserver hpjAudienceNavigatorObserver = _HpjAudienceNavigatorObserver();

class HpjReliability {
  static bool _initialised = false;

  static String get _platform {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'other';
  }

  static Future<void> initialise() async {
    if (_initialised) return;
    _initialised = true;
    final info = await HpjRuntimePackageInfo.load();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await FirebaseCrashlytics.instance.setCustomKey('hpj_version', info.version);
        await FirebaseCrashlytics.instance.setCustomKey('hpj_build', info.build);
        await FirebaseCrashlytics.instance.setCustomKey('hpj_platform', _platform);
      } catch (error) {
        farmDebugLog('Crashlytics setup skipped safely: $error');
      }
    }
  }

  static Future<void> recordFlutterError(FlutterErrorDetails details) async {
    await initialise();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      } catch (_) {}
    }
    await recordHealthOnly(
      severity: 'fatal',
      area: 'flutter',
      eventKey: 'flutter_error',
      message: details.exceptionAsString(),
    );
  }

  static Future<void> recordUncaught(Object error, StackTrace stack) async {
    await initialise();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (_) {}
    }
    await recordHealthOnly(
      severity: 'fatal',
      area: 'platform',
      eventKey: 'uncaught_platform_error',
      message: error.toString(),
    );
  }

  static Future<void> recordNonFatal(
    Object error, {
    StackTrace? stackTrace,
    String area = 'app',
    String eventKey = 'non_fatal',
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    await initialise();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace ?? StackTrace.current,
          fatal: false,
          reason: '$area/$eventKey',
        );
      } catch (_) {}
    }
    await recordHealthOnly(
      severity: 'error',
      area: area,
      eventKey: eventKey,
      message: error.toString(),
      metadata: metadata,
    );
  }

  static Future<void> recordHealthOnly({
    required String severity,
    required String area,
    required String eventKey,
    required String message,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    try {
      final info = await HpjRuntimePackageInfo.load();
      await supabase.rpc(
        'hpj_record_platform_health_event',
        params: <String, dynamic>{
          'p_severity': severity,
          'p_area': _hpjMvpClean(area, max: 80),
          'p_event_key': _hpjMvpClean(eventKey, max: 120),
          'p_message': _hpjMvpClean(message, max: 1200),
          'p_platform': _platform,
          'p_app_version': info.version,
          'p_app_build': info.build,
          'p_metadata': metadata,
        },
      );
    } catch (_) {
      // Reliability logging must never become a new failure source.
    }
  }
}

class HpjAppReleaseControl {
  final int minAndroidBuild;
  final int latestAndroidBuild;
  final bool forceLatestUpdate;
  final String updateTitle;
  final String updateMessage;
  final String playStoreUrl;
  final int snoozeHours;
  final DateTime? updatedAt;

  const HpjAppReleaseControl({
    required this.minAndroidBuild,
    required this.latestAndroidBuild,
    required this.forceLatestUpdate,
    required this.updateTitle,
    required this.updateMessage,
    required this.playStoreUrl,
    required this.snoozeHours,
    this.updatedAt,
  });

  factory HpjAppReleaseControl.fromMap(Map<String, dynamic> map) {
    return HpjAppReleaseControl(
      minAndroidBuild: _hpjMvpInt(map['min_android_build'], 1),
      latestAndroidBuild: _hpjMvpInt(map['latest_android_build'], 1),
      forceLatestUpdate: _hpjMvpBool(map['force_latest_update']),
      updateTitle: _hpjMvpClean(map['update_title']?.toString(), max: 120),
      updateMessage: _hpjMvpClean(map['update_message']?.toString(), max: 700),
      playStoreUrl: _hpjMvpClean(map['play_store_url']?.toString(), max: 300),
      snoozeHours: _hpjMvpInt(map['snooze_hours'], 12).clamp(1, 168).toInt(),
      updatedAt: _hpjMvpDate(map['updated_at']),
    );
  }

  static const fallback = HpjAppReleaseControl(
    minAndroidBuild: 1,
    latestAndroidBuild: 1,
    forceLatestUpdate: false,
    updateTitle: 'HPJ update available',
    updateMessage: 'A newer version of The Harvest Place Ja is ready with improvements and fixes.',
    playStoreUrl: 'https://play.google.com/store/apps/details?id=com.harvestplaceja.myapp',
    snoozeHours: 12,
  );
}

Future<HpjAppReleaseControl> fetchHpjPublicAppReleaseControl() async {
  try {
    final raw = await supabase.rpc('hpj_public_app_release_control');
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return HpjAppReleaseControl.fromMap(Map<String, dynamic>.from(raw.first as Map));
    }
    if (raw is Map) return HpjAppReleaseControl.fromMap(Map<String, dynamic>.from(raw));
  } catch (error) {
    farmDebugLog('Release control fallback: $error');
  }
  return HpjAppReleaseControl.fallback;
}

Future<void> updateHpjAdminAppReleaseControl(HpjAppReleaseControl value) async {
  await requireAdminAccess();
  await supabase.rpc(
    'hpj_admin_update_app_release_control',
    params: <String, dynamic>{
      'p_min_android_build': value.minAndroidBuild,
      'p_latest_android_build': value.latestAndroidBuild,
      'p_force_latest_update': value.forceLatestUpdate,
      'p_update_title': value.updateTitle,
      'p_update_message': value.updateMessage,
      'p_snooze_hours': value.snoozeHours,
    },
  );
}

class HpjAudienceSnapshot {
  final int days;
  final int visitorsToday;
  final int activeNow;
  final int visitorsPeriod;
  final int webVisitors;
  final int androidVisitors;
  final int signedInVisitors;
  final int guestVisitors;
  final int newVisitors;
  final int returningVisitors;
  final int checkoutStarts;
  final int ordersCompleted;
  final double conversionPct;
  final List<Map<String, dynamic>> appVersions;
  final List<Map<String, dynamic>> daily;

  const HpjAudienceSnapshot({
    required this.days,
    required this.visitorsToday,
    required this.activeNow,
    required this.visitorsPeriod,
    required this.webVisitors,
    required this.androidVisitors,
    required this.signedInVisitors,
    required this.guestVisitors,
    required this.newVisitors,
    required this.returningVisitors,
    required this.checkoutStarts,
    required this.ordersCompleted,
    required this.conversionPct,
    required this.appVersions,
    required this.daily,
  });

  factory HpjAudienceSnapshot.fromMap(Map<String, dynamic> map) {
    List<Map<String, dynamic>> maps(dynamic value) {
      if (value is! List) return const <Map<String, dynamic>>[];
      return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(growable: false);
    }
    return HpjAudienceSnapshot(
      days: _hpjMvpInt(map['days'], 30),
      visitorsToday: _hpjMvpInt(map['visitors_today']),
      activeNow: _hpjMvpInt(map['active_now']),
      visitorsPeriod: _hpjMvpInt(map['visitors_period']),
      webVisitors: _hpjMvpInt(map['web_visitors']),
      androidVisitors: _hpjMvpInt(map['android_visitors']),
      signedInVisitors: _hpjMvpInt(map['signed_in_visitors']),
      guestVisitors: _hpjMvpInt(map['guest_visitors']),
      newVisitors: _hpjMvpInt(map['new_visitors']),
      returningVisitors: _hpjMvpInt(map['returning_visitors']),
      checkoutStarts: _hpjMvpInt(map['checkout_starts']),
      ordersCompleted: _hpjMvpInt(map['orders_completed']),
      conversionPct: _hpjMvpDouble(map['conversion_pct']),
      appVersions: maps(map['app_versions']),
      daily: maps(map['daily']),
    );
  }
}

Future<HpjAudienceSnapshot> fetchHpjAdminAudienceSnapshot({int days = 30}) async {
  await requireAdminAccess();
  final raw = await supabase.rpc('hpj_admin_audience_snapshot', params: {'p_days': days});
  if (raw is Map) return HpjAudienceSnapshot.fromMap(Map<String, dynamic>.from(raw));
  throw Exception('Audience analytics returned an invalid response.');
}

class HpjNeedsAttentionSnapshot {
  final int paymentReviews;
  final int ordersPreparingTooLong;
  final int overdueOrders;
  final int lowStockProducts;
  final int unansweredMessages;
  final int pendingSubstitutions;
  final int platformErrors24h;
  final int total;

  const HpjNeedsAttentionSnapshot({
    required this.paymentReviews,
    required this.ordersPreparingTooLong,
    required this.overdueOrders,
    required this.lowStockProducts,
    required this.unansweredMessages,
    required this.pendingSubstitutions,
    required this.platformErrors24h,
    required this.total,
  });

  factory HpjNeedsAttentionSnapshot.fromMap(Map<String, dynamic> map) {
    return HpjNeedsAttentionSnapshot(
      paymentReviews: _hpjMvpInt(map['payment_reviews']),
      ordersPreparingTooLong: _hpjMvpInt(map['orders_preparing_too_long']),
      overdueOrders: _hpjMvpInt(map['overdue_orders']),
      lowStockProducts: _hpjMvpInt(map['low_stock_products']),
      unansweredMessages: _hpjMvpInt(map['unanswered_messages']),
      pendingSubstitutions: _hpjMvpInt(map['pending_substitutions']),
      platformErrors24h: _hpjMvpInt(map['platform_errors_24h']),
      total: _hpjMvpInt(map['total']),
    );
  }
}

Future<HpjNeedsAttentionSnapshot> fetchHpjAdminNeedsAttention() async {
  await requireAdminAccess();
  final raw = await supabase.rpc('hpj_admin_needs_attention');
  if (raw is Map) return HpjNeedsAttentionSnapshot.fromMap(Map<String, dynamic>.from(raw));
  throw Exception('Needs Attention returned an invalid response.');
}

class HpjPlatformHealthSnapshot {
  final int days;
  final int errors24h;
  final int fatals24h;
  final int eventsPeriod;
  final List<Map<String, dynamic>> recent;

  const HpjPlatformHealthSnapshot({
    required this.days,
    required this.errors24h,
    required this.fatals24h,
    required this.eventsPeriod,
    required this.recent,
  });

  factory HpjPlatformHealthSnapshot.fromMap(Map<String, dynamic> map) {
    final rawRecent = map['recent'];
    return HpjPlatformHealthSnapshot(
      days: _hpjMvpInt(map['days'], 7),
      errors24h: _hpjMvpInt(map['errors_24h']),
      fatals24h: _hpjMvpInt(map['fatals_24h']),
      eventsPeriod: _hpjMvpInt(map['events_period']),
      recent: rawRecent is List
          ? rawRecent.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(growable: false)
          : const <Map<String, dynamic>>[],
    );
  }
}

Future<HpjPlatformHealthSnapshot> fetchHpjAdminPlatformHealth({int days = 7}) async {
  await requireAdminAccess();
  final raw = await supabase.rpc('hpj_admin_platform_health_snapshot', params: {'p_days': days});
  if (raw is Map) return HpjPlatformHealthSnapshot.fromMap(Map<String, dynamic>.from(raw));
  throw Exception('Platform health returned an invalid response.');
}

class HpjOrderSubstitution {
  final String id;
  final String orderId;
  final String originalProductId;
  final String originalProductName;
  final String replacementProductId;
  final String replacementProductName;
  final int quantity;
  final double originalUnitPrice;
  final double replacementUnitPrice;
  final double originalLineTotal;
  final double replacementLineTotal;
  final double priceDifference;
  final String status;
  final String adminNote;
  final String customerNote;
  final DateTime? proposedAt;
  final DateTime? respondedAt;
  final DateTime? appliedAt;

  const HpjOrderSubstitution({
    required this.id,
    required this.orderId,
    required this.originalProductId,
    required this.originalProductName,
    required this.replacementProductId,
    required this.replacementProductName,
    required this.quantity,
    required this.originalUnitPrice,
    required this.replacementUnitPrice,
    required this.originalLineTotal,
    required this.replacementLineTotal,
    required this.priceDifference,
    required this.status,
    required this.adminNote,
    required this.customerNote,
    this.proposedAt,
    this.respondedAt,
    this.appliedAt,
  });

  bool get awaitingCustomer => status.toLowerCase() == 'proposed';
  bool get accepted => status.toLowerCase() == 'accepted';
  bool get rejected => status.toLowerCase() == 'rejected';

  factory HpjOrderSubstitution.fromMap(Map<String, dynamic> map) {
    return HpjOrderSubstitution(
      id: (map['id'] ?? '').toString(),
      orderId: (map['order_id'] ?? '').toString(),
      originalProductId: (map['original_product_id'] ?? '').toString(),
      originalProductName: (map['original_product_name'] ?? 'Original item').toString(),
      replacementProductId: (map['replacement_product_id'] ?? '').toString(),
      replacementProductName: (map['replacement_product_name'] ?? 'Replacement item').toString(),
      quantity: _hpjMvpInt(map['quantity']),
      originalUnitPrice: _hpjMvpDouble(map['original_unit_price']),
      replacementUnitPrice: _hpjMvpDouble(map['replacement_unit_price']),
      originalLineTotal: _hpjMvpDouble(map['original_line_total']),
      replacementLineTotal: _hpjMvpDouble(map['replacement_line_total']),
      priceDifference: _hpjMvpDouble(map['price_difference']),
      status: (map['status'] ?? 'proposed').toString(),
      adminNote: (map['admin_note'] ?? '').toString(),
      customerNote: (map['customer_note'] ?? '').toString(),
      proposedAt: _hpjMvpDate(map['proposed_at']),
      respondedAt: _hpjMvpDate(map['responded_at']),
      appliedAt: _hpjMvpDate(map['applied_at']),
    );
  }
}

List<HpjOrderSubstitution> _hpjSubstitutionList(dynamic raw) {
  if (raw is! List) return const <HpjOrderSubstitution>[];
  return raw.whereType<Map>().map((e) => HpjOrderSubstitution.fromMap(Map<String, dynamic>.from(e))).toList(growable: false);
}

Future<List<HpjOrderSubstitution>> fetchHpjAdminOrderSubstitutions({int limit = 100}) async {
  await requireAdminAccess();
  final raw = await supabase.rpc('hpj_admin_order_substitutions', params: {'p_limit': limit});
  return _hpjSubstitutionList(raw);
}

Future<List<HpjOrderSubstitution>> fetchHpjCustomerOrderSubstitutions(String orderId) async {
  if (!isLoggedIn) return const <HpjOrderSubstitution>[];
  final raw = await supabase.rpc('hpj_customer_order_substitutions', params: {'p_order_id': orderId});
  return _hpjSubstitutionList(raw);
}

Future<void> hpjAdminProposeOrderSubstitution({
  required String orderId,
  required String originalProductId,
  required String replacementProductId,
  String note = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'hpj_admin_propose_order_substitution',
    params: <String, dynamic>{
      'p_order_id': orderId,
      'p_original_product_id': originalProductId,
      'p_replacement_product_id': replacementProductId,
      'p_admin_note': note.trim().isEmpty ? null : note.trim(),
    },
  );
  await createOrderCustomerNotification(
    orderId: orderId,
    title: 'Fresh item replacement needs your approval',
    message: 'HPJ proposed a replacement for one item in order #${shortIdLabel(orderId)}. Open Order Details to accept or reject it.',
    type: 'order',
  );
}

Future<void> hpjCustomerRespondToSubstitution({
  required HpjOrderSubstitution substitution,
  required bool accept,
}) async {
  await supabase.rpc(
    'hpj_customer_respond_order_substitution',
    params: <String, dynamic>{
      'p_substitution_id': substitution.id,
      'p_accept': accept,
      'p_customer_note': accept ? 'Customer accepted in HPJ.' : 'Customer rejected in HPJ.',
    },
  );
  await createAdminNotification(
    title: accept ? 'Substitution accepted' : 'Substitution rejected',
    message: 'Customer ${accept ? 'accepted' : 'rejected'} the proposed replacement on order #${shortIdLabel(substitution.orderId)}.',
    type: 'admin',
    orderId: substitution.orderId,
    actionType: 'admin_customer_order',
    actionId: substitution.orderId,
    dedupeKey: 'substitution-response:${substitution.id}:${accept ? 'accepted' : 'rejected'}',
  );
}

class HpjSubstitutionOrderItemCandidate {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  const HpjSubstitutionOrderItemCandidate({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });
}

class HpjSubstitutionOrderCandidate {
  final String orderId;
  final String orderStatus;
  final String paymentStatus;
  final DateTime? createdAt;
  final List<HpjSubstitutionOrderItemCandidate> items;

  const HpjSubstitutionOrderCandidate({
    required this.orderId,
    required this.orderStatus,
    required this.paymentStatus,
    required this.createdAt,
    required this.items,
  });
}

Future<List<HpjSubstitutionOrderCandidate>> fetchHpjSubstitutionOrderCandidates() async {
  await requireAdminAccess();
  final raw = await supabase
      .from('orders')
      .select('id,order_status,payment_status,created_at,order_items(product_id,product_name,quantity,unit_price)')
      .order('created_at', ascending: false)
      .limit(80);

  final result = <HpjSubstitutionOrderCandidate>[];
  for (final row in (raw as List)) {
    final map = Map<String, dynamic>.from(row as Map);
    final status = (map['order_status'] ?? 'pending').toString().toLowerCase();
    final payment = (map['payment_status'] ?? 'unpaid').toString().toLowerCase();
    if (<String>{'cancelled', 'rejected', 'delivered', 'completed', 'collected'}.contains(status)) continue;
    if (<String>{'paid', 'verified', 'completed', 'complete'}.contains(payment)) continue;

    final items = <HpjSubstitutionOrderItemCandidate>[];
    final rawItems = map['order_items'];
    if (rawItems is List) {
      for (final item in rawItems.whereType<Map>()) {
        final m = Map<String, dynamic>.from(item);
        final id = (m['product_id'] ?? '').toString();
        if (id.isEmpty) continue;
        items.add(HpjSubstitutionOrderItemCandidate(
          productId: id,
          productName: (m['product_name'] ?? 'Product').toString(),
          quantity: _hpjMvpInt(m['quantity'], 1),
          unitPrice: _hpjMvpDouble(m['unit_price']),
        ));
      }
    }
    if (items.isEmpty) continue;
    result.add(HpjSubstitutionOrderCandidate(
      orderId: (map['id'] ?? '').toString(),
      orderStatus: status,
      paymentStatus: payment,
      createdAt: _hpjMvpDate(map['created_at']),
      items: items,
    ));
  }
  return result;
}
