part of harvest_place_app;

// Root navigator used by Android push-notification taps. Keeping one app-level
// key lets HPJ open the exact secured destination even when the notification
// launches the app from a terminated state.
final GlobalKey<NavigatorState> hpjRootNavigatorKey =
    GlobalKey<NavigatorState>();

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
      isLoggedIn;

  // Signed-in users resolve to their remembered safe workspace/tab. On a true
  // first login HPJ chooses Customer Home, Farmer Feed, or Wholesale Feed;
  // Staff/Admin is never an automatic startup destination. Guests bypass this
  // resolver so a checkout/login flow is never interrupted mid-order.
  bool shouldChooseWorkspace = isLoggedIn &&
      !AppConfig.hasPasswordRecoveryCallback &&
      !AppConfig.hasEmailConfirmationCallback;

  bool isPasswordRecovery = AppConfig.hasPasswordRecoveryCallback;
  bool isEmailConfirmation = AppConfig.hasEmailConfirmationCallback;
  String? passwordRecoveryError;
  String? emailConfirmationError;
  String? emailConfirmationMessage;
  late final StreamSubscription<AuthState> _authSubscription;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();

    if (shouldChooseWorkspace) {
      _workspaceAccessFuture = fetchOwnerWorkspaceAccessSnapshot();
      _navigationPreferenceFuture = fetchHpjNavigationPreference();
    }

    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;

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

      setState(() {});
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

    if (AppConfig.hasEmailConfirmationCallback) {
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

    if (AppConfig.hasEmailConfirmationCallback) {
      unawaited(_prepareEmailConfirmationSession());
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

  void enterMarket() {
    if (!mounted) return;
    setState(() {
      hasEnteredMarket = true;
      shouldChooseWorkspace = isLoggedIn;
      _workspaceAccessFuture =
          isLoggedIn ? fetchOwnerWorkspaceAccessSnapshot() : null;
      _navigationPreferenceFuture =
          isLoggedIn ? fetchHpjNavigationPreference() : null;
    });
  }

  Future<void> enterMarketAsGuest() async {
    await clearPrivateSessionStateForGuestBrowsing();
    if (!mounted) return;
    setState(() {
      hasEnteredMarket = true;
      shouldChooseWorkspace = false;
    });
  }

  void _enterCustomerWorkspace() {
    if (!mounted) return;
    unawaited(
      saveHpjNavigationPreference(
        workspace: 'customer',
        tab: 0,
      ),
    );
    setState(() {
      hasEnteredMarket = true;
      shouldChooseWorkspace = false;
      _workspaceAccessFuture = null;
      _navigationPreferenceFuture = null;
    });
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
          if (access.farmerProfile != null) {
            return FarmerAccessGate(
              initialTab: preference.farmerTab,
            );
          }
          break;
        case 'wholesale':
          if (access.businessAccount != null) {
            return BusinessWholesaleHubScreen(
              initialTab: preference.wholesaleTab,
            );
          }
          break;
        case 'customer':
        default:
          return MainNavigation(
            initialIndex: preference.customerTab,
          );
      }
    }

    // First-login rule: never auto-open Staff/Admin. A farmer-first account
    // starts in Farmer (Feed once approved), a business-first account starts
    // in Wholesale (Feed once approved), and everyone else starts at Home.
    final metadata =
        supabase.auth.currentUser?.userMetadata ?? const <String, dynamic>{};
    final role = (metadata['role'] ?? '').toString().trim().toLowerCase();
    final accountType =
        (metadata['account_type'] ?? '').toString().trim().toLowerCase();

    if (role == 'farmer') {
      return const FarmerAccessGate(initialTab: 0);
    }

    if (accountType == 'business' || accountType == 'wholesale') {
      return const BusinessWholesaleHubScreen(initialTab: 0);
    }

    return const MainNavigation(initialIndex: 0);
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

        // If role lookup fails, never block a signed-in user. Customer Home is
        // always the safe fallback and Staff/Admin is never auto-opened.
        if (access == null) {
          return const MainNavigation(initialIndex: 0);
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

    if (passwordRecoveryError != null && !hasEnteredMarket) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || passwordRecoveryError == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset link error: $passwordRecoveryError')),
        );
        passwordRecoveryError = null;
      });
    }

    // The welcome page is only the first splash screen. Once the user enters
    // the market, stay in the market even if auth later becomes null.
    if (!hasEnteredMarket) {
      return PublicLandingScreen(
        onEnterMarket: enterMarket,
        onAuth: () {
          openAuth();
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

  static const String _heroPhoto =
      'https://images.unsplash.com/photo-1767452433319-12b4d7e6ec91'
      '?auto=format&fit=crop&w=1800&q=82';

  static const String _customerPhoto =
      'https://images.unsplash.com/photo-1775825772432-58a1a31dcf40'
      '?auto=format&fit=crop&w=1200&q=82';

  static const String _wholesalePhoto =
      'https://images.unsplash.com/photo-1769355104335-acef3aa4c9b6'
      '?auto=format&fit=crop&w=1200&q=82';

  static const String _farmerPhoto =
      'https://images.unsplash.com/photo-1767590954924-9ff1057b9f65'
      '?auto=format&fit=crop&w=1200&q=82';

  static const String _staffPhoto =
      'https://images.unsplash.com/photo-1770992225308-154250075727'
      '?auto=format&fit=crop&w=1200&q=82';

  @override
  void initState() {
    super.initState();
    _future = fetchOwnerWorkspaceAccessSnapshot();
  }

  Future<void> _reload() async {
    final next = fetchOwnerWorkspaceAccessSnapshot();
    if (mounted) {
      setState(() => _future = next);
    }
    await next;
  }

  void _open(Widget screen) {
    // A chosen workspace becomes the navigation root. This prevents the
    // device/app Back button from ever revealing the workspace selector.
    // Users switch workspaces only from the explicit Switch Workspace action.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => screen),
      (route) => false,
    );
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    FarmDataCache.clearAll();
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

  String get _firstName {
    final user = supabase.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};

    final fullName = (metadata['full_name'] ?? '').toString().trim();
    if (fullName.isNotEmpty) {
      return fullName.split(RegExp(r'\s+')).first;
    }

    final email = user?.email?.trim() ?? '';
    if (email.contains('@')) {
      final local = email.split('@').first.trim();
      if (local.isNotEmpty) {
        return local[0].toUpperCase() +
            (local.length > 1 ? local.substring(1) : '');
      }
    }

    return 'there';
  }

  @override
  Widget build(BuildContext context) {
    const pageBackground = Color(0xFFF7F4EE);

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
            final staffRole = normalizeStaffRole(access.staffRole);
            final hasStaffAccess = isStaffRoleActive(staffRole);

            final businessStatus = business == null
                ? settings.wholesaleApplicationsEnabled
                    ? 'Apply'
                    : 'Paused'
                : business.isApproved
                    ? settings.wholesaleWorkspaceEnabled
                        ? 'Approved'
                        : 'Paused'
                    : businessAccountStatusLabel(business.status);

            final businessStatusColor = business?.isApproved == true
                ? const Color(0xFF2C754A)
                : business == null && !settings.wholesaleApplicationsEnabled
                    ? const Color(0xFF78817D)
                    : businessAccountStatusColor(business?.status);

            final farmerStatus = farmer == null
                ? settings.farmerApplicationsEnabled
                    ? 'Apply'
                    : 'Paused'
                : farmer.isApproved
                    ? settings.farmerWorkspaceEnabled
                        ? 'Approved'
                        : 'Paused'
                    : farmer.statusLabel;

            final farmerStatusColor = farmer?.isApproved == true
                ? const Color(0xFF2C754A)
                : farmer == null && !settings.farmerApplicationsEnabled
                    ? const Color(0xFF78817D)
                    : FarmColors.warning;

            return RefreshIndicator(
              onRefresh: _reload,
              color: const Color(0xFF0B4C36),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth >= 760;
                  final horizontal = isTablet ? 34.0 : 14.0;
                  final maxContentWidth =
                      constraints.maxWidth > 980 ? 920.0 : constraints.maxWidth;

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      0,
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
                              _RealPhotoWorkspaceHero(
                                firstName: _firstName,
                                photoUrl: _heroPhoto,
                                compact: !isTablet,
                                onRefresh: _reload,
                                onSignOut: _signOut,
                              ),
                              const SizedBox(height: 16),
                              const _ProfessionalVerifiedBanner(),
                              const SizedBox(height: 28),
                              const Text(
                                'YOUR WORKSPACES',
                                style: TextStyle(
                                  color: Color(0xFF707B76),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.2,
                                ),
                              ),
                              const SizedBox(height: 7),
                              const Text(
                                'Choose your workspace',
                                style: TextStyle(
                                  color: Color(0xFF103F2F),
                                  fontSize: 28,
                                  height: 1.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.75,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Access the right tools for what you want to do today.',
                                style: TextStyle(
                                  color: Color(0xFF68716D),
                                  fontSize: 12.4,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 18),
                              _BalancedWorkspaceGrid(
                                children: [
                                  _BalancedPhotoWorkspaceCard(
                                    photoUrl: _customerPhoto,
                                    title: 'Customer Shopping',
                                    subtitle: 'Shop fresh produce',
                                    status: 'Available',
                                    statusColor: const Color(0xFF2C754A),
                                    onTap: _openCustomerWorkspace,
                                  ),
                                  _BalancedPhotoWorkspaceCard(
                                    photoUrl: _wholesalePhoto,
                                    title: 'Wholesale Business',
                                    subtitle: business?.isApproved == true
                                        ? 'Buy for your business'
                                        : 'Apply for wholesale access or review your status.',
                                    status: businessStatus,
                                    statusColor: businessStatusColor,
                                    onTap: () => _open(
                                      const BusinessWholesaleHubScreen(),
                                    ),
                                  ),
                                  _BalancedPhotoWorkspaceCard(
                                    photoUrl: _farmerPhoto,
                                    title: 'Farmer Partner',
                                    subtitle: farmer?.isApproved == true
                                        ? 'Supply HPJ'
                                        : 'Apply to supply HPJ or review your status.',
                                    status: farmerStatus,
                                    statusColor: farmerStatusColor,
                                    onTap: () => _open(
                                      const FarmerAccessGate(),
                                    ),
                                  ),
                                  if (hasStaffAccess)
                                    _BalancedPhotoWorkspaceCard(
                                      photoUrl: _staffPhoto,
                                      title: 'HPJ Staff & Operations',
                                      subtitle:
                                          _balancedStaffSubtitle(staffRole),
                                      status: staffRoleDisplayLabel(staffRole),
                                      statusColor: const Color(0xFF526763),
                                      onTap: () => _open(
                                        const AdminDashboardScreen(),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const _ProfessionalAccountNote(),
                              const SizedBox(height: 14),
                              const _ProfessionalBenefitsFooter(),
                              const SizedBox(height: 12),
                              const _WorkspaceLegalFooter(),
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

String _balancedStaffSubtitle(String role) {
  switch (normalizeStaffRole(role)) {
    case 'owner':
      return 'Manage operations';
    case 'manager':
      return 'Manage operations';
    case 'packer':
      return 'Packing & fulfilment';
    case 'delivery':
      return 'Deliveries';
    case 'inventory':
      return 'Inventory & warehouse';
    case 'support':
      return 'Customer support';
    default:
      return 'HPJ operations';
  }
}

class _RealPhotoWorkspaceHero extends StatelessWidget {
  final String firstName;
  final String photoUrl;
  final bool compact;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onSignOut;

  const _RealPhotoWorkspaceHero({
    required this.firstName,
    required this.photoUrl,
    required this.compact,
    required this.onRefresh,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 306 : 302,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(compact ? 0 : 28),
          bottomRight: Radius.circular(compact ? 0 : 28),
        ),
        color: const Color(0xFF174334),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF15392E).withOpacity(0.14),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            photoUrl,
            fit: BoxFit.cover,
            alignment: const Alignment(0.15, 0),
            filterQuality: FilterQuality.medium,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const ColoredBox(
                color: Color(0xFF214D3B),
              );
            },
            errorBuilder: (_, __, ___) {
              return const ColoredBox(
                color: Color(0xFF214D3B),
              );
            },
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFF092F24).withOpacity(0.86),
                  const Color(0xFF092F24).withOpacity(0.50),
                  const Color(0xFF092F24).withOpacity(0.10),
                ],
                stops: const [0, 0.48, 0.84],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.06),
                  Colors.transparent,
                  Colors.black.withOpacity(0.15),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Row(
              children: [
                Container(
                  width: 94,
                  height: 56,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.78),
                    ),
                  ),
                  child: Image.asset(
                    'lib/assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.eco_outlined,
                      color: Color(0xFF0C4C36),
                      size: 30,
                    ),
                  ),
                ),
                const Spacer(),
                _PhotoHeroAction(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Refresh',
                  onTap: () {
                    onRefresh();
                  },
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  tooltip: 'Account',
                  onSelected: (value) {
                    if (value == 'sign_out') {
                      onSignOut();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'sign_out',
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            size: 19,
                          ),
                          SizedBox(width: 8),
                          Text('Sign out'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.94),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF0C4C36),
                      size: 23,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: compact ? 34 : 260,
            bottom: 25,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    height: 1.0,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  firstName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 39,
                    height: 0.96,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.1,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Together we grow a healthier Jamaica.',
                  maxLines: 2,
                  style: TextStyle(
                    color: Color(0xFFF2F4EF),
                    fontSize: 13.3,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
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

class _PhotoHeroAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _PhotoHeroAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.94),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              color: const Color(0xFF0C4C36),
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfessionalVerifiedBanner extends StatelessWidget {
  const _ProfessionalVerifiedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0A553A),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF153D31).withOpacity(0.13),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 49,
            height: 49,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your account is verified and secure',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'All approved workspaces stay connected to your HPJ account.',
                  style: TextStyle(
                    color: Color(0xFFD4E3DB),
                    fontSize: 11.2,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.lock_outline_rounded,
            color: Color(0xFFE3E9E5),
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _BalancedWorkspaceGrid extends StatelessWidget {
  final List<Widget> children;

  const _BalancedWorkspaceGrid({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Two large visual tiles on normal phones and tablets.
        // Only fall back to one column on exceptionally narrow layouts.
        final oneColumn = constraints.maxWidth < 330;
        final columns = oneColumn ? 1 : 2;
        final gap = oneColumn ? 12.0 : 12.0;
        final width = oneColumn
            ? constraints.maxWidth
            : (constraints.maxWidth - gap) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: 12,
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

class _BalancedPhotoWorkspaceCard extends StatelessWidget {
  final String photoUrl;
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final VoidCallback onTap;
  final bool isCurrent;
  final String actionLabel;

  const _BalancedPhotoWorkspaceCard({
    required this.photoUrl,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.onTap,
    this.isCurrent = false,
    this.actionLabel = 'Open',
  });

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF0B4C36);
    const ink = Color(0xFF183D30);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 210;
        final cardHeight = compact ? 214.0 : 224.0;
        final imageHeight = compact ? 94.0 : 104.0;

        return Semantics(
          button: true,
          label: '$title. $subtitle. $status.',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(23),
              onTap: onTap,
              child: Container(
                height: cardHeight,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? const Color(0xFFF1F8F1)
                      : const Color(0xFFFFFEFB),
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(
                    color: isCurrent ? forest : const Color(0xFFE0DDD4),
                    width: isCurrent ? 1.7 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF183D30).withOpacity(
                        isCurrent ? 0.12 : 0.08,
                      ),
                      blurRadius: isCurrent ? 24 : 20,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: imageHeight,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            filterQuality: FilterQuality.medium,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const ColoredBox(
                                color: Color(0xFFE8EFEA),
                              );
                            },
                            errorBuilder: (_, __, ___) {
                              return const ColoredBox(
                                color: Color(0xFFE8EFEA),
                                child: Center(
                                  child: Icon(
                                    Icons.grid_view_rounded,
                                    color: forest,
                                    size: 30,
                                  ),
                                ),
                              );
                            },
                          ),
                          const Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x00000000),
                                    Color(0x1A000000),
                                    Color(0x66000000),
                                  ],
                                  stops: [0, 0.62, 1],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: _BalancedStatusPill(
                              label: status,
                              color: statusColor,
                              onPhoto: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 12 : 14,
                          12,
                          compact ? 10 : 12,
                          11,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ink,
                                fontSize: compact ? 14.2 : 15.2,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.25,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFF69736E),
                                fontSize: compact ? 10.2 : 10.7,
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Text(
                                  actionLabel,
                                  style: TextStyle(
                                    color: forest,
                                    fontSize: compact ? 10.2 : 10.8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF3EC),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Icon(
                                    isCurrent
                                        ? Icons.check_rounded
                                        : Icons.arrow_forward_rounded,
                                    color: forest,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
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

class _BalancedStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool onPhoto;

  const _BalancedStatusPill({
    required this.label,
    required this.color,
    this.onPhoto = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 84,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color:
            onPhoto ? Colors.white.withOpacity(0.94) : color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(999),
        border:
            onPhoto ? Border.all(color: Colors.white.withOpacity(0.70)) : null,
        boxShadow: onPhoto
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 8.8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalAccountNote extends StatelessWidget {
  const _ProfessionalAccountNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4EC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD9E2D5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF183D30).withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.78),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_outlined,
              color: Color(0xFF0B4C36),
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'One account. Many possibilities.',
                  style: TextStyle(
                    color: Color(0xFF104531),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Switch workspaces without changing your approved permissions.',
                  style: TextStyle(
                    color: Color(0xFF65706B),
                    fontSize: 10.9,
                    height: 1.35,
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

class _ProfessionalBenefitsFooter extends StatelessWidget {
  const _ProfessionalBenefitsFooter();

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final benefits = [
      _ProfessionalBenefit(
        icon: Icons.shield_outlined,
        title: 'Secure',
        subtitle: 'Trust Center',
        onTap: () => _open(context, const TrustCenterScreen()),
      ),
      _ProfessionalBenefit(
        icon: Icons.eco_outlined,
        title: 'About',
        subtitle: 'Our story',
        onTap: () => _open(context, const AboutHpjScreen()),
      ),
      _ProfessionalBenefit(
        icon: Icons.contact_support_outlined,
        title: 'Contact',
        subtitle: 'Reach HPJ',
        onTap: () => _open(context, const ContactHpjScreen()),
      ),
      _ProfessionalBenefit(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Chat',
        subtitle: 'Customer Care',
        onTap: () => _open(
          context,
          const SupportScreen(initialSubject: 'Customer care'),
        ),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAF6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7E4DE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF183D30).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var index = 0; index < benefits.length; index++) ...[
            Expanded(child: benefits[index]),
            if (index != benefits.length - 1)
              Container(
                width: 1,
                height: 48,
                color: const Color(0xFFE7E4DE),
              ),
          ],
        ],
      ),
    );
  }
}

class _WorkspaceLegalFooter extends StatelessWidget {
  const _WorkspaceLegalFooter();

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  Widget _link(
    BuildContext context,
    String label,
    Widget screen,
  ) {
    return TextButton(
      onPressed: () => _open(context, screen),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF66706B),
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 2),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 2,
            runSpacing: 0,
            children: [
              _link(context, 'About', const AboutHpjScreen()),
              _link(context, 'Contact', const ContactHpjScreen()),
              _link(context, 'Terms', const TermsOfServiceScreen()),
              _link(context, 'Privacy', const PrivacyPolicyScreen()),
              _link(context, 'Refunds', const RefundPolicyScreen()),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${AppConfig.appName} • v${AppConfig.appVersion}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF969C98),
              fontSize: 8.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalBenefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfessionalBenefit({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF0B4C36),
                    size: 19,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF104531),
                    fontSize: 10.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF7D8782),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
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

class _WorkspaceLoadingView extends StatelessWidget {
  const _WorkspaceLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
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
          'Your customer shop is still available. Try again to reload wholesale, farmer and staff access.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: FarmColors.mutedText,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 22),
        PrimaryFarmButton(
          label: 'Continue as Customer',
          onPressed: onCustomerSelected,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try Again'),
        ),
        TextButton(
          onPressed: onSignOut,
          child: const Text('Sign out'),
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

class PublicLandingScreen extends StatelessWidget {
  final VoidCallback onEnterMarket;
  final VoidCallback onAuth;

  const PublicLandingScreen({
    super.key,
    required this.onEnterMarket,
    required this.onAuth,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: FarmColors.background,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            22,
            22,
            22,
            24 + bottomPadding,
          ),
          children: [
            Center(
              child: Container(
                width: 98,
                height: 98,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: FarmColors.line,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: FarmColors.shadow.withOpacity(0.07),
                      blurRadius: 20,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: Image.asset(
                  'lib/assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.eco_outlined,
                    size: 54,
                    color: FarmColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'The Harvest Place Ja',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FarmColors.ink,
                fontSize: 29,
                height: 1.04,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fresh Jamaican produce, simple ordering, and trusted farm connections.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FarmColors.mutedText,
                fontSize: 14.1,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            const _LandingHeroCard(),
            const SizedBox(height: 16),
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _LandingTrustPill(
                  icon: Icons.visibility_outlined,
                  label: 'Browse freely',
                ),
                _LandingTrustPill(
                  icon: Icons.lock_outline,
                  label: 'Secure checkout',
                ),
                _LandingTrustPill(
                  icon: Icons.receipt_long_outlined,
                  label: 'Track orders',
                ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryFarmButton(
              label: 'Enter Market',
              onPressed: onEnterMarket,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.person_outline),
              label: const Text(
                'Log in or Create Account',
              ),
              onPressed: onAuth,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4EC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(
                    0xFFDCE4D8,
                  ),
                ),
              ),
              child: const Text(
                'Farmer or wholesale business? Log in with the same HPJ account to access your approved workspace.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF5F6D65),
                  fontSize: 10.2,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                );
              },
              child: const Text('Forgot password?'),
            ),
            const SizedBox(height: 2),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 0,
              children: [
                _LandingPolicyLink(
                  label: 'Terms',
                  builder: (_) => const TermsOfServiceScreen(),
                ),
                _LandingPolicyLink(
                  label: 'Privacy',
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
                _LandingPolicyLink(
                  label: 'Refund Policy',
                  builder: (_) => const RefundPolicyScreen(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LandingHeroCard extends StatelessWidget {
  const _LandingHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        17,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: FarmColors.primaryDark,
        boxShadow: [
          BoxShadow(
            color: FarmColors.primary.withOpacity(0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fresh from Jamaican farms to you',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.35,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Browse what is available, build your box, and order for pickup or delivery.',
            style: TextStyle(
              color: Color(0xFFE2EEE7),
              fontSize: 12.7,
              height: 1.38,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingTrustPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _LandingTrustPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: FarmColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: FarmColors.green),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 11.8,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: builder),
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
  String? _captchaToken;
  bool hidePassword = true;
  bool isRegister = false;
  String selectedRole = 'customer';
  String selectedCustomerAccountType = 'retail';
  String selectedBusinessType = 'Restaurant / Food Service';
  String? pendingConfirmationEmail;
  bool resendingConfirmation = false;

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
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    businessNameController.dispose();
    businessPhoneController.dispose();
    businessParishController.dispose();
    _captchaController.dispose();
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
    final email = (pendingConfirmationEmail ?? emailController.text)
        .trim()
        .toLowerCase();

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

  Future<void> submit() async {
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;
    final fullName = fullNameController.text.trim();
    final businessName = businessNameController.text.trim();
    final businessPhone = businessPhoneController.text.trim();
    final businessParish = businessParishController.text.trim();

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
                    ? 'Business account created. Confirm your email, then sign in to review your wholesale application.'
                    : selectedRole == 'farmer'
                        ? 'Farmer account created. Confirm your email, then sign in and choose Farmer Partner to finish your application.'
                        : 'Account created. Please check your email and tap the confirmation link before signing in.',
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
                  ? 'Business account created. Your wholesale application is pending review.'
                  : selectedRole == 'farmer'
                      ? 'Account created. Complete your farmer application next.'
                      : 'Account created. You are signed in.',
            ),
          ),
        );

        leavingAuthScreen = true;
        if (widget.returnToPrevious) {
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => selectedRole == 'farmer'
                  ? const FarmerAccessGate(initialTab: 0)
                  : isBusinessRegistration
                      ? const BusinessWholesaleHubScreen(initialTab: 0)
                      : const MainNavigation(initialIndex: 0),
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
        ? 'Sign in to continue with The Harvest Place Ja.'
        : isBusinessRegistration
            ? 'One HPJ login for wholesale shopping, planning and orders.'
            : isFarmerRegistration
                ? 'Create your HPJ account first. Then complete the short farmer application.'
                : 'Fresh Jamaican produce, made easier.';

    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: widget.returnToPrevious
          ? AppBar(
              title: Text(isRegister ? 'Create Account' : 'Sign In'),
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
                                TextField(
                                  controller: businessParishController,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Business parish *',
                                    prefixIcon: Icon(Icons.map_outlined),
                                  ),
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
                        const SizedBox(height: 16),
                        PrimaryFarmButton(
                          label: loading
                              ? 'Please wait...'
                              : (isRegister
                                  ? isBusinessRegistration
                                      ? 'Create Business Account'
                                      : isFarmerRegistration
                                          ? 'Create Farmer Account'
                                          : 'Create Account'
                                  : 'Login'),
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

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
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
  final Set<String> seenRealtimeNotificationIds = <String>{};
  final Map<String, DateTime> realtimeNotificationCooldowns =
      <String, DateTime>{};

  int get cartItemCount => cart.length;

  int authViewVersion = 0;

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
    authStateSubscription = supabase.auth.onAuthStateChange.listen((_) async {
      if (!mounted) return;

      FarmDataCache.clearOrders();

      if (!isLoggedIn) {
        FarmDataCache.clearAll();
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

  @override
  void dispose() {
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

    try {
      final savedIds = await OfflineCartStore.restorePersistentProductIds();
      if (savedIds.isEmpty) return;

      final counts = <String, int>{};
      for (final rawId in savedIds) {
        final id = rawId.trim();
        if (id.isEmpty) continue;
        counts[id] = (counts[id] ?? 0) + 1;
      }

      final fetched = <String, Product>{};
      for (final id in counts.keys) {
        final product = await fetchProductById(id);
        if (product != null && isVisibleCustomerProduct(product)) {
          fetched[id] = product;
        }
      }

      if (!mounted || fetched.isEmpty || cart.isNotEmpty) return;

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

      if (restored.isEmpty) return;
      setState(() {
        cart
          ..clear()
          ..addAll(restored);
      });
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
    if (!kIsWeb) return;
    try {
      final ids = recentlyViewedProducts
          .where(isVisibleCustomerProduct)
          .map((product) => product.id.trim())
          .where((id) => id.isNotEmpty)
          .take(10)
          .join(',');
      farmDebugLog('Recently viewed saved in memory for this session.');
    } catch (error) {
      farmDebugLog('Recently viewed save skipped: $error');
    }
  }

  Future<void> loadRecentlyViewedProducts() async {
    if (!kIsWeb) return;
    try {
      final saved = '';
      final ids = saved
          .split(',')
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .take(10)
          .toList();

      if (ids.isEmpty) return;

      final fetched = await Future.wait<Product?>(
        ids.map(fetchProductById),
      );
      final loaded =
          fetched.whereType<Product>().where(isVisibleCustomerProduct).toList();

      if (!mounted) return;
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
