// HPJ PHASE 111 — DATABASE-BACKED ADMIN PORTAL WEBSITE ACCESS
// HPJ PHASE 96.1 — WEB SHOP HEADER MY BOX + ORDERS ACTIONS
// HPJ PHASE 95 — PUBLIC QR TRACE ROUTING (WEB)
// HPJ PHASE 91 — GROWTOGETHER HARVEST CIRCLES + GROW SIGNALS (WEB + APP)
// HPJ PHASE 90 — GRO TOGETHER MEAL PULSE SOCIAL MVP (WEB + APP)
// HPJ PHASE 89 — SMOOTH WEBSITE WORKSPACE RESUME (WEB ONLY)
// HPJ PHASE 86 — GLASS CHOOSE-YOUR-PATH OVERFLOW FIX (WEB ONLY)
// HPJ PHASE 85 — PREMIUM TRANSLUCENT CHOOSE-YOUR-PATH PANEL (WEB ONLY)
// HPJ PHASE 84 — COMPACT 4-COLUMN HOMEPAGE MEAL CARDS (WEB ONLY)
// HPJ PHASE 83 — MEAL FOR THE DAY BEFORE HOW HPJ WORKS (WEB ONLY)
// HPJ PHASE 82 — HOMEPAGE MEAL FOR THE DAY LIVE ADMIN CARDS (WEB ONLY)
// HPJ PHASE 77 — PREMIUM JAMAICAN DINNER ARTWORK CAMPAIGN (WEB ONLY)
part of harvest_place_app;
// HPJ POST-LOGIN LANDING — CUSTOMER/FARMER/BUSINESS HOME + ADMIN TODAY — 2026-09-13
// HPJ PHASE 67 — SMALL JAMAICAN DINNER BANNER (WEB ONLY)
// HPJ PHASE 65 — ELITE JAMAICAN DINNER HOMEPAGE CAMPAIGN (WEB ONLY)
// HPJ PHASE 63 — PREMIUM BUILD YOUR BOX HOMEPAGE CAMPAIGN (WEB ONLY)
// HPJ PHASE 60 — SOCIAL-COMMERCE CUSTOMER WEBSITE HEADER
// HPJ PHASE 56 — DIRECT WEBSITE FARMER + BUSINESS ROUTING
// HPJ PHASE 52 — SIGNED-IN PERSON NAME ACROSS WEBSITE HEADERS
// HPJ PHASE 46B — CUSTOMER WEB HEADER SHOWS SIGNED-IN NAME
// HPJ PHASE 46 — WEBSITE HEADER SHOWS SIGNED-IN PERSON NAME
// HPJ PHASE 45 — FRESH BOX BUILDER IS THE WEBSITE PAGE
// HPJ PHASE 44 — WEBSITE NUTRIENT BOX RUNTIME FIX
// HPJ PHASE 39 — WEB STOREFRONT SHELL, APP NAV PRESERVED
// HPJ PHASE 39C — HOME = CUSTOMER HOME, LOGO = PUBLIC HOMEPAGE
// HPJ PHASE 37C — WEB HOME = PUBLIC HOME, CUSTOMER WORKSPACE OPENS SHOP
// HPJ PHASE 37B — WEBSITE CUSTOMER SHOP LIVE, APP FLAG PRESERVED
// HPJ PHASE 37 — LIVE HIGH DEMAND HOMEPAGE MERCHANDISING
// HPJ PHASE 36E — LUXURY MINIMAL HERO SELECTOR
// HPJ PHASE 36D — ELITE MODERN WEBSITE ROLE PANEL
// HPJ PHASE 36C — DIRECT FARMER + BUSINESS SIGNUP PAGES
// HPJ PHASE 36B — SHORT COMMERCE NAV LABELS
// HPJ PHASE 36 HEADER OVERFLOW FIX — responsive desktop commerce nav
// HPJ PREMIUM PHASE 36 — COMMERCE NAV + ROLE-SPECIFIC SIGNUP
// HPJ PHASE 35 COMPILE FIX — Container minHeight moved to BoxConstraints
// HPJ PREMIUM PHASE 35 — EXACT ELITE COMMERCE WEB HOME REFERENCE
// HPJ PREMIUM PHASE 33 — ELITE COMMERCE HOME + GUEST SHOP ENTRY
// HPJ PHASE 31 RUNTIME FIX — bound Start Here desktop row height
// HPJ WEBSITE HOME — logo returns to public homepage
// HPJ PREMIUM PHASE 30 — WEB HOMEPAGE WELCOMING MVP POLISH
// HPJ PREMIUM PHASE 27 — WEB MVP PUBLIC HOMEPAGE

// Root navigator used by Android push-notification taps. Keeping one app-level
// key lets HPJ open the exact secured destination even when the notification
// launches the app from a terminated state.
final GlobalKey<NavigatorState> hpjRootNavigatorKey =
    GlobalKey<NavigatorState>();

// Website-only requests sent from the public homepage into Customer Shop.
// Native/mobile screens do not write to these notifiers.
final ValueNotifier<String?> hpjWebsiteShopSearchRequest =
    ValueNotifier<String?>(null);
final ValueNotifier<String?> hpjWebsiteShopCategoryRequest =
    ValueNotifier<String?>(null);

/// Use the native-app presentation on real mobile builds AND inside a narrow
/// Flutter Web preview such as FlutLab's phone frame. Desktop/tablet website
/// widths stay on the frozen website UI.
bool hpjUseMobileAppPresentation(BuildContext context) {
  if (!kIsWeb) return true;
  return MediaQuery.sizeOf(context).width < 720;
}

final Map<String, Future<String>> _hpjWebsiteNameFutureCache =
    <String, Future<String>>{};

final Map<String, Future<_HpjWebsiteStaffAccess>>
    _hpjWebsiteStaffAccessFutureCache =
    <String, Future<_HpjWebsiteStaffAccess>>{};

class _HpjWebsiteStaffAccess {
  final bool allowed;
  final String role;

  const _HpjWebsiteStaffAccess({
    required this.allowed,
    required this.role,
  });

  static const none = _HpjWebsiteStaffAccess(
    allowed: false,
    role: '',
  );

  bool get isAdminPortal {
    final normalized = normalizeStaffRole(role);
    return normalized == 'owner' ||
        normalized == 'manager' ||
        (allowed && normalized.isEmpty);
  }

  String get menuLabel => isAdminPortal ? 'Admin Portal' : 'Staff Portal';

  String get roleLabel {
    final normalized = normalizeStaffRole(role);
    if (normalized.isEmpty && allowed) return 'Admin';
    return staffRoleDisplayLabel(normalized);
  }
}

Future<_HpjWebsiteStaffAccess> _resolveHpjWebsiteStaffAccess() {
  final user = supabase.auth.currentUser;

  if (user == null) {
    return Future<_HpjWebsiteStaffAccess>.value(
      _HpjWebsiteStaffAccess.none,
    );
  }

  final cached = _hpjWebsiteStaffAccessFutureCache[user.id];
  if (cached != null) return cached;

  final future = () async {
    var role = '';

    try {
      role = normalizeStaffRole(
        await fetchCurrentStaffRole(),
      );
    } catch (_) {
      role = '';
    }

    if (role.isNotEmpty) {
      return _HpjWebsiteStaffAccess(
        allowed: true,
        role: role,
      );
    }

    // Compatibility path for legacy admin_users records. The existing
    // database check also recognizes an approved admin email row.
    try {
      final allowed = await isCurrentUserAdminFromDatabase();
      return _HpjWebsiteStaffAccess(
        allowed: allowed,
        role: '',
      );
    } catch (_) {
      return _HpjWebsiteStaffAccess.none;
    }
  }();

  _hpjWebsiteStaffAccessFutureCache
    ..clear()
    ..[user.id] = future;

  return future;
}

Future<void> _openHpjWebsiteAdminPortal(
  BuildContext context,
) async {
  try {
    if (!isLoggedIn) {
      final didSignIn = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => const LoginScreen(
            returnToPrevious: true,
          ),
        ),
      );

      if (!context.mounted || (didSignIn != true && !isLoggedIn)) {
        return;
      }
    }

    // Visibility is only UX. Revalidate before entering Admin.
    await requireAdminAccess();

    if (!context.mounted) return;

    // Admin always opens on Today/Dashboard after login.
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const AdminDashboardScreen(
          initialSection: 'Dashboard',
        ),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(friendlyAppError(error)),
      ),
    );
  }
}

Future<void> _openHpjWebsiteAccount(
  BuildContext context,
) async {
  if (!isLoggedIn) return;

  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => const MainNavigation(
        initialIndex: 4,
      ),
    ),
  );
}

String _hpjWebsiteMetadataName() {
  final user = supabase.auth.currentUser;
  if (user == null) return '';

  final metadata = user.userMetadata ?? const <String, dynamic>{};

  for (final key in const <String>[
    'full_name',
    'display_name',
    'name',
  ]) {
    final value = metadata[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }

  final firstName = metadata['first_name']?.toString().trim() ?? '';
  final lastName = metadata['last_name']?.toString().trim() ?? '';

  final combined = <String>[
    firstName,
    lastName,
  ].where((part) => part.isNotEmpty).join(' ').trim();

  if (combined.isNotEmpty) return combined;

  final email = user.email?.trim() ?? '';
  if (email.isNotEmpty && email.contains('@')) {
    final local = email.split('@').first.trim();

    if (local.isNotEmpty) {
      return local
          .split(RegExp(r'[._-]+'))
          .where((part) => part.trim().isNotEmpty)
          .map(
            (part) => part.length == 1
                ? part.toUpperCase()
                : '${part[0].toUpperCase()}${part.substring(1)}',
          )
          .join(' ');
    }
  }

  return '';
}

Future<String> _resolveHpjWebsiteSignedInName() {
  final user = supabase.auth.currentUser;
  if (user == null) {
    return Future<String>.value('');
  }

  final cached = _hpjWebsiteNameFutureCache[user.id];
  if (cached != null) return cached;

  final future = () async {
    try {
      final profile = await fetchCurrentCustomerProfile();
      final profileName = profile?.fullName.trim() ?? '';

      if (profileName.isNotEmpty) {
        return profileName;
      }
    } catch (_) {
      // Customer profile may not exist for Farmer/Business accounts.
      // Auth metadata remains the safe website fallback.
    }

    return _hpjWebsiteMetadataName();
  }();

  _hpjWebsiteNameFutureCache
    ..clear()
    ..[user.id] = future;

  return future;
}

String _hpjWebsiteCompactSignedInName(String fullName) {
  final clean = fullName.trim().replaceAll(RegExp(r'\s+'), ' ');

  if (clean.isEmpty) return 'Account';

  final parts =
      clean.split(' ').where((part) => part.trim().isNotEmpty).toList();

  if (parts.isEmpty) return 'Account';

  // Website headers stay compact and premium.
  return parts.first;
}

// =====================================================
// HPJ WEBSITE HOME NAVIGATION
// Website-only canonical Home route.
// The public Welcome page is the website Home.
// =====================================================

// =====================================================
// HPJ PHASE 89 — SMOOTH WEBSITE WORKSPACE ROUTING
//
// Website behavior:
// - Resume the last safe workspace.
// - On first website sign-in, open the workspace that best matches the account.
// - Keep the full Workspaces screen for explicit "Switch workspace" use.
// - Never auto-open Staff/Admin.
// Native/mobile routing remains unchanged.
// =====================================================

bool _hpjCanOpenWebsiteWorkspace(
  OwnerWorkspaceAccessSnapshot access,
  String workspace,
) {
  switch (workspace.trim().toLowerCase()) {
    case 'wholesale':
      // BusinessWholesaleHubScreen still enforces approved/pending/application
      // states. Allowing the route here does not bypass Business permissions.
      return access.businessAccount != null ||
          access.programSettings.wholesaleApplicationsEnabled ||
          access.isApprovedWholesale;

    case 'farmer':
      // FarmerAccessGate remains the permission boundary.
      return access.farmerProfile != null ||
          access.programSettings.farmerApplicationsEnabled ||
          access.isApprovedFarmer;

    case 'customer':
      // The public website always supports the Customer marketplace shell.
      return access.programSettings.customerMarketplaceEnabled || kIsWeb;

    default:
      return false;
  }
}

String _hpjDefaultWebsiteWorkspace(
  OwnerWorkspaceAccessSnapshot access,
) {
  final metadata =
      supabase.auth.currentUser?.userMetadata ?? const <String, dynamic>{};

  final role = (metadata['role'] ?? '').toString().trim().toLowerCase();
  final accountType =
      (metadata['account_type'] ?? '').toString().trim().toLowerCase();

  final businessIdentity = role == 'business' ||
      role == 'wholesale' ||
      accountType == 'business' ||
      accountType == 'wholesale';

  final farmerIdentity = role == 'farmer' || accountType == 'farmer';

  if (businessIdentity && _hpjCanOpenWebsiteWorkspace(access, 'wholesale')) {
    return 'wholesale';
  }

  if (farmerIdentity && _hpjCanOpenWebsiteWorkspace(access, 'farmer')) {
    return 'farmer';
  }

  // If the account clearly has one specialist HPJ workspace and has never
  // chosen a destination before, open that specialist workspace directly.
  if (access.businessAccount != null &&
      access.farmerProfile == null &&
      _hpjCanOpenWebsiteWorkspace(access, 'wholesale')) {
    return 'wholesale';
  }

  if (access.farmerProfile != null &&
      access.businessAccount == null &&
      _hpjCanOpenWebsiteWorkspace(access, 'farmer')) {
    return 'farmer';
  }

  return 'customer';
}

Widget _hpjWebsiteWorkspaceScreen(
  String workspace, {
  int tab = 0,
}) {
  final safeTab = tab.clamp(0, 4).toInt();

  switch (workspace.trim().toLowerCase()) {
    case 'wholesale':
      return HpjManagedWelcomeGate(
        audience: 'business',
        child: BusinessWholesaleHubScreen(
          initialTab: safeTab,
        ),
      );

    case 'farmer':
      return HpjManagedWelcomeGate(
        audience: 'farmer',
        child: FarmerAccessGate(
          initialTab: safeTab,
        ),
      );

    case 'customer':
    default:
      return HpjManagedWelcomeGate(
        audience: 'customer',
        child: MainNavigation(
          initialIndex: safeTab,
        ),
      );
  }
}

Future<void> _openRememberedHpjWebsiteWorkspace(
  BuildContext context, {
  bool forceHome = false,
}) async {
  if (!kIsWeb || !isLoggedIn) return;

  Widget destination;

  try {
    final access = await fetchOwnerWorkspaceAccessSnapshot();
    final preference = await fetchHpjNavigationPreference();

    if (!context.mounted) return;

    if (preference != null) {
      final remembered = preference.lastWorkspace.trim().toLowerCase();

      if (_hpjCanOpenWebsiteWorkspace(access, remembered)) {
        if (forceHome) {
          await saveHpjNavigationPreference(
            workspace: remembered,
            tab: 0,
          );
          if (!context.mounted) return;
        }

        destination = _hpjWebsiteWorkspaceScreen(
          remembered,
          tab: forceHome ? 0 : preference.tabFor(remembered),
        );
      } else {
        // Access changed since the last visit. In this exceptional case the
        // chooser is useful because HPJ should not guess another private role.
        destination = const OwnerWorkspaceSwitcherScreen(
          showCloseButton: true,
        );
      }
    } else {
      final firstWorkspace = _hpjDefaultWebsiteWorkspace(access);

      await saveHpjNavigationPreference(
        workspace: firstWorkspace,
        tab: 0,
      );

      if (!context.mounted) return;

      destination = _hpjWebsiteWorkspaceScreen(firstWorkspace);
    }
  } catch (error) {
    farmDebugLog(
      'Website workspace resume fallback: $error',
    );

    if (!context.mounted) return;

    destination = const OwnerWorkspaceSwitcherScreen(
      showCloseButton: true,
    );
  }

  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => destination,
    ),
  );
}

class _HpjFirstWebsiteWorkspaceEntry extends StatefulWidget {
  final OwnerWorkspaceAccessSnapshot access;

  const _HpjFirstWebsiteWorkspaceEntry({
    required this.access,
  });

  @override
  State<_HpjFirstWebsiteWorkspaceEntry> createState() =>
      _HpjFirstWebsiteWorkspaceEntryState();
}

class _HpjFirstWebsiteWorkspaceEntryState
    extends State<_HpjFirstWebsiteWorkspaceEntry> {
  late final String _workspace;
  late final Widget _destination;

  @override
  void initState() {
    super.initState();

    _workspace = _hpjDefaultWebsiteWorkspace(widget.access);
    _destination = _hpjWebsiteWorkspaceScreen(_workspace);

    // Persist the first automatic website choice once. Future sign-ins then
    // reopen whichever workspace the user last actively used.
    unawaited(
      saveHpjNavigationPreference(
        workspace: _workspace,
        tab: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _destination;
}

Future<void> _openHpjWebsiteAuth(
  BuildContext context, {
  bool createAccount = false,
  String registrationAudience = '',
  bool openWorkspaceAfterAuth = true,
}) async {
  if (!kIsWeb) return;

  // Already signed in: "Open HPJ" should continue where the user left off,
  // not interrupt them with the large workspace chooser.
  if (isLoggedIn) {
    if (openWorkspaceAfterAuth) {
      await _openRememberedHpjWebsiteWorkspace(context);
    }
    return;
  }

  final didSignIn = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => LoginScreen(
        returnToPrevious: true,
        startInRegister: createAccount,
        initialRegistrationAudience: registrationAudience,
      ),
    ),
  );

  if (!context.mounted) return;

  if ((didSignIn == true || isLoggedIn) && openWorkspaceAfterAuth) {
    await _openRememberedHpjWebsiteWorkspace(
      context,
      forceHome: true,
    );
  }
}

class HpjFarmerSignupScreen extends StatelessWidget {
  const HpjFarmerSignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(
      returnToPrevious: true,
      startInRegister: true,
      initialRegistrationAudience: 'farmer',
      lockRegistrationAudience: true,
    );
  }
}

class HpjBusinessSignupScreen extends StatelessWidget {
  const HpjBusinessSignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(
      returnToPrevious: true,
      startInRegister: true,
      initialRegistrationAudience: 'business',
      lockRegistrationAudience: true,
    );
  }
}

Future<void> _openWebsiteFarmerSignup(
  BuildContext context,
) async {
  if (!kIsWeb) return;

  // WEBSITE ROLE ROUTING:
  // Existing signed-in users go straight to Farmer Partner.
  // FarmerAccessGate keeps all existing approval/application logic:
  // approved farmer -> Farmer HQ
  // no profile / pending -> farmer onboarding or access state
  if (isLoggedIn) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const FarmerAccessGate(),
      ),
    );
    return;
  }

  final didAuthenticate = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => const HpjFarmerSignupScreen(),
    ),
  );

  if (!context.mounted) return;

  // If signup created a session immediately, or the user confirmed their
  // email and then signed in from the locked Farmer Signup screen, continue
  // directly into Farmer Partner instead of showing Workspaces.
  if (didAuthenticate == true || isLoggedIn) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const FarmerAccessGate(),
      ),
    );
  }
}

Future<void> _openWebsiteBusinessSignup(
  BuildContext context,
) async {
  if (!kIsWeb) return;

  // WEBSITE ROLE ROUTING:
  // Existing signed-in users go directly to Business / Wholesale.
  // BusinessWholesaleHubScreen retains the existing application,
  // approval, account and wholesale-access behavior.
  if (isLoggedIn) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const BusinessWholesaleHubScreen(),
      ),
    );
    return;
  }

  final didAuthenticate = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => const HpjBusinessSignupScreen(),
    ),
  );

  if (!context.mounted) return;

  // Continue directly into the Business flow after authentication.
  if (didAuthenticate == true || isLoggedIn) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const BusinessWholesaleHubScreen(),
      ),
    );
  }
}

void _openWebsiteJamaicanDinner(
  BuildContext context,
) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => const WeeklyMealIdeasScreen(),
    ),
  );
}

void _openWebsiteNutrientBox(
  BuildContext context,
) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => const HpjWebsiteNutrientBoxScreen(),
    ),
  );
}

Future<void> _openWebsiteWeeklyBox(
  BuildContext context,
) async {
  if (!isLoggedIn) {
    await _openHpjWebsiteAuth(
      context,
      openWorkspaceAfterAuth: false,
    );
  }

  if (!context.mounted || !isLoggedIn) return;

  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => const WeeklyBoxBuilderScreen(),
    ),
  );
}

class HpjWebsiteNutrientBoxScreen extends StatefulWidget {
  const HpjWebsiteNutrientBoxScreen({super.key});

  @override
  State<HpjWebsiteNutrientBoxScreen> createState() =>
      _HpjWebsiteNutrientBoxScreenState();
}

