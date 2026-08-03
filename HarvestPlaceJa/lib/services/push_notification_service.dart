part of harvest_place_app;

class PushNotificationService {
  PushNotificationService._();

  static bool _started = false;

  static StreamSubscription<String>? _tokenRefreshSubscription;
  static StreamSubscription<AuthState>? _authSubscription;

  static bool get _isSupportedAndroid {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  static Future<void> initialise() async {
    if (!_isSupportedAndroid || _started) {
      return;
    }

    _started = true;

    // Register an already signed-in user.
    await _registerCurrentDevice();

    // Register again whenever a customer or staff member signs in.
    _authSubscription = supabase.auth.onAuthStateChange.listen(
      (authState) {
        if (authState.session != null) {
          unawaited(_registerCurrentDevice());
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

  static Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _authSubscription?.cancel();

    _tokenRefreshSubscription = null;
    _authSubscription = null;
    _started = false;
  }
}
