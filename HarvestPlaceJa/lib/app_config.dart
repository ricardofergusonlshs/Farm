part of harvest_place_app;

class AppConfig {
  static const appName = 'The Harvest Place Ja';
  static const appVersion = '1.0.4';
  static const appBuildNumber = '25';
  static const supportPhoneDisplay = '876-339-1395';
  static const supportPhoneDial = '+18763391395';
  static const supportWhatsAppNumber = '18763391395';
  static const supportEmail =
      ''; // Add the official HPJ support email when ready.
  static const businessLocation = 'Mountainside, St. Elizabeth, Jamaica';

  // Cloudflare Turnstile CAPTCHA (public client configuration only).
  // IMPORTANT: Never put the Turnstile SECRET key in the Flutter app.
  //
  // In FlutLab, replace the empty defaultValue strings below with the
  // Turnstile SITE KEY and the HTTPS base URL/hostname you authorized in
  // Cloudflare. In CI, you can instead provide TURNSTILE_SITE_KEY and
  // TURNSTILE_BASE_URL using --dart-define.
  static const turnstileSiteKey = String.fromEnvironment(
    'TURNSTILE_SITE_KEY',
    defaultValue: '',
  );
  // Native Android/iOS uses this as the WebView origin. It must be an
  // http(s) URL whose hostname is authorized on the Cloudflare widget.
  // Flutter Web automatically uses the current browser origin instead.
  static const turnstileNativeBaseUrl = String.fromEnvironment(
    'TURNSTILE_BASE_URL',
    defaultValue: '',
  );

