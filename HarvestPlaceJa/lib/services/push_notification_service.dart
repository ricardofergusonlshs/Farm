part of harvest_place_app;

class PushNotificationService {
  PushNotificationService._();

  static bool _started = false;
  static bool _openingNotification = false;
  static RemoteMessage? _pendingOpenedMessage;
  static String? _lastOpenedMessageKey;

  static StreamSubscription<String>? _tokenRefreshSubscription;
  static StreamSubscription<AuthState>? _authSubscription;
  static StreamSubscription<RemoteMessage>? _messageOpenedSubscription;

  static bool get _isSupportedAndroid {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  static Future<void> initialise() async {
    if (!_isSupportedAndroid || _started) {
      return;
    }

    _started = true;

    // Listen for notification taps while the app is already running in the
    // background. This must be registered once for the lifetime of the app.
    _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) {
        unawaited(_handleOpenedRemoteMessage(message));
      },
      onError: (Object error, StackTrace stackTrace) {
        farmDebugLog('Push notification tap listener failed: $error');
        farmDebugLog('$stackTrace');
      },
    );

    // If Android launched HPJ from a terminated state, Firebase gives us the
    // message here. Queue it until MaterialApp, authentication and the root
    // navigator are ready.
    try {
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _pendingOpenedMessage = initialMessage;
      }
    } catch (error, stackTrace) {
      farmDebugLog('Initial push notification lookup failed: $error');
      farmDebugLog('$stackTrace');
    }

    // Register an already signed-in user.
    await _registerCurrentDevice();

    // Register again whenever a customer or staff member signs in. If the app
    // was opened from a private notification while signed out, keep that tap
    // queued and open it only after authentication has been restored.
    _authSubscription = supabase.auth.onAuthStateChange.listen(
      (authState) {
        if (authState.session != null) {
          unawaited(_registerCurrentDevice());
          unawaited(
            Future<void>.delayed(
              const Duration(milliseconds: 650),
              flushPendingNavigation,
            ),
          );
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        farmDebugLog(
          'Push authentication listener failed: $error',
        );
        farmDebugLog('$stackTrace');
      },
    );

    // Firebase may replace a device token periodically.
    _tokenRefreshSubscription =
        FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) {
        unawaited(_saveToken(newToken));
      },
      onError: (Object error, StackTrace stackTrace) {
        farmDebugLog(
          'Push token refresh listener failed: $error',
        );
        farmDebugLog('$stackTrace');
      },
    );
  }

  static Future<void> _registerCurrentDevice() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      farmDebugLog(
        'Push registration waiting for user sign-in.',
      );
      return;
    }

    try {
      final permission = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (permission.authorizationStatus == AuthorizationStatus.denied) {
        farmDebugLog(
          'Notification permission was denied.',
        );
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();

      if (token == null || token.trim().isEmpty) {
        farmDebugLog(
          'Firebase did not return a push token.',
        );
        return;
      }

      await _saveToken(token);
    } catch (error, stackTrace) {
      farmDebugLog(
        'Push notification registration failed: $error',
      );
      farmDebugLog('$stackTrace');
    }
  }

  static Future<void> _saveToken(String token) async {
    final cleanToken = token.trim();

    if (cleanToken.isEmpty || supabase.auth.currentUser == null) {
      return;
    }

    await supabase.rpc(
      'register_push_token',
      params: {
        'p_token': cleanToken,
        'p_platform': 'android',
      },
    );

    farmDebugLog(
      'Android push token registered successfully.',
    );
  }

  // -------------------------------------------------------------------------
  // SMART NOTIFICATION TAP ROUTING
  // -------------------------------------------------------------------------

  static String _messageKey(RemoteMessage message) {
    final data = message.data;
    final id = message.messageId?.trim() ?? '';
    if (id.isNotEmpty) return id;

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

  static Future<void> _handleOpenedRemoteMessage(RemoteMessage message) async {
    final key = _messageKey(message);
    if (key.isNotEmpty && key == _lastOpenedMessageKey) return;

    _pendingOpenedMessage = message;
    await flushPendingNavigation();
  }

  /// Called by the root app after MaterialApp is mounted and again after sign
  /// in. A notification tap is never discarded merely because HPJ was still
  /// starting or restoring the user's session.
  static Future<void> flushPendingNavigation() async {
    if (_openingNotification) return;

    final message = _pendingOpenedMessage;
    if (message == null) return;

    if (!isLoggedIn || supabase.auth.currentUser == null) {
      return;
    }

    final navigator = hpjRootNavigatorKey.currentState;
    if (navigator == null || !navigator.mounted) {
      return;
    }

    _openingNotification = true;
    try {
      final notice = await _resolveRemoteNotification(message);
      if (notice == null) {
        _pendingOpenedMessage = null;
        return;
      }

      final opened = await openFarmNotification(notice);
      if (!opened) {
        final nav = hpjRootNavigatorKey.currentState;
        if (nav != null && nav.mounted) {
          unawaited(
            nav.push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsScreen(),
              ),
            ),
          );
        }
      }

      _lastOpenedMessageKey = _messageKey(message);
      _pendingOpenedMessage = null;
    } catch (error, stackTrace) {
      farmDebugLog('Notification tap routing failed: $error');
      farmDebugLog('$stackTrace');
      // Do not keep retrying a bad payload forever. The notification remains
      // available in the Updates inbox if its database row exists.
      _pendingOpenedMessage = null;
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
    }

    final actionTypeRaw = _dataValue(
      data,
      const ['action_type', 'actionType', 'route', 'screen'],
    );
    var actionType = actionTypeRaw.trim().toLowerCase();
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
            data, const ['type', 'notification_type', 'notificationType'])
        .trim()
        .toLowerCase();

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
        'wholesale_plan',
        'wholesale_order',
        'wholesale_orders',
        'wholesale_account',
      }.contains(remoteType)) {
        actionType = remoteType;
      }
    }

    // Prefer the secured database notification row. This keeps old FCM
    // senders useful even when they only send a title/body: HPJ matches the
    // tapped push to the latest private notification row and recovers its
    // action_type/action_id before navigating.
    final matched = await _matchStoredNotificationToRemoteMessage(
      message,
      actionType: actionType,
      actionId: actionId,
      orderId: orderId,
      type: remoteType,
    );
    if (matched != null) return matched;

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
      id: '',
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
            'id, title, message, type, is_read, created_at, order_id, action_type, action_id, dedupe_key',
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

  static Future<FarmNotification?> _matchStoredNotificationToRemoteMessage(
    RemoteMessage message, {
    required String actionType,
    required String actionId,
    required String orderId,
    required String type,
  }) async {
    try {
      final notices = await fetchFarmNotifications(forceRefresh: true);
      if (notices.isEmpty) return null;

      final remoteTitle = (message.notification?.title ??
              _dataValue(message.data, const ['title']))
          .trim()
          .toLowerCase();
      final remoteBody = (message.notification?.body ??
              _dataValue(message.data, const ['body', 'message']))
          .trim()
          .toLowerCase();
      final sentAt = message.sentTime;

      FarmNotification? best;
      var bestScore = -1;

      for (final notice in notices) {
        var score = 0;
        final noticeTitle = notice.title.trim().toLowerCase();
        final noticeBody = notice.message.trim().toLowerCase();
        final noticeActionType = (notice.actionType ?? '').trim().toLowerCase();
        final noticeActionId = (notice.actionId ?? '').trim();
        final noticeOrderId = (notice.orderId ?? '').trim();

        if (actionId.isNotEmpty && noticeActionId == actionId) score += 20;
        if (actionType.isNotEmpty && noticeActionType == actionType) score += 8;
        if (orderId.isNotEmpty && noticeOrderId == orderId) score += 20;
        if (type.isNotEmpty && notice.type.trim().toLowerCase() == type) {
          score += 4;
        }
        if (remoteTitle.isNotEmpty && noticeTitle == remoteTitle) score += 12;
        if (remoteBody.isNotEmpty && noticeBody == remoteBody) score += 10;

        if (sentAt != null && notice.createdAt != null) {
          var difference = notice.createdAt!.difference(sentAt);
          if (difference.isNegative) difference = -difference;
          if (difference <= const Duration(minutes: 5)) {
            score += 8;
          } else if (difference <= const Duration(hours: 1)) {
            score += 3;
          }
        }

        if (score > bestScore) {
          best = notice;
          bestScore = score;
        }
      }

      // Avoid guessing from an unrelated notification. A stored row must have
      // at least one strong matching signal.
      return bestScore >= 8 ? best : null;
    } catch (error) {
      farmDebugLog('Notification metadata recovery skipped: $error');
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

  /// Shared by Android push taps and the in-app Updates screen. Returns true
  /// when HPJ could identify and open a meaningful destination.
  static Future<bool> openFarmNotification(
    FarmNotification notice, {
    BuildContext? context,
  }) async {
    if (!isLoggedIn || supabase.auth.currentUser == null) return false;

    await _markNotificationRead(notice);

    // Orders always win because older notification rows may only have an
    // order_id and no explicit action metadata.
    if (notice.hasOrderLink ||
        (notice.actionType ?? '').trim().toLowerCase() == 'order') {
      final directOrderId = (notice.orderId ?? '').trim().isNotEmpty
          ? notice.orderId!.trim()
          : (notice.actionId ?? '').trim();
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
    }

    final actionType = (notice.actionType ?? '').trim().toLowerCase();
    final actionId = (notice.actionId ?? '').trim();

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
        return false;

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
        final account = await fetchCurrentBusinessAccount();
        if (account == null) return false;
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
        final profile = await fetchCurrentFarmerProfile();
        if (profile == null) return false;
        await _pushPage(
          FarmerDemandBoardScreen(profile: profile),
          context: context,
        );
        return true;

      case 'farmer_collection':
      case 'collection':
        final profile = await fetchCurrentFarmerProfile();
        if (profile == null) return false;
        await _pushPage(
          FarmerCollectionScheduleScreen(profile: profile),
          context: context,
        );
        return true;

      case 'farmer_supply':
        await _pushPage(
          const FarmerAccessGate(initialTab: 1),
          context: context,
        );
        return true;

      case 'farmer_payment':
      case 'farmer_payout':
        await _pushPage(
          const FarmerAccessGate(initialTab: 3),
          context: context,
        );
        return true;

      case 'wholesale_plan':
      case 'planning_ahead':
        await _pushPage(
          const BusinessWholesaleHubScreen(initialTab: 2),
          context: context,
        );
        return true;

      case 'wholesale_order':
      case 'wholesale_request':
      case 'wholesale_orders':
        await _pushPage(
          const BusinessWholesaleHubScreen(initialTab: 3),
          context: context,
        );
        return true;

      case 'wholesale_account':
        await _pushPage(
          const BusinessWholesaleHubScreen(initialTab: 4),
          context: context,
        );
        return true;
    }

    // Backward-compatible type fallbacks for notifications created before
    // action_type/action_id were added.
    switch (notice.type.trim().toLowerCase()) {
      case 'support':
        await _pushPage(const SupportScreen(), context: context);
        return true;
      case 'farmer_demand':
        final profile = await fetchCurrentFarmerProfile();
        if (profile == null) return false;
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

    _tokenRefreshSubscription = null;
    _authSubscription = null;
    _messageOpenedSubscription = null;
    _pendingOpenedMessage = null;
    _lastOpenedMessageKey = null;
    _openingNotification = false;
    _started = false;
  }
}
