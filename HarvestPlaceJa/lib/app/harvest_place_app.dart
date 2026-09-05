part of harvest_place_app;

// Root navigator used by Android push-notification taps. Keeping one app-level
// key lets HPJ open the exact secured destination even when the notification
// launches the app from a terminated state.
final GlobalKey<NavigatorState> hpjRootNavigatorKey =
    GlobalKey<NavigatorState>();

// =====================================================
// HPJ HELP & TUTORIALS
// Repair 030
//
// Tutorial content is managed from Admin and stored in Supabase. Public
// entry screens only display a tutorial action when a matching tutorial is
// published, so HPJ never shows a dead "Watch" button.
// =====================================================

const Map<String, String> hpjHelpTutorialPlacementLabels = <String, String>{
  'signup': 'Sign Up',
  'workspaces': 'Workspaces',
  'customer': 'Customer Shopping',
  'farmer': 'Farmer Partner',
  'wholesale': 'Wholesale Business',
  'orders': 'Orders & Tracking',
  'general': 'General Help',
};

const Map<String, String> hpjHelpTutorialAudienceLabels = <String, String>{
  'all': 'Everyone',
  'customer': 'Customers',
  'farmer': 'Farmers',
  'wholesale': 'Wholesale',
  'staff': 'Staff',
};

class HpjHelpTutorial {
  final String id;
  final String title;
  final String buttonLabel;
  final String description;
  final String videoUrl;
  final String? thumbnailUrl;
  final String placement;
  final String audience;
  final bool isPublished;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HpjHelpTutorial({
    required this.id,
    required this.title,
    required this.buttonLabel,
    required this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.placement,
    required this.audience,
    required this.isPublished,
    required this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory HpjHelpTutorial.fromSupabase(Map<String, dynamic> data) {
    int parseSortOrder(Object? value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 100;
    }

    DateTime? parseDate(Object? value) {
      final raw = value?.toString().trim() ?? '';
      if (raw.isEmpty) return null;
      return DateTime.tryParse(raw)?.toLocal();
    }

    final rawThumbnail = data['thumbnail_url']?.toString().trim() ?? '';

    return HpjHelpTutorial(
      id: (data['id'] ?? '').toString(),
      title: (data['title'] ?? '').toString().trim(),
      buttonLabel:
          (data['button_label'] ?? 'Watch quick guide').toString().trim(),
      description: (data['description'] ?? '').toString().trim(),
      videoUrl: (data['video_url'] ?? '').toString().trim(),
      thumbnailUrl: rawThumbnail.isEmpty ? null : rawThumbnail,
      placement:
          (data['placement'] ?? 'general').toString().trim().toLowerCase(),
      audience: (data['audience'] ?? 'all').toString().trim().toLowerCase(),
      isPublished: data['is_published'] == true,
      sortOrder: parseSortOrder(data['sort_order']),
      createdAt: parseDate(data['created_at']),
      updatedAt: parseDate(data['updated_at']),
    );
  }

  String get placementLabel =>
      hpjHelpTutorialPlacementLabels[placement] ?? 'General Help';

  String get audienceLabel =>
      hpjHelpTutorialAudienceLabels[audience] ?? 'Everyone';
}

bool _isSafeHelpTutorialUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || uri.host.trim().isEmpty) return false;
  return uri.scheme.toLowerCase() == 'https' ||
      uri.scheme.toLowerCase() == 'http';
}

Future<List<HpjHelpTutorial>> fetchPublishedHelpTutorials({
  required String placement,
  String audience = 'all',
}) async {
  final cleanPlacement = placement.trim().toLowerCase();
  final cleanAudience = audience.trim().toLowerCase();

  if (!hpjHelpTutorialPlacementLabels.containsKey(cleanPlacement)) {
    return const <HpjHelpTutorial>[];
  }

  try {
    final response = await supabase
        .from('help_tutorials')
        .select(
          'id, title, button_label, description, video_url, thumbnail_url, placement, audience, is_published, sort_order, created_at, updated_at',
        )
        .eq('placement', cleanPlacement)
        .eq('is_published', true)
        .order('sort_order', ascending: true)
        .order('updated_at', ascending: false)
        .limit(20);

    final tutorials = (response as List)
        .map(
          (item) => HpjHelpTutorial.fromSupabase(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .where(
          (tutorial) =>
              tutorial.videoUrl.isNotEmpty &&
              _isSafeHelpTutorialUrl(tutorial.videoUrl) &&
              (cleanAudience == 'all' ||
                  tutorial.audience == 'all' ||
                  tutorial.audience == cleanAudience),
        )
        .toList();

    return tutorials;
  } catch (error) {
    // The app remains clean before Repair 030 SQL is installed and whenever
    // tutorial content is temporarily unavailable.
    farmDebugLog('Published help tutorial lookup skipped: $error');
    return const <HpjHelpTutorial>[];
  }
}

Future<HpjHelpTutorial?> fetchPublishedHelpTutorial({
  required String placement,
  String audience = 'all',
}) async {
  final tutorials = await fetchPublishedHelpTutorials(
    placement: placement,
    audience: audience,
  );
  return tutorials.isEmpty ? null : tutorials.first;
}

Future<void> openHpjHelpTutorial(
  BuildContext context,
  HpjHelpTutorial tutorial,
) async {
  final videoUrl = tutorial.videoUrl.trim();

  if (!_isSafeHelpTutorialUrl(videoUrl)) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This tutorial video link is not available yet.'),
      ),
    );
    return;
  }

  final opened = await openExternalShareUrl(videoUrl);

  if (!context.mounted || opened) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Could not open the tutorial video. Please check your connection and try again.',
      ),
    ),
  );
}

