part of harvest_place_app;

List<HomeHeroSlide> defaultHomeHeroSlides() {
  return List<HomeHeroSlide>.generate(_defaultHomeHeroImageUrls.length,
      (index) {
    return HomeHeroSlide(
      id: 'default-${index + 1}',
      position: index + 1,
      imageUrl: _defaultHomeHeroImageUrls[index],
      isActive: true,
    );
  });
}

List<HomeHeroSlide> _cleanHomeHeroSlides(List<HomeHeroSlide> slides) {
  final clean = slides
      .where((slide) => cleanHostedImageUrl(slide.imageUrl) != null)
      .toList()
    ..sort((a, b) => a.position.compareTo(b.position));

  if (clean.isEmpty) return defaultHomeHeroSlides();
  return clean.take(3).toList();
}

final Set<String> _shownBrowserNotificationTags = <String>{};

Future<List<FarmOrder>> _fetchOrdersUncached() async {
  if (!isLoggedIn) return [];

  final user = supabase.auth.currentUser;
  if (user == null) return [];

  const fields =
      'id, order_status, fulfillment_type, subtotal, delivery_fee, discount_amount, total, payment_status, payment_method, notes, created_at';

  try {
    final response = await supabase
        .from('orders')
        .select(fields)
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(20);

    return (response as List)
        .map((item) => FarmOrder.fromSupabase(Map<String, dynamic>.from(item)))
        .toList();
  } catch (userIdError) {
    farmDebugLog(
        'Order lookup by user_id unavailable, using customer_id fallback: $userIdError');
  }

  try {
    final profile = await fetchCurrentCustomerProfile();
    if (profile?.id == null || profile!.id!.isEmpty) return [];

    final response = await supabase
        .from('orders')
        .select(fields)
        .eq('customer_id', profile.id!)
        .order('created_at', ascending: false)
        .limit(20);

    return (response as List)
        .map((item) => FarmOrder.fromSupabase(Map<String, dynamic>.from(item)))
        .toList();
  } catch (error) {
    farmDebugLog('Failed to fetch only this customer orders: $error');
    return [];
  }
}

Future<String?> findOrderIdForNotification(
    FarmNotification notification) async {
  final directId = notification.orderId?.trim();
  if (directId != null && directId.isNotEmpty) return directId;

  final shortId = notificationOrderShortId(notification);
  if (shortId == null || shortId.isEmpty) return null;

  final orders = await fetchOrders();
  for (final order in orders) {
    final fullId = order.id.trim().toUpperCase();
    final displayId = order.shortId.trim().toUpperCase();

    if (displayId == shortId ||
        fullId == shortId ||
        fullId.startsWith(shortId)) {
      return order.id;
    }
  }

  // Admin notifications can point to orders that are not in the current
  // customer's My Orders list. Older notification rows may also only contain
  // the short #ABC123 label in the message. If this signed-in user is an admin,
  // resolve that short label directly against the orders table.
  try {
    if (await isCurrentUserAdminFromDatabase()) {
      final response = await supabase
          .from('orders')
          .select('id')
          .ilike('id', '${shortId.toLowerCase()}%')
          .order('created_at', ascending: false)
          .limit(1);

      final rows = response as List;
      if (rows.isNotEmpty) {
        return (rows.first['id'] ?? '').toString();
      }
    }
  } catch (error) {
    debugPrintOnce(
      'admin_notification_order_lookup_skipped',
      'Admin notification order lookup skipped safely.',
    );
  }

  return null;
}