  static String get turnstileBaseUrl {
    if (kIsWeb) {
      final uri = Uri.base;
      return Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
        path: '/',
      ).toString();
    }
    return turnstileNativeBaseUrl.trim();
  }

  static bool get turnstileConfigured {
    final siteKey = turnstileSiteKey.trim();
    final baseUrl = turnstileBaseUrl.trim();
    if (siteKey.isEmpty || baseUrl.isEmpty) return false;

    final uri = Uri.tryParse(baseUrl);
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.trim().isNotEmpty;
  }

  // Set this after deployment to your public app link.
  // Leave empty if the current app URL should be used for invite links.
  static const publicShareUrl =
      'https://play.google.com/store/apps/details?id=com.harvestplaceja.myapp';
  static const supabaseUrl = 'https://zvgvvsgjzfygbsqwawoh.supabase.co';
  static const supabaseAnonKey =
      'sb_publishable_fBvBBFqJMlIOm1I3d5Oy-w_AbBGuJKH';

  // Auth links must go to the preview app, not the editor
  // and not localhost. Add this preview URL to Supabase Auth URL Configuration.
  // Auth links should use the current running web URL.
  // This prevents expired preview links from causing 404 errors.
  static String get webBaseUrl {
    if (!kIsWeb) return '';

    final uri = Uri.base;
    final cleanPath = uri.path.endsWith('/') ? uri.path : '${uri.path}/';

    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: cleanPath,
    ).toString();
  }

  static String get shareableAppLink {
    final liveUrl = publicShareUrl.trim();
    if (liveUrl.isNotEmpty) return liveUrl;

    final currentWebUrl = webBaseUrl.trim();
    if (currentWebUrl.isNotEmpty) return currentWebUrl;

    return appName;
  }

  // Kept for compatibility if used elsewhere in the app.
  static String get previewCompatibleBaseUrl => webBaseUrl;

  static const mobileAuthCallbackUrl = 'farm://auth-callback/';
  static const mobilePasswordResetUrl = 'farm://reset-password/';

  static Uri? _mobileAuthUri;

  static void setMobileAuthUri(Uri uri) {
    _mobileAuthUri = uri;
  }

  static Uri? get activeAuthUri {
    if (kIsWeb) return Uri.base;
    return _mobileAuthUri;
  }

  static String get passwordResetUrl => '${webBaseUrl}?resetPassword=true';

  static String get emailConfirmationUrl =>
      '${webBaseUrl}?emailConfirmation=true';

  static String? get passwordResetRedirectTo {
    if (kIsWeb) return passwordResetUrl;
    return mobilePasswordResetUrl;
  }

  static String? get emailConfirmationRedirectTo {
    if (kIsWeb) return emailConfirmationUrl;
    return mobileAuthCallbackUrl;
  }

  static Map<String, String> get authCallbackParams {
    final params = <String, String>{};
    final uri = activeAuthUri;
    if (uri == null) return params;

    void addParams(String raw) {
      var clean = raw.trim();
      if (clean.startsWith('?') || clean.startsWith('#')) {
        clean = clean.substring(1);
      }
      if (clean.isEmpty) return;
      try {
        params.addAll(Uri.splitQueryString(clean));
      } catch (_) {}
    }

    try {
      addParams(uri.query);
      addParams(uri.fragment);
    } catch (_) {}

    return params;
  }

  static Map<String, String> get passwordRecoveryParams {
    return authCallbackParams;
  }

  static String? get authCallbackCode {
    final uri = activeAuthUri;
    if (uri == null) return null;

    try {
      final queryCode = uri.queryParameters['code'];
      if (queryCode != null && queryCode.trim().isNotEmpty) {
        return queryCode.trim();
      }

      final paramsCode = authCallbackParams['code'];
      if (paramsCode != null && paramsCode.trim().isNotEmpty) {
        return paramsCode.trim();
      }

      final href = uri.toString();
      final match = RegExp(r'(?:[?#&])code=([^&#]+)').firstMatch(href);
      final rawCode = match?.group(1);
      if (rawCode == null || rawCode.trim().isEmpty) return null;
      return Uri.decodeComponent(rawCode.trim());
    } catch (_) {
      return null;
    }
  }

  static String? get passwordRecoveryCode {
    if (!_hasPasswordRecoveryMarker) return null;
    return authCallbackCode;
  }

  static String? get emailConfirmationCode {
    if (!_hasEmailConfirmationMarker) return null;
    return authCallbackCode;
  }

  static String? get passwordRecoveryAccessToken {
    if (!_hasPasswordRecoveryMarker) return null;
    final token = authCallbackParams['access_token'];
    if (token == null || token.trim().isEmpty) return null;
    return token.trim();
  }

  static String? get passwordRecoveryRefreshToken {
    if (!_hasPasswordRecoveryMarker) return null;
    final token = authCallbackParams['refresh_token'];
    if (token == null || token.trim().isEmpty) return null;
    return token.trim();
  }

  static String? get emailConfirmationAccessToken {
    if (!_hasEmailConfirmationMarker) return null;
    final token = authCallbackParams['access_token'];
    if (token == null || token.trim().isEmpty) return null;
    return token.trim();
  }

  static String? get emailConfirmationRefreshToken {
    if (!_hasEmailConfirmationMarker) return null;
    final token = authCallbackParams['refresh_token'];
    if (token == null || token.trim().isEmpty) return null;
    return token.trim();
  }

  static bool get _hasPasswordRecoveryMarker {
    final uri = activeAuthUri;
    if (uri == null) return false;

    final href = uri.toString().toLowerCase();
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    final type = (authCallbackParams['type'] ?? '').trim().toLowerCase();

    return host == 'reset-password' ||
        path.contains('reset-password') ||
        href.contains('resetpassword=true') ||
        type == 'recovery' ||
        href.contains('type=recovery');
  }

  static bool get _hasEmailConfirmationMarker {
    final uri = activeAuthUri;
    if (uri == null) return false;

    final href = uri.toString().toLowerCase();
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    final type = (authCallbackParams['type'] ?? '').trim().toLowerCase();

    return host == 'auth-callback' ||
        path.contains('auth-callback') ||
        href.contains('emailconfirmation=true') ||
        type == 'signup' ||
        type == 'email' ||
        type == 'email_change' ||
        href.contains('type=signup') ||
        href.contains('type=email') ||
        href.contains('type=email_change');
  }

  static bool get hasPasswordRecoveryCallback {
    final uri = activeAuthUri;
    if (uri == null) return false;

    // Supabase may redirect password reset links in PKCE format:
    // https://your-app/?resetPassword=true&code=...
    // It may also return access/refresh tokens in the URL hash.
    // Do not treat every code=... URL as a password reset because signup
    // confirmation links also use code=....
    return _hasPasswordRecoveryMarker &&
        (authCallbackCode != null ||
            passwordRecoveryRefreshToken != null ||
            uri.toString().toLowerCase().contains('resetpassword=true') ||
            uri.host.toLowerCase() == 'reset-password');
  }

  static bool get hasEmailConfirmationCallback {
    final uri = activeAuthUri;
    if (uri == null) return false;

    return _hasEmailConfirmationMarker &&
        (authCallbackCode != null ||
            emailConfirmationRefreshToken != null ||
            uri.toString().toLowerCase().contains('emailconfirmation=true') ||
            uri.host.toLowerCase() == 'auth-callback');
  }

  static void cleanAuthCallbackUrl() {
    if (!kIsWeb) return;

    try {
      final cleanPath = Uri.base.path.trim().isEmpty ? '/' : Uri.base.path;
      SystemNavigator.routeInformationUpdated(
        location: cleanPath,
        replace: true,
      );
    } catch (_) {}
  }

  static void cleanPasswordRecoveryUrl() {
    cleanAuthCallbackUrl();
  }
}

class AppPerformanceConfig {
  static const debounce = Duration(milliseconds: 180);
  static const realtimeDebounce = Duration(milliseconds: 650);
  static const productRailCacheExtent = 420.0;
}