class FamilyFarmApp extends StatelessWidget {
  const FamilyFarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(PushNotificationService.flushPendingNavigation());
    });

    return MaterialApp(
      navigatorKey: hpjRootNavigatorKey,
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _syncKeyboardStateSafely(),
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: FarmColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: FarmColors.primary,
          primary: FarmColors.primary,
          secondary: FarmColors.accent,
          surface: FarmColors.card,
          background: FarmColors.background,
          brightness: Brightness.light,
        ).copyWith(
          onPrimary: Colors.white,
          onSecondary: FarmColors.ink,
          onSurface: FarmColors.ink,
        ),
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        cardTheme: CardThemeData(
          color: FarmColors.card,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: FarmColors.line, width: 1.05),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: FarmColors.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: FarmColors.background,
          foregroundColor: FarmColors.ink,
          iconTheme: IconThemeData(color: FarmColors.ink),
          actionsIconTheme: IconThemeData(color: FarmColors.ink),
          titleTextStyle: TextStyle(
            color: FarmColors.ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: FarmColors.card,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          labelStyle: const TextStyle(color: FarmColors.muted),
          hintStyle: const TextStyle(color: FarmColors.muted),
          prefixIconColor: FarmColors.primary,
          suffixIconColor: FarmColors.muted,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: FarmColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: FarmColors.primary, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: FarmColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: FarmColors.error, width: 1.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: FarmColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: FarmColors.line,
            disabledForegroundColor: FarmColors.muted,
            elevation: 0,
            shadowColor: FarmColors.primary.withOpacity(0.22),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.1,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: FarmColors.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: FarmColors.primary,
            side: BorderSide(color: FarmColors.primary.withOpacity(0.45)),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: FarmColors.surface,
          selectedColor: FarmColors.chipBackground,
          secondarySelectedColor: FarmColors.chipBackground,
          disabledColor: FarmColors.line,
          labelStyle: const TextStyle(color: FarmColors.ink),
          secondaryLabelStyle: const TextStyle(color: FarmColors.green),
          brightness: Brightness.light,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: const BorderSide(color: FarmColors.line),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 72,
          backgroundColor: FarmColors.surface,
          elevation: 0,
          indicatorColor: FarmColors.primarySoft,
          labelTextStyle: MaterialStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11.5,
              fontWeight: states.contains(MaterialState.selected)
                  ? FontWeight.w900
                  : FontWeight.w700,
              color: states.contains(MaterialState.selected)
                  ? FarmColors.green
                  : FarmColors.muted,
            ),
          ),
          iconTheme: MaterialStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(MaterialState.selected)
                  ? FarmColors.green
                  : FarmColors.muted,
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: FarmColors.deepGreen,
          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<OwnerWorkspaceAccessSnapshot>? _workspaceAccessFuture;
  Future<HpjNavigationPreference?>? _navigationPreferenceFuture;

  // Supabase auth links open the same Flutter web app page. The app must
  // route password-reset links and signup confirmation links internally.
  bool hasEnteredMarket = AppConfig.hasPasswordRecoveryCallback ||
      AppConfig.hasEmailConfirmationCallback ||
      AppConfig.hasGoogleOAuthCallback ||
      isLoggedIn;

  // Signed-in users resume their remembered safe workspace/tab. If no
  // navigation preference exists yet, HPJ treats this as first workspace entry
  // and opens the Workspaces selector. Staff/Admin is never an automatic
  // startup destination.
  bool shouldChooseWorkspace = isLoggedIn &&
      !AppConfig.hasPasswordRecoveryCallback &&
      !AppConfig.hasEmailConfirmationCallback &&
      !AppConfig.hasGoogleOAuthCallback;

  bool isPasswordRecovery = AppConfig.hasPasswordRecoveryCallback;
  bool isEmailConfirmation = AppConfig.hasEmailConfirmationCallback;
  bool isGoogleOAuthCallback = AppConfig.hasGoogleOAuthCallback;
  String? passwordRecoveryError;
  String? emailConfirmationError;
  String? googleOAuthError;
  String? emailConfirmationMessage;
  late final StreamSubscription<AuthState> _authSubscription;
  String? _authUserId;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _authUserId = supabase.auth.currentUser?.id.trim();

    if (shouldChooseWorkspace) {
      _workspaceAccessFuture = fetchOwnerWorkspaceAccessSnapshot();
      _navigationPreferenceFuture = fetchHpjNavigationPreference();
    }

    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;

      final rawUserId = data.session?.user.id.trim() ?? '';
      final nextUserId = rawUserId.isEmpty ? null : rawUserId;
      final identityChanged = nextUserId != _authUserId;

      if (identityChanged) {
        _authUserId = nextUserId;
        clearHpjPrivateAccountMemory();

        if (nextUserId == null) {
          setState(() {
            _workspaceAccessFuture = null;
            _navigationPreferenceFuture = null;
            shouldChooseWorkspace = false;
            hasEnteredMarket = false;
          });
        } else {
          setState(() {
            hasEnteredMarket = true;
            shouldChooseWorkspace = !isPasswordRecovery &&
                !isEmailConfirmation &&
                !isGoogleOAuthCallback;
            _workspaceAccessFuture = fetchOwnerWorkspaceAccessSnapshot();
            _navigationPreferenceFuture = fetchHpjNavigationPreference();
          });
        }
      }

      if (data.event == AuthChangeEvent.passwordRecovery) {
        setState(() {
          isPasswordRecovery = true;
          isEmailConfirmation = false;
          hasEnteredMarket = true;
          shouldChooseWorkspace = false;
          passwordRecoveryError = null;
        });
        return;
      }

      if (!identityChanged) {
        setState(() {});
      }
    });

    unawaited(_initDeepLinks());

    if (AppConfig.hasPasswordRecoveryCallback) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          isPasswordRecovery = true;
          isEmailConfirmation = false;
          hasEnteredMarket = true;
          shouldChooseWorkspace = false;
          passwordRecoveryError = null;
        });
      });
    }

    if (AppConfig.hasGoogleOAuthCallback) {
      unawaited(_prepareGoogleOAuthSession());
    } else if (AppConfig.hasEmailConfirmationCallback) {
      unawaited(_prepareEmailConfirmationSession());
    }
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    if (kIsWeb) return;

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingAuthLink(initialUri);
      }

      _deepLinkSubscription = _appLinks.uriLinkStream.listen(
        _handleIncomingAuthLink,
        onError: (error) {
          farmDebugLog('Deep link error: $error');
        },
      );
    } catch (error) {
      farmDebugLog('Deep link init skipped: $error');
    }
  }

  void _handleIncomingAuthLink(Uri uri) {
    AppConfig.setMobileAuthUri(uri);

    if (AppConfig.hasPasswordRecoveryCallback) {
      if (!mounted) return;
      setState(() {
        isPasswordRecovery = true;
        isEmailConfirmation = false;
        hasEnteredMarket = true;
        shouldChooseWorkspace = false;
        passwordRecoveryError = null;
      });
      return;
    }

    if (AppConfig.hasGoogleOAuthCallback) {
      unawaited(_prepareGoogleOAuthSession());
      return;
    }

    if (AppConfig.hasEmailConfirmationCallback) {
      unawaited(_prepareEmailConfirmationSession());
    }
  }

  Future<void> _prepareGoogleOAuthSession() async {
    if (!AppConfig.hasGoogleOAuthCallback) return;

    if (mounted) {
      setState(() {
        isGoogleOAuthCallback = true;
        isEmailConfirmation = false;
        isPasswordRecovery = false;
        hasEnteredMarket = true;
        shouldChooseWorkspace = false;
        googleOAuthError = null;
      });
    }

    try {
      final code = AppConfig.googleOAuthCode;

      // supabase_flutter normally completes the PKCE exchange automatically.
      // This fallback covers Android/deep-link timing where the callback arrives
      // before the SDK has established the session.
      if (supabase.auth.currentSession == null &&
          code != null &&
          code.isNotEmpty) {
        await supabase.auth.exchangeCodeForSession(code);
      }

      if (supabase.auth.currentSession == null) {
        throw Exception(
          'Google sign-in returned to HPJ but no session was created.',
        );
      }

      FarmDataCache.clearAll();
      AppConfig.cleanAuthCallbackUrl();

      if (!mounted) return;
      setState(() {
        isGoogleOAuthCallback = false;
        hasEnteredMarket = true;
        shouldChooseWorkspace = true;
        _workspaceAccessFuture = fetchOwnerWorkspaceAccessSnapshot();
        _navigationPreferenceFuture = fetchHpjNavigationPreference();
        googleOAuthError = null;
      });
    } catch (error) {
      AppConfig.cleanAuthCallbackUrl();

      if (!mounted) return;
      setState(() {
        isGoogleOAuthCallback = false;
        hasEnteredMarket = false;
        shouldChooseWorkspace = false;
        googleOAuthError = friendlyAppError(error);
      });
    }
  }

  Future<void> _prepareEmailConfirmationSession() async {
    if (!AppConfig.hasEmailConfirmationCallback) return;

    if (mounted) {
      setState(() {
        isEmailConfirmation = true;
        isPasswordRecovery = false;
        hasEnteredMarket = true;
        shouldChooseWorkspace = false;
        emailConfirmationError = null;
        emailConfirmationMessage = null;
      });
    }

    try {
      final code = AppConfig.emailConfirmationCode;
      final refreshToken = AppConfig.emailConfirmationRefreshToken;
      final accessToken = AppConfig.emailConfirmationAccessToken;
      final currentSession = supabase.auth.currentSession;

      if (code != null && code.isNotEmpty) {
        await supabase.auth.exchangeCodeForSession(code);
      } else if (refreshToken != null && refreshToken.isNotEmpty) {
        if (accessToken != null && accessToken.isNotEmpty) {
          await supabase.auth.setSession(
            refreshToken,
            accessToken: accessToken,
          );
        } else {
          await supabase.auth.setSession(refreshToken);
        }
      } else if (currentSession == null) {
        throw Exception(
          'Open the newest email confirmation link. This link is missing the confirmation code.',
        );
      }

      FarmDataCache.clearAll();
      AppConfig.cleanAuthCallbackUrl();

      if (!mounted) return;
      setState(() {
        isEmailConfirmation = false;
        hasEnteredMarket = true;
        shouldChooseWorkspace = true;
        _workspaceAccessFuture = fetchOwnerWorkspaceAccessSnapshot();
        _navigationPreferenceFuture = fetchHpjNavigationPreference();
        emailConfirmationError = null;
        emailConfirmationMessage =
            'Email confirmed. Welcome to The Harvest Place Ja.';
      });
    } catch (error) {
      AppConfig.cleanAuthCallbackUrl();

      if (!mounted) return;
      setState(() {
        isEmailConfirmation = false;
        hasEnteredMarket = false;
        shouldChooseWorkspace = false;
        emailConfirmationError = friendlyAppError(error);
      });
    }
  }

  Future<void> openAuth({bool createAccount = false}) async {
    final didSignIn = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          returnToPrevious: true,
          startInRegister: createAccount,
        ),
      ),
    );

    if (!mounted) return;
    if (didSignIn == true || isLoggedIn) {
      setState(() {
        hasEnteredMarket = true;
        shouldChooseWorkspace = true;
        _workspaceAccessFuture = fetchOwnerWorkspaceAccessSnapshot();
        _navigationPreferenceFuture = fetchHpjNavigationPreference();
      });
    }
  }

  Widget _preferredSignedInScreen(
    OwnerWorkspaceAccessSnapshot access,
    HpjNavigationPreference? preference,
  ) {
    if (preference != null) {
      switch (preference.lastWorkspace) {
        case 'farmer':
          if (access.isApprovedFarmer &&
              access.programSettings.farmerWorkspaceEnabled) {
            return FarmerAccessGate(
              initialTab: preference.farmerTab,
            );
          }
          break;

        case 'wholesale':
          if (access.isApprovedWholesale &&
              access.programSettings.wholesaleWorkspaceEnabled) {
            return BusinessWholesaleHubScreen(
              initialTab: preference.wholesaleTab,
            );
          }
          break;

        case 'customer':
          if (access.programSettings.customerMarketplaceEnabled) {
            return MainNavigation(
              initialIndex: preference.customerTab,
            );
          }
          break;

        default:
          break;
      }

      // A remembered destination may have been approved yesterday and paused,
      // rejected, or revoked today. Do not keep reopening a stale workspace.
      // Let the signed-in user choose from the access that is active now.
      return const OwnerWorkspaceSwitcherScreen(
        showCloseButton: false,
      );
    }

    // First workspace entry: do not guess where a new account should land.
    // Show the shared Workspaces screen so the user can see Customer, Farmer,
    // Wholesale and Staff access in one place. The first explicit selection is
    // then remembered for future sign-ins/restarts.
    return const OwnerWorkspaceSwitcherScreen(
      showCloseButton: false,
    );
  }

  Widget _routeSignedInUser() {
    final accessFuture =
        _workspaceAccessFuture ??= fetchOwnerWorkspaceAccessSnapshot();
    final preferenceFuture =
        _navigationPreferenceFuture ??= fetchHpjNavigationPreference();

    return FutureBuilder<OwnerWorkspaceAccessSnapshot>(
      future: accessFuture,
      builder: (context, accessSnapshot) {
        if (accessSnapshot.connectionState == ConnectionState.waiting &&
            accessSnapshot.data == null) {
          return const _SmartEntryLoadingView();
        }

        final access = accessSnapshot.data;

        // If access lookup fails, do not silently send the user into the wrong
        // workspace. Keep them at the shared selector where access can be
        // refreshed or they can sign out safely.
        if (access == null) {
          return const OwnerWorkspaceSwitcherScreen(
            showCloseButton: false,
          );
        }

        return FutureBuilder<HpjNavigationPreference?>(
          future: preferenceFuture,
          builder: (context, preferenceSnapshot) {
            if (preferenceSnapshot.connectionState == ConnectionState.waiting &&
                !preferenceSnapshot.hasData) {
              return const _SmartEntryLoadingView();
            }

            return _preferredSignedInScreen(
              access,
              preferenceSnapshot.data,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isGoogleOAuthCallback) {
      return const _SmartEntryLoadingView();
    }

    if (isEmailConfirmation) {
      return const EmailConfirmationProgressScreen();
    }

    // This is the important fix: the password reset URL is not a separate
    // physical web page. When the URL contains resetPassword=true, code=..., or
    // recovery tokens, show UpdatePasswordScreen before the splash/landing page.
    if (AppConfig.hasPasswordRecoveryCallback || isPasswordRecovery) {
      return UpdatePasswordScreen(
        onPasswordUpdated: () {
          AppConfig.cleanPasswordRecoveryUrl();
          if (!mounted) return;
          setState(() {
            isPasswordRecovery = false;
            hasEnteredMarket = true;
            shouldChooseWorkspace = isLoggedIn;
            _workspaceAccessFuture =
                isLoggedIn ? fetchOwnerWorkspaceAccessSnapshot() : null;
            _navigationPreferenceFuture =
                isLoggedIn ? fetchHpjNavigationPreference() : null;
          });
        },
      );
    }

    if (emailConfirmationMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || emailConfirmationMessage == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(emailConfirmationMessage!)),
        );
        emailConfirmationMessage = null;
      });
    }

    if (emailConfirmationError != null && !hasEnteredMarket) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || emailConfirmationError == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Email confirmation error: $emailConfirmationError')),
        );
        emailConfirmationError = null;
      });
    }

    if (googleOAuthError != null && !hasEnteredMarket) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || googleOAuthError == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in error: $googleOAuthError')),
        );
        googleOAuthError = null;
      });
    }

    if (passwordRecoveryError != null && !hasEnteredMarket) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || passwordRecoveryError == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset link error: $passwordRecoveryError')),
        );
        passwordRecoveryError = null;
      });
    }

    // Phase 050A — one-click Google launch from FlutLab preview.
    // The embedded preview cannot complete Google OAuth safely, so the Google
    // button opens this same HPJ build in a normal browser tab with a short-lived
    // launch marker. That tab comes straight to LoginScreen and starts OAuth.
    final externalGoogleLaunch = kIsWeb &&
        !AppConfig.hasGoogleOAuthCallback &&
        Uri.base.queryParameters['googleExternal'] == '1' &&
        Uri.base.queryParameters['auth'] == 'google';

    if (!hasEnteredMarket && externalGoogleLaunch) {
      return const LoginScreen();
    }

    // The welcome page is only the first splash screen. Once the user enters
    // the market, stay in the market even if auth later becomes null.
    if (!hasEnteredMarket) {
      return PublicLandingScreen(
        onEnterWorkspaces: () {
          unawaited(openAuth());
        },
        onCreateAccount: () {
          unawaited(openAuth(createAccount: true));
        },
      );
    }

    if (isLoggedIn && shouldChooseWorkspace) {
      return _routeSignedInUser();
    }

    return const MainNavigation();
  }
}

class _SmartEntryLoadingView extends StatelessWidget {
  const _SmartEntryLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: FarmColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Opening HPJ…',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PostLoginWorkspaceSelector extends StatefulWidget {
  final VoidCallback? onCustomerSelected;

  const PostLoginWorkspaceSelector({
    super.key,
    this.onCustomerSelected,
  });

  @override
  State<PostLoginWorkspaceSelector> createState() =>
      _PostLoginWorkspaceSelectorState();
}