Future<List<FarmNotification>> _fetchFarmNotificationsUncached() async {
  final user = supabase.auth.currentUser;
  if (user == null) return const [];

  List<FarmNotification> cleanRows(List<Map<String, dynamic>> rows) {
    final seen = <String>{};
    final output = <FarmNotification>[];

    for (final row in rows) {
      final notice = FarmNotification.fromSupabase(row);
      final key = [
        notice.title.trim().toLowerCase(),
        notice.message.trim().toLowerCase(),
        notice.type.trim().toLowerCase(),
        notice.orderId?.trim().toLowerCase() ?? '',
      ].join('|');

      if (seen.add(key)) output.add(notice);
    }

    return output;
  }

  try {
    final response = await supabase
        .from('notifications')
        .select(
            'id, user_id, user_email, title, message, type, is_read, created_at, order_id')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);

    final rows = (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    final notices = cleanRows(rows);
    if (notices.isNotEmpty) return notices;
  } catch (userIdError) {
    debugPrintOnce(
      'notification_lookup_user_id_unavailable',
      'Notification lookup by user_id unavailable. Continuing without notification list.',
    );
  }

  try {
    final userEmail = (user.email ?? '').trim().toLowerCase();
    if (userEmail.isEmpty) return const [];

    final response = await supabase
        .from('notifications')
        .select(
            'id, user_email, title, message, type, is_read, created_at, order_id')
        .eq('user_email', userEmail)
        .order('created_at', ascending: false)
        .limit(50);

    final rows = (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    return cleanRows(rows);
  } catch (emailError) {
    debugPrintOnce(
      'notification_lookup_email_unavailable',
      'Notification lookup by email unavailable. Continuing without notification list.',
    );
  }

  // Do not create repeated order/admin-style notifications from dashboard data.
  // Only show records that actually exist in the notifications table.
  return const [];
}

bool canAddToWeeklyBox(Product product) {
  return product.canAddToCart;
}

String _cleanReviewNameCandidate(String? value) {
  final clean = (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
  if (clean.isEmpty) return '';

  final lower = clean.toLowerCase();
  if (lower == 'null' ||
      lower == 'undefined' ||
      lower == 'unknown' ||
      lower == 'test' ||
      lower == 'demo') {
    return '';
  }

  if (_looksLikeEmailAddress(clean)) return '';
  if (clean.length > 60) return clean.substring(0, 60).trim();
  return clean;
}

Future<String> currentReviewCustomerName() async {
  final user = supabase.auth.currentUser;
  String? profileName;

  try {
    final profile = await fetchCurrentCustomerProfile();
    profileName = profile?.fullName;
  } catch (_) {
    profileName = null;
  }

  final metadata = user?.userMetadata ?? const <String, dynamic>{};
  final metadataName = (metadata['full_name'] ??
          metadata['name'] ??
          metadata['display_name'])
      ?.toString();

  return safeReviewDisplayName(
    profileName: profileName,
    metadataName: metadataName,
    email: user?.email,
  );
}

class AccountScreen extends StatelessWidget {
  final List<Product> favoriteProducts;
  final List<Product> recentlyViewedProducts;
  final VoidCallback onShopTap;
  final bool showAdmin;
  final VoidCallback? onSignedOut;

  const AccountScreen({
    super.key,
    this.favoriteProducts = const [],
    this.recentlyViewedProducts = const [],
    required this.onShopTap,
    this.showAdmin = false,
    this.onSignedOut,
  });

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    if (!isLoggedIn || user == null) {
      return const GuestProtectedScreen(
        title: 'Account',
        subtitle: 'Profile, rewards & tools',
        message:
            'Sign in or create an account to view your profile, rewards, saved details, and private account tools.',
      );
    }

    final name = user.userMetadata?['full_name']?.toString() ?? 'Farm Customer';
    final role = currentUserRole;
    final roleLabel = showAdmin
        ? 'Admin'
        : role == 'farmer'
            ? 'Farmer'
            : 'Customer';

    return FarmPage(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
        children: [
          const Header(
            title: 'Account',
            subtitle: 'Your farm shopping hub',
          ),
          const SizedBox(height: 18),
          EliteAccountHeroCard(
            name: name,
            email: user.email ?? '',
            roleLabel: roleLabel,
            favoriteCount: favoriteProducts.length,
            recentCount: recentlyViewedProducts.length,
            showAdmin: showAdmin,
          ),
          const SizedBox(height: 18),
          const LoyaltySummaryCard(),
          const SizedBox(height: 18),
          FarmCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AccountSectionHeading(
                  title: 'Quick actions',
                  subtitle: 'Everything you use most often.',
                ),
                const SizedBox(height: 14),
                AccountActionGrid(
                  actions: [
                    AccountActionItem(
                      icon: Icons.receipt_long_outlined,
                      title: 'Orders',
                      subtitle: 'Track purchases',
                      onTap: () => _open(context, const OrdersScreen()),
                    ),
                    AccountActionItem(
                      icon: Icons.inventory_2_outlined,
                      title: 'Weekly Box',
                      subtitle: 'Manage repeats',
                      onTap: () => _open(
                        context,
                        const CustomerSubscriptionsScreen(),
                      ),
                    ),
                    AccountActionItem(
                      icon: Icons.favorite_outline,
                      title: 'Favorites',
                      subtitle: '${favoriteProducts.length} saved',
                      onTap: () => _open(
                        context,
                        FavoritesScreen(
                          products: favoriteProducts,
                          onShopTap: onShopTap,
                        ),
                      ),
                    ),
                    AccountActionItem(
                      icon: Icons.history,
                      title: 'Recent',
                      subtitle: '${recentlyViewedProducts.length} viewed',
                      onTap: () => _open(
                        context,
                        RecentlyViewedScreen(
                          products: recentlyViewedProducts,
                          onShopTap: onShopTap,
                        ),
                      ),
                    ),
                    AccountActionItem(
                      icon: Icons.notifications_none_outlined,
                      title: 'Alerts',
                      subtitle: 'Order updates',
                      onTap: () => _open(
                        context,
                        const NotificationsScreen(),
                      ),
                    ),
                    AccountActionItem(
                      icon: Icons.card_giftcard,
                      title: 'Rewards',
                      subtitle: 'Points & perks',
                      onTap: () => _open(
                        context,
                        const LoyaltyRewardsScreen(),
                      ),
                    ),
                    AccountActionItem(
                      icon: Icons.ios_share_outlined,
                      title: 'Invite',
                      subtitle: 'Share market',
                      onTap: () => _open(
                        context,
                        const InviteFarmMarketScreen(),
                      ),
                    ),
                    AccountActionItem(
                      icon: Icons.add_to_home_screen,
                      title: 'Install',
                      subtitle: 'Home screen',
                      onTap: () => _open(
                        context,
                        const InstallAppGuideScreen(),
                      ),
                    ),
                    AccountActionItem(
                      icon: Icons.person_outline,
                      title: 'Profile',
                      subtitle: 'Saved details',
                      onTap: () => _open(
                        context,
                        const CustomerProfileScreen(),
                      ),
                    ),
                    AccountActionItem(
                      icon: Icons.support_agent_outlined,
                      title: 'Support',
                      subtitle: 'Get help fast',
                      onTap: () => _open(context, const SupportScreen()),
                    ),
                    if (showAdmin)
                      AccountActionItem(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Admin',
                        subtitle: 'Dashboard',
                        accentColor: FarmColors.warning,
                        onTap: () => _open(
                          context,
                          const AdminDashboardScreen(),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FarmCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 18, 18, 8),
                  child: AccountSectionHeading(
                    title: 'Trust & support',
                    subtitle: 'Help, feedback, and customer policies.',
                  ),
                ),
                AccountListTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Trust Center',
                  subtitle: 'How orders, freshness, privacy, and support work.',
                  onTap: () => _open(context, const TrustCenterScreen()),
                ),
                AccountListTile(
                  icon: Icons.rate_review_outlined,
                  title: 'Reviews & Feedback',
                  subtitle: 'Share your experience.',
                  onTap: () => _open(context, const ReviewScreen()),
                ),
                AccountListTile(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  subtitle: 'How the marketplace works.',
                  onTap: () => _open(context, const TermsOfServiceScreen()),
                ),
                AccountListTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'How your account and order data are protected.',
                  onTap: () => _open(context, const PrivacyPolicyScreen()),
                ),
                AccountListTile(
                  icon: Icons.replay_circle_filled_outlined,
                  title: 'Refund Policy',
                  subtitle: 'Freshness, cancellations, and support rules.',
                  isLast: true,
                  onTap: () => _open(context, const RefundPolicyScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout_outlined),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: FarmColors.danger,
              side: BorderSide(color: FarmColors.danger.withOpacity(0.32)),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: () async {
              await clearPrivateSessionStateForGuestBrowsing();
              onSignedOut?.call();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Signed out. You can keep browsing as a guest.'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class InviteFarmMarketScreen extends StatelessWidget {
  const InviteFarmMarketScreen({super.key});

  String get _marketLink => AppConfig.shareableAppLink.trim();

  String get _inviteText {
    return 'I found a fresh local farm market app you may like: ${AppConfig.appName}. Browse fresh produce, build your weekly box, and track farm orders here: $_marketLink';
  }

  String get _whatsAppShareUrl {
    return 'https://wa.me/?text=${Uri.encodeComponent(_inviteText)}';
  }

  Future<void> _copyInvite(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _inviteText));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite message copied.')),
      );
    }
  }

  Future<void> _shareOnWhatsApp(BuildContext context) async {
    final opened = await openExternalShareUrl(_whatsAppShareUrl);

    if (!context.mounted) return;

    if (opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening WhatsApp share...')),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: _inviteText));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite copied. Open WhatsApp and paste it into a chat.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Invite Friends'),
      ),
      body: FarmPage(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
          children: [
            const Header(
              title: 'Share the harvest',
              subtitle: 'Send a clean invite link by WhatsApp or copy it.',
            ),
            const SizedBox(height: 18),
            const EliteGreenHeroCard(
              eyebrow: 'Share the harvest',
              title: 'Fresh food, shared simply.',
              subtitle:
                  'Send one clean market link through WhatsApp, or copy the invite for any group chat.',
              icon: Icons.spa_outlined,
              chips: ['WhatsApp ready', 'Clean invite link'],
            ),
            const SizedBox(height: 18),
            FarmCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Invite link',
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: FarmColors.cardSoft,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: FarmColors.line),
                    ),
                    child: Text(
                      _marketLink,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.green,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Send on WhatsApp'),
                      onPressed: () => _shareOnWhatsApp(context),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Copy Invite Message'),
                      onPressed: () => _copyInvite(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FarmCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Invite message',
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: FarmColors.primarySoft.withOpacity(0.56),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: FarmColors.line),
                    ),
                    child: Text(
                      _inviteText,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FarmCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AccountSectionHeading(
                    title: 'Why people will join',
                    subtitle: 'A simple reason to share the app confidently.',
                  ),
                  SizedBox(height: 14),
                  _InviteBenefitRow(
                    icon: Icons.shopping_basket_outlined,
                    title: 'Fresh local shopping',
                    subtitle: 'Browse available harvests and build a farm box.',
                  ),
                  _InviteBenefitRow(
                    icon: Icons.local_shipping_outlined,
                    title: 'Pickup or delivery',
                    subtitle:
                        'Customers choose the fulfillment option that works for them.',
                  ),
                  _InviteBenefitRow(
                    icon: Icons.notifications_active_outlined,
                    title: 'Order updates',
                    subtitle:
                        'Friendly updates help customers track each order.',
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InstallAppGuideScreen extends StatelessWidget {
  const InstallAppGuideScreen({super.key});

  String get _marketLink => AppConfig.shareableAppLink.trim();

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _marketLink));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App link copied.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Install App'),
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
          children: [
            const EliteGreenHeroCard(
              eyebrow: 'Save the market',
              title: 'Keep the farm close.',
              subtitle:
                  'Add the market to your phone for quicker shopping, order tracking, weekly boxes, and support.',
              icon: Icons.mobile_friendly_outlined,
              chips: ['Quick access', 'Order tracking'],
            ),
            const SizedBox(height: 18),
            FarmCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AccountSectionHeading(
                    title: 'Install steps',
                    subtitle:
                        'Choose the steps for your device.',
                  ),
                  SizedBox(height: 14),
                  _InstallStepRow(
                    icon: Icons.android_outlined,
                    title: 'Android phone',
                    subtitle:
                        'Open the app link, tap the menu, then choose Add to Home screen or Install app.',
                  ),
                  _InstallStepRow(
                    icon: Icons.phone_iphone_outlined,
                    title: 'iPhone / Safari',
                    subtitle:
                        'Open the app link in Safari, tap Share, then tap Add to Home Screen.',
                  ),
                  _InstallStepRow(
                    icon: Icons.desktop_windows_outlined,
                    title: 'Computer browser',
                    subtitle:
                        'Open the app link and use the install or save option when available.',
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FarmCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'App link',
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: FarmColors.cardSoft,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: FarmColors.line),
                    ),
                    child: Text(
                      _marketLink,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.green,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Copy App Link'),
                      onPressed: () => _copyLink(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Copy your market link and share it with customers whenever you are ready.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FarmColors.mutedText.withOpacity(0.86),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstallStepRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLast;

  const _InstallStepRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: FarmColors.primarySoft,
              shape: BoxShape.circle,
              border: Border.all(color: FarmColors.primary.withOpacity(0.12)),
            ),
            child: Icon(icon, color: FarmColors.primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
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

class _InviteBenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLast;

  const _InviteBenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: FarmColors.primarySoft,
              shape: BoxShape.circle,
              border: Border.all(color: FarmColors.primary.withOpacity(0.12)),
            ),
            child: Icon(icon, color: FarmColors.primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
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

class EliteAccountHeroCard extends StatelessWidget {
  final String name;
  final String email;
  final String roleLabel;
  final int favoriteCount;
  final int recentCount;
  final bool showAdmin;

  const EliteAccountHeroCard({
    super.key,
    required this.name,
    required this.email,
    required this.roleLabel,
    required this.favoriteCount,
    required this.recentCount,
    required this.showAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'F' : name.trim()[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FarmColors.primaryDark,
            FarmColors.primary,
            FarmColors.olive.withOpacity(0.94),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: FarmColors.primaryDark.withOpacity(0.24),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.34)),
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              AccountHeroPill(
                icon: showAdmin
                    ? Icons.admin_panel_settings_outlined
                    : Icons.verified_user_outlined,
                label: roleLabel,
              ),
              AccountHeroPill(
                icon: Icons.favorite_outline,
                label: '$favoriteCount favorites',
              ),
              AccountHeroPill(
                icon: Icons.history,
                label: '$recentCount recent',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AccountHeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const AccountHeroPill({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class AccountSectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const AccountSectionHeading({
    super.key,
    required this.title,
    required this.subtitle,
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
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: FarmColors.mutedText,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class AccountActionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accentColor;

  const AccountActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accentColor = FarmColors.primary,
  });
}

class AccountActionGrid extends StatelessWidget {
  final List<AccountActionItem> actions;

  const AccountActionGrid({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final columns = availableWidth >= 560 ? 3 : 2;
        final spacing = 10.0;
        final tileWidth = (availableWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: actions
              .map(
                (action) => SizedBox(
                  width: tileWidth,
                  child: AccountActionTile(action: action),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class AccountActionTile extends StatelessWidget {
  final AccountActionItem action;

  const AccountActionTile({
    super.key,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: action.onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: FarmColors.cardSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FarmColors.line.withOpacity(0.92)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: action.accentColor.withOpacity(0.11),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      action.icon,
                      color: action.accentColor,
                      size: 19,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: FarmColors.mutedText.withOpacity(0.44),
                    size: 13,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                action.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FarmColors.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                action.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  const AccountListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: FarmColors.line.withOpacity(0.62),
                    ),
                  ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: FarmColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: FarmColors.primary, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.2,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: FarmColors.mutedText.withOpacity(0.45),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PersonalizedHomeHeroLoader extends StatelessWidget {
  final Future<CustomerProfile?> profileFuture;
  final Future<LoyaltySummary> loyaltyFuture;
  final List<Product> allProducts;
  final List<Product> buyAgainProducts;
  final List<Product> favoriteProducts;
  final List<Product> recentlyViewedProducts;
  final VoidCallback onShopTap;

  const PersonalizedHomeHeroLoader({
    super.key,
    required this.profileFuture,
    required this.loyaltyFuture,
    required this.allProducts,
    required this.buyAgainProducts,
    required this.favoriteProducts,
    required this.recentlyViewedProducts,
    required this.onShopTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CustomerProfile?>(
      future: profileFuture,
      builder: (context, profileSnapshot) {
        return FutureBuilder<LoyaltySummary>(
          future: loyaltyFuture,
          builder: (context, loyaltySnapshot) {
            final profile = profileSnapshot.data;
            final loyalty = loyaltySnapshot.data ??
                const LoyaltySummary(
                  points: 0,
                  lifetimePoints: 0,
                  tier: 'Green',
                );

            return PersonalizedHomeHeroCard(
              profile: profile,
              loyalty: loyalty,
              allProducts: allProducts,
              buyAgainProducts: buyAgainProducts,
              favoriteProducts: favoriteProducts,
              recentlyViewedProducts: recentlyViewedProducts,
              onShopTap: onShopTap,
            );
          },
        );
      },
    );
  }
}

class PersonalizedHomeHeroCard extends StatelessWidget {
  final CustomerProfile? profile;
  final LoyaltySummary loyalty;
  final List<Product> allProducts;
  final List<Product> buyAgainProducts;
  final List<Product> favoriteProducts;
  final List<Product> recentlyViewedProducts;
  final VoidCallback onShopTap;

  const PersonalizedHomeHeroCard({
    super.key,
    required this.profile,
    required this.loyalty,
    required this.allProducts,
    required this.buyAgainProducts,
    required this.favoriteProducts,
    required this.recentlyViewedProducts,
    required this.onShopTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = mostCommonText([
          ...buyAgainProducts.map((product) => product.category),
          ...favoriteProducts.map((product) => product.category),
          ...recentlyViewedProducts.map((product) => product.category),
        ]) ??
        'vegetables';

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onShopTap,
      child: HomeHeroImageSlideshow(category: category),
    );
  }
}

class HomeHeroImageSlideshow extends StatefulWidget {
  final String category;

  const HomeHeroImageSlideshow({
    super.key,
    required this.category,
  });

  @override
  State<HomeHeroImageSlideshow> createState() => _HomeHeroImageSlideshowState();
}

class _HomeHeroImageSlideshowState extends State<HomeHeroImageSlideshow> {
  final PageController _controller = PageController();
  late Future<List<HomeHeroSlide>> _slidesFuture;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _slidesFuture = fetchHomeHeroSlides();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final pageCount = _lastSlideCount;
      if (pageCount <= 1) return;
      final next = (_index + 1) % pageCount;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 430),
        curve: Curves.easeInOut,
      );
    });
  }

  int _lastSlideCount = 1;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _titleForSlide(HomeHeroSlide slide) {
    final custom = slide.title?.trim() ?? '';
    if (custom.isNotEmpty) return custom;
    return 'Fresh ${widget.category.toLowerCase()}\npicked for you today!';
  }

  String _subtitleForSlide(HomeHeroSlide slide) {
    final custom = slide.subtitle?.trim() ?? '';
    if (custom.isNotEmpty) return custom;
    return 'Hand-picked. Farm fresh. Just for you.';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HomeHeroSlide>>(
      future: _slidesFuture,
      builder: (context, snapshot) {
        final slides =
            _cleanHomeHeroSlides(snapshot.data ?? defaultHomeHeroSlides());
        _lastSlideCount = slides.length;
        if (_index >= slides.length) _index = 0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: 128,
            decoration: BoxDecoration(
              color: FarmColors.primarySoft,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: FarmColors.line),
              boxShadow: [
                BoxShadow(
                  color: FarmColors.shadow.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: slides.length,
                  onPageChanged: (value) {
                    if (mounted) setState(() => _index = value);
                  },
                  itemBuilder: (context, pageIndex) {
                    final slide = slides[pageIndex];
                    return Image.network(
                      slide.imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                      cacheWidth: 900,
                      errorBuilder: (_, __, ___) => Container(
                        color: FarmColors.primarySoft,
                      ),
                    );
                  },
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFFE5F3DF).withOpacity(0.98),
                        const Color(0xFFE5F3DF).withOpacity(0.88),
                        const Color(0xFFE5F3DF).withOpacity(0.35),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.48, 0.72, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 108, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _titleForSlide(slides[_index]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FarmColors.deepGreen,
                          fontSize: 16,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.25,
                        ),
                      ),
                      Text(
                        _subtitleForSlide(slides[_index]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: FarmColors.deepGreen.withOpacity(0.72),
                          fontSize: 11.5,
                          height: 1.18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          ...List.generate(slides.length, (dotIndex) {
                            final active = dotIndex == _index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.only(right: 4),
                              height: 5,
                              width: active ? 14 : 5,
                              decoration: BoxDecoration(
                                color: active
                                    ? FarmColors.green
                                    : FarmColors.green.withOpacity(0.30),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PersonalizedHomeHeader extends StatelessWidget {
  final Future<CustomerProfile?> profileFuture;
  final Future<LoyaltySummary> loyaltyFuture;
  final VoidCallback onCartTap;
  final int cartItemCount;

  const PersonalizedHomeHeader({
    super.key,
    required this.profileFuture,
    required this.loyaltyFuture,
    required this.onCartTap,
    required this.cartItemCount,
  });

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CustomerProfile?>(
      future: profileFuture,
      builder: (context, profileSnapshot) {
        final firstName = personalizedFirstName(profileSnapshot.data);
        return Padding(
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _timeGreeting(),
                      style: const TextStyle(
                        color: FarmColors.deepGreen,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            firstName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FarmColors.deepGreen,
                              fontSize: 27,
                              height: 1.02,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.65,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.wb_sunny_rounded,
                          color: Color(0xFFFFC928),
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Happy Harvest Day!',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: FarmHeaderInboxButton(size: 42),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onShopTap;
  final ValueChanged<String> onCategoryTap;
  final VoidCallback onCartTap;
  final int cartItemCount;
  final List<Product> recentlyViewedProducts;
  final List<Product> favoriteProducts;
  final void Function(Product product) onAddToCart;
  final void Function(Product product) onRemoveFromCart;
  final int Function(Product product) quantityForProduct;
  final void Function(Product product) onViewed;
  final VoidCallback onViewMyBox;
  final VoidCallback onCheckout;

  const HomeScreen({
    super.key,
    required this.onShopTap,
    required this.onCategoryTap,
    required this.onCartTap,
    required this.cartItemCount,
    this.recentlyViewedProducts = const [],
    this.favoriteProducts = const [],
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.quantityForProduct,
    required this.onViewed,
    required this.onViewMyBox,
    required this.onCheckout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Product>> homeProductsFuture;
  late Future<List<Product>> buyAgainProductsFuture;
  late Future<CustomerProfile?> customerProfileFuture;
  late Future<LoyaltySummary> loyaltySummaryFuture;
  List<Product> cachedHomeProducts = const <Product>[];

  @override
  void initState() {
    super.initState();
    homeProductsFuture = loadHomeProducts();
    buyAgainProductsFuture = fetchBuyAgainProductsForCustomerUi();
    customerProfileFuture = fetchCurrentCustomerProfile();
    loyaltySummaryFuture = fetchLoyaltySummary();
  }

  Future<List<Product>> loadHomeProducts({bool forceRefresh = false}) async {
    final cached = FarmDataCache.products;

    if (!forceRefresh && cached != null && cached.isNotEmpty) {
      final visible = List<Product>.from(cached)
        ..sort(compareCustomerProductAvailabilityThenName);

      cachedHomeProducts = visible;

      unawaited(_refreshHomeProductsQuietly());

      return cachedHomeProducts;
    }

    final products = await fetchProductsForCustomerUi(
      forceRefresh: forceRefresh,
      timeout: const Duration(seconds: 8),
    );

    final visible = List<Product>.from(products)
      ..sort(compareCustomerProductAvailabilityThenName);

    cachedHomeProducts = visible;
    return cachedHomeProducts;
  }

  Future<void> _refreshHomeProductsQuietly() async {
    try {
      final products = await fetchProductsForCustomerUi(
        forceRefresh: true,
        timeout: const Duration(seconds: 8),
      );

      final visible = List<Product>.from(products)
        ..sort(compareCustomerProductAvailabilityThenName);

      if (!mounted || visible.isEmpty) return;

      setState(() {
        cachedHomeProducts = visible;
        homeProductsFuture = Future<List<Product>>.value(cachedHomeProducts);
      });
    } catch (error) {
      farmDebugLog('Quiet home refresh skipped: $error');
    }
  }

  Future<void> refreshHomeProducts() async {
    FarmDataCache.clearProducts();
    if (!mounted) return;

    final nextHomeProducts = loadHomeProducts(forceRefresh: true);
    final nextBuyAgainProducts = fetchBuyAgainProductsForCustomerUi();
    final nextCustomerProfile = fetchCurrentCustomerProfile();
    final nextLoyaltySummary = fetchLoyaltySummary();

    setState(() {
      homeProductsFuture = nextHomeProducts;
      buyAgainProductsFuture = nextBuyAgainProducts;
      customerProfileFuture = nextCustomerProfile;
      loyaltySummaryFuture = nextLoyaltySummary;
    });

    await Future.wait<dynamic>([
      nextHomeProducts,
      nextBuyAgainProducts,
      nextCustomerProfile,
      nextLoyaltySummary,
    ]);
  }

  void openProduct(Product product) {
    widget.onViewed(product);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: product,
          quantity: widget.quantityForProduct(product),
          onAdd: () => widget.onAddToCart(product),
          onRemove: () => widget.onRemoveFromCart(product),
          onAddProduct: widget.onAddToCart,
          onViewed: widget.onViewed,
          onViewMyBox: widget.onViewMyBox,
          onCheckout: widget.onCheckout,
        ),
      ),
    );
  }

  Widget productRail({
    required List<Product> products,
    required int maxItems,
  }) {
    final visible = products.take(maxItems).toList();

    if (visible.isEmpty) {
      return const FarmCard(
        child: Text(
          'No fresh products are available right now. Please check back soon.',
        ),
      );
    }

    return SizedBox(
      height: 224,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        cacheExtent: AppPerformanceConfig.productRailCacheExtent,
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = visible[index];

          return InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => openProduct(product),
            child: SizedBox(
              width: 166,
              child: Opacity(
                opacity: product.isOutOfStock ? 0.72 : 1,
                child: FarmCard(
                  padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 96,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Center(
                              child: ProductVisual(product: product, size: 82),
                            ),
                            if (product.isOrganic)
                              const Positioned(
                                top: 2,
                                left: 2,
                                child: OrganicImageStamp(compact: true),
                              ),
                            if (product.hasActiveDiscount)
                              Positioned(
                                top: 2,
                                right: 2,
                                child: DiscountBadge(
                                  product: product,
                                  compact: true,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 7),
                      _HomeProductName(product: product),
                      const SizedBox(height: 6),
                      _HomePricePanel(product: product),
                      ProductAvailabilityChip(product: product, compact: true),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget loadingRail() {
    return const ProductRailSkeleton();
  }

  @override
  Widget build(BuildContext context) {
    return FarmPage(
      child: FutureBuilder<List<Product>>(
        future: homeProductsFuture,
        builder: (context, snapshot) {
          final products = snapshot.data ?? cachedHomeProducts;
          final harvestThisWeekProducts =
              products.where(isProductHarvestedThisWeek).toList();

          final weeklyHarvestProducts = harvestThisWeekProducts.isNotEmpty
              ? harvestThisWeekProducts
              : products.take(8).toList();

          final cleanRecentlyViewed = refreshProductSnapshotsFromLatestProducts(
            savedProducts: widget.recentlyViewedProducts,
            latestProducts: products,
          );
          final cleanFavoriteProducts =
              refreshProductSnapshotsFromLatestProducts(
            savedProducts: widget.favoriteProducts,
            latestProducts: products,
            limit: 20,
          );

          return FutureBuilder<List<Product>>(
            future: buyAgainProductsFuture,
            builder: (context, buyAgainSnapshot) {
              final rawBuyAgainProducts =
                  buyAgainSnapshot.data ?? const <Product>[];
              final buyAgainProducts =
                  uniqueVisibleProducts(rawBuyAgainProducts, limit: 10);
              final recommendedProducts = buildRecommendedForYouProducts(
                allProducts: products,
                recentlyViewedProducts: cleanRecentlyViewed,
                buyAgainProducts: buyAgainProducts,
                favoriteProducts: cleanFavoriteProducts,
              );

              final recommendedIds =
                  recommendedProducts.map((product) => product.id).toSet();
              final freshProductsForHome = uniqueVisibleProducts(
                weeklyHarvestProducts,
                limit: 8,
                excludeIds: recommendedIds,
              );
              final freshIds =
                  freshProductsForHome.map((product) => product.id).toSet();
              final buyAgainForHome = uniqueVisibleProducts(
                buyAgainProducts,
                limit: 8,
                excludeIds: {...recommendedIds, ...freshIds},
              );
              final buyAgainIds =
                  buyAgainForHome.map((product) => product.id).toSet();
              final recentlyViewedForHome = uniqueVisibleProducts(
                cleanRecentlyViewed,
                limit: 8,
                excludeIds: {...recommendedIds, ...freshIds, ...buyAgainIds},
              );
              final favoritesForHome = uniqueVisibleProducts(
                cleanFavoriteProducts,
                limit: 8,
              );
              final showFavorites = favoritesForHome.isNotEmpty;
              final showBuyAgain = buyAgainForHome.isNotEmpty;
              final showRecentlyViewed = recentlyViewedForHome.isNotEmpty;
              final popularCategories = buildPopularCategorySummaries(products);
              final categoryCards = <PopularCategorySummary>[
                if (showFavorites)
                  PopularCategorySummary(
                    name: 'Favorites',
                    previewProduct: favoritesForHome.first,
                    availableItemCount: favoritesForHome.length,
                  ),
                ...popularCategories,
              ];

              return RefreshIndicator(
                onRefresh: refreshHomeProducts,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 128),
                  children: [
                    PersonalizedHomeHeader(
                      profileFuture: customerProfileFuture,
                      loyaltyFuture: loyaltySummaryFuture,
                      onCartTap: widget.onCartTap,
                      cartItemCount: widget.cartItemCount,
                    ),
                    const SizedBox(height: 14),
                    PersonalizedHomeHeroLoader(
                      profileFuture: customerProfileFuture,
                      loyaltyFuture: loyaltySummaryFuture,
                      allProducts: products,
                      buyAgainProducts: buyAgainProducts,
                      favoriteProducts: cleanFavoriteProducts,
                      recentlyViewedProducts: cleanRecentlyViewed,
                      onShopTap: widget.onShopTap,
                    ),
                    const SizedBox(height: 18),
                    PersonalizedLoyaltyCard(
                      loyaltyFuture: loyaltySummaryFuture,
                    ),
                    if (!snapshot.hasError &&
                        recommendedProducts.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      SectionHeader(
                        title: 'Recommended For You',
                        subtitle: 'Fresh picks selected for your basket',
                        actionLabel: 'Shop all',
                        onAction: widget.onShopTap,
                      ),
                      const SizedBox(height: 12),
                      ProductMiniRail(
                        products: recommendedProducts,
                        onProductTap: openProduct,
                      ),
                    ],
                    const SizedBox(height: 16),
                    DealOfTheDaySection(
                      onViewed: widget.onViewed,
                      onAddProduct: widget.onAddToCart,
                      onViewMyBox: widget.onViewMyBox,
                      onCheckout: widget.onCheckout,
                    ),
                    const SizedBox(height: 18),
                    SectionHeader(
                      title: 'Fresh Products',
                      subtitle: 'Fresh items available now',
                      actionLabel: 'Shop all',
                      onAction: widget.onShopTap,
                    ),
                    const SizedBox(height: 12),
                    snapshot.connectionState == ConnectionState.waiting && products.isEmpty
                        ? loadingRail()
                        : productRail(
                            products: freshProductsForHome.isNotEmpty
                                ? freshProductsForHome
                                : weeklyHarvestProducts,
                            maxItems: 8,
                          ),
                    if (showFavorites) ...[
                      const SizedBox(height: 20),
                      SectionHeader(
                        title: 'Favorites',
                        subtitle: 'Saved picks you can shop quickly',
                        actionLabel: 'View all',
                        onAction: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FavoritesScreen(
                                products: favoritesForHome,
                                onShopTap: widget.onShopTap,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      ProductMiniRail(
                        products: favoritesForHome,
                        onProductTap: openProduct,
                      ),
                    ],
                    if (showBuyAgain) ...[
                      const SizedBox(height: 20),
                      SectionHeader(
                        title: 'Buy Again',
                        subtitle: 'Items from your past orders',
                        actionLabel: 'View shop',
                        onAction: widget.onShopTap,
                      ),
                      const SizedBox(height: 12),
                      buyAgainSnapshot.connectionState ==
                              ConnectionState.waiting
                          ? loadingRail()
                          : productRail(products: buyAgainForHome, maxItems: 8),
                    ],
                    if (showRecentlyViewed) ...[
                      const SizedBox(height: 20),
                      SectionHeader(
                        title: 'Recently Viewed',
                        subtitle: 'Items you looked at recently',
                        actionLabel: 'Shop',
                        onAction: widget.onShopTap,
                      ),
                      const SizedBox(height: 12),
                      ProductMiniRail(
                        products: recentlyViewedForHome,
                        onProductTap: openProduct,
                      ),
                    ],
                    if (categoryCards.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      SectionHeader(
                        title: 'Shop by Category',
                        subtitle: 'Find fresh picks by type',
                        actionLabel: 'View all',
                        onAction: widget.onShopTap,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 76,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(right: 4),
                          itemCount: categoryCards.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final category = categoryCards[index];
                            return SizedBox(
                              // Wider landscape cards keep names like
                              // “Vegetables” on one line while the row
                              // still uses much less vertical space.
                              width: categoryCards.length == 1 ? 272 : 218,
                              child: CategoryPill(
                                previewProduct: category.previewProduct,
                                fallbackIcon:
                                    categoryIconForName(category.name),
                                label: category.name,
                                count: category.availableItemCount,
                                onTap: () =>
                                    widget.onCategoryTap(category.name),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HomeProductName extends StatelessWidget {
  final Product product;
  final bool compact;

  const _HomeProductName({
    required this.product,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth <= 0
            ? (compact ? 138.0 : 150.0)
            : constraints.maxWidth;
        final scale = (availableWidth / (compact ? 138.0 : 150.0))
            .clamp(0.92, 1.05)
            .toDouble();
        final fontSize = (compact ? 13.2 : 13.8) * scale;

        return Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: FarmColors.ink,
            fontSize: fontSize,
            height: 1.08,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.08,
          ),
        );
      },
    );
  }
}

class _HomePricePanel extends StatelessWidget {
  final Product product;
  final bool compact;

  const _HomePricePanel({
    required this.product,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth <= 0
            ? (compact ? 138.0 : 150.0)
            : constraints.maxWidth;
        final scale = (availableWidth / (compact ? 138.0 : 150.0))
            .clamp(0.90, 1.05)
            .toDouble();
        final priceFontSize = (compact ? 13.6 : 14.2) * scale;
        final originalFontSize = (compact ? 9.8 : 10.4) * scale;
        final priceColor =
            product.isOutOfStock ? FarmColors.mutedText : FarmColors.green;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 9,
            vertical: compact ? 5 : 7,
          ),
          decoration: BoxDecoration(
            color: product.isOutOfStock
                ? FarmColors.cardSoft
                : FarmColors.lightGreen,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: product.isOutOfStock
                  ? FarmColors.line.withOpacity(0.85)
                  : FarmColors.green.withOpacity(0.10),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product.formattedEffectivePrice,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: priceColor,
                  fontSize: priceFontSize,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.15,
                ),
              ),
              if (product.hasActiveDiscount && !product.isOutOfStock) ...[
                const SizedBox(height: 2),
                Text(
                  product.formattedOriginalPrice,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: originalFontSize,
                    height: 1.0,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// Hidden from navigation pending future recipe/content strategy.
class VeganIngredientBookScreen extends StatefulWidget {
  final VoidCallback onShopTap;

  const VeganIngredientBookScreen({
    super.key,
    required this.onShopTap,
  });

  @override
  State<VeganIngredientBookScreen> createState() =>
      _VeganIngredientBookScreenState();
}

class ShopScreen extends StatefulWidget {
  final void Function(Product product) onAddToCart;
  final void Function(Product product) onRemoveFromCart;
  final int Function(Product product) quantityForProduct;
  final bool Function(Product product) isFavorite;
  final void Function(Product product) onToggleFavorite;
  final void Function(Product product) onViewed;
  final List<Product> recentlyViewedProducts;
  final String initialCategory;
  final int categorySelectionVersion;
  final VoidCallback onViewMyBox;
  final VoidCallback onCheckout;

  const ShopScreen({
    super.key,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.quantityForProduct,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onViewed,
    this.recentlyViewedProducts = const [],
    this.initialCategory = 'All',
    this.categorySelectionVersion = 0,
    required this.onViewMyBox,
    required this.onCheckout,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final searchController = TextEditingController();
  late String selectedCategory;
  List<Product> products = const <Product>[];
  List<Product> readySoonProducts = const [];
  List<Product> buyAgainProducts = const [];
  bool loadingProducts = true;
  String? productLoadMessage;
  String selectedShopFilter = 'All items';
  String selectedSort = 'Featured';
  Timer? searchDebounce;

  @override
  void initState() {
    super.initState();
    selectedCategory = normalizeProductCategory(widget.initialCategory);
    searchController.addListener(() {
      searchDebounce?.cancel();
      searchDebounce = Timer(AppPerformanceConfig.debounce, () {
        if (mounted) setState(() {});
      });
    });
    loadProducts();
  }

  @override
  void didUpdateWidget(covariant ShopScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.categorySelectionVersion != oldWidget.categorySelectionVersion) {
      final nextCategory = normalizeProductCategory(widget.initialCategory);
      if (selectedCategory != nextCategory) {
        setState(() {
          selectedCategory = nextCategory;
          selectedShopFilter = 'All items';
          searchController.clear();
        });
      }
    }
  }

  @override
  void dispose() {
    searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadProducts() async {
    if (!mounted) return;

    setState(() {
      loadingProducts = true;
      productLoadMessage = null;
    });

    try {
      final fetchedProducts = await fetchProductsForCustomerUi(
        forceRefresh: products.isEmpty,
        timeout: const Duration(seconds: 8),
      );
      final cleanProducts = fetchedProducts.where((product) {
        return product.name.trim().isNotEmpty && product.price >= 0;
      }).toList()
        ..sort(compareCustomerProductAvailabilityThenName);

      if (!mounted) return;
      setState(() {
        products = cleanProducts;
        loadingProducts = false;
        productLoadMessage = cleanProducts.isEmpty
            ? 'No fresh products are available right now. Please check back soon.'
            : null;
      });

      _loadOptionalShopProductSections();
    } catch (error) {
      farmDebugLog('Shop product load failed: $error');
      if (!mounted) return;
      setState(() {
        loadingProducts = false;
        productLoadMessage = products.isEmpty
            ? 'We couldn’t load fresh products right now. Please try again.'
            : null;
      });
    }
  }

  Future<void> _loadOptionalShopProductSections() async {
    try {
      final results = await Future.wait<List<Product>>([
        fetchReadySoonProductsForCustomerUi(forceRefresh: false),
        fetchBuyAgainProductsForCustomerUi(forceRefresh: false),
      ]);

      if (!mounted) return;
      setState(() {
        readySoonProducts = results[0]
            .where((product) => product.name.trim().isNotEmpty)
            .toList();
        buyAgainProducts = uniqueVisibleProducts(results[1], limit: 10);
      });
    } catch (error) {
      farmDebugLog('Optional shop sections skipped: $error');
    }
  }

  List<String> get categories {
    final values = <String>{'All'};

    if (products.any(widget.isFavorite)) {
      values.add('Favorites');
    }

    for (final product in products) {
      final category = product.category.trim();
      if (category.isNotEmpty) values.add(category);
    }

    final list = values.toList();
    list.sort((a, b) {
      if (a == 'All') return -1;
      if (b == 'All') return 1;
      if (a == 'Favorites') return -1;
      if (b == 'Favorites') return 1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });

    return list;
  }

  List<String> get shopFilterOptions => const [
        'All items',
        'In stock',
        'Low stock',
        'Deals',
        'Organic',
        'Out of stock',
      ];

  List<String> get shopSortOptions => const [
        'Featured',
        'Newest',
        'Price: Low',
        'Price: High',
        'A-Z',
      ];

  List<Product> filteredProducts(String activeCategory) {
    final query = searchController.text.trim().toLowerCase();
    final activeCategoryLower = activeCategory.toLowerCase();
    final showingFavorites = activeCategoryLower == 'favorites';
    final cleanFilter = selectedShopFilter.trim().toLowerCase();

    return products.where((product) {
      final category = product.category.trim().toLowerCase();
      final name = product.name.trim().toLowerCase();
      final description = (product.description ?? '').trim().toLowerCase();
      final unit = (product.unit ?? '').trim().toLowerCase();
      final farmName =
          (product.farmName ?? product.farmerName ?? '').trim().toLowerCase();

      final matchesCategory = showingFavorites
          ? widget.isFavorite(product)
          : activeCategory == 'All' ||
              category == activeCategoryLower ||
              name.contains(activeCategoryLower);

      final matchesSearch = query.isEmpty ||
          name.contains(query) ||
          category.contains(query) ||
          description.contains(query) ||
          unit.contains(query) ||
          farmName.contains(query);

      final matchesFilter = cleanFilter == 'all items' ||
          (cleanFilter == 'in stock' && product.canAddToCart) ||
          (cleanFilter == 'low stock' && product.isLowStock) ||
          (cleanFilter == 'deals' && product.hasActiveDiscount) ||
          (cleanFilter == 'organic' && product.isOrganic) ||
          (cleanFilter == 'out of stock' && product.isOutOfStock);

      // When the customer types in the search box, search the whole shop.
      // This prevents a selected category chip from hiding valid search results.
      if (query.isNotEmpty) {
        return matchesSearch &&
            matchesFilter &&
            (!showingFavorites || widget.isFavorite(product));
      }

      return matchesCategory && matchesFilter;
    }).toList();
  }

  List<Product> sortedShopProducts(List<Product> source) {
    final output = List<Product>.from(source);

    switch (selectedSort) {
      case 'Newest':
        output.sort((a, b) {
          final availability = compareCustomerProductAvailabilityThenName(a, b);
          if (a.canAddToCart != b.canAddToCart) return availability;
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
        break;
      case 'Price: Low':
        output.sort((a, b) {
          if (a.canAddToCart != b.canAddToCart) {
            return a.canAddToCart ? -1 : 1;
          }
          final compare = a.effectivePrice.compareTo(b.effectivePrice);
          if (compare != 0) return compare;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
      case 'Price: High':
        output.sort((a, b) {
          if (a.canAddToCart != b.canAddToCart) {
            return a.canAddToCart ? -1 : 1;
          }
          final compare = b.effectivePrice.compareTo(a.effectivePrice);
          if (compare != 0) return compare;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
      case 'A-Z':
        output.sort(compareCustomerProductAvailabilityThenName);
        break;
      case 'Featured':
      default:
        output.sort(compareCustomerProductAvailabilityThenName);
        break;
    }

    return output;
  }

  String get activeShopSummaryLabel {
    final parts = <String>[];
    if (selectedCategory != 'All') parts.add(selectedCategory);
    if (selectedShopFilter != 'All items') parts.add(selectedShopFilter);
    if (selectedSort != 'Featured') parts.add(selectedSort);
    return parts.isEmpty ? 'All fresh items' : parts.join(' • ');
  }

  Future<void> _showShopFilterSheet(
    List<String> availableCategories,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            Widget sheetChoice({
              required String label,
              required bool selected,
              required VoidCallback onTap,
              Color color = FarmColors.green,
            }) {
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) {
                  onTap();
                  sheetSetState(() {});
                },
                selectedColor: color,
                backgroundColor: color.withOpacity(0.10),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : color,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: BorderSide(
                    color: selected ? color : color.withOpacity(0.12),
                  ),
                ),
              );
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.78,
                  ),
                  decoration: BoxDecoration(
                    color: FarmColors.card,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: FarmColors.line),
                    boxShadow: [
                      BoxShadow(
                        color: FarmColors.shadow.withOpacity(0.16),
                        blurRadius: 28,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(
                            child: Header(
                              title: 'Shop filters',
                              subtitle: 'Choose category, stock, and sorting',
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Close filters',
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Category',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: FarmColors.ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableCategories.map((category) {
                          return sheetChoice(
                            label: category,
                            selected: selectedCategory == category,
                            onTap: () {
                              setState(() {
                                selectedCategory = category;
                                selectedShopFilter = 'All items';
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Show',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: FarmColors.ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: shopFilterOptions.map((filter) {
                          final isOutOfStock = filter == 'Out of stock';
                          final isDeal = filter == 'Deals';
                          final color = isOutOfStock
                              ? FarmColors.danger
                              : isDeal
                                  ? FarmColors.warning
                                  : FarmColors.green;
                          return sheetChoice(
                            label: filter,
                            selected: selectedShopFilter == filter,
                            color: color,
                            onTap: () {
                              setState(() => selectedShopFilter = filter);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Sort',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: FarmColors.ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: shopSortOptions.map((sort) {
                          return sheetChoice(
                            label: sort,
                            selected: selectedSort == sort,
                            onTap: () {
                              setState(() => selectedSort = sort);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  selectedCategory = 'All';
                                  selectedShopFilter = 'All items';
                                  selectedSort = 'Featured';
                                });
                                sheetSetState(() {});
                              },
                              icon: const Icon(Icons.restart_alt_rounded),
                              label: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStickySearchAndFilters(
    List<String> availableCategories,
    String activeCategory,
  ) {
    final resultCount = filteredProducts(activeCategory).length;
    final activeSortLabel = selectedSort == 'Featured'
        ? 'Featured'
        : selectedSort.replaceAll('Price: ', 'Price ');
    final hasActiveShopControls = activeCategory != 'All' ||
        selectedShopFilter != 'All items' ||
        selectedSort != 'Featured';

    return Container(
      color: FarmColors.background,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.98),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: FarmColors.line.withOpacity(0.7)),
          boxShadow: [
            BoxShadow(
              color: FarmColors.shadow.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) {
                      if (mounted) setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Search produce, farms, units...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close),
                              onPressed: searchController.clear,
                            ),
                      filled: true,
                      fillColor: FarmColors.cream,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Filters and sorting',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _showShopFilterSheet(availableCategories),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: hasActiveShopControls
                            ? FarmColors.green
                            : FarmColors.primarySoft,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: hasActiveShopControls
                              ? FarmColors.green.withOpacity(0.22)
                              : FarmColors.green.withOpacity(0.16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: FarmColors.shadow.withOpacity(
                              hasActiveShopControls ? 0.12 : 0.05,
                            ),
                            blurRadius: hasActiveShopControls ? 14 : 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: hasActiveShopControls
                                ? Colors.white
                                : FarmColors.green,
                            size: 20,
                          ),
                          if (hasActiveShopControls)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: FarmColors.gold,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: Text(
                    loadingProducts && products.isEmpty
                        ? 'Loading fresh items…'
                        : '$resultCount ${resultCount == 1 ? 'item' : 'items'} • $activeSortLabel • $activeShopSummaryLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (selectedCategory != 'All' ||
                    selectedShopFilter != 'All items' ||
                    selectedSort != 'Featured' ||
                    searchController.text.trim().isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedCategory = 'All';
                        selectedShopFilter = 'All items';
                        selectedSort = 'Featured';
                        searchController.clear();
                      });
                    },
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableCategories = categories;
    final activeCategory = availableCategories.contains(selectedCategory)
        ? selectedCategory
        : 'All';
    final visibleProducts = filteredProducts(activeCategory);
    final cleanRecentlyViewed = refreshProductSnapshotsFromLatestProducts(
      savedProducts: widget.recentlyViewedProducts,
      latestProducts: products,
    );
    final favoriteProducts =
        products.where((product) => widget.isFavorite(product)).toList();
    final visibleCustomerProducts = visibleProducts
        .where((product) => isVisibleCustomerProduct(product))
        .toList();
    final availableNowProducts = selectedSort == 'Featured'
        ? sortProductsForPersonalization(
            products: visibleCustomerProducts
              ..sort(compareCustomerProductAvailabilityThenName),
            recentlyViewedProducts: cleanRecentlyViewed,
            buyAgainProducts: buyAgainProducts,
            favoriteProducts: favoriteProducts,
          )
        : sortedShopProducts(visibleCustomerProducts);
    final suggestedForYouProducts = buildRecommendedForYouProducts(
      allProducts: products,
      recentlyViewedProducts: cleanRecentlyViewed,
      buyAgainProducts: buyAgainProducts,
      favoriteProducts: favoriteProducts,
      selectedCategory: activeCategory,
    );

    final contentSections = <Widget>[
      if (!loadingProducts && suggestedForYouProducts.isNotEmpty) ...[
        SectionHeader(
          title: 'Suggested for You',
          subtitle: 'Personalized using your views and past orders',
        ),
        const SizedBox(height: 12),
        ProductMiniRail(
          products: suggestedForYouProducts,
          onProductTap: (product) {
            widget.onViewed(product);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(
                  product: product,
                  quantity: widget.quantityForProduct(product),
                  onAdd: () => widget.onAddToCart(product),
                  onRemove: () => widget.onRemoveFromCart(product),
                  onAddProduct: widget.onAddToCart,
                  onViewed: widget.onViewed,
                  onViewMyBox: widget.onViewMyBox,
                  onCheckout: widget.onCheckout,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
      ],
      if (!loadingProducts && availableNowProducts.isNotEmpty) ...[
        SectionHeader(
          title: activeCategory == 'All' ? 'Fresh shop' : activeCategory,
          subtitle: selectedShopFilter == 'All items'
              ? 'Browse available and out-of-stock items clearly marked'
              : selectedShopFilter,
        ),
        const SizedBox(height: 12),
      ],
      if (productLoadMessage != null) ...[
        FarmCard(
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: FarmColors.green),
              const SizedBox(width: 9),
              Expanded(child: Text(productLoadMessage!)),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (loadingProducts && products.isEmpty) ...[
        const FarmSkeletonCard(height: 180),
        const FarmSkeletonCard(height: 180),
        const FarmSkeletonCard(height: 180),
      ] else if (availableNowProducts.isEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(top: 30),
          child: FarmEmptyState(
            icon: activeCategory == 'Favorites'
                ? Icons.favorite_border_rounded
                : Icons.storefront_outlined,
            title: activeCategory == 'Favorites'
                ? 'No favorites here yet'
                : 'No products found',
            message: activeCategory == 'All'
                ? 'No products match your search. Try another category or clear the search.'
                : activeCategory == 'Favorites'
                    ? 'Tap the heart on products you love to save them here.'
                    : 'No items are listed in $activeCategory right now. Try another category or clear the search.',
          ),
        ),
      ] else ...[
        ...availableNowProducts.map((product) {
          final quantity = widget.quantityForProduct(product);

          return SafeShopProductTile(
            key: ValueKey('shop-${product.id}-${product.name}'),
            product: product,
            quantity: quantity,
            isFavorite: widget.isFavorite(product),
            onFavorite: () => widget.onToggleFavorite(product),
            onAdd: () => widget.onAddToCart(product),
            onRemove: () => widget.onRemoveFromCart(product),
            onOpenDetails: () {
              widget.onViewed(product);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(
                    product: product,
                    quantity: quantity,
                    onAdd: () => widget.onAddToCart(product),
                    onRemove: () => widget.onRemoveFromCart(product),
                    onAddProduct: widget.onAddToCart,
                    onViewed: widget.onViewed,
                    onViewMyBox: widget.onViewMyBox,
                    onCheckout: widget.onCheckout,
                  ),
                ),
              );
            },
          );
        }),
        const SizedBox(height: 90),
      ],
    ];

    return FarmPage(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Header(
                    title: 'Shop',
                    subtitle: 'Fresh natural produce',
                  ),
                ),
              ],
            ),
          ),
          _buildStickySearchAndFilters(
            availableCategories,
            activeCategory,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadProducts,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                children: contentSections,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minExtentValue;
  final double maxExtentValue;
  final Widget child;

  const _ShopSearchHeaderDelegate({
    required this.minExtentValue,
    required this.maxExtentValue,
    required this.child,
  });

  @override
  double get minExtent => minExtentValue;

  @override
  double get maxExtent => maxExtentValue;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: FarmColors.background,
      elevation: overlapsContent ? 2 : 0,
      shadowColor: FarmColors.shadow.withOpacity(0.14),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _ShopSearchHeaderDelegate oldDelegate) {
    return minExtentValue != oldDelegate.minExtentValue ||
        maxExtentValue != oldDelegate.maxExtentValue ||
        child != oldDelegate.child;
  }
}

class SafeShopProductTile extends StatelessWidget {
  final Product product;
  final int quantity;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onOpenDetails;

  const SafeShopProductTile({
    super.key,
    required this.product,
    required this.quantity,
    required this.isFavorite,
    required this.onFavorite,
    required this.onAdd,
    required this.onRemove,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    final name = product.name.trim().isEmpty ? 'Product' : product.name.trim();
    final description = (product.description ?? '').trim().isEmpty
        ? 'Fresh natural harvest from the farm.'
        : product.description!.trim();
    final inStock = product.canAddToCart;
    final muted = product.isOutOfStock;

    Widget favoriteButton() {
      return SizedBox(
        width: 38,
        height: 38,
        child: Material(
          color: isFavorite
              ? FarmColors.dangerSoft
              : FarmColors.lightGreen.withOpacity(0.72),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onFavorite,
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: 19,
              color: isFavorite ? FarmColors.danger : FarmColors.green,
            ),
          ),
        ),
      );
    }

    Widget quantityControl({required bool fullWidth}) {
      Widget stepButton({
        required IconData icon,
        required VoidCallback? onPressed,
        required bool filled,
      }) {
        return SizedBox(
          height: 30,
          width: 30,
          child: Material(
            color: filled ? FarmColors.green : Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Icon(
                icon,
                size: 17,
                color: filled ? Colors.white : FarmColors.green,
              ),
            ),
          ),
        );
      }

      return SizedBox(
        width: fullWidth ? double.infinity : 118,
        height: 38,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: FarmColors.green.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: FarmColors.shadow.withOpacity(0.035),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              stepButton(
                icon: Icons.remove_rounded,
                onPressed: onRemove,
                filled: false,
              ),
              Expanded(
                child: Text(
                  fullWidth ? '$quantity in box' : '$quantity',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: FarmColors.green,
                    fontSize: 13.2,
                    letterSpacing: -0.05,
                  ),
                ),
              ),
              stepButton(
                icon: Icons.add_rounded,
                onPressed: inStock ? onAdd : null,
                filled: true,
              ),
            ],
          ),
        ),
      );
    }

    Widget primaryAction({required bool fullWidth}) {
      if (quantity > 0) return quantityControl(fullWidth: fullWidth);

      if (!inStock) {
        return SizedBox(
          width: fullWidth ? double.infinity : 126,
          child: NotifyMeWhenReadyButton(product: product, compact: true),
        );
      }

      return SizedBox(
        width: fullWidth ? double.infinity : 112,
        height: 40,
        child: ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 17),
          label: const Text('Add'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: muted ? FarmColors.cardSoft : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: muted
              ? FarmColors.danger.withOpacity(0.13)
              : FarmColors.line.withOpacity(0.84),
          width: 1.05,
        ),
        boxShadow: [
          BoxShadow(
            color: FarmColors.shadow.withOpacity(muted ? 0.025 : 0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onOpenDetails,
          child: Opacity(
            opacity: muted ? 0.82 : 1,
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        height: 92,
                        width: 92,
                        child: Center(
                          child: ProductVisual(
                            product: product,
                            size: 72,
                            // Keep product-list imagery clean. Organic is shown
                            // as a text chip below so it never clashes with
                            // discount badges on the image.
                            showOrganicBadge: false,
                          ),
                        ),
                      ),
                      if (product.hasActiveDiscount && !product.isOutOfStock)
                        Positioned(
                          top: -3,
                          left: -3,
                          child: DiscountBadge(product: product, compact: true),
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
                                name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16.4,
                                  height: 1.08,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            favoriteButton(),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 12.6,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (product.isOrganic)
                              const _SmallShopChip(label: 'Organic'),
                            ProductOriginBadge(
                              product: product,
                              compact: true,
                              includeIcon: false,
                            ),
                            ProductUnitChip(product: product, compact: true),
                            ProductAvailabilityChip(
                                product: product, compact: true),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 224;
                            final price = DiscountPriceText(
                              product: product,
                              compact: true,
                            );

                            if (isNarrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  price,
                                  const SizedBox(height: 8),
                                  primaryAction(fullWidth: true),
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: price),
                                const SizedBox(width: 9),
                                primaryAction(fullWidth: false),
                              ],
                            );
                          },
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
    );
  }
}

class _SmallShopChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color backgroundColor;

  const _SmallShopChip({
    required this.label,
    this.color = FarmColors.green,
    this.backgroundColor = FarmColors.lightGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class FarmBoxScreen extends StatelessWidget {
  final List<Product> cart;
  final void Function(Product product) onRemoveFromCart;
  final void Function(Product product) onAddToCart;
  final VoidCallback onOrderPlaced;
  final VoidCallback? onInventoryChanged;

  const FarmBoxScreen({
    super.key,
    required this.cart,
    required this.onRemoveFromCart,
    required this.onAddToCart,
    required this.onOrderPlaced,
    this.onInventoryChanged,
  });

  Map<String, CartLine> get groupedCart {
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

    return grouped;
  }

  double get subtotal {
    return groupedCart.values.fold(
      0,
      (total, line) => total + (line.product.effectivePrice * line.quantity),
    );
  }

  double get originalSubtotal {
    return groupedCart.values.fold(
      0,
      (total, line) =>
          total + (line.product.originalPriceValue * line.quantity),
    );
  }

  double get totalSavings {
    final savings = originalSubtotal - subtotal;
    return savings <= 0 ? 0 : savings;
  }

  int get totalItems {
    return groupedCart.values.fold(0, (total, line) => total + line.quantity);
  }

  int get unavailableItems {
    return groupedCart.values
        .where((line) => !line.product.canAddToCart)
        .length;
  }

  Widget _miniStat({
    required IconData icon,
    required String label,
    required String value,
    Color color = FarmColors.green,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.78),
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
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

  Widget _boxHeroCard(List<CartLine> lines) {
    final hasItems = lines.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FarmColors.green,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: FarmColors.green.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
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
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.shopping_basket_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Farm Box',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      hasItems
                          ? 'Review your fresh picks before checkout.'
                          : 'Build your box with fresh local produce.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _miniStat(
                icon: Icons.inventory_2_outlined,
                label: 'Items',
                value: '$totalItems',
              ),
              const SizedBox(width: 10),
              _miniStat(
                icon: totalSavings > 0
                    ? Icons.savings_outlined
                    : Icons.receipt_long_outlined,
                label: totalSavings > 0 ? 'Saved' : 'Subtotal',
                value: totalSavings > 0
                    ? formatJmd(totalSavings)
                    : formatJmd(subtotal),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _linePill({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.6,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool filled = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onPressed,
      child: AnimatedOpacity(
        opacity: onPressed == null ? 0.42 : 1,
        duration: const Duration(milliseconds: 140),
        child: Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: filled ? FarmColors.green : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: filled
                  ? FarmColors.green
                  : FarmColors.green.withOpacity(0.24),
            ),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: FarmColors.green.withOpacity(0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : const [],
          ),
          child: Icon(
            icon,
            size: 17,
            color: filled ? Colors.white : FarmColors.green,
          ),
        ),
      ),
    );
  }

  Widget _quantityControl(CartLine line) {
    final product = line.product;
    final canIncrease =
        product.canAddToCart && line.quantity < product.stockQuantity;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: FarmColors.line.withOpacity(0.86)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _quantityButton(
            icon: Icons.remove,
            onPressed: () => onRemoveFromCart(product),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 54),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${line.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: FarmColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _quantityButton(
            icon: Icons.add,
            filled: true,
            onPressed: canIncrease ? () => onAddToCart(product) : null,
          ),
        ],
      ),
    );
  }

  Widget _cartLineCard(CartLine line) {
    final product = line.product;
    final lineTotal = product.effectivePrice * line.quantity;
    final lineSavings =
        ((product.originalPriceValue - product.effectivePrice) * line.quantity)
            .clamp(0, double.infinity)
            .toDouble();
    final farmName = (product.farmName ?? product.farmerName ?? '').trim();
    final unit = (product.unit ?? '').trim();

    return FarmCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ProductVisual(product: product, size: 66),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.15,
                      ),
                    ),
                    if (farmName.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        farmName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FarmColors.green,
                          fontSize: 12.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _linePill(
                          label: product.canAddToCart
                              ? product.originLabel
                              : 'Unavailable',
                          color: product.canAddToCart
                              ? productOriginColor(product)
                              : FarmColors.danger,
                          icon: product.canAddToCart
                              ? productOriginIcon(product)
                              : Icons.block_outlined,
                        ),
                        if (unit.isNotEmpty)
                          _linePill(
                            label: unit,
                            color: FarmColors.mutedText,
                            icon: Icons.straighten_outlined,
                          ),
                        if (product.isLowStock)
                          _linePill(
                            label: product.lowStockLabel,
                            color: FarmColors.warning,
                            icon: Icons.local_fire_department_outlined,
                          ),
                        if (product.isOutOfStock)
                          _linePill(
                            label: 'Out of stock',
                            color: FarmColors.danger,
                            icon: Icons.block_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FarmColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FarmColors.line.withOpacity(0.72)),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatJmd(lineTotal),
                            style: const TextStyle(
                              color: FarmColors.green,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${formatJmd(product.effectivePrice)} each',
                            style: const TextStyle(
                              color: FarmColors.mutedText,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          if (lineSavings > 0) ...[
                            const SizedBox(height: 5),
                            Text(
                              'You save ${formatJmd(lineSavings)}',
                              style: const TextStyle(
                                color: FarmColors.warning,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _quantityControl(line),
                  ],
                ),
                if (!product.canAddToCart) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Icon(Icons.info_outline,
                          size: 16, color: FarmColors.danger),
                      SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Remove this item before checkout. It is not available right now.',
                          style: TextStyle(
                            color: FarmColors.danger,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: bold ? FarmColors.ink : FarmColors.mutedText,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: bold ? FarmColors.green : FarmColors.ink,
              fontSize: bold ? 18 : 14,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkoutBar(BuildContext context, List<CartLine> lines) {
    final hasUnavailable = unavailableItems > 0;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: FarmColors.line.withOpacity(0.86)),
          boxShadow: [
            BoxShadow(
              color: FarmColors.shadow.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _summaryRow('Items', '$totalItems'),
            if (totalSavings > 0)
              _summaryRow('Savings', formatJmd(totalSavings)),
            _summaryRow('Subtotal', formatJmd(subtotal), bold: true),
            if (hasUnavailable) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FarmColors.dangerSoft,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: FarmColors.danger.withOpacity(0.14)),
                ),
                child: const Text(
                  'Remove unavailable items before checkout.',
                  style: TextStyle(
                    color: FarmColors.danger,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: PrimaryFarmButton(
                label: 'Secure Checkout',
                icon: Icons.lock_outline,
                onPressed: lines.isEmpty || hasUnavailable
                    ? null
                    : () async {
                        final allowed = await requireLoginForCheckout(context);
                        if (!context.mounted || !allowed) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutScreen(
                              cartLines: lines,
                              subtotal: subtotal,
                              onOrderPlaced: onOrderPlaced,
                              onInventoryChanged: onInventoryChanged,
                            ),
                          ),
                        );
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = groupedCart.values.toList();

    return FarmPage(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              children: [
                _boxHeroCard(lines),
                const SizedBox(height: 16),
                if (lines.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.shopping_basket_outlined,
                    title: 'Your farm box is empty',
                    message:
                        'Go to Shop and add fresh items. Your box will stay ready here for checkout.',
                  )
                else ...[
                  Row(
                    children: const [
                      Expanded(
                        child: Text(
                          'Selected items',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.25,
                          ),
                        ),
                      ),
                      Text(
                        'Tap + / - to adjust',
                        style: TextStyle(
                          color: FarmColors.mutedText,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...lines.map(_cartLineCard),
                ],
              ],
            ),
          ),
          if (lines.isNotEmpty) _checkoutBar(context, lines),
        ],
      ),
    );
  }
}

class OrdersScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const OrdersScreen({super.key, this.onBackToHome});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  StreamSubscription<AuthState>? _authSubscription;
  late Future<List<FarmOrder>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = fetchOrders(forceRefresh: true);
    _authSubscription = supabase.auth.onAuthStateChange.listen((_) {
      if (mounted) {
        _refreshOrders();
      }
    });
  }

  Future<void> _refreshOrders() async {
    FarmDataCache.clearOrders();
    final future = fetchOrders(forceRefresh: true);
    if (mounted) {
      setState(() {
        _ordersFuture = future;
      });
    }
    await future;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return const GuestProtectedScreen(
        title: 'My Orders',
        subtitle: 'Track your farm orders',
        message:
            'Sign in to view your orders, receipts, payment status, and delivery tracking.',
      );
    }

    return FarmPage(
      child: RefreshIndicator(
        onRefresh: _refreshOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            Header(
              title: 'My Orders',
              subtitle: 'Track your farm orders',
              showBackButton: true,
              backTooltip: 'Back to Home',
              onBack: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).maybePop();
                  return;
                }
                widget.onBackToHome?.call();
              },
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<FarmOrder>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                final orders = snapshot.data ?? [];

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SkeletonList();
                }

                if (orders.isEmpty) {
                  return const FarmEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No orders yet',
                    message:
                        'When you place an order, your receipt, status, and pickup or delivery details will appear here.',
                  );
                }

                return Column(
                  children: orders.map((order) {
                    return OrderCard(
                      order: '#${order.shortId}',
                      status: _titleCase(order.status),
                      type:
                          '${order.formattedType} • ${order.formattedPaymentMethod} • ${order.formattedPaymentStatus}',
                      total: order.formattedTotal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                OrderDetailsScreen(orderId: order.id),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Future<OrderDetails?> _orderFuture;

  @override
  void initState() {
    super.initState();
    _orderFuture = fetchOrderDetails(widget.orderId);
  }

  Future<void> _refreshOrderDetails() async {
    final future = fetchOrderDetails(widget.orderId);
    if (mounted) {
      setState(() {
        _orderFuture = future;
      });
    }
    await future;
  }

  int _statusIndex(String status) {
    switch (status) {
      case 'pending':
        return 0;
      case 'preparing':
        return 1;
      case 'ready':
      case 'ready_for_pickup':
      case 'out_for_delivery':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  Widget _trackingRow({
    required String label,
    required bool active,
    required bool complete,
  }) {
    final icon = complete ? Icons.check_circle : Icons.radio_button_unchecked;
    final color = complete || active ? FarmColors.green : FarmColors.mutedText;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return const GuestProtectedScreen(
        title: 'Order Details',
        subtitle: 'Private order information',
        message: 'Sign in to view private order details and tracking updates.',
      );
    }

    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Order Details'),
        backgroundColor: FarmColors.background,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrderDetails,
        child: FutureBuilder<OrderDetails?>(
          future: _orderFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const SkeletonList();
            }

            final order = snapshot.data;
            if (order == null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
                children: const [
                  FarmEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Order unavailable',
                    message:
                        'We could not open this order right now. Please go back to Orders and try again.',
                  ),
                ],
              );
            }

            final isDelivery = order.fulfillmentType == 'delivery';

            final bottomSafePadding = MediaQuery.of(context).viewPadding.bottom;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                56 + bottomSafePadding,
              ),
              children: [
                EliteOrderStatusCard(order: order),
                const SizedBox(height: 14),
                EliteOrderQuickActions(
                  order: order,
                  onRefresh: _refreshOrderDetails,
                ),
                const SizedBox(height: 14),
                PremiumOrderTracker(
                  status: order.status,
                  isDelivery: isDelivery,
                  paymentStatus: order.paymentStatus,
                ),
                const SizedBox(height: 14),
                FarmCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Items',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (order.items.isEmpty)
                        const Text('No item details found.')
                      else
                        ...order.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.productName} x ${item.quantity}',
                                  ),
                                ),
                                Text('J\$${item.lineTotal.toStringAsFixed(2)}'),
                              ],
                            ),
                          ),
                        ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal'),
                          Text(order.formattedSubtotal),
                        ],
                      ),
                      if (isDelivery || order.deliveryFee > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Delivery fee'),
                            Text(order.formattedDeliveryFee),
                          ],
                        ),
                      ],
                      if (order.discountAmount > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Discount'),
                            Text('-${order.formattedDiscountAmount}'),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            order.formattedTotal,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if ((order.notes ?? '').isNotEmpty) ...[
                  const SizedBox(height: 14),
                  FarmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Notes',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(order.notes!),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

// Kept outside main navigation until the shopping guide is intentionally enabled.
class FarmBoxHelperScreen extends StatefulWidget {
  const FarmBoxHelperScreen({super.key});

  @override
  State<FarmBoxHelperScreen> createState() =>
      _FarmBoxHelperScreenState();
}

class LoyaltyRewardsScreen extends StatelessWidget {
  const LoyaltyRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Harvest Rewards'),
        backgroundColor: FarmColors.background,
      ),
      body: FutureBuilder<LoyaltySummary>(
        future: fetchLoyaltySummary(),
        builder: (context, snapshot) {
          final summary = snapshot.data ??
              const LoyaltySummary(points: 0, lifetimePoints: 0, tier: 'Green');
          final progress = loyaltyProgressValue(summary);
          final pointsToNext = loyaltyPointsToNextTier(summary);
          final nextTier = loyaltyNextTierName(summary);

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
            children: [
              _RewardsHeroCard(
                summary: summary,
                progress: progress,
                pointsToNext: pointsToNext,
                nextTier: nextTier,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _RewardMetricCard(
                      icon: Icons.savings_outlined,
                      label: 'Available',
                      value: '${summary.points}',
                      helper: 'points',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _RewardMetricCard(
                      icon: Icons.trending_up_rounded,
                      label: 'Lifetime',
                      value: '${summary.lifetimePoints}',
                      helper: 'earned',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FarmCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How rewards work',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _RewardInfoRow(
                      icon: Icons.shopping_basket_outlined,
                      title: 'Earn while shopping',
                      message:
                          'Get 1 point for every J\$100 in completed farm orders.',
                    ),
                    _RewardInfoRow(
                      icon: Icons.verified_outlined,
                      title: 'Rewards grow with completed orders',
                      message:
                          'Your points update after eligible farm orders are completed.',
                    ),
                    _RewardInfoRow(
                      icon: Icons.favorite_border_rounded,
                      title: 'Support local harvests',
                      message:
                          'The more you shop fresh, the faster your tier grows.',
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const SectionHeader(
                title: 'Reward milestones',
                subtitle: 'Clear goals that make shopping feel worthwhile',
              ),
              const SizedBox(height: 10),
              _RewardMilestoneCard(
                points: 100,
                title: 'Small thank-you discount',
                description: 'A simple reward for your next farm order.',
                currentLifetimePoints: summary.lifetimePoints,
              ),
              _RewardMilestoneCard(
                points: 250,
                title: 'Free herbs add-on',
                description: 'A fresh extra when seasonal herbs are available.',
                currentLifetimePoints: summary.lifetimePoints,
              ),
              _RewardMilestoneCard(
                points: 500,
                title: 'Gold customer tier',
                description: 'Unlock stronger recognition and priority offers.',
                currentLifetimePoints: summary.lifetimePoints,
              ),
              _RewardMilestoneCard(
                points: 1000,
                title: 'Platinum customer tier',
                description: 'Top-tier status for loyal farm supporters.',
                currentLifetimePoints: summary.lifetimePoints,
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text:
                          'I have ${summary.points} Harvest Rewards points at The Harvest Place Ja.',
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rewards summary copied')),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy rewards summary'),
                style: FilledButton.styleFrom(
                  backgroundColor: FarmColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  final List<Product> products;
  final VoidCallback onShopTap;

  const FavoritesScreen({
    super.key,
    required this.products,
    required this.onShopTap,
  });

  @override
  Widget build(BuildContext context) {
    return ProductCollectionScreen(
      title: 'Favorites',
      subtitle: 'Saved products you love',
      products: products,
      emptyText:
          'No favorites yet. Tap the heart on products you love while shopping.',
      onShopTap: onShopTap,
    );
  }
}

class RecentlyViewedScreen extends StatelessWidget {
  final List<Product> products;
  final VoidCallback onShopTap;

  const RecentlyViewedScreen({
    super.key,
    required this.products,
    required this.onShopTap,
  });

  @override
  Widget build(BuildContext context) {
    return ProductCollectionScreen(
      title: 'Recently Viewed',
      subtitle: 'Products you checked recently',
      products: products,
      emptyText:
          'No recently viewed products yet. Products you open will appear here.',
      onShopTap: onShopTap,
    );
  }
}

class ProductCollectionScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Product> products;
  final String emptyText;
  final VoidCallback onShopTap;

  const ProductCollectionScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.products,
    required this.emptyText,
    required this.onShopTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(title),
        backgroundColor: FarmColors.cream,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Header(title: title, subtitle: subtitle),
          const SizedBox(height: 18),
          if (products.isEmpty)
            FarmEmptyState(
              icon: title.toLowerCase().contains('favorite')
                  ? Icons.favorite_border_rounded
                  : Icons.history_rounded,
              title: title.toLowerCase().contains('favorite')
                  ? 'No favorites yet'
                  : 'Nothing viewed yet',
              message: emptyText,
              actionLabel: 'Go to Shop',
              actionIcon: Icons.storefront_outlined,
              onAction: () {
                Navigator.pop(context);
                onShopTap();
              },
            )
          else
            ...products.map((product) => FarmCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      ProductVisual(product: product, size: 54),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(
                              (product.description ?? '').trim().isEmpty
                                  ? 'Fresh natural harvest from the farm.'
                                  : product.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(product.formattedPrice,
                                style: const TextStyle(
                                  color: FarmColors.green,
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

class FarmNotificationButton extends StatelessWidget {
  final double size;
  final bool showBadge;

  const FarmNotificationButton({
    super.key,
    this.size = 38,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: showBadge ? fetchUnreadNotificationCount() : null,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: FarmColors.line),
            boxShadow: [
              BoxShadow(
                color: FarmColors.shadow.withOpacity(0.07),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: 'Notifications',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: FarmColors.deepGreen,
                    size: 20,
                  ),
                ),
              ),
              if (showBadge && count > 0)
                Positioned(
                  right: -1,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: FarmColors.danger,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 18),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int refreshKey = 0;
  String selectedFilter = 'all';
  bool markingRead = false;

  Future<void> markReadAndRefresh() async {
    if (markingRead) return;
    setState(() => markingRead = true);
    try {
      await markNotificationsRead();
      FarmDataCache.notifications = null;
      if (mounted) setState(() => refreshKey++);
    } finally {
      if (mounted) setState(() => markingRead = false);
    }
  }

  Future<void> refreshNotifications() async {
    FarmDataCache.notifications = null;
    if (mounted) setState(() => refreshKey++);
  }

  bool _matchesFilter(FarmNotification notice) {
    switch (selectedFilter) {
      case 'unread':
        return !notice.isRead;
      case 'orders':
        return notice.hasOrderLink ||
            notice.type == 'order' ||
            notice.type == 'payment' ||
            notice.type == 'delivery';
      case 'support':
        return notice.type == 'support' || notice.type == 'review';
      case 'stock':
        return notice.type == 'stock' || notice.type == 'product_ready';
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: const Text('Updates'),
        backgroundColor: FarmColors.background,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: refreshNotifications,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: FarmPage(
        child: FutureBuilder<List<FarmNotification>>(
          key: ValueKey(refreshKey),
          future: fetchFarmNotifications(forceRefresh: refreshKey > 0),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const SkeletonList(count: 3, height: 104);
            }

            final notifications = snapshot.data ?? const <FarmNotification>[];
            final unreadCount =
                notifications.where((notice) => !notice.isRead).length;
            final orderCount = notifications
                .where((notice) =>
                    notice.hasOrderLink ||
                    notice.type == 'order' ||
                    notice.type == 'payment' ||
                    notice.type == 'delivery')
                .length;
            final supportCount = notifications
                .where((notice) =>
                    notice.type == 'support' || notice.type == 'review')
                .length;
            final stockCount = notifications
                .where((notice) =>
                    notice.type == 'stock' || notice.type == 'product_ready')
                .length;

            final filtered = notifications.where(_matchesFilter).toList()
              ..sort((a, b) {
                if (a.isRead != b.isRead) return a.isRead ? 1 : -1;
                final aDate =
                    a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                final bDate =
                    b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                return bDate.compareTo(aDate);
              });

            return RefreshIndicator(
              onRefresh: refreshNotifications,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
                children: [
                  NotificationCenterHero(
                    unreadCount: unreadCount,
                    totalCount: notifications.length,
                    markingRead: markingRead,
                    onMarkRead: unreadCount == 0 ? null : markReadAndRefresh,
                  ),
                  const SizedBox(height: 16),
                  NotificationFilterBar(
                    selected: selectedFilter,
                    unreadCount: unreadCount,
                    orderCount: orderCount,
                    supportCount: supportCount,
                    stockCount: stockCount,
                    onSelected: (value) =>
                        setState(() => selectedFilter = value),
                  ),
                  const SizedBox(height: 16),
                  if (notifications.isEmpty)
                    const FarmEmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'No updates yet',
                      message:
                          'Order updates, farm replies, and back-in-stock alerts will appear here.',
                    )
                  else if (filtered.isEmpty)
                    FarmEmptyState(
                      icon: Icons.filter_alt_off_rounded,
                      title: 'Nothing in this view',
                      message:
                          'Try All updates to see everything from the farm.',
                      actionLabel: 'Show all',
                      actionIcon: Icons.notifications_active_outlined,
                      onAction: () => setState(() => selectedFilter = 'all'),
                    )
                  else
                    ...filtered.map(
                      (notice) => FarmNotificationTile(
                        notice: notice,
                        onTap: notice.hasOrderLink
                            ? () async {
                                final matchedOrderId =
                                    await findOrderIdForNotification(notice);

                                if (!context.mounted) return;

                                if (matchedOrderId == null ||
                                    matchedOrderId.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Order could not be found. Pull down to refresh and try again.'),
                                    ),
                                  );
                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OrderDetailsScreen(
                                      orderId: matchedOrderId.trim(),
                                    ),
                                  ),
                                );
                              }
                            : null,
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

class NotificationCenterHero extends StatelessWidget {
  final int unreadCount;
  final int totalCount;
  final bool markingRead;
  final VoidCallback? onMarkRead;

  const NotificationCenterHero({
    super.key,
    required this.unreadCount,
    required this.totalCount,
    required this.markingRead,
    this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF173526),
            Color(0xFF2F6B45),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: FarmColors.shadow.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.22)),
            ),
            child: Icon(
              hasUnread
                  ? Icons.notifications_active_outlined
                  : Icons.mark_email_read_outlined,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasUnread
                      ? '$unreadCount unread update${unreadCount == 1 ? '' : 's'}'
                      : 'All caught up',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalCount == 0
                      ? 'Your farm updates will appear here.'
                      : 'Orders, support replies, stock alerts, and farm messages in one place.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (onMarkRead != null) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: markingRead ? null : onMarkRead,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                    ),
                    icon: Icon(
                      markingRead
                          ? Icons.hourglass_top_rounded
                          : Icons.done_all_rounded,
                      size: 18,
                    ),
                    label: Text(markingRead ? 'Updating...' : 'Mark all read'),
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

class NotificationFilterBar extends StatelessWidget {
  final String selected;
  final int unreadCount;
  final int orderCount;
  final int supportCount;
  final int stockCount;
  final ValueChanged<String> onSelected;

  const NotificationFilterBar({
    super.key,
    required this.selected,
    required this.unreadCount,
    required this.orderCount,
    required this.supportCount,
    required this.stockCount,
    required this.onSelected,
  });

  Widget _chip({
    required String value,
    required String label,
    required int count,
    required IconData icon,
  }) {
    final active = selected == value;
    final display = count > 0 ? '$label $count' : label;

    return ChoiceChip(
      selected: active,
      onSelected: (_) => onSelected(value),
      avatar: Icon(
        icon,
        size: 16,
        color: active ? Colors.white : FarmColors.green,
      ),
      label: Text(display),
      labelStyle: TextStyle(
        color: active ? Colors.white : FarmColors.deepGreen,
        fontWeight: FontWeight.w900,
        fontSize: 12.2,
      ),
      selectedColor: FarmColors.green,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: active ? FarmColors.green : FarmColors.line,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _chip(
            value: 'all',
            label: 'All',
            count: 0,
            icon: Icons.all_inbox_rounded,
          ),
          const SizedBox(width: 8),
          _chip(
            value: 'unread',
            label: 'Unread',
            count: unreadCount,
            icon: Icons.markunread_outlined,
          ),
          const SizedBox(width: 8),
          _chip(
            value: 'orders',
            label: 'Orders',
            count: orderCount,
            icon: Icons.receipt_long_outlined,
          ),
          const SizedBox(width: 8),
          _chip(
            value: 'stock',
            label: 'Stock',
            count: stockCount,
            icon: Icons.inventory_2_outlined,
          ),
          const SizedBox(width: 8),
          _chip(
            value: 'support',
            label: 'Support',
            count: supportCount,
            icon: Icons.support_agent_outlined,
          ),
        ],
      ),
    );
  }
}

class FarmNotificationTile extends StatelessWidget {
  final FarmNotification notice;
  final VoidCallback? onTap;

  const FarmNotificationTile({
    super.key,
    required this.notice,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = farmNotificationAccent(notice);
    final unread = !notice.isRead;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: FarmCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        color: unread ? FarmColors.primarySoft.withOpacity(0.72) : Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withOpacity(0.22)),
              ),
              child: Icon(
                notice.icon,
                color: accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notice.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FarmColors.deepGreen,
                            fontSize: 15.8,
                            height: 1.12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          height: 10,
                          width: 10,
                          margin: const EdgeInsets.only(left: 8, top: 4),
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (notice.hasOrderLink)
                        Container(
                          height: 28,
                          width: 28,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                            border: Border.all(color: FarmColors.line),
                          ),
                          child: const Icon(
                            Icons.chevron_right_rounded,
                            color: FarmColors.green,
                            size: 21,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notice.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 12.8,
                      height: 1.28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          farmNotificationTypeLabel(notice),
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(unread ? 0.72 : 0.0),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: FarmColors.line),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: FarmColors.mutedText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              notice.timeLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                color: FarmColors.mutedText,
                                fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final subjectController = TextEditingController();
  final messageController = TextEditingController();
  bool sending = false;
  int refreshKey = 0;

  @override
  void dispose() {
    subjectController.dispose();
    messageController.dispose();
    super.dispose();
  }

  void useQuickSubject(String subject) {
    subjectController.text = subject;
    if (messageController.text.trim().isEmpty) {
      messageController.text = '';
    }
  }

  Future<void> sendTicket() async {
    final subject = subjectController.text.trim();
    final message = messageController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a subject and message.')),
      );
      return;
    }

    setState(() => sending = true);
    try {
      await createSupportTicket(subject: subject, message: message);
      subjectController.clear();
      messageController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support message sent to the farm.')),
        );
        setState(() => refreshKey++);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Could not send support message: ${friendlyAppError(error)}')),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> refreshTickets() async {
    if (mounted) setState(() => refreshKey++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Support'),
        backgroundColor: FarmColors.background,
      ),
      body: FarmPage(
        child: RefreshIndicator(
          onRefresh: refreshTickets,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            children: [
              const SupportHeroCard(),
              const SizedBox(height: 16),
              FarmCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Send a message',
                      style: TextStyle(
                        color: FarmColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Choose a topic or write your own. The farm team will reply here.',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SupportQuickChip(
                          label: 'Order question',
                          onTap: () => useQuickSubject('Order question'),
                        ),
                        SupportQuickChip(
                          label: 'Delivery help',
                          onTap: () => useQuickSubject('Delivery help'),
                        ),
                        SupportQuickChip(
                          label: 'Product request',
                          onTap: () => useQuickSubject('Product request'),
                        ),
                        SupportQuickChip(
                          label: 'Payment help',
                          onTap: () => useQuickSubject('Payment help'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: subjectController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        prefixIcon: Icon(Icons.subject_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: messageController,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        hintText: 'Tell us what you need help with...',
                        prefixIcon: Icon(Icons.message_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    PrimaryFarmButton(
                      label: sending ? 'Sending...' : 'Send Message',
                      icon: Icons.send_rounded,
                      onPressed: sending ? null : sendTicket,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionHeader(
                title: 'Support history',
                subtitle: 'Your messages and farm replies',
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<SupportTicket>>(
                key: ValueKey(refreshKey),
                future: fetchMySupportTickets(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const SkeletonList(count: 2, height: 100);
                  }
                  final tickets = snapshot.data ?? [];
                  if (tickets.isEmpty) {
                    return const FarmEmptyState(
                      icon: Icons.support_agent_outlined,
                      title: 'No support messages yet',
                      message:
                          'When you message the farm, your conversation history will appear here.',
                      compact: true,
                    );
                  }
                  return Column(
                    children: tickets
                        .map((ticket) => SupportTicketCard(ticket: ticket))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SupportHeroCard extends StatelessWidget {
  const SupportHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: FarmColors.card,
        border: Border.all(color: FarmColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: FarmColors.primarySoft,
              shape: BoxShape.circle,
              border: Border.all(color: FarmColors.green.withOpacity(0.16)),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: FarmColors.green,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Farm support',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ask about orders, delivery, products, or weekly boxes. Replies stay saved here.',
                  style: TextStyle(
                    color: FarmColors.mutedText,
                    height: 1.28,
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

class SupportQuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const SupportQuickChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      label: Text(label),
      avatar: const Icon(Icons.add_rounded, size: 16),
      labelStyle: const TextStyle(
        color: FarmColors.deepGreen,
        fontWeight: FontWeight.w900,
        fontSize: 12,
      ),
      backgroundColor: FarmColors.primarySoft,
      side: BorderSide(color: FarmColors.green.withOpacity(0.12)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class SupportTicketCard extends StatelessWidget {
  final SupportTicket ticket;

  const SupportTicketCard({
    super.key,
    required this.ticket,
  });

  Color get statusColor {
    final status = ticket.status.trim().toLowerCase();
    if (status == 'closed' || status == 'resolved') return FarmColors.success;
    if (status == 'pending') return FarmColors.warning;
    return FarmColors.green;
  }

  @override
  Widget build(BuildContext context) {
    final hasReply = (ticket.adminReply ?? '').trim().isNotEmpty;

    return FarmCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  ticket.subject,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.8,
                    height: 1.16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  ticket.formattedStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ticket.message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FarmColors.mutedText,
              height: 1.32,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.confirmation_number_outlined,
                size: 14,
                color: FarmColors.mutedText,
              ),
              const SizedBox(width: 5),
              Text(
                '#${ticket.shortId}',
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: FarmColors.mutedText,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  formatCustomerDateTime(ticket.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (hasReply) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FarmColors.primarySoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: FarmColors.green.withOpacity(0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 16,
                        color: FarmColors.green,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Farm reply',
                        style: TextStyle(
                          color: FarmColors.green,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ticket.adminReply!.trim(),
                    style: const TextStyle(
                      color: FarmColors.deepGreen,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
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

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  Product? selectedProduct;
  int rating = 5;
  final commentController = TextEditingController();
  bool sending = false;
  int refreshKey = 0;

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  void usePrompt(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final current = commentController.text.trim();
    commentController.text = current.isEmpty ? clean : '$current $clean';
    commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: commentController.text.length),
    );
  }

  Future<void> submitReview() async {
    final product = selectedProduct;
    final comment = commentController.text.trim();

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose the product you want to review.')),
      );
      return;
    }

    if (comment.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a little more detail so your review is useful.'),
        ),
      );
      return;
    }

    setState(() => sending = true);
    try {
      await createProductReview(
        productId: product.id,
        productName: product.name,
        rating: rating,
        comment: comment,
      );
      commentController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks — your review was shared.')),
        );
        setState(() {
          selectedProduct = null;
          rating = 5;
          refreshKey++;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Could not save review: ${friendlyAppError(error)}')),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Product? selectedProductFrom(List<Product> products) {
    final id = selectedProduct?.id.trim() ?? '';
    if (id.isEmpty) return null;
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Reviews'),
        backgroundColor: FarmColors.background,
      ),
      body: FarmPage(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() => refreshKey++);
            await fetchProductReviews();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            children: [
              const ReviewHeroCard(),
              const SizedBox(height: 16),
              FarmCard(
                padding: const EdgeInsets.all(18),
                child: FutureBuilder<List<Product>>(
                  future: fetchProducts(),
                  builder: (context, snapshot) {
                    final products = (snapshot.data ?? const <Product>[])
                        .where((product) => product.isCustomerVisible)
                        .toList()
                      ..sort((a, b) => a.name.compareTo(b.name));
                    final selected = selectedProductFrom(products);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Share your experience',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Help other shoppers choose fresh picks with confidence.',
                          style: TextStyle(
                            color: FarmColors.mutedText,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Product>(
                          value: selected,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Product you tried',
                            prefixIcon: Icon(Icons.shopping_basket_outlined),
                          ),
                          items: products.map((product) {
                            return DropdownMenuItem<Product>(
                              value: product,
                              child: Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (Product? product) {
                            if (product == null) return;
                            setState(() => selectedProduct = product);
                          },
                        ),
                        const SizedBox(height: 16),
                        ReviewRatingSelector(
                          value: rating,
                          onChanged: (value) => setState(() => rating = value),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ReviewPromptChip(
                              label: 'Fresh quality',
                              onTap: () =>
                                  usePrompt('The freshness was great.'),
                            ),
                            ReviewPromptChip(
                              label: 'Easy pickup',
                              onTap: () =>
                                  usePrompt('Pickup was easy and smooth.'),
                            ),
                            ReviewPromptChip(
                              label: 'Good value',
                              onTap: () =>
                                  usePrompt('Good value for the quality.'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: commentController,
                          maxLines: 4,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            labelText: 'What should other customers know?',
                            hintText:
                                'Example: Fresh, well packed, and perfect for dinner.',
                            prefixIcon: Icon(Icons.rate_review_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryFarmButton(
                          label: sending ? 'Sharing review...' : 'Share Review',
                          icon: Icons.send_rounded,
                          onPressed: sending ? null : submitReview,
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: SectionTitle('Customer Reviews'),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final reviews = await fetchProductReviews();
                      final summary = reviews.isEmpty
                          ? 'No customer reviews yet.'
                          : '${reviews.length} reviews • ${(reviews.fold<double>(0, (sum, review) => sum + review.rating) / reviews.length).toStringAsFixed(1)} average rating';
                      await Clipboard.setData(ClipboardData(text: summary));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Review summary copied.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_rounded, size: 17),
                    label: const Text('Copy'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ReviewsList(refreshKey: refreshKey),
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewHeroCard extends StatelessWidget {
  const ReviewHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductReview>>(
      future: fetchProductReviews(),
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? const <ProductReview>[];
        final count = reviews.length;
        final average = count == 0
            ? 0.0
            : reviews.fold<double>(0, (sum, review) => sum + review.rating) /
                count;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF173526), Color(0xFF315B43)],
            ),
            boxShadow: [
              BoxShadow(
                color: FarmColors.shadow.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                    ),
                    child: const Icon(
                      Icons.reviews_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Harvest Reviews',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Real feedback helps the market improve.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.78),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ReviewHeroPill(
                    icon: Icons.star_rounded,
                    label: count == 0
                        ? 'No ratings yet'
                        : '${average.toStringAsFixed(1)} average',
                  ),
                  ReviewHeroPill(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '$count reviews',
                  ),
                  const ReviewHeroPill(
                    icon: Icons.verified_user_outlined,
                    label: 'Customer feedback',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class ReviewHeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const ReviewHeroPill({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewRatingSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const ReviewRatingSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating',
          style: TextStyle(
            color: FarmColors.mutedText,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final starValue = index + 1;
            final active = starValue <= value;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onChanged(starValue),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: active ? FarmColors.accentSoft : FarmColors.cardSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active
                          ? FarmColors.accent.withOpacity(0.42)
                          : FarmColors.line,
                    ),
                  ),
                  child: Icon(
                    active ? Icons.star_rounded : Icons.star_border_rounded,
                    color: active ? FarmColors.accent : FarmColors.mutedText,
                    size: 24,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class ReviewPromptChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const ReviewPromptChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: const Icon(Icons.add_rounded, size: 16),
      onPressed: onTap,
      backgroundColor: FarmColors.primarySoft,
      side: BorderSide(color: FarmColors.green.withOpacity(0.16)),
      labelStyle: const TextStyle(
        color: FarmColors.green,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class ReviewsList extends StatelessWidget {
  final int refreshKey;
  const ReviewsList({super.key, required this.refreshKey});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductReview>>(
      key: ValueKey('reviews-$refreshKey'),
      future: fetchProductReviews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SkeletonList(count: 3, height: 116);
        }
        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) {
          return const FarmEmptyState(
            icon: Icons.reviews_outlined,
            title: 'No reviews yet',
            message:
                'After customers try products, their feedback will appear here.',
            compact: true,
          );
        }
        return Column(
          children: reviews
              .take(20)
              .map((review) => ReviewCard(review: review))
              .toList(),
        );
      },
    );
  }
}

class ReviewCard extends StatelessWidget {
  final ProductReview review;

  const ReviewCard({super.key, required this.review});

  String get displayName => safeReviewDisplayName(
        reviewName: review.customerName,
        email: review.email,
      );

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: const BoxDecoration(
                  color: FarmColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: FarmColors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      review.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: FarmColors.accentSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: FarmColors.accent, size: 16),
                    const SizedBox(width: 3),
                    Text(
                      review.rating.toString(),
                      style: const TextStyle(
                        color: FarmColors.warning,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: const TextStyle(
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.verified_outlined,
                  color: FarmColors.green.withOpacity(0.78), size: 16),
              const SizedBox(width: 5),
              Text(
                'Shared by a customer',
                style: TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReadySoonHomeSection extends StatefulWidget {
  final void Function(Product product) onViewed;

  const ReadySoonHomeSection({super.key, required this.onViewed});

  @override
  State<ReadySoonHomeSection> createState() => _ReadySoonHomeSectionState();
}

class _ReadySoonHomeSectionState extends State<ReadySoonHomeSection> {
  late Future<List<Product>> readySoonFuture;

  @override
  void initState() {
    super.initState();
    readySoonFuture = fetchReadySoonProducts();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: readySoonFuture,
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        if (products.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            ReadySoonRail(
              products: products,
              onViewed: widget.onViewed,
            ),
          ],
        );
      },
    );
  }
}

class WeeklyBoxBuilderScreen extends StatefulWidget {
  const WeeklyBoxBuilderScreen({super.key});

  @override
  State<WeeklyBoxBuilderScreen> createState() => _WeeklyBoxBuilderScreenState();
}

class _WeeklyBoxBuilderScreenState extends State<WeeklyBoxBuilderScreen> {
  late Future<List<Product>> productsFuture;
  final Set<String> selectedIds = <String>{};
  int intervalDays = 7;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    productsFuture = fetchProducts(forceRefresh: true);
  }

  void toggleProduct(Product product) {
    if (!canAddToWeeklyBox(product)) return;
    final id = product.id.trim();
    if (id.isEmpty) return;

    setState(() {
      if (!selectedIds.add(id)) {
        selectedIds.remove(id);
      }
    });
  }

  Future<void> saveBox(List<Product> products) async {
    if (saving) return;

    final selectedProducts = products
        .where((product) => selectedIds.contains(product.id))
        .where(canAddToWeeklyBox)
        .toList();

    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose at least one available item.')),
      );
      return;
    }

    setState(() => saving = true);
    try {
      final count = await saveWeeklyBoxPlanProducts(
        products: selectedProducts,
        intervalDays: intervalDays,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Weekly Box saved with $count item${count == 1 ? '' : 's'}.')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(friendlyAppError(error))),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Build Weekly Box'),
        backgroundColor: FarmColors.background,
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<Product>>(
          future: productsFuture,
          builder: (context, snapshot) {
            final products = (snapshot.data ?? const <Product>[])
                .where(canAddToWeeklyBox)
                .toList();

            if (snapshot.connectionState == ConnectionState.waiting) {
              return SkeletonList(count: 4, height: 132);
            }

            if (products.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 140),
                children: const [
                  FarmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 42, color: FarmColors.green),
                        SizedBox(height: 12),
                        Text(
                          'No items ready for a Weekly Box',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Add available products in Admin first, then customers can build their weekly repeat box here.',
                          style: TextStyle(
                            color: FarmColors.mutedText,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    children: [
                      FarmCard(
                        color: FarmColors.successSoft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 44,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_outlined,
                                    color: FarmColors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Make your weekly box',
                                        style: TextStyle(
                                          color: FarmColors.ink,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Pick the items you want repeated. You still confirm before each order.',
                                        style: TextStyle(
                                          color: FarmColors.mutedText,
                                          fontWeight: FontWeight.w700,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<int>(
                              value: intervalDays,
                              decoration: const InputDecoration(
                                labelText: 'Repeat reminder',
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 7, child: Text('Every week')),
                                DropdownMenuItem(
                                    value: 14, child: Text('Every 2 weeks')),
                                DropdownMenuItem(
                                    value: 30, child: Text('Every month')),
                              ],
                              onChanged: saving
                                  ? null
                                  : (value) =>
                                      setState(() => intervalDays = value ?? 7),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Choose items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${products.length} available items can be added to your box.',
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.74,
                        ),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final selected = selectedIds.contains(product.id);
                          return _WeeklyBoxProductTile(
                            product: product,
                            selected: selected,
                            onTap: () => toggleProduct(product),
                          );
                        },
                      ),
                      const SizedBox(height: 110),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: FutureBuilder<List<Product>>(
          future: productsFuture,
          builder: (context, snapshot) {
            final products = snapshot.data ?? const <Product>[];
            final selectedProducts = products
                .where((product) => selectedIds.contains(product.id))
                .where(canAddToWeeklyBox)
                .toList();
            final selectedTotal = selectedProducts.fold<double>(
              0,
              (sum, product) => sum + product.effectivePrice,
            );

            return Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              decoration: const BoxDecoration(
                color: FarmColors.card,
                border: Border(top: BorderSide(color: FarmColors.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${selectedProducts.length} selected',
                          style: const TextStyle(
                            color: FarmColors.mutedText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          formatJmd(selectedTotal),
                          style: const TextStyle(
                            color: FarmColors.green,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: saving || selectedProducts.isEmpty
                        ? null
                        : () => saveBox(products),
                    icon: saving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(saving ? 'Saving' : 'Save Box'),
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

class _WeeklyBoxProductTile extends StatelessWidget {
  final Product product;
  final bool selected;
  final VoidCallback onTap;

  const _WeeklyBoxProductTile({
    required this.product,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final discount = weeklyBoxDiscountForProduct(product);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? FarmColors.successSoft : FarmColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? FarmColors.green.withOpacity(0.55)
                  : FarmColors.line,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: FarmColors.shadow.withOpacity(selected ? 0.10 : 0.045),
                blurRadius: selected ? 18 : 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 28,
                    width: 28,
                    decoration: BoxDecoration(
                      color:
                          selected ? FarmColors.green : FarmColors.lightGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      selected ? Icons.check_rounded : Icons.add_rounded,
                      size: 18,
                      color: selected ? Colors.white : FarmColors.green,
                    ),
                  ),
                  const Spacer(),
                  if (discount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: FarmColors.accentSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${discount.toStringAsFixed(0)}% save',
                        style: const TextStyle(
                          color: FarmColors.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Center(child: ProductVisual(product: product, size: 76)),
              const SizedBox(height: 8),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.formattedEffectivePrice,
                style: const TextStyle(
                  color: FarmColors.green,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.unit?.trim().isNotEmpty == true
                    ? product.unit!.trim()
                    : product.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 11,
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

class CustomerSubscriptionsScreen extends StatefulWidget {
  const CustomerSubscriptionsScreen({super.key});

  @override
  State<CustomerSubscriptionsScreen> createState() =>
      _CustomerSubscriptionsScreenState();
}

class _CustomerSubscriptionsScreenState
    extends State<CustomerSubscriptionsScreen> {
  late Future<List<CustomerProductSubscription>> plansFuture;

  @override
  void initState() {
    super.initState();
    plansFuture = fetchCustomerProductSubscriptions();
  }

  Future<void> refreshPlans() async {
    final future = fetchCustomerProductSubscriptions();
    if (mounted) {
      setState(() {
        plansFuture = future;
      });
    }
    await future;
  }

  Future<void> openWeeklyBoxBuilder() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const WeeklyBoxBuilderScreen()),
    );

    if (changed == true) {
      await refreshPlans();
    }
  }

  Widget buildWeeklyBoxBuilderCard({required bool hasPlans}) {
    return FarmCard(
      color: FarmColors.successSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: FarmColors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPlans ? 'Update your Weekly Box' : 'Build your Weekly Box',
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose multiple fresh items and get a reminder before each repeat order.',
                  style: TextStyle(
                    color: FarmColors.mutedText,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: openWeeklyBoxBuilder,
                  icon: const Icon(Icons.add_shopping_cart_outlined),
                  label:
                      Text(hasPlans ? 'Edit Weekly Box' : 'Start Weekly Box'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> updateStatus(
    CustomerProductSubscription plan,
    String status,
  ) async {
    try {
      await updateCustomerSubscriptionStatus(
          subscription: plan, status: status);
      await refreshPlans();
      if (!mounted) return;
      final label = status == 'cancelled'
          ? 'cancelled'
          : status == 'paused'
              ? 'paused'
              : 'resumed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Weekly Box item $label.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(friendlyAppError(error))),
      );
    }
  }

  Future<void> changeSchedule(CustomerProductSubscription plan) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: FarmColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Change repeat schedule',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.calendar_view_week_outlined),
                  title: const Text('Every week'),
                  onTap: () => Navigator.pop(context, 7),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_view_month_outlined),
                  title: const Text('Every 2 weeks'),
                  onTap: () => Navigator.pop(context, 14),
                ),
                ListTile(
                  leading: const Icon(Icons.event_repeat_outlined),
                  title: const Text('Every month'),
                  onTap: () => Navigator.pop(context, 30),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    try {
      await updateCustomerSubscriptionSchedule(
        subscription: plan,
        intervalDays: selected,
      );
      await refreshPlans();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Schedule changed to ${repeatIntervalLabel(selected).toLowerCase()}.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(friendlyAppError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Weekly Box'),
        backgroundColor: FarmColors.background,
        actions: [
          IconButton(
            tooltip: 'Build Weekly Box',
            onPressed: openWeeklyBoxBuilder,
            icon: const Icon(Icons.add_box_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: refreshPlans,
          child: FutureBuilder<List<CustomerProductSubscription>>(
            future: plansFuture,
            builder: (context, snapshot) {
              final plans = snapshot.data ?? [];

              if (snapshot.connectionState == ConnectionState.waiting) {
                return SkeletonList(count: 3, height: 116);
              }

              if (plans.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
                  children: [
                    buildWeeklyBoxBuilderCard(hasPlans: false),
                    const SizedBox(height: 12),
                    const FarmCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.event_repeat_outlined,
                              size: 42, color: FarmColors.green),
                          SizedBox(height: 12),
                          Text(
                            'No weekly items yet',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Pick the fresh items you want in your weekly box. You stay in control and confirm before each repeat order.',
                            style: TextStyle(
                              color: FarmColors.mutedText,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
                itemCount: plans.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return buildWeeklyBoxBuilderCard(hasPlans: true);
                  }
                  final plan = plans[index - 1];
                  final isActive = plan.isActive;
                  final statusColor =
                      isActive ? FarmColors.success : FarmColors.warning;

                  return FarmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 44,
                              width: 44,
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                isActive
                                    ? Icons.event_available_outlined
                                    : Icons.pause_circle_outline,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan.productName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${plan.repeatLabel} • ${plan.savingsLabel}',
                                    style: const TextStyle(
                                      color: FarmColors.mutedText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text(isActive
                                  ? 'Active'
                                  : friendlyLabel(plan.status)),
                              backgroundColor: statusColor.withOpacity(0.10),
                              labelStyle: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: FarmColors.cardSoft,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: FarmColors.line),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _PlanMetric(
                                  label: 'Next reminder',
                                  value: plan.nextOrderLabel,
                                ),
                              ),
                              Expanded(
                                child: _PlanMetric(
                                  label: 'Repeat',
                                  value: plan.repeatLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => changeSchedule(plan),
                              icon: const Icon(Icons.tune_outlined),
                              label: const Text('Change'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => updateStatus(
                                plan,
                                isActive ? 'paused' : 'active',
                              ),
                              icon: Icon(isActive
                                  ? Icons.pause_circle_outline
                                  : Icons.play_circle_outline),
                              label: Text(isActive ? 'Pause' : 'Resume'),
                            ),
                            TextButton.icon(
                              onPressed: () => updateStatus(plan, 'cancelled'),
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final void Function(Product product)? onAddProduct;
  final void Function(Product product)? onViewed;
  final VoidCallback? onViewMyBox;
  final VoidCallback? onCheckout;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    this.onAddProduct,
    this.onViewed,
    this.onViewMyBox,
    this.onCheckout,
  });

  String get description {
    final text = (product.description ?? '').trim();
    return text.isEmpty ? 'Fresh natural harvest from the farm.' : text;
  }

  String get farmLine {
    final parts = <String>[
      if ((product.farmName ?? '').trim().isNotEmpty) product.farmName!.trim(),
      if ((product.parish ?? '').trim().isNotEmpty) product.parish!.trim(),
    ];

    return parts.isEmpty
        ? 'The Harvest Place Ja partner farm'
        : parts.join(' • ');
  }

  Widget badge({
    required String label,
    IconData? icon,
    Color color = FarmColors.green,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showAddedToMyBoxActions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: FarmColors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: FarmColors.shadow.withOpacity(0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: FarmColors.lightGreen,
                      foregroundColor: FarmColors.green,
                      child: Icon(Icons.check_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Added to My Box',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${product.name} is ready in your farm box.',
                            style: const TextStyle(color: FarmColors.mutedText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onCheckout == null
                        ? null
                        : () {
                            Navigator.pop(sheetContext);
                            onCheckout?.call();
                          },
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Checkout'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onViewMyBox == null
                        ? null
                        : () {
                            Navigator.pop(sheetContext);
                            onViewMyBox?.call();
                          },
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('View My Box'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Continue Shopping'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void handlePrimaryAdd(BuildContext context) {
    onAdd();
    showAddedToMyBoxActions(context);
  }

  @override
  Widget build(BuildContext context) {
    final inStock = product.canAddToCart;
    final unit = (product.unit ?? '').trim();
    final bottomSafePadding = MediaQuery.of(context).viewPadding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final detailImageHeight = screenWidth < 380 ? 228.0 : 260.0;

    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        backgroundColor: FarmColors.background,
        elevation: 0,
        title: Text(product.name),
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(18, 18, 18, 128 + bottomSafePadding),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Container(
                color: FarmColors.surface,
                padding: const EdgeInsets.all(14),
                child: Hero(
                  tag: 'product-${product.id}',
                  child: productImagePreviewFromUrl(
                    imageUrl: product.imageUrl,
                    height: detailImageHeight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FarmCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    farmLine,
                    style: const TextStyle(
                      color: FarmColors.green,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.42,
                      color: FarmColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      badge(
                        label: productFreshnessLabel(product),
                        icon: Icons.speed_outlined,
                        color: productFreshnessColor(product),
                      ),
                      if (product.isOrganic)
                        badge(
                          label: 'Organic',
                          icon: Icons.eco_outlined,
                          color: FarmColors.green,
                        ),
                      badge(
                        label: product.originLabel,
                        icon: productOriginIcon(product),
                        color: productOriginColor(product),
                      ),
                      badge(
                        label: product.category,
                        icon: Icons.category_outlined,
                      ),
                      if (unit.isNotEmpty)
                        badge(
                          label: unit,
                          icon: Icons.straighten_outlined,
                        ),
                      if (product.isOutOfStock)
                        badge(
                          label: 'Out of stock',
                          icon: Icons.block_outlined,
                          color: FarmColors.danger,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DiscountPriceText(product: product),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FreshnessScoreCard(product: product),
            const SizedBox(height: 14),
            ProductTraceStoryCard(product: product),
            if (product.isOutOfStock) ...[
              const SizedBox(height: 14),
              FarmCard(
                color: FarmColors.dangerSoft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.notifications_active_outlined,
                        color: FarmColors.danger),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Currently unavailable',
                            style: TextStyle(
                              color: FarmColors.danger,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'We’ll let you know when this item is back in stock.',
                            style: TextStyle(
                              color: FarmColors.danger,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (product.isLowStock) ...[
              const SizedBox(height: 14),
              FarmCard(
                color: FarmColors.warningSoft,
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_outlined,
                        color: FarmColors.warning),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '${product.lowStockLabel} — order soon while this batch lasts.',
                        style: const TextStyle(
                          color: FarmColors.warning,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (product.hasSubscribeSave) ...[
              const SizedBox(height: 14),
              SubscribeSaveButton(product: product),
            ],
            const SizedBox(height: 14),
            FrequentlyBoughtTogetherSection(
              product: product,
              onAddProduct: onAddProduct,
              onViewed: onViewed,
              onViewMyBox: onViewMyBox,
              onCheckout: onCheckout,
            ),
            const SizedBox(height: 14),
            RecommendedForYouDetailSection(
              currentProduct: product,
              onAddProduct: onAddProduct,
              onViewed: onViewed,
              onViewMyBox: onViewMyBox,
              onCheckout: onCheckout,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: FarmColors.shadow.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: quantity <= 0
              ? (inStock
                  ? PrimaryFarmButton(
                      label: 'Add to My Box',
                      busyLabel: 'Adding to My Box...',
                      icon: Icons.shopping_bag_outlined,
                      onPressed: () => handlePrimaryAdd(context),
                    )
                  : NotifyMeWhenReadyButton(product: product))
              : Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: FarmColors.lightGreen,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: IconButton(
                          onPressed: onRemove,
                          icon: const Icon(Icons.remove),
                          color: FarmColors.green,
                        ),
                      ),
                      Text(
                        '$quantity in My Box',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: FarmColors.green,
                        ),
                      ),
                      Expanded(
                        child: IconButton(
                          onPressed: inStock ? onAdd : null,
                          icon: const Icon(Icons.add),
                          color: FarmColors.green,
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

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  final double total;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.total,
  });

  String get shortOrderId {
    if (orderId.length <= 6) return orderId.toUpperCase();
    return orderId.substring(0, 6).toUpperCase();
  }

  Widget _receiptRow(String label, String value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: strong ? FarmColors.ink : FarmColors.mutedText,
                fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: strong ? FarmColors.green : FarmColors.ink,
                fontSize: strong ? 18 : 14,
                fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 34),
          children: [
            const SizedBox(height: 18),
            Center(
              child: Container(
                height: 118,
                width: 118,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [FarmColors.green, FarmColors.primaryDark],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: FarmColors.green.withOpacity(0.22),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 68,
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Order sent to the farm',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                height: 1.02,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'We received your order and will keep you updated as it moves through the harvest workflow.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FarmColors.mutedText,
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            FarmCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: FarmColors.lightGreen,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.receipt_long_outlined,
                          color: FarmColors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #$shortOrderId',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Receipt and tracking are available in Orders.',
                              style: TextStyle(
                                color: FarmColors.mutedText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _receiptRow('Status', 'Received'),
                  _receiptRow('Review', 'Farm review'),
                  const Divider(height: 22),
                  _receiptRow('Total', formatJmd(total), strong: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FarmColors.accentSoft.withOpacity(0.78),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: FarmColors.accent.withOpacity(0.18)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notifications_active_outlined,
                      color: FarmColors.warning),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tip: keep notifications on so you know when your order is ready for pickup or delivery.',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        height: 1.32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            PrimaryFarmButton(
              label: 'View My Orders',
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Continue shopping'),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  final List<CartLine> cartLines;
  final double subtotal;
  final VoidCallback onOrderPlaced;
  final VoidCallback? onInventoryChanged;

  const CheckoutScreen({
    super.key,
    required this.cartLines,
    required this.subtotal,
    required this.onOrderPlaced,
    this.onInventoryChanged,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final notesController = TextEditingController();
  final bankReferenceController = TextEditingController();
  final couponController = TextEditingController();

  bool loading = false;
  bool applyingCoupon = false;
  String? appliedCouponCode;
  double discountAmount = 0;
  CustomerProfile? savedProfile;
  String fulfillmentType = 'pickup';
  String paymentMethod = 'cash_on_pickup';
  String deliveryZone = 'Kingston / St. Andrew';
  DateTime? scheduledDate;
  TimeOfDay? scheduledTime;

  static const double homeDeliveryFee = 500.0;

  final List<String> deliveryZones = const [
    'Kingston / St. Andrew',
    'St. Catherine',
    'St. Elizabeth',
    'Manchester',
    'Clarendon',
    'Montego Bay / St. James',
    'Other Parish',
  ];

  double get deliveryFee =>
      fulfillmentType == 'delivery' ? homeDeliveryFee : 0.0;

  bool _isPrepaidPaymentMethod(String method) {
    return method == 'bank_transfer';
  }

  bool _isAllowedPaymentForCurrentFulfillment(String method) {
    if (fulfillmentType == 'delivery') return method == 'bank_transfer';
    return method == 'cash_on_pickup' || method == 'bank_transfer';
  }

  String get effectivePaymentMethod {
    if (_isAllowedPaymentForCurrentFulfillment(paymentMethod)) {
      return paymentMethod;
    }
    return fulfillmentType == 'delivery' ? 'bank_transfer' : 'cash_on_pickup';
  }

  void _syncPaymentMethodForFulfillment(String fulfillment) {
    fulfillmentType = fulfillment;
    if (fulfillment == 'delivery' && !_isPrepaidPaymentMethod(paymentMethod)) {
      paymentMethod = 'bank_transfer';
    }
  }

  List<DropdownMenuItem<String>> _paymentMethodItems() {
    return <DropdownMenuItem<String>>[
      if (fulfillmentType != 'delivery')
        const DropdownMenuItem(
          value: 'cash_on_pickup',
          child: Text(
            'Pay when you collect',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      const DropdownMenuItem(
        value: 'bank_transfer',
        child: Text(
          'Bank Transfer',
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ];
  }

  double get checkoutTotal {
    final total = widget.subtotal + deliveryFee - discountAmount;
    return total < 0 ? 0 : total;
  }

  String get scheduledDateText {
    final date = scheduledDate;
    if (date == null) return 'Choose date';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String get scheduledTimeText {
    if (scheduledTime == null) return 'Choose time';
    final hour = scheduledTime!.hour.toString().padLeft(2, '0');
    final minute = scheduledTime!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void initState() {
    super.initState();
    final user = supabase.auth.currentUser;
    nameController.text = user?.userMetadata?['full_name']?.toString() ?? '';
    final now = DateTime.now();
    final daysUntilFriday = (DateTime.friday - now.weekday + 7) % 7;
    final nextFriday = now.add(
      Duration(days: daysUntilFriday == 0 ? 7 : daysUntilFriday),
    );

    scheduledDate = DateTime(
      nextFriday.year,
      nextFriday.month,
      nextFriday.day,
    );

    scheduledTime = const TimeOfDay(hour: 16, minute: 0);
    loadSavedCustomerProfile();
  }

  Future<void> loadSavedCustomerProfile() async {
    final profile = await fetchCurrentCustomerProfile();
    if (!mounted || profile == null) return;
    setState(() {
      savedProfile = profile;
      if (nameController.text.trim().isEmpty) {
        nameController.text = profile.fullName;
      }
      phoneController.text = profile.phone;
      addressController.text = profile.address;
    });
  }

  void useSavedDeliveryAddress() {
    final profile = savedProfile;
    if (profile == null) return;
    setState(() {
      if (profile.fullName.isNotEmpty) nameController.text = profile.fullName;
      if (profile.phone.isNotEmpty) phoneController.text = profile.phone;
      if (profile.address.isNotEmpty) addressController.text = profile.address;
      _syncPaymentMethodForFulfillment('delivery');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved delivery address selected.')),
    );
  }

  Future<void> applyCoupon() async {
    final code = couponController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a promo code.')),
      );
      return;
    }

    setState(() => applyingCoupon = true);
    try {
      final validation = await validateCouponForCheckout(
        code: code,
        orderTotal: widget.subtotal,
      );

      if (!validation.valid || validation.discountAmount <= 0) {
        setState(() {
          appliedCouponCode = null;
          discountAmount = 0;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              validation.message.isEmpty
                  ? 'Promo code could not be applied.'
                  : validation.message,
            ),
          ),
        );
        return;
      }

      setState(() {
        appliedCouponCode = validation.code ?? code;
        discountAmount = validation.discountAmount;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Promo applied: ${validation.label}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Coupon check failed: ${friendlyAppError(error)}')),
      );
    } finally {
      if (mounted) setState(() => applyingCoupon = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    notesController.dispose();
    bankReferenceController.dispose();
    couponController.dispose();
    super.dispose();
  }

  Future<void> placeOrder() async {
    // Prevent double taps from creating duplicate checkout attempts.
    if (loading) return;

    if (!isLoggedIn) {
      final allowed = await requireLoginForCheckout(context);
      if (!mounted || !allowed) return;
    }

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();
    final notes = notesController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter your name and phone number.')),
      );
      return;
    }

    if (fulfillmentType == 'delivery' && address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a delivery address.')),
      );
      return;
    }

    if (scheduledDate == null || scheduledTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please choose a pickup or delivery date and time.')),
      );
      return;
    }

    if (fulfillmentType == 'delivery' &&
        !_isPrepaidPaymentMethod(effectivePaymentMethod)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Home Delivery requires payment before delivery. Please choose Bank Transfer or switch to Farm Pickup.',
          ),
        ),
      );
      return;
    }

    if (effectivePaymentMethod == 'bank_transfer' &&
        bankReferenceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your bank transfer reference number.'),
        ),
      );
      return;
    }

    if (mounted) setState(() => loading = true);

    SecureCartQuote secureQuote;
    try {
      secureQuote = await fetchSecureCartQuote(widget.cartLines);
    } catch (error) {
      FarmDataCache.clearProducts();
      FarmDataCache.clearOrders();
      widget.onInventoryChanged?.call();
      if (mounted) setState(() => loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
      return;
    }

    try {
      final signedInUser = supabase.auth.currentUser;
      if (signedInUser == null) {
        throw Exception('Please sign in before placing an order.');
      }

      final secureSubtotal = secureQuote.subtotal;
      final requestedCouponCode = couponController.text.trim().isEmpty
          ? null
          : couponController.text.trim().toUpperCase();
      var trustedCouponCode = requestedCouponCode == null
          ? null
          : (appliedCouponCode ?? requestedCouponCode);
      var trustedDiscountAmount =
          requestedCouponCode == null ? 0.0 : discountAmount;
      var total = (secureSubtotal + deliveryFee - trustedDiscountAmount)
          .clamp(0, double.infinity)
          .toDouble();
      final selectedPaymentMethod = effectivePaymentMethod;
      final selectedPaymentStatus = 'unpaid';
      final bankReference = selectedPaymentMethod == 'bank_transfer'
          ? bankReferenceController.text.trim()
          : null;

      final customerPayload = <String, dynamic>{
        'full_name': name,
        'name': name,
        'phone': phone,
        'email': signedInUser.email,
        'address': fulfillmentType == 'delivery' ? address : null,
        'fulfillment_type': fulfillmentType,
        'delivery_address': fulfillmentType == 'delivery' ? address : null,
        'delivery_zone': fulfillmentType == 'delivery' ? deliveryZone : null,
        'scheduled_date': scheduledDateText,
        'scheduled_time': scheduledTimeText,
        'delivery_status':
            fulfillmentType == 'delivery' ? 'pending' : 'ready_for_pickup',
        'subtotal': secureSubtotal,
        'delivery_fee': deliveryFee,
        'discount_code': trustedCouponCode,
        'discount_amount': trustedDiscountAmount,
        'total': total,
        'payment_status': selectedPaymentStatus,
        'bank_reference': bankReference,
      };

      final rpcItems = secureQuote.lines.map((line) {
        return <String, dynamic>{
          'product_id': line.product.id,
          'quantity': line.quantity,
        };
      }).toList();

      final checkoutNotes = <String>[
        if (notes.isNotEmpty) notes,
        'Fulfillment: ${formatFulfillmentType(fulfillmentType)}',
        if (fulfillmentType == 'delivery') 'Delivery zone: $deliveryZone',
        if (fulfillmentType == 'delivery') 'Delivery address: $address',
        'Scheduled: $scheduledDateText $scheduledTimeText',
        'Subtotal: ${formatJmd(secureSubtotal)}',
        if (fulfillmentType == 'delivery')
          'Delivery fee: ${formatJmd(deliveryFee)}',
        if (trustedDiscountAmount > 0)
          'Discount: -${formatJmd(trustedDiscountAmount)}',
        selectedPaymentMethod == 'bank_transfer'
            ? 'Total to transfer: ${formatJmd(total)}'
            : 'Total to pay: ${formatJmd(total)}',
        if (bankReference != null && bankReference.isNotEmpty)
          'Bank reference: $bankReference',
        if (requestedCouponCode != null && requestedCouponCode.isNotEmpty)
          'Promo requested: $requestedCouponCode',
      ].join('\n');

      final checkoutRpc = requestedCouponCode == null
          ? 'secure_checkout'
          : 'secure_checkout_with_coupon';
      final checkoutParams = <String, dynamic>{
        'p_customer': customerPayload,
        'p_items': rpcItems,
        'p_payment_method': selectedPaymentMethod,
        'p_notes': checkoutNotes.isEmpty ? null : checkoutNotes,
      };

      if (requestedCouponCode != null) {
        checkoutParams['p_coupon_code'] = requestedCouponCode;
      }

      final checkoutResponse = await supabase.rpc(
        checkoutRpc,
        params: checkoutParams,
      );

      if (checkoutResponse is! Map) {
        throw Exception(
            'Checkout completed, but the server response was invalid.');
      }

      final checkoutResult = Map<String, dynamic>.from(checkoutResponse);
      final orderId = (checkoutResult['order_id'] ?? '').toString();
      if (orderId.isEmpty) {
        throw Exception('Checkout completed, but no order ID was returned.');
      }

      if (checkoutResult['coupon_applied'] == true) {
        trustedCouponCode =
            (checkoutResult['coupon_code'] ?? trustedCouponCode ?? '')
                .toString();
        trustedDiscountAmount = Product._toDouble(
          checkoutResult['discount_amount'],
        );
        total = (secureSubtotal + deliveryFee - trustedDiscountAmount)
            .clamp(0, double.infinity)
            .toDouble();
      } else if (requestedCouponCode == null) {
        trustedCouponCode = null;
        trustedDiscountAmount = 0;
        total = (secureSubtotal + deliveryFee).toDouble();
      }

      final orderMetadata = <String, dynamic>{
        'fulfillment_type': fulfillmentType,
        'delivery_address': fulfillmentType == 'delivery' ? address : null,
        'delivery_zone': fulfillmentType == 'delivery' ? deliveryZone : null,
        'scheduled_date': scheduledDateText,
        'scheduled_time': scheduledTimeText,
        'delivery_status':
            fulfillmentType == 'delivery' ? 'pending' : 'ready_for_pickup',
        'subtotal': secureSubtotal,
        'delivery_fee': deliveryFee,
        'discount_code': trustedCouponCode,
        'discount_amount': trustedDiscountAmount,
        'total': total,
        'payment_status': selectedPaymentStatus,
        'payment_method': selectedPaymentMethod,
        'bank_reference': bankReference,
        'notes': checkoutNotes.isEmpty ? null : checkoutNotes,
      };

      try {
        await supabase.from('orders').update(orderMetadata).eq('id', orderId);
      } catch (error) {
        farmDebugLog('Checkout metadata update skipped: $error');
      }

      await ensureStockReducedAfterCheckout(
        orderId: orderId,
        checkoutLines: secureQuote.lines,
      );

      await createOrderConfirmationSupport(
        orderId: orderId,
        customerName: name,
        customerPhone: phone,
        customerEmail: signedInUser.email,
        total: total,
      );

      await createFarmNotification(
        title: 'Order placed',
        message: selectedPaymentMethod == 'bank_transfer'
            ? 'Order #${shortIdLabel(orderId)} was received. Please complete your bank transfer of ${formatJmd(total)} and keep your reference number.'
            : 'Order #${shortIdLabel(orderId)} was received by The Harvest Place Ja.',
        type: 'order',
        userId: signedInUser.id,
        userEmail: signedInUser.email,
        orderId: orderId,
      );

      await createAdminNotification(
        title: 'New order received',
        message:
            '$name placed order #${shortIdLabel(orderId)} for ${formatJmd(total)}.',
        type: 'admin',
        orderId: orderId,
      );

      if (selectedPaymentMethod == 'bank_transfer') {
        await createAdminNotification(
          title: 'Bank transfer to verify',
          message:
              'Order #${shortIdLabel(orderId)} is awaiting bank transfer verification. Reference: ${bankReference ?? 'not provided'}.',
          type: 'payment',
          orderId: orderId,
        );
      }

      await notifyAdminsAboutLowStockAfterCheckout(secureQuote.lines);

      final orderShortId = orderId.length >= 6
          ? orderId.substring(0, 6).toUpperCase()
          : orderId.toUpperCase();

      showBrowserNotification(
        title: 'Order placed',
        body:
            'Your order #$orderShortId from The Harvest Place Ja was sent to the farm.',
        orderId: orderId,
        type: 'order',
      );

      FarmDataCache.clearProducts();
      FarmDataCache.clearOrders();

      if (!mounted) return;

      widget.onOrderPlaced();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
            orderId: orderId,
            total: total,
          ),
        ),
      );
    } catch (error) {
      FarmDataCache.clearProducts();
      FarmDataCache.clearOrders();
      widget.onInventoryChanged?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: ${friendlyAppError(error)}')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  int get checkoutItemCount {
    return widget.cartLines.fold<int>(0, (sum, line) => sum + line.quantity);
  }

  String get checkoutItemLabel {
    if (checkoutItemCount == 1) return '1 item';
    return '$checkoutItemCount items';
  }

  String get checkoutFulfillmentHint {
    if (fulfillmentType == 'delivery') {
      return 'Delivery • $deliveryZone • $scheduledDateText at $scheduledTimeText';
    }
    return 'Farm Pickup • $scheduledDateText at $scheduledTimeText';
  }

  Widget _checkoutHeroCard() {
    return EliteGreenHeroCard(
      eyebrow: 'Secure checkout',
      title: 'Review your farm order.',
      subtitle:
          '$checkoutItemLabel ready for review. Stock is checked again before your order is sent to the farm.',
      icon: Icons.verified_user_outlined,
      chips: const ['Stock checked', 'Clear total', 'Order updates'],
      padding: const EdgeInsets.all(18),
    );
  }

  Widget _checkoutTrustPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkoutLineItem(CartLine line) {
    final lineTotal = line.product.effectivePrice * line.quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FarmColors.line.withOpacity(0.72)),
      ),
      child: Row(
        children: [
          ProductVisual(product: line.product, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${line.quantity} × ${formatJmd(line.product.effectivePrice)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatJmd(lineTotal),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: FarmColors.green,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkoutSummaryBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FarmColors.lightGreen.withOpacity(0.68),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FarmColors.green.withOpacity(0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.event_available_outlined, color: FarmColors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              checkoutFulfillmentHint,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkoutRow(String label, String value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: strong ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: strong ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 130),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _checkoutSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: FarmColors.lightGreen,
            foregroundColor: FarmColors.green,
            child: Icon(icon, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontWeight: FontWeight.w700,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Checkout'),
        backgroundColor: FarmColors.background,
      ),
      body: SafeArea(
        bottom: true,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
          children: [
            _checkoutHeroCard(),
            const SizedBox(height: 18),
            FarmCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _checkoutSectionHeader(
                    icon: Icons.receipt_long_outlined,
                    title: 'Review Order',
                    subtitle:
                        'Check your items and total before placing the order.',
                  ),
                  const SizedBox(height: 12),
                  ...widget.cartLines.map(_checkoutLineItem),
                  _checkoutSummaryBanner(),
                  const SizedBox(height: 14),
                  _checkoutRow(
                    'Subtotal',
                    'J\$${widget.subtotal.toStringAsFixed(2)}',
                  ),
                  _checkoutRow(
                    'Fulfillment',
                    formatFulfillmentType(fulfillmentType),
                  ),
                  _checkoutRow(
                    'Payment',
                    formatPaymentMethod(effectivePaymentMethod),
                  ),
                  if (deliveryFee > 0)
                    _checkoutRow(
                      'Delivery fee',
                      'J\$${deliveryFee.toStringAsFixed(2)}',
                    ),
                  if (discountAmount > 0)
                    _checkoutRow(
                      'Discount ${appliedCouponCode ?? ''}',
                      '-J\$${discountAmount.toStringAsFixed(2)}',
                    ),
                  const Divider(),
                  _checkoutRow(
                    effectivePaymentMethod == 'bank_transfer'
                        ? 'Total to transfer'
                        : 'Total to pay',
                    'J\$${checkoutTotal.toStringAsFixed(2)}',
                    strong: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fulfillmentType == 'delivery'
                        ? 'Home Delivery requires payment before delivery.'
                        : 'Pay when you collect is available for Farm Pickup.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FarmCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _checkoutSectionHeader(
                    icon: Icons.person_outline,
                    title: 'Contact',
                    subtitle: 'Tell us who the order is for.',
                  ),
                  TextField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _checkoutSectionHeader(
                    icon: Icons.local_shipping_outlined,
                    title: 'Pickup or Delivery',
                    subtitle:
                        'Choose how and when you want to receive your farm box.',
                  ),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: fulfillmentType,
                    items: const [
                      DropdownMenuItem(
                        value: 'pickup',
                        child: Text('Farm Pickup',
                            overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'delivery',
                        child: Text('Home Delivery',
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _syncPaymentMethodForFulfillment(value));
                    },
                    decoration: const InputDecoration(
                      labelText: 'Pickup or delivery',
                      prefixIcon: Icon(Icons.local_shipping_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: fulfillmentType == 'delivery'
                          ? FarmColors.warningSoft
                          : FarmColors.lightGreen,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: FarmColors.line),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          fulfillmentType == 'delivery'
                              ? Icons.lock_outline
                              : Icons.payments_outlined,
                          color: fulfillmentType == 'delivery'
                              ? FarmColors.warning
                              : FarmColors.green,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            fulfillmentType == 'delivery'
                                ? 'Home Delivery requires payment before delivery. Choose Bank Transfer for delivery.'
                                : 'Pay when you collect is available for Farm Pickup. You can also choose Bank Transfer.',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (fulfillmentType == 'delivery') ...[
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: deliveryZone,
                      items: deliveryZones
                          .map(
                            (zone) => DropdownMenuItem(
                              value: zone,
                              child: Text(
                                zone,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => deliveryZone = value);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Delivery parish / zone',
                        prefixIcon: Icon(Icons.local_shipping_outlined),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FarmColors.lightGreen,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: FarmColors.line),
                      ),
                      child: Text(
                        'Delivery fee: ${formatJmd(deliveryFee)}. This is added to your total for Home Delivery.',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: FarmColors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _selectionButton(
                        icon: Icons.calendar_month,
                        label: scheduledDateText,
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(now.year, now.month, now.day),
                            lastDate: now.add(const Duration(days: 30)),
                            initialDate: scheduledDate ??
                                DateTime(now.year, now.month, now.day),
                          );
                          if (picked != null) {
                            setState(() => scheduledDate = picked);
                          }
                        },
                      ),
                      _selectionButton(
                        icon: Icons.schedule,
                        label: scheduledTimeText,
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: scheduledTime ??
                                const TimeOfDay(hour: 16, minute: 0),
                          );
                          if (picked != null) {
                            setState(() => scheduledTime = picked);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _checkoutSectionHeader(
                    icon: Icons.payments_outlined,
                    title: 'Payment',
                    subtitle: fulfillmentType == 'delivery'
                        ? 'Choose Bank Transfer for delivery. Payment is required before delivery.'
                        : 'Add a promo code if you have one. Pay when you collect is available for pickup.',
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints:
                            const BoxConstraints(minWidth: 180, maxWidth: 520),
                        child: TextField(
                          controller: couponController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Promo code',
                            prefixIcon:
                                Icon(Icons.confirmation_number_outlined),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: applyingCoupon ? null : applyCoupon,
                        child: Text(applyingCoupon ? 'Applying...' : 'Apply'),
                      ),
                    ],
                  ),
                  if (discountAmount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Promo ${appliedCouponCode ?? ''} applied: -J\$${discountAmount.toStringAsFixed(2)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FarmColors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: effectivePaymentMethod,
                    items: _paymentMethodItems(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => paymentMethod = value);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Payment method',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                  ),
                  if (effectivePaymentMethod == 'bank_transfer') ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: FarmColors.lightGreen,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Bank Transfer Instructions',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text('Bank: National Commercial Bank',
                              maxLines: 2),
                          const Text('Account Name: The Harvest Place Ja',
                              maxLines: 2),
                          const Text('Account Number: #', maxLines: 2),
                          const SizedBox(height: 8),
                          Text(
                              'Product subtotal: ${formatJmd(widget.subtotal)}',
                              maxLines: 2),
                          if (deliveryFee > 0)
                            Text('Delivery fee: ${formatJmd(deliveryFee)}',
                                maxLines: 2),
                          if (discountAmount > 0)
                            Text(
                              'Discount: -${formatJmd(discountAmount)}',
                              maxLines: 2,
                            ),
                          Text(
                            'Total to transfer: ${formatJmd(checkoutTotal)}',
                            maxLines: 2,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: FarmColors.green,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Please transfer the full total, including delivery, then enter your reference below.',
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: bankReferenceController,
                      decoration: const InputDecoration(
                        labelText: 'Bank transfer reference number',
                        prefixIcon: Icon(Icons.confirmation_number_outlined),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (savedProfile != null &&
                      (savedProfile!.address.trim().isNotEmpty ||
                          savedProfile!.phone.trim().isNotEmpty)) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: FarmColors.lightGreen,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Saved delivery details',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          if (savedProfile!.address.trim().isNotEmpty)
                            Text(
                              savedProfile!.address,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (savedProfile!.phone.trim().isNotEmpty)
                            Text(
                              'Phone: ${savedProfile!.phone}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.location_on_outlined),
                                label: const Text('Use saved address'),
                                onPressed: useSavedDeliveryAddress,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    controller: addressController,
                    enabled: fulfillmentType == 'delivery',
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: fulfillmentType == 'delivery'
                          ? 'Delivery address'
                          : 'Delivery address (not needed for pickup)',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Order notes (optional)',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          decoration: BoxDecoration(
            color: FarmColors.surface,
            border: Border(top: BorderSide(color: FarmColors.line)),
            boxShadow: [
              BoxShadow(
                color: FarmColors.shadow.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      effectivePaymentMethod == 'bank_transfer'
                          ? 'Total to transfer'
                          : 'Total to pay',
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'J\$${checkoutTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: FarmColors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed:
                    loading || widget.cartLines.isEmpty ? null : placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FarmColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: loading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.lock_outline, size: 17),
                label: Text(loading ? 'Placing...' : 'Place Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class SecurityAuditScreen extends StatelessWidget {
  const SecurityAuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final checks = const [
      SecurityAuditItem(
        title: 'Authentication',
        status: 'Active',
        detail:
            'Account sign-in, registration, password reset, and protected access are active.',
        icon: Icons.lock_outline,
      ),
      SecurityAuditItem(
        title: 'Protected access',
        status: 'Review',
        detail:
            'Protected access is checked through the approved admin list. Confirm backend rules also enforce admin-only actions.',
        icon: Icons.admin_panel_settings_outlined,
      ),
      SecurityAuditItem(
        title: 'Customer data',
        status: 'Active',
        detail:
            'Customer profile, order, support, and notification data should remain protected by backend security rules.',
        icon: Icons.privacy_tip_outlined,
      ),
      SecurityAuditItem(
        title: 'Checkout safety',
        status: 'Active',
        detail:
            'Checkout uses a secure server flow so order creation, item inserts, stock reduction, payouts, loyalty, and order notification stay together.',
        icon: Icons.verified_outlined,
      ),
      SecurityAuditItem(
        title: 'Notifications',
        status: 'Active',
        detail:
            'Notifications are filtered for the current user email when available.',
        icon: Icons.notifications_active_outlined,
      ),
      SecurityAuditItem(
        title: 'Security readiness',
        status: 'Review',
        detail:
            'Before launch, confirm backend rules for products, orders, customers, support, notifications, admins, and reviews.',
        icon: Icons.shield_outlined,
      ),
    ];

    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(title: const Text('Security Review')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [FarmColors.deepGreen, FarmColors.green],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: FarmColors.green.withOpacity(0.20),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.security_outlined, color: Colors.white, size: 34),
                  SizedBox(height: 14),
                  Text(
                    'Security & trust overview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'A customer-friendly checklist for safety, privacy, and production readiness.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ...checks.map((item) => SecurityAuditTile(item: item)),
            const SizedBox(height: 12),
            FarmCard(
              color: FarmColors.lightGreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Recommended final launch checks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 10),
                  Text('• Enable strict backend security rules.'),
                  Text(
                      '• Confirm only approved accounts have protected access.'),
                  Text('• Rotate keys if they were exposed publicly.'),
                  Text(
                      '• Confirm refund, privacy, and terms pages are visible.'),
                  Text(
                      '• Test checkout, stock reduction, and order notifications.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PolicyScreenShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const PolicyScreenShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: FarmColors.background,
      ),
      body: FarmPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
          children: [
            Header(title: title, subtitle: subtitle),
            const SizedBox(height: 16),
            FarmCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PolicySection extends StatelessWidget {
  final String title;
  final String body;

  const PolicySection({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(height: 1.45, color: FarmColors.text),
          ),
        ],
      ),
    );
  }
}

class TrustCenterScreen extends StatelessWidget {
  const TrustCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Trust Center'),
        backgroundColor: FarmColors.background,
      ),
      body: FarmPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
          children: const [
            Header(
              title: 'Trust Center',
              subtitle: 'Fresh ordering, privacy, support, and delivery clarity.',
            ),
            SizedBox(height: 16),
            TrustCenterHeroCard(),
            SizedBox(height: 16),
            TrustCenterSection(
              title: 'How your order works',
              subtitle:
                  'Simple, clear, and checked before it reaches the farm.',
              items: [
                TrustCenterItem(
                  icon: Icons.shopping_basket_outlined,
                  title: 'Build your box',
                  body:
                      'Browse fresh products, add available items to My Box, and review everything before checkout.',
                ),
                TrustCenterItem(
                  icon: Icons.fact_check_outlined,
                  title: 'Stock is checked again',
                  body:
                      'Before an order is sent, the app checks product availability again so customers do not order unavailable items.',
                ),
                TrustCenterItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Clear order tracking',
                  body:
                      'After checkout, customers can view the order status, payment status, items, notes, pickup, or delivery details.',
                ),
              ],
            ),
            SizedBox(height: 16),
            TrustCenterSection(
              title: 'Freshness & fulfillment',
              subtitle: 'What customers can expect from pickup and delivery.',
              items: [
                TrustCenterItem(
                  icon: Icons.eco_outlined,
                  title: 'Fresh local-first shopping',
                  body:
                      'Products can show freshness, origin, organic status, unit size, stock level, and out-of-stock status clearly.',
                ),
                TrustCenterItem(
                  icon: Icons.local_shipping_outlined,
                  title: 'Pickup or delivery clarity',
                  body:
                      'Checkout shows fulfillment details and totals so customers know what they are ordering and how it will reach them.',
                ),
                TrustCenterItem(
                  icon: Icons.support_agent_outlined,
                  title: 'Support is built in',
                  body:
                      'Customers can contact support about orders, delivery, payment, product requests, or other help topics.',
                ),
              ],
            ),
            SizedBox(height: 16),
            TrustCenterSection(
              title: 'Account protection',
              subtitle:
                  'The app uses role-based controls for safer operations.',
              items: [
                TrustCenterItem(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Admin-only tools stay protected',
                  body:
                      'Inventory, reports, fulfillment, hero uploads, launch checks, and health tools are only available to approved admin accounts.',
                ),
                TrustCenterItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Customer data has a purpose',
                  body:
                      'Saved profile details, orders, favorites, support, reviews, and alerts are used to improve checkout, service, and order updates.',
                ),
                TrustCenterItem(
                  icon: Icons.notifications_active_outlined,
                  title: 'Updates are useful, not noisy',
                  body:
                      'Order and stock notifications are targeted to the right user and include duplicate protection for a cleaner customer experience.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TrustCenterHeroCard extends StatelessWidget {
  const TrustCenterHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const EliteGreenHeroCard(
      eyebrow: 'Trust center',
      title: 'Shop with confidence.',
      subtitle:
          'Clear products, secure checkout, order tracking, support, and protected admin operations are built into the market.',
      icon: Icons.verified_user_outlined,
      chips: ['Stock checked', 'Order updates', 'Support built in'],
    );
  }
}

class TrustCenterItem {
  final IconData icon;
  final String title;
  final String body;

  const TrustCenterItem({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class TrustCenterSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<TrustCenterItem> items;

  const TrustCenterSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(color: FarmColors.mutedText, height: 1.35),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => TrustCenterItemTile(item: item)),
        ],
      ),
    );
  }
}

class TrustCenterItemTile extends StatelessWidget {
  final TrustCenterItem item;

  const TrustCenterItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: FarmColors.lightGreen,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FarmColors.line),
            ),
            child: Icon(item.icon, color: FarmColors.green, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: TextStyle(
                    color: FarmColors.mutedText,
                    height: 1.35,
                    fontSize: 13.2,
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

class TrustCenterLaunchNote extends StatelessWidget {
  const TrustCenterLaunchNote({super.key});

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: FarmColors.accentSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.workspace_premium_outlined,
                color: FarmColors.warning),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Launch confidence note',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  'Before sharing widely, place one real test order, tap both customer and admin notifications, confirm image uploads, and check Admin → Launch and Admin → Health.',
                  style: TextStyle(color: FarmColors.mutedText, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PolicyScreenShell(
      title: 'Terms of Service',
      subtitle: 'How The Harvest Place Ja works',
      children: [
        PolicySection(
          title: 'Using the app',
          body:
              'The Harvest Place Ja connects customers with available farm products, pickup options, delivery options, order tracking, and support tools. You are responsible for keeping your account information accurate and secure.',
        ),
        PolicySection(
          title: 'Product availability and pricing',
          body:
              'Fresh products may change based on harvest, season, weather, and stock. Prices, quantities, descriptions, and availability may be updated at any time before checkout.',
        ),
        PolicySection(
          title: 'Orders, pickup, and delivery',
          body:
              'Orders are accepted based on available stock and selected fulfillment method. Pickup or delivery windows may be adjusted for safety, weather, farm operations, or customer communication needs.',
        ),
        PolicySection(
          title: 'Payment and acceptable use',
          body:
              'Customers agree to provide accurate payment and contact information. Abuse, fraud, false orders, or attempts to disrupt the app may result in account restriction or order cancellation.',
        ),
      ],
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PolicyScreenShell(
      title: 'Privacy Policy',
      subtitle: 'How customer data is handled',
      children: [
        PolicySection(
          title: 'Information collected',
          body:
              'The app may collect account details, name, email, phone number, delivery address, order history, support messages, reviews, notification status, and product preferences such as favorites.',
        ),
        PolicySection(
          title: 'How information is used',
          body:
              'Information is used to create accounts, process orders, confirm pickup or delivery, provide customer support, send order notifications, improve product availability, and personalize the shopping experience.',
        ),
        PolicySection(
          title: 'Storage and protection',
          body:
              'App data is stored through Supabase/backend services. Access should be protected with authentication, role-based admin controls, and database security rules.',
        ),
        PolicySection(
          title: 'Your rights',
          body:
              'Customers may request updates to their profile information, support history, or account details by contacting farm support through the app.',
        ),
      ],
    );
  }
}

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PolicyScreenShell(
      title: 'Refund Policy',
      subtitle: 'Fresh goods and order support',
      children: [
        PolicySection(
          title: 'Fresh and perishable goods',
          body:
              'Because many products are fresh or perishable, refund requests are reviewed based on product condition, timing, pickup or delivery status, and available order evidence.',
        ),
        PolicySection(
          title: 'Damaged, missing, or incorrect items',
          body:
              'If an item is damaged, missing, or incorrect, contact support as soon as possible with your order details. The farm may offer replacement, store credit, partial refund, or refund after review.',
        ),
        PolicySection(
          title: 'Cancellations',
          body:
              'Cancellation approval depends on whether the order has already been prepared, packed, picked up, or sent for delivery.',
        ),
        PolicySection(
          title: 'Pickup and delivery issues',
          body:
              'Missed pickup windows, incorrect addresses, unreachable customers, or failed delivery attempts may affect refund eligibility. Contact support for review.',
        ),
      ],
    );
  }
}