class _HpjWebsiteNutrientBoxScreenState
    extends State<HpjWebsiteNutrientBoxScreen> {
  late Future<List<Product>> _productsFuture;
  int _boxCount = 0;

  @override
  void initState() {
    super.initState();
    _productsFuture = fetchProductsForCustomerUi(
      timeout: const Duration(seconds: 8),
    );
    _boxCount = OfflineCartStore.restore().length;
  }

  void _addProduct(Product product) {
    if (!product.canAddToCart) return;

    final cart = OfflineCartStore.restore();

    if (product.stockQuantity > 0) {
      final alreadyInBox = cart.where((item) => item.id == product.id).length;

      if (alreadyInBox >= product.stockQuantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You already have the available quantity in My Box.',
            ),
          ),
        );
        return;
      }
    }

    cart.add(product);
    OfflineCartStore.save(cart);

    if (isLoggedIn) {
      unawaited(
        saveCartItemForCurrentUser(product),
      );
    }

    if (mounted) {
      setState(() {
        _boxCount = cart.length;
      });
    }
  }

  void _openMyBox() {
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (_) => const MainNavigation(
          initialIndex: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktopWeb = kIsWeb && MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 4,
        title: const Text(
          'Build Your Fresh Box',
          style: TextStyle(
            color: FarmColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _openMyBox,
            icon: const Icon(
              Icons.shopping_bag_outlined,
              size: 17,
            ),
            label: Text('My Box ($_boxCount)'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<Product>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return ListView(
                padding: EdgeInsets.fromLTRB(
                  desktopWeb ? 28 : 20,
                  24,
                  desktopWeb ? 28 : 20,
                  70,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 1120,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BUILD YOUR FRESH BOX',
                            style: TextStyle(
                              color: Color(0xFF8A6A08),
                              fontSize: 8,
                              letterSpacing: 1.25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Build Your Fresh Box',
                            style: TextStyle(
                              color: FarmColors.ink,
                              fontSize: 27,
                              height: 1,
                              letterSpacing: -.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const FarmSkeletonCard(
                            height: 260,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 520,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: FarmCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.refresh_rounded,
                            color: FarmColors.deepGreen,
                            size: 34,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Nutrient Box could not load.',
                            style: TextStyle(
                              color: FarmColors.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Please try loading the fresh marketplace again.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: FarmColors.mutedText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: () {
                              setState(() {
                                _productsFuture = fetchProductsForCustomerUi(
                                  timeout: const Duration(seconds: 8),
                                );
                              });
                            },
                            icon: const Icon(
                              Icons.refresh_rounded,
                            ),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            final products = snapshot.data ?? const <Product>[];

            return ListView(
              padding: EdgeInsets.fromLTRB(
                desktopWeb ? 28 : 20,
                desktopWeb ? 24 : 18,
                desktopWeb ? 28 : 20,
                90,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 1120,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FreshBoxBuilderCard(
                          products: products,
                          onAddProduct: _addProduct,
                          onViewMyBox: _openMyBox,
                          inlineBuilder: true,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFDDE5DD),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: FarmColors.deepGreen,
                                size: 17,
                              ),
                              SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  'Fresh Box uses current HPJ marketplace availability. Nutrition preferences guide the mix but do not replace medical or dietary advice.',
                                  style: TextStyle(
                                    color: FarmColors.mutedText,
                                    fontSize: 9,
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

class HpjWebsiteHomeRoute extends StatelessWidget {
  const HpjWebsiteHomeRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return PublicLandingScreen(
      onEnterWorkspaces: () {
        unawaited(
          _openHpjWebsiteAuth(context),
        );
      },
      onCreateAccount: () {
        unawaited(
          _openHpjWebsiteAuth(
            context,
            createAccount: true,
          ),
        );
      },
      onBrowseMarket: () {
        Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute<void>(
            builder: (_) => const MainNavigation(
              initialIndex: 1,
            ),
          ),
        );
      },
    );
  }
}

void openHpjWebsiteHome(BuildContext context) {
  if (!kIsWeb) return;

  Navigator.of(
    context,
    rootNavigator: true,
  ).pushAndRemoveUntil<void>(
    MaterialPageRoute<void>(
      builder: (_) => const HpjWebsiteHomeRoute(),
    ),
    (route) => false,
  );
}

class HpjWebsiteHomeLogoButton extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final BorderRadius borderRadius;

  const HpjWebsiteHomeLogoButton({
    super.key,
    this.size = 48,
    this.padding = const EdgeInsets.all(5),
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFDCE7D9),
    this.borderRadius = const BorderRadius.all(
      Radius.circular(14),
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'HPJ Website Home',
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: () => openHpjWebsiteHome(context),
          borderRadius: borderRadius,
          mouseCursor: SystemMouseCursors.click,
          child: Container(
            width: size,
            height: size,
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius,
              border: Border.all(
                color: borderColor,
              ),
            ),
            child: Image.asset(
              'lib/assets/images/logo.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.eco_rounded,
                color: FarmColors.deepGreen,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
        final media = MediaQuery.of(context);
        final mobilePresentation = hpjUseMobileAppPresentation(context);
        final systemTextScale = media.textScaler.scale(1.0);

        // Native/mobile HPJ uses a slightly larger baseline so Farmer,
        // Business, Staff and Customer screens remain easy to read on a phone.
        // Desktop/tablet Web keeps the frozen website typography unchanged.
        var appTextScale = systemTextScale;
        if (mobilePresentation) {
          appTextScale = systemTextScale * 1.12;
          if (systemTextScale < 1.45 && appTextScale > 1.45) {
            appTextScale = 1.45;
          }
        }

        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(appTextScale),
          ),
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _syncKeyboardStateSafely(),
            child: child ?? const SizedBox.shrink(),
          ),
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
  final bool forceWorkspaceHome;
  final bool forceWelcome;

  const AuthGate({
    super.key,
    this.forceWorkspaceHome = false,
    this.forceWelcome = false,
  });

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

    // A blocked Customer workspace can return to the public welcome page
    // without signing out or immediately routing back to the blocked tab.
    // Authentication callback flows still take precedence.
    if (widget.forceWelcome &&
        !AppConfig.hasPasswordRecoveryCallback &&
        !AppConfig.hasEmailConfirmationCallback &&
        !AppConfig.hasGoogleOAuthCallback) {
      hasEnteredMarket = false;
      shouldChooseWorkspace = false;
    }

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
    // WEBSITE:
    // Skip the large chooser during normal sign-in/resume.
    // The chooser remains available from explicit "Switch workspace" actions.
    if (kIsWeb) {
      if (preference != null) {
        final remembered = preference.lastWorkspace.trim().toLowerCase();

        if (_hpjCanOpenWebsiteWorkspace(access, remembered)) {
          return _hpjWebsiteWorkspaceScreen(
            remembered,
            tab: widget.forceWorkspaceHome ? 0 : preference.tabFor(remembered),
          );
        }

        // A stale/revoked remembered role is the one case where asking the user
        // to choose again is safer than silently guessing another workspace.
        return const OwnerWorkspaceSwitcherScreen(
          showCloseButton: false,
        );
      }

      // First website entry: open the account's natural workspace and remember
      // it. No full-screen workspace interruption.
      return _HpjFirstWebsiteWorkspaceEntry(
        access: access,
      );
    }

    // NATIVE / MOBILE:
    // Preserve the existing selector and resume behavior unchanged.
    if (preference != null) {
      switch (preference.lastWorkspace) {
        case 'farmer':
          if (access.isApprovedFarmer &&
              access.programSettings.farmerWorkspaceEnabled) {
            return HpjManagedWelcomeGate(
              audience: 'farmer',
              child: FarmerAccessGate(
                initialTab:
                    widget.forceWorkspaceHome ? 0 : preference.farmerTab,
              ),
            );
          }
          break;

        case 'wholesale':
          if (access.isApprovedWholesale &&
              access.programSettings.wholesaleWorkspaceEnabled) {
            return HpjManagedWelcomeGate(
              audience: 'business',
              child: BusinessWholesaleHubScreen(
                initialTab:
                    widget.forceWorkspaceHome ? 0 : preference.wholesaleTab,
              ),
            );
          }
          break;

        case 'customer':
          if (access.programSettings.customerMarketplaceEnabled || kIsWeb) {
            return HpjManagedWelcomeGate(
              audience: 'customer',
              child: MainNavigation(
                initialIndex:
                    widget.forceWorkspaceHome ? 0 : preference.customerTab,
              ),
            );
          }
          break;

        default:
          break;
      }

      // MOBILE APP M1:
      // A stale specialist destination should never force the user through a
      // separate workspace chooser. Fall back to the safe Customer app; the
      // signed-in account menu exposes every approved portal from there.
      return const HpjManagedWelcomeGate(
        audience: 'customer',
        child: MainNavigation(),
      );
    }

    // MOBILE APP M1:
    // First sign-in now enters HPJ as one clean app. Customer is the safe
    // default portal; Farmer, Business and Staff/Admin are available from the
    // signed-in account menu when authorized.
    if (access.programSettings.customerMarketplaceEnabled) {
      return const HpjManagedWelcomeGate(
        audience: 'customer',
        child: MainNavigation(),
      );
    }

    if (access.isApprovedFarmer &&
        access.programSettings.farmerWorkspaceEnabled) {
      return const HpjManagedWelcomeGate(
        audience: 'farmer',
        child: FarmerAccessGate(),
      );
    }

    if (access.isApprovedWholesale &&
        access.programSettings.wholesaleWorkspaceEnabled) {
      return const HpjManagedWelcomeGate(
        audience: 'business',
        child: BusinessWholesaleHubScreen(),
      );
    }

    return const HpjManagedWelcomeGate(
      audience: 'customer',
      child: MainNavigation(),
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
          if (kIsWeb) {
            return const OwnerWorkspaceSwitcherScreen(
              showCloseButton: false,
            );
          }
          return const HpjManagedWelcomeGate(
            audience: 'customer',
            child: MainNavigation(),
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
    // HPJ Phase 95: a printed packing QR can open a privacy-safe provenance
    // passport without forcing the recipient to sign in. Customer identity,
    // address, payment and private order data are never exposed by this route.
    if (kIsWeb) {
      final traceToken = Uri.base.queryParameters['hpj_trace']?.trim() ?? '';
      if (traceToken.isNotEmpty) {
        return HpjPublicTracePassportScreen(traceToken: traceToken);
      }

      // Phase 113 — public Meal Pulse social-share links. Shared meals open
      // directly without requiring sign-in; Like/Comment/Follow still use the
      // normal Meal Pulse authentication gate.
      final sharedMealId = Uri.base.queryParameters['meal']?.trim() ?? '';
      if (sharedMealId.isNotEmpty) {
        return HpjMealPulseScreen(initialPostId: sharedMealId);
      }
    }

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
        onBrowseMarket: () {
          if (!mounted) return;
          setState(() {
            hasEnteredMarket = true;
            shouldChooseWorkspace = false;
          });
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
                  width: 30,
                  height: 30,
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
        builder: (_) => const HpjManagedWelcomeGate(
          audience: 'customer',
          child: MainNavigation(),
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const pageBackground = Color(0xFFF8F5EF);

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
            final hasStaffAccess = access.hasStaffAccess;

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

            final customerEnabled = settings.isWorkspaceLive(
              'customer',
              website: kIsWeb,
            );

            return RefreshIndicator(
              onRefresh: _reload,
              color: const Color(0xFF0A4B35),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth >= 760;
                  final horizontal = isTablet ? 32.0 : 18.0;
                  final maxContentWidth =
                      constraints.maxWidth > 920 ? 820.0 : constraints.maxWidth;

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      12,
                      horizontal,
                      30,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: maxContentWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PremiumWorkspaceTopBar(
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
                              const SizedBox(height: 24),
                              const _PremiumWorkspaceHeading(),
                              const SizedBox(height: 18),
                              const _PremiumSecurityStrip(),
                              const SizedBox(height: 22),
                              _PremiumWorkspaceGrid(
                                children: [
                                  _PremiumWorkspaceCard(
                                    photoUrl: _customerPhoto,
                                    title: 'Customer Shopping',
                                    subtitle: 'Shop fresh produce',
                                    status: customerEnabled
                                        ? 'Current'
                                        : 'Coming Soon',
                                    statusColor: customerEnabled
                                        ? const Color(0xFF0B5A3F)
                                        : const Color(0xFF78817D),
                                    highlighted: customerEnabled,
                                    icon: Icons.shopping_basket_outlined,
                                    onTap: _openCustomerWorkspace,
                                  ),
                                  _PremiumWorkspaceCard(
                                    photoUrl: _wholesalePhoto,
                                    title: 'Wholesale Business',
                                    subtitle: business?.isApproved == true
                                        ? 'Orders, pricing & planning'
                                        : 'Apply or review access',
                                    status: businessStatus,
                                    statusColor: businessStatusColor,
                                    icon: Icons.storefront_outlined,
                                    onTap: () => _open(
                                      const HpjManagedWelcomeGate(
                                        audience: 'business',
                                        child: BusinessWholesaleHubScreen(),
                                      ),
                                    ),
                                  ),
                                  _PremiumWorkspaceCard(
                                    photoUrl: _farmerPhoto,
                                    title: 'Farmer Partner',
                                    subtitle: farmer?.isApproved == true
                                        ? 'Supply, collections & earnings'
                                        : 'Apply or review access',
                                    status: farmerStatus,
                                    statusColor: farmerStatusColor,
                                    icon: Icons.agriculture_outlined,
                                    onTap: () => _open(
                                      const HpjManagedWelcomeGate(
                                        audience: 'farmer',
                                        child: FarmerAccessGate(),
                                      ),
                                    ),
                                  ),
                                  if (hasStaffAccess)
                                    _PremiumWorkspaceCard(
                                      photoUrl: _staffPhoto,
                                      title: 'HPJ Staff & Operations',
                                      subtitle:
                                          _premiumStaffSubtitle(staffRole),
                                      status: '',
                                      statusColor: const Color(0xFF0B4C36),
                                      icon: Icons.groups_2_outlined,
                                      onTap: () => _open(
                                        const AdminDashboardScreen(),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              const _PremiumOneAccountCard(),
                              const SizedBox(height: 14),
                              const _PremiumBenefitsBar(),
                              const SizedBox(height: 16),
                              const _PremiumWorkspaceLegalFooter(),
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

String _premiumStaffSubtitle(String role) {
  switch (normalizeStaffRole(role)) {
    case 'owner':
      return 'Full business control';
    case 'manager':
      return 'Orders & operations';
    case 'packer':
      return 'Packing & fulfilment';
    case 'delivery':
      return 'Delivery operations';
    case 'inventory':
      return 'Stock & warehouse';
    case 'support':
      return 'Customer support';
    default:
      return 'Operations workspace';
  }
}

class _PremiumWorkspaceTopBar extends StatelessWidget {
  final Future<void> Function() onSignOut;
  final VoidCallback onOpenTrust;
  final VoidCallback onOpenAbout;
  final VoidCallback onOpenSupport;
  final VoidCallback onOpenNotifications;

  const _PremiumWorkspaceTopBar({
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
          width: 58,
          height: 58,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFEFC),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFE5E0D6)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF153A2E).withOpacity(0.075),
                blurRadius: 20,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Image.asset(
            'lib/assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.eco_outlined,
              color: forest,
              size: 30,
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workspaces',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: forest,
                  fontSize: 24,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.65,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'The Harvest Place Ja',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF7B817D),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        _PremiumCircleAction(
          tooltip: 'Notifications',
          icon: Icons.notifications_none_rounded,
          onTap: onOpenNotifications,
        ),
        const SizedBox(width: 7),
        PopupMenuButton<String>(
          tooltip: 'Menu',
          color: const Color(0xFFFFFEFC),
          elevation: 14,
          constraints: const BoxConstraints(minWidth: 270, maxWidth: 315),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
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
              height: 62,
              child: _PremiumMenuItem(
                icon: Icons.shield_outlined,
                label: 'Trust & Security',
              ),
            ),
            PopupMenuDivider(height: 1),
            PopupMenuItem<String>(
              value: 'about',
              height: 62,
              child: _PremiumMenuItem(
                icon: Icons.info_outline_rounded,
                label: 'About The Harvest Place Ja',
              ),
            ),
            PopupMenuDivider(height: 1),
            PopupMenuItem<String>(
              value: 'support',
              height: 62,
              child: _PremiumMenuItem(
                icon: Icons.support_agent_rounded,
                label: 'Help & Support',
              ),
            ),
            PopupMenuDivider(height: 1),
            PopupMenuItem<String>(
              value: 'sign_out',
              height: 62,
              child: _PremiumMenuItem(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                destructive: true,
              ),
            ),
          ],
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFEFC),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE3DED4)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF153A2E).withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.menu_rounded,
              color: forest,
              size: 27,
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumCircleAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _PremiumCircleAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFFFFEFC),
        shape: CircleBorder(
          side: BorderSide(color: const Color(0xFFE3DED4)),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(
              icon,
              color: const Color(0xFF073F2C),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool destructive;

  const _PremiumMenuItem({
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
        Icon(icon, color: color, size: 23),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumWorkspaceHeading extends StatelessWidget {
  const _PremiumWorkspaceHeading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your workspace',
          style: TextStyle(
            color: Color(0xFF073F2C),
            fontSize: 34,
            height: 0.98,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.15,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'One account. Switch anytime.',
          style: TextStyle(
            color: Color(0xFF747B77),
            fontSize: 15.5,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PremiumSecurityStrip extends StatelessWidget {
  const _PremiumSecurityStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF0A5038),
            Color(0xFF0D6344),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B4A35).withOpacity(0.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your HPJ account stays connected',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Your approved access follows you across workspaces.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFD7E7DE),
                    fontSize: 10.7,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.lock_outline_rounded,
            color: Color(0xFFE5EFEA),
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _PremiumWorkspaceGrid extends StatelessWidget {
  final List<Widget> children;

  const _PremiumWorkspaceGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final oneColumn = constraints.maxWidth < 315;
        final gap = oneColumn ? 12.0 : 13.0;
        final width =
            oneColumn ? constraints.maxWidth : (constraints.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
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

class _PremiumWorkspaceCard extends StatelessWidget {
  final String photoUrl;
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final IconData icon;
  final bool highlighted;
  final VoidCallback onTap;

  const _PremiumWorkspaceCard({
    required this.photoUrl,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF073F2C);

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 150;
        final cardHeight = narrow ? 258.0 : 286.0;
        final imageHeight = narrow ? 169.0 : 191.0;

        return Semantics(
          button: true,
          label: [
            title,
            subtitle,
            if (status.trim().isNotEmpty) status.trim(),
          ].join('. '),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: cardHeight,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFEFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: highlighted
                        ? const Color(0xFF0A553A)
                        : const Color(0xFFE4DFD5),
                    width: highlighted ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF173B30).withOpacity(
                        highlighted ? 0.12 : 0.075,
                      ),
                      blurRadius: highlighted ? 24 : 18,
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
                            filterQuality: FilterQuality.high,
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
                                    Icons.image_outlined,
                                    color: forest,
                                    size: 32,
                                  ),
                                ),
                              );
                            },
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x10000000),
                                  Color(0x00000000),
                                  Color(0x30000000),
                                ],
                                stops: [0.0, 0.60, 1.0],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 11,
                            left: 11,
                            child: Container(
                              width: 38,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.94),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.09),
                                    blurRadius: 9,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                icon,
                                color: forest,
                                size: 20,
                              ),
                            ),
                          ),
                          if (status.trim().isNotEmpty)
                            Positioned(
                              top: 11,
                              right: 11,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 92),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
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
                                    fontSize: 10.4,
                                    fontWeight: FontWeight.w900,
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
                          narrow ? 11 : 14,
                          11,
                          narrow ? 9 : 12,
                          10,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: forest,
                                      fontSize: narrow ? 13.1 : 15.1,
                                      height: 1.05,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: const Color(0xFF777E79),
                                      fontSize: narrow ? 9.1 : 10.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              width: narrow ? 32 : 36,
                              height: narrow ? 32 : 36,
                              decoration: BoxDecoration(
                                color: highlighted
                                    ? const Color(0xFFE5F2E8)
                                    : const Color(0xFFF4F2EC),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                highlighted
                                    ? Icons.check_rounded
                                    : Icons.arrow_forward_rounded,
                                color: forest,
                                size: narrow ? 18 : 20,
                              ),
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

class _PremiumOneAccountCard extends StatelessWidget {
  const _PremiumOneAccountCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5EE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD6E2D4)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFDCECDF),
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
                    fontSize: 14.6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Your permissions and access stay connected.',
                  style: TextStyle(
                    color: Color(0xFF6C7671),
                    fontSize: 11.5,
                    height: 1.3,
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

class _PremiumBenefitsBar extends StatelessWidget {
  const _PremiumBenefitsBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7E0D3)),
      ),
      child: const Row(
        children: [
          Expanded(
            child: _PremiumBenefit(
              icon: Icons.shield_outlined,
              label: 'Secure',
            ),
          ),
          _PremiumBenefitDivider(),
          Expanded(
            child: _PremiumBenefit(
              icon: Icons.insights_outlined,
              label: 'Insightful',
            ),
          ),
          _PremiumBenefitDivider(),
          Expanded(
            child: _PremiumBenefit(
              icon: Icons.bolt_outlined,
              label: 'Efficient',
            ),
          ),
          _PremiumBenefitDivider(),
          Expanded(
            child: _PremiumBenefit(
              icon: Icons.favorite_border_rounded,
              label: 'Community',
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBenefit extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PremiumBenefit({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF0A553A), size: 21),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF173F31),
            fontSize: 9.4,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PremiumBenefitDivider extends StatelessWidget {
  const _PremiumBenefitDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      color: const Color(0xFFE4DED2),
    );
  }
}

class _PremiumWorkspaceLegalFooter extends StatelessWidget {
  const _PremiumWorkspaceLegalFooter();

  void _open(BuildContext context, Widget screen) {
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
    return TextButton(
      onPressed: () => _open(context, screen),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        minimumSize: const Size(0, 34),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF496159),
          fontSize: 10.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _link(context, 'Terms', const TermsOfServiceScreen()),
            const _PremiumFooterDot(),
            _link(context, 'Privacy', const PrivacyPolicyScreen()),
            const _PremiumFooterDot(),
            _link(context, 'Refunds', const RefundPolicyScreen()),
            const _PremiumFooterDot(),
            _link(context, 'FAQ', const HpjFaqScreen()),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${AppConfig.appName} • v${AppConfig.appVersion}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF9B9F9B),
            fontSize: 9.8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PremiumFooterDot extends StatelessWidget {
  const _PremiumFooterDot();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 1),
      child: Text(
        '•',
        style: TextStyle(
          color: Color(0xFFB4B5B1),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
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
  final VoidCallback? onBrowseMarket;

  const PublicLandingScreen({
    super.key,
    required this.onEnterWorkspaces,
    required this.onCreateAccount,
    this.onBrowseMarket,
  });

  @override
  State<PublicLandingScreen> createState() => _PublicLandingScreenState();
}

class _PublicLandingScreenState extends State<PublicLandingScreen> {
  late final Future<String?> _welcomeBackgroundFuture;
  late final Future<List<HomeHeroSlide>> _legacyLandingBackgroundFuture;
  final TextEditingController _websiteSearchController =
      TextEditingController();
  StreamSubscription<AuthState>? _websiteAuthSubscription;

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

    if (kIsWeb) {
      _websiteAuthSubscription = supabase.auth.onAuthStateChange.listen((_) {
        _hpjWebsiteNameFutureCache.clear();
        _hpjWebsiteStaffAccessFutureCache.clear();
        if (!mounted) return;
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _websiteAuthSubscription?.cancel();
    _websiteSearchController.dispose();
    super.dispose();
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

  VoidCallback get _browseMarketAction =>
      widget.onBrowseMarket ?? widget.onEnterWorkspaces;

  String _websiteSignedInName() {
    final user = supabase.auth.currentUser;
    if (user == null) return '';

    final metadata = user.userMetadata ?? const <String, dynamic>{};

    for (final key in const [
      'full_name',
      'display_name',
      'name',
    ]) {
      final value = metadata[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }

    final email = user.email?.trim() ?? '';
    if (email.isNotEmpty && email.contains('@')) {
      final local = email.split('@').first.trim();
      if (local.isNotEmpty) {
        return local
            .split(RegExp(r'[._-]+'))
            .where((part) => part.trim().isNotEmpty)
            .map(
              (part) => part.length == 1
                  ? part.toUpperCase()
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' ');
      }
    }

    return 'My Account';
  }

  void _openWebsiteShopSearch([String? rawQuery]) {
    final query = (rawQuery ?? _websiteSearchController.text).trim();

    if (query.isNotEmpty) {
      hpjWebsiteShopSearchRequest.value = query;
      hpjWebsiteShopCategoryRequest.value = null;
    }

    _browseMarketAction();
  }

  void _openWebsiteShopCategory(String category) {
    final clean = category.trim();
    if (clean.isNotEmpty) {
      hpjWebsiteShopCategoryRequest.value = clean;
      hpjWebsiteShopSearchRequest.value = null;
    }
    _browseMarketAction();
  }

  Widget _webNavLink({
    required String label,
    required VoidCallback onTap,
  }) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: _forest,
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontSize: 11.6,
          fontWeight: FontWeight.w800,
        ),
      ),
      child: Text(label),
    );
  }

  Widget _webBenefit({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFDDE7DA),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C083D2A),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4E5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: _forest,
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _forest,
                    fontSize: 16,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF667268),
                    fontSize: 13,
                    height: 1.45,
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

  Widget _webAudienceCard({
    required IconData icon,
    required String eyebrow,
    required String title,
    required String body,
    required String actionLabel,
    required VoidCallback onTap,
    bool emphasized = false,
  }) {
    final cardColor = emphasized ? const Color(0xFF0B432F) : Colors.white;
    final titleColor = emphasized ? Colors.white : _forest;
    final bodyColor =
        emphasized ? Colors.white.withOpacity(0.80) : const Color(0xFF68736B);

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: emphasized ? const Color(0xFF0B432F) : const Color(0xFFDCE6D9),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10083D2A),
            blurRadius: 34,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: emphasized
                  ? Colors.white.withOpacity(0.12)
                  : const Color(0xFFEAF4E5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: emphasized ? _lime : _forest,
              size: 27,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            eyebrow.toUpperCase(),
            style: TextStyle(
              color: emphasized ? _lime : const Color(0xFF6A8A65),
              fontSize: 10.5,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 23,
              height: 1.05,
              letterSpacing: -0.4,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: TextStyle(
              color: bodyColor,
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 22),
          TextButton.icon(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: emphasized ? Colors.white : _forest,
              padding: EdgeInsets.zero,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
              ),
            ),
            iconAlignment: IconAlignment.end,
            icon: const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
            ),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Widget _webStep({
    required String number,
    required String title,
    required String body,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _gold,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: _forest,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: _forest,
            fontSize: 18,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: const TextStyle(
            color: Color(0xFF68736B),
            fontSize: 13.2,
            height: 1.48,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _desktopPublicWebsite(BuildContext context) {
    const forest = Color(0xFF063E2B);
    const deepForest = Color(0xFF043323);
    const gold = Color(0xFFFFBD25);
    const muted = Color(0xFF667169);
    const line = Color(0xFFE0E8DE);

    final signedInUser = supabase.auth.currentUser;
    final signedIn = signedInUser != null;
    final signedInName = signedIn ? _websiteSignedInName() : '';

    Widget maxWidth(
      Widget child, {
      double width = 1420,
    }) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: width,
          ),
          child: child,
        ),
      );
    }

    Widget roleChoice({
      required String number,
      required String label,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          hoverColor: Colors.white.withOpacity(.055),
          splashColor: Colors.white.withOpacity(.075),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.065),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(.13),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.055),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    number,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.48),
                      fontSize: 8.2,
                      letterSpacing: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFFFC62A),
                          fontSize: 7.2,
                          letterSpacing: 1.28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.0,
                          height: 1.05,
                          letterSpacing: -.18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(.68),
                          fontSize: 8.0,
                          height: 1.18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.085),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(.18),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget roleDivider() {
      return const SizedBox(height: 1);
    }

    Widget benefit({
      required IconData icon,
      required String label,
    }) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 15,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.6,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    Widget step({
      required String number,
      required String title,
      required String body,
    }) {
      return Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: gold,
                shape: BoxShape.circle,
              ),
              child: Text(
                number,
                style: const TextStyle(
                  color: forest,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: forest,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    body,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 8.8,
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Material(
            color: Colors.white,
            elevation: 0,
            child: Container(
              height: 66,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: line,
                  ),
                ),
              ),
              child: maxWidth(
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                  ),
                  child: Row(
                    children: [
                      Tooltip(
                        message: 'Home',
                        child: InkWell(
                          onTap: () => openHpjWebsiteHome(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 5,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 51,
                                  height: 51,
                                  child: Image.asset(
                                    'lib/assets/images/logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.eco_rounded,
                                      color: forest,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'The Harvest Place Ja',
                                      style: TextStyle(
                                        color: forest,
                                        fontSize: 14.2,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Fresh • Local • Jamaican',
                                      style: TextStyle(
                                        color: Color(0xFF55755E),
                                        fontSize: 8.4,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      _webNavLink(
                        label: 'Shop',
                        onTap: _browseMarketAction,
                      ),
                      _webNavLink(
                        label: 'Dinner',
                        onTap: () => _openWebsiteJamaicanDinner(context),
                      ),
                      _webNavLink(
                        label: 'Nutrition',
                        onTap: () => _openWebsiteNutrientBox(context),
                      ),
                      _webNavLink(
                        label: 'Farmer',
                        onTap: () {
                          unawaited(
                            _openWebsiteFarmerSignup(context),
                          );
                        },
                      ),
                      _webNavLink(
                        label: 'Business',
                        onTap: () {
                          unawaited(
                            _openWebsiteBusinessSignup(context),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 228,
                        height: 38,
                        child: TextField(
                          controller: _websiteSearchController,
                          onSubmitted: _openWebsiteShopSearch,
                          textInputAction: TextInputAction.search,
                          style: const TextStyle(
                            color: forest,
                            fontSize: 9.8,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search produce, farms, nutrients...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF7A817D),
                              fontSize: 9.2,
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: IconButton(
                              tooltip: 'Search Shop',
                              onPressed: () => _openWebsiteShopSearch(),
                              icon: const Icon(
                                Icons.search_rounded,
                                color: forest,
                                size: 18,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF3F4F2),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide: const BorderSide(
                                color: Color(0xFFBFD4C4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (signedIn) ...[
                        FutureBuilder<String>(
                          future: _resolveHpjWebsiteSignedInName(),
                          initialData: signedInName,
                          builder: (context, nameSnapshot) {
                            final fullName =
                                (nameSnapshot.data ?? signedInName).trim();

                            final compactName = _hpjWebsiteCompactSignedInName(
                              fullName,
                            );

                            return FutureBuilder<_HpjWebsiteStaffAccess>(
                              future: _resolveHpjWebsiteStaffAccess(),
                              initialData: _HpjWebsiteStaffAccess.none,
                              builder: (context, staffSnapshot) {
                                final staffAccess = staffSnapshot.data ??
                                    _HpjWebsiteStaffAccess.none;

                                return PopupMenuButton<String>(
                                  tooltip: fullName.isEmpty
                                      ? 'Account'
                                      : 'Signed in as $fullName',
                                  position: PopupMenuPosition.under,
                                  onSelected: (value) {
                                    if (value == 'account') {
                                      unawaited(
                                        _openHpjWebsiteAccount(context),
                                      );
                                    } else if (value == 'farmer') {
                                      unawaited(
                                        _openWebsiteFarmerSignup(context),
                                      );
                                    } else if (value == 'business') {
                                      unawaited(
                                        _openWebsiteBusinessSignup(context),
                                      );
                                    } else if (value == 'admin') {
                                      unawaited(
                                        _openHpjWebsiteAdminPortal(context),
                                      );
                                    } else if (value == 'workspaces') {
                                      widget.onEnterWorkspaces();
                                    }
                                  },
                                  itemBuilder: (_) => <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'account',
                                      child: Text('Account'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'farmer',
                                      child: Text('Farmer Portal'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'business',
                                      child: Text('Business Portal'),
                                    ),
                                    if (staffAccess.allowed) ...[
                                      const PopupMenuDivider(),
                                      PopupMenuItem<String>(
                                        value: 'admin',
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons
                                                  .admin_panel_settings_outlined,
                                              size: 19,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    staffAccess.menuLabel,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                  Text(
                                                    staffAccess.roleLabel,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Color(0xFF667169),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const PopupMenuDivider(),
                                    const PopupMenuItem<String>(
                                      value: 'workspaces',
                                      child: Text('Switch workspace'),
                                    ),
                                  ],
                                  child: Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(11),
                                      border: Border.all(
                                        color: staffAccess.allowed
                                            ? const Color(0xFF0B5A3F)
                                            : forest,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          staffAccess.allowed
                                              ? Icons
                                                  .admin_panel_settings_outlined
                                              : Icons.person_outline_rounded,
                                          size: 16,
                                          color: forest,
                                        ),
                                        const SizedBox(width: 7),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 120,
                                          ),
                                          child: Text(
                                            compactName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: forest,
                                              fontSize: 9.8,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 16,
                                          color: forest,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 9),
                        FilledButton(
                          onPressed: widget.onEnterWorkspaces,
                          style: FilledButton.styleFrom(
                            backgroundColor: forest,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          child: const Text('Open HPJ'),
                        ),
                      ] else ...[
                        OutlinedButton(
                          onPressed: widget.onEnterWorkspaces,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: forest,
                            side: const BorderSide(
                              color: forest,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          child: const Text('Sign In'),
                        ),
                        const SizedBox(width: 9),
                        FilledButton(
                          onPressed: widget.onCreateAccount,
                          style: FilledButton.styleFrom(
                            backgroundColor: forest,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          child: const Text('Join HPJ'),
                        ),
                      ],
                    ],
                  ),
                ),
                width: 1580,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 348,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _landingBackground(),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                deepForest.withOpacity(.82),
                                deepForest.withOpacity(.48),
                                deepForest.withOpacity(.08),
                              ],
                              stops: const [
                                0,
                                .50,
                                1,
                              ],
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(.18),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        maxWidth(
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'JAMAICA’S CONNECTED FRESH-PRODUCE MARKETPLACE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.2,
                                          letterSpacing: .95,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Fresh Jamaican produce.',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 39,
                                          height: .98,
                                          letterSpacing: -1.2,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Made easier for everyone.',
                                        style: TextStyle(
                                          color: gold,
                                          fontSize: 39,
                                          height: .98,
                                          letterSpacing: -1.2,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: 590,
                                        child: Text(
                                          'Shop for home, grow your farm business, or source reliable produce for your organisation — all in one local marketplace.',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(.95),
                                            fontSize: 13.2,
                                            height: 1.45,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FilledButton.icon(
                                            onPressed: _browseMarketAction,
                                            style: FilledButton.styleFrom(
                                              backgroundColor: gold,
                                              foregroundColor: forest,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 21,
                                                vertical: 14,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  999,
                                                ),
                                              ),
                                              textStyle: const TextStyle(
                                                fontSize: 11.2,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.shopping_cart_outlined,
                                              size: 17,
                                            ),
                                            label: const Text('Shop Fresh'),
                                          ),
                                          const SizedBox(width: 11),
                                          OutlinedButton.icon(
                                            onPressed: widget.onCreateAccount,
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.white,
                                              side: BorderSide(
                                                color: Colors.white.withOpacity(
                                                  .72,
                                                ),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 21,
                                                vertical: 14,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  999,
                                                ),
                                              ),
                                              textStyle: const TextStyle(
                                                fontSize: 11.2,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.person_add_alt_1_outlined,
                                              size: 17,
                                            ),
                                            label: const Text('Join HPJ'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 25,
                                        runSpacing: 8,
                                        children: [
                                          benefit(
                                            icon: Icons.eco_outlined,
                                            label: 'Local food',
                                          ),
                                          benefit(
                                            icon: Icons.groups_2_outlined,
                                            label: 'Local farms',
                                          ),
                                          benefit(
                                            icon: Icons.favorite_border_rounded,
                                            label: 'Stronger communities',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 34),
                                Expanded(
                                  flex: 4,
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(
                                      17,
                                      13,
                                      17,
                                      13,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFF0A4536)
                                              .withOpacity(.70),
                                          const Color(0xFF06392E)
                                              .withOpacity(.56),
                                          const Color(0xFF0B4637)
                                              .withOpacity(.64),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(26),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(.24),
                                        width: 1.1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(.17),
                                          blurRadius: 30,
                                          offset: const Offset(0, 13),
                                        ),
                                        BoxShadow(
                                          color: const Color(0xFF81C596)
                                              .withOpacity(.10),
                                          blurRadius: 22,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 26,
                                              height: 3,
                                              decoration: BoxDecoration(
                                                color: gold,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                            ),
                                            const SizedBox(width: 9),
                                            Text(
                                              'HPJ MARKETPLACE',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(.62),
                                                fontSize: 7.0,
                                                letterSpacing: 1.5,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        const Text(
                                          'Choose your path',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20.5,
                                            height: 1.0,
                                            letterSpacing: -.55,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'One marketplace. Three ways to use HPJ.',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(.72),
                                            fontSize: 8.9,
                                            height: 1.3,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        roleChoice(
                                          number: '01',
                                          label: 'Shop',
                                          title: 'Shop for home',
                                          subtitle:
                                              'Fresh produce, farms and My Box.',
                                          onTap: _browseMarketAction,
                                        ),
                                        roleDivider(),
                                        roleChoice(
                                          number: '02',
                                          label: 'Farmer',
                                          title: 'Grow with HPJ',
                                          subtitle:
                                              'Share supply and reach new buyers.',
                                          onTap: () {
                                            unawaited(
                                              _openWebsiteFarmerSignup(
                                                context,
                                              ),
                                            );
                                          },
                                        ),
                                        roleDivider(),
                                        roleChoice(
                                          number: '03',
                                          label: 'Business',
                                          title: 'Source with confidence',
                                          subtitle:
                                              'Wholesale buying and supply planning.',
                                          onTap: () {
                                            unawaited(
                                              _openWebsiteBusinessSignup(
                                                context,
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 11,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(.075),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                              color:
                                                  Colors.white.withOpacity(.12),
                                            ),
                                          ),
                                          child: Text(
                                            'Browse first. Sign in only when you need your account.',
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(.66),
                                              fontSize: 7.2,
                                              height: 1.25,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _PublicEliteCommerceShowcase(
                    onShop: _browseMarketAction,
                    onCategory: _openWebsiteShopCategory,
                  ),
                  _HpjMealForTheDaySection(
                    onViewAll: () => _openWebsiteJamaicanDinner(context),
                  ),
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFFEFFFD),
                    child: maxWidth(
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          36,
                          14,
                          36,
                          15,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 255,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'How HPJ Works',
                                    style: TextStyle(
                                      color: forest,
                                      fontSize: 18.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'A simple path from farm to buyer.',
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 9.6,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 22),
                            step(
                              number: '01',
                              title: 'Farmers share supply',
                              body:
                                  'Farmers keep expected produce and harvest timing current in HPJ.',
                            ),
                            Container(
                              width: 1,
                              height: 65,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              color: line,
                            ),
                            step(
                              number: '02',
                              title: 'Customers and businesses buy',
                              body:
                                  'Households shop fresh produce while businesses can order or plan ahead.',
                            ),
                            Container(
                              width: 1,
                              height: 65,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              color: line,
                            ),
                            step(
                              number: '03',
                              title: 'HPJ helps move it forward',
                              body:
                                  'Orders, collection, fulfilment, delivery and support stay connected.',
                            ),
                            const SizedBox(width: 22),
                            Container(
                              width: 235,
                              padding: const EdgeInsets.all(
                                13,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFEAF4E8,
                                ),
                                borderRadius: BorderRadius.circular(
                                  14,
                                ),
                              ),
                              child: const Row(
                                children: [
                                  CircleAvatar(
                                    radius: 19,
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.eco_rounded,
                                      color: forest,
                                      size: 18,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Support Jamaican Farmers',
                                          style: TextStyle(
                                            color: forest,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Every HPJ order helps strengthen local farms, families and businesses.',
                                          style: TextStyle(
                                            color: muted,
                                            fontSize: 7.8,
                                            height: 1.25,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    color: deepForest,
                    child: maxWidth(
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 34,
                          vertical: 17,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 315,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 56,
                                    height: 46,
                                    child: Image.asset(
                                      'lib/assets/images/logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.eco_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'The Harvest Place Ja',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Fresh • Local • Jamaican',
                                        style: TextStyle(
                                          color: Color(0xFFC8E965),
                                          fontSize: 8.2,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Come in. Find what you need.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Shop for home, grow with HPJ as a farmer, or create a business purchasing account.',
                                    style: TextStyle(
                                      color: Color(0xFFD3E3D5),
                                      fontSize: 8.7,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton(
                              onPressed: _browseMarketAction,
                              style: FilledButton.styleFrom(
                                backgroundColor: gold,
                                foregroundColor: forest,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    999,
                                  ),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              child: const Text('Shop Fresh'),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: widget.onCreateAccount,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withOpacity(.60),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    999,
                                  ),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              child: const Text(
                                'Create Account',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF03271C),
                    child: maxWidth(
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 34,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            TextButton(
                              onPressed: () => _openUtility(
                                const AboutHpjScreen(),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white70,
                                textStyle: const TextStyle(
                                  fontSize: 8.8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('About'),
                            ),
                            TextButton(
                              onPressed: () => _openUtility(
                                const TrustCenterScreen(),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white70,
                                textStyle: const TextStyle(
                                  fontSize: 8.8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Trust'),
                            ),
                            TextButton(
                              onPressed: () => _openUtility(
                                const HpjFaqScreen(),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white70,
                                textStyle: const TextStyle(
                                  fontSize: 8.8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('FAQ'),
                            ),
                            TextButton(
                              onPressed: () => _openUtility(
                                const SupportScreen(
                                  initialSubject: 'General enquiry',
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white70,
                                textStyle: const TextStyle(
                                  fontSize: 8.8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Support'),
                            ),
                            TextButton(
                              onPressed: () => _openUtility(
                                const TermsOfServiceScreen(),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white70,
                                textStyle: const TextStyle(
                                  fontSize: 8.8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Terms'),
                            ),
                            TextButton(
                              onPressed: () => _openUtility(
                                const PrivacyPolicyScreen(),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white70,
                                textStyle: const TextStyle(
                                  fontSize: 8.8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Privacy'),
                            ),
                            TextButton(
                              onPressed: () => _openUtility(
                                const RefundPolicyScreen(),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white70,
                                textStyle: const TextStyle(
                                  fontSize: 8.8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Refunds'),
                            ),
                            const Spacer(),
                            Text(
                              '© ${DateTime.now().year} The Harvest Place Ja • Jamaica',
                              style: TextStyle(
                                color: Colors.white.withOpacity(.56),
                                fontSize: 8.6,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _webFooterLink(
    String label,
    VoidCallback onTap,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white.withOpacity(0.72),
          padding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 5,
          ),
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(
            fontSize: 11.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label),
      ),
    );
  }

  // HPJ Welcome MVP: the following widgets only affect the narrow welcome
  // screen. The desktop storefront, workspace gates, auth and Admin-managed
  // background remain exactly as they were.
  Future<void> _welcomeOpenRole(String audience) async {
    if (audience == 'customer') {
      _browseMarketAction();
      return;
    }

    if (kIsWeb) {
      if (audience == 'farmer') {
        await _openWebsiteFarmerSignup(context);
      } else {
        await _openWebsiteBusinessSignup(context);
      }
      return;
    }

    if (isLoggedIn) {
      _openUtility(
        audience == 'farmer'
            ? const FarmerAccessGate()
            : const BusinessWholesaleHubScreen(),
      );
      return;
    }

    // Reuse the established audience-specific registration process. There is
    // no second account and no new auth / database logic on this screen.
    final authenticated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => LoginScreen(
          returnToPrevious: true,
          startInRegister: true,
          initialRegistrationAudience: audience,
          lockRegistrationAudience: true,
        ),
      ),
    );
    if (!mounted) return;
    if (authenticated == true || isLoggedIn) {
      _openUtility(
        audience == 'farmer'
            ? const FarmerAccessGate()
            : const BusinessWholesaleHubScreen(),
      );
    }
  }

  // HPJ WELCOME GLASS — scoped to the mobile landing screen only. The photo
  // is still loaded from Admin -> Welcome Screen Background (with Hero fallback).
  // A real blur and translucent color are used instead of opaque white panels.
  Widget _welcomeGlassPanel({
    required Widget child,
    required Color tint,
    double radius = 22,
    double blur = 13,
    EdgeInsetsGeometry? padding,
    Color? borderColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(.44),
              width: 1.15,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // Branded icons, not generated people/photos. The background is translucent
  // and the existing Customer/Farmer/Business callbacks are preserved.
  Widget _welcomeRoleCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color tint,
    required VoidCallback onTap,
    required double scale,
  }) {
    final isFarmer = label == 'Farmer';
    final isBusiness = label == 'Business';
    final iconColor = isFarmer
        ? const Color(0xFF456B35)
        : isBusiness
            ? const Color(0xFF23564D)
            : _forest;

    return Expanded(
      child: Semantics(
        button: true,
        label: '$label: ${subtitle.replaceAll('\n', ' ')}',
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(17 * scale),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(17 * scale),
            child: Container(
              height: 98 * scale,
              padding: EdgeInsets.symmetric(
                horizontal: 3 * scale,
                vertical: 5 * scale,
              ),
              decoration: BoxDecoration(
                // tint is intentionally translucent: the Admin-managed photo
                // stays visible through each of the three audience cards.
                color: tint,
                borderRadius: BorderRadius.circular(17 * scale),
                border: Border.all(color: Colors.white.withOpacity(.67)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18052216),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: iconColor, size: 24 * scale),
                  SizedBox(height: 5 * scale),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _forest,
                      fontSize: 13.6 * scale,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3 * scale),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF3E5648),
                        fontSize: 10.3 * scale,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _welcomeFooterLink({
    required IconData icon,
    required String label,
    required Widget destination,
    required double scale,
  }) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: () => _openUtility(destination),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 7 * scale, horizontal: 1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: _forest, size: 21 * scale),
                SizedBox(height: 4 * scale),
                Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _forest,
                    fontSize: 10.9 * scale,
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

  void _welcomeChooseWorkspace() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFEF9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8D5CB),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 19),
              const Text(
                'Choose your workspace',
                style: TextStyle(
                  color: _forest,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'One HPJ account connects all your available workspaces.',
                style: TextStyle(color: Color(0xFF68746C), fontSize: 12),
              ),
              const SizedBox(height: 18),
              _welcomeWorkspaceChoice(
                sheetContext: sheetContext,
                icon: Icons.shopping_cart_outlined,
                title: 'Customer',
                subtitle: 'Shop fresh Jamaican produce',
                audience: 'customer',
              ),
              _welcomeWorkspaceChoice(
                sheetContext: sheetContext,
                icon: Icons.eco_outlined,
                title: 'Farmer',
                subtitle: 'Supply HPJ or open your Farmer workspace',
                audience: 'farmer',
              ),
              _welcomeWorkspaceChoice(
                sheetContext: sheetContext,
                icon: Icons.business_outlined,
                title: 'Business',
                subtitle: 'Apply for wholesale or open your Business workspace',
                audience: 'business',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _welcomeWorkspaceChoice({
    required BuildContext sheetContext,
    required IconData icon,
    required String title,
    required String subtitle,
    required String audience,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: const Color(0xFFF4F8F0),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            Navigator.of(sheetContext).pop();
            if (mounted) unawaited(_welcomeOpenRole(audience));
          },
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Icon(icon, color: _forest, size: 25),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: _forest,
                              fontSize: 14,
                              fontWeight: FontWeight.w900)),
                      Text(subtitle,
                          style: const TextStyle(
                              color: Color(0xFF637368), fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _forest),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Welcome MVP: a quiet, photo-first layout. Only this mobile landing widget
  // changes; the desktop route and every navigation callback are preserved.
  Widget _mvpMobileWelcome(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDAE6D7),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Always use the photograph selected in Admin -> Welcome Screen
          // Background (and the established Home Hero fallback).
          Positioned.fill(child: _landingBackground()),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, .35, .68, 1],
                    colors: [
                      Colors.white.withOpacity(.74),
                      Colors.white.withOpacity(.43),
                      Colors.white.withOpacity(.12),
                      const Color(0xFF153C2B).withOpacity(.24),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale =
                    (constraints.maxHeight / 720).clamp(.80, 1.0).toDouble();
                final width = constraints.maxWidth;
                final side = width < 360 ? 15.0 : 20.0;
                final inset = 10.0 * scale;
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(side, inset, side, inset),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight > 2 * inset
                          ? constraints.maxHeight - 2 * inset
                          : 0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 75 * scale,
                                  height: 75 * scale,
                                  padding: EdgeInsets.all(7 * scale),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(.78),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(.9),
                                    ),
                                  ),
                                  child: Image.asset(
                                    'lib/assets/images/logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.eco_outlined,
                                      color: _forest,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Padding(
                                  padding: EdgeInsets.only(top: 12 * scale),
                                  child: Text(
                                    'FRESH  •  LOCAL  •  JAMAICAN',
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: _forest,
                                      fontSize: (width < 350 ? 7.7 : 9) * scale,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: width < 350 ? .6 : 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 15 * scale),
                            Text(
                              'Good things\ngrow together.',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                color: _forest,
                                fontSize: (width < 350 ? 30 : 34) * scale,
                                height: 1.04,
                                letterSpacing: -1.15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 8 * scale),
                            Text(
                              'Fresh produce. Stronger farmers.\nA healthier Jamaica.',
                              style: TextStyle(
                                color: const Color(0xFF203F32),
                                fontSize: 13.4 * scale,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 18 * scale),
                            // ONE quiet glass surface contains all entry actions.
                            _welcomeGlassPanel(
                              blur: 15,
                              radius: 23 * scale,
                              tint: const Color(0xFFF7F7EE).withOpacity(.67),
                              borderColor: Colors.white.withOpacity(.91),
                              padding: EdgeInsets.fromLTRB(
                                12 * scale,
                                12 * scale,
                                12 * scale,
                                8 * scale,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height: 49 * scale,
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: _welcomeChooseWorkspace,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _forest,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12 * scale,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16 * scale,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.grid_view_rounded,
                                              size: 19 * scale),
                                          Expanded(
                                            child: Text(
                                              'Choose Your Workspace',
                                              maxLines: 1,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 14.1 * scale,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                          Icon(Icons.chevron_right_rounded,
                                              size: 22 * scale),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8 * scale),
                                  SizedBox(
                                    height: 45 * scale,
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: widget.onCreateAccount,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _forest,
                                        backgroundColor:
                                            Colors.white.withOpacity(.60),
                                        side: BorderSide(
                                          color: _forest.withOpacity(.72),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16 * scale,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Create an Account',
                                        style: TextStyle(
                                          fontSize: 14.2 * scale,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: widget.onEnterWorkspaces,
                                    style: TextButton.styleFrom(
                                      foregroundColor: _forest,
                                      minimumSize: Size(0, 37 * scale),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4 * scale,
                                      ),
                                    ),
                                    child: Text.rich(
                                      const TextSpan(children: [
                                        TextSpan(text: 'Already registered? '),
                                        TextSpan(
                                          text: 'Sign In',
                                          style: TextStyle(
                                            decoration:
                                                TextDecoration.underline,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ]),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _forest,
                                        fontSize: 12.4 * scale,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 13 * scale),
                            Row(
                              children: [
                                _welcomeRoleCard(
                                  label: 'Customer',
                                  subtitle: 'Shop fresh\nproduce',
                                  icon: Icons.shopping_basket_outlined,
                                  tint:
                                      const Color(0xFFF0F9EC).withOpacity(.61),
                                  scale: scale,
                                  onTap: () => unawaited(
                                    _welcomeOpenRole('customer'),
                                  ),
                                ),
                                SizedBox(width: 8 * scale),
                                _welcomeRoleCard(
                                  label: 'Farmer',
                                  subtitle: 'Supply to HPJ',
                                  icon: Icons.eco_outlined,
                                  tint:
                                      const Color(0xFFFFF7E8).withOpacity(.63),
                                  scale: scale,
                                  onTap: () => unawaited(
                                    _welcomeOpenRole('farmer'),
                                  ),
                                ),
                                SizedBox(width: 8 * scale),
                                _welcomeRoleCard(
                                  label: 'Business',
                                  subtitle: 'Buy wholesale',
                                  icon: Icons.storefront_outlined,
                                  tint:
                                      const Color(0xFFF0F8F1).withOpacity(.63),
                                  scale: scale,
                                  onTap: () => unawaited(
                                    _welcomeOpenRole('business'),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 13 * scale),
                            // Footer remains completely functional, but it no
                            // longer competes with the photo and primary CTA.
                            _welcomeGlassPanel(
                              tint: const Color(0xFFFFFCF1).withOpacity(.64),
                              radius: 21 * scale,
                              blur: 15,
                              borderColor: Colors.white.withOpacity(.9),
                              padding: EdgeInsets.fromLTRB(
                                7 * scale,
                                8 * scale,
                                7 * scale,
                                5 * scale,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(children: [
                                    _welcomeFooterLink(
                                      icon: Icons.info_outline_rounded,
                                      label: 'About',
                                      destination: const AboutHpjScreen(),
                                      scale: scale,
                                    ),
                                    _welcomeFooterLink(
                                      icon: Icons.shield_outlined,
                                      label: 'Trust',
                                      destination: const TrustCenterScreen(),
                                      scale: scale,
                                    ),
                                    _welcomeFooterLink(
                                      icon: Icons.support_agent_rounded,
                                      label: 'Support',
                                      destination: const SupportScreen(
                                        initialSubject: 'Account help',
                                      ),
                                      scale: scale,
                                    ),
                                  ]),
                                  Row(children: [
                                    _welcomeFooterLink(
                                      icon: Icons.description_outlined,
                                      label: 'Terms',
                                      destination: const TermsOfServiceScreen(),
                                      scale: scale,
                                    ),
                                    _welcomeFooterLink(
                                      icon: Icons.lock_outline_rounded,
                                      label: 'Privacy',
                                      destination: const PrivacyPolicyScreen(),
                                      scale: scale,
                                    ),
                                    _welcomeFooterLink(
                                      icon: Icons.currency_exchange_rounded,
                                      label: 'Refunds',
                                      destination: const RefundPolicyScreen(),
                                      scale: scale,
                                    ),
                                    _welcomeFooterLink(
                                      icon: Icons.help_outline_rounded,
                                      label: 'FAQ',
                                      destination: const HpjFaqScreen(),
                                      scale: scale,
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                            SizedBox(height: 8 * scale),
                            Center(
                              child: Text(
                                '🇯🇲  GROWING A BRIGHTER JAMAICA',
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x880A281B),
                                      blurRadius: 6,
                                    ),
                                  ],
                                  fontSize: 9 * scale,
                                  letterSpacing: 1.1,
                                  fontWeight: FontWeight.w900,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _welcomeHeroBenefit(IconData icon, String text, double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFFE7C978), size: 13 * scale),
        SizedBox(width: 3 * scale),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(.92),
              fontSize: 8.4 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final desktopWeb = kIsWeb && media.size.width >= 1100;
    if (desktopWeb) return _desktopPublicWebsite(context);
    return _mvpMobileWelcome(context);
  }
}

// ============================================================================
// HPJ PHASE 82 — HOMEPAGE MEAL FOR THE DAY (WEB)
// Replaces the oversized desktop Dinner banner with real Admin-managed meal
// cards. Images/details come from hpj_weekly_meals through the existing
// customer meal system. The compact/narrow Dinner card remains unchanged.
// ============================================================================

class _HpjMealForTheDaySection extends StatefulWidget {
  final VoidCallback onViewAll;

  const _HpjMealForTheDaySection({
    required this.onViewAll,
  });

  @override
  State<_HpjMealForTheDaySection> createState() =>
      _HpjMealForTheDaySectionState();
}

class _HpjMealForTheDaySectionState extends State<_HpjMealForTheDaySection> {
  static const Color _forest = Color(0xFF063E2B);
  static const Color _deepForest = Color(0xFF032D20);
  static const Color _gold = Color(0xFFFFBD25);
  static const Color _softGreen = Color(0xFFF2F7EF);
  static const Color _line = Color(0xFFD8E3D4);
  static const Color _muted = Color(0xFF68736B);

  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    unawaited(_refreshMeals());
  }

  Future<void> _refreshMeals() async {
    await fetchPublicWeeklyMealIdeas();
    if (mounted) setState(() {});
  }

  void _openMeal(_WeeklyMealIdea meal) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => WeeklyMealIdeasScreen(
          initialMealWeekday: meal.weekday,
        ),
      ),
    );
  }

  List<_WeeklyMealIdea> _visibleMeals(List<_WeeklyMealIdea> source) {
    Iterable<_WeeklyMealIdea> meals = source;

    switch (_filter) {
      case 'Classic':
        meals = meals.where((meal) => meal.isClassic);
        break;
      case 'Vegetarian':
        meals = meals.where((meal) => meal.isVegetarian);
        break;
      case 'Ital / Vegan':
        meals = meals.where((meal) => meal.isPlantBased);
        break;
      default:
        break;
    }

    final today = DateTime.now().weekday;
    final result = meals.toList(growable: false)
      ..sort((a, b) {
        final aDistance = (a.weekday - today + 7) % 7;
        final bDistance = (b.weekday - today + 7) % 7;
        return aDistance.compareTo(bDistance);
      });

    return result;
  }

  Widget _filterChip(String label) {
    final selected = _filter == label;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (selected) return;
          setState(() => _filter = label);
        },
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: selected ? _forest : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? _forest : _line,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _forest.withOpacity(.10),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _forest,
              fontSize: 9.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _mealMeta({
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: _forest,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF405047),
            fontSize: 8.1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _ingredientChip(String label, int index) {
    const tones = <Color>[
      Color(0xFFEAF4E5),
      Color(0xFFFFF0E7),
      Color(0xFFF0F4ED),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: tones[index % tones.length],
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _forest,
          fontSize: 7.8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _mealCard(
    _WeeklyMealIdea meal, {
    required bool isToday,
  }) {
    final ingredients = meal.freshIngredients.take(3).toList(growable: false);

    return Container(
      height: 306,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isToday ? const Color(0xFF58A86D) : _line,
          width: isToday ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _deepForest.withOpacity(.055),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 116,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _MealPhoto(
                  meal: meal,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isToday
                          ? const Color(0xFF11823E)
                          : const Color(0xFFF4F8F1),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isToday
                              ? Icons.star_rounded
                              : meal.isPlantBased
                                  ? Icons.eco_rounded
                                  : Icons.restaurant_rounded,
                          size: 13,
                          color: isToday ? _gold : _forest,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isToday
                              ? "TODAY'S PICK"
                              : meal.dietaryLabel.toUpperCase(),
                          style: TextStyle(
                            color: isToday ? Colors.white : _forest,
                            fontSize: 7.4,
                            letterSpacing: .35,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _deepForest,
                      fontSize: 13.8,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    meal.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 8.2,
                      height: 1.32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 10,
                    runSpacing: 5,
                    children: [
                      _mealMeta(
                        icon: Icons.schedule_rounded,
                        text: '${meal.preparationMinutes} min',
                      ),
                      _mealMeta(
                        icon: Icons.people_alt_outlined,
                        text: '${meal.servings} servings',
                      ),
                      _mealMeta(
                        icon: Icons.bar_chart_rounded,
                        text: meal.difficulty,
                      ),
                    ],
                  ),
                  if (ingredients.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        for (var i = 0; i < ingredients.length; i++)
                          _ingredientChip(ingredients[i], i),
                      ],
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: FilledButton.icon(
                            onPressed: () => _openMeal(meal),
                            icon: const Icon(
                              Icons.soup_kitchen_outlined,
                              size: 14,
                            ),
                            label: const Text('View Recipe'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _forest,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 8.2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: OutlinedButton.icon(
                            onPressed: () => _openMeal(meal),
                            icon: const Icon(
                              Icons.shopping_basket_outlined,
                              size: 14,
                            ),
                            label: const Text('Ingredients'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _forest,
                              backgroundColor: _softGreen,
                              side: BorderSide.none,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 8.0,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFBFCF9),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(34, 20, 34, 22),
            child: ValueListenableBuilder<List<_WeeklyMealIdea>>(
              valueListenable: hpjWeeklyMealIdeasNotifier,
              builder: (context, meals, _) {
                final visible = _visibleMeals(meals);
                final shown = visible.take(4).toList(growable: false);
                final today = DateTime.now().weekday;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.restaurant_rounded,
                                    color: _forest,
                                    size: 22,
                                  ),
                                  SizedBox(width: 9),
                                  Text(
                                    'Meal for the Day',
                                    style: TextStyle(
                                      color: _deepForest,
                                      fontSize: 21,
                                      height: 1,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -.35,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Fresh Jamaican meal ideas made with local ingredients.',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 9.6,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: widget.onViewAll,
                          iconAlignment: IconAlignment.end,
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                          ),
                          label: const Text('View all dinner ideas'),
                          style: TextButton.styleFrom(
                            foregroundColor: _forest,
                            textStyle: const TextStyle(
                              fontSize: 9.8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _filterChip('All'),
                        _filterChip('Classic'),
                        _filterChip('Vegetarian'),
                        _filterChip('Ital / Vegan'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (shown.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _line),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.restaurant_menu_rounded,
                              color: _forest,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No published meals match this filter yet.',
                                style: TextStyle(
                                  color: _muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 1060
                              ? 4
                              : constraints.maxWidth >= 820
                                  ? 3
                                  : constraints.maxWidth >= 560
                                      ? 2
                                      : 1;
                          const gap = 12.0;
                          final cardWidth = columns == 1
                              ? constraints.maxWidth
                              : (constraints.maxWidth - gap * (columns - 1)) /
                                  columns;

                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              for (final meal in shown)
                                SizedBox(
                                  width: cardWidth,
                                  child: _mealCard(
                                    meal,
                                    isToday: meal.weekday == today,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 17,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F6EC),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: _line),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.eco_rounded,
                              color: Color(0xFF11823E),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 11),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fresh ingredients from Jamaican farmers.',
                                  style: TextStyle(
                                    color: _deepForest,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Get inspired, view the recipe, then shop what you need on HPJ.',
                                  style: TextStyle(
                                    color: _muted,
                                    fontSize: 8.7,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: widget.onViewAll,
                            iconAlignment: IconAlignment.end,
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 15,
                            ),
                            label: const Text('See all recipes'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _forest,
                              side: const BorderSide(color: _forest),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 8.8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HpjJamaicanDinnerCampaign extends StatefulWidget {
  final VoidCallback onTap;
  final bool compact;

  const _HpjJamaicanDinnerCampaign({
    required this.onTap,
    this.compact = false,
  });

  @override
  State<_HpjJamaicanDinnerCampaign> createState() =>
      _HpjJamaicanDinnerCampaignState();
}

class _HpjJamaicanDinnerCampaignState
    extends State<_HpjJamaicanDinnerCampaign> {
  bool _hovered = false;

  static const Color _forest = Color(0xFF063E2B);
  static const Color _deepForest = Color(0xFF032D20);
  static const Color _gold = Color(0xFFFFBD25);
  static const Color _cream = Color(0xFFFFFCF5);
  static const Color _softGreen = Color(0xFFF1F6EE);
  static const Color _line = Color(0xFFD8E3D4);
  static const Color _muted = Color(0xFF68736B);

  Widget _eyebrow() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 10 : 13,
        vertical: widget.compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0C7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFF2D787)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.restaurant_rounded,
            size: widget.compact ? 12 : 14,
            color: _forest,
          ),
          const SizedBox(width: 7),
          Text(
            'DINNER • MADE JAMAICAN',
            style: TextStyle(
              color: _forest,
              fontSize: widget.compact ? 7.1 : 8.4,
              letterSpacing: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefit({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: widget.compact ? 30 : 36,
          height: widget.compact ? 30 : 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _softGreen,
            borderRadius: BorderRadius.circular(widget.compact ? 10 : 12),
          ),
          child: Icon(
            icon,
            color: _forest,
            size: widget.compact ? 15 : 17,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: _forest,
                fontSize: widget.compact ? 8.0 : 9.1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: TextStyle(
                color: _muted,
                fontSize: widget.compact ? 6.7 : 7.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _journeyStep({
    required String number,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 11 : 14,
        vertical: widget.compact ? 9 : 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.86),
        borderRadius: BorderRadius.circular(widget.compact ? 14 : 17),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: widget.compact ? 30 : 34,
            height: widget.compact ? 30 : 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE39A),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: TextStyle(
                color: _forest,
                fontSize: widget.compact ? 8.2 : 9.1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: widget.compact ? 28 : 32,
            height: widget.compact ? 28 : 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _softGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: widget.compact ? 14 : 16,
              color: _forest,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _forest,
                    fontSize: widget.compact ? 8.4 : 9.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _muted,
                    fontSize: widget.compact ? 6.7 : 7.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_rounded,
            size: widget.compact ? 14 : 16,
            color: _forest.withOpacity(.62),
          ),
        ],
      ),
    );
  }

  Widget _leftContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _eyebrow(),
        SizedBox(height: widget.compact ? 11 : 15),
        Text(
          'Dinner, made Jamaican.',
          style: TextStyle(
            color: _forest,
            fontSize: widget.compact ? 24 : 34,
            height: .98,
            letterSpacing: widget.compact ? -.65 : -1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: widget.compact ? 8 : 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'Easy Jamaican meal ideas built around fresh local ingredients you can shop on HPJ.',
            style: TextStyle(
              color: _muted,
              fontSize: widget.compact ? 9.7 : 11.2,
              height: 1.42,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: widget.compact ? 14 : 18),
        FilledButton.icon(
          onPressed: widget.onTap,
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.arrow_forward_rounded, size: 17),
          label: const Text('Explore Dinner Ideas'),
          style: FilledButton.styleFrom(
            backgroundColor: _forest,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 18 : 23,
              vertical: widget.compact ? 12 : 15,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            textStyle: TextStyle(
              fontSize: widget.compact ? 9.3 : 10.6,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(height: widget.compact ? 15 : 20),
        Wrap(
          spacing: widget.compact ? 14 : 22,
          runSpacing: 10,
          children: [
            _benefit(
              icon: Icons.eco_outlined,
              title: 'Fresh ingredients',
              subtitle: 'From Jamaican farms',
            ),
            _benefit(
              icon: Icons.menu_book_outlined,
              title: 'Easy recipes',
              subtitle: 'Made for real homes',
            ),
            _benefit(
              icon: Icons.shopping_basket_outlined,
              title: 'Shop on HPJ',
              subtitle: 'Find what you need',
            ),
          ],
        ),
      ],
    );
  }

  Widget _rightJourney() {
    return Container(
      padding: EdgeInsets.all(widget.compact ? 13 : 17),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F1),
        borderRadius: BorderRadius.circular(widget.compact ? 19 : 23),
        border: Border.all(color: const Color(0xFFD5E2D1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: widget.compact ? 34 : 40,
                height: widget.compact ? 34 : 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _forest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.dinner_dining_rounded,
                  color: _gold,
                  size: widget.compact ? 17 : 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tonight with HPJ',
                      style: TextStyle(
                        color: _forest,
                        fontSize: widget.compact ? 10.5 : 12.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'From idea to ingredients in three simple steps.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: widget.compact ? 6.9 : 7.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: widget.compact ? 11 : 14),
          _journeyStep(
            number: '01',
            icon: Icons.restaurant_menu_rounded,
            title: 'Pick a dinner',
            subtitle: 'Choose a Jamaican meal idea',
          ),
          const SizedBox(height: 7),
          _journeyStep(
            number: '02',
            icon: Icons.menu_book_rounded,
            title: 'See the recipe',
            subtitle: 'Simple steps and ingredients',
          ),
          const SizedBox(height: 7),
          _journeyStep(
            number: '03',
            icon: Icons.shopping_basket_outlined,
            title: 'Shop ingredients',
            subtitle: 'Find fresh items on HPJ',
          ),
          SizedBox(height: widget.compact ? 11 : 13),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 11 : 13,
              vertical: widget.compact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: _deepForest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.eco_rounded,
                  color: _gold,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Good food. Stronger Jamaica.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: widget.compact ? 7.6 : 8.7,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _campaignCard(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Explore Jamaican dinner ideas and recipes',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          if (!mounted || widget.compact) return;
          setState(() => _hovered = true);
        },
        onExit: (_) {
          if (!mounted || widget.compact) return;
          setState(() => _hovered = false);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _cream,
                Color(0xFFF8F7EF),
                Color(0xFFF3F8F0),
              ],
              stops: [0, .58, 1],
            ),
            borderRadius: BorderRadius.circular(widget.compact ? 24 : 30),
            border: Border.all(
              color:
                  _hovered ? const Color(0xFFB7CCB1) : const Color(0xFFD9E3D5),
            ),
            boxShadow: [
              BoxShadow(
                color: _deepForest.withOpacity(_hovered ? .10 : .06),
                blurRadius: _hovered ? 30 : 22,
                offset: Offset(0, _hovered ? 13 : 9),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(widget.compact ? 24 : 30),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              hoverColor: _forest.withOpacity(.012),
              focusColor: _gold.withOpacity(.05),
              borderRadius: BorderRadius.circular(widget.compact ? 24 : 30),
              child: Stack(
                children: [
                  Positioned(
                    right: -78,
                    top: -92,
                    child: Container(
                      width: widget.compact ? 150 : 220,
                      height: widget.compact ? 150 : 220,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F0E1).withOpacity(.62),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: -42,
                    bottom: -74,
                    child: Container(
                      width: widget.compact ? 110 : 150,
                      height: widget.compact ? 110 : 150,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE7A8).withOpacity(.20),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(widget.compact ? 18 : 27),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final narrow =
                            widget.compact || constraints.maxWidth < 820;

                        if (narrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _leftContent(),
                              SizedBox(height: widget.compact ? 16 : 20),
                              _rightJourney(),
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 11,
                              child: _leftContent(),
                            ),
                            const SizedBox(width: 28),
                            Expanded(
                              flex: 8,
                              child: _rightJourney(),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _campaignCard(context);
    }

    return Container(
      width: double.infinity,
      color: const Color(0xFFF7F9F4),
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _campaignCard(context),
          ),
        ),
      ),
    );
  }
}

class _PublicMarketplaceDemandSignal {
  final String productName;
  final String unit;
  final double visibleDemand;
  final double opportunityGap;
  final String demandSignal;

  const _PublicMarketplaceDemandSignal({
    required this.productName,
    required this.unit,
    required this.visibleDemand,
    required this.opportunityGap,
    required this.demandSignal,
  });

  factory _PublicMarketplaceDemandSignal.fromMap(
    Map<String, dynamic> data,
  ) {
    double number(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return _PublicMarketplaceDemandSignal(
      productName: (data['product_name'] ?? '').toString().trim(),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      visibleDemand: number(data['visible_demand']),
      opportunityGap: number(data['opportunity_gap']),
      demandSignal:
          (data['demand_signal'] ?? 'watch').toString().trim().toLowerCase(),
    );
  }

  bool get isHighDemand {
    if (visibleDemand <= 0 && opportunityGap <= 0) {
      return false;
    }

    return demandSignal == 'committed_need' ||
        demandSignal == 'urgent' ||
        demandSignal == 'opportunity';
  }

  int get priority {
    switch (demandSignal) {
      case 'committed_need':
        return 4;
      case 'urgent':
        return 3;
      case 'opportunity':
        return 2;
      default:
        return 1;
    }
  }

  String get publicLabel {
    switch (demandSignal) {
      case 'committed_need':
        return 'Committed demand';
      case 'urgent':
        return 'Needed soon';
      case 'opportunity':
        return 'Strong demand';
      default:
        return 'Active demand';
    }
  }
}

class _PublicDemandProductMatch {
  final Product product;
  final _PublicMarketplaceDemandSignal demand;

  const _PublicDemandProductMatch({
    required this.product,
    required this.demand,
  });
}

class _PublicEliteCommerceShowcase extends StatefulWidget {
  final VoidCallback onShop;
  final void Function(String category) onCategory;

  const _PublicEliteCommerceShowcase({
    required this.onShop,
    required this.onCategory,
  });

  @override
  State<_PublicEliteCommerceShowcase> createState() =>
      _PublicEliteCommerceShowcaseState();
}

class _PublicEliteCommerceShowcaseState
    extends State<_PublicEliteCommerceShowcase> {
  late Future<List<Product>> _future;
  late Future<List<_PublicMarketplaceDemandSignal>> _demandFuture;

  static const List<String> _categories = <String>[
    'Vegetables',
    'Fruits',
    'Ground Provisions',
    'Herbs',
    'Eggs',
    'Prepared Foods',
  ];

  @override
  void initState() {
    super.initState();

    _future = fetchProductsForCustomerUi(
      timeout: const Duration(seconds: 8),
    );

    _demandFuture = _loadPublicDemand();
  }

  Future<List<_PublicMarketplaceDemandSignal>> _loadPublicDemand() async {
    try {
      final response = await supabase.rpc(
        'farmer_market_demand_board',
        params: const <String, dynamic>{
          'p_horizon_days': 7,
        },
      );

      if (response is! List) {
        return const <_PublicMarketplaceDemandSignal>[];
      }

      final signals = <_PublicMarketplaceDemandSignal>[];

      for (final row in response) {
        if (row is! Map) continue;

        final signal = _PublicMarketplaceDemandSignal.fromMap(
          Map<String, dynamic>.from(row),
        );

        if (signal.productName.isNotEmpty && signal.isHighDemand) {
          signals.add(signal);
        }
      }

      signals.sort((a, b) {
        final priority = b.priority.compareTo(a.priority);

        if (priority != 0) return priority;

        final gap = b.opportunityGap.compareTo(a.opportunityGap);

        if (gap != 0) return gap;

        return b.visibleDemand.compareTo(a.visibleDemand);
      });

      return signals;
    } catch (error) {
      farmDebugLog(
        'Public High Demand lookup skipped: $error',
      );

      // Never fabricate "High Demand" products if the live
      // demand source is unavailable.
      return const <_PublicMarketplaceDemandSignal>[];
    }
  }

  String _demandKey(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  List<_PublicDemandProductMatch> _highDemandMatches(
    List<Product> products,
    List<_PublicMarketplaceDemandSignal> signals,
  ) {
    final available = products
        .where(
          (product) => product.canAddToCart && product.name.trim().isNotEmpty,
        )
        .toList();

    final matches = <_PublicDemandProductMatch>[];
    final usedProductIds = <String>{};

    for (final signal in signals) {
      final wanted = _demandKey(signal.productName);
      if (wanted.isEmpty) continue;

      Product? matched;

      for (final product in available) {
        if (usedProductIds.contains(product.id)) {
          continue;
        }

        final productKey = _demandKey(product.name);

        if (productKey == wanted ||
            productKey.contains(wanted) ||
            wanted.contains(productKey)) {
          matched = product;
          break;
        }
      }

      if (matched == null) continue;

      usedProductIds.add(matched.id);

      matches.add(
        _PublicDemandProductMatch(
          product: matched,
          demand: signal,
        ),
      );

      if (matches.length >= 6) break;
    }

    return matches;
  }

  List<Product> _featured(List<Product> source) {
    final products = source
        .where(
          (product) => product.canAddToCart && product.name.trim().isNotEmpty,
        )
        .toList();

    products.sort((a, b) {
      final deals =
          (b.hasActiveDiscount ? 1 : 0).compareTo(a.hasActiveDiscount ? 1 : 0);
      if (deals != 0) return deals;

      final organic = (b.isOrganic ? 1 : 0).compareTo(a.isOrganic ? 1 : 0);
      if (organic != 0) return organic;

      return a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          );
    });

    return products.take(8).toList();
  }

  Product? _firstForCategory(
    List<Product> source,
    String category,
  ) {
    for (final product in source) {
      if (normalizeProductCategory(product.category) ==
          normalizeProductCategory(category)) {
        return product;
      }
    }
    return null;
  }

  void _addToBox(Product product) {
    if (!product.canAddToCart) return;

    final cart = OfflineCartStore.restore();
    final quantity = cart.where((item) => item.id == product.id).length;

    if (product.stockQuantity > 0 && quantity >= product.stockQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You already have the available quantity in My Box.',
          ),
        ),
      );
      return;
    }

    cart.add(product);
    OfflineCartStore.save(cart);

    if (isLoggedIn) {
      unawaited(
        saveCartItemForCurrentUser(product),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${product.name} added to My Box',
        ),
        action: SnackBarAction(
          label: 'Open Shop',
          onPressed: widget.onShop,
        ),
      ),
    );
  }

  Widget _productCard(
    Product product, {
    required double width,
  }) {
    final farm = (product.farmName ?? product.farmerName ?? '').trim();
    final unit = (product.unit ?? '').trim();

    return SizedBox(
      width: width,
      child: Container(
        height: 245,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFFE3E9E1),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B432F).withOpacity(.055),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: const Color(0xFFFBFCFA),
                    padding: const EdgeInsets.all(8),
                    child: productImagePreviewFromUrl(
                      imageUrl: product.imageUrl,
                      height: 120,
                    ),
                  ),
                  Positioned(
                    top: 9,
                    left: 9,
                    child: Wrap(
                      spacing: 5,
                      children: [
                        if (product.hasActiveDiscount)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC528),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'DEAL',
                              style: TextStyle(
                                color: Color(0xFF0B432F),
                                fontSize: 7.4,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        if (product.isOrganic)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B432F),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'ORGANIC',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 7.4,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withOpacity(.96),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: widget.onShop,
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 28,
                          height: 28,
                          child: Icon(
                            Icons.favorite_border_rounded,
                            color: Color(0xFF0B432F),
                            size: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                11,
                9,
                11,
                10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0B432F),
                      fontSize: 11.6,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    farm.isEmpty ? product.category : farm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF667169),
                      fontSize: 7.9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        'J\$${product.effectivePrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF0B432F),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (unit.isNotEmpty) ...[
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '/ $unit',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF667169),
                              fontSize: 7.7,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ] else
                        const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 31,
                    child: FilledButton.icon(
                      onPressed: () => _addToBox(product),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF078A43),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        size: 13,
                      ),
                      label: const Text('Add to Box'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDemandProduct(Product product) {
    hpjWebsiteShopSearchRequest.value = product.name.trim();
    hpjWebsiteShopCategoryRequest.value = null;
    widget.onShop();
  }

  Widget _highDemandCard(
    _PublicDemandProductMatch match, {
    required double width,
  }) {
    final product = match.product;
    final demand = match.demand;
    final farm = (product.farmName ?? product.farmerName ?? '').trim();

    return SizedBox(
      width: width,
      child: Material(
        color: const Color(0xFFFBFCF8),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _openDemandProduct(product),
          mouseCursor: SystemMouseCursors.click,
          hoverColor: const Color(0xFFFFF7DD).withOpacity(.75),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 116,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFDDE6DB),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0B432F).withOpacity(.035),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 78,
                  height: 92,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: productImagePreviewFromUrl(
                    imageUrl: product.imageUrl,
                    height: 82,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC528),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'HIGH DEMAND',
                          style: TextStyle(
                            color: Color(0xFF0B432F),
                            fontSize: 6.9,
                            letterSpacing: .55,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0B432F),
                          fontSize: 11.2,
                          height: 1.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        farm.isNotEmpty ? farm : demand.publicLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF68736B),
                          fontSize: 7.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              demand.publicLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF916800),
                                fontSize: 7.7,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF0B432F),
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _highDemandSection(
    List<Product> allProducts,
  ) {
    return FutureBuilder<List<_PublicMarketplaceDemandSignal>>(
      future: _demandFuture,
      builder: (context, snapshot) {
        final matches = _highDemandMatches(
          allProducts,
          snapshot.data ?? const <_PublicMarketplaceDemandSignal>[],
        );

        if (matches.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(
            top: 19,
            bottom: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HIGH DEMAND THIS WEEK',
                          style: TextStyle(
                            color: Color(0xFF8A6A08),
                            fontSize: 7.6,
                            letterSpacing: 1.25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'What the market is asking for now',
                          style: TextStyle(
                            color: Color(0xFF0B432F),
                            fontSize: 17.5,
                            height: 1.0,
                            letterSpacing: -.3,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Live HPJ demand signals matched to produce currently available in the marketplace.',
                          style: TextStyle(
                            color: Color(0xFF68736B),
                            fontSize: 8.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      unawaited(
                        _openWebsiteFarmerSignup(
                          context,
                        ),
                      );
                    },
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                    ),
                    label: const Text(
                      'Farmer? Supply HPJ',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0B432F),
                      textStyle: const TextStyle(
                        fontSize: 8.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 10.0;

                  final columns = constraints.maxWidth >= 1250
                      ? 6
                      : constraints.maxWidth >= 1000
                          ? 5
                          : 4;

                  final width =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;

                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final match in matches.take(columns))
                        _highDemandCard(
                          match,
                          width: width,
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _categoryTile(
    String category,
    Product? product, {
    required double width,
  }) {
    return SizedBox(
      width: width,
      height: 64,
      child: Material(
        color: _categoryTint(category),
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: () => widget.onCategory(category),
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  height: 46,
                  child: product == null
                      ? Icon(
                          _categoryIcon(category),
                          color: const Color(0xFF0B432F),
                          size: 27,
                        )
                      : productImagePreviewFromUrl(
                          imageUrl: product.imageUrl,
                          height: 46,
                        ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0B432F),
                      fontSize: 9.3,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF0B432F),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _categoryTint(String category) {
    switch (category) {
      case 'Fruits':
        return const Color(0xFFFFF0E4);
      case 'Ground Provisions':
        return const Color(0xFFF8EADF);
      case 'Eggs':
        return const Color(0xFFFFEEE3);
      case 'Prepared Foods':
        return const Color(0xFFFFF1D5);
      default:
        return const Color(0xFFEAF4E8);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Fruits':
        return Icons.apple_outlined;
      case 'Ground Provisions':
        return Icons.grass_outlined;
      case 'Herbs':
        return Icons.eco_outlined;
      case 'Eggs':
        return Icons.egg_alt_outlined;
      case 'Prepared Foods':
        return Icons.restaurant_outlined;
      default:
        return Icons.local_florist_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _future,
      builder: (context, snapshot) {
        final allProducts = snapshot.data ?? const <Product>[];
        final products = _featured(allProducts);

        return Container(
          width: double.infinity,
          color: Colors.white,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1420,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  36,
                  20,
                  36,
                  20,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const cardGap = 10.0;
                    final columns = constraints.maxWidth >= 1320
                        ? 8
                        : constraints.maxWidth >= 1050
                            ? 6
                            : 4;
                    final cardWidth =
                        (constraints.maxWidth - cardGap * (columns - 1)) /
                            columns;

                    const categoryGap = 11.0;
                    final categoryWidth =
                        (constraints.maxWidth - categoryGap * 5) / 6;

                    final productChildren = <Widget>[];

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        products.isEmpty) {
                      for (var i = 0; i < columns; i++) {
                        productChildren.add(
                          SizedBox(
                            width: cardWidth,
                            height: 245,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F8F5),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    } else {
                      for (final product in products.take(columns)) {
                        productChildren.add(
                          _productCard(
                            product,
                            width: cardWidth,
                          ),
                        );
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fresh Picks from the Marketplace',
                                    style: TextStyle(
                                      color: Color(0xFF0B432F),
                                      fontSize: 21,
                                      height: 1.0,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Real products. Real farms. Real Jamaica.',
                                    style: TextStyle(
                                      color: Color(0xFF677169),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: widget.onShop,
                              iconAlignment: IconAlignment.end,
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                              ),
                              label: const Text('Browse Full Shop'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF0B432F),
                                textStyle: const TextStyle(
                                  fontSize: 9.8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (productChildren.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F8F5),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Text(
                              'Fresh marketplace listings will appear here when products are available.',
                              style: TextStyle(
                                color: Color(0xFF677169),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          Wrap(
                            spacing: cardGap,
                            runSpacing: cardGap,
                            children: productChildren,
                          ),
                        _highDemandSection(
                          allProducts,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: categoryGap,
                          runSpacing: 10,
                          children: [
                            for (final category in _categories)
                              _categoryTile(
                                category,
                                _firstForCategory(
                                  allProducts,
                                  category,
                                ),
                                width: categoryWidth,
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PublicLandingRoleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PublicLandingRoleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4F7F0),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFDDE7D9),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F0E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF0B432F),
                  size: 19,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: const Color(0xFF0B432F),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF667169),
                        fontSize: 8.8,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: const Color(0xFF0B432F),
                size: 17,
              ),
            ],
          ),
        ),
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

// =====================================================
// TEMPORARY FARMER EARLY ACCESS WELCOME
//
// Launch-phase onboarding screen shown immediately after a NEW farmer account
// is created. It is intentionally non-dismissible: the farmer must reach the
// end of the message and acknowledge it before continuing.
//
// Remove the signup call to this screen once full customer/business ordering
// is live. The screen itself can then be deleted safely.
// =====================================================
class FarmerEarlyAccessWelcomeScreen extends StatefulWidget {
  final String farmerName;

  const FarmerEarlyAccessWelcomeScreen({
    super.key,
    this.farmerName = '',
  });

  @override
  State<FarmerEarlyAccessWelcomeScreen> createState() =>
      _FarmerEarlyAccessWelcomeScreenState();
}

class _FarmerEarlyAccessWelcomeScreenState
    extends State<FarmerEarlyAccessWelcomeScreen> {
  final ScrollController _scrollController = ScrollController();

  bool _reachedBottom = false;
  bool _understood = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScrollPosition);

    // On a large phone/tablet the whole message may fit without scrolling.
    // In that case, treat the end as reached after layout completes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollPosition();
    });
  }

  void _checkScrollPosition() {
    if (!mounted || !_scrollController.hasClients || _reachedBottom) return;

    final position = _scrollController.position;
    final isAtBottom = position.maxScrollExtent <= 12 ||
        position.pixels >= position.maxScrollExtent - 24;

    if (isAtBottom) {
      setState(() {
        _reachedBottom = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_checkScrollPosition)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cleanName = widget.farmerName.trim();

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: FarmColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 78,
                              height: 78,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: FarmColors.line),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 18,
                                    offset: const Offset(0, 7),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'lib/assets/images/logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.agriculture_rounded,
                                  color: FarmColors.primary,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'THE HARVEST PLACE JA',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: FarmColors.primary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.35,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Container(
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: FarmColors.primarySoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'FARMER EARLY ACCESS',
                                style: TextStyle(
                                  color: FarmColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 17),
                          Text(
                            cleanName.isEmpty
                                ? 'Welcome to HPJ'
                                : 'Welcome to HPJ, $cleanName',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: FarmColors.ink,
                              fontSize: 28,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.7,
                            ),
                          ),
                          const SizedBox(height: 13),
                          const Text(
                            'Thank you for joining The Harvest Place Ja. '
                            'You are joining during our farmer onboarding phase, '
                            'ahead of full customer and business ordering.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: FarmColors.muted,
                              fontSize: 14,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 22),
                          const _FarmerEarlyAccessNoticeCard(
                            icon: Icons.agriculture_rounded,
                            title: 'What to do now',
                            items: [
                              'Complete your farmer profile.',
                              'Add the produce you grow or can supply.',
                              'Upload clear farm and produce photos.',
                              'Add expected quantities and availability.',
                              'Check that your phone number and location are correct.',
                            ],
                          ),
                          const SizedBox(height: 14),
                          const _FarmerEarlyAccessNoticeCard(
                            icon: Icons.storefront_rounded,
                            title: 'Customer ordering begins soon',
                            body:
                                'HPJ is building the farmer supply side first. '
                                'Full customer and business ordering will open soon. '
                                'We will notify farmers before marketplace operations '
                                'begin so you have time to update your produce, '
                                'quantities and availability.',
                          ),
                          const SizedBox(height: 14),
                          const _FarmerEarlyAccessNoticeCard(
                            icon: Icons.handshake_rounded,
                            title: 'Why you are joining early',
                            body:
                                'This early-access period gives you time to become '
                                'familiar with HPJ and prepare your farm information '
                                'before marketplace demand begins. Thank you for '
                                'helping us build a stronger connection between '
                                'Jamaican farms, homes and businesses.',
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E8),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE8D8A7),
                              ),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Color(0xFF7A5A08),
                                  size: 21,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'You do not need to rush. Use this period to get '
                                    'your farmer account ready. HPJ will let you know '
                                    'before full ordering starts.',
                                    style: TextStyle(
                                      color: Color(0xFF654B0B),
                                      fontSize: 12.5,
                                      height: 1.4,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (!_reachedBottom)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: FarmColors.primary,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Scroll to the end to continue',
                                    style: TextStyle(
                                      color: FarmColors.primary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              color: FarmColors.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: FarmColors.line),
                            ),
                            child: CheckboxListTile(
                              value: _understood,
                              enabled: _reachedBottom,
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: FarmColors.primary,
                              contentPadding: const EdgeInsets.fromLTRB(
                                10,
                                8,
                                14,
                                8,
                              ),
                              title: const Text(
                                'I have read and understand that HPJ is currently '
                                'onboarding farmers and that full customer and '
                                'business ordering will begin soon.',
                                style: TextStyle(
                                  color: FarmColors.ink,
                                  fontSize: 13,
                                  height: 1.4,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onChanged: _reachedBottom
                                  ? (value) {
                                      setState(() {
                                        _understood = value ?? false;
                                      });
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                decoration: BoxDecoration(
                  color: FarmColors.card,
                  border: const Border(
                    top: BorderSide(color: FarmColors.line),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _reachedBottom && _understood
                              ? () => Navigator.of(context).pop()
                              : null,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 3),
                            child: Text('Continue to HPJ'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FarmerEarlyAccessNoticeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final List<String> items;

  const _FarmerEarlyAccessNoticeCard({
    required this.icon,
    required this.title,
    this.body,
    this.items = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: FarmColors.card,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: FarmColors.primarySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: FarmColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (body != null) ...[
            const SizedBox(height: 12),
            Text(
              body!,
              style: const TextStyle(
                color: FarmColors.muted,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (items.isNotEmpty) ...[
            const SizedBox(height: 13),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: FarmColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: FarmColors.ink,
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// =====================================================
// ADMIN PREVIEW — FARMER EARLY ACCESS WELCOME
//
// This card can be placed inside the Admin > Farmers screen so HPJ staff can
// preview the exact temporary onboarding screen shown to a newly registered
// farmer. Previewing does not create, approve, update, or acknowledge a farmer
// account; it only opens the existing welcome UI.
// =====================================================
class AdminFarmerWelcomePreviewCard extends StatelessWidget {
  const AdminFarmerWelcomePreviewCard({super.key});

  void _openPreview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const FarmerEarlyAccessWelcomeScreen(
          farmerName: 'Preview Farmer',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FarmColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: FarmColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.campaign_outlined,
                  color: FarmColors.primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Farmer Early Access Welcome',
                      style: TextStyle(
                        color: FarmColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Temporary new-farmer onboarding screen',
                      style: TextStyle(
                        color: FarmColors.muted,
                        fontSize: 11.5,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: FarmColors.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: FarmColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Preview the exact information screen shown to new farmers after '
            'successful registration. Preview mode does not create or change '
            'any farmer account or application data.',
            style: TextStyle(
              color: FarmColors.muted,
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openPreview(context),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Preview Farmer Welcome'),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final bool returnToPrevious;
  final bool startInRegister;
  final String initialRegistrationAudience;

  // Used by dedicated Farmer / Business website signup pages.
  // When true, the visitor stays on that registration path and does not
  // see the generic "Change account type" control.
  final bool lockRegistrationAudience;

  const LoginScreen({
    super.key,
    this.returnToPrevious = false,
    this.startInRegister = false,
    this.initialRegistrationAudience = '',
    this.lockRegistrationAudience = false,
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
  // Create-account MVP only: optional profile fields (no phone OTP).
  final signupPhoneController = TextEditingController();
  final signupParishController = TextEditingController();
  Future<String?>? _signupWelcomePhoto;
  final TurnstileController _captchaController = TurnstileController();

  bool loading = false;
  bool googleLoading = false;
  bool googleFlowStarted = false;
  StreamSubscription<AuthState>? _googleAuthSubscription;
  String? _captchaToken;
  bool hidePassword = true;
  bool _signupTermsAccepted = false;
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

    if (isRegister) {
      final initialAudience =
          widget.initialRegistrationAudience.trim().toLowerCase();

      if (initialAudience == 'farmer') {
        selectedRole = 'farmer';
        selectedCustomerAccountType = 'retail';
      } else if (initialAudience == 'business') {
        selectedRole = 'customer';
        selectedCustomerAccountType = 'business';
      }
    }

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
    signupPhoneController.dispose();
    signupParishController.dispose();
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
        builder: (_) => const AuthGate(forceWorkspaceHome: true),
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
    final optionalPhone = signupPhoneController.text.trim();
    final optionalParish = signupParishController.text.trim();
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

    if (isRegister && !_signupTermsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please accept the Terms and Privacy Policy to continue.'),
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
            if (!isBusinessRegistration && optionalPhone.isNotEmpty)
              'phone': optionalPhone,
            if (!isBusinessRegistration && optionalParish.isNotEmpty)
              'parish': optionalParish,
          },
        );

        FarmDataCache.clearAll();

        if (!mounted) return;

        // Managed MVP welcome onboarding. Customer, Farmer and Business each
        // use the Admin-controlled Welcome Screen configuration. The existing
        // Farmer Early Access screen remains the fallback if the new SQL has
        // not been installed yet.
        final welcomeAudience = isBusinessRegistration
            ? 'business'
            : selectedRole == 'farmer'
                ? 'farmer'
                : 'customer';

        await showHpjManagedWelcomeAfterRegistration(
          context: context,
          audience: welcomeAudience,
          hasSession: response.session != null,
          displayName: fullName,
        );

        if (!mounted) return;

        if (response.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isBusinessRegistration
                    ? 'Business account created. Confirm your email, then sign in to continue your Business setup.'
                    : selectedRole == 'farmer'
                        ? 'Farmer account created. Confirm your email, then sign in to continue your Farmer setup.'
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
                  ? 'Business account created. Continue to your Business setup.'
                  : selectedRole == 'farmer'
                      ? 'Farmer account created. Continue to your Farmer setup.'
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
              builder: (_) => const AuthGate(forceWorkspaceHome: true),
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
              builder: (_) => const AuthGate(forceWorkspaceHome: true),
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
    final isBusiness = icon == Icons.storefront_outlined;
    final accent =
        isBusiness ? const Color(0xFFB87A12) : const Color(0xFF0B6A46);
    final tint = isBusiness ? const Color(0xFFFFF4DF) : const Color(0xFFEAF5EC);

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFEFB),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: accent.withOpacity(0.16),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF173B30).withOpacity(0.055),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: accent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF123D2F),
                          fontSize: 14.5,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF747C78),
                          fontSize: 11.5,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: tint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: accent,
                    size: 18,
                  ),
                ),
              ],
            ),
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

  // -------------------------------------------------------------------------
  // CREATE ACCOUNT MVP. Only registration uses this screen. Existing sign-in,
  // Google OAuth, Supabase registration, approvals and workspace gates stay as-is.
  // -------------------------------------------------------------------------
  void _signupOpenPolicy(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  void _signupGoToSignIn() {
    if (loading || googleLoading) return;
    setState(() {
      isRegister = false;
      hidePassword = true;
      _captchaToken = null;
    });
    if (AppConfig.turnstileConfigured) {
      _captchaController.refreshToken().catchError((error) {
        farmDebugLog('Turnstile refresh failed: $error');
      });
    }
  }

  Widget _signupRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color tint,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    const forest = Color(0xFF0A5037);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '$title account',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 121,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: selected ? forest : const Color(0xFFE6E4DC),
                width: selected ? 1.7 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: forest.withOpacity(.09),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                if (selected)
                  const Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(Icons.check_circle_rounded,
                        color: forest, size: 17),
                  ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: forest, size: 29),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF153D30),
                          fontWeight: FontWeight.w900,
                          fontSize: 12.8,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF59645F),
                          fontSize: 10,
                          height: 1.16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _signupFieldDecoration(String hint, IconData icon,
      {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF69766F), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF315A48), size: 21),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFD8E4D9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF0B5A3E), width: 1.6),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
    );
  }

  Widget _signupMvpBackground() {
    _signupWelcomePhoto ??= fetchPublicWelcomeBackgroundUrl();
    return FutureBuilder<String?>(
      future: _signupWelcomePhoto,
      builder: (context, snapshot) {
        final imageUrl = cleanHostedImageUrl(snapshot.data);
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFDDEADB), Color(0xFFFFFCF7)],
                ),
              ),
            ),
            if (imageUrl != null && imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, .40, .78, 1.0],
                  colors: [
                    Color(0x4DFFFFFF),
                    Color(0xB8FFFCF7),
                    Color(0xF5FFFCF7),
                    Color(0xFFFFFCF7),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _signupMvp(BuildContext context) {
    const forest = Color(0xFF0A5037);
    final farmer = selectedRole == 'farmer';
    final business = isBusinessRegistration;
    final roleLocked = widget.lockRegistrationAudience;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 390;
    final horizontal = width >= 740 ? 32.0 : 15.0;

    Widget spaced(Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: child,
        );

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF7),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: compact ? 229 : 250,
                        child: Stack(
                          children: [
                            Positioned.fill(child: _signupMvpBackground()),
                            Align(
                              alignment: Alignment.topLeft,
                              child: IconButton(
                                tooltip: 'Back',
                                onPressed: () {
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  } else {
                                    _signupGoToSignIn();
                                  }
                                },
                                icon: const Icon(Icons.arrow_back_rounded,
                                    color: forest),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 12, 10, 10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: compact ? 78 : 88,
                                      height: compact ? 78 : 88,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: forest.withOpacity(.10),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          )
                                        ],
                                      ),
                                      child: Image.asset(
                                        'lib/assets/images/logo.png',
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.eco_rounded,
                                                color: forest, size: 40),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Create an Account',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: forest,
                                        fontSize: compact ? 25 : 29,
                                        height: 1.08,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -.7,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    const Text(
                                      'Join HPJ and be part of a fresher,\nstronger Jamaica.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF435A52),
                                        fontSize: 13,
                                        height: 1.35,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.all(compact ? 13 : 17),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: const Color(0xFFE5E7DE)),
                          boxShadow: [
                            BoxShadow(
                              color: forest.withOpacity(.055),
                              blurRadius: 23,
                              offset: const Offset(0, 9),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Account type',
                                style: TextStyle(
                                  color: forest,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                )),
                            const SizedBox(height: 12),
                            if (roleLocked)
                              Container(
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: farmer
                                      ? const Color(0xFFFFF8EB)
                                      : const Color(0xFFEAF7F0),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                        farmer
                                            ? Icons.spa_outlined
                                            : Icons.business_outlined,
                                        color: forest),
                                    const SizedBox(width: 10),
                                    Text(
                                        farmer
                                            ? 'Farmer account'
                                            : 'Business account',
                                        style: const TextStyle(
                                            color: forest,
                                            fontWeight: FontWeight.w800)),
                                    const Spacer(),
                                    const Icon(Icons.check_circle_rounded,
                                        color: forest),
                                  ],
                                ),
                              )
                            else
                              Row(
                                children: [
                                  _signupRoleCard(
                                    title: 'Customer',
                                    subtitle: 'Shop fresh\nproduce',
                                    icon: Icons.shopping_basket_outlined,
                                    tint: const Color(0xFFF0F9F0),
                                    selected: !farmer && !business,
                                    onTap: loading
                                        ? null
                                        : _usePersonalRegistration,
                                  ),
                                  const SizedBox(width: 7),
                                  _signupRoleCard(
                                    title: 'Farmer',
                                    subtitle: 'Supply to HPJ',
                                    icon: Icons.spa_outlined,
                                    tint: const Color(0xFFFFF8EC),
                                    selected: farmer,
                                    onTap:
                                        loading ? null : _useFarmerRegistration,
                                  ),
                                  const SizedBox(width: 7),
                                  _signupRoleCard(
                                    title: 'Business',
                                    subtitle: 'Buy wholesale',
                                    icon: Icons.business_outlined,
                                    tint: const Color(0xFFEDF9F5),
                                    selected: business,
                                    onTap: loading
                                        ? null
                                        : _useBusinessRegistration,
                                  ),
                                ],
                              ),
                            const SizedBox(height: 18),
                            spaced(TextField(
                              controller: fullNameController,
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [AutofillHints.name],
                              textInputAction: TextInputAction.next,
                              decoration: _signupFieldDecoration(
                                  business ? 'Contact person *' : 'Full name *',
                                  Icons.person_outline_rounded),
                            )),
                            if (business) ...[
                              spaced(TextField(
                                controller: businessNameController,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: _signupFieldDecoration(
                                    'Business name *',
                                    Icons.storefront_outlined),
                              )),
                              spaced(DropdownButtonFormField<String>(
                                value: selectedBusinessType,
                                isExpanded: true,
                                decoration: _signupFieldDecoration(
                                    'Business type', Icons.category_outlined),
                                items: _businessTypes
                                    .map((type) => DropdownMenuItem<String>(
                                          value: type,
                                          child: Text(type,
                                              overflow: TextOverflow.ellipsis),
                                        ))
                                    .toList(),
                                onChanged: loading
                                    ? null
                                    : (type) {
                                        if (type != null) {
                                          setState(() =>
                                              selectedBusinessType = type);
                                        }
                                      },
                              )),
                            ],
                            spaced(TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              textInputAction: TextInputAction.next,
                              decoration: _signupFieldDecoration(
                                  'Email address *',
                                  Icons.mail_outline_rounded),
                            )),
                            spaced(TextField(
                              controller: passwordController,
                              obscureText: hidePassword,
                              autofillHints: const [AutofillHints.newPassword],
                              textInputAction: TextInputAction.next,
                              decoration: _signupFieldDecoration(
                                'Password *',
                                Icons.lock_outline_rounded,
                                suffix: IconButton(
                                  tooltip: hidePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  icon: Icon(hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  onPressed: () => setState(
                                      () => hidePassword = !hidePassword),
                                ),
                              ),
                            )),
                            if (business) ...[
                              spaced(TextField(
                                controller: businessPhoneController,
                                keyboardType: TextInputType.phone,
                                autofillHints: const [
                                  AutofillHints.telephoneNumber
                                ],
                                textInputAction: TextInputAction.next,
                                decoration: _signupFieldDecoration(
                                    'Business phone *', Icons.phone_outlined),
                              )),
                              spaced(JamaicaParishDropdown(
                                controller: businessParishController,
                                label: 'Business parish *',
                                enabled: !loading,
                                prefixIcon: Icons.place_outlined,
                              )),
                            ] else ...[
                              spaced(TextField(
                                controller: signupPhoneController,
                                keyboardType: TextInputType.phone,
                                autofillHints: const [
                                  AutofillHints.telephoneNumber
                                ],
                                textInputAction: TextInputAction.next,
                                decoration: _signupFieldDecoration(
                                    'Phone number (optional)',
                                    Icons.phone_outlined),
                              )),
                              spaced(JamaicaParishDropdown(
                                controller: signupParishController,
                                label: 'Parish (optional)',
                                enabled: !loading,
                                prefixIcon: Icons.place_outlined,
                              )),
                            ],
                            if (farmer || business) ...[
                              const SizedBox(height: 2),
                              _PremiumAuthInfoPanel(
                                icon: farmer
                                    ? Icons.agriculture_outlined
                                    : Icons.verified_outlined,
                                text: farmer
                                    ? 'After creating your account, continue to the farmer application. Approval is required for Farmer tools.'
                                    : 'Business access and wholesale pricing are activated after approval.',
                                gold: business,
                              ),
                              const SizedBox(height: 10),
                            ],
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Checkbox(
                                  value: _signupTermsAccepted,
                                  activeColor: forest,
                                  onChanged: loading
                                      ? null
                                      : (value) => setState(() =>
                                          _signupTermsAccepted =
                                              value ?? false),
                                ),
                                Expanded(
                                  child: Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 2,
                                    runSpacing: 0,
                                    children: [
                                      const Text('I agree to the',
                                          style: TextStyle(fontSize: 12.4)),
                                      TextButton(
                                        onPressed: () => _signupOpenPolicy(
                                            const TermsOfServiceScreen()),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 3),
                                          minimumSize: const Size(0, 32),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text('Terms',
                                            style: TextStyle(
                                                fontSize: 12.4,
                                                decoration:
                                                    TextDecoration.underline)),
                                      ),
                                      const Text('and',
                                          style: TextStyle(fontSize: 12.4)),
                                      TextButton(
                                        onPressed: () => _signupOpenPolicy(
                                            const PrivacyPolicyScreen()),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 3),
                                          minimumSize: const Size(0, 32),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text('Privacy Policy',
                                            style: TextStyle(
                                                fontSize: 12.4,
                                                decoration:
                                                    TextDecoration.underline)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (AppConfig.turnstileConfigured) ...[
                              const SizedBox(height: 9),
                              _HpjTurnstilePanel(
                                controller: _captchaController,
                                action: 'hpj_auth',
                                onTokenChanged: (token) {
                                  if (mounted) {
                                    setState(() => _captchaToken = token);
                                  }
                                },
                              ),
                            ],
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 54,
                              child: FilledButton(
                                onPressed: loading ||
                                        googleLoading ||
                                        !_signupTermsAccepted ||
                                        (AppConfig.turnstileConfigured &&
                                            (_captchaToken == null ||
                                                _captchaToken!.isEmpty))
                                    ? null
                                    : submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: forest,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(17)),
                                ),
                                child: loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        business
                                            ? 'Create Business Account  →'
                                            : farmer
                                                ? 'Create Farmer Account  →'
                                                : 'Create Account  →',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        )),
                              ),
                            ),
                            const SizedBox(height: 15),
                            const _PremiumAuthDivider(label: 'OR'),
                            const SizedBox(height: 13),
                            SizedBox(
                              height: 51,
                              child: OutlinedButton(
                                onPressed: loading ||
                                        googleLoading ||
                                        !_signupTermsAccepted
                                    ? null
                                    : _continueWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: forest,
                                  side: const BorderSide(
                                      color: Color(0xFFC3D0C8)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(17)),
                                ),
                                child: googleLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _GoogleLetterMark(),
                                          SizedBox(width: 10),
                                          Flexible(
                                              child: Text(
                                                  'Continue with Google',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700))),
                                        ],
                                      ),
                              ),
                            ),
                            if (farmer || business) ...[
                              const SizedBox(height: 6),
                              const Text(
                                'Google signs you in with one HPJ account. Farmer and Business approval is requested separately.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Color(0xFF6B7770),
                                    fontSize: 10.2,
                                    height: 1.3),
                              ),
                            ],
                            _signupTutorialAction(),
                            const SizedBox(height: 10),
                            Center(
                              child: TextButton(
                                onPressed: _signupGoToSignIn,
                                child: const Text(
                                    'Already have an account? Sign In',
                                    style: TextStyle(
                                      color: forest,
                                      fontWeight: FontWeight.w800,
                                    )),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Uses the already Admin-managed Welcome Screen Background. The image can
  // be replaced in Admin without changing code. No new table or policy needed.
  Widget _signInGlassBackground() {
    _signupWelcomePhoto ??= fetchPublicWelcomeBackgroundUrl();
    return FutureBuilder<String?>(
      future: _signupWelcomePhoto,
      builder: (context, snapshot) {
        final imageUrl = cleanHostedImageUrl(snapshot.data);
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFCADFCD), Color(0xFF2E6443)],
                ),
              ),
            ),
            if (imageUrl != null && imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                alignment: const Alignment(0.08, 0),
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, .35, .75, 1],
                  colors: [
                    Colors.white.withOpacity(.21),
                    const Color(0xFF193F28).withOpacity(.08),
                    const Color(0xFF0A3721).withOpacity(.24),
                    const Color(0xFF081F17).withOpacity(.48),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _signInGlassPanel({
    required Widget child,
    required Color tint,
    double radius = 24,
    EdgeInsetsGeometry? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withOpacity(.77),
              width: 1.15,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  InputDecoration _signInGlassInput(String hint, IconData icon,
      {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF637068), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF214B39), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(.61),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(.94)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0A5037), width: 1.7),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  void _signInGoToCreateAccount() {
    if (loading || googleLoading) return;
    setState(() {
      isRegister = true;
      hidePassword = true;
      _captchaToken = null;
      pendingConfirmationEmail = null;
      final audience = widget.initialRegistrationAudience.trim().toLowerCase();
      if (widget.lockRegistrationAudience && audience == 'farmer') {
        selectedRole = 'farmer';
        selectedCustomerAccountType = 'retail';
      } else if (widget.lockRegistrationAudience && audience == 'business') {
        selectedRole = 'customer';
        selectedCustomerAccountType = 'business';
      } else {
        selectedRole = 'customer';
        selectedCustomerAccountType = 'retail';
      }
      _signupTutorialFuture = fetchPublishedHelpTutorial(
        placement: 'signup',
        audience: 'all',
      );
    });
    if (AppConfig.turnstileConfigured) {
      _captchaController.refreshToken().catchError((error) {
        farmDebugLog('Turnstile refresh failed: $error');
      });
    }
  }

  void _signInGoBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else if (kIsWeb) {
      openHpjWebsiteHome(context);
    } else {
      navigator.pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(builder: (_) => const AuthGate()),
        (_) => false,
      );
    }
  }

  Widget _mvpGlassMobileSignIn(BuildContext context) {
    const forest = Color(0xFF083D2A);
    return Scaffold(
      backgroundColor: forest,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _signInGlassBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale =
                    (constraints.maxHeight / 720).clamp(.82, 1.0).toDouble();
                final side = constraints.maxWidth < 360 ? 15.0 : 20.0;
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  padding:
                      EdgeInsets.fromLTRB(side, 9 * scale, side, 22 * scale),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 450),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Material(
                                color: Colors.white.withOpacity(.77),
                                shape: const CircleBorder(),
                                child: IconButton(
                                  tooltip: 'Back to Welcome',
                                  onPressed: _signInGoBack,
                                  icon: const Icon(Icons.arrow_back_rounded,
                                      color: forest),
                                ),
                              ),
                              SizedBox(width: 10 * scale),
                              Text(
                                'Sign in',
                                style: TextStyle(
                                  color: forest,
                                  fontSize: 21 * scale,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16 * scale),
                          _signInGlassPanel(
                            tint: const Color(0xFF093D2B).withOpacity(.68),
                            radius: 24 * scale,
                            padding: EdgeInsets.fromLTRB(
                              17 * scale,
                              17 * scale,
                              17 * scale,
                              14 * scale,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '—  THE HARVEST PLACE JA',
                                  style: TextStyle(
                                    color: const Color(0xFFF3D68C),
                                    fontSize: 10.3 * scale,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .9,
                                  ),
                                ),
                                SizedBox(height: 8 * scale),
                                Text(
                                  'Welcome back to HPJ.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24 * scale,
                                    fontWeight: FontWeight.w900,
                                    height: 1.08,
                                  ),
                                ),
                                SizedBox(height: 6 * scale),
                                Text(
                                  'Fresh produce, farmer supply and business '
                                  'purchasing in one trusted marketplace.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(.94),
                                    fontSize: 12.2 * scale,
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 12 * scale),
                                Container(
                                  height: 1,
                                  color: Colors.white.withOpacity(.27),
                                ),
                                SizedBox(height: 10 * scale),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.eco_outlined,
                                              size: 15 * scale,
                                              color: const Color(0xFFF2D487)),
                                          SizedBox(width: 3 * scale),
                                          Flexible(
                                            child: Text(
                                              'Fresh produce',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 9 * scale,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.groups_outlined,
                                              size: 15 * scale,
                                              color: const Color(0xFFF2D487)),
                                          SizedBox(width: 3 * scale),
                                          Flexible(
                                            child: Text(
                                              'Local farmers',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 9 * scale,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.storefront_outlined,
                                              size: 15 * scale,
                                              color: const Color(0xFFF2D487)),
                                          SizedBox(width: 3 * scale),
                                          Flexible(
                                            child: Text(
                                              'Wholesale',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 9 * scale,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12 * scale),
                          _signInGlassPanel(
                            tint: const Color(0xFFF4F3DD).withOpacity(.72),
                            radius: 23 * scale,
                            padding: EdgeInsets.fromLTRB(
                              14 * scale,
                              15 * scale,
                              14 * scale,
                              14 * scale,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 47 * scale,
                                  child: OutlinedButton(
                                    onPressed: loading || googleLoading
                                        ? null
                                        : _continueWithGoogle,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withOpacity(.89),
                                      foregroundColor: forest,
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(.98),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: googleLoading
                                        ? const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 17,
                                                height: 17,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                              SizedBox(width: 9),
                                              Text('Opening Google...'),
                                            ],
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const _GoogleLetterMark(),
                                              const SizedBox(width: 9),
                                              const Flexible(
                                                child: Text(
                                                  'Continue with Google',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                              if (_needsExternalFlutLabGoogleLaunch)
                                                const Padding(
                                                  padding:
                                                      EdgeInsets.only(left: 6),
                                                  child: Icon(
                                                    Icons.open_in_new_rounded,
                                                    size: 14,
                                                  ),
                                                ),
                                            ],
                                          ),
                                  ),
                                ),
                                if (_needsExternalFlutLabGoogleLaunch) ...[
                                  SizedBox(height: 5 * scale),
                                  Text(
                                    'Google opens securely in a browser tab.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: const Color(0xFF4D5A4F),
                                      fontSize: 10 * scale,
                                    ),
                                  ),
                                ],
                                SizedBox(height: 13 * scale),
                                const _PremiumAuthDivider(
                                    label: 'or continue with email'),
                                SizedBox(height: 13 * scale),
                                TextField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  textInputAction: TextInputAction.next,
                                  decoration: _signInGlassInput(
                                    'Email address',
                                    Icons.mail_outline_rounded,
                                  ),
                                ),
                                SizedBox(height: 10 * scale),
                                TextField(
                                  controller: passwordController,
                                  obscureText: hidePassword,
                                  autofillHints: const [AutofillHints.password],
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: loading ? null : (_) => submit(),
                                  decoration: _signInGlassInput(
                                    'Password',
                                    Icons.lock_outline_rounded,
                                    suffix: IconButton(
                                      tooltip: hidePassword
                                          ? 'Show password'
                                          : 'Hide password',
                                      onPressed: () => setState(
                                          () => hidePassword = !hidePassword),
                                      icon: Icon(
                                        hidePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: forest,
                                      ),
                                    ),
                                  ),
                                ),
                                if (AppConfig.turnstileConfigured) ...[
                                  SizedBox(height: 10 * scale),
                                  _HpjTurnstilePanel(
                                    controller: _captchaController,
                                    action: 'hpj_auth',
                                    onTokenChanged: (token) {
                                      if (!mounted) return;
                                      setState(() => _captchaToken = token);
                                    },
                                  ),
                                ],
                                if (pendingConfirmationEmail != null) ...[
                                  SizedBox(height: 11 * scale),
                                  Text(
                                    'Confirm your email: '
                                    '${pendingConfirmationEmail!}',
                                    style: const TextStyle(
                                      color: forest,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: resendingConfirmation
                                        ? null
                                        : _resendConfirmationEmail,
                                    icon: const Icon(Icons.refresh_rounded,
                                        size: 17),
                                    label: Text(resendingConfirmation
                                        ? 'Sending...'
                                        : 'Resend confirmation email'),
                                  ),
                                ],
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: loading
                                        ? null
                                        : () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    ForgotPasswordScreen(
                                                  initialEmail: emailController
                                                      .text
                                                      .trim(),
                                                ),
                                              ),
                                            );
                                          },
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: forest,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 3 * scale),
                                SizedBox(
                                  height: 49 * scale,
                                  child: FilledButton(
                                    onPressed: loading ||
                                            (AppConfig.turnstileConfigured &&
                                                (_captchaToken == null ||
                                                    _captchaToken!.isEmpty))
                                        ? null
                                        : submit,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: forest,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: Text(
                                      loading ? 'Please wait...' : 'Sign in',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4 * scale),
                                TextButton(
                                  onPressed: loading || googleLoading
                                      ? null
                                      : _signInGoToCreateAccount,
                                  child: const Text.rich(
                                    TextSpan(children: [
                                      TextSpan(text: 'New to HPJ? '),
                                      TextSpan(
                                        text: 'Create account',
                                        style: TextStyle(
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ]),
                                    style: TextStyle(color: forest),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10 * scale),
                          Text(
                            'FRESH ROOTS  •  BRIGHTER TOMORROWS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9 * scale,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                              shadows: const [
                                Shadow(
                                  color: Color(0xA0082417),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                          ),
                        ],
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

  @override
  Widget build(BuildContext context) {
    if (isRegister) return _signupMvp(context);
    if (MediaQuery.sizeOf(context).width < 700) {
      return _mvpGlassMobileSignIn(context);
    }

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
                ? 'Create your farmer account and continue directly to the HPJ farmer application.'
                : 'One secure HPJ account for the workspaces available to you.';

    final modeIcon = isBusinessRegistration
        ? Icons.storefront_rounded
        : isFarmerRegistration
            ? Icons.agriculture_rounded
            : isRegister
                ? Icons.person_add_alt_1_rounded
                : Icons.lock_open_rounded;

    final modeEyebrow = isBusinessRegistration
        ? 'WHOLESALE BUSINESS'
        : isFarmerRegistration
            ? 'FARMER PARTNER'
            : isRegister
                ? 'CREATE ACCOUNT'
                : 'SECURE SIGN IN';

    Widget accountModeBanner() {
      if (!isRegister || isPersonalRegistration) {
        return const SizedBox.shrink();
      }

      final isBusiness = isBusinessRegistration;
      final accent =
          isBusiness ? const Color(0xFFB67910) : const Color(0xFF0B6A46);
      final tint =
          isBusiness ? const Color(0xFFFFF4E1) : const Color(0xFFEAF5EC);

      return Container(
        padding: const EdgeInsets.fromLTRB(13, 11, 8, 11),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.88),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                isBusiness
                    ? Icons.storefront_outlined
                    : Icons.agriculture_outlined,
                color: accent,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBusiness ? 'Business account' : 'Farmer partner account',
                    style: const TextStyle(
                      color: Color(0xFF123D2F),
                      fontSize: 13.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isBusiness
                        ? 'Wholesale access after approval'
                        : 'Apply to supply produce to HPJ',
                    style: const TextStyle(
                      color: Color(0xFF6F7773),
                      fontSize: 10.5,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (!widget.lockRegistrationAudience)
              TextButton(
                onPressed: loading ? null : _usePersonalRegistration,
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Change'),
              ),
          ],
        ),
      );
    }

    Widget googleButton() {
      return Semantics(
        button: true,
        label: 'Continue with Google',
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: loading || googleLoading ? null : _continueWithGoogle,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF20352D),
              side: const BorderSide(
                color: Color(0xFFDADCD8),
                width: 1.1,
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            child: googleLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _GoogleLetterMark(),
                      const SizedBox(width: 10),
                      const Flexible(
                        child: Text(
                          'Continue with Google',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.05,
                          ),
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
      );
    }

    Widget emailPasswordForm() {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEFB),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFE4E0D8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF173B30).withOpacity(0.055),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3EB),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.mail_outline_rounded,
                    size: 18,
                    color: Color(0xFF0B5A3E),
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  isRegister ? 'Account details' : 'Email & password',
                  style: const TextStyle(
                    color: Color(0xFF153D30),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (isRegister) ...[
              TextField(
                controller: fullNameController,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText:
                      isBusinessRegistration ? 'Contact person *' : 'Full name',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 13),
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
              const SizedBox(height: 13),
              DropdownButtonFormField<String>(
                value: selectedBusinessType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Business type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _businessTypes
                    .map(
                      (type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(
                          type,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: loading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => selectedBusinessType = value);
                        }
                      },
              ),
              const SizedBox(height: 13),
              TextField(
                controller: businessPhoneController,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Business phone *',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 13),
              JamaicaParishDropdown(
                controller: businessParishController,
                label: 'Business parish *',
                enabled: !loading,
                prefixIcon: Icons.map_outlined,
              ),
              const SizedBox(height: 13),
            ],
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
            const SizedBox(height: 13),
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
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: hidePassword ? 'Show password' : 'Hide password',
                  onPressed: () {
                    setState(() => hidePassword = !hidePassword);
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
              const SizedBox(height: 13),
              const _PremiumAuthInfoPanel(
                icon: Icons.agriculture_outlined,
                text:
                    'After sign-in, HPJ will guide you through the short farmer application.',
              ),
            ],
            if (isBusinessRegistration) ...[
              const SizedBox(height: 13),
              const _PremiumAuthInfoPanel(
                icon: Icons.verified_outlined,
                text:
                    'Wholesale pricing is activated after approval. You can still shop normally while your application is reviewed.',
                gold: true,
              ),
            ],
          ],
        ),
      );
    }

    Widget confirmationPanel() {
      if (isRegister || pendingConfirmationEmail == null) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6EE),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD5E5D3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  color: Color(0xFF0B5A3E),
                  size: 22,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Confirm your email',
                    style: TextStyle(
                      color: Color(0xFF153D30),
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
                color: Color(0xFF67716C),
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed:
                  resendingConfirmation ? null : _resendConfirmationEmail,
              icon: resendingConfirmation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
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
      );
    }

    Widget mainAuthContent() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: const Color(0xFFE4E0D8)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF173B30).withOpacity(0.055),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Image.asset(
                  'lib/assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.eco_outlined,
                    color: Color(0xFF0B5A3E),
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THE HARVEST PLACE JA',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF123D2F),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.35,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Fresh • Local • Jamaican',
                      style: TextStyle(
                        color: Color(0xFF858C88),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 27),
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F3EA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              modeIcon,
              color: const Color(0xFF0B5A3E),
              size: 21,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            modeEyebrow,
            style: const TextStyle(
              color: Color(0xFF7A827E),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            heading,
            style: const TextStyle(
              color: Color(0xFF073F2C),
              fontSize: 31,
              height: 1.02,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF707975),
              fontSize: 13.2,
              height: 1.42,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isRegister && !isPersonalRegistration) ...[
            const SizedBox(height: 16),
            accountModeBanner(),
          ],
          const SizedBox(height: 20),
          googleButton(),
          const SizedBox(height: 7),
          Text(
            _needsExternalFlutLabGoogleLaunch
                ? 'Google opens securely in a browser tab.'
                : kIsWeb
                    ? isRegister
                        ? 'Create your account and HPJ will open the right workspace.'
                        : 'Sign in and continue where you left off.'
                    : isRegister
                        ? 'Create your account, then choose a workspace.'
                        : 'Choose your workspace after signing in.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8B918E),
              fontSize: 10.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isRegister) _signupTutorialAction(),
          const SizedBox(height: 15),
          const _PremiumAuthDivider(label: 'or continue with email'),
          const SizedBox(height: 15),
          emailPasswordForm(),
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
          if (!isRegister && pendingConfirmationEmail != null) ...[
            const SizedBox(height: 14),
            confirmationPanel(),
          ],
          if (!isRegister) ...[
            const SizedBox(height: 7),
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
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: PrimaryFarmButton(
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
                          (_captchaToken == null || _captchaToken!.isEmpty))
                  ? null
                  : submit,
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: loading
                ? null
                : () {
                    setState(() {
                      isRegister = !isRegister;
                      hidePassword = true;
                      _captchaToken = null;
                      if (isRegister) {
                        final lockedAudience = widget
                            .initialRegistrationAudience
                            .trim()
                            .toLowerCase();

                        if (widget.lockRegistrationAudience &&
                            lockedAudience == 'farmer') {
                          selectedRole = 'farmer';
                          selectedCustomerAccountType = 'retail';
                        } else if (widget.lockRegistrationAudience &&
                            lockedAudience == 'business') {
                          selectedRole = 'customer';
                          selectedCustomerAccountType = 'business';
                        } else {
                          selectedRole = 'customer';
                          selectedCustomerAccountType = 'retail';
                        }

                        pendingConfirmationEmail = null;
                        _signupTutorialFuture = fetchPublishedHelpTutorial(
                          placement: 'signup',
                          audience: 'all',
                        );
                      }
                    });
                    if (AppConfig.turnstileConfigured) {
                      _captchaController.refreshToken().catchError(
                        (error) {
                          farmDebugLog('Turnstile refresh failed: $error');
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
            const SizedBox(height: 16),
            const _PremiumAuthDivider(label: 'or join HPJ another way'),
            const SizedBox(height: 14),
            _registrationChoiceCard(
              icon: Icons.storefront_outlined,
              title: 'Business account',
              subtitle: 'Wholesale buying for your business',
              onTap: _useBusinessRegistration,
            ),
            const SizedBox(height: 10),
            _registrationChoiceCard(
              icon: Icons.agriculture_outlined,
              title: 'Farmer partner',
              subtitle: 'Apply to supply produce to HPJ',
              onTap: _useFarmerRegistration,
            ),
          ],
          const SizedBox(height: 18),
          const _PremiumAuthSecurityStrip(),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EF),
      appBar: widget.returnToPrevious
          ? AppBar(
              title: Text(
                isRegister
                    ? widget.lockRegistrationAudience &&
                            widget.initialRegistrationAudience
                                    .trim()
                                    .toLowerCase() ==
                                'farmer'
                        ? 'Farmer Signup'
                        : widget.lockRegistrationAudience &&
                                widget.initialRegistrationAudience
                                        .trim()
                                        .toLowerCase() ==
                                    'business'
                            ? 'Business Signup'
                            : 'Create account'
                    : 'Sign in',
              ),
              backgroundColor: const Color(0xFFF8F5EF),
              surfaceTintColor: Colors.transparent,
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final medium = constraints.maxWidth >= 700;

            if (wide) {
              return Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 12, 24),
                      child: _PremiumAuthBrandPanel(
                        register: isRegister,
                        business: isBusinessRegistration,
                        farmer: isFarmerRegistration,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(36, 34, 40, 42),
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: mainAuthContent(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                medium ? 34 : 18,
                16,
                medium ? 34 : 18,
                34,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PremiumAuthBrandPanel(
                          register: isRegister,
                          business: isBusinessRegistration,
                          farmer: isFarmerRegistration,
                          compact: true,
                        ),
                        const SizedBox(height: 22),
                        mainAuthContent(),
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

class _PremiumAuthBrandPanel extends StatelessWidget {
  final bool register;
  final bool business;
  final bool farmer;
  final bool compact;

  const _PremiumAuthBrandPanel({
    required this.register,
    required this.business,
    required this.farmer,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final message = business
        ? 'Plan better. Buy smarter.'
        : farmer
            ? 'Grow. Supply. Succeed.'
            : register
                ? 'One account. More opportunity.'
                : 'Welcome back to HPJ.';

    final supporting = business
        ? 'Wholesale tools built around how Jamaican businesses source fresh produce.'
        : farmer
            ? 'Connect your farm to demand, collections and opportunities across HPJ.'
            : 'Fresh produce, farmer supply and business purchasing connected in one trusted marketplace.';

    return Container(
      constraints: BoxConstraints(
        minHeight: compact ? 170 : 620,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 28 : 34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF073F2C),
            Color(0xFF0B5A3E),
            Color(0xFF174F37),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF123D30).withOpacity(0.16),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: compact ? -34 : -90,
            top: compact ? -54 : -70,
            child: Container(
              width: compact ? 150 : 310,
              height: compact ? 150 : 310,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE7BC58).withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            left: compact ? -44 : -85,
            bottom: compact ? -70 : -95,
            child: Container(
              width: compact ? 160 : 300,
              height: compact ? 160 : 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.055),
              ),
            ),
          ),
          Positioned(
            right: compact ? 18 : 34,
            bottom: compact ? 16 : 34,
            child: Icon(
              farmer
                  ? Icons.agriculture_rounded
                  : business
                      ? Icons.storefront_rounded
                      : Icons.eco_rounded,
              color: Colors.white.withOpacity(compact ? 0.11 : 0.08),
              size: compact ? 92 : 210,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 20 : 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (!compact)
                  Container(
                    width: 98,
                    height: 64,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Image.asset(
                      'lib/assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.eco_outlined,
                        color: Color(0xFF0B5A3E),
                        size: 34,
                      ),
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7BC58),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'THE HARVEST PLACE JA',
                          style: TextStyle(
                            color: Color(0xFFF0D48A),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.25,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 10 : 18),
                    Text(
                      message,
                      maxLines: compact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 25 : 42,
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: compact ? -0.7 : -1.4,
                      ),
                    ),
                    SizedBox(height: compact ? 7 : 14),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: compact ? 420 : 410,
                      ),
                      child: Text(
                        supporting,
                        maxLines: compact ? 2 : 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFFE1ECE6),
                          fontSize: compact ? 11.3 : 15,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!compact)
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PremiumAuthBenefitRow(
                        icon: Icons.verified_user_outlined,
                        title: 'Secure account access',
                        body: 'Your approved HPJ workspaces stay connected.',
                      ),
                      SizedBox(height: 16),
                      _PremiumAuthBenefitRow(
                        icon: Icons.sync_alt_rounded,
                        title: 'Switch workspaces anytime',
                        body: 'Shop, supply or manage without another login.',
                      ),
                      SizedBox(height: 16),
                      _PremiumAuthBenefitRow(
                        icon: Icons.location_on_outlined,
                        title: 'Built for Jamaica',
                        body:
                            'A marketplace designed around local agriculture.',
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumAuthBenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _PremiumAuthBenefitRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Icon(icon, color: const Color(0xFFF0D48A), size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: const TextStyle(
                  color: Color(0xFFC8DBD1),
                  fontSize: 11.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PremiumAuthDivider extends StatelessWidget {
  final String label;

  const _PremiumAuthDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFDEDCD5))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF959A97),
              fontSize: 9.2,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFDEDCD5))),
      ],
    );
  }
}

class _PremiumAuthInfoPanel extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool gold;

  const _PremiumAuthInfoPanel({
    required this.icon,
    required this.text,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = gold ? const Color(0xFFB67910) : const Color(0xFF0B5A3E);
    final background = gold ? const Color(0xFFFFF5E4) : const Color(0xFFEEF6EF);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF3E554B),
                fontSize: 11.3,
                height: 1.38,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumAuthSecurityStrip extends StatelessWidget {
  const _PremiumAuthSecurityStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE4DA)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.shield_outlined,
            color: Color(0xFF0B5A3E),
            size: 20,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Secure sign-in • One HPJ account • Your workspace permissions stay protected',
              style: TextStyle(
                color: Color(0xFF64706A),
                fontSize: 10.7,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
      child: SizedBox(
        width: 20,
        height: 20,
        child: Image.asset(
          'lib/assets/images/google_g.png',
          width: 20,
          height: 20,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) {
            // Keep the current HPJ Google mark only as a defensive fallback.
            return const CustomPaint(
              painter: _GoogleGMarkPainter(),
            );
          },
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
    final stroke = size.shortestSide * 0.175;
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    Paint strokePaint(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.square;

    // Google-style four-colour ring.
    canvas.drawArc(
      rect,
      -0.25 * _pi,
      0.50 * _pi,
      false,
      strokePaint(const Color(0xFF4285F4)),
    );
    canvas.drawArc(
      rect,
      0.25 * _pi,
      0.50 * _pi,
      false,
      strokePaint(const Color(0xFF34A853)),
    );
    canvas.drawArc(
      rect,
      0.75 * _pi,
      0.36 * _pi,
      false,
      strokePaint(const Color(0xFFFBBC05)),
    );
    canvas.drawArc(
      rect,
      1.11 * _pi,
      0.64 * _pi,
      false,
      strokePaint(const Color(0xFFEA4335)),
    );

    // Open the right side of the ring, then draw the familiar blue G crossbar.
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx + stroke * 0.20,
        center.dy - stroke * 0.58,
        size.width,
        stroke * 1.16,
      ),
      white,
    );

    final blue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          center.dx - stroke * 0.10,
          center.dy - stroke * 0.45,
          size.width * 0.46,
          stroke * 0.90,
        ),
        Radius.circular(stroke * 0.20),
      ),
      blue,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.72,
          center.dy - stroke * 0.45,
          stroke * 0.90,
          size.height * 0.28,
        ),
        Radius.circular(stroke * 0.20),
      ),
      blue,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleGMarkPainter oldDelegate) => false;
}

class _HpjCustomerWebStorefrontShell extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final int cartCount;
  final bool signedIn;
  final VoidCallback onHome;
  final VoidCallback onPublicHome;
  final VoidCallback onFeed;
  final VoidCallback onShop;
  final VoidCallback onFarms;
  final VoidCallback onRecipes;
  final VoidCallback onDemand;
  final VoidCallback onFarmer;
  final VoidCallback onBusiness;
  final VoidCallback onAdmin;
  final VoidCallback onMyBox;
  final VoidCallback onOrders;
  final VoidCallback onAccount;

  const _HpjCustomerWebStorefrontShell({
    required this.body,
    required this.selectedIndex,
    required this.cartCount,
    required this.signedIn,
    required this.onHome,
    required this.onPublicHome,
    required this.onFeed,
    required this.onShop,
    required this.onFarms,
    required this.onRecipes,
    required this.onDemand,
    required this.onFarmer,
    required this.onBusiness,
    required this.onAdmin,
    required this.onMyBox,
    required this.onOrders,
    required this.onAccount,
  });

  static const Color _forest = Color(0xFF073F2C);
  static const Color _line = Color(0xFFE1E8DF);
  static const Color _cream = Color(0xFFF8F8F3);
  static const Color _gold = Color(0xFFFFC62A);

  String _signedInDisplayName() {
    final user = supabase.auth.currentUser;
    if (user == null) return '';

    final metadata = user.userMetadata ?? const <String, dynamic>{};

    final fullName = metadata['full_name']?.toString().trim() ?? '';
    if (fullName.isNotEmpty) return fullName;

    final displayName = metadata['display_name']?.toString().trim() ?? '';
    if (displayName.isNotEmpty) return displayName;

    final name = metadata['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;

    final firstName = metadata['first_name']?.toString().trim() ?? '';
    final lastName = metadata['last_name']?.toString().trim() ?? '';

    final combinedName = [
      firstName,
      lastName,
    ].where((part) => part.isNotEmpty).join(' ').trim();

    if (combinedName.isNotEmpty) return combinedName;

    final email = user.email?.trim() ?? '';
    if (email.isNotEmpty && email.contains('@')) {
      final local = email.split('@').first.trim();

      if (local.isNotEmpty) {
        return local
            .split(RegExp(r'[._-]+'))
            .where((part) => part.trim().isNotEmpty)
            .map(
              (part) => part.length == 1
                  ? part.toUpperCase()
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' ');
      }
    }

    return 'My Account';
  }

  Widget _navLink({
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: _forest,
          backgroundColor:
              active ? const Color(0xFFEAF2E7) : Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: TextStyle(
            fontSize: 10.2,
            fontWeight: active ? FontWeight.w900 : FontWeight.w800,
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _utilityButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
    int badgeCount = 0,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        OutlinedButton.icon(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: _forest,
            backgroundColor: active ? const Color(0xFFEAF2E7) : Colors.white,
            side: BorderSide(
              color: active ? const Color(0xFFBCD2C0) : const Color(0xFFD6E0D6),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          icon: Icon(icon, size: 16),
          label: Text(label),
        ),
        if (badgeCount > 0)
          Positioned(
            top: -6,
            right: -5,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
              ),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _gold,
                shape: BoxShape.circle,
              ),
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                style: const TextStyle(
                  color: _forest,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _iconUtilityButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool active = false,
    int badgeCount = 0,
  }) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: active ? const Color(0xFFEAF2E7) : Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  icon,
                  size: 21,
                  color: _forest,
                ),
              ),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -3,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    color: _forest,
                    fontSize: 7.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signedInName = signedIn ? _signedInDisplayName() : '';

    final homeActive = selectedIndex == 0;
    final shopActive = selectedIndex == 1;
    final myBoxActive = selectedIndex == 2;
    final ordersActive = selectedIndex == 3;
    final accountActive = selectedIndex == 4;

    return Scaffold(
      backgroundColor: _cream,
      body: Column(
        children: [
          Material(
            color: Colors.white,
            elevation: 0,
            child: Container(
              height: 72,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: _line),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1580,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                    ),
                    child: Row(
                      children: [
                        Tooltip(
                          message: 'HPJ Homepage',
                          child: InkWell(
                            onTap: onPublicHome,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 47,
                                    height: 47,
                                    child: Image.asset(
                                      'lib/assets/images/logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.eco_rounded,
                                        color: _forest,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'The Harvest Place Ja',
                                        style: TextStyle(
                                          color: _forest,
                                          fontSize: 13.4,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Fresh • Local • Jamaican',
                                        style: TextStyle(
                                          color: Color(0xFF58725F),
                                          fontSize: 8.1,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final compact = constraints.maxWidth < 1040;

                              return Row(
                                children: [
                                  _navLink(
                                    label: 'Home',
                                    onTap: onHome,
                                    active: homeActive,
                                  ),
                                  _navLink(
                                    label: 'Meal Pulse',
                                    onTap: onFeed,
                                  ),
                                  _navLink(
                                    label: 'Shop',
                                    onTap: onShop,
                                    active: shopActive,
                                  ),
                                  _navLink(
                                    label: 'Farms',
                                    onTap: onFarms,
                                  ),
                                  if (!compact)
                                    _navLink(
                                      label: 'Recipes',
                                      onTap: onRecipes,
                                    ),
                                  if (!compact)
                                    _navLink(
                                      label: 'GrowTogether',
                                      onTap: onDemand,
                                    ),
                                  if (compact)
                                    PopupMenuButton<String>(
                                      tooltip: 'More',
                                      onSelected: (value) {
                                        if (value == 'recipes') {
                                          onRecipes();
                                        } else if (value == 'demand') {
                                          onDemand();
                                        } else if (value == 'farmer') {
                                          onFarmer();
                                        } else if (value == 'business') {
                                          onBusiness();
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem<String>(
                                          value: 'recipes',
                                          child: Text('Recipes'),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'demand',
                                          child: Text(
                                            'GrowTogether',
                                          ),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'farmer',
                                          child: Text('Farmer'),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'business',
                                          child: Text('Business'),
                                        ),
                                      ],
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 9,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.more_horiz_rounded,
                                              size: 18,
                                              color: _forest,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'More',
                                              style: TextStyle(
                                                color: _forest,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  const Spacer(),
                                  InkWell(
                                    onTap: onShop,
                                    borderRadius: BorderRadius.circular(999),
                                    child: Container(
                                      width: compact ? 190 : 285,
                                      height: 42,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F5F1),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.search_rounded,
                                            size: 18,
                                            color: _forest,
                                          ),
                                          SizedBox(width: 9),
                                          Expanded(
                                            child: Text(
                                              'Search produce, farms, meals, or recipes...',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Color(0xFF718078),
                                                fontSize: 9.2,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (!compact)
                                    Container(
                                      height: 42,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F9F5),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: _line,
                                        ),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_rounded,
                                            size: 16,
                                            color: _forest,
                                          ),
                                          SizedBox(width: 5),
                                          Text(
                                            'Jamaica',
                                            style: TextStyle(
                                              color: _forest,
                                              fontSize: 9.2,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          SizedBox(width: 2),
                                          Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 16,
                                            color: _forest,
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(width: 4),
                                  _iconUtilityButton(
                                    icon: Icons.shopping_bag_outlined,
                                    tooltip: cartCount > 0
                                        ? 'My Box ($cartCount)'
                                        : 'My Box',
                                    onTap: onMyBox,
                                    active: myBoxActive,
                                    badgeCount: cartCount,
                                  ),
                                  const SizedBox(width: 2),
                                  _iconUtilityButton(
                                    icon: Icons.receipt_long_outlined,
                                    tooltip: 'Orders',
                                    onTap: onOrders,
                                    active: ordersActive,
                                  ),
                                  const SizedBox(width: 2),
                                  const HpjInboxActionButton(),
                                  const SizedBox(width: 6),
                                  if (signedIn)
                                    FutureBuilder<String>(
                                      future: _resolveHpjWebsiteSignedInName(),
                                      initialData: signedInName,
                                      builder: (context, nameSnapshot) {
                                        final fullName =
                                            (nameSnapshot.data ?? signedInName)
                                                .trim();

                                        final compactName =
                                            _hpjWebsiteCompactSignedInName(
                                          fullName,
                                        );

                                        final initial = compactName.isEmpty
                                            ? 'A'
                                            : compactName
                                                .substring(0, 1)
                                                .toUpperCase();

                                        return FutureBuilder<
                                            _HpjWebsiteStaffAccess>(
                                          future:
                                              _resolveHpjWebsiteStaffAccess(),
                                          initialData:
                                              _HpjWebsiteStaffAccess.none,
                                          builder: (
                                            context,
                                            staffSnapshot,
                                          ) {
                                            final staffAccess =
                                                staffSnapshot.data ??
                                                    _HpjWebsiteStaffAccess.none;

                                            return PopupMenuButton<String>(
                                              tooltip: fullName.isEmpty
                                                  ? 'Account'
                                                  : fullName,
                                              position: PopupMenuPosition.under,
                                              onSelected: (value) {
                                                if (value == 'account') {
                                                  onAccount();
                                                } else if (value == 'farmer') {
                                                  onFarmer();
                                                } else if (value ==
                                                    'business') {
                                                  onBusiness();
                                                } else if (value == 'admin') {
                                                  onAdmin();
                                                }
                                              },
                                              itemBuilder: (_) =>
                                                  <PopupMenuEntry<String>>[
                                                const PopupMenuItem<String>(
                                                  value: 'account',
                                                  child: Text('Account'),
                                                ),
                                                const PopupMenuItem<String>(
                                                  value: 'farmer',
                                                  child: Text('Farmer Portal'),
                                                ),
                                                const PopupMenuItem<String>(
                                                  value: 'business',
                                                  child:
                                                      Text('Business Portal'),
                                                ),
                                                if (staffAccess.allowed) ...[
                                                  const PopupMenuDivider(),
                                                  PopupMenuItem<String>(
                                                    value: 'admin',
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .admin_panel_settings_outlined,
                                                          size: 19,
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),
                                                        Expanded(
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                staffAccess
                                                                    .menuLabel,
                                                                style:
                                                                    const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                ),
                                                              ),
                                                              Text(
                                                                staffAccess
                                                                    .roleLabel,
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 10,
                                                                  color: Color(
                                                                    0xFF667169,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                              child: Container(
                                                height: 44,
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                  6,
                                                  5,
                                                  10,
                                                  5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    999,
                                                  ),
                                                  border: Border.all(
                                                    color: staffAccess.allowed
                                                        ? const Color(
                                                            0xFF0B5A3F,
                                                          )
                                                        : _line,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 16,
                                                      backgroundColor:
                                                          staffAccess.allowed
                                                              ? const Color(
                                                                  0xFFE0F0E5,
                                                                )
                                                              : const Color(
                                                                  0xFFEAF2E7,
                                                                ),
                                                      child: Icon(
                                                        staffAccess.allowed
                                                            ? Icons
                                                                .admin_panel_settings_outlined
                                                            : Icons
                                                                .person_outline_rounded,
                                                        size: 16,
                                                        color: _forest,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 7),
                                                    ConstrainedBox(
                                                      constraints:
                                                          BoxConstraints(
                                                        maxWidth:
                                                            compact ? 72 : 110,
                                                      ),
                                                      child: Text(
                                                        compactName,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          color: _forest,
                                                          fontSize: 9.5,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 3),
                                                    const Icon(
                                                      Icons
                                                          .keyboard_arrow_down_rounded,
                                                      size: 16,
                                                      color: _forest,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    )
                                  else
                                    FilledButton(
                                      onPressed: onAccount,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _forest,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Sign In'),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1580,
                ),
                child: body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HPJ MOBILE M1 — ONE ACCOUNT / AUTHORIZED PORTALS
// Native-app only presentation. Existing Flutter Web account/workspace UI is
// intentionally left unchanged so the website remains frozen.
// ============================================================================

String _hpjMobilePortalKey(String value) {
  final clean = value.trim().toLowerCase();
  if (clean == 'business') return 'wholesale';
  if (clean == 'admin') return 'staff';
  return clean;
}

String _hpjMobileCompactName(String value) {
  final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (clean.isEmpty) return 'Account';
  return clean.split(' ').first;
}

String _hpjMobileAccountAvatarUrl() {
  final metadata =
      supabase.auth.currentUser?.userMetadata ?? const <String, dynamic>{};

  for (final key in const <String>[
    'avatar_url',
    'picture',
    'photo_url',
    'profile_photo_url',
  ]) {
    final value = metadata[key]?.toString().trim() ?? '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
  }

  return '';
}

Widget _hpjMobileAccountAvatar({
  required String initial,
  required double radius,
}) {
  final imageUrl = _hpjMobileAccountAvatarUrl();
  final diameter = radius * 2;

  if (imageUrl.isNotEmpty) {
    return ClipOval(
      child: Image.network(
        imageUrl,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CircleAvatar(
          radius: radius,
          backgroundColor: FarmColors.primarySoft,
          child: Text(
            initial,
            style: TextStyle(
              color: FarmColors.deepGreen,
              fontSize: radius * .72,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  return CircleAvatar(
    radius: radius,
    backgroundColor: FarmColors.primarySoft,
    child: Text(
      initial,
      style: TextStyle(
        color: FarmColors.deepGreen,
        fontSize: radius * .72,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

Future<void> _openHpjMobilePortalRoot(
  BuildContext context, {
  required String portal,
}) async {
  if (!context.mounted) return;

  final normalized = _hpjMobilePortalKey(portal);
  OwnerWorkspaceAccessSnapshot? access;

  if (normalized != 'staff') {
    try {
      access = await fetchOwnerWorkspaceAccessSnapshot();
    } catch (error) {
      farmDebugLog('Workspace access check failed before portal open: $error');
    }
  }

  if (!context.mounted) return;

  final settings =
      access?.programSettings ?? MarketplaceProgramSettings.fallback;
  final ownerBypass = normalizeStaffRole(access?.staffRole ?? '') == 'owner';
  Widget destination;

  switch (normalized) {
    case 'farmer':
      final approved = access?.isApprovedFarmer == true;
      final mode = settings.farmerWorkspaceMode;
      if (approved && !hpjWorkspaceModeIsLive(mode) && !ownerBypass) {
        destination = HpjWorkspaceAvailabilityScreen(
          workspace: 'farmer',
          mode: mode,
          message: settings.farmerMaintenanceMessage,
          returnNote: settings.farmerReturnNote,
          currentPortal: 'farmer',
          onRefresh: () => unawaited(
            _openHpjMobilePortalRoot(context, portal: 'farmer'),
          ),
        );
      } else {
        destination = HpjManagedWelcomeGate(
          audience: 'farmer',
          child: FarmerAccessGate(
            bypassWorkspaceGate: ownerBypass && !hpjWorkspaceModeIsLive(mode),
          ),
        );
      }
      unawaited(saveHpjNavigationPreference(workspace: 'farmer', tab: 0));
      break;

    case 'wholesale':
      final approved = access?.isApprovedWholesale == true;
      final mode = settings.wholesaleWorkspaceMode;
      if (approved && !hpjWorkspaceModeIsLive(mode) && !ownerBypass) {
        destination = HpjWorkspaceAvailabilityScreen(
          workspace: 'wholesale',
          mode: mode,
          message: settings.wholesaleMaintenanceMessage,
          returnNote: settings.wholesaleReturnNote,
          currentPortal: 'wholesale',
          onRefresh: () => unawaited(
            _openHpjMobilePortalRoot(context, portal: 'wholesale'),
          ),
        );
      } else {
        destination = HpjManagedWelcomeGate(
          audience: 'business',
          child: BusinessWholesaleHubScreen(
            bypassWorkspaceGate: ownerBypass && !hpjWorkspaceModeIsLive(mode),
          ),
        );
      }
      unawaited(saveHpjNavigationPreference(workspace: 'wholesale', tab: 0));
      break;

    case 'staff':
      try {
        await requireAdminAccess();
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyAppError(error))),
        );
        return;
      }
      destination = const AdminDashboardScreen();
      break;

    case 'customer':
    default:
      final mode = settings.customerWorkspaceMode;
      if (!hpjWorkspaceModeIsLive(mode) && !ownerBypass) {
        destination = HpjWorkspaceAvailabilityScreen(
          workspace: 'customer',
          mode: mode,
          message: settings.customerMaintenanceMessage,
          returnNote: settings.customerReturnNote,
          currentPortal: 'customer',
          onRefresh: () => unawaited(
            _openHpjMobilePortalRoot(context, portal: 'customer'),
          ),
        );
      } else {
        destination = HpjManagedWelcomeGate(
          audience: 'customer',
          child: MainNavigation(
            bypassWorkspaceGate: ownerBypass && !hpjWorkspaceModeIsLive(mode),
          ),
        );
      }
      unawaited(saveHpjNavigationPreference(workspace: 'customer', tab: 0));
      break;
  }

  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => destination),
    (route) => false,
  );
}

/// Customer-brand navigation used by tappable HPJ logos in the app.
/// If the logo is tapped inside MainNavigation, return to the existing Home
/// tab without rebuilding the whole app. From a pushed Customer screen, reset
/// cleanly to the Customer Home root.
void openHpjCustomerHomeFromLogo(BuildContext context) {
  final navigationState =
      context.findAncestorStateOfType<_MainNavigationState>();

  if (navigationState != null) {
    if (hpjUseMobileAppPresentation(context)) {
      navigationState._selectMobileCustomerTab(0);
    } else {
      navigationState._selectCustomerTab(0);
    }
    return;
  }

  unawaited(
    saveHpjNavigationPreference(
      workspace: 'customer',
      tab: 0,
    ),
  );

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (_) => const HpjManagedWelcomeGate(
        audience: 'customer',
        child: MainNavigation(initialIndex: 0),
      ),
    ),
    (route) => false,
  );
}

// HPJ ACCOUNT NAVIGATION — return to the Admin-managed Welcome page.
// This is navigation only: no sign-out, account switch, or settings mutation.
void openHpjWelcomeFromWorkspace(BuildContext context) {
  // The Customer cart is already stored on changes. Persist it once more
  // before replacing the navigation root so a return to Shop restores it.
  context.findAncestorStateOfType<_MainNavigationState>()?.persistCart();
  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil<void>(
    MaterialPageRoute<void>(
      builder: (_) => const AuthGate(forceWelcome: true),
    ),
    (route) => false,
  );
}

class _HpjMobilePortalRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool current;
  final bool enabled;
  final VoidCallback? onTap;

  const _HpjMobilePortalRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.current,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: current ? const Color(0xFFEAF4EA) : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: current
                      ? const Color(0xFFD9EBDD)
                      : const Color(0xFFF2F5EF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: enabled ? FarmColors.deepGreen : FarmColors.mutedText,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: enabled
                                  ? FarmColors.ink
                                  : FarmColors.mutedText,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (current)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: FarmColors.primary,
                            size: 18,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: enabled
                            ? FarmColors.mutedText
                            : FarmColors.mutedText.withOpacity(.75),
                        fontSize: 9.3,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!current && enabled)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: FarmColors.mutedText,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showHpjMobileAccountPortalSheet(
  BuildContext context, {
  required String currentPortal,
}) async {
  if (!isLoggedIn || supabase.auth.currentUser == null) return;

  // Desktop/tablet website remains frozen. Real mobile builds and the narrow
  // FlutLab phone preview use the Account menu instead of the old Workspace page.
  if (!hpjUseMobileAppPresentation(context)) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => OwnerWorkspaceSwitcherScreen(
          currentWorkspace: currentPortal,
        ),
      ),
    );
    return;
  }

  final parentContext = context;
  final accessFuture = fetchOwnerWorkspaceAccessSnapshot();
  final nameFuture = _resolveHpjWebsiteSignedInName();
  final user = supabase.auth.currentUser!;
  final current = _hpjMobilePortalKey(currentPortal);

  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      Future<void> openPortal(String portal) async {
        Navigator.of(sheetContext).pop();
        await Future<void>.delayed(Duration.zero);
        if (!parentContext.mounted) return;
        await _openHpjMobilePortalRoot(
          parentContext,
          portal: portal,
        );
      }

      Future<void> signOut() async {
        Navigator.of(sheetContext).pop();
        await signOutFromHpjSession();
        if (!parentContext.mounted) return;
        Navigator.of(parentContext).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }

      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * .88,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFEFB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: FutureBuilder<OwnerWorkspaceAccessSnapshot>(
          future: accessFuture,
          builder: (context, accessSnapshot) {
            final access = accessSnapshot.data;
            final farmer = access?.farmerProfile;
            final business = access?.businessAccount;
            final settings = access?.programSettings;
            final staffRole = normalizeStaffRole(access?.staffRole ?? '');
            final hasStaff = access?.hasStaffAccess == true;

            final farmerApproved = farmer?.isApproved == true;
            final businessApproved = business?.isApproved == true;

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7DCD4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FutureBuilder<String>(
                  future: nameFuture,
                  builder: (context, nameSnapshot) {
                    final name = (nameSnapshot.data ?? '').trim();
                    final safeName = name.isEmpty ? 'HPJ Member' : name;
                    final initial = safeName.substring(0, 1).toUpperCase();

                    return Row(
                      children: [
                        _hpjMobileAccountAvatar(
                          initial: initial,
                          radius: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                safeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: FarmColors.ink,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'YOUR LOGINS',
                  style: TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 9.4,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .9,
                  ),
                ),
                const SizedBox(height: 8),
                _HpjMobilePortalRow(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Shop HPJ',
                  subtitle: 'Shopping, My Box, orders and Meal Pulse',
                  current: current == 'customer',
                  enabled: true,
                  onTap: current == 'customer'
                      ? () => Navigator.of(sheetContext).pop()
                      : () => openPortal('customer'),
                ),
                if (farmer != null ||
                    settings?.farmerApplicationsEnabled == true) ...[
                  const SizedBox(height: 4),
                  _HpjMobilePortalRow(
                    icon: Icons.agriculture_outlined,
                    title: farmerApproved ? 'Farmer' : 'Farmer Application',
                    subtitle: farmerApproved
                        ? (farmer!.farmName.trim().isEmpty
                            ? 'Supply, demand, collections and farm tools'
                            : farmer.farmName.trim())
                        : farmer == null
                            ? 'Apply to supply produce to HPJ'
                            : '${farmer.statusLabel} • Review your application',
                    current: current == 'farmer',
                    enabled: true,
                    onTap: current == 'farmer'
                        ? () => Navigator.of(sheetContext).pop()
                        : () => openPortal('farmer'),
                  ),
                ],
                if (business != null ||
                    settings?.wholesaleApplicationsEnabled == true) ...[
                  const SizedBox(height: 4),
                  _HpjMobilePortalRow(
                    icon: Icons.business_outlined,
                    title:
                        businessApproved ? 'Business' : 'Business Application',
                    subtitle: businessApproved
                        ? 'Wholesale sourcing, planning and orders'
                        : business == null
                            ? 'Apply for wholesale business access'
                            : '${businessAccountStatusLabel(business.status)} • Review your application',
                    current: current == 'wholesale',
                    enabled: true,
                    onTap: current == 'wholesale'
                        ? () => Navigator.of(sheetContext).pop()
                        : () => openPortal('wholesale'),
                  ),
                ],
                if (hasStaff) ...[
                  const SizedBox(height: 4),
                  _HpjMobilePortalRow(
                    icon: Icons.admin_panel_settings_outlined,
                    title: staffRole == 'owner' || staffRole == 'manager'
                        ? 'Admin'
                        : 'Staff',
                    subtitle: staffRole.isEmpty
                        ? 'HPJ operations'
                        : staffRoleDisplayLabel(staffRole),
                    current: current == 'staff',
                    enabled: true,
                    onTap: current == 'staff'
                        ? () => Navigator.of(sheetContext).pop()
                        : () => openPortal('staff'),
                  ),
                ],
                if (accessSnapshot.connectionState == ConnectionState.waiting &&
                    access == null) ...[
                  const SizedBox(height: 12),
                  const Center(child: CircularProgressIndicator()),
                ],
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: const Icon(
                    Icons.manage_accounts_outlined,
                    color: FarmColors.deepGreen,
                  ),
                  title: const Text(
                    'Account settings',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Future.microtask(() {
                      if (!parentContext.mounted) return;
                      Navigator.of(parentContext).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const CustomerProfileScreen(),
                        ),
                      );
                    });
                  },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: const Icon(
                    Icons.arrow_back_rounded,
                    color: FarmColors.deepGreen,
                  ),
                  title: const Text(
                    'Back to Welcome',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle:
                      const Text('Choose a workspace without signing out.'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    openHpjWelcomeFromWorkspace(parentContext);
                  },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: FarmColors.danger,
                  ),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: FarmColors.danger,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onTap: signOut,
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

class HpjMobileAccountPortalButton extends StatelessWidget {
  final String currentPortal;
  final bool compact;

  const HpjMobileAccountPortalButton({
    super.key,
    required this.currentPortal,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!hpjUseMobileAppPresentation(context) ||
        !isLoggedIn ||
        supabase.auth.currentUser == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<String>(
      future: _resolveHpjWebsiteSignedInName(),
      builder: (context, snapshot) {
        final raw = (snapshot.data ?? '').trim();
        final name = raw.isEmpty ? 'Account' : _hpjMobileCompactName(raw);
        final initial = name.substring(0, 1).toUpperCase();

        return Tooltip(
          message: 'Account',
          child: Material(
            color: const Color(0xFFFFFEFB),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => showHpjMobileAccountPortalSheet(
                context,
                currentPortal: currentPortal,
              ),
              child: Container(
                height: 42,
                padding: EdgeInsets.fromLTRB(
                  5,
                  4,
                  compact ? 7 : 10,
                  4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE2E7DE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _hpjMobileAccountAvatar(
                      initial: initial,
                      radius: 15,
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 7),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 72),
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FarmColors.deepGreen,
                            fontSize: 10.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: FarmColors.deepGreen,
                      size: 17,
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

class HpjMobilePortalAccessCard extends StatelessWidget {
  final String currentPortal;

  const HpjMobilePortalAccessCard({
    super.key,
    required this.currentPortal,
  });

  @override
  Widget build(BuildContext context) {
    if (!hpjUseMobileAppPresentation(context) || !isLoggedIn) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<String>(
      future: _resolveHpjWebsiteSignedInName(),
      builder: (context, snapshot) {
        final raw = (snapshot.data ?? '').trim();
        final name = raw.isEmpty ? 'Your HPJ account' : raw;
        final initial = name.substring(0, 1).toUpperCase();

        return Material(
          color: const Color(0xFFF4F8F1),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => showHpjMobileAccountPortalSheet(
              context,
              currentPortal: currentPortal,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: FarmColors.green.withOpacity(.12)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 21,
                    backgroundColor: const Color(0xFFDDEBDD),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: FarmColors.deepGreen,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FarmColors.ink,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Account • profile, settings and other logins',
                          style: TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 9.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: FarmColors.deepGreen,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// =====================================================
// HPJ GLOBAL MOBILE PORTAL HEADER
// One consistent mobile utility header for Customer, Farmer, Business and
// Admin/Staff. Desktop website headers remain unchanged.
// =====================================================
const List<String> _hpjPortalParishes = <String>[
  'Hanover',
  'Westmoreland',
  'St. James',
  'Trelawny',
  'St. Elizabeth',
  'Manchester',
  'Clarendon',
  'St. Ann',
  'St. Catherine',
  'St. Mary',
  'St. Andrew',
  'Kingston',
  'Portland',
  'St. Thomas',
];

String _hpjCanonicalPortalParish(String value) {
  final clean = value.trim();
  if (clean.isEmpty) return 'St. Elizabeth';

  String key(String input) => input
      .trim()
      .toLowerCase()
      .replaceAll('saint ', 'st ')
      .replaceAll('.', '')
      .replaceAll(' parish', '')
      .replaceAll(RegExp(r'\s+'), ' ');

  final normalized = key(clean.split('•').first.split(' - ').first);
  for (final parish in _hpjPortalParishes) {
    if (key(parish) == normalized) return parish;
  }
  return 'St. Elizabeth';
}

class HpjPortalUtilityHeader extends StatefulWidget {
  final String currentPortal;
  final bool includeInbox;
  final VoidCallback? onRefresh;
  final bool safeArea;
  final EdgeInsetsGeometry padding;

  const HpjPortalUtilityHeader({
    super.key,
    required this.currentPortal,
    this.includeInbox = false,
    this.onRefresh,
    this.safeArea = true,
    this.padding = const EdgeInsets.fromLTRB(14, 8, 14, 7),
  });

  @override
  State<HpjPortalUtilityHeader> createState() => _HpjPortalUtilityHeaderState();
}

class _HpjPortalUtilityHeaderState extends State<HpjPortalUtilityHeader> {
  String _parish = 'St. Elizabeth';
  late Future<String> _nameFuture;
  Future<List<FarmNotification>>? _notificationsFuture;
  Future<int>? _inboxUnreadFuture;
  Future<OwnerWorkspaceAccessSnapshot>? _accessFuture;

  @override
  void initState() {
    super.initState();
    _nameFuture = _resolveHpjWebsiteSignedInName();
    _reloadPrivateFutures();
    unawaited(_restoreParish());
  }

  void _reloadPrivateFutures() {
    if (isLoggedIn && supabase.auth.currentUser != null) {
      _notificationsFuture = fetchFarmNotifications();
      _inboxUnreadFuture = widget.includeInbox
          ? (() async {
              try {
                final tickets = await fetchMySupportTickets();
                return tickets
                    .where((ticket) => ticket.hasUnreadForCustomer)
                    .length;
              } catch (_) {
                return 0;
              }
            })()
          : null;
      _accessFuture = fetchOwnerWorkspaceAccessSnapshot();
    } else {
      _notificationsFuture = null;
      _inboxUnreadFuture = null;
      _accessFuture = null;
    }
  }

  String? _profileImageUrl() {
    final metadata =
        supabase.auth.currentUser?.userMetadata ?? const <String, dynamic>{};

    for (final key in const <String>[
      'avatar_url',
      'picture',
      'photo_url',
      'profile_photo_url',
      'image_url',
    ]) {
      final raw = metadata[key]?.toString().trim() ?? '';
      if (raw.isEmpty) continue;
      final uri = Uri.tryParse(raw);
      if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
        return raw;
      }
    }
    return null;
  }

  Future<void> _restoreParish() async {
    try {
      final saved = await HpjSmartLocalStore.readString('shop_near_area');
      final checkout = await HpjSmartLocalStore.readString('checkout_zone');
      final raw = (saved ?? '').trim().isNotEmpty
          ? saved!.trim()
          : (checkout ?? '').trim();
      final next = _hpjCanonicalPortalParish(raw);
      if (!mounted) return;
      setState(() => _parish = next);
    } catch (_) {
      // Keep the safe Jamaica default used throughout HPJ.
    }
  }

  Future<void> _pickParish() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFEFB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          children: [
            const Text(
              'Parish',
              style: TextStyle(
                color: FarmColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -.25,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose the parish HPJ should prioritise for local marketplace information.',
              style: TextStyle(
                color: FarmColors.mutedText,
                fontSize: 10.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ..._hpjPortalParishes.map((parish) {
              final selected = parish == _parish;
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFE6F1E2)
                        : const Color(0xFFF4F7F1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: selected ? FarmColors.green : FarmColors.deepGreen,
                    size: 18,
                  ),
                ),
                title: Text(
                  parish,
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 12.2,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
                  ),
                ),
                trailing: selected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: FarmColors.green,
                        size: 19,
                      )
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(parish),
              );
            }),
          ],
        );
      },
    );

    if (!mounted || picked == null || picked.trim().isEmpty) return;
    final canonical = _hpjCanonicalPortalParish(picked);
    setState(() => _parish = canonical);
    await HpjSmartLocalStore.writeString('shop_near_area', canonical);
    hpjShopParishRequest.value = canonical;
  }

  Future<void> _openSignIn() async {
    final didSignIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const LoginScreen(returnToPrevious: true),
      ),
    );
    if (!mounted) return;
    if (didSignIn == true || isLoggedIn) {
      setState(() {
        _nameFuture = _resolveHpjWebsiteSignedInName();
        _reloadPrivateFutures();
      });
    }
  }

  Future<void> _openNotifications() async {
    if (!isLoggedIn || supabase.auth.currentUser == null) {
      await _openSignIn();
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );

    if (!mounted) return;
    setState(() {
      _notificationsFuture = fetchFarmNotifications();
    });
  }

  Future<void> _handleMenuSelection(String value) async {
    if (value == 'signin') {
      await _openSignIn();
      return;
    }

    if (value == 'inbox') {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const SupportScreen()),
      );
      if (!mounted) return;
      setState(() {
        _inboxUnreadFuture = (() async {
          try {
            final tickets = await fetchMySupportTickets();
            return tickets
                .where((ticket) => ticket.hasUnreadForCustomer)
                .length;
          } catch (_) {
            return 0;
          }
        })();
      });
      return;
    }

    if (value == 'refresh') {
      widget.onRefresh?.call();
      return;
    }

    if (value == 'account') {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const CustomerProfileScreen()),
      );
      return;
    }

    if (value == 'signout') {
      await signOutFromHpjSession();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const AuthGate()),
        (route) => false,
      );
      return;
    }

    if (_hpjMobilePortalKey(value) ==
        _hpjMobilePortalKey(widget.currentPortal)) {
      return;
    }

    await _openHpjMobilePortalRoot(context, portal: value);
  }

  PopupMenuItem<String> _portalItem({
    required String value,
    required IconData icon,
    required String title,
    String? subtitle,
    bool current = false,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: subtitle == null ? 48 : 58,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: current ? FarmColors.primarySoft : const Color(0xFFF4F7F1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: FarmColors.deepGreen),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 12.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 9.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (current)
            const Icon(
              Icons.check_circle_rounded,
              color: FarmColors.green,
              size: 18,
            ),
        ],
      ),
    );
  }

  Widget _profileControl({
    required String name,
    required OwnerWorkspaceAccessSnapshot? access,
    required bool loadingAccess,
  }) {
    final cleanName = name.trim().isEmpty ? 'Account' : name.trim();
    final initial = cleanName.substring(0, 1).toUpperCase();
    final imageUrl = _profileImageUrl();
    final current = _hpjMobilePortalKey(widget.currentPortal);

    if (!isLoggedIn || supabase.auth.currentUser == null) {
      return PopupMenuButton<String>(
        tooltip: '',
        color: const Color(0xFFFFFEFB),
        elevation: 12,
        offset: const Offset(0, 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE0E6DD)),
        ),
        onSelected: (value) => unawaited(_handleMenuSelection(value)),
        itemBuilder: (_) => [
          _portalItem(
            value: 'signin',
            icon: Icons.login_rounded,
            title: 'Log in or Create Account',
            subtitle: 'Access your HPJ portals',
          ),
        ],
        child: _profilePill(initial: '?', imageUrl: null),
      );
    }

    final farmer = access?.farmerProfile;
    final business = access?.businessAccount;
    final settings = access?.programSettings;
    final staffRole = normalizeStaffRole(access?.staffRole ?? '');
    final hasStaff = access?.hasStaffAccess == true;
    final farmerApproved = farmer?.isApproved == true;
    final businessApproved = business?.isApproved == true;

    return PopupMenuButton<String>(
      tooltip: '',
      color: const Color(0xFFFFFEFB),
      elevation: 12,
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE0E6DD)),
      ),
      onSelected: (value) => unawaited(_handleMenuSelection(value)),
      itemBuilder: (_) => <PopupMenuEntry<String>>[
        _portalItem(
          value: 'customer',
          icon: Icons.shopping_bag_outlined,
          title: 'Shop HPJ',
          subtitle: 'Customer marketplace',
          current: current == 'customer',
        ),
        if (farmer != null || settings?.farmerApplicationsEnabled == true)
          _portalItem(
            value: 'farmer',
            icon: Icons.agriculture_outlined,
            title: farmerApproved ? 'Farmer Portal' : 'Farmer Application',
            subtitle: farmerApproved
                ? ((farmer?.farmName.trim().isEmpty ?? true)
                    ? 'Farm tools & supply'
                    : farmer!.farmName.trim())
                : (farmer == null
                    ? 'Apply to supply HPJ'
                    : '${farmer.statusLabel} • Review application'),
            current: current == 'farmer',
          ),
        if (business != null || settings?.wholesaleApplicationsEnabled == true)
          _portalItem(
            value: 'wholesale',
            icon: Icons.business_outlined,
            title:
                businessApproved ? 'Business Portal' : 'Business Application',
            subtitle: businessApproved
                ? 'Wholesale sourcing & orders'
                : (business == null
                    ? 'Apply for business access'
                    : '${businessAccountStatusLabel(business.status)} • Review application'),
            current: current == 'wholesale',
          ),
        if (hasStaff)
          _portalItem(
            value: 'staff',
            icon: Icons.admin_panel_settings_outlined,
            title: staffRole == 'owner' || staffRole == 'manager'
                ? 'Admin Console'
                : 'Staff Portal',
            subtitle: staffRole.isEmpty
                ? 'HPJ operations'
                : staffRoleDisplayLabel(staffRole),
            current: current == 'staff',
          ),
        if (loadingAccess && access == null)
          const PopupMenuItem<String>(
            enabled: false,
            height: 42,
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text(
                  'Loading your HPJ access...',
                  style: TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        const PopupMenuDivider(height: 10),
        if (widget.includeInbox)
          _portalItem(
            value: 'inbox',
            icon: Icons.mail_outline_rounded,
            title: 'Inbox & support',
          ),
        if (widget.onRefresh != null)
          _portalItem(
            value: 'refresh',
            icon: Icons.refresh_rounded,
            title: 'Refresh page',
          ),
        _portalItem(
          value: 'account',
          icon: Icons.manage_accounts_outlined,
          title: 'Account & Settings',
        ),
        const PopupMenuDivider(height: 6),
        const PopupMenuItem<String>(
          value: 'signout',
          height: 46,
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: FarmColors.danger, size: 19),
              SizedBox(width: 11),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: FarmColors.danger,
                  fontSize: 12.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
      child: _profilePill(initial: initial, imageUrl: imageUrl),
    );
  }

  Widget _profilePill({
    required String initial,
    required String? imageUrl,
  }) {
    const size = 44.0;
    return Container(
      height: size,
      padding: const EdgeInsets.fromLTRB(2, 2, 4, 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDDE5DA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF7B1FA2),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: imageUrl == null
                ? Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 2),
          Container(
            width: 19,
            height: 19,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F6EE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: FarmColors.deepGreen,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!hpjUseMobileAppPresentation(context)) {
      return const SizedBox.shrink();
    }

    final content = Container(
      width: double.infinity,
      padding: widget.padding,
      color: FarmColors.background,
      child: Row(
        children: [
          Tooltip(
            message: 'Home',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => openHpjCustomerHomeFromLogo(context),
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 82,
                  height: 36,
                  child: Image.asset(
                    'lib/assets/images/logo.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'HPJ',
                        style: TextStyle(
                          color: FarmColors.deepGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          Semantics(
            button: true,
            label: 'Parish: $_parish',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => unawaited(_pickParish()),
                customBorder: const CircleBorder(),
                child: Ink(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7F1),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFDDE5DA)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.location_on_rounded,
                      color: FarmColors.deepGreen,
                      size: 19,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          FutureBuilder<List<FarmNotification>>(
            future: _notificationsFuture,
            builder: (context, snapshot) {
              final notificationUnread = isLoggedIn
                  ? (snapshot.data ?? const <FarmNotification>[])
                      .where((notice) => !notice.isRead)
                      .length
                  : 0;

              return FutureBuilder<int>(
                future: _inboxUnreadFuture,
                builder: (context, inboxSnapshot) {
                  final unread = notificationUnread +
                      (widget.includeInbox ? (inboxSnapshot.data ?? 0) : 0);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => unawaited(_openNotifications()),
                      customBorder: const CircleBorder(),
                      child: Ink(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFEFB),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E7DE)),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Center(
                              child: Icon(
                                Icons.notifications_none_rounded,
                                color: FarmColors.deepGreen,
                                size: 21,
                              ),
                            ),
                            if (unread > 0)
                              Positioned(
                                right: -1,
                                top: -2,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE53935),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFFFFFEFB),
                                      width: 1.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    unread > 99 ? '99+' : '$unread',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8.5,
                                      height: 1,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 6),
          FutureBuilder<String>(
            future: _nameFuture,
            builder: (context, nameSnapshot) {
              final raw = (nameSnapshot.data ?? '').trim();
              final displayName = raw.isEmpty ? 'Account' : raw;

              if (_accessFuture == null) {
                return _profileControl(
                  name: displayName,
                  access: null,
                  loadingAccess: false,
                );
              }

              return FutureBuilder<OwnerWorkspaceAccessSnapshot>(
                future: _accessFuture,
                builder: (context, accessSnapshot) {
                  return _profileControl(
                    name: displayName,
                    access: accessSnapshot.data,
                    loadingAccess: accessSnapshot.connectionState ==
                        ConnectionState.waiting,
                  );
                },
              );
            },
          ),
        ],
      ),
    );

    if (!widget.safeArea) return content;
    return SafeArea(bottom: false, child: content);
  }
}

PreferredSizeWidget hpjPortalUtilityAppBar({
  required String currentPortal,
  bool includeInbox = false,
  VoidCallback? onRefresh,
}) {
  return AppBar(
    automaticallyImplyLeading: false,
    backgroundColor: FarmColors.background,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    toolbarHeight: 60,
    titleSpacing: 0,
    title: HpjPortalUtilityHeader(
      currentPortal: currentPortal,
      includeInbox: includeInbox,
      onRefresh: onRefresh,
      safeArea: false,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
    ),
  );
}

class HpjWorkspaceAvailabilityScreen extends StatelessWidget {
  final String workspace;
  final String mode;
  final String message;
  final String returnNote;
  final String currentPortal;
  final VoidCallback? onOwnerBypass;
  final VoidCallback? onRefresh;

  const HpjWorkspaceAvailabilityScreen({
    super.key,
    required this.workspace,
    required this.mode,
    required this.message,
    required this.returnNote,
    required this.currentPortal,
    this.onOwnerBypass,
    this.onRefresh,
  });

  String get _workspaceLabel {
    switch (workspace.trim().toLowerCase()) {
      case 'farmer':
        return 'Farmer Workspace';
      case 'wholesale':
      case 'business':
        return 'Business Workspace';
      case 'customer_web':
        return 'Customer Website';
      case 'customer':
      default:
        return 'Customer Workspace';
    }
  }

  String get _title {
    switch (hpjNormalizeWorkspaceMode(mode)) {
      case 'read_only':
        return '$_workspaceLabel is in safe update mode';
      case 'closed':
        return '$_workspaceLabel is temporarily closed';
      case 'maintenance':
      default:
        return '$_workspaceLabel is getting an upgrade';
    }
  }

  String get _defaultMessage {
    switch (hpjNormalizeWorkspaceMode(mode)) {
      case 'read_only':
        return 'We are protecting this workspace while updates are being made. Operational changes are temporarily paused and your existing information remains safe.';
      case 'closed':
        return 'This workspace is temporarily unavailable. Your account, history and saved information remain safe.';
      case 'maintenance':
      default:
        return 'We are improving this workspace. Your account and information are safe. Please check back shortly.';
    }
  }

  IconData get _icon {
    switch (hpjNormalizeWorkspaceMode(mode)) {
      case 'read_only':
        return Icons.visibility_outlined;
      case 'closed':
        return Icons.lock_clock_outlined;
      case 'maintenance':
      default:
        return Icons.construction_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleanMessage =
        message.trim().isEmpty ? _defaultMessage : message.trim();
    final cleanReturn = returnNote.trim();

    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: hpjUseMobileAppPresentation(context)
          ? hpjPortalUtilityAppBar(
              currentPortal: currentPortal,
              includeInbox: true,
            )
          : AppBar(
              title: Text(_workspaceLabel),
              backgroundColor: FarmColors.background,
              surfaceTintColor: Colors.transparent,
            ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: FarmCard(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: FarmColors.primarySoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(_icon, color: FarmColors.primary, size: 27),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _title,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 22,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      cleanMessage,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (cleanReturn.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: FarmColors.cardSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: FarmColors.line),
                        ),
                        child: Text(
                          'Expected back: $cleanReturn',
                          style: const TextStyle(
                            color: FarmColors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onRefresh ??
                            () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AuthGate(),
                                ),
                              );
                            },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh status'),
                      ),
                    ),
                    if (workspace.trim().toLowerCase() == 'customer' ||
                        workspace.trim().toLowerCase() == 'customer_web') ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true)
                                .pushAndRemoveUntil<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => const AuthGate(
                                  forceWelcome: true,
                                ),
                              ),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Back to Welcome'),
                        ),
                      ),
                    ],
                    if (onOwnerBypass != null) ...[
                      const SizedBox(height: 8),
                      FutureBuilder<bool>(
                        future: hpjCurrentUserIsOwner(),
                        builder: (context, snapshot) {
                          if (snapshot.data != true) {
                            return const SizedBox.shrink();
                          }
                          return SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: onOwnerBypass,
                              icon: const Icon(
                                Icons.admin_panel_settings_outlined,
                              ),
                              label: const Text('Enter as Owner'),
                            ),
                          );
                        },
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

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  final bool bypassWorkspaceGate;

  const MainNavigation({
    super.key,
    this.initialIndex = 0,
    this.bypassWorkspaceGate = false,
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
  int mobileSelectedIndex = 0;
  String selectedShopCategory = 'All';
  int shopCategorySelectionVersion = 0;
  int myBoxRefreshVersion = 0;
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
    mealIngredientCartAddRequest
        .addListener(_applyMealIngredientCartAddRequest);
    customerMarketplaceSettingsFuture = fetchMarketplaceProgramSettings();
    authBoundaryUserId = supabase.auth.currentUser?.id.trim();
    final requestedInitialIndex = widget.initialIndex.clamp(0, 4).toInt();

    // Customer Home is now available on the website as well.
    // The public HPJ homepage remains accessible from the HPJ logo.
    selectedIndex = requestedInitialIndex;
    mobileSelectedIndex = requestedInitialIndex;

    unawaited(
      saveHpjNavigationPreference(
        workspace: 'customer',
        tab: selectedIndex,
      ),
    );
    cart.addAll(OfflineCartStore.restore());
    unawaited(_restorePersistentCart());
    unawaited(loadFavoriteProducts());
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

        // Clear only this device's private in-memory view on sign-out.
        // The actual favorites remain stored in Supabase customer_favorites
        // and are restored after the same user signs in again.
        setState(() {
          favoriteProductIds.clear();
          favoriteProductCache.clear();
          authViewVersion++;
        });

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
              builder: (_) => hpjUseMobileAppPresentation(context)
                  ? const MainNavigation()
                  : const OwnerWorkspaceSwitcherScreen(
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
            selectedIndex = kIsWeb ? shopTabIndex : homeTabIndex;
          }
        });
        return;
      }

      if (previousUserId == null && nextUserId != null && cart.isNotEmpty) {
        await _mergeLocalCartIntoSignedInCart();
        if (!mounted) return;
      }

      if (previousUserId == null && nextUserId != null) {
        await loadFavoriteProducts();
        if (!mounted) return;
      }

      subscribeToNotificationUpdates();
      if (mounted) {
        setState(() {
          authViewVersion++;
          myBoxRefreshVersion++;
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

    if (isLoggedIn && mounted) {
      setState(() {
        myBoxRefreshVersion++;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    mealIngredientCartAddRequest
        .removeListener(_applyMealIngredientCartAddRequest);
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

  void _applySignedInCartLines(List<CartLine> lines) {
    if (!mounted || !isLoggedIn) return;

    final syncedProducts = expandCartLinesToProducts(lines);
    setState(() {
      cart
        ..clear()
        ..addAll(syncedProducts);
      persistCart();
    });
  }

  Future<void> _mergeLocalCartIntoSignedInCart() async {
    final userId = supabase.auth.currentUser?.id.trim() ?? '';
    if (userId.isEmpty || cart.isEmpty) return;

    final localProducts = List<Product>.from(cart);
    final localQuantityById = <String, int>{};
    final localProductById = <String, Product>{};

    for (final product in localProducts) {
      final productId = product.id.trim();
      if (productId.isEmpty || !product.canAddToCart) continue;
      localQuantityById[productId] = (localQuantityById[productId] ?? 0) + 1;
      localProductById[productId] = product;
    }

    if (localQuantityById.isEmpty) return;

    try {
      final serverLines = await fetchSavedCartLinesForCurrentUser(
        throwOnError: true,
      );
      if ((supabase.auth.currentUser?.id.trim() ?? '') != userId) return;

      final serverQuantityById = <String, int>{
        for (final line in serverLines)
          if (line.product.id.trim().isNotEmpty)
            line.product.id.trim(): line.quantity,
      };

      for (final entry in localQuantityById.entries) {
        if ((supabase.auth.currentUser?.id.trim() ?? '') != userId) return;

        final product = localProductById[entry.key];
        if (product == null) continue;

        final existingQuantity = serverQuantityById[entry.key] ?? 0;
        final requestedQuantity = existingQuantity + entry.value;
        final maxQuantity = product.stockQuantity > 0
            ? product.stockQuantity
            : requestedQuantity;
        final mergedQuantity = requestedQuantity.clamp(1, maxQuantity).toInt();

        await setCartItemQuantityForCurrentUser(
          product: product,
          quantity: mergedQuantity,
        );
      }

      final mergedLines = await fetchSavedCartLinesForCurrentUser(
        throwOnError: true,
      );
      if ((supabase.auth.currentUser?.id.trim() ?? '') != userId) return;

      _applySignedInCartLines(mergedLines);
    } catch (error) {
      // Never discard the guest box just because account sync is temporarily
      // unavailable. A later My Box refresh can retry from the server.
      farmDebugLog('Guest-to-account My Box merge deferred: $error');
    }
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

  bool isFavorite(Product product) =>
      favoriteProductIds.contains(product.id.trim());

  Future<void> loadFavoriteProducts() async {
    final userId = supabase.auth.currentUser?.id.trim() ?? '';
    if (userId.isEmpty) {
      if (!mounted) return;
      setState(() {
        favoriteProductIds.clear();
        favoriteProductCache.clear();
      });
      return;
    }

    try {
      final saved = await fetchFavoriteProductsForCurrentUser(
        fallbackProducts: favoriteProducts,
      );

      // Ignore a stale response if the account changed while loading.
      if (!mounted || (supabase.auth.currentUser?.id.trim() ?? '') != userId) {
        return;
      }

      setState(() {
        favoriteProductIds.clear();
        favoriteProductCache.clear();

        for (final product in saved) {
          final id = product.id.trim();
          if (id.isEmpty || !isVisibleCustomerProduct(product)) continue;
          favoriteProductIds.add(id);
          favoriteProductCache[id] = product;
        }
      });
    } catch (error) {
      farmDebugLog('Favorite restore skipped safely: $error');
    }
  }

  void toggleFavorite(Product product) {
    final productId = product.id.trim();
    if (productId.isEmpty) return;

    final nextValue = !favoriteProductIds.contains(productId);

    setState(() {
      if (nextValue) {
        favoriteProductIds.add(productId);
        favoriteProductCache[productId] = product;
      } else {
        favoriteProductIds.remove(productId);
        favoriteProductCache.remove(productId);
      }
    });

    // Signed-in favorites are stored in Supabase and therefore survive
    // sign-out, app restarts and signing back in on another session.
    unawaited(
      setFavoriteForCurrentUser(
        product,
        isFavorite: nextValue,
      ),
    );
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

  void _applyMealIngredientCartAddRequest() {
    final requested = mealIngredientCartAddRequest.value;
    if (requested == null || requested.isEmpty) return;

    // Consume once before mutating the cart so the ValueNotifier cannot replay
    // the same meal selection on a later rebuild.
    mealIngredientCartAddRequest.value = null;

    final seen = <String>{};
    for (final product in requested) {
      final productId = product.id.trim();
      if (productId.isEmpty || !seen.add(productId) || !product.canAddToCart) {
        continue;
      }

      final currentQuantity = quantityForProduct(product);
      if (product.stockQuantity > 0 &&
          currentQuantity >= product.stockQuantity) {
        continue;
      }

      increaseProductQuantity(product);
      unawaited(saveCartItemForCurrentUser(product));
    }
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
    setState(() {
      selectedIndex = safeIndex;
      if (safeIndex == myBoxTabIndex && isLoggedIn) {
        myBoxRefreshVersion++;
      }
    });
    unawaited(
      saveHpjNavigationPreference(
        workspace: 'customer',
        tab: safeIndex,
      ),
    );
  }

  void _selectMobileCustomerTab(int index) {
    if (!mounted) return;
    final safeIndex = index.clamp(0, 4).toInt();
    setState(() {
      mobileSelectedIndex = safeIndex;
      selectedIndex = safeIndex;
      if (safeIndex == myBoxTabIndex && isLoggedIn) {
        myBoxRefreshVersion++;
      }
    });

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
      // Fresh login always starts from Customer Home.
      if (hpjUseMobileAppPresentation(context)) {
        _selectMobileCustomerTab(homeTabIndex);
      } else {
        _selectCustomerTab(homeTabIndex);
      }
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
              onShopTap: () {
                if (!mounted) return;

                if (hpjUseMobileAppPresentation(context)) {
                  Navigator.of(context).maybePop();
                  _selectMobileCustomerTab(1);
                  return;
                }

                _selectCustomerTab(shopTabIndex);
              },
              onOrderPlaced: () {
                if (!mounted) return;

                setState(() {
                  cart.clear();
                  myBoxRefreshVersion++;
                });

                persistCart();
                FarmDataCache.clearProducts();
                FarmDataCache.clearOrders();
              },
              onInventoryChanged: refreshInventoryViews,
              onSavedCartSynced: _applySignedInCartLines,
              refreshVersion: myBoxRefreshVersion,
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
        if (hpjUseMobileAppPresentation(context)) mobileSelectedIndex = 1;
      });
      unawaited(
        saveHpjNavigationPreference(
          workspace: 'customer',
          tab: shopTabIndex,
        ),
      );
    }

    void goToShopHome() {
      if (!mounted) return;

      setState(() {
        selectedShopCategory = 'All';
        shopCategorySelectionVersion++;
        selectedIndex = shopTabIndex;
        if (hpjUseMobileAppPresentation(context)) mobileSelectedIndex = 1;
      });

      unawaited(
        saveHpjNavigationPreference(
          workspace: 'customer',
          tab: shopTabIndex,
        ),
      );
    }

    void goToMyBoxFromProductDetail() {
      if (hpjUseMobileAppPresentation(context)) {
        _selectMobileCustomerTab(myBoxTabIndex);
        return;
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
      if (!mounted) return;
      _selectCustomerTab(myBoxTabIndex);
    }

    void openOrdersForCurrentPlatform() {
      if (hpjUseMobileAppPresentation(context)) {
        _selectMobileCustomerTab(ordersTabIndex);
        return;
      }

      _selectCustomerTab(ordersTabIndex);
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
                myBoxRefreshVersion++;
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
        onOrdersTap: openOrdersForCurrentPlatform,
        onAccountTap: () {
          if (isLoggedIn) {
            if (hpjUseMobileAppPresentation(context)) {
              _selectMobileCustomerTab(4);
            } else {
              _selectCustomerTab(accountTabIndex);
            }
          } else {
            unawaited(openSignInFromTab());
          }
        },
        isFavorite: isFavorite,
        onToggleFavorite: toggleFavorite,
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
        onShopTap: () {
          if (hpjUseMobileAppPresentation(context)) {
            _selectMobileCustomerTab(shopTabIndex);
          } else {
            _selectCustomerTab(shopTabIndex);
          }
        },
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
        onSavedCartSynced: _applySignedInCartLines,
        refreshVersion: myBoxRefreshVersion,
      ),
      OrdersScreen(
        key: ValueKey('orders-$authViewKey'),
        onAddToCart: increaseProductQuantity,
        onOpenMyBox: () {
          if (!mounted) return;
          if (hpjUseMobileAppPresentation(context)) {
            _selectMobileCustomerTab(myBoxTabIndex);
          } else {
            _selectCustomerTab(myBoxTabIndex);
          }
        },
        onBackToHome: () {
          if (!mounted) return;
          if (hpjUseMobileAppPresentation(context)) {
            _selectMobileCustomerTab(homeTabIndex);
          } else {
            _selectCustomerTab(homeTabIndex);
          }
        },
      ),
      AccountScreen(
        favoriteProducts: favoriteProducts,
        recentlyViewedProducts: recentlyViewedProducts,
        onShopTap: goToShopHome,
        onMyBoxTap: () {
          if (hpjUseMobileAppPresentation(context)) {
            _selectMobileCustomerTab(myBoxTabIndex);
          } else {
            openFloatingCart();
          }
        },
        onAddToCart: increaseProductQuantity,
        onSignedOut: () {
          if (!mounted) return;

          if (hpjUseMobileAppPresentation(context)) {
            _selectMobileCustomerTab(0);
          } else {
            _selectCustomerTab(shopTabIndex);
          }
        },
      ),
    ];

    void openCommunityProduct(Product product) {
      trackRecentlyViewed(product);

      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ProductDetailScreen(
            product: product,
            quantity: quantityForProduct(product),
            onAdd: () => increaseProductQuantity(product),
            onRemove: () => decreaseProductQuantity(product),
            onAddProduct: increaseProductQuantity,
            onViewed: trackRecentlyViewed,
            onViewMyBox: goToMyBoxFromProductDetail,
            onCheckout: goToCheckoutFromProductDetail,
          ),
        ),
      );
    }

    final nativePages = <Widget>[
      pages[homeTabIndex],
      pages[shopTabIndex],
      pages[myBoxTabIndex],
      pages[ordersTabIndex],
      pages[accountTabIndex],
    ];

    final nativeDestinations = <FarmBottomOption>[
      const FarmBottomOption(
        icon: Icon(Icons.home_outlined, size: 27),
        selectedIcon: Icon(Icons.home_rounded, size: 27),
        label: 'Home',
      ),
      const FarmBottomOption(
        icon: Icon(Icons.storefront_outlined, size: 27),
        selectedIcon: Icon(Icons.storefront_rounded, size: 27),
        label: 'Shop',
      ),
      FarmBottomOption(
        icon: const Icon(Icons.shopping_bag_outlined, size: 27),
        selectedIcon: const Icon(Icons.shopping_bag_rounded, size: 27),
        label: 'My Box',
        badgeCount: cartItemCount,
      ),
      const FarmBottomOption(
        icon: Icon(Icons.receipt_long_outlined, size: 27),
        selectedIcon: Icon(Icons.receipt_long_rounded, size: 27),
        label: 'Orders',
      ),
      const FarmBottomOption(
        icon: Icon(Icons.person_outline_rounded, size: 27),
        selectedIcon: Icon(Icons.person_rounded, size: 27),
        label: 'Account',
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

        final mobilePresentation = hpjUseMobileAppPresentation(context);
        final websiteWorkspace = kIsWeb && !mobilePresentation;
        final customerMode = settings.workspaceMode(
          'customer',
          website: websiteWorkspace,
        );
        final customerMarketplaceAvailable =
            widget.bypassWorkspaceGate || hpjWorkspaceModeIsLive(customerMode);

        if (!customerMarketplaceAvailable) {
          return HpjWorkspaceAvailabilityScreen(
            workspace: websiteWorkspace ? 'customer_web' : 'customer',
            mode: customerMode,
            message: settings.customerMaintenanceMessage,
            returnNote: settings.customerReturnNote,
            currentPortal: 'customer',
            onOwnerBypass: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => MainNavigation(
                    initialIndex: safeSelectedIndex,
                    bypassWorkspaceGate: true,
                  ),
                ),
              );
            },
            onRefresh: () {
              setState(() {
                customerMarketplaceSettingsFuture =
                    fetchMarketplaceProgramSettings();
              });
            },
          );
        }

        final desktopStorefrontWeb =
            kIsWeb && MediaQuery.of(context).size.width >= 1100;

        // HPJ MOBILE M1: native app uses the clean five-tab information
        // architecture. Flutter Web continues through the existing frozen
        // storefront branches below without any visual/navigation change.
        if (hpjUseMobileAppPresentation(context)) {
          final mobileIndex = mobileSelectedIndex.clamp(0, 4).toInt();

          return HpjResponsiveWorkspaceScaffold(
            workspaceLabel: 'HPJ',
            desktopMaxContentWidth: 1240,
            appBar: hpjPortalUtilityAppBar(
              currentPortal: 'customer',
            ),
            body: IndexedStack(
              index: mobileIndex,
              children: nativePages,
            ),
            selectedIndex: mobileIndex,
            destinations: nativeDestinations,
            onSelected: (index) async {
              if (!mounted) return;
              final tappedAccount = index == 4;
              if (tappedAccount && !isLoggedIn) {
                await openSignInFromTab();
                return;
              }
              _selectMobileCustomerTab(index);
            },
          );
        }

        if (desktopStorefrontWeb) {
          return _HpjCustomerWebStorefrontShell(
            body: IndexedStack(
              index: safeSelectedIndex,
              children: pages,
            ),
            selectedIndex: safeSelectedIndex,
            cartCount: cartItemCount,
            signedIn: isLoggedIn,
            onHome: () => _selectCustomerTab(homeTabIndex),
            onPublicHome: () => openHpjWebsiteHome(context),
            onFeed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const HpjMealPulseScreen(),
                ),
              );
            },
            onShop: () => _selectCustomerTab(shopTabIndex),
            onFarms: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => PublicFarmDirectoryScreen(
                    sourceWorkspace: 'customer',
                    onAddProduct: increaseProductQuantity,
                  ),
                ),
              );
            },
            onRecipes: () {
              _openWebsiteJamaicanDinner(context);
            },
            onDemand: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const HpjHarvestCirclesScreen(),
                ),
              );
            },
            onFarmer: () {
              unawaited(
                _openWebsiteFarmerSignup(context),
              );
            },
            onBusiness: () {
              unawaited(
                _openWebsiteBusinessSignup(context),
              );
            },
            onAdmin: () {
              unawaited(
                _openHpjWebsiteAdminPortal(context),
              );
            },
            onMyBox: () => _selectCustomerTab(myBoxTabIndex),
            onOrders: () => _selectCustomerTab(ordersTabIndex),
            onAccount: () {
              if (isLoggedIn) {
                _selectCustomerTab(accountTabIndex);
              } else {
                unawaited(openSignInFromTab());
              }
            },
          );
        }

        return HpjResponsiveWorkspaceScaffold(
          workspaceLabel: 'Customer',
          desktopMaxContentWidth: 1240,
          body: IndexedStack(index: safeSelectedIndex, children: pages),
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