class _PostLoginWorkspaceSelectorState
    extends State<PostLoginWorkspaceSelector> {
  late Future<OwnerWorkspaceAccessSnapshot> _future;

  static const String _customerPhoto =
      'https://images.unsplash.com/photo-1775825772432-58a1a31dcf40'
      '?auto=format&fit=crop&w=1200&q=84';

  static const String _wholesalePhoto =
      'https://images.unsplash.com/photo-1769355104335-acef3aa4c9b6'
      '?auto=format&fit=crop&w=1200&q=84';

  static const String _farmerPhoto =
      'https://images.unsplash.com/photo-1767590954924-9ff1057b9f65'
      '?auto=format&fit=crop&w=1200&q=84';

  static const String _staffPhoto =
      'https://images.unsplash.com/photo-1770992225308-154250075727'
      '?auto=format&fit=crop&w=1200&q=84';

  @override
  void initState() {
    super.initState();
    _future = fetchOwnerWorkspaceAccessSnapshot();
  }

  Future<void> _reload() async {
    final next = fetchOwnerWorkspaceAccessSnapshot();

    if (mounted) {
      setState(() {
        _future = next;
      });
    }

    await next;
  }

  void _open(Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => screen,
      ),
      (route) => false,
    );
  }

  void _openUtility(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => screen,
      ),
    );
  }

  Future<void> _signOut() async {
    await signOutFromHpjSession();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const AuthGate(),
      ),
      (route) => false,
    );
  }

  void _openCustomerWorkspace() {
    final callback = widget.onCustomerSelected;

    if (callback != null) {
      callback();
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const MainNavigation(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const pageBackground = Color(0xFFF8F6F1);

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: FutureBuilder<OwnerWorkspaceAccessSnapshot>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                snapshot.data == null) {
              return const _WorkspaceLoadingView();
            }

            if (snapshot.hasError || snapshot.data == null) {
              return _WorkspaceLoadErrorView(
                onRetry: _reload,
                onCustomerSelected: _openCustomerWorkspace,
                onSignOut: _signOut,
              );
            }

            final access = snapshot.data!;
            final business = access.businessAccount;
            final farmer = access.farmerProfile;
            final settings = access.programSettings;
            final staffRole = normalizeStaffRole(
              access.staffRole,
            );
            final hasStaffAccess = isStaffRoleActive(
              staffRole,
            );

            final businessStatus = business == null
                ? settings.wholesaleApplicationsEnabled
                    ? 'Apply'
                    : 'Paused'
                : business.isApproved
                    ? settings.wholesaleWorkspaceEnabled
                        ? ''
                        : 'Paused'
                    : businessAccountStatusLabel(
                        business.status,
                      );

            final businessStatusColor =
                business == null && !settings.wholesaleApplicationsEnabled
                    ? const Color(0xFF78817D)
                    : businessAccountStatusColor(
                        business?.status,
                      );

            final farmerStatus = farmer == null
                ? settings.farmerApplicationsEnabled
                    ? 'Apply'
                    : 'Paused'
                : farmer.isApproved
                    ? settings.farmerWorkspaceEnabled
                        ? ''
                        : 'Paused'
                    : farmer.statusLabel;

            final farmerStatusColor =
                farmer == null && !settings.farmerApplicationsEnabled
                    ? const Color(0xFF78817D)
                    : FarmColors.warning;

            return RefreshIndicator(
              onRefresh: _reload,
              color: const Color(0xFF0B4C36),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth >= 760;
                  final horizontal = isTablet ? 34.0 : 18.0;
                  final maxContentWidth =
                      constraints.maxWidth > 900 ? 760.0 : constraints.maxWidth;

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      14,
                      horizontal,
                      30,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxContentWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ReferenceWorkspaceTopBar(
                                onSignOut: _signOut,
                                onOpenTrust: () => _openUtility(
                                  const TrustCenterScreen(),
                                ),
                                onOpenAbout: () => _openUtility(
                                  const AboutHpjScreen(),
                                ),
                                onOpenSupport: () => _openUtility(
                                  const SupportScreen(
                                    initialSubject: 'Account help',
                                  ),
                                ),
                                onOpenNotifications: () => _openUtility(
                                  const NotificationsScreen(),
                                ),
                              ),
                              const SizedBox(height: 28),
                              const Text(
                                'Choose your workspace',
                                style: TextStyle(
                                  color: Color(0xFF073F2C),
                                  fontSize: 31,
                                  height: 1.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'One account. Switch anytime.',
                                style: TextStyle(
                                  color: Color(0xFF747C78),
                                  fontSize: 15,
                                  height: 1.25,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 22),
                              _ReferenceWorkspacePhotoGrid(
                                children: [
                                  _ReferenceWorkspacePhotoCard(
                                    photoUrl: _customerPhoto,
                                    title: 'Customer Shopping',
                                    status: settings.customerMarketplaceEnabled
                                        ? 'Current'
                                        : 'Coming Soon',
                                    statusColor:
                                        settings.customerMarketplaceEnabled
                                            ? const Color(0xFF0B4C36)
                                            : const Color(0xFF78817D),
                                    highlighted:
                                        settings.customerMarketplaceEnabled,
                                    showCheck:
                                        settings.customerMarketplaceEnabled,
                                    onTap: _openCustomerWorkspace,
                                  ),
                                  _ReferenceWorkspacePhotoCard(
                                    photoUrl: _wholesalePhoto,
                                    title: 'Wholesale Business',
                                    status: businessStatus,
                                    statusColor: businessStatusColor,
                                    onTap: () => _open(
                                      const BusinessWholesaleHubScreen(),
                                    ),
                                  ),
                                  _ReferenceWorkspacePhotoCard(
                                    photoUrl: _farmerPhoto,
                                    title: 'Farmer Partner',
                                    status: farmerStatus,
                                    statusColor: farmerStatusColor,
                                    onTap: () => _open(
                                      const FarmerAccessGate(),
                                    ),
                                  ),
                                  if (hasStaffAccess)
                                    _ReferenceWorkspacePhotoCard(
                                      photoUrl: _staffPhoto,
                                      title: 'HPJ Staff & Operations',
                                      status: '',
                                      statusColor: const Color(0xFF0B4C36),
                                      onTap: () => _open(
                                        const AdminDashboardScreen(),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const _ReferenceOneAccountCard(),
                              const SizedBox(height: 18),
                              const _ReferenceWorkspaceLegalFooter(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReferenceWorkspaceTopBar extends StatelessWidget {
  final Future<void> Function() onSignOut;
  final VoidCallback onOpenTrust;
  final VoidCallback onOpenAbout;
  final VoidCallback onOpenSupport;
  final VoidCallback onOpenNotifications;

  const _ReferenceWorkspaceTopBar({
    required this.onSignOut,
    required this.onOpenTrust,
    required this.onOpenAbout,
    required this.onOpenSupport,
    required this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF073F2C);

    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFFE5E1D8),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF173B30).withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Image.asset(
            'lib/assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.eco_outlined,
              color: forest,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'Workspaces',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: forest,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
        ),
        _ReferenceHeaderIcon(
          tooltip: 'Notifications',
          icon: Icons.notifications_none_rounded,
          onTap: onOpenNotifications,
        ),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          tooltip: 'Menu',
          color: const Color(0xFFFFFEFC),
          elevation: 12,
          constraints: const BoxConstraints(
            minWidth: 270,
            maxWidth: 310,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          position: PopupMenuPosition.under,
          onSelected: (value) {
            switch (value) {
              case 'trust':
                onOpenTrust();
                break;
              case 'about':
                onOpenAbout();
                break;
              case 'support':
                onOpenSupport();
                break;
              case 'sign_out':
                onSignOut();
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem<String>(
              value: 'trust',
              height: 66,
              child: _ReferenceMenuItem(
                icon: Icons.shield_outlined,
                label: 'Trust & Security',
              ),
            ),
            PopupMenuDivider(height: 1),
            PopupMenuItem<String>(
              value: 'about',
              height: 66,
              child: _ReferenceMenuItem(
                icon: Icons.info_outline_rounded,
                label: 'About The Harvest Place Ja',
              ),
            ),
            PopupMenuDivider(height: 1),
            PopupMenuItem<String>(
              value: 'support',
              height: 66,
              child: _ReferenceMenuItem(
                icon: Icons.support_agent_rounded,
                label: 'Help & Support',
              ),
            ),
            PopupMenuDivider(height: 1),
            PopupMenuItem<String>(
              value: 'sign_out',
              height: 66,
              child: _ReferenceMenuItem(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                destructive: true,
              ),
            ),
          ],
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.menu_rounded,
              color: forest,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReferenceHeaderIcon extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _ReferenceHeaderIcon({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: Icon(
        icon,
        color: const Color(0xFF073F2C),
        size: 25,
      ),
    );
  }
}

class _ReferenceMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool destructive;

  const _ReferenceMenuItem({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? const Color(0xFFD92D20) : const Color(0xFF073F2C);

    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReferenceWorkspacePhotoGrid extends StatelessWidget {
  final List<Widget> children;

  const _ReferenceWorkspacePhotoGrid({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final oneColumn = constraints.maxWidth < 300;
        final gap = oneColumn ? 12.0 : 14.0;
        final width =
            oneColumn ? constraints.maxWidth : (constraints.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: 14,
          children: children
              .map(
                (child) => SizedBox(
                  width: width,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ReferenceWorkspacePhotoCard extends StatelessWidget {
  final String photoUrl;
  final String title;
  final String status;
  final Color statusColor;
  final bool highlighted;
  final bool showCheck;
  final VoidCallback onTap;

  const _ReferenceWorkspacePhotoCard({
    required this.photoUrl,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.onTap,
    this.highlighted = false,
    this.showCheck = false,
  });

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF073F2C);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 165;
        final cardHeight = compact ? 270.0 : 292.0;
        final photoHeight = compact ? 184.0 : 202.0;

        return Semantics(
          button: true,
          label: [
            title,
            if (status.trim().isNotEmpty) status.trim(),
          ].join('. '),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(23),
              onTap: onTap,
              child: Container(
                height: cardHeight,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFEFC),
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(
                    color: highlighted ? forest : const Color(0xFFE4E0D8),
                    width: highlighted ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF173B30).withOpacity(
                        highlighted ? 0.11 : 0.075,
                      ),
                      blurRadius: highlighted ? 22 : 17,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: photoHeight,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            filterQuality: FilterQuality.medium,
                            loadingBuilder: (
                              context,
                              child,
                              progress,
                            ) {
                              if (progress == null) {
                                return child;
                              }

                              return const ColoredBox(
                                color: Color(0xFFE8EFEA),
                              );
                            },
                            errorBuilder: (_, __, ___) {
                              return const ColoredBox(
                                color: Color(0xFFE8EFEA),
                                child: Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: forest,
                                    size: 34,
                                  ),
                                ),
                              );
                            },
                          ),
                          if (status.trim().isNotEmpty)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.96),
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.09),
                                      blurRadius: 9,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  status,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 12 : 15,
                          13,
                          compact ? 10 : 13,
                          13,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: forest,
                                  fontSize: compact ? 14.4 : 16.0,
                                  height: 1.06,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            if (showCheck) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE9F3E9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: forest,
                                  size: 24,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReferenceOneAccountCard extends StatelessWidget {
  const _ReferenceOneAccountCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 17,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5EE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD7E1D4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFDDECDD),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: Color(0xFF073F2C),
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'One HPJ account',
                  style: TextStyle(
                    color: Color(0xFF073F2C),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Your access stays connected.',
                  style: TextStyle(
                    color: Color(0xFF6C7671),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceWorkspaceLegalFooter extends StatelessWidget {
  const _ReferenceWorkspaceLegalFooter();

  void _open(
    BuildContext context,
    Widget screen,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => screen,
      ),
    );
  }

  Widget _link(
    BuildContext context,
    String label,
    Widget screen,
  ) {
    return Expanded(
      child: TextButton(
        onPressed: () => _open(
          context,
          screen,
        ),
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(
            horizontal: 2,
            vertical: 5,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF073F2C),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _link(
              context,
              'Terms',
              const TermsOfServiceScreen(),
            ),
            const _ReferenceFooterDivider(),
            _link(
              context,
              'Privacy',
              const PrivacyPolicyScreen(),
            ),
            const _ReferenceFooterDivider(),
            _link(
              context,
              'Refunds',
              const RefundPolicyScreen(),
            ),
            const _ReferenceFooterDivider(),
            _link(
              context,
              'FAQ',
              const HpjFaqScreen(),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          '${AppConfig.appName} • v${AppConfig.appVersion}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF9A9F9B),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ReferenceFooterDivider extends StatelessWidget {
  const _ReferenceFooterDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 23,
      color: const Color(0xFFD8DDD8),
    );
  }
}

class _WorkspaceLoadingView extends StatelessWidget {
  const _WorkspaceLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text(
              'Preparing your workspaces...',
              style: TextStyle(
                color: FarmColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceLoadErrorView extends StatelessWidget {
  final Future<void> Function() onRetry;
  final VoidCallback onCustomerSelected;
  final Future<void> Function() onSignOut;

  const _WorkspaceLoadErrorView({
    required this.onRetry,
    required this.onCustomerSelected,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(22),
      children: [
        const SizedBox(height: 28),
        const Icon(
          Icons.hub_outlined,
          size: 54,
          color: FarmColors.green,
        ),
        const SizedBox(height: 14),
        const Text(
          'Your workspace list needs a refresh',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: FarmColors.ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'HPJ could not verify all workspace access right now. '
          'You can retry, open Customer Shopping so it can check its own '
          'availability, or sign out safely.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: FarmColors.mutedText,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 22),
        PrimaryFarmButton(
          label: 'Open Customer Shopping',
          onPressed: onCustomerSelected,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(
            Icons.refresh_rounded,
          ),
          label: const Text(
            'Try Again',
          ),
        ),
        TextButton.icon(
          onPressed: onSignOut,
          icon: const Icon(
            Icons.logout_rounded,
          ),
          label: const Text(
            'Sign Out',
          ),
        ),
      ],
    );
  }
}

class EmailConfirmationProgressScreen extends StatelessWidget {
  const EmailConfirmationProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      body: SafeArea(
        child: Center(
          child: FarmCard(
            margin: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 18),
                const Text(
                  'Confirming your email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we finish setting up your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: FarmColors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PublicLandingScreen extends StatefulWidget {
  final VoidCallback onEnterWorkspaces;
  final VoidCallback onCreateAccount;

  const PublicLandingScreen({
    super.key,
    required this.onEnterWorkspaces,
    required this.onCreateAccount,
  });

  @override
  State<PublicLandingScreen> createState() => _PublicLandingScreenState();
}

class _PublicLandingScreenState extends State<PublicLandingScreen> {
  late final Future<String?> _welcomeBackgroundFuture;
  late final Future<List<HomeHeroSlide>> _legacyLandingBackgroundFuture;

  static const Color _forest = Color(0xFF083D2A);
  static const Color _lime = Color(0xFF9EDB45);
  static const Color _gold = Color(0xFFF0AF2A);

  @override
  void initState() {
    super.initState();

    // Keep the dedicated Admin-managed Welcome Screen Background.
    // Home Hero slide 1 is used only as a backward-compatible fallback.
    _welcomeBackgroundFuture = fetchPublicWelcomeBackgroundUrl();
    _legacyLandingBackgroundFuture = fetchPublicHomeHeroSlides();
  }

  Widget _backgroundFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF8AA17E),
            Color(0xFF365C43),
            Color(0xFF0A2E20),
          ],
        ),
      ),
      child: Align(
        alignment: const Alignment(0.45, -0.05),
        child: Icon(
          Icons.eco_rounded,
          size: 230,
          color: Colors.white.withOpacity(0.035),
        ),
      ),
    );
  }

  Widget _networkLandingBackground(String imageUrl) {
    return Image.network(
      imageUrl,
      key: ValueKey<String>('hpj-welcome-background-$imageUrl'),
      fit: BoxFit.cover,
      alignment: const Alignment(0.08, 0),
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => _backgroundFallback(),
      loadingBuilder: (
        context,
        child,
        progress,
      ) {
        if (progress == null) return child;

        return Stack(
          fit: StackFit.expand,
          children: [
            _backgroundFallback(),
            child,
          ],
        );
      },
    );
  }

  Widget _legacyHomeHeroBackground() {
    return FutureBuilder<List<HomeHeroSlide>>(
      future: _legacyLandingBackgroundFuture,
      builder: (context, snapshot) {
        final slides = snapshot.data ?? const <HomeHeroSlide>[];

        for (final slide in slides) {
          final clean = cleanHostedImageUrl(slide.imageUrl);
          if (clean != null && clean.isNotEmpty) {
            return _networkLandingBackground(clean);
          }
        }

        return _backgroundFallback();
      },
    );
  }

  Widget _landingBackground() {
    return FutureBuilder<String?>(
      future: _welcomeBackgroundFuture,
      builder: (context, snapshot) {
        final welcomeUrl = cleanHostedImageUrl(snapshot.data);

        if (welcomeUrl != null && welcomeUrl.isNotEmpty) {
          return _networkLandingBackground(welcomeUrl);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _backgroundFallback();
        }

        return _legacyHomeHeroBackground();
      },
    );
  }

  void _openUtility(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => screen,
      ),
    );
  }

  Widget _logoMedallion({
    required bool compact,
  }) {
    final size = compact ? 88.0 : 102.0;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(compact ? 9 : 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.95),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Image.asset(
        'lib/assets/images/logo.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.eco_outlined,
          size: 46,
          color: _forest,
        ),
      ),
    );
  }

  Widget _workspaceButton({
    required bool compact,
  }) {
    return SizedBox(
      width: double.infinity,
      height: compact ? 58 : 64,
      child: FilledButton(
        onPressed: widget.onEnterWorkspaces,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.98),
          foregroundColor: _forest,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 18 : 22,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 18 : 21),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.grid_view_rounded,
              size: 23,
            ),
            SizedBox(width: compact ? 14 : 17),
            Expanded(
              child: Text(
                'Choose Your Workspace',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 16.0 : 17.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.35,
                ),
              ),
            ),
            SizedBox(width: compact ? 8 : 12),
            const Icon(
              Icons.chevron_right_rounded,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _createAccountButton({
    required bool compact,
  }) {
    return SizedBox(
      width: double.infinity,
      height: compact ? 56 : 62,
      child: OutlinedButton(
        onPressed: widget.onCreateAccount,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF06281C).withOpacity(0.34),
          side: BorderSide(
            color: Colors.white.withOpacity(0.95),
            width: 1.7,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 18 : 22,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 18 : 21),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_rounded,
              color: _lime,
              size: 29,
            ),
            const SizedBox(width: 14),
            Text(
              'Create an Account',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 16.0 : 17.0,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _signInLink() {
    return TextButton(
      onPressed: widget.onEnterWorkspaces,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 3,
        ),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Already registered? ',
              style: TextStyle(
                color: Colors.white.withOpacity(0.94),
                fontWeight: FontWeight.w600,
              ),
            ),
            const TextSpan(
              text: 'Sign in',
              style: TextStyle(
                color: _lime,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13.2,
          height: 1.15,
        ),
      ),
    );
  }

  Widget _utilityItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: _lime,
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _utilityDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.22),
    );
  }

  Widget _utilityRow() {
    return Row(
      children: [
        _utilityItem(
          icon: Icons.info_outline_rounded,
          label: 'About',
          onTap: () => _openUtility(
            const AboutHpjScreen(),
          ),
        ),
        _utilityDivider(),
        _utilityItem(
          icon: Icons.shield_outlined,
          label: 'Trust',
          onTap: () => _openUtility(
            const TrustCenterScreen(),
          ),
        ),
        _utilityDivider(),
        _utilityItem(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Support',
          onTap: () => _openUtility(
            const SupportScreen(
              initialSubject: 'Account help',
            ),
          ),
        ),
      ],
    );
  }

  Widget _legalItem({
    required IconData icon,
    required String label,
    required Widget screen,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => _openUtility(screen),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 2,
            vertical: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white.withOpacity(0.92),
                size: 20,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legalDivider() {
    return Container(
      width: 1,
      height: 35,
      color: Colors.white.withOpacity(0.18),
    );
  }

  Widget _legalRow() {
    return Row(
      children: [
        _legalItem(
          icon: Icons.description_outlined,
          label: 'Terms',
          screen: const TermsOfServiceScreen(),
        ),
        _legalDivider(),
        _legalItem(
          icon: Icons.lock_outline_rounded,
          label: 'Privacy',
          screen: const PrivacyPolicyScreen(),
        ),
        _legalDivider(),
        _legalItem(
          icon: Icons.currency_exchange_rounded,
          label: 'Refunds',
          screen: const RefundPolicyScreen(),
        ),
        _legalDivider(),
        _legalItem(
          icon: Icons.help_outline_rounded,
          label: 'FAQ',
          screen: const HpjFaqScreen(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compact = media.size.height < 760 || media.size.width < 355;
    final veryCompact = media.size.height < 650;
    final bottomInset = media.viewPadding.bottom;

    final horizontalPadding = compact ? 18.0 : 24.0;
    final contentMaxWidth = compact ? 420.0 : 455.0;

    return Scaffold(
      backgroundColor: const Color(0xFF06281C),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _landingBackground(),
          ),

          // Preserve the photograph at the top and gradually darken only the
          // lower half so buttons and footer stay readable on any Admin image.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [
                    0.00,
                    0.22,
                    0.43,
                    0.62,
                    0.78,
                    1.00,
                  ],
                  colors: [
                    Colors.black.withOpacity(0.03),
                    Colors.black.withOpacity(0.05),
                    const Color(0xFF06281C).withOpacity(0.16),
                    const Color(0xFF06281C).withOpacity(0.44),
                    const Color(0xFF041D14).withOpacity(0.72),
                    const Color(0xFF03160F).withOpacity(0.93),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight - bottomInset;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    compact ? 18 : 24,
                    horizontalPadding,
                    10 + bottomInset,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: availableHeight - 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: contentMaxWidth,
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: veryCompact
                                  ? 12
                                  : compact
                                      ? 24
                                      : 34,
                            ),
                            _logoMedallion(
                              compact: compact,
                            ),
                            SizedBox(
                              height: compact ? 14 : 18,
                            ),
                            Text(
                              'The Harvest Place Ja',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: compact ? 26 : 30,
                                height: 1.02,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.9,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x66000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text.rich(
                              const TextSpan(
                                children: [
                                  TextSpan(text: 'Fresh'),
                                  TextSpan(
                                    text: '  •  ',
                                    style: TextStyle(
                                      color: _gold,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  TextSpan(text: 'Local'),
                                  TextSpan(
                                    text: '  •  ',
                                    style: TextStyle(
                                      color: _gold,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  TextSpan(text: 'Jamaican'),
                                ],
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: compact ? 13.5 : 14.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.05,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x55000000),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: veryCompact
                                  ? 32
                                  : compact
                                      ? 46
                                      : 70,
                            ),
                            Text(
                              'Fresh Jamaican agriculture.\nOne connected marketplace.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: compact ? 24 : 28,
                                height: 1.10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.85,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x77000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: compact ? 12 : 15,
                            ),
                            Text(
                              'Buy fresh produce, sell your harvest, or\nmanage wholesale purchasing.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.94),
                                fontSize: compact ? 13.5 : 14.8,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x77000000),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: veryCompact
                                  ? 28
                                  : compact
                                      ? 40
                                      : 62,
                            ),
                            _workspaceButton(
                              compact: compact,
                            ),
                            const SizedBox(height: 12),
                            _createAccountButton(
                              compact: compact,
                            ),
                            const SizedBox(height: 8),
                            _signInLink(),
                            SizedBox(
                              height: compact ? 14 : 22,
                            ),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.fromLTRB(
                                compact ? 8 : 12,
                                compact ? 4 : 7,
                                compact ? 8 : 12,
                                compact ? 7 : 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF06281C).withOpacity(0.48),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Column(
                                children: [
                                  _utilityRow(),
                                  Container(
                                    height: 1,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    color: Colors.white.withOpacity(0.15),
                                  ),
                                  _legalRow(),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: compact ? 2 : 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingPolicyLink extends StatelessWidget {
  final String label;
  final WidgetBuilder builder;

  const _LandingPolicyLink({
    required this.label,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withOpacity(0.78),
        padding: const EdgeInsets.symmetric(
          horizontal: 3,
          vertical: 3,
        ),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(
          fontSize: 10.4,
          fontWeight: FontWeight.w700,
        ),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: builder,
          ),
        );
      },
      child: Text(label),
    );
  }
}

class _HpjTurnstilePanel extends StatelessWidget {
  final TurnstileController controller;
  final String action;
  final ValueChanged<String?> onTokenChanged;

  const _HpjTurnstilePanel({
    required this.controller,
    required this.action,
    required this.onTokenChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.turnstileConfigured) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: 'Security check',
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FarmColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: FarmColors.primary,
                  size: 19,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Security check',
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: CloudflareTurnstile(
                siteKey: AppConfig.turnstileSiteKey,
                baseUrl: AppConfig.turnstileBaseUrl,
                action: action,
                controller: controller,
                options: TurnstileOptions(
                  size: TurnstileSize.flexible,
                  theme: TurnstileTheme.light,
                  language: 'en',
                  retryAutomatically: true,
                  refreshExpired: TurnstileRefreshExpired.auto,
                  refreshTimeout: TurnstileRefreshTimeout.auto,
                ),
                onTokenReceived: (token) => onTokenChanged(token),
                onTokenExpired: () => onTokenChanged(null),
                onError: (error) {
                  farmDebugLog('Turnstile error: ${error.message}');
                  onTokenChanged(null);
                },
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'HPJ uses a privacy-friendly security check to block automated abuse.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FarmColors.mutedText,
                fontSize: 10.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController emailController;
  final TurnstileController _captchaController = TurnstileController();
  bool loading = false;
  String? _captchaToken;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.initialEmail.trim());
  }

  @override
  void dispose() {
    _captchaController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _refreshCaptcha() async {
    if (!AppConfig.turnstileConfigured) return;
    if (mounted) setState(() => _captchaToken = null);
    try {
      await _captchaController.refreshToken();
    } catch (error) {
      farmDebugLog('Turnstile refresh failed: $error');
    }
  }

  Future<void> sendResetLink() async {
    final email = emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address.')),
      );
      return;
    }

    if (AppConfig.turnstileConfigured &&
        (_captchaToken == null || _captchaToken!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the security check first.'),
        ),
      );
      return;
    }

    var resetSent = false;
    setState(() => loading = true);
    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: AppConfig.passwordResetRedirectTo,
        captchaToken:
            AppConfig.turnstileConfigured ? _captchaToken?.trim() : null,
      );
      resetSent = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password reset link sent to $email. Open the newest email, then create your new password.',
          ),
        ),
      );
      Navigator.pop(context);
    } on AuthException catch (error) {
      if (!mounted) return;
      farmDebugLog('Password reset auth error: ${error.message}');
      final lower = error.message.toLowerCase();
      final message = lower.contains('captcha') || lower.contains('challenge')
          ? 'The security check expired or could not be verified. Please try again.'
          : lower.contains('rate limit') || lower.contains('too many')
              ? 'Too many reset attempts. Please wait a few minutes and try again.'
              : 'Could not send the reset link. Please check the email and try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) return;
      farmDebugLog('Password reset failed: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send the reset link. Please try again.'),
        ),
      );
    } finally {
      if (!resetSent && mounted) {
        await _refreshCaptcha();
      }
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 14),
            const HeroCard(),
            const SizedBox(height: 26),
            const Text(
              'Reset your password',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your email and we will send a secure password reset link.',
              style: TextStyle(color: FarmColors.mutedText, fontSize: 15),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email address',
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (AppConfig.turnstileConfigured) ...[
              _HpjTurnstilePanel(
                controller: _captchaController,
                action: 'hpj_password_reset',
                onTokenChanged: (token) {
                  if (!mounted) return;
                  setState(() => _captchaToken = token);
                },
              ),
              const SizedBox(height: 18),
            ] else ...[
              const SizedBox(height: 4),
            ],
            PrimaryFarmButton(
              label: loading ? 'Sending reset link...' : 'Send reset link',
              onPressed: loading ||
                      (AppConfig.turnstileConfigured &&
                          (_captchaToken == null || _captchaToken!.isEmpty))
                  ? null
                  : sendResetLink,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(context),
              child: const Text('Back to login'),
            ),
          ],
        ),
      ),
    );
  }
}

class GuestSignInPrompt extends StatelessWidget {
  final String title;
  final String message;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onLogin;
  final VoidCallback onCreateAccount;
  final VoidCallback onContinueBrowsing;

  const GuestSignInPrompt({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onLogin,
    required this.onCreateAccount,
    required this.onContinueBrowsing,
  });

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_outline,
            color: FarmColors.green,
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: FarmColors.mutedText, height: 1.35),
          ),
          const SizedBox(height: 18),
          PrimaryFarmButton(label: primaryLabel, onPressed: onLogin),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: Text(secondaryLabel),
            onPressed: onCreateAccount,
          ),
          TextButton(
            onPressed: onContinueBrowsing,
            child: const Text('Continue browsing'),
          ),
        ],
      ),
    );
  }
}

class GuestProtectedScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String message;
  final IconData icon;

  const GuestProtectedScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.message,
    this.icon = Icons.lock_outline,
  });

  @override
  State<GuestProtectedScreen> createState() => _GuestProtectedScreenState();
}

