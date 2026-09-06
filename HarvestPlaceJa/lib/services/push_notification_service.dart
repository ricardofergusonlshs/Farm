part of harvest_place_app;

/// HPJ Notification Repair 010 — foreground Android system notifications
///
/// Responsibilities:
/// - register/refresh Android FCM tokens
/// - receive foreground/background notification taps
/// - invoke the secure Supabase Edge Function after a notification row is saved
/// - route notification taps to the exact HPJ destination when metadata exists
class PushNotificationService {
  PushNotificationService._();

  static bool _started = false;
  static bool _openingNotification = false;
  static RemoteMessage? _pendingOpenedMessage;
  static String? _lastOpenedMessageKey;
  static int _pendingNavigationAttempts = 0;

  static StreamSubscription<String>? _tokenRefreshSubscription;
  static StreamSubscription<AuthState>? _authSubscription;
  static StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  static StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _foregroundNotificationChannel =
      AndroidNotificationChannel(
    'hpj_foreground_notifications',
    'HPJ Notifications',
    description:
        'Order, chat, delivery and account updates from The Harvest Place Ja.',
    importance: Importance.max,
    playSound: true,
  );

  static bool _localNotificationsInitialised = false;

  static bool get _isSupportedAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> initialise() async {
    if (!_isSupportedAndroid || _started) return;
    _started = true;

    try {
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
    } catch (error, stackTrace) {
      farmDebugLog('FCM auto-init setup failed: $error');
      farmDebugLog('$stackTrace');
    }

    await _ensureNotificationPermission();
    await _initialiseLocalNotifications();

    _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) {
        unawaited(_handleOpenedRemoteMessage(message));
      },
      onError: (Object error, StackTrace stackTrace) {
        farmDebugLog('Push notification tap listener failed: $error');
        farmDebugLog('$stackTrace');
      },
    );

    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
      (message) {
        unawaited(_handleForegroundRemoteMessage(message));
      },
      onError: (Object error, StackTrace stackTrace) {
        farmDebugLog('Foreground push listener failed: $error');
        farmDebugLog('$stackTrace');
      },
    );

    try {
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _pendingOpenedMessage = initialMessage;
        _pendingNavigationAttempts = 0;
      }
    } catch (error, stackTrace) {
      farmDebugLog('Initial push notification lookup failed: $error');
      farmDebugLog('$stackTrace');
    }

    await _registerCurrentDevice();

    _authSubscription = supabase.auth.onAuthStateChange.listen(
      (authState) {
        if (authState.session == null) {
          clearPendingNavigationState();
          unawaited(invalidateLocalPushToken());
          return;
        }

        unawaited(_registerCurrentDevice());
        unawaited(
          Future<void>.delayed(
            const Duration(milliseconds: 650),
            flushPendingNavigation,
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        farmDebugLog('Push authentication listener failed: $error');
        farmDebugLog('$stackTrace');
      },
    );

    _tokenRefreshSubscription =
        FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) {
        unawaited(_saveToken(newToken));
      },
      onError: (Object error, StackTrace stackTrace) {
        farmDebugLog('Push token refresh listener failed: $error');
        farmDebugLog('$stackTrace');
      },
    );
  }

  static Future<bool> _ensureNotificationPermission() async {
    try {
      final permission = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final granted =
          permission.authorizationStatus == AuthorizationStatus.authorized ||
              permission.authorizationStatus == AuthorizationStatus.provisional;

      if (!granted) {
        farmDebugLog(
          'Notification permission is not granted: '
          '${permission.authorizationStatus}.',
        );
      }
      return granted;
    } catch (error, stackTrace) {
      farmDebugLog('Notification permission request failed: $error');
      farmDebugLog('$stackTrace');
      return false;
    }
  }

  static Future<void> _initialiseLocalNotifications() async {
    if (!_isSupportedAndroid || _localNotificationsInitialised) return;

    try {
      const androidSettings = AndroidInitializationSettings(
        'ic_stat_hpj_notification',
      );

      const settings = InitializationSettings(
        android: androidSettings,
      );

      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _handleLocalNotificationResponse,
      );

      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(
        _foregroundNotificationChannel,
      );

      final launchDetails =
          await _localNotifications.getNotificationAppLaunchDetails();
      final launchResponse = launchDetails?.notificationResponse;
      if (launchDetails?.didNotificationLaunchApp == true &&
          launchResponse != null) {
        final message = _remoteMessageFromLocalPayload(launchResponse.payload);
        if (message != null) {
          _pendingOpenedMessage = message;
          _pendingNavigationAttempts = 0;
        }
      }

      _localNotificationsInitialised = true;
      farmDebugLog('Foreground Android notification channel initialised.');
    } catch (error, stackTrace) {
      farmDebugLog('Local notification setup failed: $error');
      farmDebugLog('$stackTrace');
    }
  }

  static RemoteMessage? _remoteMessageFromLocalPayload(String? payload) {
    final cleanPayload = payload?.trim() ?? '';
    if (cleanPayload.isEmpty) return null;

    try {
      final decoded = jsonDecode(cleanPayload);
      if (decoded is! Map) return null;

      final data = <String, dynamic>{};
      decoded.forEach((key, value) {
        data[key.toString()] = value?.toString() ?? '';
      });

      return RemoteMessage(
        messageId: data['local_message_id']?.toString(),
        data: data,
        sentTime: DateTime.now(),
      );
    } catch (error, stackTrace) {
      farmDebugLog('Local notification payload could not be decoded: $error');
      farmDebugLog('$stackTrace');
      return null;
    }
  }

  static void _handleLocalNotificationResponse(
    NotificationResponse response,
  ) {
    final message = _remoteMessageFromLocalPayload(response.payload);
    if (message == null) return;

    unawaited(_handleOpenedRemoteMessage(message));
  }

  static int _foregroundNotificationId(RemoteMessage message) {
    final seed = _messageKey(message);
    if (seed.isEmpty) {
      return DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
    }
    return seed.hashCode & 0x7fffffff;
  }

  static Future<void> _showForegroundSystemNotification(
    RemoteMessage message,
    String title,
    String body,
  ) async {
    if (!_localNotificationsInitialised) {
      await _initialiseLocalNotifications();
    }
    if (!_localNotificationsInitialised) return;

    final payloadData = <String, dynamic>{
      ...message.data,
      'title': title,
      'body': body,
      'local_message_id': message.messageId?.trim().isNotEmpty == true
          ? message.messageId!.trim()
          : _messageKey(message),
    };

    const androidDetails = AndroidNotificationDetails(
      'hpj_foreground_notifications',
      'HPJ Notifications',
      channelDescription:
          'Order, chat, delivery and account updates from The Harvest Place Ja.',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_stat_hpj_notification',
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _localNotifications.show(
        _foregroundNotificationId(message),
        title.isEmpty ? 'The Harvest Place Ja' : title,
        body,
        notificationDetails,
        payload: jsonEncode(payloadData),
      );
    } catch (error, stackTrace) {
      farmDebugLog('Foreground Android system notification failed: $error');
      farmDebugLog('$stackTrace');
    }
  }

  static Future<void> _registerCurrentDevice() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      farmDebugLog('Push registration waiting for user sign-in.');
      return;
    }

    try {
      if (!await _ensureNotificationPermission()) return;

      var token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.trim().isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 900));
        token = await FirebaseMessaging.instance.getToken();
      }

      if (token == null || token.trim().isEmpty) {
        farmDebugLog('Firebase did not return a push token after retry.');
        return;
      }

      await _saveToken(token);
    } catch (error, stackTrace) {
      farmDebugLog('Push notification registration failed: $error');
      farmDebugLog('$stackTrace');
    }
  }

  static Future<void> _saveToken(String token) async {
    final cleanToken = token.trim();
    if (cleanToken.isEmpty || supabase.auth.currentUser == null) return;

    try {
      await supabase.rpc(
        'register_push_token',
        params: {
          'p_token': cleanToken,
          'p_platform': 'android',
        },
      );
      farmDebugLog('Android push token registered successfully.');
    } catch (error, stackTrace) {
      farmDebugLog('Android push token registration failed: $error');
      farmDebugLog('$stackTrace');
    }
  }

  static void clearPendingNavigationState() {
    _pendingOpenedMessage = null;
    _lastOpenedMessageKey = null;
    _pendingNavigationAttempts = 0;
    _openingNotification = false;
  }

  static Future<void> invalidateLocalPushToken() async {
    if (!_isSupportedAndroid) return;

    try {
      await FirebaseMessaging.instance.deleteToken();
      farmDebugLog(
        'Local Android push token invalidated for signed-out account.',
      );
    } catch (error, stackTrace) {
      farmDebugLog(
        'Local push token invalidation skipped: $error',
      );
      farmDebugLog('$stackTrace');
    }
  }

  static Future<void> unregisterCurrentDevice() async {
    if (!_isSupportedAndroid || supabase.auth.currentUser == null) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      final cleanToken = token?.trim() ?? '';
      if (cleanToken.isEmpty) return;

      await supabase.rpc(
        'deactivate_push_token',
        params: {'p_token': cleanToken},
      );
      farmDebugLog('Android push token deactivated for this device.');
    } catch (error, stackTrace) {
      farmDebugLog('Android push token deactivation skipped: $error');
      farmDebugLog('$stackTrace');
    }
  }

  static Future<void> dispatchStoredNotificationPush({
    required String title,
    required String message,
    required String type,
    String? targetUserId,
    String? targetEmail,
    String? orderId,
    String? actionType,
    String? actionId,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final cleanUserId = targetUserId?.trim() ?? '';
    final cleanEmail = targetEmail?.trim().toLowerCase() ?? '';
    if (cleanUserId.isEmpty && cleanEmail.isEmpty) return;

    try {
      final response = await supabase.functions.invoke(
        'send-push-notification',
        body: <String, dynamic>{
          'target_user_id': cleanUserId.isEmpty ? null : cleanUserId,
          'target_email': cleanEmail.isEmpty ? null : cleanEmail,
          'title': title.trim(),
          'message': message.trim(),
          'type': type.trim(),
          'order_id': orderId?.trim(),
          'action_type': actionType?.trim(),
          'action_id': actionId?.trim(),
        },
      );

      if (response.status < 200 || response.status >= 300) {
        farmDebugLog(
          'Push Edge Function returned HTTP ${response.status}: ${response.data}',
        );
      }
    } catch (error, stackTrace) {
      farmDebugLog('Push dispatch skipped safely: $error');
      farmDebugLog('$stackTrace');
    }
  }

  static String _messageKey(RemoteMessage message) {
    final id = message.messageId?.trim() ?? '';
    if (id.isNotEmpty) return id;

    final data = message.data;
    return <String>[
      _dataValue(data, const ['notification_id', 'notificationId']),
      _dataValue(data, const ['action_type', 'actionType', 'type']),
      _dataValue(
          data, const ['action_id', 'actionId', 'entity_id', 'entityId']),
      _dataValue(data, const ['order_id', 'orderId']),
      message.notification?.title?.trim() ?? '',
      message.sentTime?.millisecondsSinceEpoch.toString() ?? '',
    ].join('|');
  }

  static String _dataValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static Future<void> _handleForegroundRemoteMessage(
    RemoteMessage message,
  ) async {
    final title = (message.notification?.title ??
            _dataValue(message.data, const ['title']))
        .trim();
    final body = (message.notification?.body ??
            _dataValue(message.data, const ['body', 'message']))
        .trim();

    if (title.isEmpty && body.isEmpty) return;

    await _showForegroundSystemNotification(
      message,
      title,
      body,
    );
  }

  static Future<void> _handleOpenedRemoteMessage(RemoteMessage message) async {
    final key = _messageKey(message);
    if (key.isNotEmpty && key == _lastOpenedMessageKey) return;

    _pendingOpenedMessage = message;
    _pendingNavigationAttempts = 0;
    await flushPendingNavigation();
  }

  static Future<void> _openNotificationsFallback() async {
    final nav = hpjRootNavigatorKey.currentState;
    if (nav == null || !nav.mounted) return;

    unawaited(
      nav.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const NotificationsScreen(),
        ),
      ),
    );
  }

  static Future<void> flushPendingNavigation() async {
    if (_openingNotification) return;

    final message = _pendingOpenedMessage;
    if (message == null) return;
    if (!isLoggedIn || supabase.auth.currentUser == null) return;

    final operationBoundary = captureHpjPrivateOperationBoundary();

    final navigator = hpjRootNavigatorKey.currentState;
    if (navigator == null || !navigator.mounted) return;

    _openingNotification = true;
    try {
      final notice = await _resolveRemoteNotification(message);

      if (!isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
        clearPendingNavigationState();
        farmDebugLog(
          'Discarded stale notification navigation after account/session change.',
        );
        return;
      }

      if (notice == null) {
        _pendingNavigationAttempts++;

        if (_pendingNavigationAttempts <= 1) {
          farmDebugLog(
            'Notification destination is not ready yet. Retrying once.',
          );
          unawaited(
            Future<void>.delayed(
              const Duration(milliseconds: 900),
              flushPendingNavigation,
            ),
          );
          return;
        }

        _pendingOpenedMessage = null;
        _pendingNavigationAttempts = 0;
        await _openNotificationsFallback();
        return;
      }

      final opened = await openFarmNotification(notice);

      if (!isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
        clearPendingNavigationState();
        return;
      }

      if (!opened) {
        await _openNotificationsFallback();
      }

      if (!isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
        clearPendingNavigationState();
        return;
      }

      _lastOpenedMessageKey = _messageKey(message);
      _pendingOpenedMessage = null;
      _pendingNavigationAttempts = 0;
    } catch (error, stackTrace) {
      if (!isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
        clearPendingNavigationState();
        return;
      }

      farmDebugLog('Notification tap routing failed: $error');
      farmDebugLog('$stackTrace');

      _pendingNavigationAttempts++;
      if (_pendingNavigationAttempts <= 1) {
        unawaited(
          Future<void>.delayed(
            const Duration(milliseconds: 900),
            flushPendingNavigation,
          ),
        );
      } else {
        _pendingOpenedMessage = null;
        _pendingNavigationAttempts = 0;
        await _openNotificationsFallback();
      }
    } finally {
      _openingNotification = false;
    }
  }

  static Future<FarmNotification?> _resolveRemoteNotification(
    RemoteMessage message,
  ) async {
    final data = message.data;

    final notificationId = _dataValue(
      data,
      const ['notification_id', 'notificationId', 'notice_id', 'noticeId'],
    );
    if (notificationId.isNotEmpty) {
      final stored = await _fetchNotificationById(notificationId);
      if (stored != null) return stored;

      // A modern HPJ push that carries notification_id represents a private
      // database notification. If this signed-in account cannot read that row,
      // never fall through to action metadata from the remote payload. This
      // prevents a notification opened for Account A from navigating Account B
      // after a sign-out/account switch. flushPendingNavigation() retries once
      // for normal database/realtime delay before falling back to Updates.
      return null;
    }

    var actionType = _dataValue(
      data,
      const ['action_type', 'actionType', 'route', 'screen'],
    ).toLowerCase();
    var actionId = _dataValue(
      data,
      const [
        'action_id',
        'actionId',
        'entity_id',
        'entityId',
        'ticket_id',
        'ticketId',
        'conversation_id',
        'conversationId',
      ],
    );

    final orderId = _dataValue(data, const ['order_id', 'orderId']);
    final productId = _dataValue(data, const ['product_id', 'productId']);
    final workspace =
        _dataValue(data, const ['workspace']).trim().toLowerCase();
    final remoteType = _dataValue(
      data,
      const ['type', 'notification_type', 'notificationType'],
    ).toLowerCase();

    if (actionType.isEmpty && orderId.isNotEmpty) {
      actionType = 'order';
      actionId = orderId;
    }

    if (actionType.isEmpty && productId.isNotEmpty) {
      actionType =
          workspace == 'wholesale' ? 'wholesale_product' : 'customer_product';
      actionId = productId;
    }

    if (actionType.isEmpty && actionId.isNotEmpty) {
      if (remoteType == 'support') {
        actionType = 'support_chat';
      } else if (const <String>{
        'support_chat',
        'admin_support_chat',
        'customer_product',
        'wholesale_product',
        'farmer_demand',
        'farmer_collection',
        'farmer_supply',
        'farmer_payment',
        'farmer_payout',
        'wholesale_plan',
        'wholesale_order',
        'wholesale_orders',
        'wholesale_account',
        'admin_inventory',
        'admin_wholesale_demand',
        'admin_wholesale_payment',
        'admin_wholesale_application',
        'admin_wholesale_order',
        'admin_customer_order',
        'admin_farmer_application',
        'admin_product_approval',
        'admin_review',
        'customer_order',
      }.contains(remoteType)) {
        actionType = remoteType;
      }
    }

    actionType = hpjCanonicalNotificationActionType(actionType);

    final title =
        (message.notification?.title ?? _dataValue(data, const ['title']))
            .trim();
    final body = (message.notification?.body ??
            _dataValue(data, const ['body', 'message']))
        .trim();

    if (title.isEmpty &&
        body.isEmpty &&
        actionType.isEmpty &&
        orderId.isEmpty) {
      return null;
    }

    return FarmNotification(
      id: notificationId,
      title: title.isEmpty ? 'HPJ update' : title,
      message: body,
      type: remoteType.isEmpty ? 'notification' : remoteType,
      isRead: false,
      createdAt: message.sentTime,
      orderId: orderId.isEmpty ? null : orderId,
      actionType: actionType.isEmpty ? null : actionType,
      actionId: actionId.isEmpty ? null : actionId,
    );
  }

  static Future<FarmNotification?> _fetchNotificationById(String id) async {
    if (id.trim().isEmpty || supabase.auth.currentUser == null) return null;

    try {
      final response = await supabase
          .from('notifications')
          .select(
            'id, title, message, type, is_read, created_at, '
            'order_id, action_type, action_id, dedupe_key',
          )
          .eq('id', id.trim())
          .maybeSingle();

      if (response == null) return null;
      return FarmNotification.fromSupabase(
        Map<String, dynamic>.from(response),
      );
    } catch (error) {
      farmDebugLog('Notification id lookup skipped: $error');
      return null;
    }
  }

  static Future<void> _markNotificationRead(FarmNotification notice) async {
    if (notice.id.trim().isEmpty) return;
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', notice.id.trim());
      FarmDataCache.notifications = null;
    } catch (error) {
      farmDebugLog('Notification read update skipped: $error');
    }
  }

  static Future<OwnerWorkspaceAccessSnapshot?>
      _notificationWorkspaceAccessSnapshot() async {
    try {
      return await fetchOwnerWorkspaceAccessSnapshot();
    } catch (error, stackTrace) {
      farmDebugLog(
        'Notification workspace-access lookup failed: $error',
      );
      farmDebugLog('$stackTrace');
      return null;
    }
  }

  static Future<bool> _hasActiveStaffNotificationAccess() async {
    try {
      return await isCurrentUserAdminFromDatabase();
    } catch (error, stackTrace) {
      farmDebugLog(
        'Notification staff-access lookup failed: $error',
      );
      farmDebugLog('$stackTrace');
      return false;
    }
  }

  static Future<void> _pushPage(
    Widget page, {
    BuildContext? context,
  }) async {
    NavigatorState? navigator;
    if (context != null && context.mounted) {
      navigator = Navigator.of(context);
    }
    navigator ??= hpjRootNavigatorKey.currentState;

    if (navigator == null || !navigator.mounted) {
      throw StateError('HPJ navigation is not ready yet.');
    }

    unawaited(
      navigator.push<void>(
        MaterialPageRoute<void>(builder: (_) => page),
      ),
    );
    await Future<void>.delayed(Duration.zero);
  }

  static Future<bool> openFarmNotification(
    FarmNotification notice, {
    BuildContext? context,
  }) async {
    if (!isLoggedIn || supabase.auth.currentUser == null) return false;

    final operationBoundary = captureHpjPrivateOperationBoundary();

    final opened = await _openFarmNotificationDestination(
      notice,
      context: context,
    );

    if (!isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
      return false;
    }

    if (opened) {
      await _markNotificationRead(notice);
    }

    if (!isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
      return false;
    }

    return opened;
  }

  static Future<bool> _openFarmNotificationDestination(
    FarmNotification notice, {
    BuildContext? context,
  }) async {
    if (!isLoggedIn || supabase.auth.currentUser == null) return false;

    final actionType = (notice.actionType ?? '').trim().toLowerCase();
    final actionId = (notice.actionId ?? '').trim();

    final staffDestination =
        actionType.startsWith('admin_') || actionType == 'staff_support_chat';

    if (staffDestination && !await _hasActiveStaffNotificationAccess()) {
      farmDebugLog(
        'Notification destination blocked because staff access is no longer active: '
        '$actionType',
      );
      return false;
    }

    switch (actionType) {
      case 'support_chat':
      case 'customer_care':
      case 'customer_care_chat':
      case 'chat':
        if (actionId.isNotEmpty) {
          final ticket = await fetchSupportTicket(actionId);
          if (ticket != null) {
            await _pushPage(
              SupportConversationScreen(ticket: ticket),
              context: context,
            );
            return true;
          }
        }
        await _pushPage(const SupportScreen(), context: context);
        return true;

      case 'admin_support_chat':
      case 'staff_support_chat':
        if (actionId.isNotEmpty) {
          final ticket = await fetchSupportTicket(actionId);
          if (ticket != null) {
            await _pushPage(
              AdminSupportConversationScreen(ticket: ticket),
              context: context,
            );
            return true;
          }
        }

        // The exact conversation may have been closed/deleted. Keep staff in
        // the correct communication area instead of falling to generic Updates.
        await _pushPage(
          const AdminDashboardScreen(
            initialSection: 'Messages',
          ),
          context: context,
        );
        return true;

      case 'customer_product':
      case 'product':
        Product? product;
        if (actionId.isNotEmpty) {
          product = await fetchProductById(actionId);
        }
        await _pushPage(
          const MainNavigation(initialIndex: 1),
          context: context,
        );
        final productName = product?.name.trim() ?? '';
        if (productName.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            mealIngredientShopSearchRequest.value = null;
            mealIngredientShopSearchRequest.value = productName;
          });
        }
        return true;

      case 'wholesale_product':
        final access = await _notificationWorkspaceAccessSnapshot();
        if (access == null) return false;

        final account = access.businessAccount;

        if (account == null ||
            !account.isApproved ||
            !access.programSettings.wholesaleWorkspaceEnabled) {
          await _pushPage(
            const BusinessWholesaleHubScreen(
              initialTab: 0,
            ),
            context: context,
          );
          return true;
        }

        Product? product;
        if (actionId.isNotEmpty) {
          product = await fetchProductById(actionId);
        }

        await _pushPage(
          WholesaleCatalogueScreen(
            account: account,
            initialSearch: product?.name.trim() ?? '',
          ),
          context: context,
        );
        return true;

      case 'farmer_demand':
      case 'buyer_demand':
        final access = await _notificationWorkspaceAccessSnapshot();
        if (access == null) return false;

        final profile = access.farmerProfile;

        if (profile == null ||
            !profile.isApproved ||
            !access.programSettings.farmerWorkspaceEnabled) {
          await _pushPage(
            const FarmerAccessGate(initialTab: 0),
            context: context,
          );
          return true;
        }

        await _pushPage(
          FarmerDemandBoardScreen(
            profile: profile,
            initialWatchKey: actionId.isEmpty ? null : actionId,
          ),
          context: context,
        );
        return true;

      case 'farmer_collection':
      case 'collection':
        final access = await _notificationWorkspaceAccessSnapshot();
        if (access == null) return false;

        final profile = access.farmerProfile;

        if (profile == null ||
            !profile.isApproved ||
            !access.programSettings.farmerWorkspaceEnabled) {
          await _pushPage(
            const FarmerAccessGate(initialTab: 0),
            context: context,
          );
          return true;
        }

        await _pushPage(
          FarmerCollectionScheduleScreen(
            profile: profile,
            initialCollectionId: actionId.isEmpty ? null : actionId,
          ),
          context: context,
        );
        return true;

      case 'farmer_supply':
        await _pushPage(
          FarmerAccessGate(
            initialTab: 1,
            initialRecordId: actionId.isEmpty ? null : actionId,
          ),
          context: context,
        );
        return true;

      case 'farmer_payment':
      case 'farmer_payout':
        await _pushPage(
          FarmerAccessGate(
            initialTab: 3,
            initialRecordId: actionId.isEmpty ? null : actionId,
          ),
          context: context,
        );
        return true;

      case 'wholesale_plan':
      case 'planning_ahead':
        await _pushPage(
          BusinessWholesaleHubScreen(
            initialTab: 2,
            initialRecordId: actionId.isEmpty ? null : actionId,
          ),
          context: context,
        );
        return true;

      case 'wholesale_order':
      case 'wholesale_request':
      case 'wholesale_orders':
        await _pushPage(
          BusinessWholesaleHubScreen(
            initialTab: 3,
            initialRecordId: actionId.isEmpty ? null : actionId,
          ),
          context: context,
        );
        return true;

      case 'wholesale_account':
        await _pushPage(
          const BusinessWholesaleHubScreen(initialTab: 4),
          context: context,
        );
        return true;

      case 'admin_customer_order':
        final linkedOrderId = (notice.orderId ?? '').trim();
        final adminOrderId = actionId.isNotEmpty ? actionId : linkedOrderId;
        await _pushPage(
          AdminDashboardScreen(
            initialSection: 'Orders',
            initialSubSection: 'customer',
            initialRecordId: adminOrderId.isEmpty ? null : adminOrderId,
          ),
          context: context,
        );
        return true;

      case 'admin_farmer_application':
        await _pushPage(
          AdminDashboardScreen(
            initialSection: 'Farmers',
            initialRecordId: actionId.isEmpty ? null : actionId,
          ),
          context: context,
        );
        return true;

      case 'admin_product_approval':
        await _pushPage(
          AdminDashboardScreen(
            initialSection: 'Products',
            initialRecordId: actionId.isEmpty ? null : actionId,
          ),
          context: context,
        );
        return true;

      case 'admin_review':
        await _pushPage(
          AdminDashboardScreen(
            initialSection: 'Reviews',
            initialRecordId: actionId.isEmpty ? null : actionId,
          ),
          context: context,
        );
        return true;

      case 'admin_inventory':
        await _pushPage(
          AdminDashboardScreen(
            initialSection: 'Products',
            initialRecordId: actionId.isEmpty ? null : actionId,
          ),
          context: context,
        );
        return true;

      case 'admin_wholesale_demand':
        await _pushPage(
          AdminDashboardScreen(
            initialSection: 'Procurement',
            initialSubSection: 'needs_supply',
            initialRecordId: actionId.isEmpty ? null : actionId,
          ),
          context: context,
        );
        return true;

      case 'admin_wholesale_payment':
        await _pushPage(
          AdminDashboardScreen(
            initialSection: 'Business Setup',
            initialSubSection: 'invoices',
            initialRecordId: actionId.isEmpty ? null : actionId,
          ),
          context: context,
        );
        return true;

      case 'admin_wholesale_application':
        await _pushPage(
          AdminDashboardScreen(
            initialSection: 'Business Setup',
            initialSubSection: 'applications',
            initialRecordId: actionId.isEmpty ? null : actionId,
          ),
          context: context,
        );
        return true;

      case 'admin_wholesale_order':
        await _pushPage(
          AdminDashboardScreen(
            initialSection: 'Orders',
            initialSubSection: 'wholesale',
            initialRecordId: actionId.isEmpty ? null : actionId,
          ),
          context: context,
        );
        return true;

      case 'order':
      case 'customer_order':
        final directOrderId = (notice.orderId ?? '').trim().isNotEmpty
            ? notice.orderId!.trim()
            : actionId;
        final orderId = directOrderId.isNotEmpty
            ? directOrderId
            : await findOrderIdForNotification(notice);
        if (orderId != null && orderId.trim().isNotEmpty) {
          await _pushPage(
            OrderDetailsScreen(orderId: orderId.trim()),
            context: context,
          );
          return true;
        }

        // A stale/missing order target should still land in My Orders rather
        // than the generic Updates screen.
        await _pushPage(
          const MainNavigation(initialIndex: 3),
          context: context,
        );
        return true;
    }

    if (actionType.isEmpty && notice.hasOrderLink) {
      final orderId = (notice.orderId ?? '').trim().isNotEmpty
          ? notice.orderId!.trim()
          : await findOrderIdForNotification(notice);
      if (orderId != null && orderId.trim().isNotEmpty) {
        await _pushPage(
          OrderDetailsScreen(orderId: orderId.trim()),
          context: context,
        );
        return true;
      }

      await _pushPage(
        const MainNavigation(initialIndex: 3),
        context: context,
      );
      return true;
    }

    switch (notice.type.trim().toLowerCase()) {
      case 'support':
        await _pushPage(const SupportScreen(), context: context);
        return true;
      case 'farmer_demand':
        final access = await _notificationWorkspaceAccessSnapshot();
        if (access == null) return false;

        final profile = access.farmerProfile;

        if (profile == null ||
            !profile.isApproved ||
            !access.programSettings.farmerWorkspaceEnabled) {
          await _pushPage(
            const FarmerAccessGate(initialTab: 0),
            context: context,
          );
          return true;
        }

        await _pushPage(
          FarmerDemandBoardScreen(profile: profile),
          context: context,
        );
        return true;
      case 'wholesale':
        await _pushPage(
          const BusinessWholesaleHubScreen(initialTab: 0),
          context: context,
        );
        return true;
      case 'watch':
      case 'price_drop':
      case 'product_ready':
      case 'stock':
        await _pushPage(
          const MainNavigation(initialIndex: 1),
          context: context,
        );
        return true;
      case 'order':
      case 'payment':
      case 'delivery':
        await _pushPage(
          const MainNavigation(initialIndex: 3),
          context: context,
        );
        return true;
      default:
        return false;
    }
  }

  static Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _authSubscription?.cancel();
    await _messageOpenedSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();

    _tokenRefreshSubscription = null;
    _authSubscription = null;
    _messageOpenedSubscription = null;
    _foregroundMessageSubscription = null;
    _pendingOpenedMessage = null;
    _lastOpenedMessageKey = null;
    _pendingNavigationAttempts = 0;
    _openingNotification = false;
    _localNotificationsInitialised = false;
    _started = false;
  }
}
