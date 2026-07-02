part of harvest_place_app;

class FamilyFarmApp extends StatelessWidget {
  const FamilyFarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
  // Supabase auth links open the same Flutter web app page. The app must
  // route password-reset links and signup confirmation links internally.
  bool hasEnteredMarket = AppConfig.hasPasswordRecoveryCallback ||
      AppConfig.hasEmailConfirmationCallback ||
      isLoggedIn;
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

    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;

      if (data.event == AuthChangeEvent.passwordRecovery) {
        setState(() {
          isPasswordRecovery = true;
          isEmailConfirmation = false;
          hasEnteredMarket = true;
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
        emailConfirmationError = null;
        emailConfirmationMessage =
            'Email confirmed. You can continue shopping.';
      });
    } catch (error) {
      AppConfig.cleanAuthCallbackUrl();

      if (!mounted) return;
      setState(() {
        isEmailConfirmation = false;
        hasEnteredMarket = false;
        emailConfirmationError = friendlyAppError(error);
      });
    }
  }

  void enterMarket() {
    if (!mounted) return;
    setState(() => hasEnteredMarket = true);
  }

  Future<void> enterMarketAsGuest() async {
    await clearPrivateSessionStateForGuestBrowsing();
    if (!mounted) return;
    setState(() => hasEnteredMarket = true);
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
      setState(() => hasEnteredMarket = true);
    }
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

    return const MainNavigation();
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
          padding: EdgeInsets.fromLTRB(20, 18, 20, 28 + bottomPadding),
          children: [
            const SizedBox(height: 4),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: FarmColors.line),
                  boxShadow: [
                    BoxShadow(
                      color: FarmColors.shadow.withOpacity(0.08),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Image.asset(
                  'lib/assets/images/logo.png',
                  height: 78,
                  width: 78,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.eco_outlined,
                    size: 58,
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
                fontSize: 31,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              'Fresh local food, simple ordering, and farm updates you can trust.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.5,
                color: FarmColors.mutedText,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            _LandingHeroCard(onEnterMarket: onEnterMarket),
            const SizedBox(height: 16),
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _LandingTrustPill(
                  icon: Icons.visibility_outlined,
                  label: 'Browse first',
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
            const SizedBox(height: 18),
            const _LandingFeatureTile(
              icon: Icons.storefront_outlined,
              title: 'Shop fresh harvests',
              subtitle:
                  'See what is available, low stock, or currently unavailable before you order.',
            ),
            const SizedBox(height: 10),
            const _LandingFeatureTile(
              icon: Icons.local_shipping_outlined,
              title: 'Pickup or delivery',
              subtitle:
                  'Choose the fulfillment option that works best for your schedule.',
            ),
            const SizedBox(height: 10),
            const _LandingFeatureTile(
              icon: Icons.repeat_outlined,
              title: 'Build your weekly box',
              subtitle:
                  'Save favorite repeat items and confirm them when you are ready.',
            ),
            const SizedBox(height: 22),
            PrimaryFarmButton(
              label: 'Enter Market',
              onPressed: onEnterMarket,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.person_outline),
              label: const Text('Log in or Create Account'),
              onPressed: onAuth,
            ),
            const SizedBox(height: 10),
            Text(
              'No account needed to browse. Sign in only when you are ready to checkout or manage orders.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FarmColors.mutedText,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              icon: const Icon(Icons.lock_reset_outlined),
              label: const Text('Forgot password?'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
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
  final VoidCallback onEnterMarket;

  const _LandingHeroCard({required this.onEnterMarket});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEnterMarket,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              FarmColors.primaryDark,
              FarmColors.primary,
              FarmColors.olive,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: FarmColors.primary.withOpacity(0.20),
              blurRadius: 26,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: const Icon(
                    Icons.shopping_basket_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your farm market in your pocket',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.08,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Browse fresh picks, build your box, and get clear updates from order to pickup or delivery.',
                        style: TextStyle(
                          color: Color(0xFFEAF5E7),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.16)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app_outlined, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap Enter Market to start browsing now.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.8,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18),
                ],
              ),
            ),
          ],
        ),
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