class _GuestProtectedScreenState extends State<GuestProtectedScreen> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = supabase.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _openLogin({bool createAccount = false}) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          returnToPrevious: true,
          startInRegister: createAccount,
        ),
      ),
    );

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FarmPage(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Header(title: widget.title, subtitle: widget.subtitle),
          const SizedBox(height: 18),
          GuestSignInPrompt(
            title: widget.title,
            message: widget.message,
            primaryLabel: 'Log in',
            secondaryLabel: 'Create account',
            onLogin: () => _openLogin(),
            onCreateAccount: () => _openLogin(createAccount: true),
            onContinueBrowsing: () {
              Navigator.maybePop(context);
            },
          ),
        ],
      ),
    );
  }
}

class UpdatePasswordScreen extends StatefulWidget {
  final VoidCallback onPasswordUpdated;

  const UpdatePasswordScreen({
    super.key,
    required this.onPasswordUpdated,
  });

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool loading = false;
  bool hidePassword = true;
  bool preparingRecoverySession = AppConfig.hasPasswordRecoveryCallback;
  bool recoverySessionReady = !AppConfig.hasPasswordRecoveryCallback;
  String? recoverySessionError;

  @override
  void initState() {
    super.initState();
    unawaited(_prepareRecoverySession());
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _prepareRecoverySession() async {
    if (!AppConfig.hasPasswordRecoveryCallback) {
      if (!mounted) return;
      setState(() {
        preparingRecoverySession = false;
        recoverySessionReady = true;
        recoverySessionError = null;
      });
      return;
    }

    if (mounted) {
      setState(() {
        preparingRecoverySession = true;
        recoverySessionError = null;
      });
    }

    try {
      final code = AppConfig.passwordRecoveryCode;
      final refreshToken = AppConfig.passwordRecoveryRefreshToken;
      final accessToken = AppConfig.passwordRecoveryAccessToken;
      final currentSession = supabase.auth.currentSession;

      if (code != null && code.isNotEmpty) {
        await supabase.auth.exchangeCodeForSession(code);
      } else if (refreshToken != null && refreshToken.isNotEmpty) {
        if (accessToken != null && accessToken.isNotEmpty) {
          await supabase.auth.setSession(
            refreshToken,
            accessToken: accessToken,
          );
        } else {
          await supabase.auth.setSession(refreshToken);
        }
      } else if (currentSession == null) {
        throw Exception(
          'Open the newest password reset email link to continue. This page needs a valid reset link before the password can be changed.',
        );
      }

      if (!mounted) return;
      setState(() {
        preparingRecoverySession = false;
        recoverySessionReady = true;
        recoverySessionError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        preparingRecoverySession = false;
        recoverySessionReady = false;
        recoverySessionError = friendlyAppError(error);
      });
    }
  }

  void _leavePasswordScreen() {
    if (AppConfig.hasPasswordRecoveryCallback) {
      AppConfig.cleanPasswordRecoveryUrl();
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> updatePassword() async {
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a password with at least 6 characters.'),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    if (!recoverySessionReady) {
      await _prepareRecoverySession();
      if (!mounted) return;
      if (!recoverySessionReady) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              recoverySessionError ??
                  'Open the newest password reset email link and try again.',
            ),
          ),
        );
        return;
      }
    }

    setState(() => loading = true);

    try {
      await supabase.auth.updateUser(
        UserAttributes(password: password),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );

      AppConfig.cleanPasswordRecoveryUrl();
      widget.onPasswordUpdated();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Could not update password: ${friendlyAppError(error)}')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: loading ? null : _leavePasswordScreen,
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(
                  AppConfig.hasPasswordRecoveryCallback
                      ? 'Back to Sign In'
                      : 'Back to Settings',
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Image.asset(
                'lib/assets/images/logo.png',
                height: 88,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.eco_outlined,
                  size: 64,
                  color: FarmColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Create New Password',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: FarmColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a new password for your account at The Harvest Place Ja.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FarmColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (preparingRecoverySession) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 10),
              Text(
                'Verifying your reset link...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: FarmColors.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (recoverySessionError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: FarmColors.dangerSoft,
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: FarmColors.danger.withOpacity(0.25)),
                ),
                child: Text(
                  recoverySessionError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: FarmColors.danger,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FarmCard(
              child: Column(
                children: [
                  TextField(
                    controller: passwordController,
                    obscureText: hidePassword,
                    decoration: InputDecoration(
                      labelText: 'New password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => hidePassword = !hidePassword);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: hidePassword,
                    decoration: const InputDecoration(
                      labelText: 'Confirm new password',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryFarmButton(
                    label: loading ? 'Updating...' : 'Update Password',
                    icon: Icons.check_circle_outline,
                    onPressed: loading ? null : updatePassword,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'If your reset link says it expired, request a new reset email and open the newest link only once.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FarmColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// HPJ — JAMAICA PARISH SELECTOR
// One canonical list for signup, Farmer, Wholesale and address forms.
// Keep this in one part file only; all `part of harvest_place_app` files
// can reuse JamaicaParishDropdown because they share the same library.
// ================================================================

const List<String> jamaicaParishes = <String>[
  'Clarendon',
  'Hanover',
  'Kingston',
  'Manchester',
  'Portland',
  'St. Andrew',
  'St. Ann',
  'St. Catherine',
  'St. Elizabeth',
  'St. James',
  'St. Mary',
  'St. Thomas',
  'Trelawny',
  'Westmoreland',
];

String? normalizeJamaicaParish(String? value) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) return null;

  String key(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll('saint', 'st')
        .replaceAll('.', '')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  final wanted = key(raw);

  for (final parish in jamaicaParishes) {
    if (key(parish) == wanted) return parish;
  }

  return null;
}

String requireJamaicaParish(
  String? value, {
  String fieldLabel = 'Parish',
}) {
  final normalized = normalizeJamaicaParish(value);

  if (normalized == null) {
    throw Exception(
      '$fieldLabel must be one of Jamaica\'s 14 parishes.',
    );
  }

  return normalized;
}

String? normalizeOptionalJamaicaParish(
  String? value, {
  String fieldLabel = 'Parish',
}) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) return null;

  final normalized = normalizeJamaicaParish(raw);
  if (normalized == null) {
    throw Exception(
      '$fieldLabel must be one of Jamaica\'s 14 parishes.',
    );
  }

  return normalized;
}

class JamaicaParishDropdown extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final IconData prefixIcon;
  final ValueChanged<String?>? onChanged;

  const JamaicaParishDropdown({
    super.key,
    required this.controller,
    this.label = 'Parish',
    this.enabled = true,
    this.prefixIcon = Icons.location_on_outlined,
    this.onChanged,
  });

  @override
  State<JamaicaParishDropdown> createState() => _JamaicaParishDropdownState();
}

class _JamaicaParishDropdownState extends State<JamaicaParishDropdown> {
  String? selectedParish;

  @override
  void initState() {
    super.initState();
    selectedParish = normalizeJamaicaParish(
      widget.controller.text,
    );

    if (selectedParish != null) {
      widget.controller.text = selectedParish!;
    }
  }

  @override
  void didUpdateWidget(
    covariant JamaicaParishDropdown oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      selectedParish = normalizeJamaicaParish(
        widget.controller.text,
      );

      if (selectedParish != null) {
        widget.controller.text = selectedParish!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedParish,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(widget.prefixIcon),
      ),
      hint: const Text('Select parish'),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
      ),
      items: jamaicaParishes
          .map(
            (parish) => DropdownMenuItem<String>(
              value: parish,
              child: Text(
                parish,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: widget.enabled
          ? (value) {
              setState(() {
                selectedParish = value;
              });

              widget.controller.text = value ?? '';
              widget.onChanged?.call(value);
            }
          : null,
    );
  }
}

class LoginScreen extends StatefulWidget {
  final bool returnToPrevious;
  final bool startInRegister;

  const LoginScreen({
    super.key,
    this.returnToPrevious = false,
    this.startInRegister = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();
  final businessNameController = TextEditingController();
  final businessPhoneController = TextEditingController();
  final businessParishController = TextEditingController();
  final TurnstileController _captchaController = TurnstileController();

  bool loading = false;
  bool googleLoading = false;
  bool googleFlowStarted = false;
  StreamSubscription<AuthState>? _googleAuthSubscription;
  String? _captchaToken;
  bool hidePassword = true;
  bool isRegister = false;
  String selectedRole = 'customer';
  String selectedCustomerAccountType = 'retail';
  String selectedBusinessType = 'Restaurant / Food Service';
  String? pendingConfirmationEmail;
  bool resendingConfirmation = false;
  late Future<HpjHelpTutorial?> _signupTutorialFuture;

  static const List<String> _businessTypes = <String>[
    'Restaurant / Food Service',
    'Hotel / Guesthouse',
    'School / Institution',
    'Supermarket / Shop',
    'Caterer',
    'Juice Bar',
    'Food Vendor',
    'Church / Community Group',
    'Other',
  ];

  bool get isBusinessRegistration =>
      isRegister &&
      selectedRole == 'customer' &&
      selectedCustomerAccountType == 'business';

  @override
  void initState() {
    super.initState();
    isRegister = widget.startInRegister;
    _signupTutorialFuture = fetchPublishedHelpTutorial(
      placement: 'signup',
      audience: 'all',
    );

    _googleAuthSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (!googleFlowStarted || data.session == null || !mounted) return;

      googleFlowStarted = false;
      FarmDataCache.clearAll();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _finishGoogleSignInNavigation();
      });
    });

    // If the embedded FlutLab preview opened this screen in a normal browser
    // tab specifically for Google OAuth, continue automatically. This makes the
    // user click Continue with Google only once.
    if (_isExternalGoogleLaunch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || googleLoading || loading) return;
        unawaited(_continueWithGoogle());
      });
    }
  }

  @override
  void dispose() {
    _googleAuthSubscription?.cancel();
    emailController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    businessNameController.dispose();
    businessPhoneController.dispose();
    businessParishController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  void _refreshSignupTutorial() {
    if (!mounted) return;
    setState(() {
      _signupTutorialFuture = fetchPublishedHelpTutorial(
        placement: 'signup',
        audience: 'all',
      );
    });
  }

  Widget _signupTutorialAction() {
    return FutureBuilder<HpjHelpTutorial?>(
      future: _signupTutorialFuture,
      builder: (context, snapshot) {
        final tutorial = snapshot.data;

        // No published signup tutorial = no button. This keeps the auth screen
        // clean until Admin actually adds and publishes a video.
        if (tutorial == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Center(
            child: TextButton.icon(
              onPressed: loading || googleLoading
                  ? null
                  : () => unawaited(
                        openHpjHelpTutorial(context, tutorial),
                      ),
              icon: const Icon(
                Icons.play_circle_outline_rounded,
                size: 20,
              ),
              label: Text(
                'Need help signing up? ${tutorial.buttonLabel}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _refreshCaptcha() async {
    if (!AppConfig.turnstileConfigured) return;
    if (mounted) setState(() => _captchaToken = null);
    try {
      await _captchaController.refreshToken();
    } catch (error) {
      farmDebugLog('Turnstile refresh failed: $error');
    }
  }

  String _confirmationEmailErrorMessage(AuthException error) {
    final lower = error.message.trim().toLowerCase();

    if (lower.contains('email address not authorized') ||
        lower.contains('not authorized')) {
      return 'Confirmation email delivery is not configured for this address yet. Please contact HPJ support.';
    }

    if (lower.contains('rate limit') ||
        lower.contains('over_email_send_rate_limit') ||
        lower.contains('too many')) {
      return 'The email service has reached its temporary sending limit. Please wait and try again.';
    }

    return 'Could not resend the confirmation email. Please try again shortly.';
  }

  Future<void> _resendConfirmationEmail() async {
    final email =
        (pendingConfirmationEmail ?? emailController.text).trim().toLowerCase();

    if (email.isEmpty || resendingConfirmation) return;

    setState(() => resendingConfirmation = true);

    try {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: AppConfig.emailConfirmationRedirectTo,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Confirmation email sent again to $email. Check your inbox and spam/junk folder.',
          ),
        ),
      );
    } on AuthException catch (error) {
      farmDebugLog('Confirmation email resend error: ${error.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_confirmationEmailErrorMessage(error))),
      );
    } catch (error) {
      farmDebugLog('Unexpected confirmation resend error: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not resend the confirmation email. Please check your connection and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => resendingConfirmation = false);
    }
  }

  void _finishGoogleSignInNavigation() {
    if (!mounted) return;

    if (googleLoading) {
      setState(() => googleLoading = false);
    }

    if (widget.returnToPrevious) {
      Navigator.of(context).pop(true);
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const AuthGate(),
      ),
      (route) => false,
    );
  }

  bool get _isFlutLabEmbeddedPreview {
    if (!kIsWeb) return false;

    final host = Uri.base.host.trim().toLowerCase();
    return host == 'preview.flutlab.io' || host.endsWith('.preview.flutlab.io');
  }

  bool get _isExternalGoogleLaunch {
    if (!kIsWeb) return false;

    return Uri.base.queryParameters['googleExternal'] == '1' &&
        Uri.base.queryParameters['auth'] == 'google' &&
        !AppConfig.hasGoogleOAuthCallback;
  }

  bool get _needsExternalFlutLabGoogleLaunch {
    return _isFlutLabEmbeddedPreview &&
        Uri.base.queryParameters['googleExternal'] != '1';
  }

  Future<void> _openGoogleOutsideFlutLab() async {
    final current = Uri.base;
    final params = <String, String>{
      ...current.queryParameters,
      'googleExternal': '1',
      'auth': 'google',
    };

    final externalUrl = current.replace(
      queryParameters: params,
      fragment: '',
    );

    final opened = await openExternalShareUrl(
      externalUrl.toString(),
    );

    if (!mounted || opened) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Google sign-in needs a normal browser tab. Use FlutLab Open in New Tab, then try again.',
        ),
      ),
    );
  }

  Future<void> _continueWithGoogle() async {
    if (loading || googleLoading) return;

    // Google blocks account authentication inside many embedded preview
    // frames. In FlutLab, move the flow to a normal browser tab first.
    if (_needsExternalFlutLabGoogleLaunch) {
      await _openGoogleOutsideFlutLab();
      return;
    }

    setState(() {
      googleLoading = true;
      googleFlowStarted = true;
    });

    try {
      final launched = await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: AppConfig.googleOAuthRedirectTo,
      );

      if (!launched) {
        throw Exception('Google sign-in could not be opened.');
      }

      if (!mounted) return;

      // Web navigates away immediately. On Android the browser is external,
      // so release the button while AuthGate waits for farm://auth-callback.
      if (!kIsWeb && supabase.auth.currentSession == null) {
        setState(() => googleLoading = false);
      }

      if (supabase.auth.currentSession != null && googleFlowStarted) {
        googleFlowStarted = false;
        _finishGoogleSignInNavigation();
      }
    } on AuthException catch (error) {
      googleFlowStarted = false;
      if (!mounted) return;
      setState(() => googleLoading = false);

      farmDebugLog('Google sign-in AuthException: ${error.message}');

      final lower = error.message.toLowerCase();
      final message = lower.contains('provider') && lower.contains('disabled')
          ? 'Google Sign-In is not enabled in Supabase yet.'
          : lower.contains('redirect') || lower.contains('callback')
              ? 'Google Sign-In redirect is not configured correctly yet.'
              : 'Google Sign-In could not start: ${error.message}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      googleFlowStarted = false;
      if (!mounted) return;
      setState(() => googleLoading = false);

      farmDebugLog('Google sign-in failed: $error');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Google Sign-In could not start: ${friendlyAppError(error)}',
          ),
        ),
      );
    }
  }

  Future<void> submit() async {
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;
    final fullName = fullNameController.text.trim();
    final businessName = businessNameController.text.trim();
    final businessPhone = businessPhoneController.text.trim();
    final rawBusinessParish = businessParishController.text.trim();
    String businessParish = rawBusinessParish;

    if (isBusinessRegistration && rawBusinessParish.isNotEmpty) {
      try {
        businessParish = requireJamaicaParish(
          rawBusinessParish,
          fieldLabel: 'Business parish',
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyAppError(error))),
        );
        return;
      }
    }

    if (email.isEmpty ||
        password.trim().isEmpty ||
        (isRegister && fullName.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    if (isBusinessRegistration &&
        (businessName.isEmpty ||
            businessPhone.isEmpty ||
            businessParish.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Business name, business phone, and parish are required.',
          ),
        ),
      );
      return;
    }

    if (AppConfig.turnstileConfigured &&
        (_captchaToken == null || _captchaToken!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the security check first.'),
        ),
      );
      return;
    }

    var leavingAuthScreen = false;
    setState(() => loading = true);
    try {
      if (isRegister) {
        final accountType =
            selectedRole == 'customer' ? selectedCustomerAccountType : 'farmer';

        final response = await supabase.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: AppConfig.emailConfirmationRedirectTo,
          captchaToken:
              AppConfig.turnstileConfigured ? _captchaToken?.trim() : null,
          data: {
            'full_name': fullName,
            'role': selectedRole,
            'account_type': accountType,
            if (isBusinessRegistration) 'business_name': businessName,
            if (isBusinessRegistration) 'business_type': selectedBusinessType,
            if (isBusinessRegistration) 'business_phone': businessPhone,
            if (isBusinessRegistration) 'business_parish': businessParish,
          },
        );

        FarmDataCache.clearAll();

        if (!mounted) return;

        if (response.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isBusinessRegistration
                    ? 'Business account created. Confirm your email, then sign in and choose Wholesale Business.'
                    : selectedRole == 'farmer'
                        ? 'Farmer account created. Confirm your email, then sign in and choose Farmer Partner.'
                        : 'Account created. Confirm your email, then sign in to choose your HPJ workspace.',
              ),
            ),
          );

          setState(() {
            isRegister = false;
            passwordController.clear();
            pendingConfirmationEmail = email;
          });
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBusinessRegistration
                  ? 'Business account created. Choose Wholesale Business to continue your setup.'
                  : selectedRole == 'farmer'
                      ? 'Account created. Choose Farmer Partner to continue your setup.'
                      : 'Account created. Choose the HPJ workspace you want to open.',
            ),
          ),
        );

        leavingAuthScreen = true;
        if (widget.returnToPrevious) {
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const AuthGate(),
            ),
            (route) => false,
          );
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
          captchaToken:
              AppConfig.turnstileConfigured ? _captchaToken?.trim() : null,
        );

        FarmDataCache.clearAll();

        if (!mounted) return;
        leavingAuthScreen = true;
        if (widget.returnToPrevious) {
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const AuthGate(),
            ),
            (route) => false,
          );
        }
      }
    } on AuthException catch (error) {
      if (!mounted) return;

      farmDebugLog('Supabase auth error: ${error.message}');

      final message = friendlyAuthErrorMessage(
        error,
        isRegister: isRegister,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) return;

      farmDebugLog('Unexpected auth error: $error');

      final message = isRegister
          ? 'Could not create account. Please check your details and try again.'
          : 'Could not sign in. Please check your email and password.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (!leavingAuthScreen && mounted) {
        await _refreshCaptcha();
      }
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _registrationChoiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: FarmColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: FarmColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: FarmColors.primary, size: 22),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 11.5,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: FarmColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _usePersonalRegistration() {
    setState(() {
      selectedRole = 'customer';
      selectedCustomerAccountType = 'retail';
    });
  }

  void _useBusinessRegistration() {
    setState(() {
      selectedRole = 'customer';
      selectedCustomerAccountType = 'business';
    });
  }

  void _useFarmerRegistration() {
    setState(() {
      selectedRole = 'farmer';
      selectedCustomerAccountType = 'retail';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFarmerRegistration = isRegister && selectedRole == 'farmer';
    final isPersonalRegistration =
        isRegister && !isBusinessRegistration && !isFarmerRegistration;

    final heading = !isRegister
        ? 'Welcome back'
        : isBusinessRegistration
            ? 'Create your business account'
            : isFarmerRegistration
                ? 'Join as a Farmer'
                : 'Create your HPJ account';

    final subtitle = !isRegister
        ? 'Sign in to continue to your HPJ workspaces.'
        : isBusinessRegistration
            ? 'One HPJ login for wholesale shopping, planning and orders.'
            : isFarmerRegistration
                ? 'Create your HPJ account first. Then complete the short farmer application.'
                : 'One secure HPJ account for the workspaces available to you.';

    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: widget.returnToPrevious
          ? AppBar(
              title: Text(isRegister ? 'Create account' : 'Sign in'),
              backgroundColor: FarmColors.background,
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 700 ? 24.0 : 18.0;

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                22,
                horizontalPadding,
                34,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 74,
                            height: 74,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: FarmColors.line),
                              boxShadow: [
                                BoxShadow(
                                  color: FarmColors.shadow.withOpacity(0.06),
                                  blurRadius: 18,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'lib/assets/images/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.eco_outlined,
                                size: 44,
                                color: FarmColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          heading,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: FarmColors.ink,
                            fontSize: 28,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (isRegister && !isPersonalRegistration) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: FarmColors.primarySoft,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: FarmColors.line),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isBusinessRegistration
                                      ? Icons.storefront_outlined
                                      : Icons.agriculture_outlined,
                                  color: FarmColors.primary,
                                  size: 21,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isBusinessRegistration
                                        ? 'Business account'
                                        : 'Farmer partner account',
                                    style: const TextStyle(
                                      color: FarmColors.ink,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed:
                                      loading ? null : _usePersonalRegistration,
                                  child: const Text('Use personal'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Semantics(
                              button: true,
                              label: 'Continue with Google',
                              child: SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: OutlinedButton(
                                  onPressed: loading || googleLoading
                                      ? null
                                      : _continueWithGoogle,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: FarmColors.ink,
                                    side: const BorderSide(
                                      color: Color(0xFFDADCE0),
                                      width: 1.15,
                                    ),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: googleLoading
                                      ? const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 19,
                                              height: 19,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                              ),
                                            ),
                                            SizedBox(width: 11),
                                            Text(
                                              'Opening Google...',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const _GoogleLetterMark(),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Continue with Google',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.1,
                                              ),
                                            ),
                                            if (_needsExternalFlutLabGoogleLaunch) ...[
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.open_in_new_rounded,
                                                size: 15,
                                                color: FarmColors.mutedText,
                                              ),
                                            ],
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          _needsExternalFlutLabGoogleLaunch
                              ? 'Google opens securely in a browser tab.'
                              : isRegister
                                  ? 'Create your account, then choose a workspace.'
                                  : 'Choose your workspace after signing in.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 10.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isRegister) _signupTutorialAction(),
                        const SizedBox(height: 13),
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'or',
                                style: TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 14),
                        FarmCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (isRegister) ...[
                                TextField(
                                  controller: fullNameController,
                                  textCapitalization: TextCapitalization.words,
                                  autofillHints: const [AutofillHints.name],
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: isBusinessRegistration
                                        ? 'Contact person *'
                                        : 'Full name',
                                    prefixIcon:
                                        const Icon(Icons.person_outline),
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                              if (isBusinessRegistration) ...[
                                TextField(
                                  controller: businessNameController,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Business name *',
                                    prefixIcon: Icon(Icons.store_outlined),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                DropdownButtonFormField<String>(
                                  value: selectedBusinessType,
                                  decoration: const InputDecoration(
                                    labelText: 'Business type',
                                    prefixIcon: Icon(Icons.category_outlined),
                                  ),
                                  items: _businessTypes
                                      .map(
                                        (type) => DropdownMenuItem<String>(
                                          value: type,
                                          child: Text(type),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: loading
                                      ? null
                                      : (value) {
                                          if (value != null) {
                                            setState(() =>
                                                selectedBusinessType = value);
                                          }
                                        },
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: businessPhoneController,
                                  keyboardType: TextInputType.phone,
                                  autofillHints: const [
                                    AutofillHints.telephoneNumber,
                                  ],
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Business phone *',
                                    prefixIcon: Icon(Icons.phone_outlined),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                JamaicaParishDropdown(
                                  controller: businessParishController,
                                  label: 'Business parish *',
                                  enabled: !loading,
                                  prefixIcon: Icons.map_outlined,
                                ),
                                const SizedBox(height: 14),
                              ],
                              TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: passwordController,
                                obscureText: hidePassword,
                                autofillHints: isRegister
                                    ? const [AutofillHints.newPassword]
                                    : const [AutofillHints.password],
                                textInputAction: TextInputAction.done,
                                onSubmitted: loading ? null : (_) => submit(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: hidePassword
                                        ? 'Show password'
                                        : 'Hide password',
                                    onPressed: () {
                                      setState(
                                          () => hidePassword = !hidePassword);
                                    },
                                    icon: Icon(
                                      hidePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                              ),
                              if (isFarmerRegistration) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: FarmColors.primarySoft,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.agriculture_outlined,
                                        color: FarmColors.primary,
                                        size: 20,
                                      ),
                                      SizedBox(width: 9),
                                      Expanded(
                                        child: Text(
                                          'After sign-in, HPJ will guide you through the short farmer application.',
                                          style: TextStyle(
                                            color: FarmColors.ink,
                                            fontSize: 11.5,
                                            height: 1.35,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (isBusinessRegistration) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: FarmColors.primarySoft,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Text(
                                    'Wholesale pricing is activated after approval. You can still shop normally while your application is reviewed.',
                                    style: TextStyle(
                                      color: FarmColors.ink,
                                      fontSize: 11.5,
                                      height: 1.35,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (AppConfig.turnstileConfigured) ...[
                          const SizedBox(height: 14),
                          _HpjTurnstilePanel(
                            controller: _captchaController,
                            action: 'hpj_auth',
                            onTokenChanged: (token) {
                              if (!mounted) return;
                              setState(() => _captchaToken = token);
                            },
                          ),
                        ],
                        if (!isRegister &&
                            pendingConfirmationEmail != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: FarmColors.primarySoft,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: FarmColors.line),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.mark_email_unread_outlined,
                                      color: FarmColors.primary,
                                      size: 22,
                                    ),
                                    SizedBox(width: 9),
                                    Expanded(
                                      child: Text(
                                        'Confirm your email',
                                        style: TextStyle(
                                          color: FarmColors.ink,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  'We created the account for ${pendingConfirmationEmail!}. Open the confirmation email before signing in. Check Spam or Junk if it is not in your inbox.',
                                  style: const TextStyle(
                                    color: FarmColors.mutedText,
                                    fontSize: 12,
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: resendingConfirmation
                                      ? null
                                      : _resendConfirmationEmail,
                                  icon: resendingConfirmation
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.refresh_rounded),
                                  label: Text(
                                    resendingConfirmation
                                        ? 'Sending...'
                                        : 'Resend confirmation email',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (!isRegister) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              icon: const Icon(Icons.lock_reset_outlined,
                                  size: 18),
                              label: const Text('Forgot Password?'),
                              onPressed: loading
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ForgotPasswordScreen(
                                            initialEmail:
                                                emailController.text.trim(),
                                          ),
                                        ),
                                      );
                                    },
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        PrimaryFarmButton(
                          label: loading
                              ? 'Please wait...'
                              : (isRegister
                                  ? isBusinessRegistration
                                      ? 'Create Business Account'
                                      : isFarmerRegistration
                                          ? 'Create Farmer Account'
                                          : 'Create Account'
                                  : 'Sign in'),
                          onPressed: loading ||
                                  (AppConfig.turnstileConfigured &&
                                      (_captchaToken == null ||
                                          _captchaToken!.isEmpty))
                              ? null
                              : submit,
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: loading
                              ? null
                              : () {
                                  setState(() {
                                    isRegister = !isRegister;
                                    hidePassword = true;
                                    _captchaToken = null;
                                    if (isRegister) {
                                      selectedRole = 'customer';
                                      selectedCustomerAccountType = 'retail';
                                      pendingConfirmationEmail = null;
                                    }
                                  });
                                  if (AppConfig.turnstileConfigured) {
                                    _captchaController
                                        .refreshToken()
                                        .catchError(
                                      (error) {
                                        farmDebugLog(
                                          'Turnstile refresh failed: $error',
                                        );
                                      },
                                    );
                                  }
                                },
                          child: Text(
                            isRegister
                                ? 'Already have an account? Log in'
                                : 'New to HPJ? Create account',
                          ),
                        ),
                        if (isPersonalRegistration) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: const [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'JOINING HPJ FOR SOMETHING ELSE?',
                                  style: TextStyle(
                                    color: FarmColors.mutedText,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _registrationChoiceCard(
                            icon: Icons.storefront_outlined,
                            title: 'Business account',
                            subtitle: 'Wholesale buying for your business',
                            onTap: _useBusinessRegistration,
                          ),
                          const SizedBox(height: 9),
                          _registrationChoiceCard(
                            icon: Icons.agriculture_outlined,
                            title: 'Farmer partner',
                            subtitle: 'Apply to supply produce to HPJ',
                            onTap: _useFarmerRegistration,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GoogleLetterMark extends StatelessWidget {
  const _GoogleLetterMark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Google',
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
        ),
        child: const SizedBox(
          width: 17,
          height: 17,
          child: CustomPaint(
            painter: _GoogleGMarkPainter(),
          ),
        ),
      ),
    );
  }
}

class _GoogleGMarkPainter extends CustomPainter {
  const _GoogleGMarkPainter();

  static const double _pi = 3.1415926535897932;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.38;
    final stroke = size.shortestSide * 0.22;
    final rect = Rect.fromCircle(center: center, radius: radius);

    Paint arc(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Four clean segments approximate Google's familiar multicolor G
    // without adding flutter_svg or a new image asset.
    canvas.drawArc(
      rect,
      -0.20 * _pi,
      0.70 * _pi,
      false,
      arc(const Color(0xFF4285F4)),
    );
    canvas.drawArc(
      rect,
      0.50 * _pi,
      0.52 * _pi,
      false,
      arc(const Color(0xFF34A853)),
    );
    canvas.drawArc(
      rect,
      1.02 * _pi,
      0.43 * _pi,
      false,
      arc(const Color(0xFFFBBC05)),
    );
    canvas.drawArc(
      rect,
      1.45 * _pi,
      0.35 * _pi,
      false,
      arc(const Color(0xFFEA4335)),
    );

    final blue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.50,
          size.height * 0.46,
          size.width * 0.39,
          size.height * 0.16,
        ),
        Radius.circular(size.height * 0.05),
      ),
      blue,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleGMarkPainter oldDelegate) => false;
}

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with WidgetsBindingObserver {
  static const int homeTabIndex = 0;
  static const int shopTabIndex = 1;
  static const int myBoxTabIndex = 2;
  static const int ordersTabIndex = 3;
  static const int accountTabIndex = 4;

  int selectedIndex = 0;
  String selectedShopCategory = 'All';
  int shopCategorySelectionVersion = 0;
  final List<Product> cart = [];
  final Set<String> favoriteProductIds = <String>{};
  final Map<String, Product> favoriteProductCache = <String, Product>{};
  static const String recentlyViewedStorageKey =
      'natural_harvest_recently_viewed_product_ids';

  final List<Product> recentlyViewedProducts = [];
  dynamic inventoryRealtimeChannel;
  dynamic notificationRealtimeChannel;
  Timer? inventoryRefreshDebounce;
  StreamSubscription<AuthState>? authStateSubscription;
  String? authBoundaryUserId;
  final Set<String> seenRealtimeNotificationIds = <String>{};
  final Map<String, DateTime> realtimeNotificationCooldowns =
      <String, DateTime>{};

  int get cartItemCount => cart.length;

  int authViewVersion = 0;
  late Future<MarketplaceProgramSettings> customerMarketplaceSettingsFuture;

  String get authViewKey {
    if (!isLoggedIn) return 'guest-$authViewVersion';
    return 'user-${currentUserId ?? 'unknown'}-$authViewVersion';
  }

  List<Product> get favoriteProducts => favoriteProductIds
      .map((id) => favoriteProductCache[id])
      .whereType<Product>()
      .toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    customerMarketplaceSettingsFuture = fetchMarketplaceProgramSettings();
    authBoundaryUserId = supabase.auth.currentUser?.id.trim();
    selectedIndex = widget.initialIndex.clamp(0, 4).toInt();
    unawaited(
      saveHpjNavigationPreference(
        workspace: 'customer',
        tab: selectedIndex,
      ),
    );
    cart.addAll(OfflineCartStore.restore());
    unawaited(_restorePersistentCart());
    loadRecentlyViewedProducts();
    subscribeToInventoryUpdates();
    subscribeToNotificationUpdates();
    authStateSubscription =
        supabase.auth.onAuthStateChange.listen((authState) async {
      if (!mounted) return;

      final rawUserId = authState.session?.user.id.trim() ?? '';
      final nextUserId = rawUserId.isEmpty ? null : rawUserId;
      final previousUserId = authBoundaryUserId;
      final identityChanged = nextUserId != previousUserId;

      authBoundaryUserId = nextUserId;

      if (identityChanged) {
        clearHpjPrivateAccountMemory();
      } else {
        FarmDataCache.clearOrders();
      }

      // Preserve intentional guest browsing. Redirect only when a previously
      // authenticated Customer session disappears.
      if (previousUserId != null && nextUserId == null) {
        unsubscribeFromNotificationUpdates();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (_) => const AuthGate(),
            ),
            (route) => false,
          );
        });
        return;
      }

      if (previousUserId != null &&
          nextUserId != null &&
          previousUserId != nextUserId) {
        unsubscribeFromNotificationUpdates();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (_) => const OwnerWorkspaceSwitcherScreen(
                showCloseButton: false,
              ),
            ),
            (route) => false,
          );
        });
        return;
      }

      if (nextUserId == null) {
        unsubscribeFromNotificationUpdates();
        setState(() {
          authViewVersion++;
          if (selectedIndex == accountTabIndex) {
            selectedIndex = homeTabIndex;
          }
        });
        return;
      }

      subscribeToNotificationUpdates();
      if (mounted) {
        setState(() {
          authViewVersion++;
        });
      }
    });
  }

  Future<void> _revalidateCustomerWorkspace() async {
    if (!mounted) return;

    final operationBoundary = captureHpjPrivateOperationBoundary();

    final next = () async {
      final settings = await fetchMarketplaceProgramSettings();

      if (!isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
        throw StateError(
          'Customer workspace access response became stale after account change.',
        );
      }

      return settings;
    }();

    if (!isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
      return;
    }

    setState(() {
      customerMarketplaceSettingsFuture = next;
    });

    try {
      await next;
    } catch (error) {
      if (!isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
        return;
      }

      farmDebugLog(
        'Customer workspace resume validation skipped: $error',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_revalidateCustomerWorkspace());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    inventoryRefreshDebounce?.cancel();
    authStateSubscription?.cancel();
    if (inventoryRealtimeChannel != null) {
      supabase.removeChannel(inventoryRealtimeChannel);
    }
    unsubscribeFromNotificationUpdates();
    super.dispose();
  }

  void subscribeToInventoryUpdates() {
    try {
      inventoryRealtimeChannel = supabase
          .channel('natural-harvest-products-realtime')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'products',
            callback: (_) {
              inventoryRefreshDebounce?.cancel();
              inventoryRefreshDebounce = Timer(
                AppPerformanceConfig.realtimeDebounce,
                () {
                  FarmDataCache.clearProducts();
                  if (mounted) {
                    setState(() {
                      authViewVersion++;
                    });
                  }
                },
              );
            },
          )
          .subscribe();
    } catch (error) {
      farmDebugLog('Realtime inventory unavailable: $error');
    }
  }

  void subscribeToNotificationUpdates() {
    if (!isLoggedIn || notificationRealtimeChannel != null) return;

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      notificationRealtimeChannel = supabase
          .channel('natural-harvest-notifications-${currentUser.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            callback: (payload) {
              final row = Map<String, dynamic>.from(payload.newRecord);

              if (!notificationRowTargetsCurrentUser(row)) {
                farmDebugLog('Browser notification skipped');
                return;
              }

              final notice = FarmNotification.fromSupabase(row);
              final noticeKey = notice.id.trim().isNotEmpty
                  ? notice.id.trim()
                  : browserNotificationTag(
                      title: notice.title,
                      body: notice.message,
                      orderId: notice.orderId,
                      type: notice.type,
                    );

              if (!seenRealtimeNotificationIds.add(noticeKey)) {
                farmDebugLog('Browser notification skipped');
                return;
              }

              // Quiet duplicate bursts without hiding distinct order/payment events.
              final cooldownKey = <String>[
                notice.type.trim().toLowerCase(),
                (notice.orderId ?? '').trim().toLowerCase(),
                notice.title.trim().toLowerCase(),
              ].join('|');
              final now = DateTime.now();
              final lastShown = realtimeNotificationCooldowns[cooldownKey];
              if (lastShown != null &&
                  now.difference(lastShown) < const Duration(seconds: 90)) {
                farmDebugLog('Browser notification grouped to reduce noise.');
                return;
              }
              realtimeNotificationCooldowns[cooldownKey] = now;

              FarmDataCache.notifications = null;

              showBrowserNotification(
                title: notice.title,
                body: notice.message,
                orderId: notice.orderId,
                type: notice.type,
              );

              if (mounted) {
                setState(() {
                  authViewVersion++;
                });
              }
            },
          )
          .subscribe();
    } catch (error) {
      debugPrintOnce(
        'notification_realtime_unavailable',
        'Browser notification realtime skipped. In-app notifications still work.',
      );
    }
  }

  void unsubscribeFromNotificationUpdates() {
    if (notificationRealtimeChannel != null) {
      supabase.removeChannel(notificationRealtimeChannel);
      notificationRealtimeChannel = null;
    }
    seenRealtimeNotificationIds.clear();
    realtimeNotificationCooldowns.clear();
  }

  Future<void> _restorePersistentCart() async {
    if (cart.isNotEmpty) return;

    String? normalizedCurrentUserId() {
      final raw = supabase.auth.currentUser?.id.trim() ?? '';
      return raw.isEmpty ? null : raw;
    }

    final restoreUserId = normalizedCurrentUserId();

    bool restoreBoundaryIsCurrent() {
      return mounted && normalizedCurrentUserId() == restoreUserId;
    }

    try {
      final savedIds = await OfflineCartStore.restorePersistentProductIds();
      if (!restoreBoundaryIsCurrent() || savedIds.isEmpty) return;

      final counts = <String, int>{};
      for (final rawId in savedIds) {
        final id = rawId.trim();
        if (id.isEmpty) continue;
        counts[id] = (counts[id] ?? 0) + 1;
      }

      final fetched = <String, Product>{};
      for (final id in counts.keys) {
        final product = await fetchProductById(id);
        if (!restoreBoundaryIsCurrent()) return;
        if (product != null && isVisibleCustomerProduct(product)) {
          fetched[id] = product;
        }
      }

      if (!restoreBoundaryIsCurrent() || fetched.isEmpty || cart.isNotEmpty) {
        return;
      }

      final restored = <Product>[];
      for (final entry in counts.entries) {
        final product = fetched[entry.key];
        if (product == null) continue;
        final allowedQuantity = product.canAddToCart
            ? entry.value.clamp(0, product.stockQuantity).toInt()
            : 0;
        for (var i = 0; i < allowedQuantity; i++) {
          restored.add(product);
        }
      }

      if (restored.isEmpty || !restoreBoundaryIsCurrent()) return;
      setState(() {
        cart
          ..clear()
          ..addAll(restored);
      });

      if (!restoreBoundaryIsCurrent()) return;
      persistCart();
    } catch (error) {
      // Keep the saved IDs. HPJ can restore them on a later online launch.
      farmDebugLog('Persistent My Box restore deferred: $error');
    }
  }

  void persistCart() {
    OfflineCartStore.save(cart);
  }

  void refreshInventoryViews() {
    FarmDataCache.clearProducts();
    FarmDataCache.clearOrders();
    unawaited(reconcileCartWithServerStock());
    if (!mounted) return;
    setState(() {
      authViewVersion++;
    });
  }

  Future<void> reconcileCartWithServerStock() async {
    if (cart.isEmpty) return;

    try {
      final stockById = await fetchProductStockByIds(
        cart.map((product) => product.id).toList(),
      );
      final usedById = <String, int>{};
      final updatedCart = <Product>[];
      var changed = false;

      for (final product in cart) {
        final id = product.id.trim();
        final availableStock = stockById[id] ?? 0;
        final used = usedById[id] ?? 0;
        if (availableStock > used) {
          updatedCart.add(product);
          usedById[id] = used + 1;
        } else {
          changed = true;
        }
      }

      if (!changed || !mounted) return;
      setState(() {
        cart
          ..clear()
          ..addAll(updatedCart);
        persistCart();
        authViewVersion++;
      });
    } catch (error) {
      farmDebugLog('Cart stock reconciliation skipped: $error');
    }
  }

  int quantityForProduct(Product product) {
    return cart.where((item) => item.id == product.id).length;
  }

  bool isFavorite(Product product) => favoriteProductIds.contains(product.id);

  void toggleFavorite(Product product) {
    setState(() {
      if (favoriteProductIds.contains(product.id)) {
        favoriteProductIds.remove(product.id);
        favoriteProductCache.remove(product.id);
      } else {
        favoriteProductIds.add(product.id);
        favoriteProductCache[product.id] = product;
      }
    });
  }

  void saveRecentlyViewedProducts() {
    try {
      final ids = recentlyViewedProducts
          .where(isVisibleCustomerProduct)
          .map((product) => product.id.trim())
          .where((id) => id.isNotEmpty)
          .take(10)
          .toList();

      unawaited(
        HpjSmartLocalStore.writeStringList(
          recentlyViewedStorageKey,
          ids,
        ),
      );
    } catch (error) {
      farmDebugLog('Recently viewed save skipped: $error');
    }
  }

  Future<void> loadRecentlyViewedProducts() async {
    String? normalizedCurrentUserId() {
      final raw = supabase.auth.currentUser?.id.trim() ?? '';
      return raw.isEmpty ? null : raw;
    }

    final loadUserId = normalizedCurrentUserId();

    bool loadBoundaryIsCurrent() {
      return mounted && normalizedCurrentUserId() == loadUserId;
    }

    try {
      final ids = (await HpjSmartLocalStore.readStringList(
        recentlyViewedStorageKey,
      ))
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .take(10)
          .toList();

      if (!loadBoundaryIsCurrent() || ids.isEmpty) return;

      final fetched = await Future.wait<Product?>(
        ids.map(fetchProductById),
      );
      if (!loadBoundaryIsCurrent()) return;

      final loaded =
          fetched.whereType<Product>().where(isVisibleCustomerProduct).toList();

      if (loaded.isEmpty || !loadBoundaryIsCurrent()) return;
      setState(() {
        recentlyViewedProducts
          ..clear()
          ..addAll(cleanRecentlyViewedProducts(loaded));
      });
    } catch (error) {
      farmDebugLog('Recently viewed load skipped: $error');
    }
  }

  void trackRecentlyViewed(Product product) {
    if (!isVisibleCustomerProduct(product)) return;

    setState(() {
      recentlyViewedProducts.removeWhere((item) => item.id == product.id);
      recentlyViewedProducts.insert(0, product);
      final cleaned = cleanRecentlyViewedProducts(recentlyViewedProducts);
      recentlyViewedProducts
        ..clear()
        ..addAll(cleaned);
    });

    saveRecentlyViewedProducts();
  }

  void increaseProductQuantity(Product product) {
    if (!product.canAddToCart) return;
    setState(() {
      cart.add(product);
      persistCart();
    });
  }

  void decreaseProductQuantity(Product product) {
    final index = cart.indexWhere((item) => item.id == product.id);
    if (index == -1) return;

    setState(() {
      cart.removeAt(index);
      persistCart();
    });
  }

  void addToCart(Product product) {
    if (!product.canAddToCart) return;
    increaseProductQuantity(product);
  }

  void removeFromCart(Product product) => decreaseProductQuantity(product);

  void _selectCustomerTab(int index) {
    if (!mounted) return;
    final safeIndex = index.clamp(0, 4).toInt();
    setState(() => selectedIndex = safeIndex);
    unawaited(
      saveHpjNavigationPreference(
        workspace: 'customer',
        tab: safeIndex,
      ),
    );
  }

  Future<void> openSignInFromTab() async {
    final didSignIn = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(returnToPrevious: true),
      ),
    );

    if (!mounted) return;
    if (didSignIn == true || isLoggedIn) {
      _selectCustomerTab(accountTabIndex);
    } else {
      setState(() {});
    }
  }

  void openFloatingCart() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
            backgroundColor: FarmColors.background,
            appBar: AppBar(
              title: const Text('My Farm Box'),
              backgroundColor: FarmColors.background,
            ),
            body: FarmBoxScreen(
              cart: cart,
              onRemoveFromCart: removeFromCart,
              onAddToCart: increaseProductQuantity,
              onShopTap: () => _selectCustomerTab(shopTabIndex),
              onOrderPlaced: () {
                if (!mounted) return;

                setState(() {
                  cart.clear();
                });

                persistCart();
                FarmDataCache.clearProducts();
                FarmDataCache.clearOrders();
              },
              onInventoryChanged: refreshInventoryViews,
            )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void goToShop({String? category}) {
      if (!mounted) return;

      final cleanCategory = category?.trim();
      setState(() {
        if (cleanCategory != null && cleanCategory.isNotEmpty) {
          selectedShopCategory = normalizeProductCategory(cleanCategory);
          shopCategorySelectionVersion++;
        }
        selectedIndex = shopTabIndex;
      });
      unawaited(
        saveHpjNavigationPreference(
          workspace: 'customer',
          tab: shopTabIndex,
        ),
      );
    }

    final goToShopHome = () => goToShop();

    void goToMyBoxFromProductDetail() {
      Navigator.of(context).popUntil((route) => route.isFirst);
      if (!mounted) return;
      _selectCustomerTab(myBoxTabIndex);
    }

    List<CartLine> currentCartLines() {
      final grouped = <String, CartLine>{};

      for (final product in cart) {
        if (grouped.containsKey(product.id)) {
          grouped[product.id] = grouped[product.id]!.copyWith(
            quantity: grouped[product.id]!.quantity + 1,
          );
        } else {
          grouped[product.id] = CartLine(product: product, quantity: 1);
        }
      }

      return grouped.values.toList();
    }

    double subtotalForCartLines(List<CartLine> lines) {
      return lines.fold<double>(
        0,
        (total, line) => total + (line.product.effectivePrice * line.quantity),
      );
    }

    void goToCheckoutFromProductDetail() async {
      final lines = currentCartLines();
      if (lines.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Your farm box is empty. Add an item before checkout.'),
          ),
        );
        return;
      }

      final allowed = await requireLoginForCheckout(context);
      if (!mounted || !context.mounted || !allowed) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CheckoutScreen(
            cartLines: lines,
            subtotal: subtotalForCartLines(lines),
            onOrderPlaced: () {
              if (!mounted) return;

              setState(() {
                cart.clear();
              });

              persistCart();
              FarmDataCache.clearProducts();
              FarmDataCache.clearOrders();
            },
            onInventoryChanged: refreshInventoryViews,
          ),
        ),
      );
    }

    final pages = <Widget>[
      HomeScreen(
        key: ValueKey('home-$authViewKey'),
        onShopTap: goToShopHome,
        onCategoryTap: (category) => goToShop(category: category),
        onCartTap: openFloatingCart,
        cartItemCount: cartItemCount,
        recentlyViewedProducts: recentlyViewedProducts,
        favoriteProducts: favoriteProducts,
        onAddToCart: increaseProductQuantity,
        onRemoveFromCart: decreaseProductQuantity,
        quantityForProduct: quantityForProduct,
        onViewed: trackRecentlyViewed,
        onViewMyBox: goToMyBoxFromProductDetail,
        onCheckout: goToCheckoutFromProductDetail,
      ),
      ShopScreen(
        key: ValueKey('shop-$authViewKey'),
        onAddToCart: increaseProductQuantity,
        onRemoveFromCart: decreaseProductQuantity,
        quantityForProduct: quantityForProduct,
        isFavorite: isFavorite,
        onToggleFavorite: toggleFavorite,
        onViewed: trackRecentlyViewed,
        recentlyViewedProducts: recentlyViewedProducts,
        initialCategory: selectedShopCategory,
        categorySelectionVersion: shopCategorySelectionVersion,
        onViewMyBox: goToMyBoxFromProductDetail,
        onCheckout: goToCheckoutFromProductDetail,
      ),
      FarmBoxScreen(
        cart: cart,
        onRemoveFromCart: removeFromCart,
        onAddToCart: increaseProductQuantity,
        onShopTap: () => _selectCustomerTab(shopTabIndex),
        onOrderPlaced: () {
          if (!mounted) return;

          setState(() {
            cart.clear();
          });

          persistCart();
          FarmDataCache.clearProducts();
          FarmDataCache.clearOrders();
        },
        onInventoryChanged: refreshInventoryViews,
      ),
      OrdersScreen(
        key: ValueKey('orders-$authViewKey'),
        onAddToCart: increaseProductQuantity,
        onOpenMyBox: () {
          if (!mounted) return;
          _selectCustomerTab(myBoxTabIndex);
        },
        onBackToHome: () {
          if (!mounted) return;
          _selectCustomerTab(homeTabIndex);
        },
      ),
      AccountScreen(
        favoriteProducts: favoriteProducts,
        recentlyViewedProducts: recentlyViewedProducts,
        onShopTap: goToShopHome,
        onAddToCart: increaseProductQuantity,
        onSignedOut: () {
          if (!mounted) return;
          _selectCustomerTab(homeTabIndex);
        },
      ),
    ];

    final destinations = <FarmBottomOption>[
      const FarmBottomOption(
        icon: Icon(Icons.home_outlined, size: 28),
        selectedIcon: Icon(Icons.home_rounded, size: 28),
        label: 'Home',
      ),
      const FarmBottomOption(
        icon: Icon(Icons.storefront_outlined, size: 28),
        selectedIcon: Icon(Icons.storefront_rounded, size: 28),
        label: 'Shop',
      ),
      FarmBottomOption(
        icon: const Icon(Icons.shopping_bag_outlined, size: 28),
        selectedIcon: const Icon(Icons.shopping_bag_rounded, size: 28),
        label: 'My Box',
        badgeCount: cartItemCount,
      ),
      const FarmBottomOption(
        icon: Icon(Icons.receipt_long_outlined, size: 28),
        selectedIcon: Icon(Icons.receipt_long_rounded, size: 28),
        label: 'Orders',
      ),
      const FarmBottomOption(
        icon: Icon(Icons.person_outline_rounded, size: 28),
        selectedIcon: Icon(Icons.person_rounded, size: 28),
        label: 'Account',
      ),
    ];

    final safeSelectedIndex =
        selectedIndex >= pages.length ? homeTabIndex : selectedIndex;

    return FutureBuilder<MarketplaceProgramSettings>(
      future: customerMarketplaceSettingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const _SmartEntryLoadingView();
        }

        final settings = snapshot.data ?? MarketplaceProgramSettings.fallback;
        if (!settings.customerMarketplaceEnabled) {
          return const CustomerMarketplaceComingSoonScreen();
        }

        return Scaffold(
          body: IndexedStack(index: safeSelectedIndex, children: pages),
          bottomNavigationBar: FarmBottomOptionsBar(
            selectedIndex: safeSelectedIndex,
            destinations: destinations,
            onSelected: (index) async {
              if (!mounted) return;

              final tappedAccountTab = index == accountTabIndex;

              if (tappedAccountTab && !isLoggedIn) {
                await openSignInFromTab();
                return;
              }

              _selectCustomerTab(index);
            },
          ),
        );
      },
    );
  }
}

class FarmPage extends StatelessWidget {
  final Widget child;

  const FarmPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FarmColors.background,
      child: SafeArea(child: child),
    );
  }
}
