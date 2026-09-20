// HPJ PHASE 88B — BUSINESS WORKSPACE COMPILE-SAFE SINGLE PART
// Business UI separated from wholesale_management.dart, but intentionally
// kept in ONE Dart part so FlutLab only needs one new part declaration.
part of harvest_place_app;
// HPJ BUSINESS SOURCING RESILIENCE MVP — 2026-09-13
// HPJ BUSINESS WHOLESALE PRODUCT CARD — COMPACT MOBILE MVP FIX — 2026-09-13
// HPJ BUSINESS SUPER ELITE MVP — RENDERFLEX MOBILE STATUS FIX — 2026-09-13
// HPJ BUSINESS SUPER ELITE MVP — WEB + RESPONSIVE APP — 2026-09-13


// ============================================================================
// SOURCE SECTION: business_shell.dart
// ============================================================================
// HPJ PHASE 88 — BUSINESS WORKSPACE SHELL + ACCOUNT ACCESS
// Extracted from wholesale_management.dart without changing runtime behavior.

class _BusinessWholesaleHubSnapshot {
  final MarketplaceProgramSettings settings;
  final BusinessAccount? account;

  const _BusinessWholesaleHubSnapshot({
    required this.settings,
    required this.account,
  });
}

Future<_BusinessWholesaleHubSnapshot>
    fetchBusinessWholesaleHubSnapshot() async {
  final values = await Future.wait<dynamic>([
    fetchMarketplaceProgramSettings(),
    fetchCurrentBusinessAccount(),
  ]);

  return _BusinessWholesaleHubSnapshot(
    settings: values[0] as MarketplaceProgramSettings,
    account: values[1] as BusinessAccount?,
  );
}

PreferredSizeWidget _wholesaleAccessAppBar(
  BuildContext context,
  String title,
) {
  final navigator = Navigator.of(context);
  final canGoBack = navigator.canPop();

  return AppBar(
    automaticallyImplyLeading: false,
    leading: canGoBack
        ? IconButton(
            tooltip: 'Back',
            onPressed: () => navigator.maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          )
        : null,
    title: Text(title),
    actions: [
      if (kIsWeb)
        IconButton(
          tooltip: 'Switch Workspace',
          onPressed: () {
            navigator.push(
              MaterialPageRoute<void>(
                builder: (_) => const OwnerWorkspaceSwitcherScreen(
                  currentWorkspace: 'wholesale',
                ),
              ),
            );
          },
          icon: const Icon(Icons.apps_rounded),
        )
      else
        const Padding(
          padding: EdgeInsets.only(right: 8),
          child: HpjMobileAccountPortalButton(
            currentPortal: 'wholesale',
            compact: true,
          ),
        ),
    ],
  );
}

class BusinessWholesaleHubScreen extends StatefulWidget {
  final int initialTab;
  final String? initialRecordId;
  final bool bypassWorkspaceGate;

  const BusinessWholesaleHubScreen({
    super.key,
    this.initialTab = 0,
    this.initialRecordId,
    this.bypassWorkspaceGate = false,
  });

  @override
  State<BusinessWholesaleHubScreen> createState() =>
      _BusinessWholesaleHubScreenState();
}

class _BusinessWholesaleHubScreenState
    extends State<BusinessWholesaleHubScreen> {
  late Future<_BusinessWholesaleHubSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchBusinessWholesaleHubSnapshot();
  }

  Future<void> _reload() async {
    final next = fetchBusinessWholesaleHubSnapshot();

    if (mounted) {
      setState(() {
        _future = next;
      });
    }

    await next;
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn || supabase.auth.currentUser == null) {
      return const GuestProtectedScreen(
        title: 'Business & Wholesale',
        subtitle: 'Bulk shopping for organisations',
        message:
            'Sign in with your customer account to apply for wholesale access.',
      );
    }

    return FutureBuilder<_BusinessWholesaleHubSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return Scaffold(
            backgroundColor: FarmColors.background,
            appBar: _wholesaleAccessAppBar(
              context,
              'Business & Wholesale',
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final data = snapshot.data;

        if (data == null) {
          return Scaffold(
            backgroundColor: FarmColors.background,
            appBar: _wholesaleAccessAppBar(
              context,
              'Business & Wholesale',
            ),
            body: FarmPage(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  18,
                  18,
                  120,
                ),
                children: [
                  _MarketplaceProgramNotice(
                    icon: Icons.error_outline,
                    title: 'Could not load wholesale access',
                    message:
                        'Please check your connection and try again.',
                    actionLabel: 'Try Again',
                    onAction: _reload,
                  ),
                ],
              ),
            ),
          );
        }

        final account = data.account;
        final settings = data.settings;

        if (account != null && account.isApproved) {
          final wholesaleMode = settings.wholesaleWorkspaceMode;
          final workspaceLive = settings.wholesaleWorkspaceEnabled &&
              hpjWorkspaceModeIsLive(wholesaleMode);

          if (workspaceLive || widget.bypassWorkspaceGate) {
            return _WholesaleWorkspaceShell(
              account: account,
              initialIndex: widget.initialTab,
              initialRecordId: widget.initialRecordId,
              bypassWorkspaceGate: widget.bypassWorkspaceGate,
            );
          }

          return HpjWorkspaceAvailabilityScreen(
            workspace: 'wholesale',
            mode: wholesaleMode,
            message: settings.wholesaleMaintenanceMessage,
            returnNote: settings.wholesaleReturnNote,
            currentPortal: 'wholesale',
            onRefresh: _reload,
            onOwnerBypass: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => BusinessWholesaleHubScreen(
                    initialTab: widget.initialTab,
                    initialRecordId: widget.initialRecordId,
                    bypassWorkspaceGate: true,
                  ),
                ),
              );
            },
          );
        }

        Widget content;

        if (account == null &&
            !settings.wholesaleApplicationsEnabled) {
          content = _MarketplaceProgramNotice(
            icon: Icons.storefront_outlined,
            title: 'Wholesale applications are paused',
            message:
                'You can continue shopping at regular customer prices. Please check again when business applications reopen.',
            actionLabel: 'Refresh Status',
            onAction: _reload,
          );
        } else if (account == null) {
          content = BusinessApplicationForm(
            onSubmitted: _reload,
          );
        } else if (!account.isApproved) {
          content = _BusinessApplicationStatusCard(
            account: account,
            onUpdated: _reload,
          );
        } else {
          content = _MarketplaceProgramNotice(
            icon: Icons.pause_circle_outline,
            title: 'Wholesale ordering is temporarily paused',
            message:
                'Your approved business account is safe. Regular shopping remains available while the wholesale workspace is paused.',
            actionLabel: 'Refresh Status',
            onAction: _reload,
          );
        }

        return Scaffold(
          backgroundColor: FarmColors.background,
          appBar: _wholesaleAccessAppBar(
            context,
            'Business & Wholesale',
          ),
          body: FarmPage(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  18,
                  18,
                  18,
                  120,
                ),
                children: [
                  if (account == null ||
                      !account.isApproved) ...[
                    const _WholesaleHeroCard(),
                    const SizedBox(height: 16),
                  ],
                  content,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WholesaleWorkspaceShell extends StatefulWidget {
  final BusinessAccount account;
  final int initialIndex;
  final String? initialRecordId;
  final bool bypassWorkspaceGate;

  const _WholesaleWorkspaceShell({
    required this.account,
    this.initialIndex = 0,
    this.initialRecordId,
    this.bypassWorkspaceGate = false,
  });

  @override
  State<_WholesaleWorkspaceShell> createState() =>
      _WholesaleWorkspaceShellState();
}

class _WholesaleWorkspaceShellState
    extends State<_WholesaleWorkspaceShell>
    with WidgetsBindingObserver {
  int selectedIndex = 0;
  int mobileSectionIndex = 0;
  int todayRefreshKey = 0;
  late BusinessAccount currentAccount;
  StreamSubscription<AuthState>? _authBoundarySubscription;
  String? _authBoundaryUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    selectedIndex = widget.initialIndex.clamp(0, 4).toInt();
    mobileSectionIndex = _mobileSectionForLegacyIndex(selectedIndex);
    currentAccount = widget.account;
    _authBoundaryUserId =
        supabase.auth.currentUser?.id.trim();

    _authBoundarySubscription =
        supabase.auth.onAuthStateChange.listen((authState) {
      if (!mounted) return;

      final rawUserId =
          authState.session?.user.id.trim() ?? '';
      final nextUserId =
          rawUserId.isEmpty ? null : rawUserId;
      final previousUserId = _authBoundaryUserId;

      if (nextUserId == previousUserId) return;

      _authBoundaryUserId = nextUserId;
      clearHpjPrivateAccountMemory();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => nextUserId == null || !kIsWeb
                ? const AuthGate()
                : const OwnerWorkspaceSwitcherScreen(
                    showCloseButton: false,
                  ),
          ),
          (route) => false,
        );
      });
    });

    unawaited(
      saveHpjNavigationPreference(
        workspace: 'wholesale',
        tab: selectedIndex,
      ),
    );
  }

  BusinessAccount get account => currentAccount;

  Future<void> _reloadAccount() async {
    final operationBoundary =
        captureHpjPrivateOperationBoundary();

    final latest = await fetchCurrentBusinessAccount();

    if (!mounted ||
        latest == null ||
        !isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
      return;
    }

    setState(() {
      currentAccount = latest;
      todayRefreshKey++;
    });
  }

  Future<void> _revalidateWholesaleWorkspace() async {
    if (!mounted) return;

    final operationBoundary =
        captureHpjPrivateOperationBoundary();

    if (!isLoggedIn || supabase.auth.currentUser == null) {
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

    try {
      final access = await fetchOwnerWorkspaceAccessSnapshot();

      if (!mounted ||
          !isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
        return;
      }

      final latest = access.businessAccount;
      final isOwner = normalizeStaffRole(access.staffRole) == 'owner';
      final settings = access.programSettings;
      final workspaceLive = settings.wholesaleWorkspaceEnabled &&
          hpjWorkspaceModeIsLive(settings.wholesaleWorkspaceMode);
      final active = latest != null &&
          latest.isApproved &&
          (workspaceLive || (widget.bypassWorkspaceGate && isOwner));

      if (!active) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (_) => BusinessWholesaleHubScreen(
                initialTab: 0,
                bypassWorkspaceGate:
                    widget.bypassWorkspaceGate && isOwner,
              ),
            ),
            (route) => false,
          );
        });
        return;
      }

      setState(() {
        currentAccount = latest;
        todayRefreshKey++;
      });
    } catch (error) {
      farmDebugLog(
        'Wholesale workspace resume validation skipped: $error',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_revalidateWholesaleWorkspace());
  }

  @override
  void dispose() {
    _authBoundarySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  int _mobileSectionForLegacyIndex(int index) {
    switch (index) {
      case 0:
        return 0; // Home
      case 1:
      case 2:
        return 1; // Source / Planning
      case 3:
        return 3; // Orders
      case 4:
      default:
        return 4; // Account
    }
  }

  void _selectMobileBusinessSection(int index) {
    if (!mounted) return;

    final safe = index.clamp(0, 4).toInt();

    // Suppliers is a new native primary destination. Keep the legacy
    // wholesale tab contract (0..4) intact for web, notifications and
    // remembered routes.
    if (safe == 2) {
      setState(() {
        mobileSectionIndex = 2;
      });

      unawaited(
        saveHpjNavigationPreference(
          workspace: 'wholesale',
          tab: 1,
        ),
      );
      return;
    }

    final legacyIndex = switch (safe) {
      0 => 0,
      1 => 1,
      3 => 3,
      4 => 4,
      _ => 0,
    };

    _select(legacyIndex);
  }

  static const titles = <String>[
    'Business Home',
    'Wholesale Shop',
    'Planning Ahead',
    'Orders',
    'Business Account',
  ];

  void _select(int index) {
    if (!mounted) return;

    final safeIndex = index.clamp(0, 4).toInt();
    setState(() {
      selectedIndex = safeIndex;
      if (hpjUseMobileAppPresentation(context)) {
        mobileSectionIndex = _mobileSectionForLegacyIndex(safeIndex);
      }
    });
    unawaited(
      saveHpjNavigationPreference(
        workspace: 'wholesale',
        tab: safeIndex,
      ),
    );
  }

  void _switchWorkspace() {
    if (hpjUseMobileAppPresentation(context)) {
      unawaited(
        showHpjMobileAccountPortalSheet(
          context,
          currentPortal: 'wholesale',
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const OwnerWorkspaceSwitcherScreen(
          currentWorkspace: 'wholesale',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobileApp = hpjUseMobileAppPresentation(context);

    final pages = <Widget>[
      _WholesaleTodayWorkspacePage(
        key: ValueKey('wholesale-today-$todayRefreshKey'),
        account: account,
        onOpenShop: () => _select(1),
        onOpenPlan: () => _select(2),
        onOpenOrders: () => _select(3),
        onOpenAccount: () => _select(4),
        onOpenSuppliers:
            mobileApp ? () => _selectMobileBusinessSection(2) : null,
      ),
      WholesaleCatalogueScreen(
        account: account,
        embedded: true,
        onOpenSuppliers:
            mobileApp ? () => _selectMobileBusinessSection(2) : null,
      ),
      WholesalePlanningAheadScreen(
        account: account,
        embedded: true,
        initialForecastId: selectedIndex == 2 ? widget.initialRecordId : null,
      ),
      MyWholesaleRequestsScreen(
        embedded: true,
        initialRequestId: selectedIndex == 3 ? widget.initialRecordId : null,
      ),
      _WholesaleAccountWorkspacePage(
        account: account,
        onOpenShop: () => _select(1),
        onOpenPlan: () => _select(2),
        onOpenOrders: () => _select(3),
        onBusinessUpdated: _reloadAccount,
      ),
    ];

    const mobileDestinations = <FarmBottomOption>[
      FarmBottomOption(
        icon: Icon(Icons.home_outlined, size: 27),
        selectedIcon: Icon(Icons.home_rounded, size: 27),
        label: 'Home',
      ),
      FarmBottomOption(
        icon: Icon(Icons.shopping_basket_outlined, size: 27),
        selectedIcon: Icon(Icons.shopping_basket_rounded, size: 27),
        label: 'Source',
      ),
      FarmBottomOption(
        icon: Icon(Icons.handshake_outlined, size: 27),
        selectedIcon: Icon(Icons.handshake_rounded, size: 27),
        label: 'Suppliers',
      ),
      FarmBottomOption(
        icon: Icon(Icons.receipt_long_outlined, size: 27),
        selectedIcon: Icon(Icons.receipt_long_rounded, size: 27),
        label: 'Orders',
      ),
      FarmBottomOption(
        icon: Icon(Icons.business_outlined, size: 27),
        selectedIcon: Icon(Icons.business, size: 27),
        label: 'Account',
      ),
    ];

    const webDestinations = <FarmBottomOption>[
      FarmBottomOption(
        icon: Icon(Icons.home_outlined, size: 27),
        selectedIcon: Icon(Icons.home_rounded, size: 27),
        label: 'Home',
      ),
      FarmBottomOption(
        icon: Icon(Icons.storefront_outlined, size: 27),
        selectedIcon: Icon(Icons.storefront_rounded, size: 27),
        label: 'Shop',
      ),
      FarmBottomOption(
        icon: Icon(Icons.event_note_outlined, size: 27),
        selectedIcon: Icon(Icons.event_note, size: 27),
        label: 'Plan',
      ),
      FarmBottomOption(
        icon: Icon(Icons.receipt_long_outlined, size: 27),
        selectedIcon: Icon(Icons.receipt_long_rounded, size: 27),
        label: 'Orders',
      ),
      FarmBottomOption(
        icon: Icon(Icons.business_outlined, size: 27),
        selectedIcon: Icon(Icons.business, size: 27),
        label: 'Account',
      ),
    ];

    final destinations = mobileApp ? mobileDestinations : webDestinations;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !mounted) return;

        if (mobileApp && mobileSectionIndex != 0) {
          _select(0);
          return;
        }

        if (selectedIndex != 0) {
          _select(0);
        }
      },
      child: HpjResponsiveWorkspaceScaffold(
        workspaceLabel: 'Business',
        desktopMaxContentWidth: 1320,
        backgroundColor: FarmColors.background,
        appBar: mobileApp
            ? hpjPortalUtilityAppBar(
                currentPortal: 'wholesale',
                includeInbox: true,
                onRefresh: mobileSectionIndex == 0
                    ? () {
                        setState(() {
                          todayRefreshKey++;
                        });
                      }
                    : null,
              )
            : AppBar(
                automaticallyImplyLeading: false,
                leading: selectedIndex == 0
                    ? null
                    : IconButton(
                        tooltip: 'Back to Business Home',
                        onPressed: () => _select(0),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                title: Text(titles[selectedIndex]),
                actions: [
                  const HpjInboxActionButton(),
                  IconButton(
                    tooltip: 'Switch Workspace',
                    onPressed: _switchWorkspace,
                    icon: const Icon(Icons.apps_rounded),
                  ),
                  if (selectedIndex == 0)
                    IconButton(
                      tooltip: 'Refresh Home',
                      onPressed: () {
                        setState(() {
                          todayRefreshKey++;
                        });
                      },
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                ],
              ),
        body: mobileApp && mobileSectionIndex == 2
            ? WholesaleSupplierDiscoveryScreen(
                account: account,
                embedded: true,
              )
            : IndexedStack(
                index: selectedIndex,
                children: pages,
              ),
        selectedIndex: mobileApp ? mobileSectionIndex : selectedIndex,
        destinations: destinations,
        onSelected: mobileApp ? _selectMobileBusinessSection : _select,
      ),
    );
  }
}

class _WholesaleTodayWorkspacePage
    extends StatefulWidget {
  final BusinessAccount account;
  final VoidCallback onOpenShop;
  final VoidCallback onOpenPlan;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenAccount;
  final VoidCallback? onOpenSuppliers;

  const _WholesaleTodayWorkspacePage({
    super.key,
    required this.account,
    required this.onOpenShop,
    required this.onOpenPlan,
    required this.onOpenOrders,
    required this.onOpenAccount,
    this.onOpenSuppliers,
  });

  @override
  State<_WholesaleTodayWorkspacePage> createState() =>
      _WholesaleTodayWorkspacePageState();
}

class _WholesaleTodayWorkspacePageState
    extends State<_WholesaleTodayWorkspacePage> {
  int refreshKey = 0;

  Future<void> _refresh() async {
    setState(() {
      refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FarmPage(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            18,
            16,
            18,
            120,
          ),
          children: [
            KeyedSubtree(
              key: ValueKey(
                'wholesale-dashboard-$refreshKey',
              ),
              child: _ApprovedWholesaleDashboard(
                account: widget.account,
                onOpenShop: widget.onOpenShop,
                onOpenPlan: widget.onOpenPlan,
                onOpenOrders: widget.onOpenOrders,
                onOpenAccount: widget.onOpenAccount,
                onOpenSuppliers: widget.onOpenSuppliers,
                onRetry: _refresh,
              ),
            ),
          ],
        ),
      ),
    );
  }
}




class _WholesaleSettingsScreen extends StatefulWidget {
  const _WholesaleSettingsScreen();

  @override
  State<_WholesaleSettingsScreen> createState() =>
      _WholesaleSettingsScreenState();
}

class _WholesaleSettingsScreenState
    extends State<_WholesaleSettingsScreen> {
  UserExperiencePreferences preferences =
      UserExperiencePreferences.defaults;
  bool loading = true;
  bool saving = false;
  String? loadError;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      loadError = null;
    });

    try {
      final next = await fetchCurrentUserExperiencePreferences(
        throwOnError: true,
      );

      if (!mounted) return;
      setState(() {
        preferences = next;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loading = false;
        loadError = friendlyAppError(error);
      });
    }
  }

  Future<void> _save() async {
    if (saving) return;

    setState(() => saving = true);

    try {
      await saveCurrentUserExperiencePreferences(preferences);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wholesale settings saved.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _preferenceSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLast = false,
  }) {
    return Column(
      children: [
        SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 2,
          ),
          secondary: Icon(
            icon,
            color: FarmColors.primary,
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: FarmColors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 10.2,
              height: 1.3,
            ),
          ),
          value: value,
          onChanged: saving ? null : onChanged,
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: const Text('Wholesale Settings'),
      ),
      body: FarmPage(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : loadError != null
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
                    children: [
                      FarmCard(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.sync_problem_outlined,
                              color: FarmColors.warning,
                              size: 34,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Settings could not be loaded',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              loadError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Try again'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
                    children: [
                      const HpjCompactAccountHero(
                        icon: Icons.tune_rounded,
                        title: 'Business preferences',
                        subtitle:
                            'Choose the updates and market information most useful to your team.',
                        badge: 'Wholesale',
                        badgeColor: FarmColors.success,
                      ),
                      const SizedBox(height: 16),
                      FarmCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _preferenceSwitch(
                              icon: Icons.local_shipping_outlined,
                              title: 'Order & delivery alerts',
                              subtitle:
                                  'Updates about wholesale orders, preparation and delivery.',
                              value: preferences.pushOrderUpdates,
                              onChanged: (value) {
                                setState(() {
                                  preferences = preferences.copyWith(
                                    pushOrderUpdates: value,
                                  );
                                });
                              },
                            ),
                            _preferenceSwitch(
                              icon: Icons.chat_bubble_outline_rounded,
                              title: 'Messages',
                              subtitle:
                                  'Alerts when HPJ sends a business or support message.',
                              value: preferences.pushMessages,
                              onChanged: (value) {
                                setState(() {
                                  preferences = preferences.copyWith(
                                    pushMessages: value,
                                  );
                                });
                              },
                            ),
                            _preferenceSwitch(
                              icon: Icons.price_change_outlined,
                              title: 'Price & availability alerts',
                              subtitle:
                                  'Useful changes in product price or availability.',
                              value: preferences.pushPriceDrops,
                              onChanged: (value) {
                                setState(() {
                                  preferences = preferences.copyWith(
                                    pushPriceDrops: value,
                                  );
                                });
                              },
                            ),
                            _preferenceSwitch(
                              icon: Icons.insights_outlined,
                              title: 'Market intelligence',
                              subtitle:
                                  'Show agriculture and market intelligence in the Wholesale workspace.',
                              value: preferences.showAgricultureNews,
                              isLast: true,
                              onChanged: (value) {
                                setState(() {
                                  preferences = preferences.copyWith(
                                    showAgricultureNews: value,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const FarmCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: FarmColors.primary,
                              size: 20,
                            ),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'These are convenience preferences. Critical account, payment or security information remains available in HPJ Updates.',
                                style: TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 10.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      PrimaryFarmButton(
                        label: saving ? 'Saving...' : 'Save Settings',
                        icon: Icons.save_outlined,
                        onPressed: saving ? null : _save,
                      ),
                    ],
                  ),
      ),
    );
  }
}


class _WholesaleAccountWorkspacePage extends StatelessWidget {
  final BusinessAccount account;
  final VoidCallback onOpenShop;
  final VoidCallback onOpenPlan;
  final VoidCallback onOpenOrders;
  final Future<void> Function() onBusinessUpdated;

  const _WholesaleAccountWorkspacePage({
    required this.account,
    required this.onOpenShop,
    required this.onOpenPlan,
    required this.onOpenOrders,
    required this.onBusinessUpdated,
  });

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  Future<void> _editBusiness(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _BusinessDetailsEditScreen(
          account: account,
        ),
      ),
    );

    if (changed == true) {
      await onBusinessUpdated();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FarmPage(
      child: FutureBuilder<WholesaleOrderingControl>(
        future: fetchWholesaleOrderingControl(
          account: account,
        ),
        builder: (context, snapshot) {
          final control = snapshot.data;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
            children: [
              _PremiumBusinessAccountHero(
                account: account,
                control: control,
                controlLoading:
                    snapshot.connectionState == ConnectionState.waiting,
                controlUnavailable:
                    snapshot.hasError && snapshot.data == null,
              ),
              const SizedBox(height: 14),

              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 10.0;
                  final width =
                      (constraints.maxWidth - gap) / 2;

                  final actions = <Widget>[
                    _PremiumBusinessAccountQuickAction(
                      icon: Icons.local_shipping_outlined,
                      title: 'Orders',
                      subtitle: 'Track current and past requests',
                      onTap: onOpenOrders,
                    ),
                    _PremiumBusinessAccountQuickAction(
                      icon: Icons.repeat_rounded,
                      title: 'Repeat & Standing',
                      subtitle: 'Manage regular purchasing',
                      onTap: () => _open(
                        context,
                        WholesaleRepeatStandingOrdersScreen(
                          account: account,
                        ),
                      ),
                    ),
                    _PremiumBusinessAccountQuickAction(
                      icon: Icons.payments_outlined,
                      title: 'Invoices',
                      subtitle: 'Balances and payment confirmations',
                      onTap: () => _open(
                        context,
                        BusinessWholesaleInvoicesScreen(
                          account: account,
                        ),
                      ),
                    ),
                    _PremiumBusinessAccountQuickAction(
                      icon: Icons.description_outlined,
                      title: 'Account Statement',
                      subtitle: 'Credit, aging and PDF record',
                      onTap: () => _open(
                        context,
                        const BusinessWholesaleStatementScreen(),
                      ),
                    ),
                  ];

                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: actions
                        .map(
                          (item) => SizedBox(
                            width: width,
                            child: item,
                          ),
                        )
                        .toList(),
                  );
                },
              ),

              const SizedBox(height: 14),
              const HpjInviteGrowthShortcut(audience: 'business'),

              _PremiumBusinessAccountStatusCard(
                account: account,
                control: control,
                loading:
                    snapshot.connectionState == ConnectionState.waiting,
                unavailable:
                    snapshot.hasError && snapshot.data == null,
              ),

              const SizedBox(height: 14),

              FarmCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(15, 14, 15, 5),
                      child: AccountSectionHeading(
                        title: 'Business & purchasing',
                        subtitle:
                            'Manage the details and purchasing tools HPJ uses for your business.',
                      ),
                    ),
                    AccountListTile(
                      icon: Icons.business_center_outlined,
                      title: 'Business Details',
                      subtitle:
                          'Contacts, address, parish and delivery preferences.',
                      onTap: () => _editBusiness(context),
                    ),
                    AccountListTile(
                      icon: Icons.repeat_rounded,
                      title: 'Repeat & Standing Orders',
                      subtitle:
                          'Reuse frequent baskets and manage recurring requirements.',
                      onTap: () => _open(
                        context,
                        WholesaleRepeatStandingOrdersScreen(
                          account: account,
                        ),
                      ),
                    ),
                    AccountListTile(
                      icon: Icons.payments_outlined,
                      title: 'Invoices & Payments',
                      subtitle:
                          'Balances, invoices, payment confirmations and receipts.',
                      onTap: () => _open(
                        context,
                        BusinessWholesaleInvoicesScreen(
                          account: account,
                        ),
                      ),
                    ),
                    AccountListTile(
                      icon: Icons.account_balance_outlined,
                      title: 'Account Statement',
                      subtitle:
                          'Outstanding balance, credit, aging and statement PDF.',
                      onTap: () => _open(
                        context,
                        const BusinessWholesaleStatementScreen(),
                      ),
                    ),
                    AccountListTile(
                      icon: Icons.description_outlined,
                      title: 'Activity Statement',
                      subtitle:
                          'Planning, orders, invoices and payments in one HPJ record.',
                      isLast: true,
                      onTap: () => _open(
                        context,
                        _WholesaleActivityStatementScreen(
                          account: account,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (hpjUseMobileAppPresentation(context)) ...[
                const SizedBox(height: 12),
                FarmCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(15, 14, 15, 5),
                        child: AccountSectionHeading(
                          title: 'Sourcing network',
                          subtitle:
                              'Planning, preferred suppliers and Jamaica-wide demand signals.',
                        ),
                      ),
                      AccountListTile(
                        icon: Icons.event_note_outlined,
                        title: 'Planning Ahead',
                        subtitle:
                            'Share future produce needs so HPJ can prepare supply early.',
                        onTap: onOpenPlan,
                      ),
                      AccountListTile(
                        icon: Icons.handshake_outlined,
                        title: 'Find Suppliers',
                        subtitle:
                            'Discover approved Jamaican farms and build repeat relationships.',
                        onTap: () => _open(
                          context,
                          WholesaleSupplierDiscoveryScreen(
                            account: account,
                          ),
                        ),
                      ),
                      AccountListTile(
                        icon: Icons.star_outline_rounded,
                        title: 'Preferred Suppliers',
                        subtitle:
                            'Open the farms your business has marked as preferred.',
                        onTap: () => _open(
                          context,
                          WholesaleSupplierDiscoveryScreen(
                            account: account,
                            initialPreferredOnly: true,
                          ),
                        ),
                      ),
                      AccountListTile(
                        icon: Icons.hub_outlined,
                        title: 'Jamaica Demand Network',
                        subtitle:
                            'Publish and review business demand signals across HPJ.',
                        isLast: true,
                        onTap: () => _open(
                          context,
                          HpjBusinessDemandNetworkScreen(
                            account: account,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              FarmCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(15, 14, 15, 5),
                      child: AccountSectionHeading(
                        title: 'Workspace preferences',
                        subtitle:
                            'Control convenience settings and get help when needed.',
                      ),
                    ),
                    AccountListTile(
                      icon: Icons.tune_rounded,
                      title: 'Settings & Preferences',
                      subtitle:
                          'Order, delivery, messages and market preferences.',
                      onTap: () => _open(
                        context,
                        const _WholesaleSettingsScreen(),
                      ),
                    ),
                    AccountListTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Information',
                      subtitle:
                          'Support, contact information and HPJ policies.',
                      isLast: true,
                      onTap: () => _open(
                        context,
                        const HpjAccountHelpInfoScreen(
                          supportSubject: 'Wholesale support',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              const _WholesaleWorkspaceSwitchCard(
                currentWorkspace: 'wholesale',
              ),

              const SizedBox(height: 16),

              OutlinedButton.icon(
                icon: const Icon(
                  Icons.logout_outlined,
                  size: 18,
                ),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FarmColors.danger,
                  side: BorderSide(
                    color: FarmColors.danger.withOpacity(.24),
                  ),
                  backgroundColor: FarmColors.card,
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      HpjMvpUi.controlRadius,
                    ),
                  ),
                ),
                onPressed: () async {
                  await clearPrivateSessionStateForGuestBrowsing();

                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const MainNavigation(),
                      ),
                      (_) => false,
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}


class _HpjBusinessMobileMetricData {
  final String value;
  final String label;
  final bool warning;

  const _HpjBusinessMobileMetricData({
    required this.value,
    required this.label,
    this.warning = false,
  });
}

class _HpjBusinessMobileHeaderCard extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String? status;
  final List<_HpjBusinessMobileMetricData> metrics;
  final VoidCallback? onAction;
  final String? actionLabel;
  final IconData actionIcon;

  const _HpjBusinessMobileHeaderCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.status,
    this.metrics = const <_HpjBusinessMobileMetricData>[],
    this.onAction,
    this.actionLabel,
    this.actionIcon = Icons.arrow_forward_rounded,
  });

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF0B5B3D);
    const forest2 = Color(0xFF28784F);
    const gold = Color(0xFFF0C451);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            forest,
            Color(0xFF126A46),
            forest2,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: forest.withOpacity(.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: 36,
            child: Icon(
              Icons.eco_rounded,
              size: 178,
              color: Colors.white.withOpacity(.055),
            ),
          ),
          Positioned(
            right: 12,
            top: 18,
            child: Transform.rotate(
              angle: -.12,
              child: Text(
                eyebrow == 'BUSINESS HOME'
                    ? 'Source • Plan • Grow'
                    : 'HPJ Business',
                style: TextStyle(
                  color: Colors.white.withOpacity(.18),
                  fontSize: 16,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -.4,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.12),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withOpacity(.15),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eyebrow,
                            style: TextStyle(
                              color: Colors.white.withOpacity(.70),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.05,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              height: 1.04,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if ((status ?? '').trim().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withOpacity(.20),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 12,
                              color: gold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status!.trim(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(.83),
                        fontSize: 11.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (metrics.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var index = 0; index < metrics.length; index++) ...[
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 68),
                            padding: const EdgeInsets.fromLTRB(10, 10, 8, 9),
                            decoration: BoxDecoration(
                              color: metrics[index].warning
                                  ? const Color(0xFFFFD972).withOpacity(.14)
                                  : Colors.white.withOpacity(.10),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: metrics[index].warning
                                    ? gold.withOpacity(.42)
                                    : Colors.white.withOpacity(.14),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  metrics[index].value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: metrics[index].warning
                                        ? const Color(0xFFFFE29A)
                                        : Colors.white,
                                    fontSize: metrics.length >= 4 ? 13.4 : 15,
                                    height: 1,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  metrics[index].label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(.72),
                                    fontSize: metrics.length >= 4 ? 7.1 : 7.8,
                                    height: 1.15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (index < metrics.length - 1)
                          const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ],
                if (onAction != null &&
                    (actionLabel ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 11),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: FilledButton.icon(
                      onPressed: onAction,
                      icon: Icon(actionIcon, size: 17),
                      label: Text(actionLabel!),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: forest,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBusinessAccountHero extends StatelessWidget {
  final BusinessAccount account;
  final WholesaleOrderingControl? control;
  final bool controlLoading;
  final bool controlUnavailable;

  const _PremiumBusinessAccountHero({
    required this.account,
    required this.control,
    required this.controlLoading,
    required this.controlUnavailable,
  });

  Widget _metric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(.16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: const Color(0xFFE8C768),
              size: 17,
            ),
            const SizedBox(height: 7),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(.72),
                fontSize: 8.6,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controlValue = control;

    final subtitle = <String>[
      if (account.businessType.trim().isNotEmpty)
        account.businessType.trim(),
      if (account.parish.trim().isNotEmpty)
        account.parish.trim(),
    ].join(' • ');

    final statusLabel = controlLoading
        ? 'CHECKING'
        : controlUnavailable
            ? 'APPROVED'
            : controlValue?.statusLabel.toUpperCase() ?? 'APPROVED';

    final availableCredit = controlUnavailable
        ? '—'
        : controlLoading
            ? '…'
            : controlValue == null
                ? '—'
                : controlValue.hasHardCreditLimit
                    ? formatJmd(controlValue.availableCredit)
                    : account.hasActiveWholesaleCredit
                        ? 'NO LIMIT'
                        : 'DUE NOW';

    final outstanding = controlUnavailable
        ? '—'
        : controlLoading
            ? '…'
            : controlValue == null
                ? '—'
                : formatJmd(controlValue.outstandingInvoices);

    if (hpjUseMobileAppPresentation(context)) {
      return _HpjBusinessMobileHeaderCard(
        icon: Icons.business_center_outlined,
        eyebrow: 'BUSINESS ACCOUNT',
        title: account.displayName,
        subtitle: subtitle,
        status: statusLabel,
        metrics: <_HpjBusinessMobileMetricData>[
          _HpjBusinessMobileMetricData(
            value: outstanding,
            label: 'Outstanding',
            warning: !controlLoading &&
                !controlUnavailable &&
                controlValue != null &&
                controlValue.outstandingInvoices > 0,
          ),
          _HpjBusinessMobileMetricData(
            value: availableCredit,
            label: 'Available',
          ),
          _HpjBusinessMobileMetricData(
            value: account.wholesalePaymentTermsLabel,
            label: 'Terms',
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FarmColors.deepGreen,
            FarmColors.green,
            Color(0xFF4E8157),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: FarmColors.deepGreen.withOpacity(.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
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
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.14),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: Colors.white.withOpacity(.20),
                  ),
                ),
                child: Image.asset(
                  'lib/assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.business_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BUSINESS ACCOUNT',
                      style: TextStyle(
                        color: Colors.white.withOpacity(.72),
                        fontSize: 10.3,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .9,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      account.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(.78),
                          fontSize: 10.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.11),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withOpacity(.15),
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .35,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              _metric(
                icon: Icons.account_balance_wallet_outlined,
                value: outstanding,
                label: 'Outstanding',
              ),
              const SizedBox(width: 8),
              _metric(
                icon: Icons.credit_score_outlined,
                value: availableCredit,
                label: 'Available credit',
              ),
              const SizedBox(width: 8),
              _metric(
                icon: Icons.event_available_outlined,
                value: account.wholesalePaymentTermsLabel,
                label: 'Payment terms',
              ),
            ],
          ),

          const SizedBox(height: 9),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.10),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(.14),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFFE8C768),
                  size: 17,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Approved HPJ business • ${account.wholesaleCreditStatusLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.84),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
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
}

class _PremiumBusinessAccountQuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PremiumBusinessAccountQuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FarmColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: FarmColors.line,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: FarmColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: FarmColors.deepGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
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
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 8.8,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: FarmColors.mutedText,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumBusinessAccountStatusCard extends StatelessWidget {
  final BusinessAccount account;
  final WholesaleOrderingControl? control;
  final bool loading;
  final bool unavailable;

  const _PremiumBusinessAccountStatusCard({
    required this.account,
    required this.control,
    required this.loading,
    required this.unavailable,
  });

  @override
  Widget build(BuildContext context) {
    final value = control;

    final color = loading || unavailable
        ? FarmColors.primary
        : value == null
            ? FarmColors.primary
            : value.isBlocked
                ? FarmColors.danger
                : value.hasWarning
                    ? FarmColors.warning
                    : FarmColors.success;

    final icon = loading
        ? Icons.hourglass_top_rounded
        : unavailable
            ? Icons.info_outline_rounded
            : value == null
                ? Icons.verified_user_outlined
                : value.isBlocked
                    ? Icons.block_outlined
                    : value.hasWarning
                        ? Icons.warning_amber_rounded
                        : Icons.verified_user_outlined;

    final title = loading
        ? 'Checking wholesale account'
        : unavailable
            ? 'Account status temporarily unavailable'
            : value?.statusLabel ?? account.wholesaleCreditStatusLabel;

    final message = loading
        ? 'HPJ is checking outstanding invoices, credit and wholesale ordering status.'
        : unavailable
            ? 'Your approved Business workspace remains available. Open Account Statement or refresh later for the latest finance snapshot.'
            : value == null
                ? 'Your HPJ wholesale account is active.'
                : value.reason.trim().isNotEmpty
                    ? value.reason.trim()
                    : value.isBlocked
                        ? 'Ordering is currently blocked by the wholesale account rules.'
                        : value.hasWarning
                            ? 'Your account can continue, but HPJ has flagged an item for review.'
                            : 'Your wholesale account is ready for purchasing.';

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 9.4,
                    height: 1.38,
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


String _wholesaleStatementDate(
  DateTime? value,
) {
  if (value == null) return '-';

  return '${value.year}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

String _wholesaleStatementStatus(
  String value,
) {
  final clean = value
      .trim()
      .replaceAll('_', ' ');

  if (clean.isEmpty) return '-';

  return clean
      .split(' ')
      .where((item) => item.isNotEmpty)
      .map(
        (item) =>
            '${item[0].toUpperCase()}${item.substring(1)}',
      )
      .join(' ');
}

Future<Uint8List>
    _buildWholesaleActivityStatementPdf(
  BusinessAccount account,
  _WholesaleTodaySnapshot data,
) async {
  final pdf = pw.Document();
  final logo =
      await _loadBusinessPortalPdfLogo();

  final green =
      PdfColor.fromInt(0xFF1F6B3A);
  final softGreen =
      PdfColor.fromInt(0xFFEAF3EC);

  final totalPaid =
      data.invoices.fold<double>(
    0,
    (sum, item) =>
        sum + item.paidAmount,
  );

  final totalDue =
      data.invoices.fold<double>(
    0,
    (sum, item) =>
        sum + item.amountDue,
  );

  final completedOrders =
      data.requests.where(
    (item) {
      final status =
          item.status.trim().toLowerCase();

      return status == 'completed' ||
          status == 'delivered';
    },
  ).length;

  pw.Widget metric(
    String label,
    String value,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(9),
        decoration: pw.BoxDecoration(
          color: softGreen,
          borderRadius:
              pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment:
              pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 7.5,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              _businessPortalPdfClean(
                value,
              ),
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight:
                    pw.FontWeight.bold,
                color: green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget sectionTitle(String value) {
    return pw.Container(
      width: double.infinity,
      padding:
          const pw.EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 8,
      ),
      decoration: pw.BoxDecoration(
        color: softGreen,
        borderRadius:
            pw.BorderRadius.circular(5),
      ),
      child: pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: green,
        ),
      ),
    );
  }

  pw.Widget table({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    if (rows.isEmpty) {
      return pw.Padding(
        padding:
            const pw.EdgeInsets.symmetric(
          vertical: 8,
        ),
        child: pw.Text(
          'No records available.',
          style: const pw.TextStyle(
            fontSize: 8.5,
            color: PdfColors.grey600,
          ),
        ),
      );
    }

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows
          .map(
            (row) => row
                .map(
                  _businessPortalPdfClean,
                )
                .toList(),
          )
          .toList(),
      headerDecoration: pw.BoxDecoration(
        color: PdfColors.grey200,
      ),
      headerStyle: pw.TextStyle(
        fontSize: 7.5,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle:
          const pw.TextStyle(fontSize: 7.2),
      cellPadding:
          const pw.EdgeInsets.all(4),
      border: pw.TableBorder.all(
        color: PdfColors.grey300,
        width: 0.5,
      ),
    );
  }

  final forecasts =
      List<WholesaleDemandForecast>.from(
    data.forecasts,
  )
        ..sort(
          (a, b) => b.needByDate
              .compareTo(a.needByDate),
        );

  final requests =
      List<WholesaleOrderRequest>.from(
    data.requests,
  )
        ..sort(
          (a, b) =>
              (b.createdAt ??
                      DateTime(2000))
                  .compareTo(
            a.createdAt ??
                DateTime(2000),
          ),
        );

  final invoices =
      List<WholesaleInvoice>.from(
    data.invoices,
  )
        ..sort(
          (a, b) =>
              (b.issueDate ??
                      b.createdAt ??
                      DateTime(2000))
                  .compareTo(
            a.issueDate ??
                a.createdAt ??
                DateTime(2000),
          ),
        );

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(
        32,
        30,
        32,
        34,
      ),
      footer: (context) => pw.Column(
        children: [
          pw.Divider(
            color: PdfColors.grey300,
          ),
          pw.Row(
            mainAxisAlignment:
                pw.MainAxisAlignment
                    .spaceBetween,
            children: [
              pw.Text(
                'The Harvest Place Ja',
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
      build: (context) => [
        _businessPortalPdfHeader(
          logo: logo,
          title:
              'BUSINESS ACTIVITY STATEMENT',
          reference:
              _wholesaleStatementDate(
            DateTime.now(),
          ),
        ),

        pw.SizedBox(height: 14),

        pw.Container(
          width: double.infinity,
          padding:
              const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: PdfColors.grey300,
            ),
            borderRadius:
                pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment:
                pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _businessPortalPdfClean(
                  account.displayName,
                ),
                style: pw.TextStyle(
                  fontSize: 10.5,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                _businessPortalPdfClean(
                  [
                    if (account.parish
                        .trim()
                        .isNotEmpty)
                      account.parish,
                    if (account.phone
                        .trim()
                        .isNotEmpty)
                      account.phone,
                  ].join(' | '),
                ),
                style: const pw.TextStyle(
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 12),

        pw.Row(
          children: [
            metric(
              'Future needs',
              '${data.forecasts.length}',
            ),
            pw.SizedBox(width: 7),
            metric(
              'Orders completed',
              '$completedOrders',
            ),
            pw.SizedBox(width: 7),
            metric(
              'Payments recorded',
              formatJmd(totalPaid),
            ),
          ],
        ),

        pw.SizedBox(height: 7),

        pw.Row(
          children: [
            metric(
              'Orders placed',
              '${data.requests.length}',
            ),
            pw.SizedBox(width: 7),
            metric(
              'Invoices',
              '${data.invoices.length}',
            ),
            pw.SizedBox(width: 7),
            metric(
              'Amount due',
              formatJmd(totalDue),
            ),
          ],
        ),

        pw.SizedBox(height: 18),
        sectionTitle(
          'PLANNING AHEAD HISTORY',
        ),
        pw.SizedBox(height: 6),
        table(
          headers: const [
            'Product',
            'Quantity',
            'Need by',
            'Status',
          ],
          rows: forecasts
              .take(30)
              .map(
                (item) => [
                  item.productName,
                  item.formattedQuantity,
                  _wholesaleStatementDate(
                    item.needByDate,
                  ),
                  item.statusLabel,
                ],
              )
              .toList(),
        ),

        pw.SizedBox(height: 16),
        sectionTitle(
          'WHOLESALE ORDER HISTORY',
        ),
        pw.SizedBox(height: 6),
        table(
          headers: const [
            'Created',
            'Reference',
            'Estimate',
            'Status',
          ],
          rows: requests
              .take(30)
              .map(
                (item) => [
                  _wholesaleStatementDate(
                    item.createdAt,
                  ),
                  item.shortId,
                  formatJmd(
                    item.quotedTotal ??
                        item.subtotalEstimate,
                  ),
                  _wholesaleStatementStatus(
                    item.status,
                  ),
                ],
              )
              .toList(),
        ),

        pw.SizedBox(height: 16),
        sectionTitle(
          'INVOICE & PAYMENT HISTORY',
        ),
        pw.SizedBox(height: 6),
        table(
          headers: const [
            'Date',
            'Invoice',
            'Total',
            'Paid',
            'Due',
            'Status',
          ],
          rows: invoices
              .take(30)
              .map(
                (item) => [
                  _wholesaleStatementDate(
                    item.issueDate ??
                        item.createdAt,
                  ),
                  item.invoiceNumber,
                  formatJmd(
                    item.totalAmount,
                  ),
                  formatJmd(
                    item.paidAmount,
                  ),
                  formatJmd(
                    item.amountDue,
                  ),
                  item.paymentStatusLabel,
                ],
              )
              .toList(),
        ),

        pw.SizedBox(height: 18),

        pw.Container(
          padding:
              const pw.EdgeInsets.all(9),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius:
                pw.BorderRadius.circular(5),
          ),
          child: pw.Text(
            'This statement is a record of activity held in The Harvest Place Ja system. '
            'It is not a bank statement, audited financial statement, credit rating or tax certificate.',
            style: const pw.TextStyle(
              fontSize: 7.4,
              color: PdfColors.grey700,
            ),
          ),
        ),
      ],
    ),
  );

  return pdf.save();
}

class _WholesaleActivityStatementScreen
    extends StatefulWidget {
  final BusinessAccount account;

  const _WholesaleActivityStatementScreen({
    required this.account,
  });

  @override
  State<_WholesaleActivityStatementScreen>
      createState() =>
          _WholesaleActivityStatementScreenState();
}

class _WholesaleActivityStatementScreenState
    extends State<
        _WholesaleActivityStatementScreen> {
  late Future<_WholesaleTodaySnapshot>
      future;

  bool exporting = false;

  @override
  void initState() {
    super.initState();

    future =
        fetchWholesaleTodaySnapshot();
  }

  Future<void> _refresh() async {
    setState(() {
      future =
          fetchWholesaleTodaySnapshot();
    });

    await future;
  }

  Future<void> _printOrSave(
    _WholesaleTodaySnapshot data,
  ) async {
    if (exporting) return;

    setState(() {
      exporting = true;
    });

    try {
      final bytes =
          await _buildWholesaleActivityStatementPdf(
        widget.account,
        data,
      );

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name:
            'HPJ_Business_Activity_Statement.pdf',
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyAppError(error),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          exporting = false;
        });
      }
    }
  }

  Future<void> _share(
    _WholesaleTodaySnapshot data,
  ) async {
    if (exporting) return;

    setState(() {
      exporting = true;
    });

    try {
      final bytes =
          await _buildWholesaleActivityStatementPdf(
        widget.account,
        data,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'HPJ_Business_Activity_Statement.pdf',
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyAppError(error),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          exporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: const Text(
          'Business Activity Statement',
        ),
      ),
      body:
          FutureBuilder<_WholesaleTodaySnapshot>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError ||
              snapshot.data == null) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Text(
                      'Your business statement could not be loaded.',
                      textAlign:
                          TextAlign.center,
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    OutlinedButton(
                      onPressed: _refresh,
                      child: const Text(
                        'Try Again',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;

          final totalPaid =
              data.invoices.fold<double>(
            0,
            (sum, item) =>
                sum + item.paidAmount,
          );

          final totalDue =
              data.invoices.fold<double>(
            0,
            (sum, item) =>
                sum + item.amountDue,
          );

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                16,
                18,
                32,
              ),
              children: [
                FarmCard(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        widget.account
                            .displayName,
                        style:
                            const TextStyle(
                          color:
                              FarmColors.ink,
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      const Text(
                        'Your own HPJ planning, purchasing and payment record.',
                        style: TextStyle(
                          color: FarmColors
                              .mutedText,
                          fontSize: 10.2,
                          height: 1.35,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      const SizedBox(
                        height: 14,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child:
                                _WholesaleStatementMetric(
                              label:
                                  'Future needs',
                              value:
                                  '${data.forecasts.length}',
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child:
                                _WholesaleStatementMetric(
                              label:
                                  'Orders',
                              value:
                                  '${data.requests.length}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child:
                                _WholesaleStatementMetric(
                              label:
                                  'Payments recorded',
                              value:
                                  formatJmd(totalPaid),
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child:
                                _WholesaleStatementMetric(
                              label:
                                  'Amount due',
                              value:
                                  formatJmd(totalDue),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                FarmCard(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Text(
                        'Export your record',
                        style: TextStyle(
                          color:
                              FarmColors.ink,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      const Text(
                        'Keep a PDF copy for your internal records or share it with the appropriate person in your business.',
                        style: TextStyle(
                          color: FarmColors
                              .mutedText,
                          fontSize: 9.6,
                          height: 1.35,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      SizedBox(
                        width:
                            double.infinity,
                        child: ElevatedButton
                            .icon(
                          onPressed: exporting
                              ? null
                              : () =>
                                  _printOrSave(
                                    data,
                                  ),
                          icon: const Icon(
                            Icons
                                .picture_as_pdf_outlined,
                          ),
                          label: Text(
                            exporting
                                ? 'Preparing...'
                                : 'View / Save PDF',
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 7,
                      ),
                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            OutlinedButton.icon(
                          onPressed: exporting
                              ? null
                              : () =>
                                  _share(
                                    data,
                                  ),
                          icon: const Icon(
                            Icons.share_outlined,
                          ),
                          label:
                              const Text(
                            'Share PDF',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFF0F4EC,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                    border: Border.all(
                      color: const Color(
                        0xFFDCE4D8,
                      ),
                    ),
                  ),
                  child: const Text(
                    'This is an HPJ activity record, not a bank statement, audited financial statement, credit rating or tax certificate.',
                    style: TextStyle(
                      color: FarmColors
                          .mutedText,
                      fontSize: 9.4,
                      height: 1.35,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WholesaleStatementMetric
    extends StatelessWidget {
  final String label;
  final String value;

  const _WholesaleStatementMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: FarmColors.background,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: FarmColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 8.7,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 13,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}


class _WholesaleWorkspaceSwitchCard extends StatelessWidget {
  final String currentWorkspace;

  const _WholesaleWorkspaceSwitchCard({
    required this.currentWorkspace,
  });

  @override
  Widget build(BuildContext context) {
    if (hpjUseMobileAppPresentation(context)) {
      return const SizedBox.shrink();
    }

    return Material(
      color: const Color(0xFFF1F6EF),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => OwnerWorkspaceSwitcherScreen(
                currentWorkspace: currentWorkspace,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: FarmColors.green.withOpacity(.16),
            ),
          ),
          child: const Row(
            children: [
              _PremiumWholesaleWorkspaceSwitchIcon(),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Switch HPJ workspace',
                      style: TextStyle(
                        color: FarmColors.ink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Open Customer, Farmer, Admin or another workspace available to your account.',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 9.2,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: FarmColors.deepGreen,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumWholesaleWorkspaceSwitchIcon extends StatelessWidget {
  const _PremiumWholesaleWorkspaceSwitchIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FarmColors.deepGreen,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(
        Icons.apps_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}


class _WholesaleHeroCard extends StatelessWidget {
  const _WholesaleHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FarmColors.deepGreen,
            FarmColors.green,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: FarmColors.deepGreen.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.storefront_outlined, color: Colors.white, size: 34),
          SizedBox(height: 16),
          Text(
            'Fresh produce for your business.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Wholesale pricing, bulk quantities, organised requests, and dependable Jamaican farm supply.',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class BusinessApplicationForm extends StatefulWidget {
  final BusinessAccount? existing;
  final Future<void> Function() onSubmitted;

  const BusinessApplicationForm({
    super.key,
    this.existing,
    required this.onSubmitted,
  });

  @override
  State<BusinessApplicationForm> createState() =>
      _BusinessApplicationFormState();
}

class _BusinessApplicationFormState extends State<BusinessApplicationForm> {
  late final TextEditingController businessNameController;
  late final TextEditingController contactController;
  late final TextEditingController phoneController;
  late final TextEditingController whatsappController;
  late final TextEditingController addressController;
  late final TextEditingController parishController;
  late final TextEditingController registrationController;
  late final TextEditingController spendController;
  String businessType = 'Restaurant / Food Service';
  final Set<String> selectedDays = <String>{};
  bool saving = false;

  static const List<String> businessTypes = <String>[
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

  static const List<String> deliveryDays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    final account = widget.existing;
    final user = supabase.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};

    businessNameController = TextEditingController(
      text:
          account?.businessName ?? (metadata['business_name'] ?? '').toString(),
    );
    contactController = TextEditingController(
      text: account?.contactName ?? (metadata['full_name'] ?? '').toString(),
    );
    phoneController = TextEditingController(
      text: account?.phone ?? (metadata['business_phone'] ?? '').toString(),
    );
    whatsappController = TextEditingController(text: account?.whatsapp ?? '');
    addressController = TextEditingController(text: account?.address ?? '');
    parishController = TextEditingController(
      text: account?.parish ?? (metadata['business_parish'] ?? '').toString(),
    );
    registrationController = TextEditingController(
      text: account?.registrationNumber ?? '',
    );
    spendController = TextEditingController(
      text: account != null && account.expectedWeeklySpend > 0
          ? account.expectedWeeklySpend.toStringAsFixed(0)
          : '',
    );

    final candidateType =
        account?.businessType ?? (metadata['business_type'] ?? '').toString();
    if (businessTypes.contains(candidateType)) {
      businessType = candidateType;
    }

    selectedDays.addAll(account?.preferredDeliveryDays ?? const <String>[]);
  }

  @override
  void dispose() {
    businessNameController.dispose();
    contactController.dispose();
    phoneController.dispose();
    whatsappController.dispose();
    addressController.dispose();
    parishController.dispose();
    registrationController.dispose();
    spendController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (saving) return;

    final spend =
        double.tryParse(spendController.text.trim().replaceAll(',', '')) ?? 0;

    setState(() => saving = true);
    try {
      await submitBusinessApplication(
        businessName: businessNameController.text,
        businessType: businessType,
        contactName: contactController.text,
        phone: phoneController.text,
        whatsapp: whatsappController.text,
        address: addressController.text,
        parish: parishController.text,
        registrationNumber: registrationController.text,
        expectedWeeklySpend: spend,
        preferredDeliveryDays: selectedDays.toList(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Business application submitted for review.',
          ),
        ),
      );
      await widget.onSubmitted();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Business shopper application',
            style: TextStyle(
              color: FarmColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tell us about your organisation. You can continue shopping at retail prices while the application is reviewed.',
            style: TextStyle(
              color: FarmColors.mutedText,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: businessNameController,
            decoration: const InputDecoration(
              labelText: 'Business name *',
              prefixIcon: Icon(Icons.store_outlined),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: businessType,
            decoration: const InputDecoration(
              labelText: 'Business type',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: businessTypes
                .map(
                  (type) => DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => businessType = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: contactController,
            decoration: const InputDecoration(
              labelText: 'Contact person *',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Business phone *',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: whatsappController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'WhatsApp number',
              prefixIcon: Icon(Icons.chat_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: addressController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Business address',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 12),
          JamaicaParishDropdown(
            controller: parishController,
            label: 'Parish *',
            enabled: !saving,
            prefixIcon: Icons.map_outlined,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: registrationController,
            decoration: const InputDecoration(
              labelText: 'TRN or registration number (optional)',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: spendController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Expected weekly spend (J\$)',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Preferred delivery days',
            style: TextStyle(
              color: FarmColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: deliveryDays.map((day) {
              final selected = selectedDays.contains(day);
              return FilterChip(
                label: Text(day),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      selectedDays.add(day);
                    } else {
                      selectedDays.remove(day);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send_outlined),
              label: Text(
                saving
                    ? 'Submitting...'
                    : widget.existing == null
                        ? 'Submit Application'
                        : 'Update Application',
              ),
              onPressed: saving ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessApplicationStatusCard extends StatefulWidget {
  final BusinessAccount account;
  final Future<void> Function() onUpdated;

  const _BusinessApplicationStatusCard({
    required this.account,
    required this.onUpdated,
  });

  @override
  State<_BusinessApplicationStatusCard> createState() =>
      _BusinessApplicationStatusCardState();
}

class _BusinessApplicationStatusCardState
    extends State<_BusinessApplicationStatusCard> {
  bool editing = false;

  @override
  Widget build(BuildContext context) {
    if (editing) {
      return BusinessApplicationForm(
        existing: widget.account,
        onSubmitted: () async {
          setState(() => editing = false);
          await widget.onUpdated();
        },
      );
    }

    final account = widget.account;
    final color = businessAccountStatusColor(account.status);

    return FarmCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.business_center_outlined, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.displayName,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      businessAccountStatusLabel(account.status),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            account.isPending
                ? 'Your application is being reviewed. You may continue using normal retail shopping while you wait.'
                : account.isRejected
                    ? 'Please review your business details and submit an update.'
                    : 'Wholesale access is currently paused. Contact support for assistance.',
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          if (account.adminNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FarmColors.cardSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FarmColors.line),
              ),
              child: Text(
                account.adminNotes,
                style: const TextStyle(
                  color: FarmColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Review Business Details'),
              onPressed: () => setState(() => editing = true),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// PHASE 3N — BUSINESS ACCOUNT INVOICE PORTAL
// Approved wholesale businesses can view only their own
// issued invoices, balances and payment receipts.
// =====================================================

String _businessPortalPdfClean(
  String? value, {
  String fallback = '',
}) {
  final clean = value
          ?.replaceAll('•', '-')
          .replaceAll('–', '-')
          .replaceAll('—', '-')
          .replaceAll('\u00A0', ' ')
          .trim() ??
      '';

  return clean.isEmpty ? fallback : clean;
}

String _businessPortalPdfDate(DateTime? value) {
  if (value == null) return 'Not available';

  final date = value.toLocal();
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _businessPortalPdfMoney(double value) {
  return 'J\$${value.toStringAsFixed(2)}';
}

String _businessPortalShortId(String value) {
  final clean = value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();

  return clean.length <= 8 ? clean : clean.substring(0, 8);
}

Future<pw.MemoryImage?> _loadBusinessPortalPdfLogo() async {
  try {
    final bytes = await rootBundle.load('lib/assets/images/logo.png');
    return pw.MemoryImage(bytes.buffer.asUint8List());
  } catch (_) {
    return null;
  }
}

pw.Widget _businessPortalPdfHeader({
  required pw.MemoryImage? logo,
  required String title,
  required String reference,
}) {
  final green = PdfColor.fromInt(0xFF1F6B3A);
  final deepGreen = PdfColor.fromInt(0xFF124D32);

  return pw.Column(
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(
            width: 62,
            height: 62,
            child: logo != null
                ? pw.Image(logo, fit: pw.BoxFit.contain)
                : pw.Center(
                    child: pw.Text(
                      'HPJ',
                      style: pw.TextStyle(
                        fontSize: 19,
                        fontWeight: pw.FontWeight.bold,
                        color: green,
                      ),
                    ),
                  ),
          ),
          pw.SizedBox(width: 12),
          pw.Container(width: 2, height: 56, color: green),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'THE HARVEST PLACE JA',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: deepGreen,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Mountainside, St. Elizabeth, Jamaica | Tel: 876-339-1395',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Fresh - Local - Jamaican',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Container(height: 2, width: double.infinity, color: green),
      pw.SizedBox(height: 9),
      pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: green,
                letterSpacing: .35,
              ),
            ),
          ),
          pw.Text(
            reference,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: deepGreen,
            ),
          ),
        ],
      ),
    ],
  );
}

pw.Widget _businessPortalPdfInfoBox({
  required String title,
  required List<String> lines,
}) {
  final green = PdfColor.fromInt(0xFF1F6B3A);

  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColor.fromInt(0xFFD8E8D8)),
      borderRadius: pw.BorderRadius.circular(9),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
            color: green,
          ),
        ),
        pw.SizedBox(height: 7),
        ...lines.where((line) => line.trim().isNotEmpty).map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Text(
                  _businessPortalPdfClean(line),
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey800,
                  ),
                ),
              ),
            ),
      ],
    ),
  );
}

pw.Widget _businessPortalPdfAmountRow(
  String label,
  String value, {
  bool strong = false,
  bool green = false,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 5),
    child: pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: strong ? 10.5 : 9.5,
              fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: strong ? 11.5 : 9.5,
            fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: green ? PdfColor.fromInt(0xFF1F6B3A) : PdfColors.black,
          ),
        ),
      ],
    ),
  );
}

Future<Uint8List> _buildBusinessPortalInvoicePdf(
  WholesaleInvoice invoice,
) async {
  final pdf = pw.Document();
  final logo = await _loadBusinessPortalPdfLogo();
  final green = PdfColor.fromInt(0xFF1F6B3A);
  final softGreen = PdfColor.fromInt(0xFFEAF3EC);
  final requestRef = _businessPortalShortId(invoice.requestId);

  pw.Widget cell(
    String value, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        _businessPortalPdfClean(value),
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(34, 32, 34, 34),
      footer: (context) => pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey400),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'The Harvest Place Ja',
                style: const pw.TextStyle(
                  fontSize: 7.5,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 7.5,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
      build: (context) => [
        _businessPortalPdfHeader(
          logo: logo,
          title: 'WHOLESALE INVOICE',
          reference: invoice.invoiceNumber,
        ),
        pw.SizedBox(height: 18),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _businessPortalPdfInfoBox(
                title: 'BILL TO',
                lines: [
                  invoice.businessName.trim().isEmpty
                      ? 'Wholesale Business'
                      : invoice.businessName,
                  invoice.contactName,
                  invoice.contactPhone,
                  invoice.billingAddress,
                  invoice.billingParish,
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _businessPortalPdfInfoBox(
                title: 'INVOICE DETAILS',
                lines: [
                  'Invoice: ${invoice.invoiceNumber}',
                  'Request: #$requestRef',
                  'Issued: ${_businessPortalPdfDate(invoice.issueDate ?? invoice.issuedAt)}',
                  'Due: ${_businessPortalPdfDate(invoice.dueDate)}',
                  'Terms: ${invoice.paymentTermsDays} day${invoice.paymentTermsDays == 1 ? '' : 's'}',
                  'Payment: ${invoice.paymentStatusLabel}',
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Text(
          'INVOICE ITEMS',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: green,
          ),
        ),
        pw.SizedBox(height: 7),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: .6),
          columnWidths: const {
            0: pw.FlexColumnWidth(3.6),
            1: pw.FlexColumnWidth(1.4),
            2: pw.FlexColumnWidth(1.4),
            3: pw.FlexColumnWidth(1.6),
            4: pw.FlexColumnWidth(1.7),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: softGreen),
              children: [
                cell('Product', bold: true),
                cell('Qty', bold: true),
                cell('Unit', bold: true),
                cell('Unit Price', bold: true, align: pw.TextAlign.right),
                cell('Total', bold: true, align: pw.TextAlign.right),
              ],
            ),
            ...invoice.items.map(
              (item) => pw.TableRow(
                children: [
                  cell(item.productName),
                  cell(item.quantityLabel),
                  cell(item.unit),
                  cell(
                    _businessPortalPdfMoney(item.unitPrice),
                    align: pw.TextAlign.right,
                  ),
                  cell(
                    _businessPortalPdfMoney(item.lineTotal),
                    bold: true,
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 5,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (invoice.customerNote.trim().isNotEmpty) ...[
                    pw.Text(
                      'NOTE',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: green,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      _businessPortalPdfClean(invoice.customerNote),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.SizedBox(height: 14),
                  ],
                  pw.Text(
                    'PAYMENT REFERENCE',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: green,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'When paying by bank transfer, use ${invoice.invoiceNumber} as the payment reference.',
                    style: const pw.TextStyle(fontSize: 8.5, height: 1.35),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 24),
            pw.Expanded(
              flex: 4,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _businessPortalPdfAmountRow(
                      'Subtotal',
                      _businessPortalPdfMoney(invoice.subtotal),
                    ),
                    if (invoice.deliveryFee > 0)
                      _businessPortalPdfAmountRow(
                        'Delivery',
                        _businessPortalPdfMoney(invoice.deliveryFee),
                      ),
                    if (invoice.discountAmount > 0)
                      _businessPortalPdfAmountRow(
                        'Discount',
                        '-${_businessPortalPdfMoney(invoice.discountAmount)}',
                      ),
                    if (invoice.taxAmount > 0)
                      _businessPortalPdfAmountRow(
                        'Tax',
                        _businessPortalPdfMoney(invoice.taxAmount),
                      ),
                    if (invoice.otherAmount > 0)
                      _businessPortalPdfAmountRow(
                        'Other',
                        _businessPortalPdfMoney(invoice.otherAmount),
                      ),
                    pw.Divider(),
                    _businessPortalPdfAmountRow(
                      'TOTAL',
                      _businessPortalPdfMoney(invoice.totalAmount),
                      strong: true,
                    ),
                    if (invoice.paidAmount > 0)
                      _businessPortalPdfAmountRow(
                        'Paid',
                        _businessPortalPdfMoney(invoice.paidAmount),
                      ),
                    _businessPortalPdfAmountRow(
                      'BALANCE DUE',
                      _businessPortalPdfMoney(invoice.amountDue),
                      strong: true,
                      green: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (invoice.payments.isNotEmpty) ...[
          pw.SizedBox(height: 22),
          pw.Text(
            'PAYMENT HISTORY',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: green,
            ),
          ),
          pw.SizedBox(height: 7),
          ...invoice.payments.map(
            (payment) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 5),
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      '${_businessPortalPdfDate(payment.paidAt)} - ${payment.methodLabel}'
                      '${payment.paymentReference.isEmpty ? '' : ' - Ref: ${payment.paymentReference}'}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ),
                  pw.Text(
                    payment.isReversed
                        ? 'REVERSED'
                        : _businessPortalPdfMoney(payment.amount),
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: payment.isReversed ? PdfColors.red700 : green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        pw.SizedBox(height: 24),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          decoration: pw.BoxDecoration(
            color: green,
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Center(
            child: pw.Text(
              invoice.isPaid
                  ? 'PAID IN FULL - THANK YOU'
                  : 'Thank you for supporting Jamaican agriculture.',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  return pdf.save();
}

Future<Uint8List> _buildBusinessPortalReceiptPdf(
  WholesaleInvoice invoice,
  WholesaleInvoicePayment payment,
) async {
  if (payment.isReversed) {
    throw Exception('A reversed payment does not have an active receipt.');
  }

  final pdf = pw.Document();
  final logo = await _loadBusinessPortalPdfLogo();
  final green = PdfColor.fromInt(0xFF1F6B3A);

  final confirmed = invoice.payments.where((item) => item.isConfirmed).toList()
    ..sort((a, b) {
      final aDate = a.paidAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.paidAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aDate.compareTo(bDate);
    });

  double paidToDate = 0;
  bool found = false;

  for (final item in confirmed) {
    paidToDate += item.amount;
    if (item.id == payment.id) {
      found = true;
      break;
    }
  }

  if (!found) paidToDate = invoice.paidAmount;

  final balance = invoice.totalAmount - paidToDate;
  final remaining = balance < 0 ? 0.0 : balance;
  final receiptNumber = _businessPortalShortId(payment.id);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(38),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _businessPortalPdfHeader(
            logo: logo,
            title: 'OFFICIAL WHOLESALE PAYMENT RECEIPT',
            reference: 'Receipt #$receiptNumber',
          ),
          pw.SizedBox(height: 22),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _businessPortalPdfInfoBox(
                  title: 'RECEIVED FROM',
                  lines: [
                    invoice.businessName.trim().isEmpty
                        ? 'Wholesale Business'
                        : invoice.businessName,
                    invoice.contactName,
                    invoice.contactPhone,
                  ],
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _businessPortalPdfInfoBox(
                  title: 'PAYMENT DETAILS',
                  lines: [
                    'Invoice: ${invoice.invoiceNumber}',
                    'Date: ${_businessPortalPdfDate(payment.paidAt)}',
                    'Method: ${payment.methodLabel}',
                    if (payment.paymentReference.isNotEmpty)
                      'Reference: ${payment.paymentReference}',
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 22),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFEAF3EC),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'PAYMENT RECEIVED',
                  style: pw.TextStyle(
                    color: green,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  _businessPortalPdfMoney(payment.amount),
                  style: pw.TextStyle(
                    color: green,
                    fontSize: 27,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 22),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                _businessPortalPdfAmountRow(
                  'Invoice Total',
                  _businessPortalPdfMoney(invoice.totalAmount),
                  strong: true,
                ),
                _businessPortalPdfAmountRow(
                  'This Payment',
                  _businessPortalPdfMoney(payment.amount),
                  green: true,
                ),
                _businessPortalPdfAmountRow(
                  'Paid To Date',
                  _businessPortalPdfMoney(paidToDate),
                ),
                pw.Divider(),
                _businessPortalPdfAmountRow(
                  'Remaining Balance',
                  _businessPortalPdfMoney(remaining),
                  strong: true,
                  green: remaining <= .01,
                ),
              ],
            ),
          ),
          if (payment.paymentNote.trim().isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text(
              'PAYMENT NOTE',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: green,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              _businessPortalPdfClean(payment.paymentNote),
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
          pw.Spacer(),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 10),
            decoration: pw.BoxDecoration(
              color: green,
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Center(
              child: pw.Text(
                remaining <= .01
                    ? 'PAID IN FULL'
                    : 'PAYMENT RECEIVED - THANK YOU',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'This receipt confirms payment recorded against ${invoice.invoiceNumber}.',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey600,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  return pdf.save();
}

// ============================================================================
// SOURCE SECTION: business_home.dart
// ============================================================================
// HPJ PHASE 88 — BUSINESS SOCIAL-COMMERCE HOME
// Extracted from wholesale_management.dart without changing runtime behavior.

class WholesaleDemandGapLine {
  final String demandForecastId;
  final String productName;
  final String unit;
  final double requiredQuantity;
  final double securedQuantity;
  final double gapQuantity;
  final DateTime needByDate;
  final String demandStatus;
  final String sourceType;

  const WholesaleDemandGapLine({
    required this.demandForecastId,
    required this.productName,
    required this.unit,
    required this.requiredQuantity,
    required this.securedQuantity,
    required this.gapQuantity,
    required this.needByDate,
    required this.demandStatus,
    required this.sourceType,
  });

  factory WholesaleDemandGapLine.fromSupabase(Map<String, dynamic> data) {
    double number(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return WholesaleDemandGapLine(
      demandForecastId: (data['demand_forecast_id'] ?? '').toString(),
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      requiredQuantity: number(data['required_quantity']),
      securedQuantity: number(data['secured_quantity']),
      gapQuantity: number(data['gap_quantity']),
      needByDate: parseProductDate(data['need_by_date']) ?? DateTime.now(),
      demandStatus: (data['demand_status'] ?? 'forecast').toString().trim().toLowerCase(),
      sourceType: (data['source_type'] ?? 'planning').toString().trim().toLowerCase(),
    );
  }

  bool get hasGap => gapQuantity > 0.0001;
}

Future<List<WholesaleDemandGapLine>> fetchMyWholesaleDemandGap({
  int horizonDays = 30,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) return const <WholesaleDemandGapLine>[];

  try {
    final response = await supabase.rpc(
      'business_wholesale_demand_gap',
      params: {
        'p_horizon_days': horizonDays.clamp(1, 365),
      },
    );

    return (response as List)
        .map(
          (item) => WholesaleDemandGapLine.fromSupabase(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  } catch (error) {
    farmDebugLog(
      'Wholesale business demand-gap insight unavailable: $error',
    );
    rethrow;
  }
}

class _WholesaleTodaySnapshot {
  final List<WholesaleDemandForecast> forecasts;
  final List<WholesaleOrderRequest> requests;
  final List<WholesaleInvoice> invoices;
  final List<WholesaleOrderJourney> journeys;
  final List<WholesaleProduct> catalogue;
  final List<WholesaleDemandGapLine> demandGaps;
  final WholesaleOrderingControl? orderingControl;
  final Set<String> unavailableSections;

  const _WholesaleTodaySnapshot({
    required this.forecasts,
    required this.requests,
    required this.invoices,
    required this.journeys,
    required this.catalogue,
    this.demandGaps = const <WholesaleDemandGapLine>[],
    this.orderingControl,
    this.unavailableSections = const <String>{},
  });

  bool get hasLoadIssues => unavailableSections.isNotEmpty;
}

Future<_WholesaleTodaySnapshot> fetchWholesaleTodaySnapshot({
  BusinessAccount? account,
}) async {
  final unavailableSections = <String>{};

  Future<List<WholesaleDemandForecast>> loadForecasts() async {
    try {
      return await fetchMyWholesaleDemandForecasts(
        includeCancelled: false,
      );
    } catch (error) {
      unavailableSections.add('Planning');
      farmDebugLog('Wholesale Today — planning unavailable: $error');
      return <WholesaleDemandForecast>[];
    }
  }

  Future<List<WholesaleOrderRequest>> loadRequests() async {
    try {
      return await fetchMyWholesaleRequests(
        limit: 200,
      );
    } catch (error) {
      unavailableSections.add('Orders');
      farmDebugLog('Wholesale Today — orders unavailable: $error');
      return <WholesaleOrderRequest>[];
    }
  }

  Future<List<WholesaleInvoice>> loadInvoices() async {
    try {
      return await fetchMyWholesaleInvoices(
        includePaid: true,
        limit: 300,
      );
    } catch (error) {
      unavailableSections.add('Invoices');
      farmDebugLog('Wholesale Today — invoices unavailable: $error');
      return <WholesaleInvoice>[];
    }
  }

  Future<List<WholesaleOrderJourney>> loadJourneys() async {
    try {
      return await fetchMyWholesaleOrderJourneys();
    } catch (error) {
      unavailableSections.add('Tracking');
      farmDebugLog('Wholesale Today — tracking unavailable: $error');
      return <WholesaleOrderJourney>[];
    }
  }

  Future<List<WholesaleProduct>> loadCatalogue() async {
    try {
      return await fetchWholesaleCatalogue();
    } catch (error) {
      unavailableSections.add('Catalogue');
      farmDebugLog('Wholesale Today — catalogue unavailable: $error');
      return <WholesaleProduct>[];
    }
  }

  Future<List<WholesaleDemandGapLine>> loadDemandGaps() async {
    try {
      return await fetchMyWholesaleDemandGap(
        horizonDays: 30,
      );
    } catch (error) {
      unavailableSections.add('Demand insight');
      farmDebugLog(
        'Wholesale Today — business insight unavailable: $error',
      );
      return <WholesaleDemandGapLine>[];
    }
  }

  Future<WholesaleOrderingControl?> loadOrderingControl() async {
    try {
      return await fetchWholesaleOrderingControl(
        account: account,
      );
    } catch (error) {
      unavailableSections.add('Ordering status');
      farmDebugLog(
        'Wholesale Today — ordering status unavailable: $error',
      );
      return null;
    }
  }

  final forecastsFuture = loadForecasts();
  final requestsFuture = loadRequests();
  final invoicesFuture = loadInvoices();
  final journeysFuture = loadJourneys();
  final catalogueFuture = loadCatalogue();
  final demandGapsFuture = loadDemandGaps();
  final orderingControlFuture = loadOrderingControl();

  final forecasts = await forecastsFuture;
  final requests = await requestsFuture;
  final invoices = await invoicesFuture;
  final journeys = await journeysFuture;
  final catalogue = await catalogueFuture;
  var demandGaps = await demandGapsFuture;
  final orderingControl = await orderingControlFuture;

  if (demandGaps.isEmpty && forecasts.isNotEmpty) {
    final today = DateTime.now();
    final cutoff = today.add(
      const Duration(days: 30),
    );

    demandGaps = forecasts
        .where(
          (item) =>
              !item.isCancelled &&
              !item.needByDate.isBefore(
                DateTime(
                  today.year,
                  today.month,
                  today.day,
                ),
              ) &&
              !item.needByDate.isAfter(cutoff),
        )
        .map(
          (item) {
            final fullySecured =
                item.isReserved || item.isConverted;

            return WholesaleDemandGapLine(
              demandForecastId: item.id,
              productName: item.productName,
              unit: item.unit,
              requiredQuantity: item.quantity,
              securedQuantity:
                  fullySecured ? item.quantity : 0,
              gapQuantity:
                  fullySecured ? 0 : item.quantity,
              needByDate: item.needByDate,
              demandStatus: item.status,
              sourceType: item.sourceType,
            );
          },
        )
        .toList();
  }

  return _WholesaleTodaySnapshot(
    forecasts: forecasts,
    requests: requests,
    invoices: invoices,
    journeys: journeys,
    catalogue: catalogue,
    demandGaps: demandGaps,
    orderingControl: orderingControl,
    unavailableSections:
        Set<String>.unmodifiable(unavailableSections),
  );
}

class _PremiumBusinessHeadquartersHero extends StatelessWidget {
  final BusinessAccount account;
  final int activeNeeds;
  final int supplyGaps;
  final double amountDue;
  final int deliveriesToday;
  final bool hasLoadIssues;
  final VoidCallback onOpenShop;
  final VoidCallback onOpenPlan;
  final VoidCallback onOpenOrders;

  const _PremiumBusinessHeadquartersHero({
    required this.account,
    required this.activeNeeds,
    required this.supplyGaps,
    required this.amountDue,
    required this.deliveriesToday,
    required this.hasLoadIssues,
    required this.onOpenShop,
    required this.onOpenPlan,
    required this.onOpenOrders,
  });

  Widget _metric({
    required IconData icon,
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    final content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFFE8C768),
            size: 17,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(.72),
              fontSize: 8.7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return Expanded(child: content);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: content,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessName = account.displayName.trim().isEmpty
        ? 'Your Business'
        : account.displayName.trim();

    final subtitle = <String>[
      if (account.businessType.trim().isNotEmpty)
        account.businessType.trim(),
      if (account.parish.trim().isNotEmpty)
        account.parish.trim(),
    ].join(' • ');

    if (hpjUseMobileAppPresentation(context)) {
      return _HpjBusinessMobileHeaderCard(
        icon: Icons.business_rounded,
        eyebrow: 'BUSINESS HOME',
        title: businessName,
        subtitle: subtitle.isEmpty
            ? 'Source Jamaican produce through HPJ.'
            : subtitle,
        status: 'APPROVED',
        metrics: <_HpjBusinessMobileMetricData>[
          _HpjBusinessMobileMetricData(
            value: '$activeNeeds',
            label: 'Needs',
          ),
          _HpjBusinessMobileMetricData(
            value: '$supplyGaps',
            label: 'Supply gaps',
            warning: supplyGaps > 0,
          ),
          _HpjBusinessMobileMetricData(
            value: amountDue > 0 ? formatJmd(amountDue) : 'Clear',
            label: 'Amount due',
            warning: amountDue > 0,
          ),
          _HpjBusinessMobileMetricData(
            value: '$deliveriesToday',
            label: 'Today',
          ),
        ],
        onAction: onOpenShop,
        actionLabel: 'Source produce',
        actionIcon: Icons.shopping_basket_outlined,
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FarmColors.deepGreen,
            FarmColors.green,
            Color(0xFF4E8157),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: FarmColors.deepGreen.withOpacity(.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
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
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.14),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: Colors.white.withOpacity(.20),
                  ),
                ),
                child: Image.asset(
                  'lib/assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.business_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BUSINESS HQ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(.72),
                        fontSize: 10.3,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .9,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(.78),
                          fontSize: 10.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D7B46).withOpacity(.35),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withOpacity(.18),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 13,
                      color: Color(0xFFE8C768),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'APPROVED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            'Order fresh Jamaican produce, plan future demand and keep '
            'purchasing activity moving through HPJ.',
            style: TextStyle(
              color: Colors.white.withOpacity(.84),
              fontSize: 11.2,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _metric(
                icon: Icons.event_note_outlined,
                value: hasLoadIssues ? '—' : '$activeNeeds',
                label: hasLoadIssues
                    ? 'Needs unavailable'
                    : 'Planned needs',
                onTap: onOpenPlan,
              ),
              const SizedBox(width: 8),
              _metric(
                icon: Icons.warning_amber_rounded,
                value: hasLoadIssues ? '—' : '$supplyGaps',
                label: hasLoadIssues
                    ? 'Gaps unavailable'
                    : 'Supply gaps',
                onTap: onOpenPlan,
              ),
              const SizedBox(width: 8),
              _metric(
                icon: Icons.payments_outlined,
                value:
                    hasLoadIssues ? '—' : formatJmd(amountDue),
                label: hasLoadIssues
                    ? 'Balance unavailable'
                    : 'Amount due',
                onTap: onOpenOrders,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.10),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(.14),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  deliveriesToday > 0
                      ? Icons.local_shipping_outlined
                      : Icons.storefront_outlined,
                  color: const Color(0xFFE8C768),
                  size: 17,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    deliveriesToday > 0
                        ? '$deliveriesToday ${deliveriesToday == 1 ? 'delivery' : 'deliveries'} scheduled today'
                        : 'Your approved HPJ Business workspace is ready for purchasing.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.84),
                      fontSize: 9.6,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onOpenShop,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Shop'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumWebBusinessMvpHero extends StatelessWidget {
  final BusinessAccount account;
  final int activeNeeds;
  final int supplyGaps;
  final double amountDue;
  final int deliveriesToday;
  final bool hasLoadIssues;
  final VoidCallback onOpenShop;
  final VoidCallback onOpenPlan;
  final VoidCallback onOpenOrders;

  const _PremiumWebBusinessMvpHero({
    required this.account,
    required this.activeNeeds,
    required this.supplyGaps,
    required this.amountDue,
    required this.deliveriesToday,
    required this.hasLoadIssues,
    required this.onOpenShop,
    required this.onOpenPlan,
    required this.onOpenOrders,
  });

  Widget _metric({
    required IconData icon,
    required String value,
    required String label,
    bool warning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.11),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: warning
              ? const Color(0xFFE8C768).withOpacity(.45)
              : Colors.white.withOpacity(.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFFE8C768),
            size: 18,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(.72),
              fontSize: 8.7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool emphasized = false,
  }) {
    return Material(
      color: emphasized
          ? const Color(0xFFE8C768)
          : Colors.white.withOpacity(.10),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: emphasized
                  ? const Color(0xFFE8C768)
                  : Colors.white.withOpacity(.15),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: emphasized
                    ? FarmColors.deepGreen
                    : Colors.white,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: emphasized
                            ? FarmColors.deepGreen
                            : Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: emphasized
                            ? FarmColors.deepGreen.withOpacity(.70)
                            : Colors.white.withOpacity(.68),
                        fontSize: 8.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: emphasized
                    ? FarmColors.deepGreen
                    : Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessName = account.displayName.trim().isEmpty
        ? 'Your Business'
        : account.displayName.trim();

    final businessLine = <String>[
      if (account.businessType.trim().isNotEmpty)
        account.businessType.trim(),
      if (account.parish.trim().isNotEmpty)
        account.parish.trim(),
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FarmColors.deepGreen,
            FarmColors.green,
            Color(0xFF4E8157),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: FarmColors.deepGreen.withOpacity(.14),
            blurRadius: 26,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.13),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withOpacity(.18),
                        ),
                      ),
                      child: Image.asset(
                        'lib/assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(
                          Icons.business_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'HPJ BUSINESS',
                      style: TextStyle(
                        color: Color(0xFFCFE0CF),
                        fontSize: 10.2,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .9,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withOpacity(.14),
                        ),
                      ),
                      child: Text(
                        hasLoadIssues
                            ? 'PARTIAL DATA'
                            : 'BUSINESS READY',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    height: 1.02,
                    letterSpacing: -.6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (businessLine.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    businessLine,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.70),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: 610,
                  child: Text(
                    'Order fresh produce, plan future requirements, discover verified farms and follow fulfilment from one purchasing workspace.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.82),
                      fontSize: 12.3,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 19),
                Row(
                  children: [
                    Expanded(
                      child: _action(
                        icon: Icons.shopping_cart_outlined,
                        title: 'Order Produce',
                        subtitle: 'Shop wholesale supply',
                        onTap: onOpenShop,
                        emphasized: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _action(
                        icon: Icons.calendar_month_outlined,
                        title: 'Plan Ahead',
                        subtitle: 'Share future demand',
                        onTap: onOpenPlan,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _action(
                        icon: Icons.local_shipping_outlined,
                        title: 'Track Orders',
                        subtitle: 'Follow fulfilment',
                        onTap: onOpenOrders,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _metric(
                        icon: Icons.event_note_outlined,
                        value: '$activeNeeds',
                        label: 'Active needs',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metric(
                        icon: Icons.warning_amber_rounded,
                        value: '$supplyGaps',
                        label: 'Supply gaps',
                        warning: supplyGaps > 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _metric(
                        icon: Icons.payments_outlined,
                        value: formatJmd(amountDue),
                        label: 'Amount due',
                        warning: amountDue > 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metric(
                        icon: Icons.local_shipping_outlined,
                        value: '$deliveriesToday',
                        label: 'Deliveries today',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.09),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(.14),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        color: Color(0xFFE8C768),
                        size: 17,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Verified farms • Planning • Repeat purchasing • Invoices • Tracking',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(.80),
                            fontSize: 8.8,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

class _ApprovedWholesaleDashboard extends StatelessWidget {
  final BusinessAccount account;
  final VoidCallback? onOpenShop;
  final VoidCallback? onOpenPlan;
  final VoidCallback? onOpenOrders;
  final VoidCallback? onOpenAccount;
  final VoidCallback? onOpenSuppliers;
  final VoidCallback? onRetry;

  const _ApprovedWholesaleDashboard({
    required this.account,
    this.onOpenShop,
    this.onOpenPlan,
    this.onOpenOrders,
    this.onOpenAccount,
    this.onOpenSuppliers,
    this.onRetry,
  });

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  void _goPlan(BuildContext context) {
    final callback = onOpenPlan;
    if (callback != null) {
      callback();
      return;
    }
    _open(context, WholesalePlanningAheadScreen(account: account));
  }

  void _goShop(BuildContext context) {
    final callback = onOpenShop;
    if (callback != null) {
      callback();
      return;
    }
    _open(context, WholesaleCatalogueScreen(account: account));
  }

  void _goOrders(BuildContext context) {
    final callback = onOpenOrders;
    if (callback != null) {
      callback();
      return;
    }
    _open(context, const MyWholesaleRequestsScreen());
  }

  void _goAccount(BuildContext context) {
    final callback = onOpenAccount;
    if (callback != null) {
      callback();
      return;
    }
    _open(context, _BusinessDetailsEditScreen(account: account));
  }

  void _goSuppliers(BuildContext context) {
    final callback = onOpenSuppliers;
    if (callback != null) {
      callback();
      return;
    }

    _open(
      context,
      WholesaleSupplierDiscoveryScreen(account: account),
    );
  }

  void _goDemandNetwork(BuildContext context) {
    _open(
      context,
      HpjBusinessDemandNetworkScreen(account: account),
    );
  }

  void _goInvoices(BuildContext context) {
    _open(
      context,
      BusinessWholesaleInvoicesScreen(account: account),
    );
  }

  void _goRepeatOrders(BuildContext context) {
    _open(
      context,
      WholesaleRepeatStandingOrdersScreen(account: account),
    );
  }

  Future<void> _handleAgricultureFeedAction(
    BuildContext context,
    AgricultureFeedUpdate update,
  ) async {
    switch (update.actionType) {
      case 'wholesale_shop':
        _goShop(context);
        return;
      case 'wholesale_plan':
        _goPlan(context);
        return;
      case 'customer_care':
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => SupportScreen(
              initialSubject: update.title,
            ),
          ),
        );
        return;
      case 'external':
        final url = update.sourceUrl?.trim() ?? '';
        if (url.isEmpty) return;
        final opened = await openExternalShareUrl(url);
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the source link.')),
          );
        }
        return;
      default:
        return;
    }
  }

  bool _sameDay(DateTime? value, DateTime day) {
    if (value == null) return false;
    final local = value.toLocal();
    return local.year == day.year &&
        local.month == day.month &&
        local.day == day.day;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_WholesaleTodaySnapshot>(
      future: fetchWholesaleTodaySnapshot(account: account),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const SizedBox(
            height: 360,
            child: SkeletonList(count: 4),
          );
        }

        final data = snapshot.data ??
            const _WholesaleTodaySnapshot(
              forecasts: <WholesaleDemandForecast>[],
              requests: <WholesaleOrderRequest>[],
              invoices: <WholesaleInvoice>[],
              journeys: <WholesaleOrderJourney>[],
              catalogue: <WholesaleProduct>[],
            );

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final activeForecasts =
            data.forecasts.where((item) => item.isActive).toList()
              ..sort((a, b) => a.needByDate.compareTo(b.needByDate));

        final forecastsNeedingReview =
            activeForecasts.where(_wholesaleForecastNeedsReview).toList();

        final deliveriesToday = data.journeys.where((journey) {
          return !journey.isCollection &&
              journey.requestStatus != 'cancelled' &&
              journey.requestStatus != 'rejected' &&
              _sameDay(journey.scheduledFor, today);
        }).length;

        final awaitingReceipt = data.journeys
            .where((journey) => journey.canConfirmReceipt)
            .toList(growable: false);

        final overdueInvoices = data.invoices
            .where(
              (item) =>
                  item.amountDue > 0.0001 &&
                  item.dueDate != null &&
                  item.dueDate!.isBefore(today),
            )
            .toList();

        final nextNeed = activeForecasts.isEmpty ? null : activeForecasts.first;
        final nextNeedSoon = nextNeed != null &&
            nextNeed.needByDate.difference(today).inDays <= 7;
        final nextNeedNeedsReview =
            nextNeed != null && _wholesaleForecastNeedsReview(nextNeed);

        final detailsReady = account.phone.trim().isNotEmpty &&
            account.address.trim().isNotEmpty &&
            account.parish.trim().isNotEmpty;

        final dailyPicks = _wholesaleSmartCataloguePicks(
          catalogue: data.catalogue,
          forecasts: activeForecasts,
          requests: data.requests,
          day: today,
        );

        final gapLines = data.demandGaps;
        final gapLinesNeedingSupply = gapLines
            .where((item) => item.hasGap)
            .toList(growable: false);
        final securedDemandLines = gapLines
            .where((item) => !item.hasGap)
            .length;

        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        final ninetyDaysAgo = now.subtract(const Duration(days: 90));

        // Financial purchasing totals come from the latest issued invoice for
        // each request, not from request status or the earlier order estimate.
        // This keeps Purchased/90-day spend aligned with the final packed bill.
        final invoiceByRequest = <String, WholesaleInvoice>{};
        for (final invoice in data.invoices) {
          final requestId = invoice.requestId.trim();
          if (requestId.isEmpty || invoice.isVoid) continue;
          invoiceByRequest.putIfAbsent(requestId, () => invoice);
        }

        DateTime? invoiceActivityDate(WholesaleInvoice invoice) {
          return invoice.issuedAt ?? invoice.issueDate ?? invoice.createdAt;
        }

        bool invoicedSince(WholesaleInvoice invoice, DateTime cutoff) {
          final activity = invoiceActivityDate(invoice);
          return activity != null && !activity.isBefore(cutoff);
        }

        final finalInvoices = invoiceByRequest.values.toList(growable: false);
        final purchased30 = finalInvoices
            .where((item) => invoicedSince(item, thirtyDaysAgo))
            .toList(growable: false);
        final purchased90 = finalInvoices
            .where((item) => invoicedSince(item, ninetyDaysAgo))
            .toList(growable: false);
        final spend30 = purchased30.fold<double>(
          0,
          (sum, item) => sum + item.totalAmount,
        );
        final spend90 = purchased90.fold<double>(
          0,
          (sum, item) => sum + item.totalAmount,
        );

        final orderingControl = data.orderingControl;
        final attentionRows = <Widget>[];

        void addAttention(Widget row) {
          attentionRows.add(row);
        }

        if (orderingControl != null &&
            (orderingControl.isBlocked || orderingControl.hasWarning)) {
          addAttention(
            _WholesaleAttentionRow(
              title: orderingControl.statusLabel,
              message: orderingControl.reason.isEmpty
                  ? 'Review your wholesale account before placing another order.'
                  : orderingControl.reason,
              action: orderingControl.outstandingInvoices > 0
                  ? 'Payments'
                  : 'Account',
              onTap: orderingControl.outstandingInvoices > 0
                  ? () => _goInvoices(context)
                  : () => _goAccount(context),
            ),
          );
        }

        if (!detailsReady) {
          addAttention(
            _WholesaleAttentionRow(
              title: 'Complete business details',
              message:
                  'Add your phone, parish and delivery address before fulfilment.',
              action: 'Account',
              onTap: () => _goAccount(context),
            ),
          );
        }

        if (forecastsNeedingReview.isNotEmpty) {
          addAttention(
            _WholesaleAttentionRow(
              title:
                  '${forecastsNeedingReview.length} planned need${forecastsNeedingReview.length == 1 ? '' : 's'} need review',
              message:
                  'Confirm dates and quantities so HPJ can keep your supply plan current.',
              action: 'Review',
              onTap: () => _goPlan(context),
            ),
          );
        } else if (nextNeed != null && nextNeedSoon && !nextNeedNeedsReview) {
          addAttention(
            _WholesaleAttentionRow(
              title: '${nextNeed.productName} is needed soon',
              message:
                  '${nextNeed.quantity.toStringAsFixed(nextNeed.quantity == nextNeed.quantity.roundToDouble() ? 0 : 1)} ${nextNeed.unit} is planned for ${_wholesaleSimpleDate(nextNeed.needByDate)}.',
              action: 'View plan',
              onTap: () => _goPlan(context),
            ),
          );
        }

        if (overdueInvoices.isNotEmpty) {
          addAttention(
            _WholesaleAttentionRow(
              title:
                  '${overdueInvoices.length} overdue invoice${overdueInvoices.length == 1 ? '' : 's'}',
              message:
                  '${formatJmd(overdueInvoices.fold<double>(0, (sum, item) => sum + item.amountDue))} requires attention.',
              action: 'Payments',
              onTap: () => _goInvoices(context),
            ),
          );
        }

        if (awaitingReceipt.isNotEmpty) {
          addAttention(
            _WholesaleAttentionRow(
              title:
                  'Confirm ${awaitingReceipt.length} delivered order${awaitingReceipt.length == 1 ? '' : 's'}',
              message:
                  'HPJ marked ${awaitingReceipt.length == 1 ? 'this delivery' : 'these deliveries'} delivered. Confirm receipt after your business checks the order.',
              action: 'Orders',
              onTap: () => _goOrders(context),
            ),
          );
        }

        if (attentionRows.isEmpty &&
            !data.hasLoadIssues &&
            data.forecasts.isEmpty &&
            data.requests.isEmpty) {
          addAttention(
            _WholesaleAttentionRow(
              title: 'Add your upcoming needs',
              message:
                  'Tell HPJ what your business expects to need so supply can be prepared early.',
              action: 'Plan Ahead',
              onTap: () => _goPlan(context),
            ),
          );
        }

        final mobileBusinessApp = hpjUseMobileAppPresentation(context);
        final desktopBusinessWeb =
            kIsWeb && MediaQuery.sizeOf(context).width >= 1100;

        if (mobileBusinessApp) {
          return _HpjEliteBusinessMobileHome(
            account: account,
            activeForecasts: activeForecasts,
            gapLines: gapLinesNeedingSupply,
            recommendedProducts: dailyPicks,
            attentionRows: attentionRows,
            activeNeeds: activeForecasts.length,
            supplyGaps: gapLinesNeedingSupply.length,
            amountDue: data.invoices.fold<double>(
              0,
              (sum, item) => sum + item.amountDue,
            ),
            deliveriesToday: deliveriesToday,
            securedDemandLines: securedDemandLines,
            purchasedOrders30: purchased30.length,
            spend30: spend30,
            spend90: spend90,
            hasLoadIssues: data.hasLoadIssues,
            unavailableSections: data.unavailableSections,
            onRetry: onRetry,
            onOpenShop: () => _goShop(context),
            onOpenPlan: () => _goPlan(context),
            onOpenOrders: () => _goOrders(context),
            onOpenAccount: () => _goAccount(context),
            onOpenDemandNetwork: () => _goDemandNetwork(context),
            onFindSuppliers: () => _goSuppliers(context),
            onAgricultureAction: (update) =>
                _handleAgricultureFeedAction(context, update),
          );
        }

        if (desktopBusinessWeb) {
          return _EliteBusinessSocialCommerceHome(
            account: account,
            activeForecasts: activeForecasts,
            gapLines: gapLinesNeedingSupply,
            recommendedProducts: dailyPicks,
            attentionRows: attentionRows,
            activeNeeds: activeForecasts.length,
            supplyGaps: gapLinesNeedingSupply.length,
            amountDue: data.invoices.fold<double>(
              0,
              (sum, item) => sum + item.amountDue,
            ),
            deliveriesToday: deliveriesToday,
            spend30: spend30,
            spend90: spend90,
            hasLoadIssues: data.hasLoadIssues,
            unavailableSections: data.unavailableSections,
            onRetry: onRetry,
            onOpenShop: () => _goShop(context),
            onOpenPlan: () => _goPlan(context),
            onOpenOrders: () => _goOrders(context),
            onOpenAccount: () => _goAccount(context),
            onOpenDemandNetwork: () => _goDemandNetwork(context),
            onFindSuppliers: () => _open(
              context,
              WholesaleSupplierDiscoveryScreen(account: account),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (kIsWeb &&
                MediaQuery.sizeOf(context).width >= 1100)
              _PremiumWebBusinessMvpHero(
                account: account,
                activeNeeds: activeForecasts.length,
                supplyGaps: gapLinesNeedingSupply.length,
                amountDue: data.invoices.fold<double>(
                  0,
                  (sum, item) => sum + item.amountDue,
                ),
                deliveriesToday: deliveriesToday,
                hasLoadIssues: data.hasLoadIssues,
                onOpenShop: () => _goShop(context),
                onOpenPlan: () => _goPlan(context),
                onOpenOrders: () => _goOrders(context),
              )
            else
              _PremiumBusinessHeadquartersHero(
                account: account,
                activeNeeds: activeForecasts.length,
                supplyGaps: gapLinesNeedingSupply.length,
                amountDue: data.invoices.fold<double>(
                  0,
                  (sum, item) => sum + item.amountDue,
                ),
                deliveriesToday: deliveriesToday,
                hasLoadIssues: data.hasLoadIssues,
                onOpenShop: () => _goShop(context),
                onOpenPlan: () => _goPlan(context),
                onOpenOrders: () => _goOrders(context),
              ),
            if (data.hasLoadIssues) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  12,
                  10,
                  8,
                  10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: FarmColors.warning.withOpacity(.28),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: FarmColors.warning,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Some business data could not load: '
                        '${data.unavailableSections.join(', ')}. '
                        'Figures marked unavailable should not be treated as zero.',
                        style: const TextStyle(
                          color: FarmColors.ink,
                          fontSize: 9.6,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onRetry,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _WholesaleHomeQuickActions(
              onOrderNow: () => _goShop(context),
              onPlanAhead: () => _goPlan(context),
              onFindSuppliers: () => _goSuppliers(context),
              onTrackOrders: () => _goOrders(context),
            ),
            const SizedBox(height: 12),
            _HpjBusinessDemandNetworkEntryCard(
              onTap: () => _goDemandNetwork(context),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final desktopWeb =
                    kIsWeb && MediaQuery.sizeOf(context).width >= 1100;
                final useDesktopRow =
                    desktopWeb &&
                    constraints.maxWidth >= 980 &&
                    attentionRows.isNotEmpty;

                final businessStatus = _WholesaleBusinessSnapshotCard(
                  businessName: account.displayName,
                  demandLineCount: gapLines.length,
                  securedLineCount: securedDemandLines,
                  gapLineCount: gapLinesNeedingSupply.length,
                  purchasedOrders30: purchased30.length,
                  spend30: spend30,
                  spend90: spend90,
                  deliveriesToday: deliveriesToday,
                  gapLines: gapLinesNeedingSupply,
                  unavailableSections: data.unavailableSections,
                  onOpenPlan: () => _goPlan(context),
                  onOpenOrders: () => _goOrders(context),
                );

                if (!useDesktopRow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (attentionRows.isNotEmpty) ...[
                        const SectionHeader(
                          title: 'Action needed',
                          subtitle:
                              'The highest-priority item for your business.',
                        ),
                        const SizedBox(height: 9),
                        FarmCard(
                          padding: const EdgeInsets.all(14),
                          child: attentionRows.first,
                        ),
                        const SizedBox(height: 20),
                      ],
                      businessStatus,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'Action needed',
                            subtitle:
                                'The highest-priority item for your business.',
                          ),
                          const SizedBox(height: 9),
                          FarmCard(
                            padding: const EdgeInsets.all(14),
                            child: attentionRows.first,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 6,
                      child: businessStatus,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            _WholesaleMarketIntelligenceCard(
              dailyPicks: dailyPicks,
              activeForecasts: activeForecasts,
              gapLines: gapLinesNeedingSupply,
              onOpenShop: () => _goShop(context),
              onOpenPlan: () => _goPlan(context),
              onAgricultureAction: (update) =>
                  _handleAgricultureFeedAction(context, update),
            ),
          ],
        );
      },
    );
  }
}



// =====================================================
// HPJ BUSINESS SUPER ELITE — RESPONSIVE APP HOME
// Uses the same live Business data as desktop while prioritising the five
// jobs a buyer needs on a phone: source, plan, suppliers, orders and account.
// =====================================================

class _HpjEliteBusinessMobileHome extends StatelessWidget {
  final BusinessAccount account;
  final List<WholesaleDemandForecast> activeForecasts;
  final List<WholesaleDemandGapLine> gapLines;
  final List<WholesaleProduct> recommendedProducts;
  final List<Widget> attentionRows;
  final int activeNeeds;
  final int supplyGaps;
  final double amountDue;
  final int deliveriesToday;
  final int securedDemandLines;
  final int purchasedOrders30;
  final double spend30;
  final double spend90;
  final bool hasLoadIssues;
  final Set<String> unavailableSections;
  final VoidCallback? onRetry;
  final VoidCallback onOpenShop;
  final VoidCallback onOpenPlan;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenDemandNetwork;
  final VoidCallback onFindSuppliers;
  final Future<void> Function(AgricultureFeedUpdate) onAgricultureAction;

  const _HpjEliteBusinessMobileHome({
    required this.account,
    required this.activeForecasts,
    required this.gapLines,
    required this.recommendedProducts,
    required this.attentionRows,
    required this.activeNeeds,
    required this.supplyGaps,
    required this.amountDue,
    required this.deliveriesToday,
    required this.securedDemandLines,
    required this.purchasedOrders30,
    required this.spend30,
    required this.spend90,
    required this.hasLoadIssues,
    required this.unavailableSections,
    required this.onRetry,
    required this.onOpenShop,
    required this.onOpenPlan,
    required this.onOpenOrders,
    required this.onOpenAccount,
    required this.onOpenDemandNetwork,
    required this.onFindSuppliers,
    required this.onAgricultureAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PremiumBusinessHeadquartersHero(
          account: account,
          activeNeeds: activeNeeds,
          supplyGaps: supplyGaps,
          amountDue: amountDue,
          deliveriesToday: deliveriesToday,
          hasLoadIssues: hasLoadIssues,
          onOpenShop: onOpenShop,
          onOpenPlan: onOpenPlan,
          onOpenOrders: onOpenOrders,
        ),
        if (hasLoadIssues) ...[
          const SizedBox(height: 10),
          _EliteBusinessLoadWarning(
            unavailableSections: unavailableSections,
            onRetry: onRetry,
          ),
        ],
        const SizedBox(height: 15),
        _WholesaleHomeQuickActions(
          onOrderNow: onOpenShop,
          onPlanAhead: onOpenPlan,
          onFindSuppliers: onFindSuppliers,
          onTrackOrders: onOpenOrders,
        ),
        const SizedBox(height: 13),
        _HpjBusinessDemandNetworkEntryCard(
          onTap: onOpenDemandNetwork,
        ),
        const SizedBox(height: 18),
        _HpjBusinessMobileSectionTitle(
          icon: Icons.warning_amber_rounded,
          title: 'Supply gaps',
          subtitle: 'Requirements HPJ is still working to secure.',
          action: 'Plan',
          onAction: onOpenPlan,
        ),
        const SizedBox(height: 9),
        _HpjBusinessMobileGapList(
          gaps: gapLines,
          onOpenPlan: onOpenPlan,
        ),
        const SizedBox(height: 18),
        _HpjBusinessMobileSectionTitle(
          icon: Icons.storefront_outlined,
          title: 'Fresh Supply',
          subtitle: 'Wholesale produce available now.',
          action: 'View all',
          onAction: onOpenShop,
        ),
        const SizedBox(height: 9),
        _HpjBusinessMobileFreshSupply(
          products: recommendedProducts,
          onOpenShop: onOpenShop,
        ),
        if (attentionRows.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _HpjBusinessMobileSectionTitle(
            icon: Icons.priority_high_rounded,
            title: 'Action needed',
            subtitle: 'The highest-priority item for your business.',
          ),
          const SizedBox(height: 9),
          FarmCard(
            padding: const EdgeInsets.all(13),
            child: attentionRows.first,
          ),
        ],
        const SizedBox(height: 18),
        _HpjBusinessMobileStatusCard(
          activeNeeds: activeNeeds,
          supplyGaps: supplyGaps,
          securedDemandLines: securedDemandLines,
          purchasedOrders30: purchasedOrders30,
          spend30: spend30,
          spend90: spend90,
          amountDue: amountDue,
          deliveriesToday: deliveriesToday,
          onOpenPlan: onOpenPlan,
          onOpenOrders: onOpenOrders,
          onOpenAccount: onOpenAccount,
        ),
        const SizedBox(height: 14),
        _WholesaleMarketIntelligenceCard(
          dailyPicks: recommendedProducts,
          activeForecasts: activeForecasts,
          gapLines: gapLines,
          onOpenShop: onOpenShop,
          onOpenPlan: onOpenPlan,
          onAgricultureAction: onAgricultureAction,
        ),
      ],
    );
  }
}

class _HpjBusinessMobileSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onAction;

  const _HpjBusinessMobileSectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFEDF6E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFF0B5B3D),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: FarmColors.ink,
                  fontSize: 15.5,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.25,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 10.5,
                  height: 1.28,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (action != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0B5B3D),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: Text(action!),
          ),
      ],
    );
  }
}

class _HpjBusinessMobileGapList extends StatelessWidget {
  final List<WholesaleDemandGapLine> gaps;
  final VoidCallback onOpenPlan;

  const _HpjBusinessMobileGapList({
    required this.gaps,
    required this.onOpenPlan,
  });

  String _qty(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final visible = gaps.take(3).toList(growable: false);

    if (visible.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F8EF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDDE7D9)),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 20,
              color: Color(0xFF11814C),
            ),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'No current supply gaps. HPJ is aligned with your active plan.',
                style: TextStyle(
                  color: Color(0xFF315541),
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return FarmCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            InkWell(
              onTap: onOpenPlan,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 11, 10, 11),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3DD),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        size: 17,
                        color: Color(0xFFB77A10),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visible[i].productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FarmColors.ink,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_qty(visible[i].gapQuantity)} ${visible[i].unit} still needed • Need by ${_wholesaleSimpleDate(visible[i].needByDate)}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 10.5,
                              height: 1.25,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: FarmColors.mutedText,
                      size: 19,
                    ),
                  ],
                ),
              ),
            ),
            if (i != visible.length - 1)
              const Divider(height: 1, indent: 57),
          ],
        ],
      ),
    );
  }
}

class _HpjBusinessMobileFreshSupply extends StatelessWidget {
  final List<WholesaleProduct> products;
  final VoidCallback onOpenShop;

  const _HpjBusinessMobileFreshSupply({
    required this.products,
    required this.onOpenShop,
  });

  @override
  Widget build(BuildContext context) {
    final picks = products.take(4).toList(growable: false);

    if (picks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEFB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDDE7DB)),
        ),
        child: const Text(
          'Fresh wholesale recommendations will appear as supply becomes available.',
          style: TextStyle(
            color: FarmColors.mutedText,
            fontSize: 10.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return SizedBox(
      height: 205,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: picks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 154,
            child: _HpjBusinessMobileProductCard(
              item: picks[index],
              onTap: onOpenShop,
            ),
          );
        },
      ),
    );
  }
}

class _HpjBusinessMobileProductCard extends StatelessWidget {
  final WholesaleProduct item;
  final VoidCallback onTap;

  const _HpjBusinessMobileProductCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.product.imageUrl?.trim() ?? '';

    return Material(
      color: const Color(0xFFFFFEFB),
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFDDE7DB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 104,
                width: double.infinity,
                child: imageUrl.isEmpty
                    ? Container(
                        color: const Color(0xFFF0F6ED),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.eco_outlined,
                          color: Color(0xFF0B5B3D),
                          size: 30,
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF0F6ED),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.eco_outlined,
                            color: Color(0xFF0B5B3D),
                            size: 30,
                          ),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.formattedWholesalePrice} / ${item.wholesaleUnit}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0B6B43),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      width: double.infinity,
                      height: 31,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF6E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'View supply',
                        style: TextStyle(
                          color: Color(0xFF0B5B3D),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
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
    );
  }
}

class _HpjBusinessMobileStatusCard extends StatelessWidget {
  final int activeNeeds;
  final int supplyGaps;
  final int securedDemandLines;
  final int purchasedOrders30;
  final double spend30;
  final double spend90;
  final double amountDue;
  final int deliveriesToday;
  final VoidCallback onOpenPlan;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenAccount;

  const _HpjBusinessMobileStatusCard({
    required this.activeNeeds,
    required this.supplyGaps,
    required this.securedDemandLines,
    required this.purchasedOrders30,
    required this.spend30,
    required this.spend90,
    required this.amountDue,
    required this.deliveriesToday,
    required this.onOpenPlan,
    required this.onOpenOrders,
    required this.onOpenAccount,
  });

  Widget _metric({
    required IconData icon,
    required String value,
    required String label,
    required String note,
    required VoidCallback onTap,
    bool warning = false,
  }) {
    return Expanded(
      child: Material(
        color: const Color(0xFFF7FAF4),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 104),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: warning
                    ? const Color(0xFFE8C768).withOpacity(.55)
                    : const Color(0xFFDDE7DB),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: warning
                      ? const Color(0xFFAD7410)
                      : const Color(0xFF0B5B3D),
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 13.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  note,
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Business status',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Business account',
                visualDensity: VisualDensity.compact,
                onPressed: onOpenAccount,
                icon: const Icon(
                  Icons.lock_outline_rounded,
                  size: 17,
                  color: FarmColors.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              _metric(
                icon: Icons.event_note_outlined,
                value: '$activeNeeds',
                label: 'Demand',
                note: 'Next 30 days',
                onTap: onOpenPlan,
              ),
              const SizedBox(width: 8),
              _metric(
                icon: Icons.warning_amber_rounded,
                value: '$supplyGaps',
                label: 'Supply gaps',
                note: '$securedDemandLines secured',
                onTap: onOpenPlan,
                warning: supplyGaps > 0,
              ),
              const SizedBox(width: 8),
              _metric(
                icon: Icons.payments_outlined,
                value: formatJmd(spend30),
                label: 'Purchased',
                note: '$purchasedOrders30 orders',
                onTap: onOpenOrders,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            '$deliveriesToday due today • ${formatJmd(amountDue)} outstanding • 90d ${formatJmd(spend90)}',
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}



// =====================================================
// HPJ PHASE 87 — BUSINESS SOCIAL COMMERCE + AGRO NETWORK
// DESKTOP WEB ONLY
// =====================================================

class _EliteBusinessSocialCommerceHome extends StatelessWidget {
  final BusinessAccount account;
  final List<WholesaleDemandForecast> activeForecasts;
  final List<WholesaleDemandGapLine> gapLines;
  final List<WholesaleProduct> recommendedProducts;
  final List<Widget> attentionRows;
  final int activeNeeds;
  final int supplyGaps;
  final double amountDue;
  final int deliveriesToday;
  final double spend30;
  final double spend90;
  final bool hasLoadIssues;
  final Set<String> unavailableSections;
  final VoidCallback? onRetry;
  final VoidCallback onOpenShop;
  final VoidCallback onOpenPlan;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenDemandNetwork;
  final VoidCallback onFindSuppliers;

  const _EliteBusinessSocialCommerceHome({
    required this.account,
    required this.activeForecasts,
    required this.gapLines,
    required this.recommendedProducts,
    required this.attentionRows,
    required this.activeNeeds,
    required this.supplyGaps,
    required this.amountDue,
    required this.deliveriesToday,
    required this.spend30,
    required this.spend90,
    required this.hasLoadIssues,
    required this.unavailableSections,
    required this.onRetry,
    required this.onOpenShop,
    required this.onOpenPlan,
    required this.onOpenOrders,
    required this.onOpenAccount,
    required this.onOpenDemandNetwork,
    required this.onFindSuppliers,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final businessLine = <String>[
      if (account.businessType.trim().isNotEmpty) account.businessType.trim(),
      if (account.parish.trim().isNotEmpty) account.parish.trim(),
    ].join(' • ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EliteBusinessHero(
          greeting: _greeting,
          businessName: account.displayName,
          businessLine: businessLine,
          products: recommendedProducts,
          activeNeeds: activeNeeds,
          supplyGaps: supplyGaps,
          deliveriesToday: deliveriesToday,
          onOpenShop: onOpenShop,
          onOpenPlan: onOpenPlan,
          onOpenOrders: onOpenOrders,
          onFindSuppliers: onFindSuppliers,
        ),
        if (hasLoadIssues) ...[
          const SizedBox(height: 10),
          _EliteBusinessLoadWarning(
            unavailableSections: unavailableSections,
            onRetry: onRetry,
          ),
        ],
        const SizedBox(height: 12),
        _EliteBusinessKpiRow(
          activeNeeds: activeNeeds,
          supplyGaps: supplyGaps,
          amountDue: amountDue,
          deliveriesToday: deliveriesToday,
          onOpenPlan: onOpenPlan,
          onOpenOrders: onOpenOrders,
          onFindSuppliers: onFindSuppliers,
        ),
        const SizedBox(height: 12),
        _HpjBusinessDemandNetworkEntryCard(
          onTap: onOpenDemandNetwork,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final roomy = constraints.maxWidth >= 1000;

            final network = _EliteBusinessNetworkFeed(
              gaps: gapLines,
              forecasts: activeForecasts,
              onOpenPlan: onOpenPlan,
              onFindSuppliers: onFindSuppliers,
            );
            final recommendations = _EliteBusinessRecommendations(
              products: recommendedProducts,
              onOpenShop: onOpenShop,
            );
            final actions = _EliteBusinessActionsPanel(
              attentionRows: attentionRows,
              onOpenPlan: onOpenPlan,
              onOpenOrders: onOpenOrders,
              onOpenAccount: onOpenAccount,
              onFindSuppliers: onFindSuppliers,
            );
            final insights = _EliteBusinessInsightsPanel(
              forecasts: activeForecasts,
              spend30: spend30,
              spend90: spend90,
            );

            if (!roomy) {
              return Column(
                children: [
                  network,
                  const SizedBox(height: 12),
                  recommendations,
                  const SizedBox(height: 12),
                  actions,
                  const SizedBox(height: 12),
                  insights,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 31, child: network),
                const SizedBox(width: 12),
                Expanded(flex: 44, child: recommendations),
                const SizedBox(width: 12),
                Expanded(
                  flex: 25,
                  child: Column(
                    children: [
                      actions,
                      const SizedBox(height: 12),
                      insights,
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EliteBusinessHero extends StatelessWidget {
  final String greeting;
  final String businessName;
  final String businessLine;
  final List<WholesaleProduct> products;
  final int activeNeeds;
  final int supplyGaps;
  final int deliveriesToday;
  final VoidCallback onOpenShop;
  final VoidCallback onOpenPlan;
  final VoidCallback onOpenOrders;
  final VoidCallback onFindSuppliers;

  const _EliteBusinessHero({
    required this.greeting,
    required this.businessName,
    required this.businessLine,
    required this.products,
    required this.activeNeeds,
    required this.supplyGaps,
    required this.deliveriesToday,
    required this.onOpenShop,
    required this.onOpenPlan,
    required this.onOpenOrders,
    required this.onFindSuppliers,
  });

  @override
  Widget build(BuildContext context) {
    final heroProducts = products.take(3).toList(growable: false);

    return Container(
      height: 248,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF043726).withOpacity(.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF043827),
                  Color(0xFF0A6240),
                  Color(0xFF2D7C4B),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _EliteBusinessNetworkPatternPainter(),
            ),
          ),
          Positioned(
            right: -70,
            bottom: -95,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.055),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 24, 24, 22),
            child: Row(
              children: [
                Expanded(
                  flex: 62,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting, $businessName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          height: 1.02,
                          letterSpacing: -.45,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Source. Plan. Grow. Together.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1.05,
                          letterSpacing: -.35,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (businessLine.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Text(
                          businessLine,
                          style: TextStyle(
                            color: Colors.white.withOpacity(.76),
                            fontSize: 9.3,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 11),
                      SizedBox(
                        width: 610,
                        child: Text(
                          'Connect with Jamaican farmers, source fresh produce, '
                          'share future demand and grow your business through the HPJ agro network.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(.86),
                            fontSize: 11.2,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          _EliteBusinessHeroButton(
                            icon: Icons.shopping_cart_outlined,
                            label: 'Order Produce',
                            subtitle: 'Shop wholesale supply',
                            onTap: onOpenShop,
                            emphasized: true,
                          ),
                          const SizedBox(width: 9),
                          _EliteBusinessHeroButton(
                            icon: Icons.calendar_month_outlined,
                            label: 'Plan Ahead',
                            subtitle: 'Share future demand',
                            onTap: onOpenPlan,
                          ),
                          const SizedBox(width: 9),
                          _EliteBusinessHeroButton(
                            icon: Icons.local_shipping_outlined,
                            label: 'Track Orders',
                            subtitle: 'Follow fulfilment',
                            onTap: onOpenOrders,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 38,
                  child: _EliteBusinessHeroNetworkPanel(
                    products: heroProducts,
                    activeNeeds: activeNeeds,
                    supplyGaps: supplyGaps,
                    deliveriesToday: deliveriesToday,
                    onTap: onFindSuppliers,
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

class _EliteBusinessHeroButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool emphasized;

  const _EliteBusinessHeroButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = emphasized
        ? const Color(0xFFFFC42C)
        : Colors.white.withOpacity(.08);
    final fg = emphasized
        ? const Color(0xFF063D2A)
        : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 185,
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: emphasized
                ? null
                : Border.all(color: Colors.white.withOpacity(.24)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontSize: 10.4,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: emphasized
                            ? fg.withOpacity(.72)
                            : Colors.white.withOpacity(.68),
                        fontSize: 7.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: fg,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EliteBusinessHeroNetworkPanel extends StatelessWidget {
  final List<WholesaleProduct> products;
  final int activeNeeds;
  final int supplyGaps;
  final int deliveriesToday;
  final VoidCallback onTap;

  const _EliteBusinessHeroNetworkPanel({
    required this.products,
    required this.activeNeeds,
    required this.supplyGaps,
    required this.deliveriesToday,
    required this.onTap,
  });

  Widget _thumb(WholesaleProduct item) {
    final url = item.product.imageUrl?.trim() ?? '';

    return Container(
      width: 58,
      height: 58,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.20)),
      ),
      child: url.isEmpty
          ? const Icon(
              Icons.eco_outlined,
              color: Colors.white,
              size: 24,
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.eco_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(.14),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(.17),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.hub_outlined,
                    color: Color(0xFFFFC42C),
                    size: 18,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'JAMAICA’S AGRO NETWORK',
                    style: TextStyle(
                      color: Color(0xFFFFD85A),
                      fontSize: 7.6,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              const Text(
                'More farms.\nMore opportunities.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.3,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'A stronger food system for Jamaica.',
                style: TextStyle(
                  color: Colors.white.withOpacity(.74),
                  fontSize: 9.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (products.isNotEmpty)
                Row(
                  children: [
                    for (final item in products) ...[
                      _thumb(item),
                      const SizedBox(width: 7),
                    ],
                  ],
                )
              else
                Row(
                  children: [
                    _EliteNetworkMiniMetric(
                      value: '$activeNeeds',
                      label: 'needs',
                    ),
                    const SizedBox(width: 7),
                    _EliteNetworkMiniMetric(
                      value: '$supplyGaps',
                      label: 'gaps',
                    ),
                    const SizedBox(width: 7),
                    _EliteNetworkMiniMetric(
                      value: '$deliveriesToday',
                      label: 'today',
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Explore verified Jamaican suppliers',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.82),
                      fontSize: 8.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EliteNetworkMiniMetric extends StatelessWidget {
  final String value;
  final String label;

  const _EliteNetworkMiniMetric({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.08),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(.62),
                fontSize: 7.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EliteBusinessNetworkPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(.055)
      ..strokeWidth = 1.2;

    final nodePaint = Paint()
      ..color = const Color(0xFFFFC42C).withOpacity(.16);

    final points = <Offset>[
      Offset(size.width * .58, size.height * .22),
      Offset(size.width * .69, size.height * .14),
      Offset(size.width * .79, size.height * .30),
      Offset(size.width * .88, size.height * .18),
      Offset(size.width * .70, size.height * .52),
      Offset(size.width * .84, size.height * .57),
      Offset(size.width * .94, size.height * .43),
      Offset(size.width * .76, size.height * .78),
      Offset(size.width * .91, size.height * .80),
    ];

    final links = <List<int>>[
      [0, 1],
      [0, 4],
      [1, 2],
      [2, 3],
      [2, 5],
      [4, 5],
      [5, 6],
      [4, 7],
      [5, 8],
      [7, 8],
      [6, 8],
    ];

    for (final link in links) {
      canvas.drawLine(
        points[link[0]],
        points[link[1]],
        linePaint,
      );
    }

    for (final point in points) {
      canvas.drawCircle(point, 3.2, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EliteBusinessKpiRow extends StatelessWidget {
  final int activeNeeds;
  final int supplyGaps;
  final double amountDue;
  final int deliveriesToday;
  final VoidCallback onOpenPlan;
  final VoidCallback onOpenOrders;
  final VoidCallback onFindSuppliers;

  const _EliteBusinessKpiRow({
    required this.activeNeeds,
    required this.supplyGaps,
    required this.amountDue,
    required this.deliveriesToday,
    required this.onOpenPlan,
    required this.onOpenOrders,
    required this.onFindSuppliers,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _EliteBusinessKpiCard(
            icon: Icons.inventory_2_outlined,
            value: '$activeNeeds',
            label: 'Active needs',
            note: 'Your demand plan',
            onTap: onOpenPlan,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _EliteBusinessKpiCard(
            icon: Icons.warning_amber_rounded,
            value: '$supplyGaps',
            label: 'Supply gaps',
            note: supplyGaps > 0 ? 'Needs attention' : 'Fully covered',
            warning: supplyGaps > 0,
            onTap: onOpenPlan,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _EliteBusinessKpiCard(
            icon: Icons.account_balance_wallet_outlined,
            value: formatJmd(amountDue),
            label: 'Amount due',
            note: amountDue > 0 ? 'Review invoices' : 'No balance due',
            onTap: onOpenOrders,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _EliteBusinessKpiCard(
            icon: Icons.local_shipping_outlined,
            value: '$deliveriesToday',
            label: 'Deliveries today',
            note: deliveriesToday > 0 ? 'Track fulfilment' : 'Nothing scheduled',
            onTap: onOpenOrders,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onFindSuppliers,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 96,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFEAF5E7),
                      Color(0xFFF5F9F2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFD4E5D1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_outlined,
                        color: Color(0xFF0B6B43),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verified farms',
                            style: TextStyle(
                              color: Color(0xFF153D2B),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Discover • Connect • Source',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF66736B),
                              fontSize: 8.1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 17,
                      color: Color(0xFF0B6B43),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EliteBusinessKpiCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String note;
  final bool warning;
  final VoidCallback onTap;

  const _EliteBusinessKpiCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.note,
    required this.onTap,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        warning ? const Color(0xFFD59A00) : const Color(0xFF0A6B43);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 96,
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: warning
                  ? const Color(0xFFE9CE81)
                  : const Color(0xFFDDE7DB),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.025),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF14251D),
                        fontSize: 15,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF334A3D),
                        fontSize: 8.9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF718078),
                        fontSize: 7.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EliteBusinessNetworkFeed extends StatelessWidget {
  final List<WholesaleDemandGapLine> gaps;
  final List<WholesaleDemandForecast> forecasts;
  final VoidCallback onOpenPlan;
  final VoidCallback onFindSuppliers;

  const _EliteBusinessNetworkFeed({
    required this.gaps,
    required this.forecasts,
    required this.onOpenPlan,
    required this.onFindSuppliers,
  });

  String _qty(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final signals = gaps.take(3).toList(growable: false);

    return _EliteBusinessSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ElitePanelHeader(
            title: 'From the HPJ Network',
            subtitle: 'Live supply and demand signals across Jamaica.',
            action: 'Explore',
            onAction: onFindSuppliers,
          ),
          const SizedBox(height: 10),
          if (signals.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F8F1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF13834E),
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Current visible demand is covered. Keep your plan updated to stay connected to new supply opportunities.',
                      style: TextStyle(
                        color: Color(0xFF526258),
                        fontSize: 8.9,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < signals.length; i++) ...[
              _EliteNetworkSignalRow(
                gap: signals[i],
                onTap: onOpenPlan,
              ),
              if (i != signals.length - 1)
                const Divider(
                  height: 15,
                  color: Color(0xFFE5ECE3),
                ),
            ],
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onFindSuppliers,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4E7),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.groups_2_outlined,
                      size: 18,
                      color: Color(0xFF0B6B43),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Connect with verified Jamaican farmers',
                        style: TextStyle(
                          color: Color(0xFF153D2B),
                          fontSize: 8.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Color(0xFF0B6B43),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EliteNetworkSignalRow extends StatelessWidget {
  final WholesaleDemandGapLine gap;
  final VoidCallback onTap;

  const _EliteNetworkSignalRow({
    required this.gap,
    required this.onTap,
  });

  String _qty(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F7EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hub_outlined,
                size: 18,
                color: Color(0xFF0B6B43),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${gap.productName} needs supply',
                    style: const TextStyle(
                      color: Color(0xFF14251D),
                      fontSize: 9.4,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_qty(gap.gapQuantity)} ${gap.unit} still needed • '
                    'Need by ${_wholesaleSimpleDate(gap.needByDate)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF69776F),
                      fontSize: 8.0,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF758079),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _EliteBusinessRecommendations extends StatelessWidget {
  final List<WholesaleProduct> products;
  final VoidCallback onOpenShop;

  const _EliteBusinessRecommendations({
    required this.products,
    required this.onOpenShop,
  });

  @override
  Widget build(BuildContext context) {
    final picks = products.take(4).toList(growable: false);

    return _EliteBusinessSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ElitePanelHeader(
            title: 'Recommended for Your Business',
            subtitle: 'Fresh supply available through HPJ.',
            action: 'View all',
            onAction: onOpenShop,
          ),
          const SizedBox(height: 10),
          if (picks.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F8F1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Wholesale recommendations will appear as fresh supply becomes available.',
                style: TextStyle(
                  color: Color(0xFF66736B),
                  fontSize: 8.7,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 8.0;
                final cardWidth =
                    (constraints.maxWidth - gap * (picks.length - 1)) /
                        picks.length;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < picks.length; i++) ...[
                      SizedBox(
                        width: cardWidth,
                        child: _EliteBusinessProductCard(
                          item: picks[i],
                          onTap: onOpenShop,
                        ),
                      ),
                      if (i != picks.length - 1)
                        const SizedBox(width: gap),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _EliteBusinessProductCard extends StatelessWidget {
  final WholesaleProduct item;
  final VoidCallback onTap;

  const _EliteBusinessProductCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final url = item.product.imageUrl?.trim() ?? '';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE0E8DE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 102,
            width: double.infinity,
            child: url.isEmpty
                ? Container(
                    color: const Color(0xFFF2F6EF),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.eco_outlined,
                      color: Color(0xFF0B6B43),
                      size: 28,
                    ),
                  )
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF2F6EF),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.eco_outlined,
                        color: Color(0xFF0B6B43),
                        size: 28,
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 9, 9, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF14251D),
                    fontSize: 9.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.formattedWholesalePrice} / ${item.wholesaleUnit}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0B6B43),
                    fontSize: 8.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Min ${item.minimumQuantity} ${item.wholesaleUnit}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF758079),
                    fontSize: 7.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0B6B43),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 7.7,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    child: const Text('Order'),
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

class _EliteBusinessActionsPanel extends StatelessWidget {
  final List<Widget> attentionRows;
  final VoidCallback onOpenPlan;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenAccount;
  final VoidCallback onFindSuppliers;

  const _EliteBusinessActionsPanel({
    required this.attentionRows,
    required this.onOpenPlan,
    required this.onOpenOrders,
    required this.onOpenAccount,
    required this.onFindSuppliers,
  });

  @override
  Widget build(BuildContext context) {
    final visibleAttention = attentionRows.take(2).toList(growable: false);

    return _EliteBusinessSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ElitePanelHeader(
            title: 'Your Actions',
            subtitle: 'Keep your business moving.',
          ),
          const SizedBox(height: 9),
          if (visibleAttention.isNotEmpty) ...[
            for (var i = 0; i < visibleAttention.length; i++) ...[
              visibleAttention[i],
              if (i != visibleAttention.length - 1)
                const SizedBox(height: 6),
            ],
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFE5ECE3)),
            const SizedBox(height: 7),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7ED),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 17,
                    color: Color(0xFF128049),
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'You are up to date.',
                      style: TextStyle(
                        color: Color(0xFF234A34),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          _EliteActionLink(
            icon: Icons.event_note_outlined,
            label: 'Update your demand plan',
            onTap: onOpenPlan,
          ),
          _EliteActionLink(
            icon: Icons.groups_2_outlined,
            label: 'Explore verified suppliers',
            onTap: onFindSuppliers,
          ),
          _EliteActionLink(
            icon: Icons.local_shipping_outlined,
            label: 'Track current orders',
            onTap: onOpenOrders,
          ),
          _EliteActionLink(
            icon: Icons.business_outlined,
            label: 'Review business account',
            onTap: onOpenAccount,
          ),
        ],
      ),
    );
  }
}

class _EliteActionLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _EliteActionLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 2,
          vertical: 7,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F6ED),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 15,
                color: const Color(0xFF0B6B43),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF344A3D),
                  fontSize: 8.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF758079),
              size: 17,
            ),
          ],
        ),
      ),
    );
  }
}

class _EliteBusinessInsightsPanel extends StatelessWidget {
  final List<WholesaleDemandForecast> forecasts;
  final double spend30;
  final double spend90;

  const _EliteBusinessInsightsPanel({
    required this.forecasts,
    required this.spend30,
    required this.spend90,
  });

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};

    for (final item in forecasts) {
      final category = (item.category ?? '').trim();
      final label = category.isEmpty ? 'Other' : category;
      counts[label] = (counts[label] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = counts.values.fold<int>(0, (sum, value) => sum + value);
    final top = sorted.take(4).toList(growable: false);

    return _EliteBusinessSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ElitePanelHeader(
            title: 'Business Insights',
            subtitle: 'Current demand-plan mix.',
          ),
          const SizedBox(height: 10),
          if (top.isEmpty)
            const Text(
              'Add future requirements to unlock category insights.',
              style: TextStyle(
                color: Color(0xFF66736B),
                fontSize: 8.4,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            for (final entry in top) ...[
              _EliteInsightBar(
                label: entry.key,
                fraction: total == 0 ? 0 : entry.value / total,
              ),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 3),
          const Divider(height: 1, color: Color(0xFFE5ECE3)),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _EliteSmallInsight(
                  label: '30d purchases',
                  value: formatJmd(spend30),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EliteSmallInsight(
                  label: '90d purchases',
                  value: formatJmd(spend90),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EliteInsightBar extends StatelessWidget {
  final String label;
  final double fraction;

  const _EliteInsightBar({
    required this.label,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (fraction * 100).round();

    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF435449),
              fontSize: 7.7,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: const Color(0xFFE8EEE6),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF0B6B43),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 30,
          child: Text(
            '$percentage%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF56665D),
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _EliteSmallInsight extends StatelessWidget {
  final String label;
  final String value;

  const _EliteSmallInsight({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF173A29),
              fontSize: 9.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF758079),
              fontSize: 6.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EliteBusinessAgroNetworkBanner extends StatelessWidget {
  final int activeNeeds;
  final int supplyGaps;
  final VoidCallback onExplore;

  const _EliteBusinessAgroNetworkBanner({
    required this.activeNeeds,
    required this.supplyGaps,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF06402D),
            Color(0xFF087247),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -25,
            bottom: -45,
            child: Icon(
              Icons.hub_outlined,
              size: 190,
              color: Colors.white.withOpacity(.06),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 18, 17),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jamaica’s\nAgro Network',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          height: 1.02,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.3,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'More farms. More opportunities.\nA stronger Jamaica.',
                        style: TextStyle(
                          color: Color(0xFFD7E8D9),
                          fontSize: 8.7,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        _EliteAgroStat(
                          value: '$activeNeeds',
                          label: 'active needs',
                        ),
                        const SizedBox(width: 7),
                        _EliteAgroStat(
                          value: '$supplyGaps',
                          label: 'supply gaps',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 166,
                      height: 35,
                      child: FilledButton.icon(
                        onPressed: onExplore,
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                        ),
                        label: const Text('Explore Network'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF06402D),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 8.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
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

class _EliteAgroStat extends StatelessWidget {
  final String value;
  final String label;

  const _EliteAgroStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.09),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: Colors.white.withOpacity(.12),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(.68),
              fontSize: 6.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EliteBusinessSurface extends StatelessWidget {
  final Widget child;

  const _EliteBusinessSurface({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDDE7DB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ElitePanelHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onAction;

  const _ElitePanelHeader({
    required this.title,
    required this.subtitle,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF14251D),
                  fontSize: 12.1,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF6C7971),
                  fontSize: 7.9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (action != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0B6B43),
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 5,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 7.6,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: Text(action!),
          ),
      ],
    );
  }
}

class _EliteBusinessLoadWarning extends StatelessWidget {
  final Set<String> unavailableSections;
  final VoidCallback? onRetry;

  const _EliteBusinessLoadWarning({
    required this.unavailableSections,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD59A00).withOpacity(.28),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFD59A00),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Some Business Home data is temporarily unavailable'
              '${unavailableSections.isEmpty ? '.' : ': ${unavailableSections.join(', ')}.'}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF4C4430),
                fontSize: 8.6,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Refresh'),
            ),
        ],
      ),
    );
  }
}



// =====================================================
// HPJ PHASE 044D — WHOLESALE SECONDARY INTELLIGENCE
// =====================================================

class _WholesaleMarketIntelligenceCard extends StatefulWidget {
  final List<WholesaleProduct> dailyPicks;
  final List<WholesaleDemandForecast> activeForecasts;
  final List<WholesaleDemandGapLine> gapLines;
  final VoidCallback onOpenShop;
  final VoidCallback onOpenPlan;
  final Future<void> Function(AgricultureFeedUpdate) onAgricultureAction;

  const _WholesaleMarketIntelligenceCard({
    required this.dailyPicks,
    required this.activeForecasts,
    required this.gapLines,
    required this.onOpenShop,
    required this.onOpenPlan,
    required this.onAgricultureAction,
  });

  @override
  State<_WholesaleMarketIntelligenceCard> createState() =>
      _WholesaleMarketIntelligenceCardState();
}

class _WholesaleMarketIntelligenceCardState
    extends State<_WholesaleMarketIntelligenceCard> {
  bool expanded = false;

  String _qty(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final topGaps = widget.gapLines.take(2).toList(growable: false);
    final showMarketIntelligence =
        hpjCurrentUserExperiencePreferences.showAgricultureNews;

    return FarmCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(HpjMvpUi.cardRadius),
              onTap: () => setState(() => expanded = !expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: FarmColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.insights_outlined,
                        size: 20,
                        color: FarmColors.primary,
                      ),
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Market intelligence',
                            style: TextStyle(
                              color: FarmColors.ink,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Fresh supply, demand gaps, reels and updates',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 9.8,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: expanded ? .5 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: const Icon(
                        Icons.expand_more_rounded,
                        color: FarmColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (topGaps.isNotEmpty) ...[
                    const SectionHeader(
                      title: 'Supply gaps',
                      subtitle: 'Requirements HPJ is still working to secure.',
                    ),
                    const SizedBox(height: 7),
                    for (final gap in topGaps)
                      HpjMvpListRow(
                        icon: Icons.warning_amber_rounded,
                        title: gap.productName,
                        subtitle:
                            'Still Needed • ${_qty(gap.gapQuantity)} ${gap.unit} • '
                            '${_qty(gap.securedQuantity)} secured of '
                            '${_qty(gap.requiredQuantity)} required',
                        iconColor: FarmColors.warning,
                        onTap: widget.onOpenPlan,
                      ),
                    const SizedBox(height: 8),
                  ],
                  if (showMarketIntelligence &&
                      widget.dailyPicks.isNotEmpty) ...[
                    _WholesaleDailyFeed(
                      products: widget.dailyPicks,
                      onOpenShop: widget.onOpenShop,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (showMarketIntelligence &&
                      hpjCurrentUserExperiencePreferences.showFreshReels) ...[
                    FreshReelFeedPreviewCard(
                      preferences: hpjCurrentUserExperiencePreferences,
                      audience: 'wholesale',
                      placement: freshReelPlacementWholesaleFeed,
                      refreshKey: 0,
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (showMarketIntelligence)
                    HpjJamaicaMarketPulseSection(
                      audience: 'wholesale',
                      limit: 4,
                      socialStyle: true,
                      preferredCropNames: widget.activeForecasts
                          .map((item) => item.productName)
                          .toList(growable: false),
                      onPrimaryAction: (insight) async {
                        insight.hasShortage
                            ? widget.onOpenPlan()
                            : widget.onOpenShop();
                      },
                    )
                  else
                    const HpjMvpListRow(
                      icon: Icons.visibility_off_outlined,
                      title: 'Market intelligence hidden',
                      subtitle: 'Turn it on from Account → Settings.',
                      iconColor: FarmColors.mutedText,
                    ),
                  if (showMarketIntelligence) ...[
                    const SizedBox(height: 14),
                    HpjAgricultureUpdatesSection(
                      audience: 'wholesale',
                      workspace: 'wholesale',
                      limit: 1,
                      socialStyle: true,
                      title: 'Agriculture update',
                      subtitle: 'One relevant update for your business.',
                      onAction: widget.onAgricultureAction,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}


class _WholesaleBusinessSnapshotCard extends StatelessWidget {
  final String businessName;
  final int demandLineCount;
  final int securedLineCount;
  final int gapLineCount;
  final int purchasedOrders30;
  final double spend30;
  final double spend90;
  final int deliveriesToday;
  final List<WholesaleDemandGapLine> gapLines;
  final Set<String> unavailableSections;
  final VoidCallback onOpenPlan;
  final VoidCallback onOpenOrders;

  const _WholesaleBusinessSnapshotCard({
    required this.businessName,
    required this.demandLineCount,
    required this.securedLineCount,
    required this.gapLineCount,
    required this.purchasedOrders30,
    required this.spend30,
    required this.spend90,
    required this.deliveriesToday,
    required this.gapLines,
    this.unavailableSections = const <String>{},
    required this.onOpenPlan,
    required this.onOpenOrders,
  });

  @override
  Widget build(BuildContext context) {
    final demandUnavailable =
        unavailableSections.contains('Planning') ||
        unavailableSections.contains('Demand insight');

    final invoicesUnavailable =
        unavailableSections.contains('Invoices');

    final trackingUnavailable =
        unavailableSections.contains('Tracking');

    final footer = <String>[
      if (!demandUnavailable)
        '$securedLineCount secured',
      if (!trackingUnavailable && deliveriesToday > 0)
        '$deliveriesToday ${deliveriesToday == 1 ? 'delivery' : 'deliveries'} today',
      if (!invoicesUnavailable)
        '${purchasedOrders30} invoice${purchasedOrders30 == 1 ? '' : 's'}',
      if (!invoicesUnavailable)
        '90d ${formatJmd(spend90)}',
    ];

    if (footer.isEmpty) {
      footer.add(
        'Live status is temporarily incomplete',
      );
    }

    return FarmCard(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Business status',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.lock_outline_rounded,
                size: 15,
                color: FarmColors.mutedText.withOpacity(.75),
              ),
            ],
          ),
          const SizedBox(height: 11),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth < 310;
              final itemWidth = twoColumns
                  ? (constraints.maxWidth - 8) / 2
                  : (constraints.maxWidth - 16) / 3;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _WholesaleBusinessMetric(
                      label: 'Demand',
                      value: demandUnavailable
                          ? '—'
                          : '$demandLineCount',
                      note: demandUnavailable
                          ? 'Unavailable'
                          : 'Next 30 days',
                      onTap: onOpenPlan,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _WholesaleBusinessMetric(
                      label: 'Supply gaps',
                      value: demandUnavailable
                          ? '—'
                          : '$gapLineCount',
                      note: demandUnavailable
                          ? 'Unavailable'
                          : gapLineCount == 0
                              ? 'Covered'
                              : 'Need attention',
                      warning:
                          !demandUnavailable && gapLineCount > 0,
                      onTap: onOpenPlan,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _WholesaleBusinessMetric(
                      label: 'Purchased',
                      value: invoicesUnavailable
                          ? '—'
                          : formatJmd(spend30),
                      note: invoicesUnavailable
                          ? 'Unavailable'
                          : 'Last 30 days',
                      onTap: onOpenOrders,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 9),
          Text(
            footer.join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 9.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}



class _WholesaleBusinessMetric extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  final bool warning;
  final VoidCallback onTap;

  const _WholesaleBusinessMetric({
    required this.label,
    required this.value,
    required this.note,
    this.warning = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = warning ? FarmColors.warning : FarmColors.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
        decoration: BoxDecoration(
          color: FarmColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FarmColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.ink,
                fontSize: 9.6,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 8.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _HpjBusinessMobileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool emphasized;

  const _HpjBusinessMobileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF0B5B3D);

    return Material(
      color: emphasized ? forest : const Color(0xFFFFFEFB),
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          constraints: const BoxConstraints(minHeight: 116),
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: emphasized
                  ? Colors.white.withOpacity(.10)
                  : const Color(0xFFDDE6DA),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(emphasized ? .06 : .022),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 37,
                    height: 37,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: emphasized
                          ? Colors.white.withOpacity(.13)
                          : const Color(0xFFEDF6E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: emphasized ? Colors.white : forest,
                      size: 19,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: emphasized
                        ? Colors.white70
                        : const Color(0xFF7B887E),
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: emphasized ? Colors.white : FarmColors.ink,
                  fontSize: 11.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: emphasized
                      ? Colors.white.withOpacity(.73)
                      : FarmColors.mutedText,
                  fontSize: 10.5,
                  height: 1.28,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WholesaleHomeQuickActions extends StatelessWidget {
  final VoidCallback onOrderNow;
  final VoidCallback onPlanAhead;
  final VoidCallback onFindSuppliers;
  final VoidCallback onTrackOrders;

  const _WholesaleHomeQuickActions({
    required this.onOrderNow,
    required this.onPlanAhead,
    required this.onFindSuppliers,
    required this.onTrackOrders,
  });

  @override
  Widget build(BuildContext context) {
    final desktopWeb =
        kIsWeb && MediaQuery.sizeOf(context).width >= 1100;

    if (hpjUseMobileAppPresentation(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Run your purchasing',
            subtitle: 'The four actions your business will use most.',
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 8.0;
              final width = (constraints.maxWidth - gap) / 2;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: width,
                    child: _HpjBusinessMobileActionTile(
                      icon: Icons.shopping_basket_outlined,
                      title: 'Source Produce',
                      subtitle: 'Order from current HPJ supply.',
                      emphasized: true,
                      onTap: onOrderNow,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _HpjBusinessMobileActionTile(
                      icon: Icons.event_note_outlined,
                      title: 'Plan Ahead',
                      subtitle: 'Share future demand early.',
                      onTap: onPlanAhead,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _HpjBusinessMobileActionTile(
                      icon: Icons.handshake_outlined,
                      title: 'Suppliers',
                      subtitle: 'Preferred & repeat farm links.',
                      onTap: onFindSuppliers,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _HpjBusinessMobileActionTile(
                      icon: Icons.local_shipping_outlined,
                      title: 'Orders',
                      subtitle: 'Track, receive and buy again.',
                      onTap: onTrackOrders,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      );
    }

    final actions = <Widget>[
      _PremiumBusinessHomeAction(
        icon: Icons.shopping_cart_outlined,
        title: 'Order Produce',
        subtitle: 'Shop fresh HPJ wholesale supply',
        emphasized: true,
        onTap: onOrderNow,
      ),
      _PremiumBusinessHomeAction(
        icon: Icons.event_note_outlined,
        title: 'Plan Ahead',
        subtitle: 'Tell HPJ what you will need next',
        onTap: onPlanAhead,
      ),
      _PremiumBusinessHomeAction(
        icon: Icons.agriculture_outlined,
        title: 'Find Suppliers',
        subtitle: 'Explore approved Jamaican farms',
        onTap: onFindSuppliers,
      ),
      _PremiumBusinessHomeAction(
        icon: Icons.local_shipping_outlined,
        title: 'Track Orders',
        subtitle: 'Follow orders, delivery and receipt',
        onTap: onTrackOrders,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Run your purchasing',
          subtitle:
              'Order now, plan future needs, find farms or follow deliveries.',
        ),
        SizedBox(height: desktopWeb ? 12 : 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final useFourColumns =
                desktopWeb && constraints.maxWidth >= 980;
            final columns = useFourColumns ? 4 : 2;
            const spacing = 10.0;
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: actions
                  .map(
                    (item) => SizedBox(
                      width: width,
                      child: item,
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _PremiumBusinessHomeAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool emphasized;

  const _PremiumBusinessHomeAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final background =
        emphasized ? FarmColors.deepGreen : FarmColors.card;
    final foreground =
        emphasized ? Colors.white : FarmColors.deepGreen;
    final subtitleColor = emphasized
        ? Colors.white.withOpacity(.76)
        : FarmColors.mutedText;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: emphasized
                  ? Colors.white.withOpacity(.10)
                  : FarmColors.line,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  emphasized ? .07 : .025,
                ),
                blurRadius: emphasized ? 18 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: emphasized
                          ? Colors.white.withOpacity(.13)
                          : FarmColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: foreground,
                      size: 19,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: emphasized
                        ? Colors.white70
                        : FarmColors.mutedText,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 9.1,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _WholesaleHomeActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _WholesaleHomeActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FarmColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 92,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: FarmColors.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 23,
                color: FarmColors.primary,
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: FarmColors.ink,
                  fontSize: 9.8,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WholesaleHomeSectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _WholesaleHomeSectionHeading({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: FarmColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 10.5,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _WholesaleSocialFeedFilters extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _WholesaleSocialFeedFilters({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const filters = <(String, IconData)>[
      ('For You', Icons.home_rounded),
      ('Market', Icons.query_stats_rounded),
      ('News', Icons.newspaper_rounded),
      ('Orders', Icons.local_shipping_outlined),
      ('Alerts', Icons.notifications_none_rounded),
    ];

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = filters[index];
                final active = selected == item.$1;
                return ChoiceChip(
                  selected: active,
                  onSelected: (_) => onSelected(item.$1),
                  avatar: Icon(
                    item.$2,
                    size: 15,
                    color: active ? Colors.white : FarmColors.primary,
                  ),
                  label: Text(item.$1),
                  labelStyle: TextStyle(
                    color: active ? Colors.white : FarmColors.ink,
                    fontSize: 11.2,
                    fontWeight: FontWeight.w800,
                  ),
                  selectedColor: FarmColors.primary,
                  backgroundColor: FarmColors.card,
                  side: BorderSide(
                    color: active ? FarmColors.primary : FarmColors.line,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  showCheckmark: false,
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        const FarmNotificationButton(size: 38),
      ],
    );
  }
}

class _WholesaleSocialEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _WholesaleSocialEmptyState({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FarmColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FarmColors.line),
      ),
      child: Row(
        children: [
          Icon(icon, color: FarmColors.primary, size: 23),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 11.5,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WholesaleFeedStories extends StatelessWidget {
  final WholesaleProduct? firstPick;
  final int freshCount;
  final int openOrderCount;
  final int planCount;
  final int paymentCount;
  final VoidCallback onOpenFresh;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenPlans;
  final VoidCallback onOpenPayments;

  const _WholesaleFeedStories({
    required this.firstPick,
    required this.freshCount,
    required this.openOrderCount,
    required this.planCount,
    required this.paymentCount,
    required this.onOpenFresh,
    required this.onOpenOrders,
    required this.onOpenPlans,
    required this.onOpenPayments,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick updates',
          style: TextStyle(
            color: FarmColors.ink,
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _WholesaleFeedStory(
                label: 'Fresh',
                count: freshCount,
                product: firstPick,
                icon: Icons.eco_rounded,
                onTap: onOpenFresh,
              ),
              const SizedBox(width: 13),
              _WholesaleFeedStory(
                label: 'Orders',
                count: openOrderCount,
                icon: Icons.local_shipping_rounded,
                onTap: onOpenOrders,
              ),
              const SizedBox(width: 13),
              _WholesaleFeedStory(
                label: 'Plans',
                count: planCount,
                icon: Icons.event_note_rounded,
                onTap: onOpenPlans,
              ),
              const SizedBox(width: 13),
              _WholesaleFeedStory(
                label: 'Payments',
                count: paymentCount,
                icon: Icons.receipt_long_rounded,
                onTap: onOpenPayments,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WholesaleFeedStory extends StatelessWidget {
  final String label;
  final int count;
  final WholesaleProduct? product;
  final IconData icon;
  final VoidCallback onTap;

  const _WholesaleFeedStory({
    required this.label,
    required this.count,
    this.product,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUpdate = count > 0;

    return SizedBox(
      width: 72,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasUpdate ? FarmColors.primary : FarmColors.line,
                      width: hasUpdate ? 2.4 : 1.4,
                    ),
                  ),
                  child: ClipOval(
                    child: product != null
                        ? HpjProductThumb(
                            productId: product!.product.id,
                            productName: product!.product.name,
                            size: 54,
                            radius: 27,
                          )
                        : Container(
                            color: FarmColors.primarySoft,
                            alignment: Alignment.center,
                            child: Icon(
                              icon,
                              color: FarmColors.primary,
                              size: 25,
                            ),
                          ),
                  ),
                ),
                if (hasUpdate)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: FarmColors.primary,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: FarmColors.card, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: FarmColors.ink,
                fontSize: 11.1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WholesaleFeedHeader extends StatelessWidget {
  final int count;
  final DateTime date;

  const _WholesaleFeedHeader({
    required this.count,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: FarmColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.dynamic_feed_rounded,
                color: FarmColors.primary,
                size: 19,
              ),
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: Text(
                "Today's feed",
                style: TextStyle(
                  color: FarmColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const FarmNotificationButton(size: 36),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          count == 0
              ? '${_wholesaleSimpleDate(date)} • You are caught up'
              : '${_wholesaleSimpleDate(date)} • $count useful update${count == 1 ? '' : 's'}',
          style: const TextStyle(
            color: FarmColors.mutedText,
            fontSize: 12.2,
            height: 1.3,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Pull down to refresh orders, plans, payments and fresh catalogue picks.',
          style: TextStyle(
            color: FarmColors.mutedText,
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _WholesaleFeedSectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _WholesaleFeedSectionLabel({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: FarmColors.primary, size: 17),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: FarmColors.ink,
            fontSize: 13.2,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _WholesaleFeedAllClearCard extends StatelessWidget {
  const _WholesaleFeedAllClearCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4EC),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFDCE4D8)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: FarmColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'You are caught up. New order, planning and catalogue updates will appear here.',
              style: TextStyle(
                color: Color(0xFF5F6D65),
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<WholesaleProduct> _wholesaleSmartCataloguePicks({
  required List<WholesaleProduct> catalogue,
  required List<WholesaleDemandForecast> forecasts,
  required List<WholesaleOrderRequest> requests,
  required DateTime day,
}) {
  if (catalogue.isEmpty) return const <WholesaleProduct>[];

  final productScores = <String, int>{};
  final today = DateTime(day.year, day.month, day.day);

  for (final forecast in forecasts.where((item) => item.isActive)) {
    final key = hpjSmartNormalizeSearch(forecast.productName);
    if (key.isEmpty) continue;
    var score = 3500;
    final days = forecast.needByDate.difference(today).inDays;
    if (days <= 7) score += 2500;
    if (days <= 3) score += 1800;
    productScores[key] = (productScores[key] ?? 0) + score;
  }

  for (final request in requests) {
    final ageDays = request.createdAt == null
        ? 999
        : today.difference(request.createdAt!).inDays.abs();
    final recency = ageDays <= 30 ? 1200 : ageDays <= 90 ? 700 : 300;
    for (final line in request.items) {
      final key = hpjSmartNormalizeSearch(line.productName);
      if (key.isEmpty) continue;
      productScores[key] = (productScores[key] ?? 0) + recency;
    }
  }

  final dayOfYear = day.difference(DateTime(day.year, 1, 1)).inDays;
  final ranked = List<WholesaleProduct>.from(catalogue)
    ..sort((a, b) {
      int score(WholesaleProduct item) {
        final key = hpjSmartNormalizeSearch(item.product.name);
        var value = productScores[key] ?? 0;
        if (item.canOrder) value += 400;
        if (item.product.hasActiveDiscount) value += 160;
        if (item.product.isLocal) value += 80;
        // Stable daily movement for ties so the feed still feels fresh.
        final seed = item.product.id.hashCode.abs() + dayOfYear;
        value += seed % 97;
        return value;
      }

      final compare = score(b).compareTo(score(a));
      if (compare != 0) return compare;
      return a.product.name.toLowerCase().compareTo(
            b.product.name.toLowerCase(),
          );
    });

  final count = ranked.length < 3 ? ranked.length : 3;
  return ranked.take(count).toList(growable: false);
}


class _WholesaleDailyFeed extends StatelessWidget {
  final List<WholesaleProduct> products;
  final VoidCallback onOpenShop;

  const _WholesaleDailyFeed({
    required this.products,
    required this.onOpenShop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: FarmColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: FarmColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: Text(
                'Fresh Supply',
                style: TextStyle(
                  color: FarmColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: onOpenShop,
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Wholesale products available now.',
          style: TextStyle(
            color: FarmColors.mutedText,
            fontSize: 11.3,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 232,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = products[index];
              return _WholesaleDailyPickCard(
                item: item,
                onTap: onOpenShop,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WholesaleDailyPickCard extends StatefulWidget {
  final WholesaleProduct item;
  final VoidCallback onTap;

  const _WholesaleDailyPickCard({
    required this.item,
    required this.onTap,
  });

  @override
  State<_WholesaleDailyPickCard> createState() => _WholesaleDailyPickCardState();
}

class _WholesaleDailyPickCardState extends State<_WholesaleDailyPickCard> {
  bool seen = true;

  String get feedKey {
    final now = DateTime.now();
    final date = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'fresh:${widget.item.product.id}:$date';
  }

  @override
  void initState() {
    super.initState();
    _loadSeen();
  }

  @override
  void didUpdateWidget(covariant _WholesaleDailyPickCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.product.id != widget.item.product.id) {
      _loadSeen();
    }
  }

  Future<void> _loadSeen() async {
    final value = await isHpjFeedItemSeen(
      workspace: 'wholesale',
      itemKey: feedKey,
    );
    if (mounted) setState(() => seen = value);
  }

  Future<void> _open() async {
    if (!seen && mounted) setState(() => seen = true);
    await markHpjFeedItemSeen(
      workspace: 'wholesale',
      itemKey: feedKey,
    );
    if (!mounted) return;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return SizedBox(
      width: 148,
      child: Material(
        color: FarmColors.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _open,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: FarmColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    HpjProductThumb(
                      productId: item.product.id,
                      productName: item.product.name,
                      size: 106,
                      radius: 14,
                    ),
                    if (!seen)
                      Positioned(
                        left: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: FarmColors.danger,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 12.6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.formattedWholesalePrice} / ${item.wholesaleUnit}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.primary,
                    fontSize: 10.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: HpjWatchButton(
                    workspace: 'wholesale',
                    watchType: 'product',
                    entityKey: item.product.id,
                    entityName: item.product.name,
                    compact: true,
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

class _WholesaleWelcomeCard extends StatelessWidget {
  final VoidCallback onOpenShop;

  const _WholesaleWelcomeCard({
    required this.onOpenShop,
  });

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: FarmColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: FarmColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Welcome to HPJ Wholesale',
            style: TextStyle(
              color: FarmColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Order fresh Jamaican produce for your business. When you know what you will need later, use Planning Ahead so HPJ can prepare supply early.',
            style: TextStyle(
              color: FarmColors.mutedText,
              fontSize: 10.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onOpenShop,
              child: const Text('Start Shopping'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WholesaleActiveOrderCard extends StatelessWidget {
  final WholesaleOrderRequest request;
  final VoidCallback onTap;

  const _WholesaleActiveOrderCard({
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final requestedDate = request.requestedDate == null
        ? null
        : _wholesaleSimpleDate(request.requestedDate!);
    final fulfilment = request.requestedDispatchMethod == 'business_collection'
        ? 'Business collection'
        : 'HPJ delivery';
    final itemCount = request.items.length;
    final firstItem = itemCount == 0 ? null : request.items.first;

    Widget orderVisual() {
      if (firstItem == null) {
        return Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: FarmColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.local_shipping_outlined,
            color: FarmColors.primary,
          ),
        );
      }

      return SizedBox(
        width: 62,
        height: 62,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            HpjProductThumb(
              productId: firstItem.productId,
              productName: firstItem.productName,
              size: 58,
              radius: 14,
            ),
            if (itemCount > 1)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: FarmColors.primary,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    '+${itemCount - 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return FarmCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              orderVisual(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order in progress',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 9.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Order #${request.shortId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        _wholesaleStatementStatus(request.status),
                        if (itemCount > 0)
                          '$itemCount item${itemCount == 1 ? '' : 's'}',
                        fulfilment,
                        if (requestedDate != null) 'Requested $requestedDate',
                      ].join(' • '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 9.6,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
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

class _WholesalePlanningSummaryCard extends StatelessWidget {
  final WholesaleDemandForecast? nextNeed;
  final VoidCallback onTap;

  const _WholesalePlanningSummaryCard({
    required this.nextNeed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final planned = nextNeed;
    final quantity = planned == null
        ? ''
        : planned.quantity.toStringAsFixed(
            planned.quantity == planned.quantity.roundToDouble() ? 0 : 1,
          );

    return FarmCard(
      padding: const EdgeInsets.all(14),
      child: planned == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.event_note_outlined,
                      color: FarmColors.primary,
                      size: 23,
                    ),
                    SizedBox(width: 9),
                    Text(
                      'Planning Ahead',
                      style: TextStyle(
                        color: FarmColors.ink,
                        fontSize: 13.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                const Text(
                  'Tell HPJ what your business may need in the coming weeks.',
                  style: TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 11.4,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onTap,
                    child: const Text('Plan Ahead'),
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HpjProductThumb(
                  productId: planned.productId,
                  productName: planned.productName,
                  size: 78,
                  radius: 15,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Next planned need',
                        style: TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 10.4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        planned.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FarmColors.ink,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$quantity ${planned.unit} • Needed by ${_wholesaleSimpleDate(planned.needByDate)}',
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 11.4,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: onTap,
                          child: const Text('View Plan'),
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

String _wholesaleSimpleDate(DateTime value) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${value.day} ${months[value.month - 1]}';
}

class _WholesaleTodayMetric extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  final VoidCallback? onTap;

  const _WholesaleTodayMetric({
    required this.label,
    required this.value,
    required this.note,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Container(
          height: 102,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: FarmColors.card,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: FarmColors.line,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF183D30).withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 10.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FarmColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 10.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WholesaleAttentionRow extends StatelessWidget {
  final String title;
  final String message;
  final String action;
  final VoidCallback onTap;

  const _WholesaleAttentionRow({
    required this.title,
    required this.message,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 5),
          decoration: const BoxDecoration(
            color: Color(0xFF0B4C36),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: FarmColors.ink,
                  fontSize: 13.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                message,
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 11.4,
                  height: 1.32,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onTap,
          child: Text(
            action,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _WholesaleSimpleMenuTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _WholesaleSimpleMenuTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 2,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: FarmColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: FarmColors.mutedText,
          fontSize: 9.6,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 19,
      ),
      onTap: onTap,
    );
  }
}

class _BusinessDetailsEditScreen extends StatelessWidget {
  final BusinessAccount account;

  const _BusinessDetailsEditScreen({
    required this.account,
  });

  int _recordScore() {
    final values = <String>[
      account.businessName,
      account.businessType,
      account.contactName,
      account.phone,
      account.address,
      account.parish,
      account.registrationNumber,
    ];

    final complete =
        values.where((value) => value.trim().isNotEmpty).length;

    return ((complete / values.length) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: const Text('Business Details'),
      ),
      body: FarmPage(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
          children: [
            _PremiumBusinessDetailsHero(
              account: account,
              recordScore: _recordScore(),
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F6EF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFDCE4D8),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    color: FarmColors.deepGreen,
                    size: 19,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'These details support HPJ ordering, delivery, account contact and business verification. They are not a public business profile.',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 9.4,
                        height: 1.38,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            BusinessApplicationForm(
              existing: account,
              onSubmitted: () async {
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumBusinessDetailsHero extends StatelessWidget {
  final BusinessAccount account;
  final int recordScore;

  const _PremiumBusinessDetailsHero({
    required this.account,
    required this.recordScore,
  });

  Widget _metric(
    String value,
    String label,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.12),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withOpacity(.16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(.72),
                fontSize: 8.6,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preferredDays = account.preferredDeliveryDays.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FarmColors.deepGreen,
            FarmColors.green,
            Color(0xFF4E8157),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRIVATE BUSINESS RECORD',
            style: TextStyle(
              color: Color(0xFFCFE0CF),
              fontSize: 10.3,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            account.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Keep your contact, delivery and business information current so HPJ can fulfil orders correctly.',
            style: TextStyle(
              color: Colors.white.withOpacity(.82),
              fontSize: 10.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _metric(
                '$recordScore%',
                'Record ready',
              ),
              const SizedBox(width: 8),
              _metric(
                account.parish.trim().isEmpty
                    ? 'SET UP'
                    : account.parish.trim(),
                'Parish',
              ),
              const SizedBox(width: 8),
              _metric(
                '$preferredDays',
                'Delivery days',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WholesaleMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _WholesaleMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
      leading: CircleAvatar(
        backgroundColor: FarmColors.primarySoft,
        child: Icon(icon, color: FarmColors.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: FarmColors.ink,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: FarmColors.mutedText,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: onTap,
    );
  }
}
// =====================================================
// WHOLESALE PLANNING AHEAD
// =====================================================

// ============================================================================
// SOURCE SECTION: business_shop.dart
// ============================================================================
// HPJ PHASE 88 — BUSINESS WHOLESALE SHOP + REPEAT ORDERS
// Extracted from wholesale_management.dart without changing runtime behavior.

class WholesaleCatalogueScreen extends StatefulWidget {
  final BusinessAccount account;
  final bool embedded;
  final String initialSearch;
  final VoidCallback? onOpenSuppliers;

  const WholesaleCatalogueScreen({
    super.key,
    required this.account,
    this.embedded = false,
    this.initialSearch = '',
    this.onOpenSuppliers,
  });

  @override
  State<WholesaleCatalogueScreen> createState() =>
      _WholesaleCatalogueScreenState();
}

class _WholesaleCatalogueScreenState extends State<WholesaleCatalogueScreen> {
  late Future<List<WholesaleProduct>> _future;
  final Map<String, WholesaleProduct> selectedProducts =
      <String, WholesaleProduct>{};
  final Map<String, int> quantities = <String, int>{};
  final searchController = TextEditingController();
  String search = '';

  @override
  void initState() {
    super.initState();
    final initialSearch = widget.initialSearch.trim();
    if (initialSearch.isNotEmpty) {
      search = initialSearch;
      searchController.text = initialSearch;
      searchController.selection = TextSelection.collapsed(
        offset: searchController.text.length,
      );
    }
    _future = fetchWholesaleCatalogue();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshCatalogue() async {
    final next = fetchWholesaleCatalogue();
    if (mounted) {
      setState(() => _future = next);
    }
    await next;
  }

  int get selectedLineCount => selectedProducts.length;

  double get selectedEstimate {
    double total = 0;
    for (final entry in selectedProducts.entries) {
      final quantity = quantities[entry.key] ?? entry.value.minimumQuantity;
      total += entry.value.totalFor(quantity);
    }
    return total;
  }

  void _toggle(WholesaleProduct item) {
    setState(() {
      if (selectedProducts.containsKey(item.product.id)) {
        selectedProducts.remove(item.product.id);
        quantities.remove(item.product.id);
      } else {
        selectedProducts[item.product.id] = item;
        quantities[item.product.id] = item.minimumQuantity;
      }
    });
  }

  void _changeQuantity(WholesaleProduct item, int change) {
    final current = quantities[item.product.id] ?? item.minimumQuantity;
    var next = current + change;

    if (next < item.minimumQuantity) {
      next = item.minimumQuantity;
    }

    if (item.marketAllocationManaged) {
      final maximum = item.maximumManagedOrderQuantity;
      if (next > maximum) {
        next = maximum;
      }
    }

    setState(() {
      quantities[item.product.id] = next;
    });
  }

  void _review() {
    if (selectedProducts.isEmpty) return;

    for (final entry in selectedProducts.entries) {
      final item = entry.value;
      final quantity = quantities[entry.key] ?? item.minimumQuantity;

      if (item.marketAllocationManaged &&
          quantity > item.maximumManagedOrderQuantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item.product.name} currently has only '
              '${item.maximumManagedOrderQuantity} ${item.wholesaleUnit} '
              'allocated for Wholesale.',
            ),
          ),
        );
        return;
      }
    }

    final lines = selectedProducts.values
        .map(
          (item) => _WholesaleBasketLine(
            item: item,
            quantity: quantities[item.product.id] ?? item.minimumQuantity,
          ),
        )
        .toList();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WholesaleRequestReviewScreen(
          account: widget.account,
          lines: lines,
        ),
      ),
    );
  }

  void _openSuppliers() {
    final callback = widget.onOpenSuppliers;
    if (callback != null) {
      callback();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WholesaleSupplierDiscoveryScreen(
          account: widget.account,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('Wholesale Shop')),
      bottomNavigationBar: selectedProducts.isEmpty
          ? null
          : _PremiumWholesaleBasketBar(
              lineCount: selectedLineCount,
              estimate: selectedEstimate,
              onReview: _review,
            ),
      body: FutureBuilder<List<WholesaleProduct>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return FarmPage(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
                children: const [
                  FarmSkeletonCard(height: 210),
                  SizedBox(height: 12),
                  FarmSkeletonCard(height: 220),
                  SizedBox(height: 12),
                  FarmSkeletonCard(height: 220),
                ],
              ),
            );
          }

          if (snapshot.hasError && !snapshot.hasData) {
            return FarmPage(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 28, 18, 120),
                children: [
                  FarmEmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Wholesale catalogue unavailable',
                    message:
                        'HPJ could not load current wholesale supply. Your Business account is safe.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _refreshCatalogue,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry Source Produce'),
                  ),
                ],
              ),
            );
          }

          final all = snapshot.data ?? const <WholesaleProduct>[];
          final query = search.trim();
          final textQuery = hpjSmartSearchTextQuery(query);
          final maxWholesalePrice = hpjSmartSearchMaxPrice(query);

          final items = query.isEmpty
              ? List<WholesaleProduct>.from(all)
              : all.where((item) {
                  final matchesPrice = maxWholesalePrice == null ||
                      item.wholesalePrice <= maxWholesalePrice + 0.001;
                  final matchesText = textQuery.isEmpty ||
                      hpjSmartProductMatchesSearch(
                        item.product,
                        textQuery,
                      );

                  return matchesPrice && matchesText;
                }).toList();

          items.sort((a, b) {
            if (textQuery.isNotEmpty) {
              final scoreCompare =
                  hpjSmartProductSearchScore(
                    b.product,
                    textQuery,
                  ).compareTo(
                    hpjSmartProductSearchScore(
                      a.product,
                      textQuery,
                    ),
                  );

              if (scoreCompare != 0) return scoreCompare;
            }

            if (maxWholesalePrice != null) {
              final priceCompare =
                  a.wholesalePrice.compareTo(b.wholesalePrice);
              if (priceCompare != 0) return priceCompare;
            }

            if (a.canOrder != b.canOrder) {
              return a.canOrder ? -1 : 1;
            }

            return a.product.name.toLowerCase().compareTo(
                  b.product.name.toLowerCase(),
                );
          });

          final managedCount =
              all.where((item) => item.marketAllocationManaged).length;

          return FarmPage(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                18,
                16,
                18,
                selectedProducts.isEmpty ? 120 : 200,
              ),
              children: [
                _PremiumWholesaleShopHero(
                  businessName: widget.account.displayName,
                  productCount: all.length,
                  managedCount: managedCount,
                  selectedCount: selectedLineCount,
                  selectedEstimate: selectedEstimate,
                  onFindSuppliers: _openSuppliers,
                ),
                const SizedBox(height: 16),

                const Text(
                  'Shop wholesale',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Build a bulk request using current HPJ wholesale prices, '
                  'minimum quantities and available market allocation.',
                  style: TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 10.2,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 11),

                TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) => setState(() => search = value),
                  onSubmitted: (value) {
                    unawaited(
                      HpjSmartLocalStore.rememberRecentSearch(value),
                    );
                  },
                  decoration: InputDecoration(
                    hintText: 'Search produce or price',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              searchController.clear();
                              setState(() => search = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        query.isEmpty
                            ? '${all.length} wholesale product${all.length == 1 ? '' : 's'} available'
                            : '${items.length} result${items.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _openSuppliers,
                      icon: const Icon(
                        Icons.agriculture_outlined,
                        size: 16,
                      ),
                      label: const Text('Find Farms'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                if (items.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No wholesale products',
                    message:
                        'Try another search. Wholesale products appear here when HPJ enables them for business ordering.',
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final useTwoColumns =
                          constraints.maxWidth >= 900;
                      const gap = 12.0;
                      final width = useTwoColumns
                          ? (constraints.maxWidth - gap) / 2
                          : constraints.maxWidth;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: items.map((item) {
                          final selected = selectedProducts
                              .containsKey(item.product.id);

                          final quantity =
                              quantities[item.product.id] ??
                                  item.minimumQuantity;

                          return SizedBox(
                            width: width,
                            child: _PremiumWholesaleProductCard(
                              item: item,
                              selected: selected,
                              quantity: quantity,
                              onToggle: () => _toggle(item),
                              onDecrease: () =>
                                  _changeQuantity(item, -1),
                              onIncrease: () =>
                                  _changeQuantity(item, 1),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PremiumWholesaleShopHero extends StatelessWidget {
  final String businessName;
  final int productCount;
  final int managedCount;
  final int selectedCount;
  final double selectedEstimate;
  final VoidCallback onFindSuppliers;

  const _PremiumWholesaleShopHero({
    required this.businessName,
    required this.productCount,
    required this.managedCount,
    required this.selectedCount,
    required this.selectedEstimate,
    required this.onFindSuppliers,
  });

  Widget _metric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(.16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 17,
              color: const Color(0xFFE8C768),
            ),
            const SizedBox(height: 7),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(.72),
                fontSize: 8.7,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanName = businessName.trim().isEmpty
        ? 'Business wholesale'
        : businessName.trim();

    if (hpjUseMobileAppPresentation(context)) {
      return _HpjBusinessMobileHeaderCard(
        icon: Icons.shopping_basket_outlined,
        eyebrow: 'SOURCE PRODUCE',
        title: cleanName,
        subtitle:
            'Build a wholesale request from current HPJ supply and market allocation.',
        metrics: <_HpjBusinessMobileMetricData>[
          _HpjBusinessMobileMetricData(
            value: '$productCount',
            label: 'Products',
          ),
          _HpjBusinessMobileMetricData(
            value: '$managedCount',
            label: 'Allocated',
          ),
          _HpjBusinessMobileMetricData(
            value: '$selectedCount',
            label: 'Selected',
          ),
          _HpjBusinessMobileMetricData(
            value: selectedCount == 0
                ? '—'
                : formatJmd(selectedEstimate),
            label: 'Estimate',
          ),
        ],
        onAction: onFindSuppliers,
        actionLabel: 'Find preferred suppliers',
        actionIcon: Icons.handshake_outlined,
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FarmColors.deepGreen,
            FarmColors.green,
            Color(0xFF4E8157),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: FarmColors.deepGreen.withOpacity(.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.13),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(.18),
                  ),
                ),
                child: const Icon(
                  Icons.shopping_basket_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WHOLESALE SHOP',
                      style: TextStyle(
                        color: Colors.white.withOpacity(.72),
                        fontSize: 10.3,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .9,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cleanName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Build a request from HPJ-approved bulk produce and current '
            'market allocation.',
            style: TextStyle(
              color: Colors.white.withOpacity(.83),
              fontSize: 10.8,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _metric(
                icon: Icons.inventory_2_outlined,
                value: '$productCount',
                label: 'Products',
              ),
              const SizedBox(width: 8),
              _metric(
                icon: Icons.hub_outlined,
                value: '$managedCount',
                label: 'HPJ allocated',
              ),
              const SizedBox(width: 8),
              _metric(
                icon: Icons.shopping_cart_outlined,
                value: selectedCount == 0
                    ? '0'
                    : '$selectedCount',
                label: selectedCount == 0
                    ? 'Selected'
                    : formatJmd(selectedEstimate),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Material(
            color: Colors.white.withOpacity(.10),
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              onTap: onFindSuppliers,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(.14),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.agriculture_outlined,
                      color: Color(0xFFE8C768),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Need a preferred farm? Discover approved Jamaican suppliers through HPJ.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(.84),
                          fontSize: 9.5,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumWholesaleProductCard extends StatelessWidget {
  final WholesaleProduct item;
  final bool selected;
  final int quantity;
  final VoidCallback onToggle;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _PremiumWholesaleProductCard({
    required this.item,
    required this.selected,
    required this.quantity,
    required this.onToggle,
    required this.onDecrease,
    required this.onIncrease,
  });

  Widget _image({required bool compact}) {
    final url = item.product.imageUrl;

    if (url == null || url.trim().isEmpty) {
      return Container(
        color: FarmColors.cardSoft,
        alignment: Alignment.center,
        child: Icon(
          Icons.eco_outlined,
          color: FarmColors.green,
          size: compact ? 26 : 30,
        ),
      );
    }

    return Container(
      color: compact ? Colors.white : FarmColors.cardSoft,
      alignment: Alignment.center,
      child: Image.network(
        url,
        width: double.infinity,
        height: double.infinity,
        // On the app, show the whole produce instead of blowing it up/cropping it.
        fit: compact ? BoxFit.contain : BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: FarmColors.cardSoft,
          alignment: Alignment.center,
          child: Icon(
            Icons.eco_outlined,
            color: FarmColors.green,
            size: compact ? 26 : 30,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lineTotal = item.totalFor(quantity);
    final compact = hpjUseMobileAppPresentation(context);
    final viewportWidth = MediaQuery.sizeOf(context).width;

    // Keep the original roomy desktop merchandising card, but make the app
    // substantially denser so users can browse several products quickly.
    final imageHeight = compact
        ? 104.0
        : viewportWidth < 900
            ? 126.0
            : 150.0;

    final cardRadius = compact ? 16.0 : 18.0;

    return FarmCard(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(
            color: selected
                ? FarmColors.green.withOpacity(.38)
                : Colors.transparent,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(cardRadius),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: imageHeight,
                    child: _image(compact: compact),
                  ),
                ),
                Positioned(
                  top: compact ? 8 : 10,
                  left: compact ? 8 : 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 7 : 8,
                      vertical: compact ? 4 : 5,
                    ),
                    decoration: BoxDecoration(
                      color: FarmColors.deepGreen.withOpacity(.90),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'WHOLESALE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 7.4 : 8.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .45,
                      ),
                    ),
                  ),
                ),
                if (selected)
                  Positioned(
                    top: compact ? 8 : 10,
                    right: compact ? 8 : 10,
                    child: Container(
                      width: compact ? 26 : 30,
                      height: compact ? 26 : 30,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: FarmColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: compact ? 16 : 18,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: compact
                  ? const EdgeInsets.fromLTRB(12, 9, 12, 11)
                  : const EdgeInsets.fromLTRB(14, 13, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontSize: compact ? 14 : 15.5,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: compact ? 5 : 7),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          item.formattedWholesalePrice,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: FarmColors.deepGreen,
                            fontSize: compact ? 15.5 : 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '/ ${item.wholesaleUnit}',
                          style: TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: compact ? 8.8 : 9.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 3 : 4),
                  Text(
                    'Minimum ${item.minimumQuantity} ${item.wholesaleUnit}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: compact ? 9.1 : 9.7,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.marketAllocationManaged) ...[
                    SizedBox(height: compact ? 6 : 7),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 8 : 9,
                        vertical: compact ? 6 : 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F6EF),
                        borderRadius: BorderRadius.circular(compact ? 10 : 12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.hub_outlined,
                            color: FarmColors.deepGreen,
                            size: compact ? 14 : 15,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.marketAvailabilityLabel,
                              maxLines: compact ? 2 : null,
                              overflow:
                                  compact ? TextOverflow.ellipsis : null,
                              style: TextStyle(
                                color: FarmColors.deepGreen,
                                fontSize: compact ? 8.4 : 8.9,
                                height: 1.25,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: compact ? 7 : 9),
                  HpjWatchButton(
                    workspace: 'wholesale',
                    watchType: 'product',
                    entityKey: item.product.id,
                    entityName: item.product.name,
                    compact: true,
                  ),
                  SizedBox(height: compact ? 8 : 11),
                  if (!selected)
                    SizedBox(
                      width: double.infinity,
                      height: compact ? 38 : null,
                      child: OutlinedButton.icon(
                        style: compact
                            ? OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                visualDensity: VisualDensity.compact,
                              )
                            : null,
                        icon: Icon(
                          Icons.add_shopping_cart_outlined,
                          size: compact ? 16 : 17,
                        ),
                        label: Text(
                          compact ? 'Add to Bulk Request' : 'Add to Bulk Request',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: onToggle,
                      ),
                    )
                  else ...[
                    Container(
                      padding: EdgeInsets.all(compact ? 7 : 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F5),
                        borderRadius: BorderRadius.circular(compact ? 13 : 15),
                        border: Border.all(
                          color: FarmColors.line,
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Decrease quantity',
                            visualDensity: VisualDensity.compact,
                            constraints: compact
                                ? const BoxConstraints(
                                    minWidth: 34,
                                    minHeight: 34,
                                  )
                                : null,
                            onPressed: onDecrease,
                            icon: const Icon(Icons.remove_rounded),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '$quantity ${item.wholesaleUnit}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: FarmColors.ink,
                                    fontSize: compact ? 11.5 : 12.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatJmd(lineTotal),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: FarmColors.green,
                                    fontSize: compact ? 9 : 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Increase quantity',
                            visualDensity: VisualDensity.compact,
                            constraints: compact
                                ? const BoxConstraints(
                                    minWidth: 34,
                                    minHeight: 34,
                                  )
                                : null,
                            onPressed: onIncrease,
                            icon: const Icon(Icons.add_rounded),
                          ),
                          IconButton(
                            tooltip: 'Remove',
                            visualDensity: VisualDensity.compact,
                            constraints: compact
                                ? const BoxConstraints(
                                    minWidth: 34,
                                    minHeight: 34,
                                  )
                                : null,
                            onPressed: onToggle,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: FarmColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumWholesaleBasketBar extends StatelessWidget {
  final int lineCount;
  final double estimate;
  final VoidCallback onReview;

  const _PremiumWholesaleBasketBar({
    required this.lineCount,
    required this.estimate,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: FarmColors.card,
          border: Border(
            top: BorderSide(color: FarmColors.line),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 22,
              offset: const Offset(0, -7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FarmColors.primarySoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.shopping_basket_outlined,
                color: FarmColors.deepGreen,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$lineCount bulk item${lineCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: FarmColors.ink,
                      fontSize: 11.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatJmd(estimate)} estimated subtotal',
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 9.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: onReview,
              child: const Text('Review Request'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WholesaleBasketLine {
  final WholesaleProduct item;
  final int quantity;

  const _WholesaleBasketLine({
    required this.item,
    required this.quantity,
  });

  double get total => item.totalFor(quantity);
}

class WholesaleRequestReviewScreen extends StatefulWidget {
  final BusinessAccount account;
  final List<_WholesaleBasketLine> lines;
  final String? standingOrderId;
  final String? initialDispatchMethod;
  final DateTime? preferredScheduleDate;

  const WholesaleRequestReviewScreen({
    super.key,
    required this.account,
    required this.lines,
    this.standingOrderId,
    this.initialDispatchMethod,
    this.preferredScheduleDate,
  });

  @override
  State<WholesaleRequestReviewScreen> createState() =>
      _WholesaleRequestReviewScreenState();
}

class _WholesaleRequestReviewScreenState
    extends State<WholesaleRequestReviewScreen> {
  late final TextEditingController addressController;
  late final TextEditingController parishController;
  final notesController = TextEditingController();
  bool submitting = false;

  WholesaleOrderingControl? orderingControl;
  bool loadingOrderingControl = true;
  String? orderingControlError;

  String dispatchMethod = 'hpj_delivery';
  List<WholesaleScheduleOption> scheduleOptions =
      const <WholesaleScheduleOption>[];
  WholesaleScheduleOption? selectedSchedule;
  bool loadingSchedule = true;
  String? scheduleError;

  @override
  void initState() {
    super.initState();
    addressController = TextEditingController(text: widget.account.address);
    parishController = TextEditingController(text: widget.account.parish);
    final requestedMethod = widget.initialDispatchMethod?.trim().toLowerCase();
    if (requestedMethod == 'business_collection' ||
        requestedMethod == 'hpj_delivery') {
      dispatchMethod = requestedMethod!;
    }
    _loadOrderingControl();
    _loadScheduleOptions();
  }

  @override
  void dispose() {
    addressController.dispose();
    parishController.dispose();
    notesController.dispose();
    super.dispose();
  }

  double get estimate => widget.lines.fold<double>(
        0,
        (sum, line) => sum + line.total,
      );

  Future<void> _loadOrderingControl() async {
    if (mounted) {
      setState(() {
        loadingOrderingControl = true;
        orderingControlError = null;
      });
    }

    try {
      final control = await fetchWholesaleOrderingControl(
        account: widget.account,
        estimatedTotal: estimate,
      );

      if (!mounted) return;
      setState(() {
        orderingControl = control;
        loadingOrderingControl = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        orderingControl = null;
        loadingOrderingControl = false;
        orderingControlError = friendlyAppError(error);
      });
    }
  }

  Future<void> _loadScheduleOptions() async {
    if (mounted) {
      setState(() {
        loadingSchedule = true;
        scheduleError = null;
        selectedSchedule = null;
      });
    }

    try {
      final options = await fetchWholesaleScheduleOptions(
        dispatchMethod: dispatchMethod,
      );

      if (!mounted) return;
      WholesaleScheduleOption? preferred;
      final preferredDate = widget.preferredScheduleDate;
      if (preferredDate != null) {
        final target = DateTime(
          preferredDate.year,
          preferredDate.month,
          preferredDate.day,
        );
        for (final option in options) {
          final date = option.scheduledDate.toLocal();
          final dateOnly = DateTime(date.year, date.month, date.day);
          if (!dateOnly.isBefore(target)) {
            preferred = option;
            break;
          }
        }
      }

      setState(() {
        scheduleOptions = options;
        selectedSchedule =
            preferred ?? (options.isEmpty ? null : options.first);
        loadingSchedule = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        scheduleOptions = const <WholesaleScheduleOption>[];
        selectedSchedule = null;
        loadingSchedule = false;
        scheduleError = friendlyAppError(error);
      });
    }
  }

  Future<void> _changeDispatchMethod(String value) async {
    if (dispatchMethod == value) return;
    setState(() => dispatchMethod = value);
    await _loadScheduleOptions();
  }

  Future<void> _submit() async {
    if (submitting) return;

    if (dispatchMethod == 'hpj_delivery' &&
        (addressController.text.trim().isEmpty ||
            parishController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery address and parish are required.'),
        ),
      );
      return;
    }

    if (loadingOrderingControl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checking wholesale account status. Please try again.'),
        ),
      );
      return;
    }

    if (orderingControl?.isBlocked == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orderingControl!.reason)),
      );
      return;
    }

    if (loadingSchedule || selectedSchedule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose an available delivery or collection window.'),
        ),
      );
      return;
    }

    setState(() => submitting = true);
    try {
      final deliveryAddress = dispatchMethod == 'business_collection'
          ? widget.account.address
          : addressController.text;
      final deliveryParish = dispatchMethod == 'business_collection'
          ? widget.account.parish
          : parishController.text;

      final id = await submitWholesaleOrderRequest(
        items: widget.lines
            .map(
              (line) => {
                'product_id': line.item.product.id,
                'quantity': line.quantity,
              },
            )
            .toList(),
        deliveryAddress: deliveryAddress,
        deliveryParish: deliveryParish,
        schedule: selectedSchedule!,
        dispatchMethod: dispatchMethod,
        notes: notesController.text,
        estimatedTotal: estimate,
      );

      final standingId = widget.standingOrderId?.trim() ?? '';
      if (standingId.isNotEmpty) {
        try {
          await markWholesaleStandingOrderUsed(
            standingOrderId: standingId,
            requestId: id,
          );
        } catch (error) {
          farmDebugLog(
            'Standing order next-date update skipped safely: $error',
          );
        }
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => WholesaleRequestSuccessScreen(requestId: id),
        ),
        (route) => route.isFirst,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
      await _loadScheduleOptions();
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dispatchLabel = dispatchMethod == 'business_collection'
        ? 'Business Collection'
        : 'HPJ Delivery';

    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: const Text('Review Bulk Request'),
      ),
      body: FarmPage(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 140),
          children: [
            _PremiumWholesaleReviewHero(
              businessName: widget.account.displayName,
              lineCount: widget.lines.length,
              estimate: estimate,
              dispatchLabel: dispatchLabel,
            ),
            const SizedBox(height: 16),

            const Text(
              'Request items',
              style: TextStyle(
                color: FarmColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your quantities are shown below. HPJ confirms final farm '
              'availability and pricing before fulfilment.',
              style: TextStyle(
                color: FarmColors.mutedText,
                fontSize: 9.7,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            ...widget.lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PremiumWholesaleReviewLineCard(
                  line: line,
                ),
              ),
            ),

            const SizedBox(height: 2),
            FarmCard(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated subtotal',
                          style: TextStyle(
                            color: FarmColors.ink,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Before final HPJ confirmation',
                          style: TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 8.9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatJmd(estimate),
                    style: const TextStyle(
                      color: FarmColors.deepGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              'Account & credit',
              style: TextStyle(
                color: FarmColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),

            if (loadingOrderingControl)
              const FarmCard(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Checking account balance, aging and available credit...',
                        style: TextStyle(
                          color: FarmColors.mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (orderingControl != null)
              _WholesaleOrderingControlCard(
                control: orderingControl!,
                showRequestEstimate: true,
                onRefresh: _loadOrderingControl,
              )
            else
              FarmCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account check unavailable',
                      style: TextStyle(
                        color: FarmColors.danger,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      orderingControlError ??
                          'Could not verify wholesale ordering status.',
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _loadOrderingControl,
                      icon: const Icon(Icons.refresh_outlined),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 14),

            FarmCard(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        color: FarmColors.deepGreen,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fulfilment',
                          style: TextStyle(
                            color: FarmColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Choose how the business will receive this request.',
                    style: TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 9.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 11),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('HPJ Delivery'),
                        selected:
                            dispatchMethod == 'hpj_delivery',
                        onSelected: (_) =>
                            _changeDispatchMethod('hpj_delivery'),
                      ),
                      ChoiceChip(
                        label:
                            const Text('Business Collection'),
                        selected:
                            dispatchMethod == 'business_collection',
                        onSelected: (_) =>
                            _changeDispatchMethod(
                              'business_collection',
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),

                  if (loadingSchedule)
                    const Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Checking available capacity...',
                            style: TextStyle(
                              color: FarmColors.mutedText,
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (scheduleOptions.isEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scheduleError ??
                              'No available windows were found. Please try another fulfilment method or contact HPJ.',
                          style: const TextStyle(
                            color: FarmColors.danger,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _loadScheduleOptions,
                          icon: const Icon(
                            Icons.refresh_outlined,
                          ),
                          label: const Text('Check Again'),
                        ),
                      ],
                    )
                  else
                    DropdownButtonFormField<String>(
                      value:
                          selectedSchedule?.selectionKey,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Available window',
                        prefixIcon:
                            Icon(Icons.schedule_outlined),
                      ),
                      items: scheduleOptions
                          .map(
                            (option) =>
                                DropdownMenuItem<String>(
                              value: option.selectionKey,
                              child: Text(
                                option.displayLabel,
                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        final match = scheduleOptions.where(
                          (option) =>
                              option.selectionKey == value,
                        );

                        if (match.isNotEmpty) {
                          setState(
                            () => selectedSchedule =
                                match.first,
                          );
                        }
                      },
                    ),
                ],
              ),
            ),

            if (dispatchMethod == 'hpj_delivery') ...[
              const SizedBox(height: 14),
              FarmCard(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: FarmColors.deepGreen,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Delivery details',
                          style: TextStyle(
                            color: FarmColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText:
                            'Business delivery address',
                        prefixIcon:
                            Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    JamaicaParishDropdown(
                      controller: parishController,
                      label: 'Delivery parish',
                      prefixIcon: Icons.map_outlined,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            FarmCard(
              padding: const EdgeInsets.all(15),
              child: TextField(
                controller: notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText:
                      dispatchMethod == 'business_collection'
                          ? 'Collection instructions or contact notes'
                          : 'Receiving hours or special instructions',
                  prefixIcon:
                      const Icon(Icons.notes_outlined),
                ),
              ),
            ),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F6EF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFDCE4D8),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: FarmColors.deepGreen,
                    size: 19,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Submitting creates a wholesale request. HPJ still confirms farm availability, final pricing and fulfilment before completion.',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 9.4,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(
                  orderingControl?.isBlocked == true
                      ? Icons.block_outlined
                      : Icons.send_outlined,
                ),
                label: Text(
                  submitting
                      ? 'Submitting...'
                      : loadingOrderingControl
                          ? 'Checking Account...'
                          : loadingSchedule
                              ? 'Checking Capacity...'
                              : orderingControl?.isBlocked == true
                                  ? 'Ordering Blocked'
                                  : selectedSchedule == null
                                      ? 'Choose a Window'
                                      : 'Submit Bulk Request',
                ),
                onPressed: submitting ||
                        loadingOrderingControl ||
                        loadingSchedule ||
                        selectedSchedule == null ||
                        orderingControl?.isBlocked == true
                    ? null
                    : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumWholesaleReviewHero extends StatelessWidget {
  final String businessName;
  final int lineCount;
  final double estimate;
  final String dispatchLabel;

  const _PremiumWholesaleReviewHero({
    required this.businessName,
    required this.lineCount,
    required this.estimate,
    required this.dispatchLabel,
  });

  Widget _metric(
    String value,
    String label,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.12),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withOpacity(.16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(.72),
                fontSize: 8.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = businessName.trim().isEmpty
        ? 'Business request'
        : businessName.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FarmColors.deepGreen,
            FarmColors.green,
            Color(0xFF4E8157),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REVIEW WHOLESALE REQUEST',
            style: TextStyle(
              color: Color(0xFFCFE0CF),
              fontSize: 10.3,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Review quantities, account status and fulfilment before sending the request to HPJ.',
            style: TextStyle(
              color: Colors.white.withOpacity(.82),
              fontSize: 10.5,
              height: 1.38,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _metric(
                '$lineCount',
                'Product lines',
              ),
              const SizedBox(width: 8),
              _metric(
                formatJmd(estimate),
                'Estimate',
              ),
              const SizedBox(width: 8),
              _metric(
                dispatchLabel,
                'Fulfilment',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumWholesaleReviewLineCard extends StatelessWidget {
  final _WholesaleBasketLine line;

  const _PremiumWholesaleReviewLineCard({
    required this.line,
  });

  @override
  Widget build(BuildContext context) {
    final url = line.item.product.imageUrl;

    return FarmCard(
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: SizedBox(
              width: 58,
              height: 58,
              child: url == null || url.trim().isEmpty
                  ? Container(
                      color: FarmColors.cardSoft,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.eco_outlined,
                        color: FarmColors.green,
                      ),
                    )
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: FarmColors.cardSoft,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.eco_outlined,
                          color: FarmColors.green,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${line.quantity} ${line.item.wholesaleUnit} • ${line.item.formattedWholesalePrice} / ${line.item.wholesaleUnit}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 9.2,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatJmd(line.total),
            style: const TextStyle(
              color: FarmColors.deepGreen,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class WholesaleRequestSuccessScreen extends StatelessWidget {
  final String requestId;

  const WholesaleRequestSuccessScreen({
    super.key,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    final clean = requestId.replaceAll('-', '').toUpperCase();
    final shortId =
        clean.length > 8 ? clean.substring(0, 8) : clean;

    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: const Text('Request Submitted'),
      ),
      body: FarmPage(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            18,
            24,
            18,
            120,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    FarmColors.deepGreen,
                    FarmColors.green,
                    Color(0xFF4E8157),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        FarmColors.deepGreen.withOpacity(.14),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.13),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(.18),
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFFE8C768),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Bulk request received',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Request #$shortId',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.78),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'HPJ will review farm availability, confirm final pricing and move the request into fulfilment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.84),
                      fontSize: 10.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            FarmCard(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'What happens next',
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 12),
                  _PremiumWholesaleNextStep(
                    number: '1',
                    title: 'Supply check',
                    text:
                        'HPJ confirms the farm supply available for your requested quantities.',
                  ),
                  SizedBox(height: 10),
                  _PremiumWholesaleNextStep(
                    number: '2',
                    title: 'Final confirmation',
                    text:
                        'Pricing, credit status and fulfilment details are confirmed.',
                  ),
                  SizedBox(height: 10),
                  _PremiumWholesaleNextStep(
                    number: '3',
                    title: 'Track the request',
                    text:
                        'Follow progress from Orders as HPJ prepares delivery or collection.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const MyWholesaleRequestsScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.local_shipping_outlined,
                ),
                label:
                    const Text('View My Bulk Requests'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumWholesaleNextStep extends StatelessWidget {
  final String number;
  final String title;
  final String text;

  const _PremiumWholesaleNextStep({
    required this.number,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: FarmColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: FarmColors.deepGreen,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
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
                  color: FarmColors.ink,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 9.3,
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

class WholesaleRepeatStandingOrdersScreen extends StatefulWidget {
  final BusinessAccount account;

  const WholesaleRepeatStandingOrdersScreen({
    super.key,
    required this.account,
  });

  @override
  State<WholesaleRepeatStandingOrdersScreen> createState() =>
      _WholesaleRepeatStandingOrdersScreenState();
}

class _WholesaleRepeatStandingOrdersScreenState
    extends State<WholesaleRepeatStandingOrdersScreen> {
  late Future<List<WholesaleOrderTemplate>> templatesFuture;
  late Future<List<WholesaleStandingOrder>> standingFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    templatesFuture = fetchMyWholesaleOrderTemplates();
    standingFuture = fetchMyWholesaleStandingOrders();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await Future.wait<Object>([templatesFuture, standingFuture]);
  }

  Future<void> _useItems({
    required List<WholesaleSavedOrderItem> items,
    String? standingOrderId,
    String? dispatchMethod,
    DateTime? preferredDate,
  }) async {
    try {
      final draft = await prepareWholesaleSavedBasket(items);
      if (!mounted) return;

      if (draft.lines.isEmpty) {
        throw Exception(
          'None of the saved products are currently available for wholesale ordering.',
        );
      }

      if (draft.unavailableProducts.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unavailable items were skipped: ${draft.unavailableProducts.join(', ')}',
            ),
          ),
        );
      }

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WholesaleRequestReviewScreen(
            account: widget.account,
            lines: draft.lines,
            standingOrderId: standingOrderId,
            initialDispatchMethod: dispatchMethod,
            preferredScheduleDate: preferredDate,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  Future<void> _renameTemplate(WholesaleOrderTemplate template) async {
    final controller = TextEditingController(text: template.name);
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename Repeat Order'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Template name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (save == true) {
      try {
        await renameWholesaleOrderTemplate(
          template: template,
          name: controller.text,
        );
        await _refresh();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyAppError(error))),
          );
        }
      }
    }
    controller.dispose();
  }

  Future<void> _archiveTemplate(WholesaleOrderTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove saved order?'),
        content: Text(
          'Remove “${template.name}” from your repeat-order list? Existing orders are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await archiveWholesaleOrderTemplate(template);
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  Future<void> _createStandingOrder(WholesaleOrderTemplate template) async {
    final nameController = TextEditingController(text: template.name);
    final notesController = TextEditingController();
    String frequency = 'weekly';
    String method = 'hpj_delivery';
    DateTime startDate = DateTime.now().add(const Duration(days: 7));

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Create Standing Order'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: 'Standing-order name'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: frequency,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                    items: const [
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(
                          value: 'biweekly', child: Text('Every 2 Weeks')),
                      DropdownMenuItem(
                          value: 'monthly', child: Text('Monthly')),
                    ],
                    onChanged: (value) {
                      if (value != null)
                        setDialogState(() => frequency = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: method,
                    decoration: const InputDecoration(labelText: 'Fulfilment'),
                    items: const [
                      DropdownMenuItem(
                        value: 'hpj_delivery',
                        child: Text('HPJ Delivery'),
                      ),
                      DropdownMenuItem(
                        value: 'business_collection',
                        child: Text('Business Collection'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => method = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: const Text('First required date'),
                    subtitle: Text(
                      '${startDate.day}/${startDate.month}/${startDate.year}',
                    ),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (picked != null) {
                        setDialogState(() => startDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'Special recurring requirement',
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'HPJ must approve the standing order. Each occurrence still uses current wholesale prices, live credit checks, and an available delivery/collection window.',
                    style: TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 10.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Send for Approval'),
              ),
            ],
          );
        },
      ),
    );

    if (save == true) {
      try {
        await createWholesaleStandingOrderFromTemplate(
          template: template,
          name: nameController.text,
          frequency: frequency,
          startDate: startDate,
          dispatchMethod: method,
          deliveryAddress: widget.account.address,
          deliveryParish: widget.account.parish,
          notes: notesController.text,
        );
        await _refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Standing order sent to HPJ for approval.'),
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyAppError(error))),
          );
        }
      }
    }

    nameController.dispose();
    notesController.dispose();
  }

  Future<void> _changeStandingStatus(
    WholesaleStandingOrder order,
    String status,
  ) async {
    try {
      await updateMyWholesaleStandingOrderStatus(order: order, status: status);
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return 'Not set';
    final date = value.toLocal();
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _standingColor(WholesaleStandingOrder order) {
    if (order.isActive) return FarmColors.success;
    if (order.isRejected || order.isCancelled) return FarmColors.danger;
    if (order.isPaused) return FarmColors.warning;
    return FarmColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: FarmColors.background,
        appBar: AppBar(
          title: const Text('Repeat & Standing Orders'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.replay_rounded),
                text: 'Repeat Orders',
              ),
              Tab(
                icon: Icon(Icons.event_repeat_rounded),
                text: 'Standing',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FutureBuilder<List<WholesaleOrderTemplate>>(
              future: templatesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                        ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      friendlyAppError(snapshot.error!),
                    ),
                  );
                }

                final templates =
                    snapshot.data ?? const <WholesaleOrderTemplate>[];

                final totalLines = templates.fold<int>(
                  0,
                  (sum, template) =>
                      sum + template.items.length,
                );

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      16,
                      18,
                      120,
                    ),
                    children: [
                      _PremiumRecurringOrdersHero(
                        mode: 'repeat',
                        businessName:
                            widget.account.displayName,
                        primaryCount: templates.length,
                        secondaryCount: totalLines,
                        tertiaryCount: 0,
                        nextDue: null,
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Saved repeat orders',
                        style: TextStyle(
                          color: FarmColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Reuse a familiar basket, then HPJ checks today’s availability, prices, capacity and credit before you submit it.',
                        style: TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 9.6,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (templates.isEmpty)
                        const FarmEmptyState(
                          icon: Icons.bookmark_add_outlined,
                          title: 'No repeat orders saved',
                          message:
                              'Open Orders and choose Save Template on a previous bulk request.',
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final useTwo =
                                constraints.maxWidth >= 900;

                            const gap = 12.0;

                            final width = useTwo
                                ? (constraints.maxWidth - gap) / 2
                                : constraints.maxWidth;

                            return Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: templates
                                  .map(
                                    (template) => SizedBox(
                                      width: width,
                                      child:
                                          _PremiumRepeatOrderCard(
                                        template: template,
                                        onUse: () => _useItems(
                                          items: template.items,
                                        ),
                                        onStanding: () =>
                                            _createStandingOrder(
                                          template,
                                        ),
                                        onRename: () =>
                                            _renameTemplate(
                                          template,
                                        ),
                                        onRemove: () =>
                                            _archiveTemplate(
                                          template,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),

            FutureBuilder<List<WholesaleStandingOrder>>(
              future: standingFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                        ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      friendlyAppError(snapshot.error!),
                    ),
                  );
                }

                final orders =
                    snapshot.data ?? const <WholesaleStandingOrder>[];

                final activeCount =
                    orders.where((order) => order.isActive).length;

                final pausedCount =
                    orders.where((order) => order.isPaused).length;

                final awaitingCount =
                    orders.where((order) => order.isProposed).length;

                final activeWithDates = orders
                    .where(
                      (order) =>
                          order.isActive &&
                          order.nextDueDate != null,
                    )
                    .toList()
                  ..sort(
                    (a, b) => a.nextDueDate!.compareTo(
                      b.nextDueDate!,
                    ),
                  );

                final nextDue = activeWithDates.isEmpty
                    ? null
                    : activeWithDates.first.nextDueDate;

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      16,
                      18,
                      120,
                    ),
                    children: [
                      _PremiumRecurringOrdersHero(
                        mode: 'standing',
                        businessName:
                            widget.account.displayName,
                        primaryCount: activeCount,
                        secondaryCount: pausedCount,
                        tertiaryCount: awaitingCount,
                        nextDue: nextDue,
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Standing orders',
                        style: TextStyle(
                          color: FarmColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Recurring requirements approved by HPJ. Every occurrence still receives a live capacity, price and credit check before submission.',
                        style: TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 9.6,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (orders.isEmpty)
                        const FarmEmptyState(
                          icon: Icons.event_repeat_outlined,
                          title: 'No standing orders',
                          message:
                              'Create one from a saved Repeat Order when your business has a regular weekly or monthly requirement.',
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final useTwo =
                                constraints.maxWidth >= 900;

                            const gap = 12.0;

                            final width = useTwo
                                ? (constraints.maxWidth - gap) / 2
                                : constraints.maxWidth;

                            return Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: orders
                                  .map(
                                    (order) => SizedBox(
                                      width: width,
                                      child:
                                          _PremiumStandingOrderCard(
                                        order: order,
                                        statusColor:
                                            _standingColor(
                                          order,
                                        ),
                                        dateLabel:
                                            _dateLabel(
                                          order.nextDueDate,
                                        ),
                                        onCreate: order.isActive
                                            ? () => _useItems(
                                                  items:
                                                      order.items,
                                                  standingOrderId:
                                                      order.id,
                                                  dispatchMethod:
                                                      order.dispatchMethod,
                                                  preferredDate:
                                                      order.nextDueDate,
                                                )
                                            : null,
                                        onPause: order.isActive
                                            ? () =>
                                                _changeStandingStatus(
                                                  order,
                                                  'paused',
                                                )
                                            : null,
                                        onResume: order.isPaused
                                            ? () =>
                                                _changeStandingStatus(
                                                  order,
                                                  'active',
                                                )
                                            : null,
                                        onCancel:
                                            order.isActive ||
                                                    order.isPaused
                                                ? () =>
                                                    _changeStandingStatus(
                                                      order,
                                                      'cancelled',
                                                    )
                                                : null,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumRecurringOrdersHero extends StatelessWidget {
  final String mode;
  final String businessName;
  final int primaryCount;
  final int secondaryCount;
  final int tertiaryCount;
  final DateTime? nextDue;

  const _PremiumRecurringOrdersHero({
    required this.mode,
    required this.businessName,
    required this.primaryCount,
    required this.secondaryCount,
    required this.tertiaryCount,
    required this.nextDue,
  });

  String _date(DateTime? value) {
    if (value == null) return 'None';

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final date = value.toLocal();

    return '${date.day} ${months[date.month - 1]}';
  }

  Widget _metric(
    String value,
    String label,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.12),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withOpacity(.16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(.72),
                fontSize: 8.7,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repeatMode = mode == 'repeat';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FarmColors.deepGreen,
            FarmColors.green,
            Color(0xFF4E8157),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            repeatMode
                ? 'REPEAT ORDERS'
                : 'STANDING ORDERS',
            style: const TextStyle(
              color: Color(0xFFCFE0CF),
              fontSize: 10.3,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            businessName.trim().isEmpty
                ? 'Regular purchasing'
                : businessName.trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            repeatMode
                ? 'Save a familiar basket, then reorder it using current HPJ availability and pricing.'
                : 'Manage recurring requirements while HPJ keeps each occurrence subject to live supply, capacity and credit checks.',
            style: TextStyle(
              color: Colors.white.withOpacity(.82),
              fontSize: 10.5,
              height: 1.38,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: repeatMode
                ? [
                    _metric(
                      '$primaryCount',
                      'Saved baskets',
                    ),
                    const SizedBox(width: 8),
                    _metric(
                      '$secondaryCount',
                      'Product lines',
                    ),
                    const SizedBox(width: 8),
                    _metric(
                      'LIVE',
                      'Price recheck',
                    ),
                  ]
                : [
                    _metric(
                      '$primaryCount',
                      'Active',
                    ),
                    const SizedBox(width: 8),
                    _metric(
                      '$secondaryCount',
                      'Paused',
                    ),
                    const SizedBox(width: 8),
                    _metric(
                      '$tertiaryCount',
                      'Awaiting HPJ',
                    ),
                  ],
          ),
          if (!repeatMode) ...[
            const SizedBox(height: 9),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(.14),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_outlined,
                    color: Color(0xFFE8C768),
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Next active requirement: ${_date(nextDue)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(.83),
                        fontSize: 9.4,
                        fontWeight: FontWeight.w800,
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

class _PremiumRepeatOrderCard extends StatelessWidget {
  final WholesaleOrderTemplate template;
  final VoidCallback onUse;
  final VoidCallback onStanding;
  final VoidCallback onRename;
  final VoidCallback onRemove;

  const _PremiumRepeatOrderCard({
    required this.template,
    required this.onUse,
    required this.onStanding,
    required this.onRename,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final preview = template.items
        .take(3)
        .map((item) => item.productName)
        .where((value) => value.trim().isNotEmpty)
        .join(' • ');

    return FarmCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: FarmColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bookmark_outline_rounded,
                  color: FarmColors.deepGreen,
                  size: 19,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  template.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F5),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: FarmColors.line,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${template.items.length} product line${template.items.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: FarmColors.deepGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 9,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 11),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onUse,
              icon: const Icon(
                Icons.shopping_cart_checkout,
                size: 17,
              ),
              label: const Text('Use Repeat Order'),
            ),
          ),

          const SizedBox(height: 7),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onStanding,
              icon: const Icon(
                Icons.event_repeat_rounded,
                size: 17,
              ),
              label: const Text('Make Standing Order'),
            ),
          ),

          const SizedBox(height: 4),

          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onRename,
                  child: const Text('Rename'),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: onRemove,
                  style: TextButton.styleFrom(
                    foregroundColor: FarmColors.danger,
                  ),
                  child: const Text('Remove'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumStandingOrderCard extends StatelessWidget {
  final WholesaleStandingOrder order;
  final Color statusColor;
  final String dateLabel;
  final VoidCallback? onCreate;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;

  const _PremiumStandingOrderCard({
    required this.order,
    required this.statusColor,
    required this.dateLabel,
    required this.onCreate,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final preview = order.items
        .take(3)
        .map((item) => item.productName)
        .where((value) => value.trim().isNotEmpty)
        .join(' • ');

    return FarmCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.event_repeat_rounded,
                  color: statusColor,
                  size: 19,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  order.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.09),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: statusColor.withOpacity(.16),
                  ),
                ),
                child: Text(
                  order.statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 8.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _PremiumStandingDetail(
                  label: 'Pattern',
                  value: order.frequencyLabel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PremiumStandingDetail(
                  label: 'Fulfilment',
                  value: order.dispatchMethodLabel,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _PremiumStandingDetail(
                  label: 'Product lines',
                  value: '${order.items.length}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PremiumStandingDetail(
                  label: 'Next requirement',
                  value: dateLabel,
                ),
              ),
            ],
          ),

          if (preview.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 9,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          if (order.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                order.notes,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 8.9,
                  height: 1.3,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          const SizedBox(height: 11),

          if (onCreate != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(
                  Icons.playlist_add_check_rounded,
                  size: 17,
                ),
                label: const Text('Create Next Request'),
              ),
            ),

          if (onPause != null || onResume != null || onCancel != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (onPause != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onPause,
                      child: const Text('Pause'),
                    ),
                  ),
                if (onResume != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onResume,
                      child: const Text('Resume'),
                    ),
                  ),
                if ((onPause != null || onResume != null) &&
                    onCancel != null)
                  const SizedBox(width: 8),
                if (onCancel != null)
                  Expanded(
                    child: TextButton(
                      onPressed: onCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: FarmColors.danger,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PremiumStandingDetail extends StatelessWidget {
  final String label;
  final String value;

  const _PremiumStandingDetail({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FarmColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 7.9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 9.3,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SOURCE SECTION: business_plan.dart
// ============================================================================
// HPJ PHASE 88 — BUSINESS PLANNING AHEAD
// Extracted from wholesale_management.dart without changing runtime behavior.

class _WholesalePlanningLineDraft {
  final Product product;
  String quantityText;
  DateTime? customNeedBy;

  _WholesalePlanningLineDraft({
    required this.product,
    required this.quantityText,
    this.customNeedBy,
  });
}

class WholesalePlanningAheadScreen extends StatefulWidget {
  final BusinessAccount account;
  final bool embedded;
  final String? initialForecastId;

  const WholesalePlanningAheadScreen({
    super.key,
    required this.account,
    this.embedded = false,
    this.initialForecastId,
  });

  @override
  State<WholesalePlanningAheadScreen> createState() =>
      _WholesalePlanningAheadScreenState();
}

class _WholesalePlanningAheadScreenState
    extends State<WholesalePlanningAheadScreen> {
  int refreshKey = 0;
  late Future<List<Product>> _planningProductsFuture;

  bool _showPlanningForm = false;
  bool _savingPlanning = false;
  int _planningStep = 0;

  final List<_WholesalePlanningLineDraft> _lines =
      <_WholesalePlanningLineDraft>[];
  List<WholesaleDemandForecast> _recentPlanningForecasts =
      <WholesaleDemandForecast>[];

  String _productQuery = '';
  String _notesText = '';
  String? _smartPlanningMessage;

  DateTime _needByDate = DateTime.now().add(
    const Duration(days: 14),
  );
  String _frequency = 'one_time';
  String _certainty = 'likely';

  @override
  void initState() {
    super.initState();
    _planningProductsFuture = _loadPlanningProducts();
    unawaited(_restorePlanningDraft());
  }

  String _unitFor(Product product) {
    final clean = (product.unit ?? '').trim();
    return clean.isEmpty ? 'unit' : clean;
  }

  String _simpleNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  int _cadenceDays(String frequency) {
    switch (frequency) {
      case 'weekly':
        return 7;
      case 'biweekly':
        return 14;
      case 'monthly':
        return 30;
      default:
        return 14;
    }
  }

  String _encodeDraftLines() {
    return _lines.map((line) {
      final customMs = line.customNeedBy?.millisecondsSinceEpoch ?? 0;
      return '${line.product.id}|${line.quantityText.trim()}|$customMs';
    }).join(';;');
  }

  List<List<String>> _decodeDraftLines(String? raw) {
    final clean = raw?.trim() ?? '';
    if (clean.isEmpty) return const <List<String>>[];

    return clean
        .split(';;')
        .map((entry) => entry.split('|'))
        .where((parts) => parts.length >= 3 && parts.first.trim().isNotEmpty)
        .toList();
  }

  Future<void> _restorePlanningDraft() async {
    final wasOpen =
        await HpjSmartLocalStore.readBool('wholesale_plan_open');
    if (wasOpen != true) return;

    final encodedLines =
        await HpjSmartLocalStore.readString('wholesale_plan_lines');
    final legacyProductId =
        await HpjSmartLocalStore.readString('wholesale_plan_product');
    final legacyQuantity =
        await HpjSmartLocalStore.readString('wholesale_plan_quantity');
    final notes = await HpjSmartLocalStore.readString('wholesale_plan_notes');
    final frequency =
        await HpjSmartLocalStore.readString('wholesale_plan_frequency');
    final certainty =
        await HpjSmartLocalStore.readString('wholesale_plan_certainty');
    final needByMs =
        await HpjSmartLocalStore.readInt('wholesale_plan_need_by');
    final savedStep =
        await HpjSmartLocalStore.readInt('wholesale_plan_step');

    List<Product> products;
    try {
      products = await _planningProductsFuture;
    } catch (_) {
      products = const <Product>[];
    }

    final decoded = _decodeDraftLines(encodedLines).toList();
    if (decoded.isEmpty && (legacyProductId ?? '').trim().isNotEmpty) {
      decoded.add(<String>[
        legacyProductId!.trim(),
        (legacyQuantity ?? '10').trim().isEmpty
            ? '10'
            : legacyQuantity!.trim(),
        '0',
      ]);
    }

    if (!mounted) return;

    setState(() {
      _showPlanningForm = true;
      _planningStep = (savedStep ?? 0).clamp(0, 2).toInt();
      _notesText = notes ?? '';

      if (const <String>['one_time', 'weekly', 'biweekly', 'monthly']
          .contains(frequency)) {
        _frequency = frequency!;
      }
      if (const <String>['tentative', 'likely', 'expected']
          .contains(certainty)) {
        _certainty = certainty!;
      }
      if (needByMs != null && needByMs > 0) {
        _needByDate = DateTime.fromMillisecondsSinceEpoch(needByMs);
      }

      _lines.clear();
      for (final parts in decoded) {
        final id = parts[0].trim();
        Product? product;
        for (final candidate in products) {
          if (candidate.id == id) {
            product = candidate;
            break;
          }
        }
        if (product == null) continue;

        final customMs = int.tryParse(parts[2].trim()) ?? 0;
        _lines.add(
          _WholesalePlanningLineDraft(
            product: product,
            quantityText: parts[1].trim().isEmpty ? '10' : parts[1].trim(),
            customNeedBy: customMs > 0
                ? DateTime.fromMillisecondsSinceEpoch(customMs)
                : null,
          ),
        );
      }

      if (_lines.isEmpty && _planningStep > 0) {
        _planningStep = 0;
      }
      _smartPlanningMessage =
          'Draft restored. HPJ kept your unfinished planning list on this device.';
    });
  }

  void _persistPlanningDraft() {
    unawaited(
      HpjSmartLocalStore.writeBool(
        'wholesale_plan_open',
        _showPlanningForm,
      ),
    );
    unawaited(
      HpjSmartLocalStore.writeString(
        'wholesale_plan_lines',
        _encodeDraftLines(),
      ),
    );
    unawaited(
      HpjSmartLocalStore.writeString(
        'wholesale_plan_notes',
        _notesText,
      ),
    );
    unawaited(
      HpjSmartLocalStore.writeString(
        'wholesale_plan_frequency',
        _frequency,
      ),
    );
    unawaited(
      HpjSmartLocalStore.writeString(
        'wholesale_plan_certainty',
        _certainty,
      ),
    );
    unawaited(
      HpjSmartLocalStore.writeInt(
        'wholesale_plan_need_by',
        _needByDate.millisecondsSinceEpoch,
      ),
    );
    unawaited(
      HpjSmartLocalStore.writeInt(
        'wholesale_plan_step',
        _planningStep,
      ),
    );
  }

  Future<void> _clearPlanningDraft() async {
    for (final key in const <String>[
      'wholesale_plan_open',
      'wholesale_plan_product',
      'wholesale_plan_quantity',
      'wholesale_plan_lines',
      'wholesale_plan_notes',
      'wholesale_plan_frequency',
      'wholesale_plan_certainty',
      'wholesale_plan_need_by',
      'wholesale_plan_step',
    ]) {
      await HpjSmartLocalStore.remove(key);
    }
  }

  void _startPlanning(List<WholesaleDemandForecast> active) {
    final sorted = List<WholesaleDemandForecast>.of(active)
      ..sort((a, b) {
        final aDate = a.updatedAt ?? a.createdAt ?? a.needByDate;
        final bDate = b.updatedAt ?? b.createdAt ?? b.needByDate;
        return bDate.compareTo(aDate);
      });

    setState(() {
      _showPlanningForm = true;
      _planningStep = 0;
      _lines.clear();
      _productQuery = '';
      _notesText = '';
      _frequency = 'one_time';
      _certainty = 'likely';
      _needByDate = DateTime.now().add(const Duration(days: 14));
      _smartPlanningMessage = null;
      _recentPlanningForecasts = sorted.take(6).toList();
    });

    unawaited(
      _clearPlanningDraft().then((_) async => _persistPlanningDraft()),
    );
  }

  void _closePlanning() {
    if (_savingPlanning) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _showPlanningForm = false;
      _planningStep = 0;
      _lines.clear();
      _productQuery = '';
      _smartPlanningMessage = null;
    });
    unawaited(_clearPlanningDraft());
  }

  int _lineIndex(String productId) {
    return _lines.indexWhere((line) => line.product.id == productId);
  }

  WholesaleDemandForecast? _recentForProduct(Product product) {
    for (final forecast in _recentPlanningForecasts) {
      final sameId = forecast.productId != null &&
          forecast.productId!.isNotEmpty &&
          forecast.productId == product.id;
      final sameName = forecast.productName.trim().toLowerCase() ==
          product.name.trim().toLowerCase();
      if (sameId || sameName) return forecast;
    }
    return null;
  }

  void _addProduct(Product product) {
    if (_lineIndex(product.id) >= 0) return;
    if (_lines.length >= 25) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A Planning Ahead list can contain up to 25 products.'),
        ),
      );
      return;
    }

    final recent = _recentForProduct(product);
    final wasEmpty = _lines.isEmpty;

    setState(() {
      _lines.add(
        _WholesalePlanningLineDraft(
          product: product,
          quantityText: recent == null ? '10' : _simpleNumber(recent.quantity),
        ),
      );

      if (wasEmpty && recent != null) {
        if (const <String>['one_time', 'weekly', 'biweekly', 'monthly']
            .contains(recent.frequency)) {
          _frequency = recent.frequency;
        }
        if (const <String>['tentative', 'likely', 'expected']
            .contains(recent.certainty)) {
          _certainty = recent.certainty;
        }
        _needByDate = DateTime.now().add(
          Duration(days: _cadenceDays(_frequency)),
        );
      }

      _smartPlanningMessage = recent == null
          ? '${_lines.length} item${_lines.length == 1 ? '' : 's'} selected.'
          : 'HPJ used your recent ${product.name} quantity as a starting point.';
    });
    _persistPlanningDraft();
  }

  void _removeProduct(Product product) {
    setState(() {
      _lines.removeWhere((line) => line.product.id == product.id);
      _smartPlanningMessage = _lines.isEmpty
          ? null
          : '${_lines.length} item${_lines.length == 1 ? '' : 's'} selected.';
    });
    _persistPlanningDraft();
  }

  void _toggleProduct(Product product) {
    _lineIndex(product.id) >= 0 ? _removeProduct(product) : _addProduct(product);
  }

  void _applyRecentPlanning(
    WholesaleDemandForecast forecast,
    List<Product> products,
  ) {
    Product? product;
    for (final candidate in products) {
      final sameId = forecast.productId != null &&
          forecast.productId!.isNotEmpty &&
          candidate.id == forecast.productId;
      final sameName = candidate.name.trim().toLowerCase() ==
          forecast.productName.trim().toLowerCase();
      if (sameId || sameName) {
        product = candidate;
        break;
      }
    }

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'That recent product is not currently available for planning.',
          ),
        ),
      );
      return;
    }
    _addProduct(product);
  }

  bool _validateLines() {
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose at least one product first.')),
      );
      return false;
    }

    for (final line in _lines) {
      final quantity = double.tryParse(line.quantityText.trim());
      if (quantity == null || quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enter a valid quantity for ${line.product.name}.'),
          ),
        );
        return false;
      }
    }
    return true;
  }

  void _planningBack() {
    if (_savingPlanning || _planningStep <= 0) return;
    FocusScope.of(context).unfocus();
    setState(() => _planningStep--);
    _persistPlanningDraft();
  }

  void _planningContinue() {
    if (_savingPlanning) return;
    if (_planningStep == 0 && _lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose at least one product first.')),
      );
      return;
    }
    if (_planningStep == 1 && !_validateLines()) return;

    FocusScope.of(context).unfocus();
    if (_planningStep < 2) {
      setState(() => _planningStep++);
      _persistPlanningDraft();
    }
  }

  void _refresh() {
    setState(() => refreshKey++);
  }

  Future<List<Product>> _loadPlanningProducts() async {
    final products = await fetchAllProducts();
    final eligible = products
        .where((product) => product.isApproved && !product.isHidden)
        .toList()
      ..sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    return eligible;
  }

  void _reloadPlanningProducts() {
    setState(() {
      _planningProductsFuture = _loadPlanningProducts();
    });
  }

  String _planningDateLabel(DateTime date) {
    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  DateTime _lineNeedBy(_WholesalePlanningLineDraft line) {
    return line.customNeedBy ?? _needByDate;
  }

  void _setNeedByDays(int days) {
    final now = DateTime.now();
    setState(() {
      _needByDate = DateTime(now.year, now.month, now.day)
          .add(Duration(days: days));
    });
    _persistPlanningDraft();
  }

  Future<void> _chooseLineDate(_WholesalePlanningLineDraft line) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = _lineNeedBy(line);

    final chosen = await showDatePicker(
      context: context,
      initialDate: current.isBefore(today) ? today : current,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
      helpText: 'When will you need ${line.product.name}?',
    );
    if (!mounted || chosen == null) return;

    setState(() {
      final sameAsShared = chosen.year == _needByDate.year &&
          chosen.month == _needByDate.month &&
          chosen.day == _needByDate.day;
      line.customNeedBy = sameAsShared ? null : chosen;
    });
    _persistPlanningDraft();
  }

  Future<void> _savePlanningRequirement() async {
    if (_savingPlanning || !_validateLines()) return;

    final items = <WholesaleDemandPlanItem>[
      for (final line in _lines)
        WholesaleDemandPlanItem(
          productId: line.product.id,
          productName: line.product.name,
          category: line.product.category,
          quantity: double.parse(line.quantityText.trim()),
          unit: _unitFor(line.product),
          needByDate: _lineNeedBy(line),
        ),
    ];

    setState(() => _savingPlanning = true);

    try {
      final saved = await createWholesaleDemandForecastBatch(
        items: items,
        frequency: _frequency,
        certainty: _certainty,
        notes: _notesText.trim(),
      );
      if (!mounted) return;

      setState(() {
        _showPlanningForm = false;
        _savingPlanning = false;
        _planningStep = 0;
        _lines.clear();
        _productQuery = '';
        _notesText = '';
        _frequency = 'one_time';
        _certainty = 'likely';
        _smartPlanningMessage = null;
        _needByDate = DateTime.now().add(const Duration(days: 14));
        refreshKey++;
      });

      await _clearPlanningDraft();
      if (!mounted) return;

      final planMore = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _WholesalePlanningBatchSavedSheet(forecasts: saved),
      );
      if (!mounted) return;
      if (planMore == true) {
        _startPlanning(<WholesaleDemandForecast>[
          ...saved,
          ..._recentPlanningForecasts,
        ]);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _savingPlanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  Widget _planningProgress() {
    return Row(
      children: [
        for (var index = 0; index < 3; index++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 4,
              decoration: BoxDecoration(
                color: index <= _planningStep
                    ? FarmColors.primary
                    : FarmColors.line,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          if (index < 2) const SizedBox(width: 5),
        ],
      ],
    );
  }

  Widget _selectedMiniCard(_WholesalePlanningLineDraft line) {
    final product = line.product;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
      decoration: BoxDecoration(
        color: FarmColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FarmColors.line),
      ),
      child: Row(
        children: [
          HpjProductThumb(
            product: product,
            productName: product.name,
            size: 46,
            radius: 10,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 10.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.category} • ${_unitFor(product)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove ${product.name}',
            visualDensity: VisualDensity.compact,
            onPressed: _savingPlanning ? null : () => _removeProduct(product),
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _lineEditor(_WholesalePlanningLineDraft line) {
    final product = line.product;
    final hasCustomDate = line.customNeedBy != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FarmColors.card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              HpjProductThumb(
                product: product,
                productName: product.name,
                size: 56,
                radius: 12,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${product.category} • ${_unitFor(product)}',
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: _savingPlanning ? null : () => _removeProduct(product),
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: ValueKey('plan-qty-${product.id}'),
            initialValue: line.quantityText,
            enabled: !_savingPlanning,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Quantity',
              suffixText: _unitFor(product),
            ),
            onChanged: (value) {
              line.quantityText = value;
              _persistPlanningDraft();
            },
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _savingPlanning ? null : () => _chooseLineDate(line),
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: Text(
                    _planningDateLabel(_lineNeedBy(line)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (hasCustomDate) ...[
                const SizedBox(width: 6),
                TextButton(
                  onPressed: _savingPlanning
                      ? null
                      : () {
                          setState(() => line.customNeedBy = null);
                          _persistPlanningDraft();
                        },
                  child: const Text('Use shared'),
                ),
              ],
            ],
          ),
          if (hasCustomDate)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Custom date for this item',
                style: TextStyle(
                  color: FarmColors.primary,
                  fontSize: 9.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _reviewLine(_WholesalePlanningLineDraft line) {
    final product = line.product;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: FarmColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FarmColors.line),
      ),
      child: Row(
        children: [
          HpjProductThumb(
            product: product,
            productName: product.name,
            size: 48,
            radius: 11,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 10.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${line.quantityText} ${_unitFor(product)} • ${_planningDateLabel(_lineNeedBy(line))}',
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 9.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _planningForm() {
    return FutureBuilder<List<Product>>(
      future: _planningProductsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return FarmCard(
            padding: const EdgeInsets.all(18),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return FarmCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                FarmEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Products could not load',
                  message: friendlyAppError(snapshot.error!),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _reloadPlanningProducts,
                    child: const Text('Try Again'),
                  ),
                ),
              ],
            ),
          );
        }

        final products = snapshot.data ?? const <Product>[];
        if (products.isEmpty) {
          return FarmCard(
            padding: const EdgeInsets.all(18),
            child: const FarmEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No products available for planning',
              message:
                  'HPJ needs at least one approved product before a future requirement can be created.',
            ),
          );
        }

        final query = _productQuery.trim().toLowerCase();
        final filtered = products.where((product) {
          if (query.isEmpty) return true;
          return product.name.toLowerCase().contains(query) ||
              product.category.toLowerCase().contains(query) ||
              hpjSmartProductMatchesSearch(product, _productQuery);
        }).toList()
          ..sort(
            (a, b) => hpjSmartProductSearchScore(b, _productQuery)
                .compareTo(hpjSmartProductSearchScore(a, _productQuery)),
          );
        final visibleFiltered = filtered.take(12).toList();

        return FarmCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Step ${_planningStep + 1} of 3',
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  if (_lines.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: FarmColors.primarySoft,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${_lines.length} selected',
                        style: const TextStyle(
                          color: FarmColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: _savingPlanning ? null : _closePlanning,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              _planningProgress(),
              const SizedBox(height: 17),

              if (_planningStep == 0) ...[
                const Text(
                  'What will your business need?',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose one or more products. Set quantities and dates on the next step.',
                  style: TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 10.8,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),

                if (_lines.isNotEmpty) ...[
                  const Text(
                    'Selected products',
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontSize: 10.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  for (final line in _lines) ...[
                    _selectedMiniCard(line),
                    const SizedBox(height: 7),
                  ],
                  const SizedBox(height: 6),
                ],

                if (_recentPlanningForecasts.isNotEmpty) ...[
                  const Text(
                    'Repeat a recent need',
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontSize: 10.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  SizedBox(
                    height: 106,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentPlanningForecasts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final forecast = _recentPlanningForecasts[index];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _savingPlanning
                                ? null
                                : () => _applyRecentPlanning(forecast, products),
                            child: Ink(
                              width: 116,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: FarmColors.background,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: FarmColors.line),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  HpjProductThumb(
                                    productId: forecast.productId,
                                    productName: forecast.productName,
                                    size: 60,
                                    radius: 12,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    forecast.productName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: FarmColors.ink,
                                      fontSize: 10.2,
                                      fontWeight: FontWeight.w900,
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
                  const SizedBox(height: 13),
                ],

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Browse product pictures'),
                    onPressed: _savingPlanning
                        ? null
                        : () async {
                            final product = await showHpjProductPicturePicker(
                              context,
                              title: 'Add a product to your plan',
                              products: products,
                            );
                            if (!mounted || product == null) return;
                            _addProduct(product);
                          },
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: _productQuery,
                  enabled: !_savingPlanning,
                  decoration: const InputDecoration(
                    labelText: 'Find product',
                    hintText: 'Search HPJ products',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (value) => setState(() => _productQuery = value),
                ),
                const SizedBox(height: 9),
                Container(
                  constraints: const BoxConstraints(maxHeight: 260),
                  decoration: BoxDecoration(
                    color: FarmColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FarmColors.line),
                  ),
                  child: visibleFiltered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(15),
                          child: Text(
                            'No matching products.',
                            style: TextStyle(
                              color: FarmColors.mutedText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          primary: false,
                          itemCount: visibleFiltered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final product = visibleFiltered[index];
                            final selected = _lineIndex(product.id) >= 0;
                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              leading: HpjProductThumb(
                                product: product,
                                productName: product.name,
                                size: 52,
                                radius: 12,
                              ),
                              title: Text(
                                product.name,
                                style: const TextStyle(
                                  color: FarmColors.ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                product.category.trim().isEmpty
                                    ? 'HPJ product'
                                    : product.category,
                              ),
                              trailing: Checkbox(
                                value: selected,
                                onChanged: _savingPlanning
                                    ? null
                                    : (_) => _toggleProduct(product),
                              ),
                              onTap: _savingPlanning
                                  ? null
                                  : () => _toggleProduct(product),
                            );
                          },
                        ),
                ),
                if (_smartPlanningMessage != null) ...[
                  const SizedBox(height: 9),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4EC),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      _smartPlanningMessage!,
                      style: const TextStyle(
                        color: Color(0xFF5E6C64),
                        fontSize: 9.8,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ] else if (_planningStep == 1) ...[
                const Text(
                  'How much, and when?',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Set a shared date, then change any item that needs a different date.',
                  style: TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 10.8,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 13),
                const Text(
                  'Shared need-by date',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _planningDateLabel(_needByDate),
                  style: const TextStyle(
                    color: FarmColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final days in const <int>[7, 14, 30, 60, 90])
                      ChoiceChip(
                        label: Text('$days days'),
                        selected: _needByDate
                                .difference(
                                  DateTime(
                                    DateTime.now().year,
                                    DateTime.now().month,
                                    DateTime.now().day,
                                  ),
                                )
                                .inDays ==
                            days,
                        onSelected: _savingPlanning
                            ? null
                            : (_) => _setNeedByDays(days),
                      ),
                  ],
                ),
                const SizedBox(height: 15),
                for (final line in _lines) ...[
                  _lineEditor(line),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _savingPlanning
                        ? null
                        : () {
                            setState(() => _planningStep = 0);
                            _persistPlanningDraft();
                          },
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Add another item'),
                  ),
                ),
              ] else ...[
                const Text(
                  'Review your planning list',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_lines.length} product${_lines.length == 1 ? '' : 's'} will be saved as one planning list while HPJ keeps each item separate for supply matching.',
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 10.8,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 13),
                for (final line in _lines) ...[
                  _reviewLine(line),
                  const SizedBox(height: 7),
                ],
                const SizedBox(height: 8),
                const Text(
                  'Frequency',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final option in const <MapEntry<String, String>>[
                      MapEntry('one_time', 'One time'),
                      MapEntry('weekly', 'Weekly'),
                      MapEntry('biweekly', 'Every 2 weeks'),
                      MapEntry('monthly', 'Monthly'),
                    ])
                      ChoiceChip(
                        label: Text(option.value),
                        selected: _frequency == option.key,
                        onSelected: _savingPlanning
                            ? null
                            : (_) {
                                setState(() => _frequency = option.key);
                                _persistPlanningDraft();
                              },
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'How certain is this need?',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final option in const <MapEntry<String, String>>[
                      MapEntry('tentative', 'Tentative'),
                      MapEntry('likely', 'Likely'),
                      MapEntry('expected', 'Expected'),
                    ])
                      ChoiceChip(
                        label: Text(option.value),
                        selected: _certainty == option.key,
                        onSelected: _savingPlanning
                            ? null
                            : (_) {
                                setState(() => _certainty = option.key);
                                _persistPlanningDraft();
                              },
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  initialValue: _notesText,
                  enabled: !_savingPlanning,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Anything HPJ should know about this planning list?',
                  ),
                  onChanged: (value) {
                    _notesText = value;
                    _persistPlanningDraft();
                  },
                ),
              ],

              const SizedBox(height: 18),
              Row(
                children: [
                  if (_planningStep > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _savingPlanning ? null : _planningBack,
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 9),
                  ],
                  Expanded(
                    flex: _planningStep > 0 ? 2 : 1,
                    child: _planningStep < 2
                        ? ElevatedButton(
                            onPressed:
                                _savingPlanning ? null : _planningContinue,
                            child: Text(
                              _planningStep == 0
                                  ? _lines.isEmpty
                                      ? 'Choose products'
                                      : 'Continue with ${_lines.length} item${_lines.length == 1 ? '' : 's'}'
                                  : 'Continue',
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _savingPlanning
                                ? null
                                : _savePlanningRequirement,
                            child: Text(
                              _savingPlanning
                                  ? 'Saving...'
                                  : 'Save ${_lines.length} Planned Item${_lines.length == 1 ? '' : 's'}',
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('Planning Ahead')),
      body: FarmPage(
        child: FutureBuilder<List<WholesaleDemandForecast>>(
          key: ValueKey('wholesale-planning-$refreshKey'),
          future: fetchMyWholesaleDemandForecasts(includeCancelled: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError && !snapshot.hasData) {
              return RefreshIndicator(
                onRefresh: () async => _refresh(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                  children: [
                    FarmCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          FarmEmptyState(
                            icon: Icons.event_busy_outlined,
                            title: 'Plans could not load',
                            message: friendlyAppError(snapshot.error!),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _refresh,
                              child: const Text('Try Again'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            final forecasts =
                snapshot.data ?? const <WholesaleDemandForecast>[];

            final allActive = forecasts.where((item) => item.isActive).toList()
              ..sort((a, b) => a.needByDate.compareTo(b.needByDate));

            final requestedForecastId =
                widget.initialForecastId?.trim() ?? '';

            final focusedForecasts = requestedForecastId.isEmpty
                ? const <WholesaleDemandForecast>[]
                : allActive
                    .where((item) => item.id.trim() == requestedForecastId)
                    .toList();

            final exactForecastFound = focusedForecasts.isNotEmpty;
            final active = exactForecastFound ? focusedForecasts : allActive;
            final needsReview =
                active.where(_wholesaleForecastNeedsReview).toList();

            final totalNeedsReview =
                allActive.where(_wholesaleForecastNeedsReview).length;

            final recurringCount = allActive
                .where((item) => item.frequency != 'one_time')
                .length;

            final expectedCount = allActive
                .where((item) => item.certainty == 'expected')
                .length;

            final securedCount = allActive
                .where((item) => item.isReserved || item.isMatched)
                .length;

            final nextNeed = allActive.isEmpty
                ? null
                : allActive.first.needByDate;

            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
                children: [
                  _PremiumWholesalePlanningHero(
                    businessName: widget.account.displayName,
                    activeCount: allActive.length,
                    recurringCount: recurringCount,
                    reviewCount: totalNeedsReview,
                    securedCount: securedCount,
                    expectedCount: expectedCount,
                    nextNeed: nextNeed,
                    onAddPlan: _savingPlanning
                        ? null
                        : () {
                            _showPlanningForm
                                ? _closePlanning()
                                : _startPlanning(allActive);
                          },
                    formOpen: _showPlanningForm,
                  ),
                  if (_showPlanningForm) ...[
                    const SizedBox(height: 12),
                    _planningForm(),
                  ],
                  const SizedBox(height: 18),

                  if (requestedForecastId.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: exactForecastFound
                            ? FarmColors.primarySoft
                            : const Color(0xFFFFF7E8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: exactForecastFound
                              ? FarmColors.primary.withOpacity(0.20)
                              : FarmColors.warning.withOpacity(0.28),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            exactForecastFound
                                ? Icons.notifications_active_outlined
                                : Icons.info_outline_rounded,
                            size: 18,
                            color: exactForecastFound
                                ? FarmColors.primary
                                : FarmColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              exactForecastFound
                                  ? 'Opened from your notification. Showing the related planned need.'
                                  : 'That planned need is no longer active. Showing your current planning list instead.',
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 10,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Future purchasing needs',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Keep quantities and dates current so HPJ can prepare sourcing early.',
                              style: TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 9.6,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (active.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: FarmColors.primarySoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${active.length} active',
                            style: const TextStyle(
                              color: FarmColors.deepGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),

                  if (needsReview.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: FarmColors.warning.withOpacity(.20),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.schedule_outlined,
                            color: FarmColors.warning,
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${needsReview.length} planned need${needsReview.length == 1 ? '' : 's'} need a quick review. Confirm that they are still current or update them before HPJ plans against old information.',
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 9.8,
                                height: 1.38,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  if (active.isEmpty)
                    FarmCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.event_note_outlined,
                            size: 30,
                            color: FarmColors.primary,
                          ),
                          const SizedBox(height: 9),
                          const Text(
                            'Nothing planned yet',
                            style: TextStyle(
                              color: FarmColors.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Add what you expect to need and HPJ can prepare farm supply ahead of time.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 10.5,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _savingPlanning
                                ? null
                                : () => _startPlanning(allActive),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Plan Future Needs'),
                          ),
                        ],
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final useTwoColumns =
                            constraints.maxWidth >= 900;
                        const gap = 12.0;
                        final width = useTwoColumns
                            ? (constraints.maxWidth - gap) / 2
                            : constraints.maxWidth;

                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: active
                              .map(
                                (forecast) => SizedBox(
                                  width: width,
                                  child: _WholesalePlanningSimpleCard(
                                    forecast: forecast,
                                    onChanged: _refresh,
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PremiumWholesalePlanningHero extends StatelessWidget {
  final String businessName;
  final int activeCount;
  final int recurringCount;
  final int reviewCount;
  final int securedCount;
  final int expectedCount;
  final DateTime? nextNeed;
  final VoidCallback? onAddPlan;
  final bool formOpen;

  const _PremiumWholesalePlanningHero({
    required this.businessName,
    required this.activeCount,
    required this.recurringCount,
    required this.reviewCount,
    required this.securedCount,
    required this.expectedCount,
    required this.nextNeed,
    required this.onAddPlan,
    required this.formOpen,
  });

  Widget _metric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: const Color(0xFFE8C768),
              size: 17,
            ),
            const SizedBox(height: 7),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(.72),
                fontSize: 8.7,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanName = businessName.trim().isEmpty
        ? 'Business planning'
        : businessName.trim();

    final nextNeedText = nextNeed == null
        ? 'No date yet'
        : _wholesaleSimpleDate(nextNeed!);

    if (hpjUseMobileAppPresentation(context)) {
      return _HpjBusinessMobileHeaderCard(
        icon: Icons.event_note_outlined,
        eyebrow: 'PLANNING AHEAD',
        title: cleanName,
        subtitle:
            'Share future demand early so HPJ can prepare the right Jamaican supply.',
        metrics: <_HpjBusinessMobileMetricData>[
          _HpjBusinessMobileMetricData(
            value: '$activeCount',
            label: 'Active',
          ),
          _HpjBusinessMobileMetricData(
            value: '$recurringCount',
            label: 'Recurring',
          ),
          _HpjBusinessMobileMetricData(
            value: '$reviewCount',
            label: 'Review',
            warning: reviewCount > 0,
          ),
          _HpjBusinessMobileMetricData(
            value: nextNeedText,
            label: 'Next need',
          ),
        ],
        onAction: formOpen ? null : onAddPlan,
        actionLabel: formOpen ? null : 'Add future need',
        actionIcon: Icons.add_rounded,
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FarmColors.deepGreen,
            FarmColors.green,
            Color(0xFF4E8157),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: FarmColors.deepGreen.withOpacity(.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
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
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.13),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(.18)),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PLANNING AHEAD',
                      style: TextStyle(
                        color: Colors.white.withOpacity(.72),
                        fontSize: 10.3,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .9,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cleanName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.11),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(.15)),
                ),
                child: const Text(
                  'NOT AN ORDER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8.2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Share expected demand early so HPJ can prepare Jamaican farm supply, procurement and fulfilment before you place an order.',
            style: TextStyle(
              color: Colors.white.withOpacity(.84),
              fontSize: 10.8,
              height: 1.42,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _metric(
                icon: Icons.event_note_outlined,
                value: '$activeCount',
                label: 'Active needs',
              ),
              const SizedBox(width: 8),
              _metric(
                icon: Icons.repeat_rounded,
                value: '$recurringCount',
                label: 'Recurring',
              ),
              const SizedBox(width: 8),
              _metric(
                icon: reviewCount > 0
                    ? Icons.warning_amber_rounded
                    : Icons.verified_outlined,
                value: '$reviewCount',
                label: 'Need review',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _metric(
                icon: Icons.hub_outlined,
                value: '$securedCount',
                label: 'Matched / reserved',
              ),
              const SizedBox(width: 8),
              _metric(
                icon: Icons.task_alt_outlined,
                value: '$expectedCount',
                label: 'Expected',
              ),
              const SizedBox(width: 8),
              _metric(
                icon: Icons.schedule_outlined,
                value: nextNeedText,
                label: 'Next need',
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAddPlan,
              icon: Icon(
                formOpen ? Icons.close_rounded : Icons.add_rounded,
              ),
              label: Text(
                formOpen ? 'Close Planning Form' : 'Add Planning List',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: FarmColors.deepGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WholesalePlanningBatchSavedSheet extends StatelessWidget {
  final List<WholesaleDemandForecast> forecasts;

  const _WholesalePlanningBatchSavedSheet({required this.forecasts});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    DateTime? earliest;
    for (final forecast in forecasts) {
      if (earliest == null || forecast.needByDate.isBefore(earliest)) {
        earliest = forecast.needByDate;
      }
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
      child: Container(
        decoration: const BoxDecoration(
          color: FarmColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: FarmColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'PLANNING LIST SAVED',
              style: TextStyle(
                color: FarmColors.success,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${forecasts.length} planned item${forecasts.length == 1 ? '' : 's'} shared with HPJ.',
              style: const TextStyle(
                color: FarmColors.ink,
                fontSize: 20,
                height: 1.08,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (earliest != null) ...[
              const SizedBox(height: 5),
              Text(
                'Earliest need: ${_wholesaleSimpleDate(earliest)}',
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: forecasts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 7),
                itemBuilder: (context, index) {
                  final forecast = forecasts[index];
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: FarmColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: FarmColors.line),
                    ),
                    child: Row(
                      children: [
                        HpjProductThumb(
                          productId: forecast.productId,
                          productName: forecast.productName,
                          size: 48,
                          radius: 11,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                forecast.productName,
                                style: const TextStyle(
                                  color: FarmColors.ink,
                                  fontSize: 10.8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${forecast.formattedQuantity} • ${_wholesaleSimpleDate(forecast.needByDate)}',
                                style: const TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 9.6,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.check_circle_rounded,
                          color: FarmColors.success,
                          size: 20,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Done'),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Plan More'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WholesalePlanningValueSheet
    extends StatelessWidget {
  final String productName;
  final double quantity;
  final String unit;
  final DateTime needByDate;
  final String frequency;
  final String certainty;

  const _WholesalePlanningValueSheet({
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.needByDate,
    required this.frequency,
    required this.certainty,
  });

  String get quantityLabel {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toStringAsFixed(0);
    }

    return quantity.toStringAsFixed(1);
  }

  String get frequencyLabel {
    switch (frequency) {
      case 'weekly':
        return 'Weekly';
      case 'biweekly':
        return 'Every 2 weeks';
      case 'monthly':
        return 'Monthly';
      default:
        return 'One time';
    }
  }

  String get certaintyLabel {
    switch (certainty) {
      case 'expected':
        return 'Expected';
      case 'tentative':
        return 'Tentative';
      default:
        return 'Likely';
    }
  }

  int get noticeDays {
    final now = DateTime.now();
    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );
    final need = DateTime(
      needByDate.year,
      needByDate.month,
      needByDate.day,
    );

    final days = need.difference(today).inDays;

    return days < 0 ? 0 : days;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.88,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: FarmColors.card,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(26),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          18,
          14,
          18,
          12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: FarmColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HpjProductThumb(
                      productName: productName,
                      size: 76,
                      radius: 16,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'PLANNED NEED SAVED',
                      style: TextStyle(
                        color: FarmColors.success,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      noticeDays > 0
                          ? 'HPJ now has $noticeDays day${noticeDays == 1 ? '' : 's'} to prepare.'
                          : 'HPJ has your planned need.',
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 20,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FarmColors.background,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: FarmColors.line,
                        ),
                      ),
                      child: Column(
                        children: [
                          _WholesaleValueRow(
                            label: 'Product',
                            value: productName,
                          ),
                          _WholesaleValueRow(
                            label: 'Quantity',
                            value: '$quantityLabel $unit',
                          ),
                          _WholesaleValueRow(
                            label: 'Need by',
                            value: _wholesaleSimpleDate(needByDate),
                          ),
                          _WholesaleValueRow(
                            label: 'Pattern',
                            value: '$frequencyLabel • $certaintyLabel',
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pop(false),
                    child: const Text('Done'),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).pop(true),
                    child: const Text('Plan Another'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WholesaleValueRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const _WholesaleValueRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 6,
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 76,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 10.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1),
      ],
    );
  }
}

class _WholesaleSelectedPlanningProduct extends StatelessWidget {
  final Product product;
  final String unit;
  final VoidCallback? onChange;

  const _WholesaleSelectedPlanningProduct({
    required this.product,
    required this.unit,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FarmColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: FarmColors.line,
        ),
      ),
      child: Row(
        children: [
          HpjProductThumb(
            product: product,
            productName: product.name,
            size: 62,
            radius: 13,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.category} • $unit',
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 10.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (onChange != null)
            TextButton(
              onPressed: onChange,
              child: const Text(
                'Change',
              ),
            ),
        ],
      ),
    );
  }
}

// =====================================================
// SIMPLE FORECAST CARD
// =====================================================

class _WholesalePlanningSimpleCard extends StatelessWidget {
  final WholesaleDemandForecast forecast;
  final VoidCallback onChanged;

  const _WholesalePlanningSimpleCard({
    required this.forecast,
    required this.onChanged,
  });

  String _date(DateTime date) {
    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _confirmStillNeeded(BuildContext context) async {
    try {
      await confirmWholesaleDemandForecastCurrent(forecast);
      onChanged();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${forecast.productName} confirmed as still needed.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  Future<void> _review(BuildContext context) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WholesaleForecastReviewSheet(
        forecast: forecast,
      ),
    );

    if (changed == true) onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final needsReview = _wholesaleForecastNeedsReview(forecast);
    final daysToNeed = _wholesaleForecastDaysToNeed(forecast);

    final dueMessage = daysToNeed < 0
        ? 'Need date passed'
        : daysToNeed == 0
            ? 'Needed today'
            : daysToNeed <= 7
                ? 'Needed in $daysToNeed day${daysToNeed == 1 ? '' : 's'}'
                : _wholesaleForecastFreshnessLabel(forecast);

    final statusLabel = needsReview
        ? 'Review'
        : forecast.isReserved
            ? 'Supply reserved'
            : forecast.isMatched
                ? 'Supply matched'
                : 'Needs supply';

    final statusColor = needsReview
        ? FarmColors.warning
        : forecast.isReserved
            ? FarmColors.success
            : FarmColors.primary;

    return FarmCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HpjProductThumb(
                productId: forecast.productId,
                productName: forecast.productName,
                size: 68,
                radius: 14,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      forecast.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 15,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      forecast.formattedQuantity,
                      style: const TextStyle(
                        color: FarmColors.deepGreen,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: statusColor.withOpacity(.18),
                        ),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _PremiumPlanningDetail(
                  icon: Icons.calendar_today_outlined,
                  label: 'Need by',
                  value: _date(forecast.needByDate),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PremiumPlanningDetail(
                  icon: Icons.repeat_rounded,
                  label: 'Pattern',
                  value: forecast.frequencyLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PremiumPlanningDetail(
                  icon: Icons.analytics_outlined,
                  label: 'Confidence',
                  value: forecast.certaintyLabel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PremiumPlanningDetail(
                  icon: Icons.schedule_outlined,
                  label: 'Timing',
                  value: dueMessage,
                ),
              ),
            ],
          ),

          if (needsReview) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E9),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: FarmColors.warning.withOpacity(.20),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: FarmColors.warning,
                    size: 17,
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'HPJ needs a quick confirmation that this future requirement is still current.',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 9.1,
                        height: 1.32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (forecast.isForecast) ...[
            const SizedBox(height: 11),
            if (needsReview && daysToNeed >= 0)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.check_rounded,
                        size: 17,
                      ),
                      label: const Text('Still Needed'),
                      onPressed: () => _confirmStillNeeded(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                      ),
                      onPressed: () => _review(context),
                      label: const Text('Review'),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _review(context),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(needsReview ? 'Review Plan' : 'Edit Plan'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PremiumPlanningDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PremiumPlanningDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F5),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: FarmColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: FarmColors.deepGreen,
            size: 15,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 7.9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 9.3,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
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

class _WholesaleForecastReviewSheet
    extends StatefulWidget {
  final WholesaleDemandForecast forecast;

  const _WholesaleForecastReviewSheet({
    required this.forecast,
  });

  @override
  State<_WholesaleForecastReviewSheet>
      createState() =>
          _WholesaleForecastReviewSheetState();
}

class _WholesaleForecastReviewSheetState
    extends State<_WholesaleForecastReviewSheet> {
  late final TextEditingController
      quantityController;
  late final TextEditingController
      notesController;

  late DateTime needByDate;
  late String frequency;
  late String certainty;

  bool saving = false;
  bool cancelling = false;

  WholesaleDemandForecast get forecast =>
      widget.forecast;

  @override
  void initState() {
    super.initState();

    quantityController = TextEditingController(
      text: forecast.quantity ==
              forecast.quantity.roundToDouble()
          ? forecast.quantity.toStringAsFixed(0)
          : forecast.quantity.toStringAsFixed(1),
    );

    notesController = TextEditingController(
      text: forecast.notes,
    );

    needByDate = forecast.needByDate;
    frequency = forecast.frequency;
    certainty = forecast.certainty;
  }

  @override
  void dispose() {
    quantityController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate:
          needByDate.isBefore(now)
              ? now.add(
                  const Duration(days: 7),
                )
              : needByDate,
      firstDate: now,
      lastDate: now.add(
        const Duration(days: 730),
      ),
    );

    if (!mounted || selected == null) return;

    setState(() {
      needByDate = selected;
    });
  }

  Future<void> _save() async {
    if (saving || cancelling) return;

    final quantity = double.tryParse(
      quantityController.text.trim(),
    );

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid quantity.',
          ),
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      await updateWholesaleDemandForecast(
        forecast: forecast,
        productId: forecast.productId,
        productName: forecast.productName,
        category: forecast.category,
        quantity: quantity,
        unit: forecast.unit,
        needByDate: needByDate,
        frequency: frequency,
        certainty: certainty,
        notes: notesController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyAppError(error),
          ),
        ),
      );
    }
  }

  Future<void> _cancel() async {
    if (saving || cancelling) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Cancel this future need?',
          ),
          content: Text(
            '${forecast.productName} will be removed from active Planning Ahead.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext)
                      .pop(false),
              child: const Text('Keep'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext)
                      .pop(true),
              child: const Text(
                'Cancel requirement',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      cancelling = true;
    });

    try {
      await cancelWholesaleDemandForecast(
        forecast.id,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        cancelling = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyAppError(error),
          ),
        ),
      );
    }
  }

  String _dateLabel(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final busy = saving || cancelling;

    return AnimatedPadding(
      duration:
          const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: FarmColors.card,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(26),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            18,
            14,
            18,
            22,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: FarmColors.line,
                    borderRadius:
                        BorderRadius.circular(99),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                forecast.productName,
                style: const TextStyle(
                  color: FarmColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Keep this future need current so HPJ can plan sourcing against reliable information.',
                style: TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 10.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: quantityController,
                enabled: !busy,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  suffixText: forecast.unit,
                ),
              ),

              const SizedBox(height: 12),

              InkWell(
                onTap: busy ? null : _chooseDate,
                borderRadius:
                    BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Need by',
                    suffixIcon: Icon(
                      Icons.calendar_month_outlined,
                    ),
                  ),
                  child: Text(
                    _dateLabel(needByDate),
                    style: const TextStyle(
                      color: FarmColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'Frequency',
                style: TextStyle(
                  color: FarmColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 7),

              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final option
                      in const <MapEntry<String, String>>[
                    MapEntry('one_time', 'One time'),
                    MapEntry('weekly', 'Weekly'),
                    MapEntry('biweekly', 'Every 2 weeks'),
                    MapEntry('monthly', 'Monthly'),
                  ])
                    ChoiceChip(
                      label: Text(option.value),
                      selected:
                          frequency == option.key,
                      onSelected: busy
                          ? null
                          : (_) {
                              setState(() {
                                frequency =
                                    option.key;
                              });
                            },
                    ),
                ],
              ),

              const SizedBox(height: 14),

              const Text(
                'Confidence',
                style: TextStyle(
                  color: FarmColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 7),

              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final option
                      in const <MapEntry<String, String>>[
                    MapEntry('tentative', 'Tentative'),
                    MapEntry('likely', 'Likely'),
                    MapEntry('expected', 'Expected'),
                  ])
                    ChoiceChip(
                      label: Text(option.value),
                      selected:
                          certainty == option.key,
                      onSelected: busy
                          ? null
                          : (_) {
                              setState(() {
                                certainty =
                                    option.key;
                              });
                            },
                    ),
                ],
              ),

              const SizedBox(height: 12),

              TextField(
                controller: notesController,
                enabled: !busy,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: busy ? null : _save,
                  child: Text(
                    saving
                        ? 'Saving...'
                        : 'Save Changes',
                  ),
                ),
              ),

              const SizedBox(height: 7),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed:
                      busy ? null : _cancel,
                  child: Text(
                    cancelling
                        ? 'Cancelling...'
                        : 'Cancel This Requirement',
                    style: const TextStyle(
                      color: FarmColors.danger,
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

// =====================================================
// PLANNING AHEAD UI HELPERS
// =====================================================

class _WholesalePlanningIntroCard extends StatelessWidget {
  final BusinessAccount account;

  const _WholesalePlanningIntroCard({
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: FarmColors.primarySoft,
              borderRadius: BorderRadius.circular(
                14,
              ),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: FarmColors.primary,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Plan before you order',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  '${account.displayName}, share likely future needs so HPJ can prepare farm supply ahead of time.',
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(
                  height: 7,
                ),
                const Text(
                  'Planning only • Not an order',
                  style: TextStyle(
                    color: FarmColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
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

class _PlanningMiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _PlanningMiniStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: FarmColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: FarmColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WholesalePlanningCard extends StatelessWidget {
  final WholesaleDemandForecast forecast;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  const _WholesalePlanningCard({
    required this.forecast,
    this.onEdit,
    this.onCancel,
  });

  Color get _statusColor {
    if (forecast.isReserved) {
      return FarmColors.success;
    }

    if (forecast.isMatched) {
      return FarmColors.primary;
    }

    if (forecast.isCancelled) {
      return FarmColors.danger;
    }

    return FarmColors.green;
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;

    final notes = forecast.notes.trim();

    return FarmCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(
                    0.10,
                  ),
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: color,
                  size: 19,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      forecast.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      forecast.formattedQuantity,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(
                    0.10,
                  ),
                  borderRadius: BorderRadius.circular(
                    999,
                  ),
                ),
                child: Text(
                  forecast.statusLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: FarmColors.mutedText,
                size: 14,
              ),
              const SizedBox(
                width: 6,
              ),
              Text(
                'Need by ${_wholesalePlanningDate(forecast.needByDate)}',
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _PlanningChip(
                label: forecast.frequencyLabel,
              ),
              _PlanningChip(
                label: forecast.certaintyLabel,
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(
              height: 9,
            ),
            Text(
              notes,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
          if (forecast.isMatched) ...[
            const SizedBox(
              height: 10,
            ),
            const Text(
              'HPJ is matching this need with expected farm supply.',
              style: TextStyle(
                color: FarmColors.primary,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (forecast.isReserved) ...[
            const SizedBox(
              height: 10,
            ),
            const Text(
              'Supply has been reserved for this requirement.',
              style: TextStyle(
                color: FarmColors.success,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (onEdit != null || onCancel != null) ...[
            const SizedBox(
              height: 10,
            ),
            Row(
              children: [
                if (onEdit != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                      ),
                      label: const Text(
                        'Update',
                      ),
                      onPressed: onEdit,
                    ),
                  ),
                if (onEdit != null && onCancel != null)
                  const SizedBox(
                    width: 8,
                  ),
                if (onCancel != null)
                  TextButton(
                    onPressed: onCancel,
                    child: const Text(
                      'Cancel',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanningChip extends StatelessWidget {
  final String label;

  const _PlanningChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: FarmColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: FarmColors.primary,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _wholesalePlanningDate(
  DateTime date,
) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${date.day} '
      '${months[date.month - 1]} '
      '${date.year}';
}


// =====================================================
// HPJ PHASE 039 — WHOLESALE SUPPLIER DISCOVERY
//
// Business buyer → published HPJ farm → preferred-supplier demand forecast
// → existing HPJ procurement workflow.
//
// This does NOT expose farmer phone, email or exact address.
// =====================================================

// ============================================================================
// SOURCE SECTION: business_orders.dart
// ============================================================================
// HPJ PHASE 88 — BUSINESS ORDER TRACKING
// Extracted from wholesale_management.dart without changing runtime behavior.

class MyWholesaleRequestsScreen extends StatefulWidget {
  final bool embedded;
  final String? initialRequestId;

  const MyWholesaleRequestsScreen({
    super.key,
    this.embedded = false,
    this.initialRequestId,
  });

  @override
  State<MyWholesaleRequestsScreen> createState() =>
      _MyWholesaleRequestsScreenState();
}

class _MyWholesaleRequestsScreenState extends State<MyWholesaleRequestsScreen> {
  int _refreshKey = 0;
  int _orderLoadLimit = 50;

  void _refreshOrders() {
    if (!mounted) return;
    setState(() => _refreshKey++);
  }

  void _loadMoreOrders() {
    if (!mounted || _orderLoadLimit >= 1000) return;

    setState(() {
      _orderLoadLimit += 50;
      if (_orderLoadLimit > 1000) {
        _orderLoadLimit = 1000;
      }
    });
  }

  Future<void> _orderAgain(
    BuildContext context,
    WholesaleOrderRequest request,
  ) async {
    try {
      final account = await fetchCurrentBusinessAccount();
      if (account == null || !account.isApproved) {
        throw Exception('An approved wholesale account is required.');
      }

      final saved = request.items
          .map(
            (item) => WholesaleSavedOrderItem(
              id: item.id,
              parentId: request.id,
              productId: item.productId,
              productName: item.productName,
              quantity: item.quantity,
              unit: item.unit,
              unitPriceSnapshot: item.unitPrice,
            ),
          )
          .toList();

      final draft = await prepareWholesaleSavedBasket(saved);

      if (!context.mounted) return;

      if (draft.lines.isEmpty) {
        throw Exception(
          'None of the products from this order are currently available for wholesale ordering.',
        );
      }

      if (draft.unavailableProducts.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unavailable items were skipped: ${draft.unavailableProducts.join(', ')}',
            ),
          ),
        );
      }

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WholesaleRequestReviewScreen(
            account: account,
            lines: draft.lines,
            initialDispatchMethod: request.requestedDispatchMethod,
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  Future<void> _saveTemplate(
    BuildContext context,
    WholesaleOrderRequest request,
  ) async {
    final controller = TextEditingController(
      text: 'Repeat Order ${request.shortId}',
    );

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save as Repeat Order'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Template name',
            hintText: 'e.g. Monday Restaurant Order',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (save != true) {
      controller.dispose();
      return;
    }

    try {
      await saveWholesaleTemplateFromRequest(
        request: request,
        name: controller.text,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repeat-order template saved.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      controller.dispose();
    }
  }

  String _shortDate(DateTime? value) {
    if (value == null) return '';

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final date = value.toLocal();
    return '${date.day} ${months[date.month - 1]}';
  }

  String _orderStatus(
    WholesaleOrderRequest request,
    WholesaleOrderJourney? journey,
  ) {
    if (journey != null) return journey.currentStageLabel;

    switch (request.status.trim().toLowerCase()) {
      case 'approved':
      case 'fulfilled':
        return 'Confirmed';
      case 'quoted':
        return 'Quote Ready';
      case 'rejected':
        return 'Needs Attention';
      case 'cancelled':
        return 'Cancelled';
      case 'pending':
      case 'submitted':
        return 'Submitted';
      default:
        final clean = request.status.trim().replaceAll('_', ' ');
        if (clean.isEmpty) return 'Submitted';
        return clean
            .split(' ')
            .where((part) => part.isNotEmpty)
            .map(
              (part) =>
                  '${part.substring(0, 1).toUpperCase()}${part.substring(1).toLowerCase()}',
            )
            .join(' ');
    }
  }

  bool _isPastOrder(
    WholesaleOrderRequest request,
    WholesaleOrderJourney? journey,
  ) {
    if (journey?.isComplete == true) return true;

    final status = request.status.trim().toLowerCase();
    return status == 'cancelled' || status == 'rejected';
  }

  String _fulfilmentDateLabel(
    WholesaleOrderRequest request,
    WholesaleOrderJourney? journey,
  ) {
    final scheduled = _shortDate(journey?.scheduledFor);
    final requested = _shortDate(request.requestedDate);
    final ordered = _shortDate(request.createdAt);
    final method = (journey?.isCollection == true ||
            request.requestedDispatchMethod == 'business_collection')
        ? 'Collection'
        : 'Delivery';

    if (scheduled.isNotEmpty) {
      return '$method scheduled $scheduled';
    }

    if (requested.isNotEmpty) {
      final window = request.requestedWindowLabel.trim();
      return [
        '$method requested $requested',
        if (window.isNotEmpty) window,
      ].join(' • ');
    }

    if (ordered.isNotEmpty) return 'Ordered $ordered';
    return '';
  }

  String _orderAmountLabel(
    WholesaleOrderRequest request,
    WholesaleOrderJourney? journey,
    WholesaleInvoice? invoice,
  ) {
    final finalTotal = invoice?.totalAmount ?? journey?.invoiceTotal ?? 0;
    if (finalTotal > 0) return 'Final ${formatJmd(finalTotal)}';

    final quoted = request.quotedTotal;
    if (quoted != null) return 'Quoted ${formatJmd(quoted)}';
    return 'Est. ${formatJmd(request.subtotalEstimate)}';
  }

  String _itemsPreview(WholesaleOrderRequest request) {
    if (request.items.isEmpty) return 'Order items';

    final first = request.items.first.productName.trim().isEmpty
        ? 'Product'
        : request.items.first.productName.trim();

    final more = request.items.length - 1;
    return more <= 0 ? first : '$first +$more more';
  }

  Future<void> _handleMoreAction(
    BuildContext context,
    String action,
    WholesaleOrderRequest request,
  ) async {
    if (action == 'again') {
      await _orderAgain(context, request);
      return;
    }
    if (action == 'template') {
      await _saveTemplate(context, request);
    }
  }

  Future<void> _confirmReceived(
    BuildContext context,
    WholesaleOrderRequest request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm order received?'),
        content: Text(
          'Confirm that your business received Order #${request.shortId}. '
          'Use this after the delivered items have been checked.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm Received'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await confirmWholesaleOrderReceived(request.id);
      if (!mounted) return;
      _refreshOrders();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt confirmed. Thank you.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  Future<void> _showOrderDetails(
    BuildContext context,
    WholesaleOrderRequest request,
    WholesaleOrderJourney? journey,
    WholesaleInvoice? invoice,
  ) async {
    final status = _orderStatus(request, journey);
    final dateLabel = _fulfilmentDateLabel(request, journey);
    final finalTotal = invoice?.totalAmount ?? journey?.invoiceTotal ?? 0;
    final amountDue = invoice?.amountDue ?? journey?.amountDue ?? 0;
    final paidAmount = invoice?.paidAmount ??
        (finalTotal > amountDue ? finalTotal - amountDue : 0);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);

        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: media.size.height * 0.90,
            ),
            decoration: const BoxDecoration(
              color: FarmColors.background,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: FarmColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (request.items.isNotEmpty)
                            HpjProductThumb(
                              productId: request.items.first.productId,
                              productName: request.items.first.productName,
                              size: 72,
                              radius: 17,
                            )
                          else
                            Container(
                              width: 72,
                              height: 72,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: FarmColors.primarySoft,
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(color: FarmColors.line),
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: FarmColors.primary,
                              ),
                            ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order #${request.shortId}',
                                  style: const TextStyle(
                                    color: FarmColors.ink,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                _WholesaleStatusChip(status: status),
                                if (dateLabel.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    dateLabel,
                                    style: const TextStyle(
                                      color: FarmColors.mutedText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        invoice != null
                            ? 'Requested items'
                            : request.items.length == 1
                                ? '1 item'
                                : '${request.items.length} items',
                        style: const TextStyle(
                          color: FarmColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 9),
                      ...request.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: FarmColors.line),
                            ),
                            child: Row(
                              children: [
                                HpjProductThumb(
                                  productId: item.productId,
                                  productName: item.productName,
                                  size: 52,
                                  radius: 12,
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: FarmColors.ink,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${item.quantityLabel} ${item.unit}',
                                        style: const TextStyle(
                                          color: FarmColors.mutedText,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formatJmd(item.lineTotal),
                                  style: const TextStyle(
                                    color: FarmColors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: FarmColors.cardSoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: FarmColors.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (finalTotal > 0) ...[
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Final invoice total',
                                      style: TextStyle(
                                        color: FarmColors.mutedText,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    formatJmd(finalTotal),
                                    style: const TextStyle(
                                      color: FarmColors.ink,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              if (paidAmount > 0) ...[
                                const SizedBox(height: 7),
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Paid',
                                        style: TextStyle(
                                          color: FarmColors.mutedText,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      formatJmd(paidAmount),
                                      style: const TextStyle(
                                        color: FarmColors.success,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const Divider(height: 18),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Balance due',
                                      style: TextStyle(
                                        color: FarmColors.ink,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    formatJmd(amountDue),
                                    style: TextStyle(
                                      color: amountDue > 0
                                          ? FarmColors.warning
                                          : FarmColors.success,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Final amount is based on the invoiced / packed quantities.',
                                style: TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 9.5,
                                  height: 1.3,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      request.quotedTotal != null
                                          ? 'Quoted total'
                                          : 'Estimated total',
                                      style: const TextStyle(
                                        color: FarmColors.mutedText,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    request.quotedTotal != null
                                        ? formatJmd(request.quotedTotal!)
                                        : formatJmd(request.subtotalEstimate),
                                    style: const TextStyle(
                                      color: FarmColors.ink,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (invoice != null && invoice.items.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Final invoiced quantities',
                          style: TextStyle(
                            color: FarmColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        ...invoice.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.productName} • ${item.formattedQuantity}',
                                    style: const TextStyle(
                                      color: FarmColors.mutedText,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.formattedLineTotal,
                                  style: const TextStyle(
                                    color: FarmColors.ink,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (journey != null) ...[
                        const SizedBox(height: 18),
                        const Text(
                          'Order progress',
                          style: TextStyle(
                            color: FarmColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: FarmColors.line),
                          ),
                          child: _WholesaleJourneyTimeline(journey: journey),
                        ),
                      ],
                      if (journey?.canConfirmReceipt == true) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: FarmColors.primarySoft,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: FarmColors.primary.withOpacity(0.22),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    color: FarmColors.primary,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Delivered by HPJ — confirm receipt',
                                      style: TextStyle(
                                        color: FarmColors.ink,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'After your business checks the delivery, confirm that it was received.',
                                style: TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 10.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if ((journey?.recipientName ?? '')
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(
                                  'Delivered to ${(journey?.recipientName ?? '').trim()}',
                                  style: const TextStyle(
                                    color: FarmColors.ink,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    Navigator.of(sheetContext).pop();
                                    await _confirmReceived(context, request);
                                  },
                                  icon: const Icon(
                                    Icons.task_alt_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Confirm Received'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (journey?.businessReceivedAt != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: FarmColors.success.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: FarmColors.success.withOpacity(0.24),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.verified_outlined,
                                color: FarmColors.success,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your business confirmed this order was received.',
                                  style: TextStyle(
                                    color: FarmColors.ink,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (journey != null &&
                          (journey.invoiceNumber.isNotEmpty ||
                              journey.amountDue > 0)) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: journey.amountDue > 0
                                ? FarmColors.warning.withOpacity(0.08)
                                : FarmColors.cardSoft,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: journey.amountDue > 0
                                  ? FarmColors.warning.withOpacity(0.30)
                                  : FarmColors.line,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                journey.amountDue > 0
                                    ? Icons.payments_outlined
                                    : Icons.receipt_long_outlined,
                                color: journey.amountDue > 0
                                    ? FarmColors.warning
                                    : FarmColors.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  [
                                    if (journey.invoiceNumber.isNotEmpty)
                                      'Invoice ${journey.invoiceNumber}',
                                    if (journey.amountDue > 0)
                                      'Amount due ${formatJmd(journey.amountDue)}'
                                    else if (journey.paymentStatus.isNotEmpty)
                                      journey.paymentStatus
                                          .replaceAll('_', ' '),
                                  ].join(' • '),
                                  style: const TextStyle(
                                    color: FarmColors.ink,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (request.adminNotes.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: FarmColors.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'HPJ note',
                                style: TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                request.adminNotes.trim(),
                                style: const TextStyle(
                                  color: FarmColors.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: FarmColors.line),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.of(sheetContext).pop();
                              await _saveTemplate(context, request);
                            },
                            icon: const Icon(
                              Icons.bookmark_add_outlined,
                              size: 17,
                            ),
                            label: const Text('Save Repeat'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.of(sheetContext).pop();
                              await _orderAgain(context, request);
                            },
                            icon: const Icon(
                              Icons.replay_rounded,
                              size: 17,
                            ),
                            label: const Text('Order Again'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _orderCard(
    BuildContext context,
    WholesaleOrderRequest request,
    WholesaleOrderJourney? journey,
    WholesaleInvoice? invoice,
  ) {
    final status = _orderStatus(request, journey);
    final dateLabel = _fulfilmentDateLabel(request, journey);
    final hasAmountDue = (invoice?.amountDue ?? journey?.amountDue ?? 0) > 0;
    final isPast = _isPastOrder(request, journey);
    final needsReceipt = journey?.canConfirmReceipt == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FarmCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (request.items.isNotEmpty)
                      HpjProductThumb(
                        productId: request.items.first.productId,
                        productName: request.items.first.productName,
                        size: 64,
                        radius: 15,
                      )
                    else
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: FarmColors.primarySoft,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: FarmColors.line),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: FarmColors.primary,
                        ),
                      ),
                    if (request.items.length > 1)
                      Positioned(
                        right: -7,
                        bottom: -7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: FarmColors.primary,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            '+${request.items.length - 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'Order #${request.shortId}',
                              style: const TextStyle(
                                color: FarmColors.ink,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            tooltip: 'More order actions',
                            onSelected: (action) => _handleMoreAction(
                              context,
                              action,
                              request,
                            ),
                            itemBuilder: (_) => const [
                              PopupMenuItem<String>(
                                value: 'again',
                                child: Row(
                                  children: [
                                    Icon(Icons.replay_rounded, size: 18),
                                    SizedBox(width: 9),
                                    Text('Order Again'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'template',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.bookmark_add_outlined,
                                      size: 18,
                                    ),
                                    SizedBox(width: 9),
                                    Text('Save Repeat Order'),
                                  ],
                                ),
                              ),
                            ],
                            icon: const Icon(
                              Icons.more_horiz_rounded,
                              color: FarmColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _WholesaleStatusChip(status: status),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _itemsPreview(request),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              [
                request.items.length == 1
                    ? '1 item'
                    : '${request.items.length} items',
                _orderAmountLabel(request, journey, invoice),
              ].join(' • '),
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (dateLabel.isNotEmpty) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(
                    Icons.event_outlined,
                    size: 15,
                    color: FarmColors.primary,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      dateLabel,
                      style: const TextStyle(
                        color: FarmColors.primary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (hasAmountDue) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: FarmColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: FarmColors.warning.withOpacity(0.30),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      size: 18,
                      color: FarmColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Payment due ${formatJmd(invoice?.amountDue ?? journey!.amountDue)}',
                        style: const TextStyle(
                          color: FarmColors.ink,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: needsReceipt
                  ? ElevatedButton.icon(
                      onPressed: () => _showOrderDetails(
                        context,
                        request,
                        journey,
                        invoice,
                      ),
                      icon: const Icon(
                        Icons.task_alt_rounded,
                        size: 18,
                      ),
                      label: const Text('Confirm Receipt'),
                    )
                  : isPast
                      ? OutlinedButton.icon(
                          onPressed: () => _showOrderDetails(
                            context,
                            request,
                            journey,
                            invoice,
                          ),
                          icon: const Icon(
                            Icons.receipt_long_outlined,
                            size: 18,
                          ),
                          label: const Text('View Order'),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => _showOrderDetails(
                            context,
                            request,
                            journey,
                            invoice,
                          ),
                          icon: const Icon(
                            Icons.local_shipping_outlined,
                            size: 18,
                          ),
                          label: const Text('Track Order'),
                        ),
            ),
          ],
        ),
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: widget.embedded ? null : AppBar(title: const Text('Orders')),
      body: FutureBuilder<List<Object>>(
        key: ValueKey(_refreshKey),
        future: Future.wait<Object>([
          fetchMyWholesaleRequests(
            limit: (widget.initialRequestId?.trim().isNotEmpty ?? false)
                ? 500
                : _orderLoadLimit + 1,
          ),
          fetchMyWholesaleOrderJourneys(),
          fetchMyWholesaleInvoices(
            includePaid: true,
            limit: _orderLoadLimit < 150
                ? 300
                : _orderLoadLimit * 2,
          ),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  friendlyAppError(snapshot.error!),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data;

          final fetchedRequests = data == null
              ? const <WholesaleOrderRequest>[]
              : data[0] as List<WholesaleOrderRequest>;

          final requestedRequestId =
              widget.initialRequestId?.trim() ?? '';

          final hasMoreOrders = requestedRequestId.isEmpty &&
              fetchedRequests.length > _orderLoadLimit;

          final allRequests = requestedRequestId.isEmpty
              ? fetchedRequests.take(_orderLoadLimit).toList(growable: false)
              : fetchedRequests;

          final focusedRequests = requestedRequestId.isEmpty
              ? const <WholesaleOrderRequest>[]
              : allRequests
                  .where((request) => request.id.trim() == requestedRequestId)
                  .toList();

          final exactRequestFound = focusedRequests.isNotEmpty;
          final requests = exactRequestFound ? focusedRequests : allRequests;

          final journeys = data == null
              ? const <WholesaleOrderJourney>[]
              : data[1] as List<WholesaleOrderJourney>;

          final journeyByRequest = <String, WholesaleOrderJourney>{
            for (final journey in journeys) journey.requestId: journey,
          };

          final invoices = data == null
              ? const <WholesaleInvoice>[]
              : data[2] as List<WholesaleInvoice>;

          final invoiceByRequest = <String, WholesaleInvoice>{};

          for (final invoice in invoices) {
            final requestId = invoice.requestId.trim();
            if (requestId.isEmpty || invoice.isVoid) continue;
            invoiceByRequest.putIfAbsent(requestId, () => invoice);
          }

          final ordered = List<WholesaleOrderRequest>.from(requests)
            ..sort((a, b) {
              final aPast = _isPastOrder(a, journeyByRequest[a.id]);
              final bPast = _isPastOrder(b, journeyByRequest[b.id]);

              if (aPast != bPast) return aPast ? 1 : -1;

              final aDate =
                  (a.updatedAt ?? a.createdAt ?? DateTime(2000)).toLocal();
              final bDate =
                  (b.updatedAt ?? b.createdAt ?? DateTime(2000)).toLocal();

              return bDate.compareTo(aDate);
            });

          final current = ordered
              .where(
                (request) =>
                    !_isPastOrder(request, journeyByRequest[request.id]),
              )
              .toList();

          final past = ordered
              .where(
                (request) =>
                    _isPastOrder(request, journeyByRequest[request.id]),
              )
              .toList();

          final allCurrentCount = allRequests
              .where(
                (request) =>
                    !_isPastOrder(request, journeyByRequest[request.id]),
              )
              .length;

          final receiptActions =
              journeys.where((journey) => journey.canConfirmReceipt).length;

          final amountDue = invoices
              .where(
                (invoice) =>
                    !invoice.isVoid &&
                    !invoice.isPaid &&
                    invoice.amountDue > 0,
              )
              .fold<double>(0, (sum, invoice) => sum + invoice.amountDue);

          final scheduledJourneys = journeys
              .where(
                (journey) =>
                    journey.scheduledFor != null &&
                    !journey.isLogisticsComplete,
              )
              .toList()
            ..sort(
              (a, b) => a.scheduledFor!.compareTo(b.scheduledFor!),
            );

          final nextScheduled =
              scheduledJourneys.isEmpty ? null : scheduledJourneys.first;

          return FarmPage(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
              children: [
                _PremiumWholesaleOrdersHero(
                  currentOrders: allCurrentCount,
                  loadedOrders: allRequests.length,
                  receiptActions: receiptActions,
                  amountDue: amountDue,
                  nextScheduled: nextScheduled,
                ),
                const SizedBox(height: 16),

                if (requestedRequestId.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: exactRequestFound
                          ? FarmColors.primarySoft
                          : const Color(0xFFFFF7E8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: exactRequestFound
                            ? FarmColors.primary.withOpacity(0.20)
                            : FarmColors.warning.withOpacity(0.28),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          exactRequestFound
                              ? Icons.notifications_active_outlined
                              : Icons.info_outline_rounded,
                          size: 18,
                          color: exactRequestFound
                              ? FarmColors.primary
                              : FarmColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            exactRequestFound
                                ? 'Opened from your notification. Showing the related order.'
                                : 'That order is no longer available in this view. Showing your current orders instead.',
                            style: const TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 10,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                if (receiptActions > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: FarmColors.warning.withOpacity(.20),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          color: FarmColors.warning,
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$receiptActions delivered order${receiptActions == 1 ? '' : 's'} '
                            '${receiptActions == 1 ? 'is' : 'are'} waiting for receipt confirmation.',
                            style: const TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 9.7,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                if (requests.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: 'No wholesale orders yet',
                    message:
                        'Start in Shop when your business is ready to place an order.',
                  )
                else ...[
                  if (current.isNotEmpty) ...[
                    _PremiumWholesaleOrderSectionHeader(
                      title: 'Current orders',
                      subtitle:
                          'Orders still moving through confirmation, fulfilment or delivery.',
                      count: current.length,
                    ),
                    const SizedBox(height: 9),
                    ...current.map(
                      (request) => _orderCard(
                        context,
                        request,
                        journeyByRequest[request.id],
                        invoiceByRequest[request.id],
                      ),
                    ),
                  ],

                  if (past.isNotEmpty) ...[
                    if (current.isNotEmpty) const SizedBox(height: 7),
                    _PremiumWholesaleOrderSectionHeader(
                      title: 'Past orders',
                      subtitle:
                          'Completed, cancelled or otherwise closed wholesale activity.',
                      count: past.length,
                    ),
                    const SizedBox(height: 9),
                    ...past.map(
                      (request) => _orderCard(
                        context,
                        request,
                        journeyByRequest[request.id],
                        invoiceByRequest[request.id],
                      ),
                    ),
                  ],

                  if (hasMoreOrders) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _loadMoreOrders,
                        icon: const Icon(
                          Icons.expand_more_rounded,
                          size: 18,
                        ),
                        label: const Text('Load 50 More Orders'),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Showing the ${allRequests.length} most recent wholesale orders.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 9.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PremiumWholesaleOrdersHero extends StatelessWidget {
  final int currentOrders;
  final int loadedOrders;
  final int receiptActions;
  final double amountDue;
  final WholesaleOrderJourney? nextScheduled;

  const _PremiumWholesaleOrdersHero({
    required this.currentOrders,
    required this.loadedOrders,
    required this.receiptActions,
    required this.amountDue,
    required this.nextScheduled,
  });

  String _dateLabel(DateTime? value) {
    if (value == null) return 'None';

    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final date = value.toLocal();
    return '${date.day} ${months[date.month - 1]}';
  }

  Widget _metric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFE8C768), size: 17),
            const SizedBox(height: 7),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(.72),
                fontSize: 8.7,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final next = nextScheduled;

    final nextText = next == null
        ? 'No active schedule'
        : '${next.isCollection ? 'Collection' : 'Delivery'} • '
            '${_dateLabel(next.scheduledFor)}';

    if (hpjUseMobileAppPresentation(context)) {
      return _HpjBusinessMobileHeaderCard(
        icon: Icons.local_shipping_outlined,
        eyebrow: 'BUSINESS ORDERS',
        title: 'Track & receive',
        subtitle: nextText,
        metrics: <_HpjBusinessMobileMetricData>[
          _HpjBusinessMobileMetricData(
            value: '$currentOrders',
            label: 'Current',
          ),
          _HpjBusinessMobileMetricData(
            value: '$receiptActions',
            label: 'Confirm',
            warning: receiptActions > 0,
          ),
          _HpjBusinessMobileMetricData(
            value: amountDue > 0 ? formatJmd(amountDue) : 'Clear',
            label: 'Amount due',
            warning: amountDue > 0,
          ),
          _HpjBusinessMobileMetricData(
            value: '$loadedOrders',
            label: 'Loaded',
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FarmColors.deepGreen,
            FarmColors.green,
            Color(0xFF4E8157),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: FarmColors.deepGreen.withOpacity(.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                color: Color(0xFFE8C768),
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'BUSINESS ORDERS',
                style: TextStyle(
                  color: Color(0xFFCFE0CF),
                  fontSize: 10.3,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'Track every wholesale request',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Follow confirmation, preparation, packing, delivery or collection, '
            'final invoice totals and receipt confirmation.',
            style: TextStyle(
              color: Colors.white.withOpacity(.83),
              fontSize: 10.6,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _metric(
                icon: Icons.autorenew_rounded,
                value: '$currentOrders',
                label: 'Current',
              ),
              const SizedBox(width: 8),
              _metric(
                icon: Icons.inventory_2_outlined,
                value: '$receiptActions',
                label: 'Confirm receipt',
              ),
              const SizedBox(width: 8),
              _metric(
                icon: Icons.payments_outlined,
                value: formatJmd(amountDue),
                label: 'Amount due',
              ),
            ],
          ),
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.10),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(.14)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  color: Color(0xFFE8C768),
                  size: 17,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '$nextText • $loadedOrders loaded order${loadedOrders == 1 ? '' : 's'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.83),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
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
}

class _PremiumWholesaleOrderSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;

  const _PremiumWholesaleOrderSectionHeader({
    required this.title,
    required this.subtitle,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: FarmColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 9.3,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: FarmColors.primarySoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: FarmColors.deepGreen,
              fontSize: 9.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _WholesaleJourneyTimeline extends StatelessWidget {
  final WholesaleOrderJourney journey;

  const _WholesaleJourneyTimeline({
    required this.journey,
  });

  String _timeLabel(DateTime? value) {
    if (value == null) return '';

    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final date = value.toLocal();
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final meridiem = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day} ${months[date.month - 1]} • '
        '$hour:$minute $meridiem';
  }

  @override
  Widget build(BuildContext context) {
    final stages = journey.stageLabels;
    final current = journey.currentStageIndex;
    final interrupted = journey.requestStatus == 'cancelled' ||
        journey.requestStatus == 'rejected';

    final statusColor =
        interrupted ? FarmColors.danger : FarmColors.green;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F5),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  interrupted
                      ? Icons.warning_amber_rounded
                      : Icons.route_outlined,
                  color: statusColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order journey',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 8.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      journey.currentStageLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (journey.scheduledFor != null &&
              !journey.isLogisticsComplete) ...[
            const SizedBox(height: 9),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: FarmColors.primarySoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_outlined,
                    color: FarmColors.deepGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${journey.isCollection ? 'Collection' : 'Delivery'} '
                      'schedule • ${_timeLabel(journey.scheduledFor)}',
                      style: const TextStyle(
                        color: FarmColors.deepGreen,
                        fontSize: 9.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          ...List.generate(
            stages.length,
            (index) {
              final reached = !interrupted && index <= current;
              final isCurrent = !interrupted && index == current;
              final isLast = index == stages.length - 1;
              final time =
                  _timeLabel(journey.timestampForStage(index));

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Column(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: reached
                                ? FarmColors.green
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCurrent
                                  ? FarmColors.green
                                  : reached
                                      ? FarmColors.green
                                      : FarmColors.line,
                              width: isCurrent ? 2 : 1.4,
                            ),
                          ),
                          child: reached
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: time.isEmpty ? 28 : 36,
                            color: index < current &&
                                    !interrupted
                                ? FarmColors.green
                                : FarmColors.line,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 1,
                        bottom: 10,
                      ),
                      child: Container(
                        padding: isCurrent
                            ? const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 7,
                              )
                            : EdgeInsets.zero,
                        decoration: isCurrent
                            ? BoxDecoration(
                                color: FarmColors.primarySoft,
                                borderRadius:
                                    BorderRadius.circular(12),
                              )
                            : null,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              stages[index],
                              style: TextStyle(
                                color: isCurrent
                                    ? FarmColors.deepGreen
                                    : reached
                                        ? FarmColors.ink
                                        : FarmColors.mutedText,
                                fontSize: 9.8,
                                fontWeight:
                                    isCurrent || reached
                                        ? FontWeight.w900
                                        : FontWeight.w600,
                              ),
                            ),
                            if (time.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                time,
                                style: const TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ] else if (isCurrent &&
                                journey.canConfirmReceipt) ...[
                              const SizedBox(height: 2),
                              const Text(
                                'Waiting for your receipt confirmation',
                                style: TextStyle(
                                  color: FarmColors.warning,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WholesaleStatusChip extends StatelessWidget {
  final String status;

  const _WholesaleStatusChip({required this.status});

  String _friendlyLabel(String clean) {
    switch (clean) {
      case 'approved':
      case 'confirmed':
      case 'fulfilled':
        return 'Confirmed';
      case 'quote_ready':
      case 'quoted':
        return 'Quote Ready';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'ready_for_collection':
      case 'ready_for_pickup':
        return 'Ready for Collection';
      case 'ready_for_dispatch':
        return 'Ready for Dispatch';
      case 'delivery_scheduled':
        return 'Delivery Scheduled';
      case 'collection_scheduled':
        return 'Collection Scheduled';
      case 'needs_attention':
      case 'rejected':
        return 'Needs Attention';
      default:
        final spaced = clean.replaceAll('_', ' ').trim();
        if (spaced.isEmpty) return 'Submitted';
        return spaced
            .split(' ')
            .where((part) => part.isNotEmpty)
            .map(
              (part) =>
                  '${part.substring(0, 1).toUpperCase()}${part.substring(1).toLowerCase()}',
            )
            .join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final clean = status.trim().toLowerCase().replaceAll(' ', '_');

    final color = clean == 'fulfilled' ||
            clean == 'approved' ||
            clean == 'confirmed' ||
            clean == 'delivered' ||
            clean == 'collected'
        ? FarmColors.success
        : clean == 'rejected' ||
                clean == 'cancelled' ||
                clean == 'needs_attention'
            ? FarmColors.danger
            : clean == 'quoted' ||
                    clean == 'quote_ready' ||
                    clean == 'payment_due'
                ? FarmColors.warning
                : FarmColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        _friendlyLabel(clean),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ============================================================================
// SOURCE SECTION: business_suppliers.dart
// ============================================================================
// HPJ PHASE 88 — BUSINESS SUPPLIER DISCOVERY
// Extracted from wholesale_management.dart without changing runtime behavior.

class _WholesaleSupplierDiscoveryEntryCard extends StatelessWidget {
  final BusinessAccount account;

  const _WholesaleSupplierDiscoveryEntryCard({
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FarmColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => WholesaleSupplierDiscoveryScreen(
                account: account,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FarmColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: FarmColors.primarySoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.agriculture_outlined,
                  color: FarmColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find Suppliers',
                      style: TextStyle(
                        color: FarmColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Discover verified Jamaican farms and request supply through HPJ.',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 11.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: FarmColors.primary,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WholesaleSupplierDiscoveryScreen extends StatefulWidget {
  final BusinessAccount account;
  final bool embedded;
  final bool initialPreferredOnly;

  const WholesaleSupplierDiscoveryScreen({
    super.key,
    required this.account,
    this.embedded = false,
    this.initialPreferredOnly = false,
  });

  @override
  State<WholesaleSupplierDiscoveryScreen> createState() =>
      _WholesaleSupplierDiscoveryScreenState();
}

class _WholesaleSupplierDiscoveryScreenState
    extends State<WholesaleSupplierDiscoveryScreen> {
  late Future<List<FarmPublicProfileRecord>> _future;
  final searchController = TextEditingController();
  String query = '';
  bool _preferredOnly = false;
  Set<String> _preferredFarmIds = <String>{};
  Map<String, HpjRelationshipRecommendation> _relationshipByFarm =
      <String, HpjRelationshipRecommendation>{};

  @override
  void initState() {
    super.initState();
    _preferredOnly = widget.initialPreferredOnly;
    _future = fetchPublishedFarmPublicProfiles(limit: 80);
    unawaited(_loadRelationshipSignals());
  }

  Future<void> _loadRelationshipSignals() async {
    final preferred = await fetchHpjPreferredFarmIds(
      contextType: 'business',
      businessAccountId: widget.account.id,
    );
    final relationships = await fetchHpjRelationshipRecommendations(
      contextType: 'business',
      businessAccountId: widget.account.id,
    );

    if (!mounted) return;
    setState(() {
      _preferredFarmIds = preferred;
      _relationshipByFarm = <String, HpjRelationshipRecommendation>{
        for (final item in relationships) item.farmerProfileId: item,
      };
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final next = fetchPublishedFarmPublicProfiles(limit: 80);
    setState(() {
      _future = next;
    });
    await Future.wait<dynamic>([
      next,
      _loadRelationshipSignals(),
    ]);
  }

  Future<void> _togglePreferred(FarmPublicProfileRecord farm) async {
    final current = _preferredFarmIds.contains(farm.farmerId);

    try {
      final next = await setHpjPreferredFarm(
        farmerProfileId: farm.farmerId,
        contextType: 'business',
        businessAccountId: widget.account.id,
        preferred: !current,
      );

      if (!mounted) return;
      setState(() {
        if (next) {
          _preferredFarmIds.add(farm.farmerId);
        } else {
          _preferredFarmIds.remove(farm.farmerId);
        }
      });

      await _loadRelationshipSignals();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next
                ? '${farm.publicName} is now a preferred supplier.'
                : '${farm.publicName} was removed from preferred suppliers.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  bool _matches(FarmPublicProfileRecord farm) {
    if (_preferredOnly && !_preferredFarmIds.contains(farm.farmerId)) {
      return false;
    }

    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return true;

    final haystack = <String>[
      farm.publicName,
      farm.community,
      farm.parish,
      farm.publicBio,
      ...farm.tags,
      ...farm.farmingPractices,
    ].join(' ').toLowerCase();

    return haystack.contains(clean);
  }

  void _viewFarm(FarmPublicProfileRecord farm) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublicFarmProfileScreen(
          farmerId: farm.farmerId,
          sourceWorkspace: 'wholesale',
          wholesaleAccount: widget.account,
        ),
      ),
    );
  }

  void _requestSupply(FarmPublicProfileRecord farm) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WholesaleSupplierRequestScreen(
          account: widget.account,
          farm: farm,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Find Suppliers'),
            ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<FarmPublicProfileRecord>>(
          future: _future,
          builder: (context, snapshot) {
            final allFarms =
                snapshot.data ?? const <FarmPublicProfileRecord>[];

            final farms = allFarms.where(_matches).toList()
              ..sort(
                (a, b) {
                  final aPreferred =
                      _preferredFarmIds.contains(a.farmerId);
                  final bPreferred =
                      _preferredFarmIds.contains(b.farmerId);

                  if (aPreferred != bPreferred) {
                    return aPreferred ? -1 : 1;
                  }

                  final aScore =
                      _relationshipByFarm[a.farmerId]?.relationshipScore ?? 0;
                  final bScore =
                      _relationshipByFarm[b.farmerId]?.relationshipScore ?? 0;

                  final scoreCompare = bScore.compareTo(aScore);
                  if (scoreCompare != 0) return scoreCompare;

                  if (a.hpjVerified != b.hpjVerified) {
                    return a.hpjVerified ? -1 : 1;
                  }

                  return a.publicName
                      .toLowerCase()
                      .compareTo(b.publicName.toLowerCase());
                },
              );

            final verifiedCount =
                allFarms.where((farm) => farm.hpjVerified).length;

            final parishCount = allFarms
                .map((farm) => farm.parish.trim())
                .where((value) => value.isNotEmpty)
                .toSet()
                .length;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
                children: [
                  _PremiumWholesaleSupplierHero(
                    businessName: widget.account.displayName,
                    farmCount: allFarms.length,
                    verifiedCount: verifiedCount,
                    parishCount: parishCount,
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Discover farm partners',
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Search by farm, parish, crop tag or farming practice, then ask HPJ to source with that farm as your preference.',
                    style: TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 9.7,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: searchController,
                    onChanged: (value) => setState(() => query = value),
                    decoration: InputDecoration(
                      hintText:
                          'Search farm, parish, crop tag or farming practice...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: query.trim().isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                searchController.clear();
                                setState(() => query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        selected: _preferredOnly,
                        onSelected: (value) {
                          setState(() => _preferredOnly = value);
                        },
                        avatar: Icon(
                          _preferredOnly
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 16,
                        ),
                        label: Text(
                          _preferredOnly
                              ? 'Preferred suppliers'
                              : 'Show preferred only',
                        ),
                      ),
                      if (_relationshipByFarm.isNotEmpty)
                        Chip(
                          avatar: const Icon(
                            Icons.handshake_outlined,
                            size: 16,
                          ),
                          label: Text(
                            '${_relationshipByFarm.length} repeat relationship${_relationshipByFarm.length == 1 ? '' : 's'}',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FarmColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: FarmColors.green.withOpacity(0.12),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: FarmColors.green,
                          size: 20,
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Preferred supplier does not create a direct buyer-to-farmer contract. HPJ manages sourcing, pricing, collection, receiving and fulfilment, and may use another verified farm if needed.',
                            style: TextStyle(
                              color: FarmColors.deepGreen,
                              fontSize: 9.8,
                              height: 1.38,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (snapshot.connectionState ==
                          ConnectionState.waiting &&
                      snapshot.data == null)
                    const Column(
                      children: [
                        FarmSkeletonCard(height: 150),
                        SizedBox(height: 10),
                        FarmSkeletonCard(height: 150),
                      ],
                    )
                  else if (snapshot.hasError && allFarms.isEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const FarmEmptyState(
                          icon: Icons.cloud_off_outlined,
                          title: 'Supplier network could not load',
                          message:
                              'HPJ could not reach the verified-farm directory right now.',
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry Suppliers'),
                        ),
                      ],
                    )
                  else if (farms.isEmpty)
                    const FarmEmptyState(
                      icon: Icons.agriculture_outlined,
                      title: 'No matching suppliers',
                      message:
                          'Try another search or check again as more approved farms publish their HPJ pages.',
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            query.trim().isEmpty
                                ? 'Jamaican suppliers'
                                : 'Matching suppliers',
                            style: const TextStyle(
                              color: FarmColors.ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: FarmColors.primarySoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${farms.length}',
                            style: const TextStyle(
                              color: FarmColors.deepGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final useTwoColumns =
                            constraints.maxWidth >= 900;
                        const gap = 12.0;

                        final width = useTwoColumns
                            ? (constraints.maxWidth - gap) / 2
                            : constraints.maxWidth;

                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: farms
                              .map(
                                (farm) => SizedBox(
                                  width: width,
                                  child: _WholesaleSupplierCard(
                                    farm: farm,
                                    preferred: _preferredFarmIds
                                        .contains(farm.farmerId),
                                    relationship:
                                        _relationshipByFarm[farm.farmerId],
                                    onTogglePreferred: () =>
                                        _togglePreferred(farm),
                                    onViewFarm: () => _viewFarm(farm),
                                    onRequestSupply: () =>
                                        _requestSupply(farm),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PremiumWholesaleSupplierHero extends StatelessWidget {
  final String businessName;
  final int farmCount;
  final int verifiedCount;
  final int parishCount;

  const _PremiumWholesaleSupplierHero({
    required this.businessName,
    required this.farmCount,
    required this.verifiedCount,
    required this.parishCount,
  });

  Widget _metric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: const Color(0xFFE8C768),
              size: 17,
            ),
            const SizedBox(height: 7),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(.72),
                fontSize: 8.7,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanName = businessName.trim().isEmpty
        ? 'Your business'
        : businessName.trim();

    if (hpjUseMobileAppPresentation(context)) {
      return _HpjBusinessMobileHeaderCard(
        icon: Icons.handshake_outlined,
        eyebrow: 'SUPPLIER NETWORK',
        title: cleanName,
        subtitle:
            'Discover Jamaican farm partners, preferred suppliers and repeat relationships.',
        metrics: <_HpjBusinessMobileMetricData>[
          _HpjBusinessMobileMetricData(
            value: '$farmCount',
            label: 'Farms',
          ),
          _HpjBusinessMobileMetricData(
            value: '$verifiedCount',
            label: 'Verified',
          ),
          _HpjBusinessMobileMetricData(
            value: '$parishCount',
            label: 'Parishes',
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FarmColors.deepGreen,
            FarmColors.green,
            Color(0xFF4E8157),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: FarmColors.deepGreen.withOpacity(.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.13),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(.18),
                  ),
                ),
                child: const Icon(
                  Icons.agriculture_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HPJ SUPPLIER NETWORK',
                      style: TextStyle(
                        color: Colors.white.withOpacity(.72),
                        fontSize: 10.3,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .9,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cleanName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Discover published Jamaican farm partners and tell HPJ which farm you would prefer us to check first.',
            style: TextStyle(
              color: Colors.white.withOpacity(.84),
              fontSize: 10.8,
              height: 1.42,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _metric(
                icon: Icons.storefront_outlined,
                value: '$farmCount',
                label: 'Published farms',
              ),
              const SizedBox(width: 8),
              _metric(
                icon: Icons.verified_rounded,
                value: '$verifiedCount',
                label: 'HPJ Verified',
              ),
              const SizedBox(width: 8),
              _metric(
                icon: Icons.map_outlined,
                value: '$parishCount',
                label: 'Parishes',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WholesaleSupplierCard extends StatelessWidget {
  final FarmPublicProfileRecord farm;
  final bool preferred;
  final HpjRelationshipRecommendation? relationship;
  final VoidCallback onTogglePreferred;
  final VoidCallback onViewFarm;
  final VoidCallback onRequestSupply;

  const _WholesaleSupplierCard({
    required this.farm,
    required this.preferred,
    required this.relationship,
    required this.onTogglePreferred,
    required this.onViewFarm,
    required this.onRequestSupply,
  });

  @override
  Widget build(BuildContext context) {
    final image = cleanHostedImageUrl(farm.coverImageUrl) ??
        cleanHostedImageUrl(farm.logoImageUrl);

    final practices = farm.farmingPractices
        .where((item) => item.trim().isNotEmpty)
        .take(2)
        .toList();

    if (hpjUseMobileAppPresentation(context)) {
      final relationshipLabel = relationship == null
          ? ''
          : relationship!.preferred
              ? 'Preferred'
              : relationship!.relationshipCount > 1
                  ? '${relationship!.relationshipCount} repeat'
                  : '';

      return FarmCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onViewFarm,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(11, 11, 10, 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 82,
                    height: 82,
                    child: image == null
                        ? Container(
                            color: FarmColors.primarySoft,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.agriculture_outlined,
                              color: FarmColors.deepGreen,
                              size: 30,
                            ),
                          )
                        : Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: FarmColors.primarySoft,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.agriculture_outlined,
                                color: FarmColors.deepGreen,
                                size: 30,
                              ),
                            ),
                          ),
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
                              farm.publicName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: FarmColors.ink,
                                fontSize: 14.2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (farm.hpjVerified)
                            const Padding(
                              padding: EdgeInsets.only(left: 5),
                              child: Icon(
                                Icons.verified_rounded,
                                color: FarmColors.gold,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        farm.locationLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 9.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (relationshipLabel.isNotEmpty || preferred) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: [
                            if (preferred)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4D9),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Preferred',
                                  style: TextStyle(
                                    color: Color(0xFF8A6219),
                                    fontSize: 8.0,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            if (relationshipLabel.isNotEmpty && !preferred)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF3E7),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  relationshipLabel,
                                  style: const TextStyle(
                                    color: FarmColors.green,
                                    fontSize: 8.0,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: FilledButton.icon(
                                onPressed: onRequestSupply,
                                icon: const Icon(
                                  Icons.add_business_outlined,
                                  size: 15,
                                ),
                                label: const Text(
                                  'Request',
                                  style: TextStyle(
                                    fontSize: 9.2,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton.filledTonal(
                            tooltip: preferred
                                ? 'Remove preferred supplier'
                                : 'Mark preferred supplier',
                            visualDensity: VisualDensity.compact,
                            onPressed: onTogglePreferred,
                            icon: Icon(
                              preferred
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 18,
                            ),
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
      );
    }

    return FarmCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 150,
                  child: image == null
                      ? Container(
                          color: FarmColors.primarySoft,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.agriculture_outlined,
                            color: FarmColors.deepGreen,
                            size: 38,
                          ),
                        )
                      : Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: FarmColors.primarySoft,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.agriculture_outlined,
                              color: FarmColors.deepGreen,
                              size: 38,
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: FarmColors.deepGreen.withOpacity(.90),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'JAMAICAN FARM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .45,
                    ),
                  ),
                ),
              ),
              if (farm.hpjVerified)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: FarmColors.gold,
                          size: 13,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'HPJ VERIFIED',
                          style: TextStyle(
                            color: FarmColors.deepGreen,
                            fontSize: 7.9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farm.publicName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: FarmColors.mutedText,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        farm.locationLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 9.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                if (farm.publicBio.trim().isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Text(
                    farm.publicBio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 9.4,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                if (farm.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: farm.tags
                        .take(4)
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: FarmColors.primarySoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: FarmColors.deepGreen,
                                fontSize: 8.3,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],

                if (practices.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.eco_outlined,
                        color: FarmColors.green,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          practices.join(' • '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 8.9,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 11),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: preferred
                        ? const Color(0xFFFFF8E9)
                        : FarmColors.cardSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        preferred
                            ? Icons.star_rounded
                            : relationship != null
                                ? Icons.handshake_outlined
                                : Icons.history_rounded,
                        color: preferred
                            ? FarmColors.gold
                            : FarmColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          relationship?.reason ??
                              (preferred
                                  ? 'Preferred supplier'
                                  : 'Build a repeat HPJ sourcing relationship'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FarmColors.deepGreen,
                            fontSize: 8.4,
                            height: 1.3,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: onTogglePreferred,
                        icon: Icon(
                          preferred
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 15,
                        ),
                        label: Text(
                          preferred ? 'Preferred' : 'Prefer',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onViewFarm,
                        icon: const Icon(
                          Icons.storefront_outlined,
                          size: 17,
                        ),
                        label: const Text('View Farm'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onRequestSupply,
                        icon: const Icon(
                          Icons.add_business_outlined,
                          size: 17,
                        ),
                        label: const Text('Request Supply'),
                      ),
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

class WholesaleSupplierRequestScreen extends StatefulWidget {
  final BusinessAccount account;
  final FarmPublicProfileRecord farm;
  final Product? initialProduct;

  const WholesaleSupplierRequestScreen({
    super.key,
    required this.account,
    required this.farm,
    this.initialProduct,
  });

  @override
  State<WholesaleSupplierRequestScreen> createState() =>
      _WholesaleSupplierRequestScreenState();
}

class _WholesaleSupplierRequestScreenState
    extends State<WholesaleSupplierRequestScreen> {
  final productNameController = TextEditingController();
  final quantityController = TextEditingController();
  final unitController = TextEditingController(text: 'lb');
  final notesController = TextEditingController();

  late Future<FarmPublicProfileBundle> _farmFuture;

  Product? selectedProduct;
  DateTime needByDate = DateTime.now().add(const Duration(days: 7));
  String frequency = 'one_time';
  String certainty = 'likely';
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    _farmFuture = fetchFarmPublicProfileBundle(widget.farm.farmerId);

    final initial = widget.initialProduct;
    if (initial != null) {
      selectedProduct = initial;
      productNameController.text = initial.name;

      final initialUnit = initial.unit?.trim() ?? '';
      if (initialUnit.isNotEmpty) {
        unitController.text = initialUnit;
      }
    }
  }

  @override
  void dispose() {
    productNameController.dispose();
    quantityController.dispose();
    unitController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: needByDate.isBefore(now) ? now : needByDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, 12, 31),
    );

    if (picked != null && mounted) {
      setState(() => needByDate = picked);
    }
  }

  String _dateLabel(DateTime value) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  Future<void> _submit() async {
    if (submitting) return;

    final productName = productNameController.text.trim();
    final quantity = double.tryParse(
      quantityController.text.trim().replaceAll(',', ''),
    );
    final unit = unitController.text.trim();

    if (productName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter or choose the produce you need.')),
      );
      return;
    }

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity.')),
      );
      return;
    }

    if (unit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the unit, for example lb or case.')),
      );
      return;
    }

    setState(() => submitting = true);

    try {
      final preferenceNote =
          'Preferred HPJ farm: ${widget.farm.publicName} '
          '(farmer_id: ${widget.farm.farmerId}).';
      final userNotes = notesController.text.trim();
      final combinedNotes =
          userNotes.isEmpty ? preferenceNote : '$preferenceNote\n$userNotes';

      final forecast = await createWholesaleDemandForecast(
        productId: selectedProduct?.id,
        productName: productName,
        category: selectedProduct?.category,
        quantity: quantity,
        unit: unit,
        needByDate: needByDate,
        frequency: frequency,
        certainty: certainty,
        notes: combinedNotes,
      );

      try {
        await saveWholesalePreferredSupplier(
          forecast: forecast,
          farm: widget.farm,
        );
      } catch (error) {
        // The business requirement itself is already safely saved in the
        // existing procurement pipeline. Do not ask the buyer to submit twice.
        farmDebugLog(
          'Preferred supplier link was not saved, but demand forecast exists: $error',
        );
      }

      try {
        await createAdminNotification(
          title: 'Preferred-farm supply request',
          message:
              '${widget.account.displayName} prefers ${widget.farm.publicName} '
              'for ${forecast.formattedQuantity} of ${forecast.productName}.',
          type: 'wholesale',
          actionType: 'admin_wholesale_demand',
          actionId: forecast.id,
          dedupeKey: 'preferred-farm:${forecast.id}',
        );
      } catch (error) {
        farmDebugLog(
          'Preferred-farm admin notification skipped safely: $error',
        );
      }

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline_rounded,
            color: FarmColors.success,
            size: 38,
          ),
          title: const Text('Supply request received'),
          content: Text(
            'HPJ will first check ${widget.farm.publicName}. '
            'If needed, HPJ may recommend another verified farm to complete the requirement.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );

      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: const Text('Preferred Farm Request'),
      ),
      body: FarmPage(
        child: FutureBuilder<FarmPublicProfileBundle>(
          future: _farmFuture,
          builder: (context, snapshot) {
            final bundle = snapshot.data;
            final products = bundle?.products ?? const <Product>[];

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
              children: [
                _PremiumPreferredFarmRequestHero(
                  farm: widget.farm,
                  businessName: widget.account.displayName,
                  productCount: products.length,
                ),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F6EF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFDCE4D8),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: FarmColors.deepGreen,
                        size: 19,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This creates an HPJ sourcing requirement, not a direct contract with the farm. HPJ checks the preferred farm first and manages the sourcing process.',
                          style: TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 9.5,
                            height: 1.38,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                FarmCard(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _PreferredFarmSectionTitle(
                        icon: Icons.shopping_basket_outlined,
                        title: 'Produce requirement',
                        subtitle:
                            'Choose one of this farm’s current HPJ products or type another item for HPJ to source.',
                      ),
                      const SizedBox(height: 13),

                      if (snapshot.connectionState ==
                              ConnectionState.waiting &&
                          bundle == null)
                        const Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 11),
                            Expanded(
                              child: Text(
                                'Loading this farm’s HPJ supply...',
                              ),
                            ),
                          ],
                        )
                      else ...[
                        if (products.isNotEmpty) ...[
                          DropdownButtonFormField<String>(
                            value: products.any(
                              (product) =>
                                  product.id == selectedProduct?.id,
                            )
                                ? selectedProduct?.id
                                : null,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Choose from this farm',
                              prefixIcon: Icon(Icons.eco_outlined),
                            ),
                            items: products
                                .map(
                                  (product) => DropdownMenuItem<String>(
                                    value: product.id,
                                    child: Text(
                                      product.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              Product? match;

                              for (final product in products) {
                                if (product.id == value) {
                                  match = product;
                                  break;
                                }
                              }

                              if (match == null) return;

                              setState(() {
                                selectedProduct = match;
                                productNameController.text = match!.name;

                                final selectedUnit =
                                    match.unit?.trim() ?? '';

                                if (selectedUnit.isNotEmpty) {
                                  unitController.text = selectedUnit;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                        ],

                        TextField(
                          controller: productNameController,
                          decoration: const InputDecoration(
                            labelText: 'Produce needed',
                            prefixIcon:
                                Icon(Icons.shopping_basket_outlined),
                          ),
                        ),
                        const SizedBox(height: 11),

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: quantityController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Quantity',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: unitController,
                                decoration: const InputDecoration(
                                  labelText: 'Unit',
                                  hintText: 'lb, case, kg',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                FarmCard(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _PreferredFarmSectionTitle(
                        icon: Icons.calendar_month_outlined,
                        title: 'Timing & pattern',
                        subtitle:
                            'Tell HPJ when the business needs it and whether this is a one-time or recurring requirement.',
                      ),
                      const SizedBox(height: 13),

                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Need by',
                            prefixIcon:
                                Icon(Icons.calendar_month_outlined),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _dateLabel(needByDate),
                                  style: const TextStyle(
                                    color: FarmColors.ink,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: FarmColors.mutedText,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 11),

                      DropdownButtonFormField<String>(
                        value: frequency,
                        decoration: const InputDecoration(
                          labelText: 'How often?',
                          prefixIcon: Icon(Icons.repeat_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'one_time',
                            child: Text('One time'),
                          ),
                          DropdownMenuItem(
                            value: 'weekly',
                            child: Text('Weekly'),
                          ),
                          DropdownMenuItem(
                            value: 'biweekly',
                            child: Text('Every 2 weeks'),
                          ),
                          DropdownMenuItem(
                            value: 'monthly',
                            child: Text('Monthly'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => frequency = value);
                          }
                        },
                      ),
                      const SizedBox(height: 11),

                      DropdownButtonFormField<String>(
                        value: certainty,
                        decoration: const InputDecoration(
                          labelText: 'Planning confidence',
                          prefixIcon: Icon(Icons.analytics_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'tentative',
                            child: Text('Tentative'),
                          ),
                          DropdownMenuItem(
                            value: 'likely',
                            child: Text('Likely'),
                          ),
                          DropdownMenuItem(
                            value: 'expected',
                            child: Text(
                              'Expected / confirmed need',
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => certainty = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                FarmCard(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _PreferredFarmSectionTitle(
                        icon: Icons.notes_outlined,
                        title: 'Sourcing notes',
                        subtitle:
                            'Add size, grade, packaging, receiving or delivery details that HPJ should know.',
                      ),
                      const SizedBox(height: 13),
                      TextField(
                        controller: notesController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Notes for HPJ',
                          hintText:
                              'Size, grade, packaging, delivery pattern or other requirement',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: FarmColors.warning.withOpacity(.18),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: FarmColors.warning,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Preferred means HPJ checks this farm first. Supply, pricing, collection, receiving and fulfilment remain managed through HPJ, and another verified farm may be used if needed.',
                          style: TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 9.3,
                            height: 1.38,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                PrimaryFarmButton(
                  label: submitting
                      ? 'Sending Request...'
                      : 'Send Preferred-Farm Request',
                  icon: Icons.send_outlined,
                  onPressed: submitting ? null : _submit,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}


class _PremiumPreferredFarmRequestHero extends StatelessWidget {
  final FarmPublicProfileRecord farm;
  final String businessName;
  final int productCount;

  const _PremiumPreferredFarmRequestHero({
    required this.farm,
    required this.businessName,
    required this.productCount,
  });

  @override
  Widget build(BuildContext context) {
    final image = cleanHostedImageUrl(farm.coverImageUrl) ??
        cleanHostedImageUrl(farm.logoImageUrl);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: FarmColors.deepGreen,
        boxShadow: [
          BoxShadow(
            color: FarmColors.deepGreen.withOpacity(.13),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 138,
            width: double.infinity,
            child: image == null
                ? Container(
                    color: FarmColors.green,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.agriculture_outlined,
                      color: Colors.white,
                      size: 42,
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: FarmColors.green,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.agriculture_outlined,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color(0xCC123C2C),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PREFERRED FARM REQUEST',
                            style: TextStyle(
                              color: Color(0xFFCFE0CF),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            farm.publicName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (farm.hpjVerified)
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFFE8C768),
                        size: 22,
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  farm.locationLine,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.76),
                    fontSize: 9.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(
                      child: _PreferredFarmHeroMetric(
                        value: '$productCount',
                        label: 'Current HPJ products',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PreferredFarmHeroMetric(
                        value: farm.hpjVerified ? 'YES' : 'PUBLISHED',
                        label: 'HPJ verification',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PreferredFarmHeroMetric(
                        value: businessName.trim().isEmpty
                            ? 'BUSINESS'
                            : 'PREFERRED',
                        label: 'Sourcing route',
                      ),
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

class _PreferredFarmHeroMetric extends StatelessWidget {
  final String value;
  final String label;

  const _PreferredFarmHeroMetric({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(.70),
              fontSize: 7.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferredFarmSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PreferredFarmSectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: FarmColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: FarmColors.deepGreen,
            size: 18,
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
                  color: FarmColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 9.2,
                  height: 1.3,
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

// ============================================================================
// SOURCE SECTION: business_finance.dart
// ============================================================================
// HPJ PHASE 88 — BUSINESS INVOICES + STATEMENTS
// Extracted from wholesale_management.dart without changing runtime behavior.

class BusinessWholesaleInvoicesScreen extends StatefulWidget {
  final BusinessAccount account;

  const BusinessWholesaleInvoicesScreen({
    super.key,
    required this.account,
  });

  @override
  State<BusinessWholesaleInvoicesScreen> createState() =>
      _BusinessWholesaleInvoicesScreenState();
}

class _BusinessWholesaleInvoicesScreenState
    extends State<BusinessWholesaleInvoicesScreen> {
  late Future<List<WholesaleInvoice>> _future;
  late Future<List<WholesalePaymentSubmission>> _submissionsFuture;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _future = fetchMyWholesaleInvoices();
    _submissionsFuture = fetchMyWholesalePaymentSubmissions();
  }

  Future<void> _reload() async {
    final nextInvoices = fetchMyWholesaleInvoices();
    final nextSubmissions = fetchMyWholesalePaymentSubmissions();

    setState(() {
      _future = nextInvoices;
      _submissionsFuture = nextSubmissions;
    });

    await Future.wait<Object>([
      nextInvoices,
      nextSubmissions,
    ]);
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return '—';
    final date = value.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Color _paymentColor(WholesaleInvoice invoice) {
    if (invoice.isPaid) return FarmColors.green;
    if (invoice.isOverdue) return FarmColors.danger;
    if (invoice.isPartiallyPaid) return FarmColors.warning;
    return FarmColors.primary;
  }

  String _paymentLabel(WholesaleInvoice invoice) {
    if (invoice.isOverdue) return 'OVERDUE';
    return invoice.paymentStatusLabel.toUpperCase();
  }

  Widget _metric({
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow({
    required String label,
    required String value,
    bool strong = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: strong ? FarmColors.ink : FarmColors.mutedText,
                fontSize: strong ? 11 : 10,
                fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: strong ? FarmColors.ink : FarmColors.mutedText,
              fontSize: strong ? 12 : 10,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareInvoice(WholesaleInvoice invoice) async {
    try {
      final bytes = await _buildBusinessPortalInvoicePdf(invoice);
      final safeName = invoice.invoiceNumber.replaceAll(
        RegExp(r'[^A-Za-z0-9_-]'),
        '_',
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename: '$safeName.pdf',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not create invoice PDF: ${friendlyAppError(error)}',
          ),
        ),
      );
    }
  }

  Future<void> _shareReceipt(
    WholesaleInvoice invoice,
    WholesaleInvoicePayment payment,
  ) async {
    try {
      final bytes = await _buildBusinessPortalReceiptPdf(invoice, payment);
      final receiptId = _businessPortalShortId(payment.id);

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'HPJ-Wholesale-Receipt-$receiptId.pdf',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not create receipt PDF: ${friendlyAppError(error)}',
          ),
        ),
      );
    }
  }

  List<WholesaleInvoice> _filtered(List<WholesaleInvoice> invoices) {
    switch (_filter) {
      case 'outstanding':
        return invoices.where((invoice) => !invoice.isPaid).toList();
      case 'paid':
        return invoices.where((invoice) => invoice.isPaid).toList();
      case 'overdue':
        return invoices.where((invoice) => invoice.isOverdue).toList();
      default:
        return invoices;
    }
  }

  WholesalePaymentSubmission? _latestSubmissionForInvoice(
    WholesaleInvoice invoice,
    List<WholesalePaymentSubmission> submissions,
  ) {
    final matches =
        submissions.where((item) => item.invoiceId == invoice.id).toList()
          ..sort((a, b) {
            final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });

    return matches.isEmpty ? null : matches.first;
  }

  Future<void> _cancelPaymentConfirmation(
    WholesalePaymentSubmission submission,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Payment Confirmation?'),
        content: const Text(
          'This removes the confirmation from HPJ\'s review queue. The invoice and any recorded payments are not changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Back'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel Confirmation'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await cancelWholesalePaymentConfirmation(submission);
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment confirmation cancelled.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  Future<void> _submitPaymentProof(WholesaleInvoice invoice) async {
    final amountController = TextEditingController(
      text: invoice.amountDue.toStringAsFixed(2),
    );
    final referenceController = TextEditingController();
    final noteController = TextEditingController();

    String method = 'bank_transfer';
    PickedProductImage? proofFile;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> chooseProof() async {
              HpjImageSource source = HpjImageSource.gallery;

              if (!kIsWeb) {
                final selected = await showModalBottomSheet<HpjImageSource>(
                  context: dialogContext,
                  showDragHandle: true,
                  builder: (sheetContext) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera_alt_outlined),
                          title: const Text('Take payment proof photo'),
                          onTap: () => Navigator.pop(
                            sheetContext,
                            HpjImageSource.camera,
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library_outlined),
                          title: const Text('Choose screenshot / image'),
                          onTap: () => Navigator.pop(
                            sheetContext,
                            HpjImageSource.gallery,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );

                if (selected == null) return;
                source = selected;
              }

              try {
                final image = await pickProductImageFromDevice(
                  source: source,
                );

                if (image != null) {
                  setDialogState(() => proofFile = image);
                }
              } catch (error) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(friendlyAppError(error))),
                );
              }
            }

            return AlertDialog(
              title: Text('Confirm Payment • ${invoice.invoiceNumber}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Balance due: ${invoice.formattedDue}',
                      style: const TextStyle(
                        color: FarmColors.green,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount paid',
                        prefixText: 'J\$ ',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: method,
                      decoration: const InputDecoration(
                        labelText: 'Payment method',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'bank_transfer',
                          child: Text('Bank Transfer'),
                        ),
                        DropdownMenuItem(
                          value: 'cheque',
                          child: Text('Cheque'),
                        ),
                        DropdownMenuItem(
                          value: 'cash',
                          child: Text('Cash'),
                        ),
                        DropdownMenuItem(
                          value: 'card',
                          child: Text('Card'),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => method = value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: referenceController,
                      decoration: const InputDecoration(
                        labelText: 'Payment reference',
                        hintText: 'Bank reference, cheque number, etc.',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: chooseProof,
                        icon: Icon(
                          proofFile == null
                              ? Icons.upload_file_outlined
                              : Icons.check_circle_outline,
                        ),
                        label: Text(
                          proofFile == null
                              ? 'Choose Payment Screenshot / Photo'
                              : 'Payment Proof Selected',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'HPJ will verify the payment before it is added to your invoice balance.',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Back'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(
                      amountController.text.trim().replaceAll(',', ''),
                    );

                    if (amount == null ||
                        amount <= 0 ||
                        amount > invoice.amountDue + .01) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Enter an amount between J\$0.01 and ${invoice.formattedDue}.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (proofFile == null) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Choose a payment proof image first.'),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Submit for Verification'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || proofFile == null) {
      amountController.dispose();
      referenceController.dispose();
      noteController.dispose();
      return;
    }

    final amount = double.parse(
      amountController.text.trim().replaceAll(',', ''),
    );

    try {
      final path = await uploadWholesalePaymentProof(
        invoice: invoice,
        image: proofFile!,
      );

      await submitWholesalePaymentConfirmation(
        invoice: invoice,
        amount: amount,
        paymentMethod: method,
        paymentReference: referenceController.text,
        proofPath: path,
        note: noteController.text,
      );

      await _reload();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment confirmation sent to HPJ for verification.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      amountController.dispose();
      referenceController.dispose();
      noteController.dispose();
    }
  }

  Widget _paymentSubmissionCard(
    WholesaleInvoice invoice,
    WholesalePaymentSubmission submission,
  ) {
    final color = submission.isPending
        ? FarmColors.warning
        : submission.isRejected
            ? FarmColors.danger
            : submission.isApproved
                ? FarmColors.green
                : FarmColors.mutedText;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withOpacity(.07),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withOpacity(.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, color: color, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  submission.statusLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                submission.formattedAmount,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            submission.isPending
                ? 'HPJ is checking your payment proof. Your invoice balance will update after approval.'
                : submission.isRejected
                    ? (submission.adminNote.isEmpty
                        ? 'HPJ could not verify this payment. You may submit a new confirmation.'
                        : submission.adminNote)
                    : submission.isApproved
                        ? 'This payment confirmation was approved.'
                        : 'This payment confirmation was cancelled.',
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 9.5,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (submission.paymentReference.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              'Ref: ${submission.paymentReference}',
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (submission.isPending) ...[
            const SizedBox(height: 5),
            TextButton(
              onPressed: () => _cancelPaymentConfirmation(submission),
              child: const Text('Cancel Confirmation'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _invoiceCard(
    WholesaleInvoice invoice,
    List<WholesalePaymentSubmission> submissions,
  ) {
    final color = _paymentColor(invoice);
    final confirmedPayments =
        invoice.payments.where((payment) => payment.isConfirmed).toList();

    final latestSubmission = _latestSubmissionForInvoice(
      invoice,
      submissions,
    );

    final hasPendingSubmission = latestSubmission?.isPending == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FarmCard(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.invoiceNumber,
                        style: const TextStyle(
                          color: FarmColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Issued ${_dateLabel(invoice.issueDate ?? invoice.issuedAt)}'
                        ' • Due ${_dateLabel(invoice.dueDate)}',
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(.10),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    _paymentLabel(invoice),
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...invoice.items.take(4).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.productName} • ${item.formattedQuantity}',
                            style: const TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          item.formattedLineTotal,
                          style: const TextStyle(
                            color: FarmColors.ink,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (invoice.items.length > 4)
              Text(
                '+ ${invoice.items.length - 4} more items',
                style: const TextStyle(
                  color: FarmColors.primary,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            const Divider(height: 22),
            _amountRow(label: 'Invoice Total', value: invoice.formattedTotal),
            if (invoice.paidAmount > 0)
              _amountRow(label: 'Paid', value: invoice.formattedPaid),
            _amountRow(
              label: 'Balance Due',
              value: invoice.formattedDue,
              strong: true,
            ),
            if (invoice.customerNote.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FarmColors.cardSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FarmColors.line),
                ),
                child: Text(
                  invoice.customerNote,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 10,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 11),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _shareInvoice(invoice),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
                label: const Text('Share / Save Invoice PDF'),
              ),
            ),
            if (latestSubmission != null &&
                (latestSubmission.isPending || latestSubmission.isRejected))
              _paymentSubmissionCard(invoice, latestSubmission),
            if (!invoice.isPaid && !hasPendingSubmission) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _submitPaymentProof(invoice),
                  icon: const Icon(Icons.account_balance_outlined),
                  label: Text(
                    latestSubmission?.isRejected == true
                        ? 'Resubmit Payment Confirmation'
                        : 'I Have Made a Payment',
                  ),
                ),
              ),
            ],
            if (invoice.payments.isNotEmpty) ...[
              const SizedBox(height: 6),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  'Payment History (${invoice.payments.length})',
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                children: invoice.payments.map((payment) {
                  final reversed = payment.isReversed;
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 7),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: FarmColors.cardSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: FarmColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                payment.formattedAmount,
                                style: TextStyle(
                                  color: reversed
                                      ? FarmColors.mutedText
                                      : FarmColors.green,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              payment.statusLabel,
                              style: TextStyle(
                                color: reversed
                                    ? FarmColors.danger
                                    : FarmColors.green,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${payment.methodLabel} • ${_dateLabel(payment.paidAt)}',
                          style: const TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 9.5,
                          ),
                        ),
                        if (payment.paymentReference.isNotEmpty)
                          Text(
                            'Ref: ${payment.paymentReference}',
                            style: const TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (reversed && payment.reversalReason.isNotEmpty)
                          Text(
                            'Reversed: ${payment.reversalReason}',
                            style: const TextStyle(
                              color: FarmColors.danger,
                              fontSize: 9.5,
                            ),
                          ),
                        if (!reversed) ...[
                          const SizedBox(height: 5),
                          OutlinedButton.icon(
                            onPressed: () => _shareReceipt(invoice, payment),
                            icon: const Icon(
                              Icons.receipt_long_outlined,
                              size: 15,
                            ),
                            label: const Text('Receipt PDF'),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            if (invoice.isPaid && confirmedPayments.isNotEmpty) ...[
              const SizedBox(height: 5),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FarmColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      color: FarmColors.green,
                      size: 18,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'PAID IN FULL',
                      style: TextStyle(
                        color: FarmColors.green,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: const Text('Invoices & Payments'),
      ),
      body: FarmPage(
        child: FutureBuilder<List<Object>>(
          future: Future.wait<Object>([
            _future,
            _submissionsFuture,
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                    ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    18,
                    18,
                    110,
                  ),
                  children: [
                    FarmEmptyState(
                      icon: Icons.error_outline,
                      title:
                          'Invoices could not be loaded',
                      message:
                          friendlyAppError(snapshot.error!),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data;

            final invoices = data == null
                ? const <WholesaleInvoice>[]
                : data[0] as List<WholesaleInvoice>;

            final submissions = data == null
                ? const <WholesalePaymentSubmission>[]
                : data[1]
                    as List<WholesalePaymentSubmission>;

            final outstanding = invoices
                .where((invoice) => !invoice.isPaid)
                .fold<double>(
                  0,
                  (sum, invoice) =>
                      sum + invoice.amountDue,
                );

            final overdue = invoices
                .where((invoice) => invoice.isOverdue)
                .length;

            final paid = invoices
                .where((invoice) => invoice.isPaid)
                .length;

            final pendingConfirmations = submissions
                .where((item) => item.isPending)
                .length;

            final filtered = _filtered(invoices);

            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  18,
                  16,
                  18,
                  110,
                ),
                children: [
                  _PremiumWholesaleInvoicesHero(
                    businessName:
                        widget.account.displayName,
                    outstanding: outstanding,
                    overdue: overdue,
                    paid: paid,
                    pendingConfirmations:
                        pendingConfirmations,
                    invoiceCount: invoices.length,
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Invoice history',
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Review balances, submit payment confirmation and save invoice or receipt PDFs.',
                    style: TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 9.5,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _filter == 'all',
                          onSelected: (_) =>
                              setState(
                            () => _filter = 'all',
                          ),
                        ),
                        const SizedBox(width: 7),
                        ChoiceChip(
                          label:
                              const Text('Outstanding'),
                          selected:
                              _filter == 'outstanding',
                          onSelected: (_) =>
                              setState(
                            () =>
                                _filter = 'outstanding',
                          ),
                        ),
                        const SizedBox(width: 7),
                        ChoiceChip(
                          label: const Text('Overdue'),
                          selected:
                              _filter == 'overdue',
                          onSelected: (_) =>
                              setState(
                            () => _filter = 'overdue',
                          ),
                        ),
                        const SizedBox(width: 7),
                        ChoiceChip(
                          label: const Text('Paid'),
                          selected: _filter == 'paid',
                          onSelected: (_) =>
                              setState(
                            () => _filter = 'paid',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (pendingConfirmations > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E9),
                        borderRadius:
                            BorderRadius.circular(16),
                        border: Border.all(
                          color: FarmColors.warning
                              .withOpacity(.20),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.hourglass_top_rounded,
                            color: FarmColors.warning,
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$pendingConfirmations payment confirmation${pendingConfirmations == 1 ? '' : 's'} '
                              '${pendingConfirmations == 1 ? 'is' : 'are'} waiting for HPJ review.',
                              style: const TextStyle(
                                color:
                                    FarmColors.mutedText,
                                fontSize: 9.7,
                                height: 1.35,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (invoices.isEmpty)
                    const FarmEmptyState(
                      icon:
                          Icons.receipt_long_outlined,
                      title:
                          'No issued invoices yet',
                      message:
                          'Issued wholesale invoices will appear here automatically.',
                    )
                  else if (filtered.isEmpty)
                    const FarmEmptyState(
                      icon:
                          Icons.filter_alt_off_outlined,
                      title:
                          'Nothing in this filter',
                      message:
                          'Choose another invoice filter to continue.',
                    )
                  else
                    ...filtered.map(
                      (invoice) => _invoiceCard(
                        invoice,
                        submissions,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PremiumWholesaleInvoicesHero extends StatelessWidget {
  final String businessName;
  final double outstanding;
  final int overdue;
  final int paid;
  final int pendingConfirmations;
  final int invoiceCount;

  const _PremiumWholesaleInvoicesHero({
    required this.businessName,
    required this.outstanding,
    required this.overdue,
    required this.paid,
    required this.pendingConfirmations,
    required this.invoiceCount,
  });

  Widget _metric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(.16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: const Color(0xFFE8C768),
              size: 17,
            ),
            const SizedBox(height: 7),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(.72),
                fontSize: 8.6,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = businessName.trim().isEmpty
        ? 'Business finance'
        : businessName.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FarmColors.deepGreen,
            FarmColors.green,
            Color(0xFF4E8157),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color:
                FarmColors.deepGreen.withOpacity(.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Color(0xFFE8C768),
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'INVOICES & PAYMENTS',
                style: TextStyle(
                  color: Color(0xFFCFE0CF),
                  fontSize: 10.3,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            outstanding > 0
                ? '${formatJmd(outstanding)} currently outstanding across issued wholesale invoices.'
                : 'Your currently loaded issued invoices have no outstanding balance.',
            style: TextStyle(
              color: Colors.white.withOpacity(.83),
              fontSize: 10.6,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _metric(
                icon: Icons.payments_outlined,
                value: formatJmd(outstanding),
                label: 'Outstanding',
              ),
              const SizedBox(width: 8),
              _metric(
                icon: Icons.warning_amber_rounded,
                value: '$overdue',
                label: 'Overdue',
              ),
              const SizedBox(width: 8),
              _metric(
                icon: Icons.verified_outlined,
                value: '$paid',
                label: 'Paid',
              ),
            ],
          ),
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.10),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(.14),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  pendingConfirmations > 0
                      ? Icons.hourglass_top_rounded
                      : Icons.receipt_long_outlined,
                  color: const Color(0xFFE8C768),
                  size: 17,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    pendingConfirmations > 0
                        ? '$pendingConfirmations payment confirmation${pendingConfirmations == 1 ? '' : 's'} waiting for review'
                        : '$invoiceCount invoice record${invoiceCount == 1 ? '' : 's'} loaded',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.83),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
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
}

// =====================================================
// PHASE 3P — BUSINESS WHOLESALE ACCOUNT STATEMENT
// =====================================================

class BusinessWholesaleStatementScreen extends StatefulWidget {
  const BusinessWholesaleStatementScreen({super.key});

  @override
  State<BusinessWholesaleStatementScreen> createState() =>
      _BusinessWholesaleStatementScreenState();
}

class _BusinessWholesaleStatementScreenState
    extends State<BusinessWholesaleStatementScreen> {
  late Future<_WholesaleAccountStatementSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchMyWholesaleAccountStatement();
  }

  Future<void> _reload() async {
    final next = fetchMyWholesaleAccountStatement();
    setState(() {
      _future = next;
    });
    await next;
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return '—';
    final date = value.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  int _daysOverdue(WholesaleInvoice invoice) {
    final due = invoice.dueDate?.toLocal();
    if (due == null || invoice.amountDue <= 0.005) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final value = today.difference(dueDay).inDays;
    return value < 0 ? 0 : value;
  }

  Widget _metric(String label, String value) {
    return Container(
      width: 132,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Future<pw.MemoryImage?> _statementLogo() async {
    try {
      final bytes = await rootBundle.load('lib/assets/images/logo.png');
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  String _pdfMoney(double value) => 'J\$${value.toStringAsFixed(2)}';

  String _pdfDate(DateTime? value) {
    if (value == null) return '—';
    final date = value.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<Uint8List> _buildStatementPdf(
    _WholesaleAccountStatementSnapshot data,
  ) async {
    final pdf = pw.Document();
    final logo = await _statementLogo();
    final green = PdfColor.fromInt(0xFF1F6B3A);
    final softGreen = PdfColor.fromInt(0xFFEAF3EC);
    final account = data.account;
    final aging = data.aging;
    final openInvoices = data.invoices
        .where(
            (invoice) => invoice.isIssued && !invoice.isPaid && !invoice.isVoid)
        .toList()
      ..sort((a, b) {
        final ad = a.dueDate ?? a.issueDate ?? a.createdAt ?? DateTime(2100);
        final bd = b.dueDate ?? b.issueDate ?? b.createdAt ?? DateTime(2100);
        return ad.compareTo(bd);
      });

    final recentPayments =
        <MapEntry<WholesaleInvoice, WholesaleInvoicePayment>>[];
    for (final invoice in data.invoices) {
      for (final payment in invoice.payments.where((p) => p.isConfirmed)) {
        recentPayments.add(MapEntry(invoice, payment));
      }
    }
    recentPayments.sort((a, b) {
      final ad = a.value.paidAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.value.paidAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });

    pw.Widget amountBox(String label, double amount) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: softGreen,
            borderRadius: pw.BorderRadius.circular(7),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                label,
                style:
                    const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                _pdfMoney(amount),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: green,
                ),
              ),
            ],
          ),
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 30, 34, 34),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'The Harvest Place Ja • Wholesale Account Statement',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            ),
          ],
        ),
        build: (_) => [
          pw.Row(
            children: [
              pw.SizedBox(
                width: 58,
                height: 58,
                child: logo == null
                    ? pw.Center(
                        child: pw.Text(
                          'HPJ',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: green,
                          ),
                        ),
                      )
                    : pw.Image(logo, fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'THE HARVEST PLACE JA',
                      style: pw.TextStyle(
                        fontSize: 19,
                        fontWeight: pw.FontWeight.bold,
                        color: green,
                      ),
                    ),
                    pw.Text(
                      'Mountainside, St. Elizabeth, Jamaica | Tel: 876-339-1395',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'WHOLESALE ACCOUNT STATEMENT',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Divider(color: green),
          pw.SizedBox(height: 12),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(11),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(7),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(account.displayName,
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      if (account.contactName.isNotEmpty)
                        pw.Text(account.contactName,
                            style: const pw.TextStyle(fontSize: 8.5)),
                      if (account.address.isNotEmpty)
                        pw.Text(account.address,
                            style: const pw.TextStyle(fontSize: 8.5)),
                      if (account.parish.isNotEmpty)
                        pw.Text(account.parish,
                            style: const pw.TextStyle(fontSize: 8.5)),
                      if (account.phone.isNotEmpty)
                        pw.Text(account.phone,
                            style: const pw.TextStyle(fontSize: 8.5)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(11),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(7),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Statement date: ${_pdfDate(DateTime.now())}',
                          style: const pw.TextStyle(fontSize: 8.5)),
                      pw.Text('Account: ${account.wholesaleCreditStatusLabel}',
                          style: const pw.TextStyle(fontSize: 8.5)),
                      pw.Text('Terms: ${account.wholesalePaymentTermsLabel}',
                          style: const pw.TextStyle(fontSize: 8.5)),
                      pw.Text(
                        account.wholesaleCreditLimit > 0
                            ? 'Credit limit: ${_pdfMoney(account.wholesaleCreditLimit)}'
                            : 'Credit limit: Not set',
                        style: const pw.TextStyle(fontSize: 8.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text('AGING SUMMARY',
              style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold, color: green)),
          pw.SizedBox(height: 7),
          pw.Row(
            children: [
              amountBox('Current', aging.current),
              pw.SizedBox(width: 6),
              amountBox('1-30 Days', aging.days1To30),
              pw.SizedBox(width: 6),
              amountBox('31-60 Days', aging.days31To60),
              pw.SizedBox(width: 6),
              amountBox('61+ Days', aging.days61Plus),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'TOTAL OUTSTANDING: ${_pdfMoney(aging.total)}',
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold, color: green),
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text('OPEN INVOICES',
              style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold, color: green)),
          pw.SizedBox(height: 7),
          if (openInvoices.isEmpty)
            pw.Text('No outstanding invoices.',
                style: const pw.TextStyle(fontSize: 9))
          else
            pw.Table.fromTextArray(
              headers: const [
                'Invoice',
                'Issued',
                'Due',
                'Total',
                'Paid',
                'Balance'
              ],
              data: openInvoices
                  .map((invoice) => [
                        invoice.invoiceNumber,
                        _pdfDate(invoice.issueDate ?? invoice.issuedAt),
                        _pdfDate(invoice.dueDate),
                        _pdfMoney(invoice.totalAmount),
                        _pdfMoney(invoice.paidAmount),
                        _pdfMoney(invoice.amountDue),
                      ])
                  .toList(),
              headerDecoration: pw.BoxDecoration(color: green),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
              cellPadding: const pw.EdgeInsets.all(5),
            ),
          if (recentPayments.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text('RECENT PAYMENTS',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: green)),
            pw.SizedBox(height: 7),
            ...recentPayments.take(10).map(
                  (entry) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColors.grey300, width: .4)),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            '${_pdfDate(entry.value.paidAt)} • ${entry.key.invoiceNumber} • ${entry.value.methodLabel}',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Text(
                          _pdfMoney(entry.value.amount),
                          style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: green),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          pw.SizedBox(height: 20),
          pw.Text(
            'Please quote your invoice number when making payment. '
            'Contact The Harvest Place Ja if any transaction on this statement needs review.',
            style: const pw.TextStyle(
                fontSize: 8, color: PdfColors.grey700, height: 1.35),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> _shareStatement(
    _WholesaleAccountStatementSnapshot data,
  ) async {
    try {
      final bytes = await _buildStatementPdf(data);
      final safeName =
          data.account.displayName.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'HPJ-Wholesale-Statement-$safeName.pdf',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: const Text('Account Statement'),
      ),
      body: FarmPage(
        child: FutureBuilder<_WholesaleAccountStatementSnapshot>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                snapshot.data == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError ||
                snapshot.data == null) {
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    18,
                    18,
                    110,
                  ),
                  children: [
                    FarmEmptyState(
                      icon: Icons.error_outline,
                      title:
                          'Statement could not be loaded',
                      message: snapshot.hasError
                          ? friendlyAppError(
                              snapshot.error!,
                            )
                          : 'Please refresh and try again.',
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data!;
            final account = data.account;
            final aging = data.aging;

            final openInvoices = data.invoices
                .where(
                  (invoice) =>
                      invoice.isIssued &&
                      !invoice.isPaid &&
                      !invoice.isVoid,
                )
                .toList()
              ..sort((a, b) {
                final ad = a.dueDate ??
                    a.issueDate ??
                    a.createdAt ??
                    DateTime(2100);

                final bd = b.dueDate ??
                    b.issueDate ??
                    b.createdAt ??
                    DateTime(2100);

                return ad.compareTo(bd);
              });

            final overdueCount = openInvoices
                .where((invoice) => invoice.isOverdue)
                .length;

            final confirmedPaymentCount =
                data.invoices.fold<int>(
              0,
              (sum, invoice) =>
                  sum +
                  invoice.payments
                      .where(
                        (payment) =>
                            payment.isConfirmed,
                      )
                      .length,
            );

            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  18,
                  16,
                  18,
                  110,
                ),
                children: [
                  _PremiumWholesaleStatementHero(
                    businessName:
                        account.displayName,
                    outstanding: aging.total,
                    overdueCount: overdueCount,
                    openInvoiceCount:
                        openInvoices.length,
                    availableCredit:
                        data.availableCredit,
                    creditLabel:
                        account.wholesaleCreditStatusLabel,
                    termsLabel:
                        account.wholesalePaymentTermsLabel,
                    paymentCount:
                        confirmedPaymentCount,
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Aging summary',
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Outstanding issued invoices grouped by how long they have been due.',
                    style: TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 9.5,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final useFour =
                          constraints.maxWidth >= 900;

                      final columns =
                          useFour ? 4 : 2;

                      const gap = 8.0;

                      final width =
                          (constraints.maxWidth -
                                  gap *
                                      (columns - 1)) /
                              columns;

                      final metrics = <Widget>[
                        _PremiumStatementAgingMetric(
                          label: 'Current',
                          value:
                              formatJmd(aging.current),
                          danger: false,
                        ),
                        _PremiumStatementAgingMetric(
                          label: '1-30 Days',
                          value: formatJmd(
                            aging.days1To30,
                          ),
                          danger: false,
                        ),
                        _PremiumStatementAgingMetric(
                          label: '31-60 Days',
                          value: formatJmd(
                            aging.days31To60,
                          ),
                          danger:
                              aging.days31To60 > 0,
                        ),
                        _PremiumStatementAgingMetric(
                          label: '61+ Days',
                          value: formatJmd(
                            aging.days61Plus,
                          ),
                          danger:
                              aging.days61Plus > 0,
                        ),
                      ];

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: metrics
                            .map(
                              (metric) => SizedBox(
                                width: width,
                                child: metric,
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  FarmCard(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Outstanding',
                                style: TextStyle(
                                  color: FarmColors.ink,
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'All unpaid issued wholesale invoices',
                                style: TextStyle(
                                  color:
                                      FarmColors.mutedText,
                                  fontSize: 8.8,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatJmd(aging.total),
                          style: TextStyle(
                            color: aging.days61Plus > 0
                                ? FarmColors.danger
                                : FarmColors.green,
                            fontSize: 19,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _shareStatement(data),
                      icon: const Icon(
                        Icons.picture_as_pdf_outlined,
                      ),
                      label: const Text(
                        'Share / Save Statement PDF',
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Open invoices',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Outstanding invoices included in the statement balance.',
                              style: TextStyle(
                                color:
                                    FarmColors.mutedText,
                                fontSize: 9.3,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: FarmColors.primarySoft,
                          borderRadius:
                              BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${openInvoices.length}',
                          style: const TextStyle(
                            color:
                                FarmColors.deepGreen,
                            fontSize: 9,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 9),

                  if (openInvoices.isEmpty)
                    const FarmEmptyState(
                      icon: Icons.verified_outlined,
                      title: 'Account is clear',
                      message:
                          'There are no outstanding wholesale invoices.',
                    )
                  else
                    ...openInvoices.map(
                      (invoice) {
                        final overdueDays =
                            _daysOverdue(invoice);

                        return Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 9,
                          ),
                          child:
                              _PremiumStatementInvoiceCard(
                            invoice: invoice,
                            overdueDays:
                                overdueDays,
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 6),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFF1F6EF),
                      borderRadius:
                          BorderRadius.circular(15),
                      border: Border.all(
                        color:
                            const Color(0xFFDCE4D8),
                      ),
                    ),
                    child: const Text(
                      'This is an HPJ activity record, not a bank statement, '
                      'audited financial statement, credit rating or tax certificate.',
                      style: TextStyle(
                        color:
                            FarmColors.mutedText,
                        fontSize: 9.2,
                        height: 1.35,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PremiumWholesaleStatementHero extends StatelessWidget {
  final String businessName;
  final double outstanding;
  final int overdueCount;
  final int openInvoiceCount;
  final double availableCredit;
  final String creditLabel;
  final String termsLabel;
  final int paymentCount;

  const _PremiumWholesaleStatementHero({
    required this.businessName,
    required this.outstanding,
    required this.overdueCount,
    required this.openInvoiceCount,
    required this.availableCredit,
    required this.creditLabel,
    required this.termsLabel,
    required this.paymentCount,
  });

  Widget _metric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(.16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: const Color(0xFFE8C768),
              size: 17,
            ),
            const SizedBox(height: 7),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(.72),
                fontSize: 8.6,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = businessName.trim().isEmpty
        ? 'Business account'
        : businessName.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FarmColors.deepGreen,
            FarmColors.green,
            Color(0xFF4E8157),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color:
                FarmColors.deepGreen.withOpacity(.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: Color(0xFFE8C768),
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'BUSINESS ACCOUNT STATEMENT',
                style: TextStyle(
                  color: Color(0xFFCFE0CF),
                  fontSize: 10.2,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            outstanding > 0
                ? '${formatJmd(outstanding)} outstanding across $openInvoiceCount open invoice${openInvoiceCount == 1 ? '' : 's'}.'
                : 'Your current HPJ wholesale statement has no outstanding balance.',
            style: TextStyle(
              color: Colors.white.withOpacity(.83),
              fontSize: 10.6,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _metric(
                icon: Icons.payments_outlined,
                value: formatJmd(outstanding),
                label: 'Outstanding',
              ),
              const SizedBox(width: 8),
              _metric(
                icon: Icons.warning_amber_rounded,
                value: '$overdueCount',
                label: 'Overdue',
              ),
              const SizedBox(width: 8),
              _metric(
                icon: Icons.credit_card_outlined,
                value: formatJmd(availableCredit),
                label: 'Available credit',
              ),
            ],
          ),
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.10),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(.14),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_outlined,
                  color: Color(0xFFE8C768),
                  size: 17,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '$creditLabel • $termsLabel • $paymentCount recorded payment${paymentCount == 1 ? '' : 's'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.83),
                      fontSize: 9.4,
                      fontWeight: FontWeight.w800,
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
}

class _PremiumStatementAgingMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool danger;

  const _PremiumStatementAgingMetric({
    required this.label,
    required this.value,
    required this.danger,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: danger
            ? const Color(0xFFFFF2F0)
            : FarmColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: danger
              ? FarmColors.danger.withOpacity(.18)
              : FarmColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: danger
                  ? FarmColors.danger
                  : FarmColors.deepGreen,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumStatementInvoiceCard extends StatelessWidget {
  final WholesaleInvoice invoice;
  final int overdueDays;

  const _PremiumStatementInvoiceCard({
    required this.invoice,
    required this.overdueDays,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        overdueDays > 0 ? FarmColors.danger : FarmColors.green;

    String dateLabel(DateTime? value) {
      if (value == null) return '—';

      const months = <String>[
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];

      final date = value.toLocal();
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }

    return FarmCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 39,
            height: 39,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              overdueDays > 0
                  ? Icons.warning_amber_rounded
                  : Icons.receipt_long_outlined,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        invoice.invoiceNumber,
                        style: const TextStyle(
                          color: FarmColors.ink,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      formatJmd(invoice.amountDue),
                      style: TextStyle(
                        color: color,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Issued ${dateLabel(invoice.issueDate ?? invoice.issuedAt)} '
                  '• Due ${dateLabel(invoice.dueDate)}',
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (overdueDays > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$overdueDays day${overdueDays == 1 ? '' : 's'} overdue',
                    style: const TextStyle(
                      color: FarmColors.danger,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// PHASE 3R — ADMIN SCHEDULING & CAPACITY WORKSPACE
// =====================================================

// ============================================================================
// SOURCE SECTION: business_entry.dart
// ============================================================================
// HPJ PHASE 88 — BUSINESS-NAMED PUBLIC ENTRY

/// New business-first route name. Existing BusinessWholesaleHubScreen remains
/// available so older navigation and notification routes do not break.
class BusinessHubScreen extends StatelessWidget {
  final int initialTab;
  final String? initialRecordId;

  const BusinessHubScreen({
    super.key,
    this.initialTab = 0,
    this.initialRecordId,
  });

  @override
  Widget build(BuildContext context) {
    return BusinessWholesaleHubScreen(
      initialTab: initialTab,
      initialRecordId: initialRecordId,
    );
  }
}


// ============================================================================
// HPJ PHASES 105–107 — JAMAICA DEMAND NETWORK
// Phase 105: Demand Radar
// Phase 106: Business Procurement Posts
// Phase 107: Smart Farmer Matching
// ============================================================================

class HpjDemandRadarSignal {
  final String cropName;
  final String category;
  final String unit;
  final double totalDemand;
  final double reportedSupply;
  final double gapQuantity;
  final double coveragePercent;
  final int businessCount;
  final int farmerCount;
  final DateTime? earliestNeedBy;

  const HpjDemandRadarSignal({
    required this.cropName,
    required this.category,
    required this.unit,
    required this.totalDemand,
    required this.reportedSupply,
    required this.gapQuantity,
    required this.coveragePercent,
    required this.businessCount,
    required this.farmerCount,
    required this.earliestNeedBy,
  });

  factory HpjDemandRadarSignal.fromSupabase(Map<String, dynamic> row) {
    double number(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    int whole(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return HpjDemandRadarSignal(
      cropName: (row['crop_name'] ?? 'Produce').toString().trim(),
      category: (row['category'] ?? '').toString().trim(),
      unit: (row['unit'] ?? 'lb').toString().trim(),
      totalDemand: number(row['total_demand']),
      reportedSupply: number(row['reported_supply']),
      gapQuantity: number(row['gap_quantity']),
      coveragePercent: number(row['coverage_percent']),
      businessCount: whole(row['business_count']),
      farmerCount: whole(row['farmer_count']),
      earliestNeedBy: parseProductDate(row['earliest_need_by']),
    );
  }

  String get signalLabel {
    if (gapQuantity <= 0.0001) return 'Covered';
    if (coveragePercent < 50) return 'High opportunity';
    return 'Supply opportunity';
  }
}

class HpjBusinessDemandPost {
  final String id;
  final String forecastId;
  final String cropName;
  final String category;
  final double quantity;
  final String unit;
  final DateTime needByDate;
  final String frequency;
  final String status;
  final String publicNote;
  final bool allowAlternatives;
  final int responseCount;
  final DateTime? createdAt;

  const HpjBusinessDemandPost({
    required this.id,
    required this.forecastId,
    required this.cropName,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.needByDate,
    required this.frequency,
    required this.status,
    required this.publicNote,
    required this.allowAlternatives,
    required this.responseCount,
    this.createdAt,
  });

  factory HpjBusinessDemandPost.fromSupabase(Map<String, dynamic> row) {
    double number(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    int whole(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return HpjBusinessDemandPost(
      id: (row['id'] ?? '').toString().trim(),
      forecastId: (row['forecast_id'] ?? '').toString().trim(),
      cropName: (row['crop_name'] ?? 'Produce').toString().trim(),
      category: (row['category'] ?? '').toString().trim(),
      quantity: number(row['quantity']),
      unit: (row['unit'] ?? 'lb').toString().trim(),
      needByDate: parseProductDate(row['need_by_date']) ?? DateTime.now(),
      frequency: (row['frequency'] ?? 'one_time').toString().trim(),
      status: (row['status'] ?? 'open').toString().trim().toLowerCase(),
      publicNote: (row['public_note'] ?? '').toString().trim(),
      allowAlternatives: row['allow_alternatives'] != false,
      responseCount: whole(row['response_count']),
      createdAt: parseProductDate(row['created_at']),
    );
  }

  bool get isOpen => status == 'open' || status == 'responding';

  String get statusLabel {
    switch (status) {
      case 'responding':
        return 'Farmers responding';
      case 'closed':
        return 'Closed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Open';
    }
  }

  String get formattedQuantity {
    final value =
        quantity == quantity.roundToDouble()
            ? quantity.toInt().toString()
            : quantity.toStringAsFixed(1);
    return '$value $unit';
  }
}

Future<List<HpjDemandRadarSignal>> fetchHpjDemandRadar({
  int limit = 30,
}) async {
  try {
    final response = await supabase.rpc(
      'hpj_demand_radar',
      params: <String, dynamic>{
        'p_limit': limit.clamp(1, 100),
      },
    );

    return (response as List)
        .map(
          (item) => HpjDemandRadarSignal.fromSupabase(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  } catch (error) {
    farmDebugLog('HPJ Demand Radar unavailable: $error');
    return const <HpjDemandRadarSignal>[];
  }
}

Future<List<HpjBusinessDemandPost>> fetchMyHpjBusinessDemandPosts() async {
  final user = supabase.auth.currentUser;
  if (user == null) return const <HpjBusinessDemandPost>[];

  try {
    final response = await supabase.rpc('hpj_my_business_demand_posts');

    return (response as List)
        .map(
          (item) => HpjBusinessDemandPost.fromSupabase(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  } catch (error) {
    farmDebugLog('Business demand posts unavailable: $error');
    return const <HpjBusinessDemandPost>[];
  }
}

Future<void> publishHpjBusinessDemandPost({
  required BusinessAccount account,
  required WholesaleDemandForecast forecast,
  String publicNote = '',
  bool allowAlternatives = true,
}) async {
  if (!account.isApproved) {
    throw Exception('Your Business account must be approved.');
  }

  await supabase.from('hpj_business_demand_posts').insert(
    <String, dynamic>{
      'business_account_id': account.id,
      'forecast_id': forecast.id,
      'public_note': publicNote.trim(),
      'allow_alternatives': allowAlternatives,
    },
  );
}

Future<void> closeHpjBusinessDemandPost(String postId) async {
  final cleanId = postId.trim();
  if (cleanId.isEmpty) return;

  await supabase
      .from('hpj_business_demand_posts')
      .update(<String, dynamic>{'status': 'closed'})
      .eq('id', cleanId);
}

class _HpjBusinessDemandNetworkEntryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _HpjBusinessDemandNetworkEntryCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            color: const Color(0xFF073F2C),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE8C66A).withOpacity(.55),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.09),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  color: Color(0xFFFFD15A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jamaica Demand Network',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Post a buyer need, see national supply gaps and let HPJ match farmers without exposing private contacts.',
                      style: TextStyle(
                        color: Color(0xFFCFE0D6),
                        fontSize: 9.0,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HpjBusinessDemandNetworkScreen extends StatefulWidget {
  final BusinessAccount account;

  const HpjBusinessDemandNetworkScreen({
    super.key,
    required this.account,
  });

  @override
  State<HpjBusinessDemandNetworkScreen> createState() =>
      _HpjBusinessDemandNetworkScreenState();
}

class _HpjBusinessDemandNetworkScreenState
    extends State<HpjBusinessDemandNetworkScreen> {
  late Future<List<HpjDemandRadarSignal>> _radarFuture;
  late Future<List<HpjBusinessDemandPost>> _postsFuture;
  late Future<List<WholesaleProduct>> _catalogueFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _radarFuture = fetchHpjDemandRadar();
    _postsFuture = fetchMyHpjBusinessDemandPosts();
    _catalogueFuture = fetchWholesaleCatalogue();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await Future.wait<dynamic>([
      _radarFuture,
      _postsFuture,
      _catalogueFuture,
    ]);
  }

  Future<void> _createPost() async {
    final products = await _catalogueFuture;
    if (!mounted) return;

    final created = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HpjBusinessDemandPostSheet(
        account: widget.account,
        catalogue: products,
      ),
    );

    if (created == true && mounted) {
      await _refresh();
    }
  }

  Future<void> _closePost(HpjBusinessDemandPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Close buyer need?'),
        content: Text(
          '${post.cropName} will stop appearing as an open demand signal. '
          'The original Planning Ahead requirement remains in HPJ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep open'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await closeHpjBusinessDemandPost(post.id);
      if (!mounted) return;
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  String _number(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  Widget _radarCard(HpjDemandRadarSignal signal) {
    final gap = signal.gapQuantity;
    final covered = gap <= 0.0001;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: FarmColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: covered
                  ? FarmColors.successSoft
                  : FarmColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              covered ? Icons.check_rounded : Icons.radar_rounded,
              color: covered ? FarmColors.success : FarmColors.primary,
              size: 21,
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
                        signal.cropName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FarmColors.ink,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      signal.signalLabel,
                      style: TextStyle(
                        color: covered
                            ? FarmColors.success
                            : FarmColors.warning,
                        fontSize: 8.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_number(signal.totalDemand)} ${signal.unit} demand • '
                  '${_number(signal.reportedSupply)} ${signal.unit} reported supply',
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 9.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  covered
                      ? '${signal.coveragePercent.toStringAsFixed(0)}% covered across ${signal.businessCount} business need${signal.businessCount == 1 ? '' : 's'}'
                      : '${_number(signal.gapQuantity)} ${signal.unit} opportunity • '
                          '${signal.businessCount} business need${signal.businessCount == 1 ? '' : 's'} • '
                          '${signal.farmerCount} farmer${signal.farmerCount == 1 ? '' : 's'} reporting',
                  style: const TextStyle(
                    color: FarmColors.deepGreen,
                    fontSize: 8.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _postCard(HpjBusinessDemandPost post) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  post.cropName,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: post.isOpen
                      ? FarmColors.primarySoft
                      : FarmColors.cardSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  post.statusLabel,
                  style: TextStyle(
                    color: post.isOpen
                        ? FarmColors.deepGreen
                        : FarmColors.mutedText,
                    fontSize: 7.6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${post.formattedQuantity} • need by ${_wholesaleSimpleDate(post.needByDate)} • '
            '${post.responseCount} farmer response${post.responseCount == 1 ? '' : 's'}',
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 9.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (post.publicNote.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              post.publicNote,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.ink,
                fontSize: 8.8,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (post.isOpen) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _closePost(post),
                icon: const Icon(Icons.close_rounded, size: 15),
                label: const Text('Close need'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: const Text('Jamaica Demand Network'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPost,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post Buyer Need'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF073F2C),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.hub_outlined,
                    color: Color(0xFFFFD15A),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tell HPJ what your business needs. Farmers see aggregated opportunities, while HPJ keeps buyer and farmer private contact details protected.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.2,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionHeader(
              title: 'Demand Radar',
              subtitle:
                  'Jamaica-wide demand compared with farmer-reported supply.',
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<HpjDemandRadarSignal>>(
              future: _radarFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    snapshot.data == null) {
                  return const SkeletonList(count: 3);
                }

                final rows = snapshot.data ?? const <HpjDemandRadarSignal>[];
                if (rows.isEmpty) {
                  return const FarmEmptyState(
                    icon: Icons.radar_rounded,
                    title: 'No open demand signals yet',
                    message:
                        'Post the first Buyer Need or keep using Planning Ahead.',
                  );
                }

                return Column(
                  children: [
                    for (var i = 0; i < rows.length && i < 12; i++) ...[
                      _radarCard(rows[i]),
                      if (i != rows.length - 1 && i != 11)
                        const SizedBox(height: 8),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(
                  child: SectionHeader(
                    title: 'Your Buyer Needs',
                    subtitle:
                        'Published needs remain connected to HPJ Planning Ahead.',
                  ),
                ),
                FilledButton.icon(
                  onPressed: _createPost,
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: const Text('Post Need'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<HpjBusinessDemandPost>>(
              future: _postsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    snapshot.data == null) {
                  return const SkeletonList(count: 2);
                }

                final posts =
                    snapshot.data ?? const <HpjBusinessDemandPost>[];
                if (posts.isEmpty) {
                  return const FarmEmptyState(
                    icon: Icons.campaign_outlined,
                    title: 'No buyer needs posted',
                    message:
                        'Publish a requirement and HPJ will surface the aggregated opportunity to farmers.',
                  );
                }

                return Column(
                  children: [
                    for (var i = 0; i < posts.length; i++) ...[
                      _postCard(posts[i]),
                      if (i != posts.length - 1)
                        const SizedBox(height: 8),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HpjBusinessDemandPostSheet extends StatefulWidget {
  final BusinessAccount account;
  final List<WholesaleProduct> catalogue;

  const _HpjBusinessDemandPostSheet({
    required this.account,
    required this.catalogue,
  });

  @override
  State<_HpjBusinessDemandPostSheet> createState() =>
      _HpjBusinessDemandPostSheetState();
}

class _HpjBusinessDemandPostSheetState
    extends State<_HpjBusinessDemandPostSheet> {
  final quantityController = TextEditingController();
  final noteController = TextEditingController();

  String selectedProductId = '';
  String frequency = 'one_time';
  DateTime needBy = DateTime.now().add(const Duration(days: 14));
  bool allowAlternatives = true;
  bool saving = false;

  @override
  void dispose() {
    quantityController.dispose();
    noteController.dispose();
    super.dispose();
  }

  WholesaleProduct? get selectedProduct {
    for (final item in widget.catalogue) {
      if (item.product.id.trim() == selectedProductId) return item;
    }
    return null;
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final chosen = await showDatePicker(
      context: context,
      initialDate: needBy,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: today.add(const Duration(days: 365)),
    );
    if (chosen == null || !mounted) return;
    setState(() => needBy = chosen);
  }

  Future<void> _submit() async {
    final item = selectedProduct;
    final quantity = double.tryParse(
      quantityController.text.trim().replaceAll(',', ''),
    );

    if (item == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose the produce your business needs.')),
      );
      return;
    }

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity.')),
      );
      return;
    }

    setState(() => saving = true);

    try {
      final forecast = await createWholesaleDemandForecast(
        productId: item.product.id,
        productName: item.product.name,
        category: item.product.category,
        quantity: quantity,
        unit: item.wholesaleUnit,
        needByDate: needBy,
        frequency: frequency,
        certainty: 'expected',
        notes: noteController.text.trim(),
      );

      await publishHpjBusinessDemandPost(
        account: widget.account,
        forecast: forecast,
        publicNote: noteController.text.trim(),
        allowAlternatives: allowAlternatives,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.catalogue
        .where((item) => item.wholesaleEnabled)
        .toList(growable: false);

    return Container(
      decoration: const BoxDecoration(
        color: FarmColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Post a Buyer Need',
              style: TextStyle(
                color: FarmColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'This also creates a normal HPJ Planning Ahead requirement so procurement stays in one system.',
              style: TextStyle(
                color: FarmColors.mutedText,
                fontSize: 10.2,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedProductId.isEmpty ? null : selectedProductId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Produce',
                prefixIcon: Icon(Icons.eco_outlined),
              ),
              items: products
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item.product.id,
                      child: Text(
                        '${item.product.name} • ${item.wholesaleUnit}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: saving
                  ? null
                  : (value) {
                      setState(() {
                        selectedProductId = value?.trim() ?? '';
                        final item = selectedProduct;
                        if (item != null &&
                            quantityController.text.trim().isEmpty) {
                          quantityController.text =
                              item.minimumQuantity.toString();
                        }
                      });
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              enabled: !saving,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: selectedProduct == null
                    ? 'Quantity'
                    : 'Quantity (${selectedProduct!.wholesaleUnit})',
                prefixIcon: const Icon(Icons.scale_outlined),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: frequency,
              decoration: const InputDecoration(
                labelText: 'How often?',
                prefixIcon: Icon(Icons.repeat_rounded),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'one_time',
                  child: Text('One time'),
                ),
                DropdownMenuItem(
                  value: 'weekly',
                  child: Text('Weekly'),
                ),
                DropdownMenuItem(
                  value: 'biweekly',
                  child: Text('Every 2 weeks'),
                ),
                DropdownMenuItem(
                  value: 'monthly',
                  child: Text('Monthly'),
                ),
              ],
              onChanged: saving
                  ? null
                  : (value) => setState(
                        () => frequency = value ?? 'one_time',
                      ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.calendar_month_outlined,
                color: FarmColors.primary,
              ),
              title: const Text(
                'Need by',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(_wholesaleSimpleDate(needBy)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: saving ? null : _pickDate,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              enabled: !saving,
              maxLength: 280,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Public requirement note (optional)',
                hintText:
                    'Example: Grade A preferred, consistent weekly supply needed.',
                alignLabelWithHint: true,
              ),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: allowAlternatives,
              onChanged: saving
                  ? null
                  : (value) => setState(
                        () => allowAlternatives = value,
                      ),
              title: const Text(
                'Allow HPJ to match other verified farms',
                style: TextStyle(
                  color: FarmColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: const Text(
                'Farmer identity and private contact details remain protected.',
                style: TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: saving ? null : _submit,
                icon: saving
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.campaign_outlined),
                label: Text(
                  saving ? 'Publishing…' : 'Publish Buyer Need',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