class _LandingFeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _LandingFeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FarmColors.line),
        boxShadow: [
          BoxShadow(
            color: FarmColors.shadow.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: FarmColors.lightGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: FarmColors.green, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FarmColors.mutedText,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.2,
                    height: 1.25,
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

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController emailController;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.initialEmail.trim());
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> sendResetLink() async {
    final email = emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: AppConfig.passwordResetRedirectTo,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password reset link sent to $email. Open the newest email, then create your new password.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset failed: $error')),
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
            const SizedBox(height: 22),
            PrimaryFarmButton(
              label: loading ? 'Sending reset link...' : 'Send reset link',
              onPressed: loading ? null : sendResetLink,
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
            const SizedBox(height: 28),
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
  bool loading = false;
  bool isRegister = false;
  String selectedRole = 'customer';

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
    super.dispose();
  }

  Future<void> submit() async {
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;
    final fullName = fullNameController.text.trim();

    if (email.isEmpty ||
        password.trim().isEmpty ||
        (isRegister && fullName.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      if (isRegister) {
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: AppConfig.emailConfirmationRedirectTo,
          data: {
            'full_name': fullName,
            'role': selectedRole,
          },
        );

        FarmDataCache.clearAll();

        if (!mounted) return;

        if (response.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account created. Please check your email and tap the confirmation link before signing in.',
              ),
            ),
          );

          setState(() {
            isRegister = false;
            passwordController.clear();
          });
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created. You are signed in.')),
        );

        if (widget.returnToPrevious) {
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigation()),
            (route) => false,
          );
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        FarmDataCache.clearAll();

        if (!mounted) return;
        if (widget.returnToPrevious) {
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigation()),
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
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: widget.returnToPrevious
          ? AppBar(
              title: Text(isRegister ? 'Create Account' : 'Sign In'),
              backgroundColor: FarmColors.background,
            )
          : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const SizedBox(height: 28),
            const HeroCard(),
            const SizedBox(height: 26),
            Text(
              isRegister ? 'Create your account' : 'Welcome back',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isRegister
                  ? 'Sign up as a customer.'
                  : 'Login to continue shopping fresh farm produce.',
              style: TextStyle(color: FarmColors.mutedText),
            ),
            const SizedBox(height: 22),
            if (isRegister) ...[
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'customer',
                    icon: Icon(Icons.person_outline),
                    label: Text('Customer'),
                  ),
                  ButtonSegment(
                    value: 'farmer',
                    icon: Icon(Icons.agriculture_outlined),
                    label: Text('Farmer'),
                  ),
                ],
                selected: {selectedRole},
                onSelectionChanged: (values) {
                  setState(() => selectedRole = values.first);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            if (!isRegister) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.lock_reset_outlined, size: 18),
                  label: const Text('Forgot Password?'),
                  onPressed: loading
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ForgotPasswordScreen(
                                initialEmail: emailController.text.trim(),
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
                  : (isRegister ? 'Create Account' : 'Login'),
              onPressed: loading ? null : submit,
            ),
            TextButton(
              onPressed: loading
                  ? null
                  : () => setState(() => isRegister = !isRegister),
              child: Text(isRegister
                  ? 'Already have an account? Login'
                  : 'Create account'),
            ),
          ],
        ),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  static const int homeTabIndex = 0;
  static const int shopTabIndex = 1;
  static const int myBoxTabIndex = 2;
  static const int ordersTabIndex = 3;
  static const int adminTabIndex = 4;

  int get accountTabIndex => showAdmin ? 5 : 4;

  int selectedIndex = 0;
  String selectedShopCategory = 'All';
  int shopCategorySelectionVersion = 0;
  final List<Product> cart = [];
  final Set<String> favoriteProductIds = <String>{};
  final Map<String, Product> favoriteProductCache = <String, Product>{};
  static const String recentlyViewedStorageKey =
      'natural_harvest_recently_viewed_product_ids';

  final List<Product> recentlyViewedProducts = [];
  bool checkingAdmin = true;
  bool showAdmin = false;
  dynamic inventoryRealtimeChannel;
  dynamic notificationRealtimeChannel;
  Timer? inventoryRefreshDebounce;
  StreamSubscription<AuthState>? authStateSubscription;
  final Set<String> seenRealtimeNotificationIds = <String>{};

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
    cart.addAll(OfflineCartStore.restore());
    loadRecentlyViewedProducts();
    loadAdminStatus();
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
          showAdmin = false;
          checkingAdmin = false;
          if (selectedIndex == accountTabIndex ||
              selectedIndex == adminTabIndex) {
            selectedIndex = homeTabIndex;
          }
        });
        return;
      }

      await loadAdminStatus();
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
  }

  Future<void> loadAdminStatus() async {
    if (!isLoggedIn) {
      if (!mounted) return;
      setState(() {
        showAdmin = false;
        checkingAdmin = false;
      });
      return;
    }

    final result = await isCurrentUserAdminFromDatabase();
    if (!mounted) return;
    setState(() {
      showAdmin = result;
      checkingAdmin = false;
    });
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

  Future<void> openSignInFromTab() async {
    final didSignIn = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(returnToPrevious: true),
      ),
    );

    if (!mounted) return;
    if (didSignIn == true || isLoggedIn) {
      await loadAdminStatus();
      if (!mounted) return;
      // After the admin check finishes, Account may have shifted to index 5.
      setState(() => selectedIndex = accountTabIndex);
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
              onShopTap: () => setState(() => selectedIndex = 1),
              onOrderPlaced: () {
                setState(() {
                  selectedIndex = 3;
                });
              },
              onInventoryChanged: refreshInventoryViews,
            )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (checkingAdmin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
    }

    final goToShopHome = () => goToShop();

    void goToMyBoxFromProductDetail() {
      Navigator.of(context).popUntil((route) => route.isFirst);
      if (!mounted) return;
      setState(() {
        selectedIndex = myBoxTabIndex;
      });
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
                persistCart();
                FarmDataCache.clearProducts();
                FarmDataCache.clearOrders();
                authViewVersion++;
                selectedIndex = ordersTabIndex;
              });
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
        onShopTap: () => setState(() => selectedIndex = 1),
        onOrderPlaced: () {
          setState(() {
            selectedIndex = 3;
          });
        },
        onInventoryChanged: refreshInventoryViews,
      ),
      OrdersScreen(
        key: ValueKey('orders-$authViewKey'),
        onBackToHome: () {
          if (!mounted) return;
          setState(() => selectedIndex = homeTabIndex);
        },
      ),
      if (showAdmin)
        AdminDashboardScreen(
          onHomeTap: () {
            if (!mounted) return;
            setState(() => selectedIndex = homeTabIndex);
          },
        ),
      AccountScreen(
        favoriteProducts: favoriteProducts,
        recentlyViewedProducts: recentlyViewedProducts,
        onShopTap: goToShopHome,
        showAdmin: showAdmin,
        onSignedOut: () {
          if (!mounted) return;
          setState(() {
            selectedIndex = homeTabIndex;
            showAdmin = false;
            checkingAdmin = false;
          });
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
      if (showAdmin)
        const FarmBottomOption(
          icon: Icon(Icons.local_offer_outlined, size: 28),
          selectedIcon: Icon(Icons.local_offer_rounded, size: 28),
          label: 'Admin',
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
          final tappedAdminTab = showAdmin && index == adminTabIndex;

          if (tappedAccountTab && !isLoggedIn) {
            await openSignInFromTab();
            return;
          }

          if (tappedAdminTab) {
            await loadAdminStatus();
            if (!showAdmin) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Admin permission required.')),
              );
              return;
            }
          }

          setState(() => selectedIndex = index);
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
