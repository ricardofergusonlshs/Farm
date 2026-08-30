part of harvest_place_app;

class CustomerOrderMessage {
  final String id;
  final String message;
  final String senderRole;
  final DateTime? createdAt;

  const CustomerOrderMessage({
    required this.id,
    required this.message,
    required this.senderRole,
    this.createdAt,
  });

  factory CustomerOrderMessage.fromSupabase(Map<String, dynamic> data) {
    return CustomerOrderMessage(
      id: (data['id'] ?? '').toString(),
      message: (data['message'] ?? '').toString().trim(),
      senderRole: (data['sender_role'] ?? 'staff').toString().trim(),
      createdAt: parseProductDate(data['created_at']),
    );
  }
}

Future<List<CustomerOrderMessage>> fetchCustomerOrderMessages(
  String orderId,
) async {
  final cleanOrderId = orderId.trim();
  if (cleanOrderId.isEmpty) return const <CustomerOrderMessage>[];

  final response = await supabase
      .from('order_messages')
      .select('id, message, sender_role, created_at')
      .eq('order_id', cleanOrderId)
      .eq('visible_to_customer', true)
      .order('created_at', ascending: false);

  return (response as List)
      .map(
        (item) => CustomerOrderMessage.fromSupabase(
          Map<String, dynamic>.from(item as Map),
        ),
      )
      .toList();
}

class CustomerOrderUpdatesCard extends StatelessWidget {
  final String orderId;

  const CustomerOrderUpdatesCard({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CustomerOrderMessage>>(
      future: fetchCustomerOrderMessages(orderId),
      builder: (context, snapshot) {
        final messages = snapshot.data ?? const <CustomerOrderMessage>[];

        if (snapshot.connectionState == ConnectionState.waiting &&
            messages.isEmpty) {
          return const FarmCard(
            child: Text(
              'Loading order updates...',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          );
        }

        if (messages.isEmpty) {
          return const SizedBox.shrink();
        }

        return FarmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.message_outlined,
                    color: FarmColors.green,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Order Updates',
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...messages.map(
                (message) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FarmColors.cardSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: FarmColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.message,
                        style: const TextStyle(
                          color: FarmColors.ink,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message.createdAt == null
                            ? 'Sent by staff'
                            : 'Sent by staff • ${formatCustomerDateTime(message.createdAt!)}',
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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
  return clean.take(4).toList();
}

final Set<String> _shownBrowserNotificationTags = <String>{};
final ValueNotifier<String?> mealIngredientShopSearchRequest =
    ValueNotifier<String?>(null);
final ValueNotifier<String?> harvestPulseShopRequest =
    ValueNotifier<String?>(null);
    final ValueNotifier<String?> harvestPulseFreshPickId =
    ValueNotifier<String?>(null);
final ValueNotifier<String?> mealIngredientReturnLabel =
    ValueNotifier<String?>(null);

const List<DeliveryZone> _defaultDeliveryZones = <DeliveryZone>[
  DeliveryZone(
    id: 'default-st-elizabeth',
    parish: 'St. Elizabeth',
    deliveryFee: 1000,
    isActive: true,
    sortOrder: 1,
  ),
  DeliveryZone(
    id: 'default-manchester',
    parish: 'Manchester',
    deliveryFee: 1500,
    isActive: true,
    sortOrder: 2,
  ),
];

List<DeliveryZone> _cleanDeliveryZones(List<DeliveryZone> zones) {
  final clean = zones.where((zone) => zone.parish.trim().isNotEmpty).toList()
    ..sort((a, b) {
      final orderCompare = a.sortOrder.compareTo(b.sortOrder);
      if (orderCompare != 0) return orderCompare;
      return a.displayName.compareTo(b.displayName);
    });

  return clean;
}

Future<List<DeliveryZone>> fetchActiveDeliveryZones() async {
  try {
    final response = await supabase
        .from('delivery_zones')
        .select(
          'id, parish, zone_name, delivery_fee, is_active, sort_order, notes, updated_at',
        )
        .eq('is_active', true)
        .order('sort_order', ascending: true)
        .order('parish', ascending: true);

    final zones = (response as List)
        .map((item) =>
            DeliveryZone.fromSupabase(Map<String, dynamic>.from(item)))
        .toList();

    final clean = _cleanDeliveryZones(zones);
    if (clean.isNotEmpty) return clean;
  } catch (error) {
    farmDebugLog(
        'Active delivery zones unavailable. Using safe defaults: $error');
  }

  return _defaultDeliveryZones;
}

Future<List<DeliveryZone>> fetchAdminDeliveryZones() async {
  await requireAdminAccess();

  try {
    final response = await supabase
        .from('delivery_zones')
        .select(
          'id, parish, zone_name, delivery_fee, is_active, sort_order, notes, updated_at',
        )
        .order('sort_order', ascending: true)
        .order('parish', ascending: true);

    final zones = (response as List)
        .map((item) =>
            DeliveryZone.fromSupabase(Map<String, dynamic>.from(item)))
        .toList();

    final clean = _cleanDeliveryZones(zones);
    if (clean.isNotEmpty) return clean;
  } catch (error) {
    farmDebugLog('Admin delivery zones unavailable: $error');
  }

  return _defaultDeliveryZones;
}

Future<void> upsertDeliveryZone({
  String? id,
  required String parish,
  String? zoneName,
  required double deliveryFee,
  required bool isActive,
  int sortOrder = 0,
  String? notes,
}) async {
  await requireAdminAccess();

  final cleanParish = parish.trim();
  if (cleanParish.isEmpty) {
    throw Exception('Please enter a parish.');
  }

  final payload = <String, dynamic>{
    'parish': cleanParish,
    'zone_name':
        zoneName == null || zoneName.trim().isEmpty ? '' : zoneName.trim(),
    'delivery_fee': deliveryFee < 0 ? 0 : deliveryFee,
    'is_active': isActive,
    'sort_order': sortOrder,
    'notes': notes == null || notes.trim().isEmpty ? null : notes.trim(),
    'updated_at': DateTime.now().toIso8601String(),
  };

  final cleanId = id?.trim() ?? '';
  if (cleanId.isNotEmpty && !cleanId.startsWith('default-')) {
    await supabase.from('delivery_zones').update(payload).eq('id', cleanId);
    return;
  }

  await supabase.from('delivery_zones').upsert(
        payload,
        onConflict: 'parish,zone_name',
      );
}

Future<void> seedDefaultDeliveryZones() async {
  await requireAdminAccess();

  final parishes = <DeliveryZone>[
    const DeliveryZone(
        id: 'seed-1',
        parish: 'St. Elizabeth',
        deliveryFee: 1000,
        isActive: true,
        sortOrder: 1),
    const DeliveryZone(
        id: 'seed-2',
        parish: 'Manchester',
        deliveryFee: 1500,
        isActive: true,
        sortOrder: 2),
    const DeliveryZone(
        id: 'seed-3',
        parish: 'Clarendon',
        deliveryFee: 1800,
        isActive: false,
        sortOrder: 3),
    const DeliveryZone(
        id: 'seed-4',
        parish: 'Kingston',
        deliveryFee: 2500,
        isActive: false,
        sortOrder: 4),
    const DeliveryZone(
        id: 'seed-5',
        parish: 'St. Andrew',
        deliveryFee: 2500,
        isActive: false,
        sortOrder: 5),
    const DeliveryZone(
        id: 'seed-6',
        parish: 'St. Catherine',
        deliveryFee: 2200,
        isActive: false,
        sortOrder: 6),
    const DeliveryZone(
        id: 'seed-7',
        parish: 'St. James',
        deliveryFee: 3000,
        isActive: false,
        sortOrder: 7),
    const DeliveryZone(
        id: 'seed-8',
        parish: 'Westmoreland',
        deliveryFee: 2200,
        isActive: false,
        sortOrder: 8),
    const DeliveryZone(
        id: 'seed-9',
        parish: 'Hanover',
        deliveryFee: 2800,
        isActive: false,
        sortOrder: 9),
    const DeliveryZone(
        id: 'seed-10',
        parish: 'Trelawny',
        deliveryFee: 2800,
        isActive: false,
        sortOrder: 10),
    const DeliveryZone(
        id: 'seed-11',
        parish: 'St. Ann',
        deliveryFee: 3000,
        isActive: false,
        sortOrder: 11),
    const DeliveryZone(
        id: 'seed-12',
        parish: 'St. Mary',
        deliveryFee: 3200,
        isActive: false,
        sortOrder: 12),
    const DeliveryZone(
        id: 'seed-13',
        parish: 'Portland',
        deliveryFee: 3500,
        isActive: false,
        sortOrder: 13),
    const DeliveryZone(
        id: 'seed-14',
        parish: 'St. Thomas',
        deliveryFee: 3500,
        isActive: false,
        sortOrder: 14),
  ];

  for (final zone in parishes) {
    await upsertDeliveryZone(
      parish: zone.parish,
      zoneName: zone.zoneName,
      deliveryFee: zone.deliveryFee,
      isActive: zone.isActive,
      sortOrder: zone.sortOrder,
      notes: zone.notes,
    );
  }
}

Future<List<FarmOrder>> _fetchOrdersUncached() async {
  if (!isLoggedIn) return [];

  final user = supabase.auth.currentUser;
  if (user == null) return [];

  const fields =
      'id, order_status, fulfillment_type, subtotal, delivery_fee, discount_amount, total, payment_status, payment_method, delivery_address, delivery_zone, scheduled_date, scheduled_time, notes, created_at, order_items(product_id, product_name, quantity, unit_price, line_total)';

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
            'id, user_id, user_email, title, message, type, is_read, created_at, order_id, action_type, action_id, dedupe_key')
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
            'id, user_email, title, message, type, is_read, created_at, order_id, action_type, action_id, dedupe_key')
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

String normalizeCategoryKey(String? value) {
  final clean = (value ?? '').trim().toLowerCase();

  switch (clean) {
    case 'fruit':
    case 'fruits':
      return 'fruits';
    case 'vegetable':
    case 'vegetables':
      return 'vegetables';
    case 'ground provision':
    case 'ground provisions':
      return 'ground provisions';
    case 'herb':
    case 'herbs':
      return 'herbs';
    case 'egg':
    case 'eggs':
      return 'eggs';
    case 'prepared food':
    case 'prepared foods':
      return 'prepared foods';
    case 'all':
      return 'all';
    default:
      return clean;
  }
}

String displayCategoryLabel(String? value) {
  switch (normalizeCategoryKey(value)) {
    case 'fruits':
      return 'Fruits';
    case 'vegetables':
      return 'Vegetables';
    case 'ground provisions':
      return 'Ground Provisions';
    case 'herbs':
      return 'Herbs';
    case 'eggs':
      return 'Eggs';
    case 'prepared foods':
      return 'Prepared Foods';
    case 'all':
      return 'All';
    default:
      final clean = (value ?? '').trim();
      return clean.isEmpty ? 'Other' : clean;
  }
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
  final metadataName =
      (metadata['full_name'] ?? metadata['name'] ?? metadata['display_name'])
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
  final ValueChanged<Product>? onAddToCart;
  final VoidCallback? onSignedOut;

  const AccountScreen({
    super.key,
    this.favoriteProducts = const [],
    this.recentlyViewedProducts = const [],
    required this.onShopTap,
    this.onAddToCart,
    this.onSignedOut,
  });

  void _open(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    if (!isLoggedIn || user == null) {
      return const GuestProtectedScreen(
        title: 'Account',
        subtitle: 'Orders, profile, rewards',
        message:
            'Sign in or create an account to view your orders, saved details, rewards, and support options.',
      );
    }

    final rawName = user.userMetadata?['full_name']?.toString().trim() ?? '';
    final name = rawName.isEmpty ? 'HPJ Customer' : rawName;

    return FutureBuilder<SavedCustomerProductSnapshot>(
      future: fetchSavedCustomerProductSnapshot(
        fallbackFavoriteProducts: favoriteProducts,
        fallbackRecentlyViewedProducts: recentlyViewedProducts,
      ),
      builder: (context, savedSnapshot) {
        final savedProducts = savedSnapshot.data ??
            SavedCustomerProductSnapshot(
              favoriteProducts: favoriteProducts,
              recentlyViewedProducts: recentlyViewedProducts,
            );

        final displayFavoriteProducts = savedProducts.favoriteProducts;

        return FarmPage(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
            children: [
              HpjCompactAccountHero(
                icon: Icons.person_outline_rounded,
                title: name,
                subtitle: user.email ?? '',
                badge: 'Customer',
              ),
              const SizedBox(height: 12),

              _CustomerWorkspaceSwitchCard(
                onShopTap: onShopTap,
              ),
              const SizedBox(height: 14),

              FarmCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AccountSectionHeading(
                      title: 'Quick access',
                      subtitle: 'The account tools you are most likely to need.',
                    ),
                    const SizedBox(height: 14),
                    AccountActionGrid(
                      actions: [
                        AccountActionItem(
                          icon: Icons.receipt_long_outlined,
                          title: 'Orders',
                          subtitle: 'Track purchases',
                          onTap: () => _open(
                            context,
                            const OrdersScreen(),
                          ),
                        ),
                        AccountActionItem(
                          icon: Icons.person_outline_rounded,
                          title: 'Profile',
                          subtitle: 'Details & addresses',
                          onTap: () => _open(
                            context,
                            const CustomerProfileScreen(),
                          ),
                        ),
                        AccountActionItem(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications',
                          subtitle: 'Order updates',
                          onTap: () => _open(
                            context,
                            const NotificationsScreen(),
                          ),
                        ),
                        AccountActionItem(
                          icon: Icons.tune_rounded,
                          title: 'Settings',
                          subtitle: 'Preferences & password',
                          onTap: () => _open(
                            context,
                            const HpjSettingsPreferencesScreen(
                              audience: HpjPreferenceAudience.customer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              FarmCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
                      child: AccountSectionHeading(
                        title: 'Shopping & rewards',
                        subtitle: 'Saved shopping tools in one place.',
                      ),
                    ),
                    AccountListTile(
                      icon: Icons.inventory_2_outlined,
                      title: 'Weekly Box',
                      subtitle: 'Manage recurring boxes.',
                      onTap: () => _open(
                        context,
                        const CustomerSubscriptionsScreen(),
                      ),
                    ),
                    AccountListTile(
                      icon: Icons.favorite_outline_rounded,
                      title: 'Favorites',
                      subtitle: '${displayFavoriteProducts.length} saved',
                      onTap: () => _open(
                        context,
                        FavoritesScreen(
                          products: displayFavoriteProducts,
                          onShopTap: onShopTap,
                        ),
                      ),
                    ),
                    AccountListTile(
                      icon: Icons.card_giftcard_rounded,
                      title: 'Rewards',
                      subtitle: 'Points and benefits.',
                      onTap: () => _open(
                        context,
                        const LoyaltyRewardsScreen(),
                      ),
                    ),
                    AccountListTile(
                      icon: Icons.play_circle_outline_rounded,
                      title: 'Fresh Reels',
                      subtitle: 'Watch farm, harvest and recipe videos.',
                      onTap: () => _open(
                        context,
                        HpjFreshReelsEntryScreen(
                          onAddToCart: (product) {
                            onAddToCart?.call(product);
                            Future.microtask(
                              () => saveCartItemForCurrentUser(product),
                            );
                          },
                        ),
                      ),
                    ),
                    AccountListTile(
                      icon: Icons.ios_share_outlined,
                      title: 'Invite & Earn',
                      subtitle: 'Share HPJ and earn referral rewards.',
                      isLast: true,
                      onTap: () => _open(
                        context,
                        const InviteFarmMarketScreen(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              FarmCard(
                padding: EdgeInsets.zero,
                child: AccountListTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & information',
                  subtitle: 'Support, contact details and HPJ policies.',
                  isLast: true,
                  onTap: () => _open(
                    context,
                    const HpjAccountHelpInfoScreen(
                      supportSubject: 'Customer support',
                      showTrustCenter: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              OutlinedButton.icon(
                icon: const Icon(Icons.logout_outlined),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FarmColors.danger,
                  side: BorderSide(
                    color: FarmColors.danger.withOpacity(0.26),
                  ),
                  backgroundColor: FarmColors.card,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () async {
                  await clearPrivateSessionStateForGuestBrowsing();
                  onSignedOut?.call();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Signed out. You can keep browsing as a guest.',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}


class _CustomerWorkspaceSwitchCard extends StatelessWidget {
  final VoidCallback onShopTap;

  const _CustomerWorkspaceSwitchCard({
    required this.onShopTap,
  });

  void _openAllWorkspaces(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OwnerWorkspaceSwitcherScreen(
          onShopTap: onShopTap,
          currentWorkspace: 'customer',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FarmColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openAllWorkspaces(context),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: FarmColors.line),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.apps_rounded,
                color: FarmColors.primary,
                size: 23,
              ),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Switch workspace',
                      style: TextStyle(
                        color: FarmColors.ink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Open another approved HPJ workspace.',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
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

class InviteFarmMarketScreen extends StatelessWidget {
  const InviteFarmMarketScreen({super.key});

  String get _shareSubject => 'The Harvest Place Ja';

  String _encoded(String value) => Uri.encodeComponent(value.trim());

  List<_InviteShareAction> _shareActionsFor(ReferralShareSnapshot referral) {
    final inviteText = referral.inviteMessage.trim();
    final referralLink = referral.referralLink.trim();

    final encodedInviteText = _encoded(inviteText);
    final encodedReferralLink = _encoded(referralLink);
    final encodedSubject = _encoded(_shareSubject);

    final webShareText =
        _encoded('Fresh local food, weekly boxes, and farm order tracking.');

    return [
      _InviteShareAction(
        label: 'WhatsApp',
        subtitle: 'Chats & groups',
        icon: Icons.chat_bubble_outline,
        accentColor: FarmColors.success,
        urls: [
          'whatsapp://send?text=$encodedInviteText',
          'https://wa.me/?text=$encodedInviteText',
          'https://api.whatsapp.com/send?text=$encodedInviteText',
        ],
        successMessage: 'Opening WhatsApp...',
      ),
      _InviteShareAction(
        label: 'Telegram',
        subtitle: 'Send link',
        icon: Icons.send_outlined,
        accentColor: const Color(0xFF2AABEE),
        urls: [
          'tg://msg_url?url=$encodedReferralLink&text=$encodedInviteText',
          'tg://msg?text=$encodedInviteText',
          'https://t.me/share/url?url=$encodedReferralLink&text=$webShareText',
        ],
        successMessage: 'Opening Telegram...',
      ),
      _InviteShareAction(
        label: 'Facebook',
        subtitle: 'Share link',
        icon: Icons.facebook,
        accentColor: const Color(0xFF1877F2),
        urls: [
          'fb://facewebmodal/f?href=https://www.facebook.com/sharer/sharer.php?u=$encodedReferralLink',
          'https://www.facebook.com/sharer/sharer.php?u=$encodedReferralLink',
        ],
        successMessage: 'Opening Facebook...',
      ),
      _InviteShareAction(
        label: 'X',
        subtitle: 'Post invite',
        icon: Icons.alternate_email_rounded,
        accentColor: FarmColors.ink,
        urls: [
          'twitter://post?message=$encodedInviteText',
          'https://twitter.com/intent/tweet?text=$encodedInviteText',
        ],
        successMessage: 'Opening X...',
      ),
      _InviteShareAction(
        label: 'Text',
        subtitle: 'SMS invite',
        icon: Icons.sms_outlined,
        accentColor: FarmColors.primary,
        urls: [
          'sms:?body=$encodedInviteText',
          'sms:&body=$encodedInviteText',
          'smsto:?body=$encodedInviteText',
        ],
        successMessage: 'Opening text message...',
      ),
      _InviteShareAction(
        label: 'Email',
        subtitle: 'Send email',
        icon: Icons.email_outlined,
        accentColor: FarmColors.warning,
        urls: [
          'mailto:?subject=$encodedSubject&body=$encodedInviteText',
        ],
        successMessage: 'Opening email...',
      ),
      _InviteShareAction(
        label: 'Open link',
        subtitle: 'Browser',
        icon: Icons.open_in_new_rounded,
        accentColor: FarmColors.green,
        urls: [referralLink],
        successMessage: 'Opening invite link...',
      ),
    ];
  }

  Future<bool> _openFirstAvailable(List<String> urls) async {
    for (final url in urls) {
      final cleanUrl = url.trim();
      if (cleanUrl.isEmpty) continue;

      try {
        final opened = await openExternalShareUrl(cleanUrl);
        if (opened) return true;
      } catch (_) {
        // Keep trying every fallback before copying.
      }
    }

    return false;
  }

  Future<void> _showShareSnackBar(
    BuildContext context,
    String message,
  ) async {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _copyInvite(
    BuildContext context,
    ReferralShareSnapshot referral,
  ) async {
    await Clipboard.setData(ClipboardData(text: referral.inviteMessage));
    await _showShareSnackBar(context, 'Referral invite copied.');
  }

  Future<void> _copyCode(
    BuildContext context,
    ReferralShareSnapshot referral,
  ) async {
    await Clipboard.setData(ClipboardData(text: referral.referralCode));
    await _showShareSnackBar(context, 'Referral code copied.');
  }

  Future<void> _copyLink(
    BuildContext context,
    ReferralShareSnapshot referral,
  ) async {
    await Clipboard.setData(ClipboardData(text: referral.referralLink));
    await _showShareSnackBar(context, 'Referral link copied.');
  }

  Future<void> _shareWithAction(
    BuildContext context,
    _InviteShareAction action,
    ReferralShareSnapshot referral,
  ) async {
    final opened = await _openFirstAvailable(action.urls);

    if (!context.mounted) return;

    if (opened) {
      await _showShareSnackBar(context, action.successMessage);
      return;
    }

    await Clipboard.setData(ClipboardData(text: referral.inviteMessage));

    if (!context.mounted) return;

    await _showShareSnackBar(
      context,
      '${action.label} could not open on this device. Referral invite copied instead.',
    );
  }

  Future<void> _shareOnWhatsApp(
    BuildContext context,
    ReferralShareSnapshot referral,
  ) async {
    final whatsapp = _shareActionsFor(referral).firstWhere(
      (action) => action.label == 'WhatsApp',
    );
    await _shareWithAction(context, whatsapp, referral);
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn || supabase.auth.currentUser == null) {
      return const GuestProtectedScreen(
        title: 'Invite Friends',
        subtitle: 'Share the market and earn rewards',
        message:
            'Sign in to get your personal referral link and earn Harvest Rewards points when invited customers complete their first order.',
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Invite & Earn'),
      ),
      body: FarmPage(
        child: FutureBuilder<ReferralShareSnapshot>(
          future: fetchReferralShareSnapshot(),
          builder: (context, snapshot) {
            final loading = snapshot.connectionState == ConnectionState.waiting;
            final referral = snapshot.data;

            if (loading && referral == null) {
              return const SizedBox.expand(child: SkeletonList(count: 4));
            }

            if (referral == null) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
                children: const [
                  FarmEmptyState(
                    icon: Icons.ios_share_outlined,
                    title: 'Referral link not ready',
                    message:
                        'Please check your connection and try opening Invite & Earn again.',
                  ),
                ],
              );
            }

            final shareActions = _shareActionsFor(referral);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
              children: [
                const Header(
                  title: 'Invite & Earn',
                  subtitle:
                      'Share your personal link and earn points after a new customer’s first completed order.',
                ),
                const SizedBox(height: 18),
                _ReferralRewardsHero(referral: referral),
                const SizedBox(height: 14),
                FarmCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AccountSectionHeading(
                        title: 'Your referral',
                        subtitle:
                            'Use WhatsApp first, or copy your code/link anytime.',
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: FarmColors.cardSoft,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: FarmColors.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Referral code',
                              style: TextStyle(
                                color: FarmColors.mutedText,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    referral.referralCode,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: FarmColors.green,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.copy_outlined),
                                  label: const Text('Copy'),
                                  onPressed: () => _copyCode(context, referral),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Referral link',
                              style: TextStyle(
                                color: FarmColors.mutedText,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              referral.referralLink,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: FarmColors.ink,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('WhatsApp'),
                              onPressed: () =>
                                  _shareOnWhatsApp(context, referral),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.link_rounded),
                              label: const Text('Copy link'),
                              onPressed: () => _copyLink(context, referral),
                            ),
                          ),
                        ],
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
                      const AccountSectionHeading(
                        title: 'Share with',
                        subtitle:
                            'Each option tries the phone app first, then falls back safely.',
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 520 ? 3 : 2;
                          final spacing = 10.0;
                          final width =
                              (constraints.maxWidth - spacing * (columns - 1)) /
                                  columns;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              ...shareActions.map(
                                (action) => SizedBox(
                                  width: width,
                                  child: _InviteShareTile(
                                    action: action,
                                    onTap: () => _shareWithAction(
                                      context,
                                      action,
                                      referral,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: _InviteShareTile(
                                  action: const _InviteShareAction(
                                    label: 'Copy',
                                    subtitle: 'Message',
                                    icon: Icons.copy_outlined,
                                    accentColor: FarmColors.green,
                                    urls: [],
                                    successMessage: 'Invite copied.',
                                  ),
                                  onTap: () => _copyInvite(context, referral),
                                ),
                              ),
                            ],
                          );
                        },
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
                        'How points work',
                        style: TextStyle(
                          color: FarmColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _RewardInfoRow(
                        icon: Icons.ios_share_outlined,
                        title: 'Share your personal link',
                        message:
                            'Send your link by WhatsApp, text, email, or social media.',
                      ),
                      _RewardInfoRow(
                        icon: Icons.person_add_alt_1_outlined,
                        title: 'A new customer joins',
                        message:
                            'The referral is saved when the invited customer opens the app with your link or code.',
                      ),
                      _RewardInfoRow(
                        icon: Icons.card_giftcard_outlined,
                        title: 'Earn after their first order',
                        message:
                            'You earn $referralRewardPoints points after their first eligible completed order.',
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
                        'Message preview',
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
                          color: FarmColors.primarySoft.withOpacity(0.46),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: FarmColors.line),
                        ),
                        child: Text(
                          referral.inviteMessage,
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
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReferralRewardsHero extends StatelessWidget {
  final ReferralShareSnapshot referral;

  const _ReferralRewardsHero({required this.referral});

  @override
  Widget build(BuildContext context) {
    final summary = referral.referralSummary;
    final loyalty = referral.loyaltySummary;

    return FarmCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7E9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDDEED8)),
                ),
                child: const Icon(
                  Icons.card_giftcard_outlined,
                  color: FarmColors.green,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Give fresh. Earn points.',
                      style: TextStyle(
                        color: FarmColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Earn referral rewards when new customers shop through your invite.',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontWeight: FontWeight.w700,
                        height: 1.28,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ReferralMiniMetric(
                  label: 'Available',
                  value: '${loyalty.points}',
                  helper: 'points',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ReferralMiniMetric(
                  label: 'Completed',
                  value: '${summary.completedCount}',
                  helper: 'referrals',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ReferralMiniMetric(
                  label: 'Pending',
                  value: '${summary.pendingCount}',
                  helper: 'invites',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReferralMiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final String helper;

  const _ReferralMiniMetric({
    required this.label,
    required this.value,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FarmColors.green,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FarmColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 11.2,
            ),
          ),
          Text(
            helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontWeight: FontWeight.w700,
              fontSize: 10.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteShareAction {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<String> urls;
  final String successMessage;

  const _InviteShareAction({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.urls,
    required this.successMessage,
  });
}

class _InviteShareTile extends StatelessWidget {
  final _InviteShareAction action;
  final VoidCallback onTap;

  const _InviteShareTile({
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 92),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: FarmColors.cardSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FarmColors.line.withOpacity(0.88)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: action.accentColor.withOpacity(0.11),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      action.icon,
                      color: action.accentColor,
                      size: 18,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: FarmColors.mutedText.withOpacity(0.40),
                    size: 12,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FarmColors.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 14.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                action.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.6,
                ),
              ),
            ],
          ),
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
                    subtitle: 'Choose the steps for your device.',
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FarmColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: FarmColors.green.withOpacity(0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: FarmColors.shadow.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: FarmColors.primarySoft,
              shape: BoxShape.circle,
              border: Border.all(color: FarmColors.green.withOpacity(0.14)),
            ),
            child: Text(
              initial,
              style: const TextStyle(
                color: FarmColors.green,
                fontSize: 24,
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
                    color: FarmColors.ink,
                    fontSize: 22,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    AccountHeroPill(
                      icon: showAdmin
                          ? Icons.admin_panel_settings_outlined
                          : Icons.verified_user_outlined,
                      label: roleLabel,
                    ),
                    if (favoriteCount > 0)
                      AccountHeroPill(
                        icon: Icons.favorite_outline,
                        label: '$favoriteCount saved',
                      ),
                    if (recentCount > 0)
                      AccountHeroPill(
                        icon: Icons.history,
                        label: '$recentCount recent',
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
        color: FarmColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: FarmColors.green.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: FarmColors.green, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.green,
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
          constraints: const BoxConstraints(minHeight: 84),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FarmColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FarmColors.line.withOpacity(0.90)),
            boxShadow: [
              BoxShadow(
                color: FarmColors.shadow.withOpacity(0.025),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: action.accentColor.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  action.icon,
                  color: action.accentColor,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.4,
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
                        fontSize: 11.1,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: FarmColors.mutedText.withOpacity(0.34),
                size: 12,
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

// THE HARVEST PLACE JA
// SAFE SECTIONAL UPGRADE
// File to update: lib/screens/customer/customer_screens.dart
//
// 1. Find: class PersonalizedHomeHeroCard extends StatelessWidget
// 2. Replace that class AND the complete HomeHeroImageSlideshow section
//    with everything in this file.
// 3. Stop replacing immediately before the class that currently follows
//    _HomeHeroImageSlideshowState in your project.
//
// No Supabase, Firebase, checkout, cart, nutrient, driver, or admin code
// is changed by this section.

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

    return HomeHeroImageSlideshow(
      category: category,
      onShopTap: onShopTap,
    );
  }
}

// THE HARVEST PLACE JA
// TARGETED ELITE WEEKLY MEAL REPLACEMENT
// In customer_screens.dart, keep PersonalizedHomeHeroCard.
// Replace from: class _WeeklyMealIdea {
// through the final closing brace of the current WeeklyMealIdeasScreen.

class _WeeklyMealIdea {
  final int weekday;
  final String day;
  final String shortDay;
  final String name;
  final String dietaryLabel;
  final String imageUrl;
  final String? localImageAsset;
  final String description;
  final int preparationMinutes;
  final int servings;
  final String difficulty;
  final List<String> freshIngredients;
  final List<String> pantryIngredients;
  final List<String> nutritionHighlights;

  const _WeeklyMealIdea({
    required this.weekday,
    required this.day,
    required this.shortDay,
    required this.name,
    required this.dietaryLabel,
    required this.imageUrl,
    this.localImageAsset,
    required this.description,
    required this.preparationMinutes,
    required this.servings,
    required this.difficulty,
    required this.freshIngredients,
    required this.pantryIngredients,
    required this.nutritionHighlights,
  });

  bool get isPlantBased {
    final normalized = dietaryLabel.toLowerCase();
    return normalized.contains('vegan') || normalized.contains('ital');
  }
}

const List<_WeeklyMealIdea> _weeklyMealIdeas = <_WeeklyMealIdea>[
  _WeeklyMealIdea(
    weekday: DateTime.monday,
    day: 'Monday',
    shortDay: 'MON',
    name: 'Curry Chicken with White Rice',
    dietaryLabel: 'Classic',
    imageUrl:
        'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?auto=format&fit=crop&w=1200&q=84',
    description:
        'A comforting Jamaican-style curry meal with fresh herbs, vegetables, and fluffy white rice.',
    preparationMinutes: 50,
    servings: 4,
    difficulty: 'Easy',
    freshIngredients: <String>[
      'Chicken',
      'Irish potato',
      'Carrot',
      'Scallion',
      'Thyme',
      'Scotch bonnet',
    ],
    pantryIngredients: <String>[
      'Rice',
      'Curry seasoning',
      'Cooking oil',
    ],
    nutritionHighlights: <String>['Protein', 'Iron', 'Vitamin C'],
  ),
  _WeeklyMealIdea(
    weekday: DateTime.tuesday,
    day: 'Tuesday',
    shortDay: 'TUE',
    name: 'Callaloo and Saltfish',
    dietaryLabel: 'Classic',
    imageUrl:
        'https://images.unsplash.com/photo-1576045057995-568f588f82fb?auto=format&fit=crop&w=1200&q=84',
    description:
        'Fresh callaloo gently cooked with saltfish, tomato, sweet pepper, scallion, and Jamaican seasonings.',
    preparationMinutes: 35,
    servings: 4,
    difficulty: 'Easy',
    freshIngredients: <String>[
      'Callaloo',
      'Tomato',
      'Sweet pepper',
      'Onion',
      'Scallion',
      'Scotch bonnet',
    ],
    pantryIngredients: <String>['Saltfish', 'Cooking oil', 'Black pepper'],
    nutritionHighlights: <String>['Iron', 'Fiber', 'Vitamin C'],
  ),
  _WeeklyMealIdea(
    weekday: DateTime.wednesday,
    day: 'Wednesday',
    shortDay: 'WED',
    name: 'Brown Stew Chicken',
    dietaryLabel: 'Classic',
    imageUrl:
        'https://images.unsplash.com/photo-1532550907401-a500c9a57435?auto=format&fit=crop&w=1200&q=84',
    description:
        'A rich Jamaican brown stew made with chicken, vegetables, herbs, and a deeply flavoured gravy.',
    preparationMinutes: 55,
    servings: 4,
    difficulty: 'Easy',
    freshIngredients: <String>[
      'Chicken',
      'Tomato',
      'Carrot',
      'Sweet pepper',
      'Onion',
      'Thyme',
    ],
    pantryIngredients: <String>[
      'Browning',
      'Cooking oil',
      'Seasoning',
    ],
    nutritionHighlights: <String>['Protein', 'Potassium', 'Vitamin C'],
  ),
  _WeeklyMealIdea(
    weekday: DateTime.thursday,
    day: 'Thursday',
    shortDay: 'THU',
    name: 'Ital Stew',
    dietaryLabel: 'Ital / Vegan',
    imageUrl:
        'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=1200&q=84',
    description:
        'A colourful plant-based Jamaican stew with peas, vegetables, coconut, herbs, and ground provisions.',
    preparationMinutes: 45,
    servings: 4,
    difficulty: 'Easy',
    freshIngredients: <String>[
      'Pumpkin',
      'Chocho',
      'Carrot',
      'Callaloo',
      'Scallion',
      'Thyme',
    ],
    pantryIngredients: <String>[
      'Red peas',
      'Coconut milk',
      'Pimento',
    ],
    nutritionHighlights: <String>['Fiber', 'Iron', 'Potassium'],
  ),
  _WeeklyMealIdea(
    weekday: DateTime.friday,
    day: 'Friday',
    shortDay: 'FRI',
    name: 'Escovitch Fish with Bammy',
    dietaryLabel: 'Classic',
    imageUrl:
        'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?auto=format&fit=crop&w=1200&q=84',
    description:
        'Crisp fish topped with a bright escovitch mixture of carrot, onion, sweet pepper, and Scotch bonnet.',
    preparationMinutes: 50,
    servings: 4,
    difficulty: 'Medium',
    freshIngredients: <String>[
      'Fish',
      'Carrot',
      'Onion',
      'Sweet pepper',
      'Scotch bonnet',
      'Lime',
    ],
    pantryIngredients: <String>['Bammy', 'Vinegar', 'Cooking oil'],
    nutritionHighlights: <String>['Protein', 'Vitamin C', 'Potassium'],
  ),
  _WeeklyMealIdea(
    weekday: DateTime.saturday,
    day: 'Saturday',
    shortDay: 'SAT',
    name: 'Jamaican Red Peas Soup',
    dietaryLabel: 'Classic',
    imageUrl:
        'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=1200&q=84',
    description:
        'A hearty Saturday soup with red peas, pumpkin, vegetables, herbs, and filling ground provisions.',
    preparationMinutes: 70,
    servings: 6,
    difficulty: 'Easy',
    freshIngredients: <String>[
      'Pumpkin',
      'Yellow yam',
      'Chocho',
      'Carrot',
      'Scallion',
      'Thyme',
    ],
    pantryIngredients: <String>['Red peas', 'Flour', 'Pimento'],
    nutritionHighlights: <String>['Fiber', 'Iron', 'Vitamin A'],
  ),
  _WeeklyMealIdea(
    weekday: DateTime.sunday,
    day: 'Sunday',
    shortDay: 'SUN',
    name: 'Rice and Peas Sunday Dinner',
    dietaryLabel: 'Classic',
    imageUrl:
        'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=1200&q=84',
    description:
        'A Jamaican Sunday favourite with rice and peas, a main dish, fresh vegetables, and plantain.',
    preparationMinutes: 75,
    servings: 6,
    difficulty: 'Medium',
    freshIngredients: <String>[
      'Scallion',
      'Thyme',
      'Cabbage',
      'Carrot',
      'Plantain',
      'Scotch bonnet',
    ],
    pantryIngredients: <String>['Rice', 'Red peas', 'Coconut milk'],
    nutritionHighlights: <String>['Fiber', 'Protein', 'Potassium'],
  ),
];

_WeeklyMealIdea _mealForWeekday(int weekday) {
  return _weeklyMealIdeas.firstWhere(
    (meal) => meal.weekday == weekday,
    orElse: () => _weeklyMealIdeas.first,
  );
}

class _MealPhoto extends StatelessWidget {
  final _WeeklyMealIdea meal;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const _MealPhoto({
    required this.meal,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.borderRadius,
  });

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      color: FarmColors.primarySoft,
      alignment: Alignment.center,
      child: Icon(
        Icons.restaurant_menu_rounded,
        color: FarmColors.green.withOpacity(0.55),
        size: 42,
      ),
    );
  }

  Widget _networkImage() {
    return Image.network(
      meal.imageUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      cacheWidth: 1200,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget image;

    final assetPath = meal.localImageAsset?.trim() ?? '';
    if (assetPath.isNotEmpty) {
      image = Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, __, ___) => _networkImage(),
      );
    } else {
      image = _networkImage();
    }

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}

class HomeHeroImageSlideshow extends StatefulWidget {
  final String category;
  final VoidCallback? onShopTap;

  const HomeHeroImageSlideshow({
    super.key,
    required this.category,
    this.onShopTap,
  });

  @override
  State<HomeHeroImageSlideshow> createState() => _HomeHeroImageSlideshowState();
}

class _HomeHeroImageSlideshowState extends State<HomeHeroImageSlideshow> {
  final PageController _controller = PageController();
  late Future<List<HomeHeroSlide>> _slidesFuture;
  Timer? _timer;
  int _index = 0;
  int _lastSlideCount = 1;

  @override
  void initState() {
    super.initState();
    _slidesFuture = fetchHomeHeroSlides();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients || _lastSlideCount <= 1) return;

      final next = (_index + 1) % _lastSlideCount;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _titleForSlide(HomeHeroSlide slide) {
    final custom = slide.title?.trim() ?? '';
    if (custom.isNotEmpty) return custom;
    return 'Build Your Fresh Box';
  }

  String _subtitleForSlide(HomeHeroSlide slide) {
    final custom = slide.subtitle?.trim() ?? '';
    if (custom.isNotEmpty) return custom;
    return 'Choose local produce for pickup or delivery';
  }

  void _openWeeklyMeals() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WeeklyMealIdeasScreen(
          onShopTap: widget.onShopTap,
        ),
      ),
    );
  }

  Widget _pageDots(int totalCount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(totalCount, (dotIndex) {
        final active = dotIndex == _index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.only(right: 4),
          height: 5,
          width: active ? 16 : 5,
          decoration: BoxDecoration(
            color:
                active ? FarmColors.green : FarmColors.green.withOpacity(0.28),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }

  Widget _networkHeroImage(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      alignment: Alignment.centerRight,
      cacheWidth: 1000,
      errorBuilder: (_, __, ___) {
        return Container(
          color: FarmColors.primarySoft,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 34),
          child: Icon(
            Icons.eco_rounded,
            size: 44,
            color: FarmColors.green.withOpacity(0.34),
          ),
        );
      },
    );
  }

  Widget _buildExistingSlide({
    required HomeHeroSlide slide,
    required int totalCount,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onShopTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _networkHeroImage(slide.imageUrl),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFFE5F3DF).withOpacity(0.99),
                    const Color(0xFFE5F3DF).withOpacity(0.90),
                    const Color(0xFFE5F3DF).withOpacity(0.36),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.48, 0.72, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 108, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _titleForSlide(slide),
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
                    _subtitleForSlide(slide),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: FarmColors.deepGreen.withOpacity(0.72),
                      fontSize: 11.5,
                      height: 1.18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 14,
              bottom: 9,
              child: _pageDots(totalCount),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyMealSlide({required int totalCount}) {
    final meal = _mealForWeekday(DateTime.now().weekday);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openWeeklyMeals,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth < 340
                ? constraints.maxWidth * 0.72
                : constraints.maxWidth * 0.68;

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: _MealPhoto(
                    meal: meal,
                    alignment: Alignment.centerRight,
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFFFFF8E9).withOpacity(1.0),
                        const Color(0xFFF3F7E9).withOpacity(0.98),
                        const Color(0xFFE8F2DE).withOpacity(0.70),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.48, 0.76, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 8, 23),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: contentWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.74),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: FarmColors.green.withOpacity(0.16),
                                  ),
                                ),
                                child: const Text(
                                  'JAMAICAN MEAL GUIDE',
                                  style: TextStyle(
                                    color: FarmColors.green,
                                    fontSize: 7.8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            "WHAT'S COOKING THIS WEEK?",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: FarmColors.deepGreen,
                              fontSize: 14.6,
                              height: 1.04,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.20,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: FarmColors.accentSoft,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color:
                                          FarmColors.accent.withOpacity(0.30),
                                    ),
                                  ),
                                  child: Text(
                                    '${meal.day} • ${meal.name}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: FarmColors.warning,
                                      fontSize: 8.6,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                height: 25,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 9),
                                decoration: BoxDecoration(
                                  color: FarmColors.green,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: FarmColors.green.withOpacity(0.18),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Explore',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8.8,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(width: 2),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 9,
                  child: _pageDots(totalCount),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HomeHeroSlide>>(
      future: _slidesFuture,
      builder: (context, snapshot) {
        final existingSlides =
            _cleanHomeHeroSlides(snapshot.data ?? defaultHomeHeroSlides());

        final firstSlide = existingSlides.isNotEmpty
            ? existingSlides.first
            : defaultHomeHeroSlides().first;

        final differentSlides = existingSlides.where((slide) {
          return slide.imageUrl.trim() != firstSlide.imageUrl.trim();
        }).toList();

        final secondSlide =
            differentSlides.isNotEmpty ? differentSlides.first : firstSlide;

        const totalCount = 3;
        _lastSlideCount = totalCount;

        if (_index >= totalCount) _index = 0;

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
            child: PageView.builder(
              controller: _controller,
              itemCount: totalCount,
              onPageChanged: (value) {
                if (!mounted) return;
                setState(() => _index = value);
              },
              itemBuilder: (context, pageIndex) {
                if (pageIndex == 0) {
                  return _buildExistingSlide(
                    slide: firstSlide,
                    totalCount: totalCount,
                  );
                }

                if (pageIndex == 1) {
                  return _buildWeeklyMealSlide(totalCount: totalCount);
                }

                return _buildExistingSlide(
                  slide: secondSlide,
                  totalCount: totalCount,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class WeeklyMealIdeasScreen extends StatefulWidget {
  final VoidCallback? onShopTap;

  const WeeklyMealIdeasScreen({
    super.key,
    this.onShopTap,
  });

  @override
  State<WeeklyMealIdeasScreen> createState() => _WeeklyMealIdeasScreenState();
}

class _WeeklyMealIdeasScreenState extends State<WeeklyMealIdeasScreen> {
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    final preferences = hpjCurrentUserExperiencePreferences;
    if (preferences.dietaryStyle == 'vegan' ||
        preferences.dietaryStyle == 'vegetarian' ||
        preferences.recommendationStyle == 'vegan') {
      _selectedFilter = 'Ital / Vegan';
    }
  }

  List<_WeeklyMealIdea> get _filteredMeals {
    switch (_selectedFilter) {
      case 'Classic':
        return _weeklyMealIdeas.where((meal) => !meal.isPlantBased).toList();
      case 'Ital / Vegan':
        return _weeklyMealIdeas.where((meal) => meal.isPlantBased).toList();
      default:
        return _weeklyMealIdeas;
    }
  }

  void _openMeal(_WeeklyMealIdea meal) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _EliteMealDetailsSheet(
          meal: meal,
          showShopAction: widget.onShopTap != null,
          onShopTap: () {
            Navigator.of(sheetContext).pop();
            Navigator.of(context).pop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onShopTap?.call();
            });
          },
        );
      },
    );
  }

  Widget _filterChip(String label) {
    final selected = _selectedFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) {
          if (!mounted) return;
          setState(() => _selectedFilter = label);
        },
        selectedColor: FarmColors.green,
        backgroundColor: FarmColors.card,
        side: BorderSide(
          color: selected ? FarmColors.green : FarmColors.line,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: TextStyle(
          color: selected ? Colors.white : FarmColors.deepGreen,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      ),
    );
  }

  Widget _todayHero(_WeeklyMealIdea meal) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 246,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _MealPhoto(meal: meal),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.16),
                    Colors.black.withOpacity(0.78),
                  ],
                  stops: const [0.0, 0.46, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.restaurant_menu_rounded,
                      size: 15,
                      color: FarmColors.warning,
                    ),
                    SizedBox(width: 5),
                    Text(
                      "TODAY'S PICK",
                      style: TextStyle(
                        color: FarmColors.deepGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.day,
                    style: const TextStyle(
                      color: Color(0xFFFFDCA4),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meal.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      height: 1.03,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _HeroMeta(
                        icon: Icons.schedule_rounded,
                        label: '${meal.preparationMinutes} min',
                      ),
                      const SizedBox(width: 8),
                      _HeroMeta(
                        icon: Icons.groups_rounded,
                        label: 'Serves ${meal.servings}',
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => _openMeal(meal),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: FarmColors.deepGreen,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 10,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View meal',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 15),
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

  Widget _dayStrip() {
    final today = DateTime.now().weekday;

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: _weeklyMealIdeas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final meal = _weeklyMealIdeas[index];
          final isToday = meal.weekday == today;

          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _openMeal(meal),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: isToday ? FarmColors.green : FarmColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isToday ? FarmColors.green : FarmColors.line,
                ),
                boxShadow: [
                  if (isToday)
                    BoxShadow(
                      color: FarmColors.green.withOpacity(0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    meal.shortDay,
                    style: TextStyle(
                      color: isToday ? Colors.white : FarmColors.mutedText,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Icon(
                    meal.isPlantBased
                        ? Icons.eco_rounded
                        : Icons.restaurant_rounded,
                    color: isToday ? Colors.white : FarmColors.green,
                    size: 20,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isToday ? 'Today' : '${meal.preparationMinutes}m',
                    style: TextStyle(
                      color: isToday
                          ? Colors.white.withOpacity(0.92)
                          : FarmColors.mutedText,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _mealCard(_WeeklyMealIdea meal) {
    final isToday = DateTime.now().weekday == meal.weekday;

    return FarmCard(
      padding: EdgeInsets.zero,
      color: isToday ? FarmColors.primarySoft : FarmColors.card,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openMeal(meal),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _MealPhoto(
                meal: meal,
                width: 92,
                height: 92,
                borderRadius: BorderRadius.circular(17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isToday ? '${meal.day} • Today' : meal.day,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FarmColors.green,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _DietaryBadge(meal: meal),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      meal.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 15.5,
                        height: 1.10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: FarmColors.mutedText,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${meal.preparationMinutes} min',
                          style: const TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.groups_rounded,
                          size: 14,
                          color: FarmColors.mutedText,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${meal.servings}',
                          style: const TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          height: 28,
                          width: 28,
                          decoration: BoxDecoration(
                            color: FarmColors.green,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 16,
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

  @override
  Widget build(BuildContext context) {
    final preferences = hpjCurrentUserExperiencePreferences;
    final preferPlantBased = preferences.dietaryStyle == 'vegan' ||
        preferences.dietaryStyle == 'vegetarian' ||
        preferences.recommendationStyle == 'vegan';
    final todayMeal = preferPlantBased
        ? _weeklyMealIdeas.firstWhere((meal) => meal.isPlantBased)
        : _mealForWeekday(DateTime.now().weekday);
    final filteredMeals = _filteredMeals;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("What's Cooking This Week?"),
        actions: [
          IconButton(
            tooltip: 'About meal ideas',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    title: const Text('Jamaican meal inspiration'),
                    content: const Text(
                      'These meals are flexible suggestions. Adjust ingredients, portions, and preparation to suit your household.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Got it'),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: FarmPage(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            _todayHero(todayMeal),
            if (preferences.showFreshReels) ...[
              const SizedBox(height: 16),
              FreshReelFeedPreviewCard(
                preferences: preferences,
                audience: 'customer',
                placement: freshReelPlacementMealPlanner,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your week at a glance',
                        style: TextStyle(
                          color: FarmColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap a day to preview the meal.',
                        style: TextStyle(
                          color: FarmColors.mutedText.withOpacity(0.94),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: FarmColors.accentSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '7 meals',
                    style: TextStyle(
                      color: FarmColors.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            _dayStrip(),
            const SizedBox(height: 20),
            const Text(
              'Explore the week',
              style: TextStyle(
                color: FarmColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Classic Jamaican favourites and a fresh Ital option.',
              style: TextStyle(
                color: FarmColors.mutedText,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 11),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All'),
                  _filterChip('Classic'),
                  _filterChip('Ital / Vegan'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...filteredMeals.map(
              (meal) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _mealCard(meal),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF5DE), Color(0xFFF3F8EC)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: FarmColors.line),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: FarmColors.warning,
                    size: 21,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Meal ideas are suggestions. Swap a day, change the protein, or choose the Ital option to suit your family.',
                      style: TextStyle(
                        color: FarmColors.warning,
                        fontWeight: FontWeight.w800,
                        height: 1.32,
                      ),
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
}

class _HeroMeta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroMeta({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.30),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DietaryBadge extends StatelessWidget {
  final _WeeklyMealIdea meal;

  const _DietaryBadge({required this.meal});

  @override
  Widget build(BuildContext context) {
    final background =
        meal.isPlantBased ? FarmColors.successSoft : FarmColors.accentSoft;
    final foreground =
        meal.isPlantBased ? FarmColors.green : FarmColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        meal.dietaryLabel,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EliteMealDetailsSheet extends StatelessWidget {
  final _WeeklyMealIdea meal;
  final bool showShopAction;
  final VoidCallback onShopTap;

  const _EliteMealDetailsSheet({
    required this.meal,
    required this.showShopAction,
    required this.onShopTap,
  });

  Widget _infoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
        decoration: BoxDecoration(
          color: FarmColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FarmColors.line),
        ),
        child: Column(
          children: [
            Icon(icon, color: FarmColors.green, size: 19),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: FarmColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: FarmColors.mutedText,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _ingredientWrap(
    List<String> ingredients, {
    required bool pantry,
    required BuildContext context,
  }) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: ingredients.map((ingredient) {
        final canShopIngredient = !pantry && showShopAction;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: canShopIngredient
                ? () {
                    final query = ingredient.trim();
                    if (query.isEmpty) return;

                    mealIngredientShopSearchRequest.value = null;
                    mealIngredientShopSearchRequest.value = query;
                    mealIngredientReturnLabel.value = query;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Searching shop for $query...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );

                    onShopTap();
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                color: pantry ? FarmColors.card : FarmColors.primarySoft,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: pantry
                      ? FarmColors.line
                      : FarmColors.green.withOpacity(0.16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    pantry
                        ? Icons.kitchen_outlined
                        : Icons.shopping_basket_outlined,
                    size: 13,
                    color: pantry ? FarmColors.mutedText : FarmColors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ingredient,
                    style: TextStyle(
                      color:
                          pantry ? FarmColors.mutedText : FarmColors.deepGreen,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (canShopIngredient) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: FarmColors.green,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    return Container(
      constraints: BoxConstraints(maxHeight: height * 0.93),
      decoration: const BoxDecoration(
        color: FarmColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            height: 5,
            width: 44,
            decoration: BoxDecoration(
              color: FarmColors.line,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _MealPhoto(meal: meal),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.50),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 14,
                            bottom: 13,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                meal.day,
                                style: const TextStyle(
                                  color: FarmColors.deepGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          meal.name,
                          style: const TextStyle(
                            color: FarmColors.ink,
                            fontSize: 25,
                            height: 1.04,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.35,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _DietaryBadge(meal: meal),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    meal.description,
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      fontWeight: FontWeight.w700,
                      height: 1.38,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _infoItem(
                        icon: Icons.schedule_rounded,
                        label: 'Preparation',
                        value: '${meal.preparationMinutes} min',
                      ),
                      const SizedBox(width: 8),
                      _infoItem(
                        icon: Icons.groups_rounded,
                        label: 'Household',
                        value: 'Serves ${meal.servings}',
                      ),
                      const SizedBox(width: 8),
                      _infoItem(
                        icon: Icons.signal_cellular_alt_rounded,
                        label: 'Difficulty',
                        value: meal.difficulty,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle(
                    'Nutrition highlights',
                    'General guidance based on the meal ingredients.',
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: meal.nutritionHighlights.map((nutrient) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: FarmColors.successSoft,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: FarmColors.green.withOpacity(0.18),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite_rounded,
                              color: FarmColors.green,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              nutrient,
                              style: const TextStyle(
                                color: FarmColors.deepGreen,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle(
                    'Fresh ingredients',
                    'Produce and fresh items you may need for this meal.',
                  ),
                  const SizedBox(height: 10),
                  _ingredientWrap(
                    meal.freshIngredients,
                    pantry: false,
                    context: context,
                  ),
                  const SizedBox(height: 18),
                  _sectionTitle(
                    'Pantry check',
                    'Optional items customers may already have at home.',
                  ),
                  const SizedBox(height: 10),
                  _ingredientWrap(
                    meal.pantryIngredients,
                    pantry: true,
                    context: context,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: FarmColors.accentSoft,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: FarmColors.accent.withOpacity(0.24),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: FarmColors.warning,
                          size: 20,
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Meal and nutrition information is general guidance. Portions, ingredients, and preparation may be adjusted for your household.',
                            style: TextStyle(
                              color: FarmColors.warning,
                              fontWeight: FontWeight.w800,
                              height: 1.32,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: showShopAction
                          ? onShopTap
                          : () => Navigator.of(context).pop(),
                      icon: Icon(
                        showShopAction
                            ? Icons.shopping_basket_rounded
                            : Icons.check_rounded,
                      ),
                      label: Text(
                        showShopAction ? 'Shop Fresh Ingredients' : 'Done',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: FarmColors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
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
}

class _CustomerHeaderWorkspaceButton
    extends StatelessWidget {
  const _CustomerHeaderWorkspaceButton();

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const OwnerWorkspaceSwitcherScreen(
          currentWorkspace: 'customer',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn ||
        supabase.auth.currentUser == null) {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: 'Switch Workspace',
      child: Material(
        color: FarmColors.cardSoft,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _open(context),
          child: const SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              Icons.apps_rounded,
              color: FarmColors.primary,
              size: 22,
            ),
          ),
        ),
      ),
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
                      'Fresh local produce, ready for you',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _CustomerHeaderWorkspaceButton(),
                    if (isLoggedIn)
                      const SizedBox(width: 7),
                    const FarmHeaderInboxButton(
                      size: 42,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FreshBoxLineItem {
  final Product product;
  int quantity;

  _FreshBoxLineItem({
    required this.product,
    this.quantity = 1,
  });

  double get unitPrice {
    if (product.effectivePrice > 0) return product.effectivePrice;
    return product.price;
  }

  double get lineTotal => unitPrice * quantity;
}

class _FreshBoxPlan {
  final List<_FreshBoxLineItem> items;
  final double budget;

  const _FreshBoxPlan({
    required this.items,
    required this.budget,
  });

  double get total {
    return items.fold<double>(0, (sum, item) => sum + item.lineTotal);
  }

  int get totalUnits {
    return items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  int get distinctItems => items.length;

  double get remaining {
    final value = budget - total;
    return value < 0 ? 0 : value;
  }

  int get budgetUsedPercent {
    if (budget <= 0) return 0;
    final percent = ((total / budget) * 100).round();
    if (percent < 0) return 0;
    if (percent > 100) return 100;
    return percent;
  }
}

class FreshBoxBuilderCard extends StatefulWidget {
  final List<Product> products;
  final void Function(Product product) onAddProduct;
  final VoidCallback onViewMyBox;

  // Optional image used when this builder appears
  // inside the Home swipe carousel.
  final String? heroImageUrl;

  const FreshBoxBuilderCard({
    super.key,
    required this.products,
    required this.onAddProduct,
    required this.onViewMyBox,
    this.heroImageUrl,
  });

  @override
  State<FreshBoxBuilderCard> createState() => _FreshBoxBuilderCardState();
}

class _FreshBoxBuilderCardState extends State<FreshBoxBuilderCard> {
  double selectedBudget = 3500;
  List<String> selectedNutrients = [];
  String selectedFamilySize = '2–3 people';

  final List<double> budgetOptions = const [
    2000,
    3500,
    5000,
    7500,
  ];

  final List<String> nutrientOptions = const [
    'Magnesium',
    'Iron',
    'Fiber',
    'Potassium',
    'Vitamin C',
    'Protein',
    'Calcium',
    'Antioxidants',
  ];

  final List<String> familySizeOptions = const [
    '1 person',
    '2–3 people',
    '4–5 people',
    '6+ people',
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_restoreSmartFreshBoxDefaults());
  }

  Future<void> _restoreSmartFreshBoxDefaults() async {
    final budget = await HpjSmartLocalStore.readDouble('fresh_box_budget');
    final family = await HpjSmartLocalStore.readString('fresh_box_family');
    final nutrients =
        await HpjSmartLocalStore.readStringList('fresh_box_nutrients');

    if (!mounted) return;

    setState(() {
      if (budget != null && budgetOptions.contains(budget)) {
        selectedBudget = budget;
      }
      if (family != null && familySizeOptions.contains(family)) {
        selectedFamilySize = family;
      }
      selectedNutrients = nutrients
          .where(nutrientOptions.contains)
          .take(3)
          .toList(growable: true);
    });
  }

  Future<void> _saveSmartFreshBoxDefaults() async {
    await Future.wait<void>([
      HpjSmartLocalStore.writeDouble('fresh_box_budget', selectedBudget),
      HpjSmartLocalStore.writeString('fresh_box_family', selectedFamilySize),
      HpjSmartLocalStore.writeStringList(
        'fresh_box_nutrients',
        selectedNutrients,
      ),
    ]);
  }

  int get _minimumDistinctItems {
    switch (selectedFamilySize) {
      case '1 person':
        return 4;
      case '2–3 people':
        return 6;
      case '4–5 people':
        return 8;
      case '6+ people':
        return 10;
      default:
        return 6;
    }
  }

  int get _maximumDistinctItems {
    switch (selectedFamilySize) {
      case '1 person':
        return 6;
      case '2–3 people':
        return 9;
      case '4–5 people':
        return 12;
      case '6+ people':
        return 15;
      default:
        return 9;
    }
  }

  int get _maxQuantityPerLine {
    switch (selectedFamilySize) {
      case '1 person':
        return 2;
      case '2–3 people':
        return 3;
      case '4–5 people':
        return 4;
      case '6+ people':
        return 5;
      default:
        return 3;
    }
  }

  String _nutrientKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Set<String> _normalizedSet(List<String> values) {
    return values.map(_nutrientKey).where((value) => value.isNotEmpty).toSet();
  }

  bool _containsNutrient(List<String> values, String nutrient) {
    return _normalizedSet(values).contains(_nutrientKey(nutrient));
  }

  int _tagLevelForProduct(Product product, String nutrient) {
    if (_containsNutrient(product.nutrientStrong, nutrient)) return 3;
    if (_containsNutrient(product.nutrientGood, nutrient)) return 2;
    if (_containsNutrient(product.nutrientContains, nutrient)) return 1;
    return 0;
  }

  bool _productHasAnySelectedTag(Product product) {
    return selectedNutrients.any((nutrient) {
      return _tagLevelForProduct(product, nutrient) > 0;
    });
  }

  int _selectedTagScore(Product product) {
    int score = 0;
    int matchCount = 0;

    for (final nutrient in selectedNutrients) {
      final level = _tagLevelForProduct(product, nutrient);
      if (level > 0) {
        matchCount += 1;
        score += level * 100;
      }
    }

    if (matchCount > 1) score += matchCount * 70;
    if (matchCount >= selectedNutrients.length &&
        selectedNutrients.length > 1) {
      score += 90;
    }
    if (product.nutritionVerified) score += 18;

    return score;
  }

  List<String> _priorityTermsForNutrient(String nutrient) {
    switch (nutrient) {
      case 'Magnesium':
        return [
          'callaloo',
          'spinach',
          'pumpkin seed',
          'seed',
          'avocado',
          'banana',
          'sweet potato',
          'breadfruit',
          'beans',
          'peas',
          'okra',
        ];
      case 'Iron':
        return [
          'callaloo',
          'spinach',
          'peas',
          'beans',
          'pumpkin seed',
          'seed',
          'egg',
          'okra',
        ];
      case 'Fiber':
        return [
          'okra',
          'callaloo',
          'cabbage',
          'sweet potato',
          'yam',
          'beans',
          'peas',
          'avocado',
          'soursop',
          'sweet sop',
          'star apple',
          'guava',
          'carrot',
          'pumpkin',
          'breadfruit',
          'plantain',
        ];
      case 'Potassium':
        return [
          'banana',
          'plantain',
          'avocado',
          'sweet potato',
          'yam',
          'breadfruit',
          'coconut',
          'tomato',
          'callaloo',
        ];
      case 'Vitamin C':
        return [
          'lime',
          'orange',
          'guava',
          'pineapple',
          'sweet pepper',
          'pepper',
          'cabbage',
          'tomato',
          'soursop',
          'sweet sop',
        ];
      case 'Protein':
        return [
          'egg',
          'beans',
          'peas',
          'peanut',
          'seed',
          'dairy',
          'yogurt',
        ];
      case 'Calcium':
        return [
          'callaloo',
          'spinach',
          'cabbage',
          'dairy',
          'milk',
          'cheese',
          'yogurt',
          'seed',
        ];
      case 'Antioxidants':
        return [
          'sorrel',
          'berry',
          'guava',
          'tomato',
          'pepper',
          'turmeric',
          'ginger',
          'cabbage',
          'callaloo',
          'soursop',
          'sweet sop',
          'star apple',
        ];
      default:
        return [
          'vegetable',
          'fruit',
          'ground provision',
          'herb',
        ];
    }
  }

  List<String> _selectedPriorityTerms() {
    final terms = <String>{};
    for (final nutrient in selectedNutrients) {
      terms.addAll(_priorityTermsForNutrient(nutrient));
    }
    return terms.toList();
  }

  String _singleNutrientDescription(String nutrient) {
    switch (nutrient) {
      case 'Magnesium':
        return 'Fresh foods commonly associated with magnesium.';
      case 'Iron':
        return 'Fresh picks that can help add more iron-containing foods.';
      case 'Fiber':
        return 'More filling produce choices that naturally contain fiber.';
      case 'Potassium':
        return 'Fruit and produce commonly known for potassium.';
      case 'Vitamin C':
        return 'Bright produce choices commonly linked with vitamin C.';
      case 'Protein':
        return 'Simple staples that can help add more protein-containing foods.';
      case 'Calcium':
        return 'Fresh picks commonly associated with calcium-containing foods.';
      case 'Antioxidants':
        return 'Colourful produce and herbs commonly linked with antioxidants.';
      default:
        return 'Fresh items selected from available stock.';
    }
  }

  String _nutritionMixLabel() {
    if (selectedNutrients.isEmpty) return 'Harvest Mix';
    if (selectedNutrients.length == 1) return selectedNutrients.first;

    return selectedNutrients.join(' + ');
  }

  String _nutritionMixDescription() {
    if (selectedNutrients.isEmpty) {
      return 'Fresh picks selected from your budget, family size, and available stock.';
    }

    if (selectedNutrients.length == 1) {
      return _singleNutrientDescription(selectedNutrients.first);
    }

    return 'Fresh picks selected from your ${selectedNutrients.length}-nutrient mix.';
  }

  String _planTitle() {
    return '${_nutritionMixLabel()} Fresh Box';
  }

  double _priceOf(Product product) {
    final price = product.effectivePrice;
    if (price > 0) return price;

    if (product.price > 0) return product.price;

    return 0;
  }

  bool _matchesSelectedTerms(Product product) {
    if (selectedNutrients.isEmpty) return true;

    final terms = _selectedPriorityTerms()
        .map((term) => term.trim().toLowerCase())
        .where((term) => term.isNotEmpty)
        .toList();

    if (terms.isEmpty) return true;

    final text = [
      product.name,
      product.category,
      product.description ?? '',
      product.unit ?? '',
    ].join(' ').toLowerCase();

    return terms.any((term) => text.contains(term));
  }

  bool _isRepeatFriendly(Product product) {
    final text = [
      product.name,
      product.category,
      product.description ?? '',
      product.unit ?? '',
    ].join(' ').toLowerCase();

    return text.contains('yam') ||
        text.contains('potato') ||
        text.contains('sweet potato') ||
        text.contains('banana') ||
        text.contains('plantain') ||
        text.contains('egg') ||
        text.contains('fruit') ||
        text.contains('vegetable') ||
        text.contains('ground provision') ||
        text.contains('cucumber') ||
        text.contains('tomato') ||
        text.contains('herb');
  }

  double _priorityScore(Product product, List<String> terms) {
    double score = _selectedTagScore(product).toDouble();

    if (score <= 0) {
      final text = [
        product.name,
        product.category,
        product.description ?? '',
        product.unit ?? '',
      ].join(' ').toLowerCase();

      for (final term in terms) {
        if (text.contains(term.toLowerCase())) {
          score += 3;
        }
      }
    }

    if (_isRepeatFriendly(product)) score += 2;

    final price = _priceOf(product);
    if (price >= selectedBudget * 0.08) score += 1.5;
    if (price >= selectedBudget * 0.12) score += 1.0;

    return score;
  }

  int _availableStockFor(Product product) {
    final stock = product.stockQuantity;
    if (stock <= 0) return 0;
    return stock;
  }

  List<Product> _rankedNutritionProducts(List<Product> available) {
    final taggedMatches = available.where(_productHasAnySelectedTag).toList();

    final candidates = taggedMatches.isNotEmpty
        ? taggedMatches
        : available.where(_matchesSelectedTerms).toList();

    final terms = _selectedPriorityTerms();

    candidates.sort((a, b) {
      final tagScoreCompare =
          _selectedTagScore(b).compareTo(_selectedTagScore(a));
      if (tagScoreCompare != 0) return tagScoreCompare;

      final priorityCompare =
          _priorityScore(b, terms).compareTo(_priorityScore(a, terms));
      if (priorityCompare != 0) return priorityCompare;

      return _priceOf(b).compareTo(_priceOf(a));
    });

    return candidates;
  }

  _FreshBoxPlan _buildFreshBoxPlan() {
    final budget = selectedBudget;

    final available = widget.products.where((product) {
      return product.canAddToCart &&
          product.name.trim().isNotEmpty &&
          _priceOf(product) > 0 &&
          _priceOf(product) <= budget;
    }).toList();

    if (available.isEmpty) {
      return _FreshBoxPlan(
        items: const <_FreshBoxLineItem>[],
        budget: budget,
      );
    }

    final rankedProducts = _rankedNutritionProducts(available);

    if (rankedProducts.isEmpty) {
      return _FreshBoxPlan(
        items: const <_FreshBoxLineItem>[],
        budget: budget,
      );
    }

    final terms = _selectedPriorityTerms();

    final items = <_FreshBoxLineItem>[];
    final itemMap = <String, _FreshBoxLineItem>{};
    final usedCategories = <String>{};

    double total = 0;

    double cheapestPrice = _priceOf(rankedProducts.first);
    for (final product in rankedProducts) {
      final price = _priceOf(product);
      if (price < cheapestPrice) cheapestPrice = price;
    }

    bool canAddUnit(Product product) {
      return total + _priceOf(product) <= budget;
    }

    void addNewLine(Product product) {
      final line = _FreshBoxLineItem(product: product, quantity: 1);
      items.add(line);
      itemMap[product.id] = line;
      usedCategories.add(product.category.toLowerCase());
      total += line.unitPrice;
    }

    bool addQuantity(Product product) {
      final line = itemMap[product.id];
      if (line == null) return false;
      if (line.quantity >= _maxQuantityPerLine) return false;
      if (line.quantity >= _availableStockFor(product)) return false;
      if (!canAddUnit(product)) return false;

      line.quantity += 1;
      total += line.unitPrice;
      return true;
    }

    // Pass 1: build a diverse base from products that match the nutrition mix.
    for (final product in rankedProducts) {
      if (items.length >= _minimumDistinctItems) break;
      if (itemMap.containsKey(product.id)) continue;
      if (!canAddUnit(product)) continue;

      final category = product.category.toLowerCase();
      final hasEnoughVariety = usedCategories.length >= 3 ||
          items.length >= _minimumDistinctItems - 1;

      if (usedCategories.contains(category) && !hasEnoughVariety) {
        continue;
      }

      addNewLine(product);
    }

    // Pass 2: if strict variety blocked useful matches, add remaining matched items.
    for (final product in rankedProducts) {
      if (items.length >= _minimumDistinctItems) break;
      if (itemMap.containsKey(product.id)) continue;
      if (!canAddUnit(product)) continue;

      addNewLine(product);
    }

    // Pass 3: add more matched items if the budget allows.
    for (final product in rankedProducts) {
      if (items.length >= _maximumDistinctItems) break;
      if (itemMap.containsKey(product.id)) continue;
      if (!canAddUnit(product)) continue;
      if (budget - total < cheapestPrice) break;

      addNewLine(product);

      if ((total / budget) >= 0.78) break;
    }

    // Pass 4: increase quantities only from matched products.
    bool improved = true;
    while (improved) {
      improved = false;

      final repeatable = items.where((item) {
        return _isRepeatFriendly(item.product) ||
            _selectedTagScore(item.product) > 0;
      }).toList()
        ..sort((a, b) {
          final scoreCompare = _priorityScore(
            b.product,
            terms,
          ).compareTo(_priorityScore(a.product, terms));
          if (scoreCompare != 0) return scoreCompare;
          return b.unitPrice.compareTo(a.unitPrice);
        });

      for (final line in repeatable) {
        if (addQuantity(line.product)) {
          improved = true;

          if ((budget - total) < cheapestPrice) break;
          if ((total / budget) >= 0.93) break;
        }
      }

      if ((budget - total) < cheapestPrice) break;
      if ((total / budget) >= 0.93) break;
    }

    items.sort((a, b) {
      final tagCompare =
          _selectedTagScore(b.product).compareTo(_selectedTagScore(a.product));
      if (tagCompare != 0) return tagCompare;

      final categoryCompare = a.product.category.toLowerCase().compareTo(
            b.product.category.toLowerCase(),
          );
      if (categoryCompare != 0) return categoryCompare;
      return b.lineTotal.compareTo(a.lineTotal);
    });

    return _FreshBoxPlan(
      items: items,
      budget: budget,
    );
  }

  String _statusText(_FreshBoxPlan plan) {
    if (plan.budgetUsedPercent >= 90) {
      return 'Excellent match';
    }
    if (plan.budgetUsedPercent >= 75) {
      return 'Strong match';
    }
    if (plan.budgetUsedPercent >= 55) {
      return 'Balanced box';
    }
    return 'Nutrition match';
  }

  void _toggleNutrient({
    required BuildContext context,
    required String nutrient,
    required void Function(VoidCallback action) updateDialog,
  }) {
    final selected = selectedNutrients.contains(nutrient);

    if (!selected && selectedNutrients.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose up to 3 nutrients for a focused box.'),
        ),
      );
      return;
    }

    updateDialog(() {
      if (selected) {
        selectedNutrients = selectedNutrients
            .where((item) => item != nutrient)
            .toList(growable: true);
      } else {
        selectedNutrients = [...selectedNutrients, nutrient];
      }
    });
    unawaited(_saveSmartFreshBoxDefaults());
  }

  Future<void> _openBuilder() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final plan = _buildFreshBoxPlan();

            void updateDialog(VoidCallback action) {
              setDialogState(action);
              if (mounted) setState(() {});
            }

            Future<void> addPlanToBox() async {
              if (plan.items.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'No matching items are available for this box right now.',
                    ),
                  ),
                );
                return;
              }

              for (final item in plan.items) {
                for (int i = 0; i < item.quantity; i++) {
                  widget.onAddProduct(item.product);
                }
              }

              if (Navigator.of(sheetContext).canPop()) {
                Navigator.of(sheetContext).pop();
              }

              if (!mounted) return;

              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${plan.totalUnits} items added to My Box.',
                  ),
                ),
              );

              widget.onViewMyBox();
            }

            return Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
                ),
                decoration: const BoxDecoration(
                  color: FarmColors.cream,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: FarmColors.line,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: FarmColors.primarySoft,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.shopping_basket_rounded,
                              color: FarmColors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Build Your Fresh Box',
                                  style: TextStyle(
                                    color: FarmColors.ink,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    height: 1.05,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Build a fresh basket matched to your nutrition mix, family size, and budget.',
                                  style: TextStyle(
                                    color: FarmColors.mutedText,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      if (hpjCurrentUserExperiencePreferences.showFreshReels) ...[
                        const SizedBox(height: 16),
                        FreshReelFeedPreviewCard(
                          preferences: hpjCurrentUserExperiencePreferences,
                          audience: 'customer',
                          placement: freshReelPlacementFreshBox,
                          onAddToCart: widget.onAddProduct,
                        ),
                      ],
                      const SizedBox(height: 20),
                      const Text(
                        'Budget',
                        style: TextStyle(
                          color: FarmColors.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: budgetOptions.map((budget) {
                          final selected = selectedBudget == budget;
                          return ChoiceChip(
                            selected: selected,
                            label: Text(formatJmd(budget)),
                            onSelected: (_) {
                              updateDialog(() {
                                selectedBudget = budget;
                              });
                              unawaited(_saveSmartFreshBoxDefaults());
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Nutrition mix',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            '${selectedNutrients.length}/3 selected',
                            style: const TextStyle(
                              color: FarmColors.mutedText,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Choose up to 3 nutrients for a focused fresh box.',
                        style: TextStyle(
                          color: FarmColors.mutedText,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: nutrientOptions.map((nutrient) {
                          final selected = selectedNutrients.contains(nutrient);
                          return ChoiceChip(
                            selected: selected,
                            label: Text(nutrient),
                            avatar: selected
                                ? const Icon(Icons.check_rounded, size: 16)
                                : null,
                            onSelected: (_) {
                              _toggleNutrient(
                                context: context,
                                nutrient: nutrient,
                                updateDialog: updateDialog,
                              );
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Family size',
                        style: TextStyle(
                          color: FarmColors.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: familySizeOptions.map((size) {
                          final selected = selectedFamilySize == size;
                          return ChoiceChip(
                            selected: selected,
                            label: Text(size),
                            onSelected: (_) {
                              updateDialog(() {
                                selectedFamilySize = size;
                              });
                              unawaited(_saveSmartFreshBoxDefaults());
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: FarmColors.lightGreen,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: FarmColors.green.withOpacity(0.13),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _planTitle(),
                              style: const TextStyle(
                                color: FarmColors.ink,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _nutritionMixDescription(),
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.74),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _statusText(plan),
                                    style: const TextStyle(
                                      color: FarmColors.green,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${plan.budgetUsedPercent}% of budget used',
                                  style: const TextStyle(
                                    color: FarmColors.mutedText,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _FreshBoxSummaryPill(
                                    label: 'Units',
                                    value: '${plan.totalUnits}',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _FreshBoxSummaryPill(
                                    label: 'Total',
                                    value: formatJmd(plan.total),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _FreshBoxSummaryPill(
                                    label: 'Used',
                                    value: '${plan.budgetUsedPercent}%',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Budget: ${formatJmd(selectedBudget)} • Remaining: ${formatJmd(plan.remaining)}',
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (plan.items.isEmpty)
                        const FarmCard(
                          child: Text(
                            'No fresh box could be created from available stock right now. Try a higher budget or another nutrition mix.',
                            style: TextStyle(
                              color: FarmColors.mutedText,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        )
                      else
                        ...plan.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _FreshBoxProductTile(
                              item: item,
                              focusNutrients: selectedNutrients,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_shopping_cart_outlined),
                          label: const Text('Add Fresh Box to My Box'),
                          onPressed: addPlanToBox,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try another budget'),
                          onPressed: () {
                            updateDialog(() {
                              if (selectedBudget == 2000) {
                                selectedBudget = 3500;
                              } else if (selectedBudget == 3500) {
                                selectedBudget = 5000;
                              } else if (selectedBudget == 5000) {
                                selectedBudget = 7500;
                              } else {
                                selectedBudget = 2000;
                              }
                            });
                          },
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableCount =
        widget.products.where((product) => product.canAddToCart).length;

    final previewMix = _nutritionMixLabel();

    return _HPJSwipePromoCard(
      style: _HPJHeroStyle.freshBox,
      eyebrow: 'FRESH BOX',
      title: 'Build a box around your life.',
      subtitle:
          'Fresh Jamaican produce selected around your budget and nutrition preferences.',
      badges: [
        previewMix,
        '$availableCount available',
      ],
      ctaLabel: 'Build My Box',
      imageUrl: widget.heroImageUrl,
      fallbackIcon: Icons.shopping_basket_rounded,
      onTap: _openBuilder,
    );
  }
} // ADD THIS BRACE

class _FreshBoxSummaryPill extends StatelessWidget {
  final String label;
  final String value;

  const _FreshBoxSummaryPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FarmColors.green,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _FreshBoxProductTile extends StatelessWidget {
  final _FreshBoxLineItem item;
  final List<String> focusNutrients;

  const _FreshBoxProductTile({
    required this.item,
    this.focusNutrients = const [],
  });

  String _nutrientKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _containsNutrient(List<String> values, String nutrient) {
    final key = _nutrientKey(nutrient);
    return values.any((value) => _nutrientKey(value) == key);
  }

  String _matchLabel(Product product) {
    for (final nutrient in focusNutrients) {
      if (_containsNutrient(product.nutrientStrong, nutrient)) {
        return 'Strong $nutrient pick';
      }
    }

    for (final nutrient in focusNutrients) {
      if (_containsNutrient(product.nutrientGood, nutrient)) {
        return 'Good $nutrient pick';
      }
    }

    for (final nutrient in focusNutrients) {
      if (_containsNutrient(product.nutrientContains, nutrient)) {
        return 'Contains $nutrient';
      }
    }

    if (focusNutrients.isNotEmpty) {
      return '${focusNutrients.first} pick';
    }

    return 'Fresh pick';
  }

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final matchLabel = _matchLabel(product);

    return FarmCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ProductVisual(product: product, size: 52),
          const SizedBox(width: 12),
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
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${product.category} • ${product.unit ?? 'each'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: FarmColors.primarySoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Qty ${item.quantity}',
                        style: const TextStyle(
                          color: FarmColors.green,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: FarmColors.lightGreen,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: FarmColors.green.withOpacity(0.12),
                        ),
                      ),
                      child: Text(
                        matchLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FarmColors.green,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Text(
                      '${product.formattedEffectivePrice} each',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatJmd(item.lineTotal),
            style: const TextStyle(
              color: FarmColors.green,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
// ===============================================================
// HPJ HOME SWIPE PROMOTIONAL CARD
// ===============================================================

enum _HPJHeroStyle {
  freshBox,
  meals,
  deals,
  farm,
}

class _HPJSwipePromoCard extends StatelessWidget {
  final _HPJHeroStyle style;
  final String eyebrow;
  final String title;
  final String subtitle;

  // Keep meta for compatibility with the other
  // carousel cards while we upgrade them.
  final String? meta;

  final List<String> badges;
  final String ctaLabel;
  final String? imageUrl;
  final IconData fallbackIcon;
  final VoidCallback onTap;

  const _HPJSwipePromoCard({
    this.style = _HPJHeroStyle.freshBox,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onTap,
    this.meta,
    this.badges = const [],
    this.imageUrl,
    this.fallbackIcon = Icons.eco_rounded,
  });

  bool get _lightText {
    return style == _HPJHeroStyle.meals || style == _HPJHeroStyle.farm;
  }

  Color get _accentColor {
    switch (style) {
      case _HPJHeroStyle.freshBox:
        return const Color(0xFF24543A);

      case _HPJHeroStyle.meals:
        return const Color(0xFFA67C3B);

      case _HPJHeroStyle.deals:
        return const Color(0xFF8E6A2F);

      case _HPJHeroStyle.farm:
        return const Color(0xFF355E43);
    }
  }

  Color get _fallbackBackground {
    switch (style) {
      case _HPJHeroStyle.freshBox:
        return const Color(0xFFF6F4EE);

      case _HPJHeroStyle.meals:
        return const Color(0xFF22382B);

      case _HPJHeroStyle.deals:
        return const Color(0xFFF5EFE2);

      case _HPJHeroStyle.farm:
        return const Color(0xFF1F3428);
    }
  }

  List<Color> get _gradientColors {
    switch (style) {
      case _HPJHeroStyle.freshBox:
        return [
          const Color(0xFFF8F6F0),
          const Color(0xFFF2EFE6).withOpacity(0.98),
          const Color(0xFFE7E0CF).withOpacity(0.82),
          const Color(0xFFE7E0CF).withOpacity(0.22),
          Colors.transparent,
        ];

      case _HPJHeroStyle.meals:
        return [
          const Color(0xFF1C3126).withOpacity(0.98),
          const Color(0xFF1C3126).withOpacity(0.93),
          const Color(0xFF1C3126).withOpacity(0.70),
          const Color(0xFF1C3126).withOpacity(0.22),
          Colors.transparent,
        ];

      case _HPJHeroStyle.deals:
        return [
          const Color(0xFFF8F4EA).withOpacity(0.99),
          const Color(0xFFF2EADA).withOpacity(0.96),
          const Color(0xFFE2CFAB).withOpacity(0.72),
          const Color(0xFFE2CFAB).withOpacity(0.22),
          Colors.transparent,
        ];

      case _HPJHeroStyle.farm:
        return [
          const Color(0xFF193125).withOpacity(0.98),
          const Color(0xFF193125).withOpacity(0.93),
          const Color(0xFF193125).withOpacity(0.68),
          const Color(0xFF193125).withOpacity(0.20),
          Colors.transparent,
        ];
    }
  }

  String? _usableImageUrl() {
    final raw = imageUrl?.trim() ?? '';

    if (raw.isEmpty) {
      return null;
    }

    return cleanHostedImageUrl(raw) ?? raw;
  }

  Widget _buildBackground() {
    final url = _usableImageUrl();

    if (url == null) {
      return Container(
        color: _fallbackBackground,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        child: Icon(
          fallbackIcon,
          size: 86,
          color: _accentColor.withOpacity(0.25),
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      gaplessPlayback: true,
      cacheWidth: 1200,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }

        return Container(
          color: _fallbackBackground,
        );
      },
      errorBuilder: (_, __, ___) {
        return Container(
          color: _fallbackBackground,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 28),
          child: Icon(
            fallbackIcon,
            size: 86,
            color: _accentColor.withOpacity(0.25),
          ),
        );
      },
    );
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _lightText
            ? Colors.white.withOpacity(0.16)
            : Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _lightText
              ? Colors.white.withOpacity(0.16)
              : FarmColors.green.withOpacity(0.10),
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _lightText ? Colors.white : FarmColors.deepGreen,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayBadges = <String>[
      ...badges.where((item) => item.trim().isNotEmpty),
      if (badges.isEmpty && meta != null && meta!.trim().isNotEmpty)
        meta!.trim(),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.black.withOpacity(0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: _fallbackBackground,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildBackground(),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: _lightText
                        ? [
                            // Dark-photo slides:
                            // This Week, Deals, etc.
                            Colors.black.withOpacity(0.62),
                            Colors.black.withOpacity(0.44),
                            Colors.black.withOpacity(0.16),
                            Colors.transparent,
                          ]
                        : [
                            // Light slides:
                            // Fresh Box, etc.
                            const Color(0xFFF7F4E8).withOpacity(0.92),
                            const Color(0xFFF7F4E8).withOpacity(0.72),
                            const Color(0xFFF7F4E8).withOpacity(0.20),
                            Colors.transparent,
                          ],
                    stops: const [
                      0.00,
                      0.38,
                      0.68,
                      1.00,
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -22,
                right: -18,
                child: IgnorePointer(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _lightText
                          ? Colors.white.withOpacity(0.05)
                          : _accentColor.withOpacity(0.08),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  19,
                  17,
                  17,
                  17,
                ),
                child: FractionallySizedBox(
                  widthFactor: 0.76,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _lightText
                              ? Colors.black.withOpacity(0.18)
                              : Colors.white.withOpacity(0.84),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          eyebrow.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _lightText ? Colors.white : FarmColors.green,
                            fontSize: 8.8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.75,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              _lightText ? Colors.white : FarmColors.deepGreen,
                          fontSize: 24,
                          height: 0.99,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _lightText
                              ? Colors.white.withOpacity(0.98)
                              : const Color(0xFF23402F),
                          fontSize: 11.3,
                          height: 1.28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.05,
                          shadows: _lightText
                              ? [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : const [],
                        ),
                      ),
                      if (displayBadges.isNotEmpty) ...[
                        const SizedBox(height: 11),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children:
                              displayBadges.take(2).map(_infoChip).toList(),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Container(
                        height: 38,
                        padding: const EdgeInsets.fromLTRB(
                          14,
                          0,
                          6,
                          0,
                        ),
                        decoration: BoxDecoration(
                          color: _accentColor,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: _accentColor.withOpacity(0.20),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ctaLabel,
                              style: TextStyle(
                                color: style == _HPJHeroStyle.meals
                                    ? FarmColors.deepGreen
                                    : Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 27,
                              height: 27,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 15,
                                color: style == _HPJHeroStyle.meals
                                    ? FarmColors.deepGreen
                                    : Colors.white,
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
          ),
        ),
      ),
    );
  }
}
// ===============================================================
// HPJ PREMIUM HOME SWIPE CAROUSEL
// ===============================================================

class _HPJHomeNavItem {
  final String label;
  final Color accent;

  const _HPJHomeNavItem({
    required this.label,
    required this.accent,
  });
}

class HPJHomeSwipeCarousel extends StatefulWidget {
  final List<Product> products;
  final List<HomeHeroSlide> heroSlides;
  final void Function(Product product) onAddProduct;
  final VoidCallback onViewMyBox;
  final VoidCallback onShopTap;
  final VoidCallback onDealsTap;
  final bool showMealIdeas;
  final bool showFarmStories;

  const HPJHomeSwipeCarousel({
    super.key,
    required this.products,
    required this.heroSlides,
    required this.onAddProduct,
    required this.onViewMyBox,
    required this.onShopTap,
    required this.onDealsTap,
    this.showMealIdeas = true,
    this.showFarmStories = true,
  });

  @override
  State<HPJHomeSwipeCarousel> createState() => _HPJHomeSwipeCarouselState();
}

class _HPJHomeSwipeCarouselState extends State<HPJHomeSwipeCarousel> {
  late final PageController _pageController;

  int _currentPage = 0;

  static const int _cardCount = 4;

  List<_HPJHomeNavItem> get _navItems => [
        const _HPJHomeNavItem(
          label: 'Fresh Box',
          accent: Color(0xFF25613D),
        ),
        _HPJHomeNavItem(
          label: widget.showMealIdeas ? 'This Week' : 'Seasonal',
          accent: const Color(0xFF9A6A18),
        ),
        const _HPJHomeNavItem(
          label: 'Deals',
          accent: Color(0xFFB6533C),
        ),
        const _HPJHomeNavItem(
          label: 'Pulse',
          accent: Color(0xFF2E6B45),
        ),
      ];

  @override
  void initState() {
    super.initState();

    _pageController = PageController(
      viewportFraction: 0.94,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  String? _productImage(Product? product) {
    final image = product?.imageUrl?.trim() ?? '';

    if (image.isEmpty) {
      return null;
    }

    return image;
  }

  Product? _findDealProduct() {
    for (final product in widget.products) {
      if (product.canAddToCart &&
          product.hasActiveDiscount &&
          _productImage(product) != null) {
        return product;
      }
    }

    return null;
  }

  Product? _findFarmProduct() {
    // First choice: recently harvested Jamaican produce.
    for (final product in widget.products) {
      if (product.canAddToCart &&
          product.isLocal &&
          isProductHarvestedThisWeek(product) &&
          _productImage(product) != null) {
        return product;
      }
    }

    // Second choice: any local product with an image.
    for (final product in widget.products) {
      if (product.canAddToCart &&
          product.isLocal &&
          _productImage(product) != null) {
        return product;
      }
    }

    return null;
  }

  Product? _findGeneralImageProduct() {
    for (final product in widget.products) {
      if (product.canAddToCart && _productImage(product) != null) {
        return product;
      }
    }

    return null;
  }

  void _openWeeklyMeals() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WeeklyMealIdeasScreen(
          onShopTap: widget.onShopTap,
        ),
      ),
    );
  }

  Widget _buildQuickNavigation() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(right: 8),
        itemCount: _navItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _navItems[index];
          final selected = index == _currentPage;

          final accent = item.accent;

          return AnimatedScale(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            scale: selected ? 1.0 : 0.985,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _goToPage(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? accent : accent.withOpacity(0.065),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? accent : accent.withOpacity(0.17),
                      width: 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: accent.withOpacity(0.16),
                              blurRadius: 13,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : const [],
                  ),
                  child: Center(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      style: TextStyle(
                        color: selected ? Colors.white : accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.10,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _cardCount,
        (index) {
          final active = index == _currentPage;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            height: 6,
            width: active ? 22 : 6,
            decoration: BoxDecoration(
              color: active
                  ? FarmColors.green
                  : FarmColors.green.withOpacity(0.16),
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultSlides = widget.heroSlides.isNotEmpty
        ? widget.heroSlides
        : defaultHomeHeroSlides();

    final String? freshBoxImage =
        defaultSlides.isNotEmpty ? defaultSlides[0].imageUrl : null;

    final String? mealsImage =
        defaultSlides.length > 1 ? defaultSlides[1].imageUrl : freshBoxImage;

    final String? dealsImage =
        defaultSlides.length > 2 ? defaultSlides[2].imageUrl : mealsImage;

    final String? farmImage =
        defaultSlides.length > 2 ? defaultSlides[2].imageUrl : freshBoxImage;

    final dealProduct = _findDealProduct();
    final farmProduct = _findFarmProduct();
    final generalProduct = _findGeneralImageProduct();

    final freshPick = farmProduct;

final freshPickName =
    freshPick?.name.trim() ?? '';

final hasFreshPick =
    freshPick != null &&
    freshPick.canAddToCart &&
    freshPick.isLocal &&
    isProductHarvestedThisWeek(freshPick);

    final meal = _mealForWeekday(
      DateTime.now().weekday,
    );

    final availableCount =
        widget.products.where((product) => product.canAddToCart).length;

    final dealCount = widget.products
        .where(
          (product) => product.canAddToCart && product.hasActiveDiscount,
        )
        .length;

    final localCount = widget.products
        .where(
          (product) => product.canAddToCart && product.isLocal,
        )
        .length;

    final harvestedCount = widget.products
        .where(
          (product) =>
              product.canAddToCart &&
              product.isLocal &&
              isProductHarvestedThisWeek(product),
        )
        .length;

    final farmName =
        (farmProduct?.farmName ?? farmProduct?.farmerName ?? '').trim();

    final screenWidth = MediaQuery.sizeOf(context).width;

    final double heroHeight;

    if (screenWidth < 360) {
      heroHeight = 250;
    } else if (screenWidth >= 700) {
      heroHeight = 276;
    } else {
      heroHeight = 260;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // -------------------------------------------------------
        // AMAZON-STYLE QUICK DISCOVERY ROW
        // -------------------------------------------------------

        _buildQuickNavigation(),

        const SizedBox(height: 13),

        // -------------------------------------------------------
        // LARGE PREMIUM HERO CARDS
        // -------------------------------------------------------

        SizedBox(
          height: heroHeight,
          child: PageView.builder(
            controller: _pageController,
            padEnds: false,
            pageSnapping: true,
            physics: const BouncingScrollPhysics(),
            itemCount: _cardCount,
            onPageChanged: (index) {
              if (!mounted) return;

              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              Widget card;

              // =================================================
              // 1 — FRESH BOX
              // =================================================

              if (index == 0) {
                card = FreshBoxBuilderCard(
                  products: widget.products,
                  onAddProduct: widget.onAddProduct,
                  onViewMyBox: widget.onViewMyBox,
                  // CARD 1 — FRESH BOX
                  heroImageUrl: freshBoxImage ?? _productImage(generalProduct),
                );
              }

              // =================================================
              // 2 — WHAT'S COOKING
              // =================================================

              else if (index == 1) {
                if (widget.showMealIdeas) {
                  card = _HPJSwipePromoCard(
                    style: _HPJHeroStyle.meals,
                    eyebrow: 'WHAT’S COOKING',
                    title: meal.name,
                    subtitle:
                        'Plan a Jamaican meal and shop the fresh ingredients in one place.',
                    badges: [
                      meal.dietaryLabel,
                      '${meal.preparationMinutes} min',
                    ],
                    ctaLabel: 'See This Week',
                    // CARD 2 — WHAT'S COOKING
                    imageUrl: mealsImage ?? meal.imageUrl,
                    fallbackIcon: Icons.restaurant_menu_rounded,
                    onTap: _openWeeklyMeals,
                  );
                } else {
                  card = _HPJSwipePromoCard(
                    style: _HPJHeroStyle.meals,
                    eyebrow: 'SEASONAL PICKS',
                    title: '$availableCount fresh items available.',
                    subtitle:
                        'Browse fresh Jamaican produce without meal-planning content.',
                    badges: const ['Fresh', 'Local first'],
                    ctaLabel: 'Shop Fresh',
                    imageUrl: mealsImage ?? _productImage(generalProduct),
                    fallbackIcon: Icons.eco_outlined,
                    onTap: widget.onShopTap,
                  );
                }
              }

              // =================================================
              // 3 — FRESH DEALS
              // =================================================

              else if (index == 2) {
                card = _HPJSwipePromoCard(
                  style: _HPJHeroStyle.deals,
                  eyebrow: 'FRESH SAVINGS',
                  title: dealCount > 0
                      ? '$dealCount fresh ${dealCount == 1 ? 'deal' : 'deals'} today.'
                      : 'Fresh value, every week.',
                  subtitle:
                      'Save on selected local produce while supplies last.',
                  badges: [
                    if (dealProduct != null) dealProduct.name,
                    'Local savings',
                  ],
                  ctaLabel: 'Shop Deals',
                  imageUrl: dealsImage ??
                      _productImage(dealProduct) ??
                      _productImage(generalProduct),
                  fallbackIcon: Icons.local_offer_outlined,
                  onTap: widget.onDealsTap,
                );
              }

              // =================================================
              // 4 — LOCAL FARMS
              // =================================================
else {
  final lowStockCount = widget.products
      .where(
        (product) =>
            product.canAddToCart &&
            product.isLowStock,
      )
      .length;

  final dealPulseCount = widget.products
      .where(
        (product) =>
            product.canAddToCart &&
            product.hasActiveDiscount,
      )
      .length;

  String pulseTitle;
  String pulseSubtitle;
  String pulseRequest;

 if (harvestedCount > 0) {
  pulseTitle =
      '$harvestedCount fresh ${harvestedCount == 1 ? 'harvest' : 'harvests'} available now.';

  pulseSubtitle = hasFreshPick &&
          freshPickName.isNotEmpty
      ? '$freshPickName is today’s Fresh Pick.'
      : 'Fresh Jamaican produce is moving through HPJ right now.';

  pulseRequest = 'fresh';
}else if (lowStockCount > 0) {
    pulseTitle =
        '$lowStockCount ${lowStockCount == 1 ? 'item is' : 'items are'} moving fast.';

    pulseSubtitle =
        'Some fresh picks are moving into limited supply.';

    pulseRequest = 'low_stock';
  } else if (dealPulseCount > 0) {
    pulseTitle =
        '$dealPulseCount fresh ${dealPulseCount == 1 ? 'price opportunity' : 'price opportunities'} today.';

    pulseSubtitle =
        'Good value is showing across selected fresh products.';

    pulseRequest = 'deals';
  } else {
    pulseTitle =
        'Fresh activity across the marketplace.';

    pulseSubtitle =
        'See what is fresh, local and moving through HPJ today.';

    pulseRequest = 'all';
  }

  card = _HPJSwipePromoCard(
    style: _HPJHeroStyle.farm,
    eyebrow: 'HARVEST PULSE • LIVE',
    title: pulseTitle,
    subtitle: pulseSubtitle,
    badges: [
  harvestedCount > 0
      ? '$harvestedCount fresh'
      : '$localCount local',

  if (hasFreshPick &&
      freshPickName.isNotEmpty)
    'Pick • $freshPickName'
  else if (widget.showFarmStories && farmName.isNotEmpty)
    farmName
  else
    'Jamaican grown',
],
    ctaLabel: 'Explore Harvest',
    imageUrl: farmImage ??
        (widget.showFarmStories ? _productImage(farmProduct) : null) ??
        _productImage(generalProduct),
    fallbackIcon: Icons.monitor_heart_outlined,
    onTap: () {
  harvestPulseFreshPickId.value =
      hasFreshPick ? freshPick?.id : null;

  harvestPulseShopRequest.value =
      pulseRequest;

  widget.onShopTap();
},
  );
}
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: card,
              );
            },
          ),
        ),

        const SizedBox(height: 11),

        _buildDots(),
      ],
    );
  }
}

String _homeCategoryDisplayName(String category) {
  switch (category.trim().toLowerCase()) {
    case 'vegetables':
      return 'Vegetables';

    case 'fruits':
      return 'Fruits';

    case 'herbs':
      return 'Herbs & Seasonings';

    case 'ground provisions':
      return 'Ground Provisions';

    case 'eggs':
      return 'Eggs';

    case 'prepared foods':
      return 'Prepared Foods';

    case 'favorites':
      return 'Favorites';

    case 'other':
      return 'Pantry & Specialty';

    default:
      return category.trim();
  }
}

IconData _homeCategoryIcon(String category) {
  switch (category.trim().toLowerCase()) {
    case 'vegetables':
      return Icons.eco_outlined;

    case 'fruits':
      return Icons.apple_outlined;

    case 'herbs':
      return Icons.spa_outlined;

    case 'ground provisions':
      return Icons.agriculture_outlined;

    case 'eggs':
      return Icons.egg_alt_outlined;

    case 'prepared foods':
      return Icons.restaurant_outlined;

    case 'favorites':
      return Icons.favorite_border_rounded;

    case 'other':
      return Icons.inventory_2_outlined;

    default:
      return Icons.local_grocery_store_outlined;
  }
}

class _HPJHomeCategoryCard extends StatelessWidget {
  final String category;
  final int count;
  final VoidCallback onTap;

  const _HPJHomeCategoryCard({
    required this.category,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = _homeCategoryDisplayName(category);
    final icon = _homeCategoryIcon(category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 176,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFCF8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE1E7DD),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4EC),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFFDCE6D7),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: const Color(0xFF315B40),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF203126),
                        fontSize: 13.5,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$count available',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF788178),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE0E6DD),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: Color(0xFF315B40),
                ),
              ),
            ],
          ),
        ),
      ),
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
  void _showDealsOnHome() {
    homeSearchFocusNode.unfocus();
    homeSearchController.clear();

    setState(() {
      homeSearchQuery = '';
      selectedHomeCategory = 'All';
      selectedHomeNutrient = 'All';
      selectedHomeFilter = 'Deals';
    });
  }

  late Future<List<Product>> homeProductsFuture;
  late Future<List<Product>> buyAgainProductsFuture;
  late Future<CustomerProfile?> customerProfileFuture;
  late Future<LoyaltySummary> loyaltySummaryFuture;
  late Future<List<HomeHeroSlide>> homeHeroSlidesFuture;
  late Future<List<FarmOrder>> homeOrdersFuture;
  List<Product> cachedHomeProducts = const <Product>[];
  List<Product> homeRecentlyViewedProducts = const <Product>[];
  final TextEditingController homeSearchController = TextEditingController();
  final FocusNode homeSearchFocusNode = FocusNode();
  String homeSearchQuery = '';
  String selectedHomeCategory = 'All';
  String selectedHomeNutrient = 'All';
  String selectedHomeFilter = 'All items';
  int agricultureFeedRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    homeProductsFuture = loadHomeProducts();
    buyAgainProductsFuture = fetchBuyAgainProductsForCustomerUi();
    homeOrdersFuture = fetchOrders();
    unawaited(_loadHomeRecentlyViewed());
    unawaited(_loadUserPreferences());
    customerProfileFuture = fetchCurrentCustomerProfile();
    loyaltySummaryFuture = fetchLoyaltySummary();
    homeHeroSlidesFuture = fetchPublicHomeHeroSlides();
    homeSearchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadUserPreferences() async {
    await fetchCurrentUserExperiencePreferences();
    if (mounted) setState(() {});
  }

  Future<void> _loadHomeRecentlyViewed() async {
    try {
      final saved = await fetchRecentlyViewedProductsForCurrentUser(
        fallbackProducts: widget.recentlyViewedProducts,
      );

      if (!mounted) return;

      setState(() {
        homeRecentlyViewedProducts = saved;
      });
    } catch (error) {
      farmDebugLog(
        'Home recently viewed load skipped: $error',
      );
    }
  }

  @override
  void dispose() {
    homeSearchController.dispose();
    homeSearchFocusNode.dispose();
    super.dispose();
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
    FarmDataCache.clearOrders();
    FarmDataCache.clearProducts();

    if (!mounted) return;

    final nextHomeOrders = fetchOrders(forceRefresh: true);

    final nextHomeProducts = loadHomeProducts(forceRefresh: true);

    final nextBuyAgainProducts = fetchBuyAgainProductsForCustomerUi();

    final nextCustomerProfile = fetchCurrentCustomerProfile();

    final nextLoyaltySummary = fetchLoyaltySummary();

    setState(() {
      agricultureFeedRefreshKey++;
      homeOrdersFuture = nextHomeOrders;
      homeProductsFuture = nextHomeProducts;
      buyAgainProductsFuture = nextBuyAgainProducts;
      customerProfileFuture = nextCustomerProfile;
      loyaltySummaryFuture = nextLoyaltySummary;
    });

    await Future.wait<dynamic>([
      nextHomeOrders,
      nextHomeProducts,
      nextBuyAgainProducts,
      nextCustomerProfile,
      nextLoyaltySummary,
    ]);

    await Future.wait<void>([
      _loadHomeRecentlyViewed(),
      _loadUserPreferences(),
    ]);
  }

  void _addProductToCart(Product product) {
    widget.onAddToCart(product);
    Future.microtask(() => saveCartItemForCurrentUser(product));
  }

  void _removeProductFromCart(Product product) {
    widget.onRemoveFromCart(product);
    Future.microtask(() => removeCartItemForCurrentUser(product));
  }

  void _rememberViewedProduct(Product product) {
    final updated = <Product>[
      product,
      ...homeRecentlyViewedProducts.where(
        (item) => item.id != product.id,
      ),
    ];

    setState(() {
      homeRecentlyViewedProducts = updated.take(20).toList();
    });

    widget.onViewed(product);

    unawaited(
      saveRecentlyViewedForCurrentUser(product),
    );
  }

  Future<void> openProduct(Product product) async {
    _rememberViewedProduct(product);

    final nutrientToFilter = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (detailContext) => ProductDetailScreen(
          product: product,
          quantity: widget.quantityForProduct(product),

          // Makes the nutrient chips clickable when opened from Home.
          onNutrientTap: (nutrient) {
            Navigator.of(detailContext).pop(nutrient);
          },

          onAdd: () => _addProductToCart(product),
          onRemove: () => _removeProductFromCart(product),
          onAddProduct: _addProductToCart,
          onViewed: _rememberViewedProduct,
          onViewMyBox: widget.onViewMyBox,
          onCheckout: widget.onCheckout,
        ),
      ),
    );

    if (!mounted ||
        nutrientToFilter == null ||
        nutrientToFilter.trim().isEmpty) {
      return;
    }

    final selectedNutrient = nutrientToFilter.trim();

    setState(() {
      selectedHomeCategory = 'All';
      selectedHomeNutrient = selectedNutrient;
      selectedHomeFilter = 'All items';

      homeSearchController.clear();
      homeSearchQuery = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Showing products with $selectedNutrient.',
        ),
        behavior: SnackBarBehavior.floating,
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
      height: 146,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        cacheExtent: AppPerformanceConfig.productRailCacheExtent,
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = visible[index];

          return InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              unawaited(openProduct(product));
            },
            child: SizedBox(
              width: 142,
              child: Opacity(
                opacity: product.isOutOfStock ? 0.72 : 1,
                child: FarmCard(
                  padding: const EdgeInsets.all(9),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(
                        child: ProductVisual(
                          product: product,
                          size: 104,
                          showOrganicBadge: false,
                        ),
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
                      Positioned(
                        left: 2,
                        bottom: 2,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 106),
                          child: Wrap(
                            alignment: WrapAlignment.start,
                            crossAxisAlignment: WrapCrossAlignment.start,
                            spacing: 5,
                            runSpacing: 5,
                            children: [
                              ProductOriginBadge(
                                product: product,
                                compact: true,
                                includeIcon: false,
                              ),
                              if (product.isOutOfStock || product.isLowStock)
                                ProductAvailabilityChip(
                                  product: product,
                                  compact: true,
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
      ),
    );
  }

  Map<String, String>? get _activeSponsoredCampaign {
    return {
      'eyebrow': 'SPONSORED',
      'title': 'Featured Harvest • St. Elizabeth',
      'subtitle': 'Fresh local picks selected for this week.',
      'cta': 'Explore',
    };
  }

  Widget _sponsoredHomeCard(
    Map<String, String> campaign,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onShopTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            16,
            14,
            14,
            14,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE9DFC8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ============================================
              // GOLD ACCENT
              // ============================================
              Container(
                width: 3,
                height: 66,
                decoration: BoxDecoration(
                  color: const Color(0xFFC58A2B),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(width: 13),

              // ============================================
              // CONTENT
              // ============================================
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EAD4),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        campaign['eyebrow'] ?? 'SPONSORED',
                        style: const TextStyle(
                          color: Color(0xFF9A681C),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.65,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      campaign['title'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      campaign['subtitle'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 11.2,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ============================================
              // CTA
              // ============================================
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    campaign['cta'] ?? 'Explore',
                    style: const TextStyle(
                      color: FarmColors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: FarmColors.green,
                    size: 21,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> get _homeNutrientOptions => const [
        'Magnesium',
        'Iron',
        'Fiber',
        'Potassium',
        'Vitamin C',
        'Protein',
        'Calcium',
        'Antioxidants',
      ];

  String _cleanHomeSearchValue(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _homeListHasNutrient(List<String> values, String nutrient) {
    final key = _cleanHomeSearchValue(nutrient);
    if (key.isEmpty) return false;

    return values.any((value) => _cleanHomeSearchValue(value) == key);
  }

  int _homeProductNutrientLevel(Product product, String nutrient) {
    if (_homeListHasNutrient(product.nutrientStrong, nutrient)) return 3;
    if (_homeListHasNutrient(product.nutrientGood, nutrient)) return 2;
    if (_homeListHasNutrient(product.nutrientContains, nutrient)) return 1;
    return 0;
  }

  String? _homeNutrientFromQuery(String value) {
    final clean = _cleanHomeSearchValue(value);
    if (clean.isEmpty) return null;

    for (final nutrient in _homeNutrientOptions) {
      final nutrientKey = _cleanHomeSearchValue(nutrient);
      if (clean == nutrientKey || clean.contains(nutrientKey)) {
        return nutrient;
      }
    }

    if (clean == 'vit c' || clean.contains('vit c')) return 'Vitamin C';
    if (clean == 'antioxidant' || clean.contains('antioxidant')) {
      return 'Antioxidants';
    }

    return null;
  }

  String _homeSearchTextForProduct(Product product) {
    return _cleanHomeSearchValue([
      product.name,
      product.category,
      product.description ?? '',
      product.unit ?? '',
      product.farmName ?? '',
      product.farmerName ?? '',
      ...product.nutrientStrong,
      ...product.nutrientGood,
      ...product.nutrientContains,
    ].join(' '));
  }

  bool _homeProductMatchesSearch(Product product, String query) {
    final cleanQuery = _cleanHomeSearchValue(query);
    if (cleanQuery.isEmpty) return true;

    final nutrient = _homeNutrientFromQuery(query);
    if (nutrient != null && _homeProductNutrientLevel(product, nutrient) > 0) {
      return true;
    }

    return _homeSearchTextForProduct(product).contains(cleanQuery) ||
        hpjSmartProductMatchesSearch(product, query);
  }

  int _homeSearchRankScore(Product product, String query) {
    final cleanQuery = _cleanHomeSearchValue(query);
    final nutrient = _homeNutrientFromQuery(query);
    var score = 0;

    final cleanName = _cleanHomeSearchValue(product.name);
    final cleanCategory = _cleanHomeSearchValue(product.category);
    final cleanFarm = _cleanHomeSearchValue(
      product.farmName ?? product.farmerName ?? '',
    );

    if (cleanName == cleanQuery) score += 5000;
    if (cleanName.startsWith(cleanQuery)) score += 3000;
    if (cleanName.contains(cleanQuery)) score += 1800;
    if (cleanCategory.contains(cleanQuery)) score += 900;
    if (cleanFarm.contains(cleanQuery)) score += 700;

    if (nutrient != null) {
      score += _homeProductNutrientLevel(product, nutrient) * 1200;
      if (product.nutritionVerified) score += 220;
    }

    final smartScore = hpjSmartProductSearchScore(product, query);
    if (smartScore > 0) score += smartScore;

    if (product.canAddToCart) score += 160;
    if (product.hasActiveDiscount) score += 80;
    if (product.isOrganic) score += 30;

    return score;
  }

  List<String> get _homeNutrientFilterOptions => [
        'All',
        ..._homeNutrientOptions,
      ];

  List<String> get _homeFilterOptions => const [
        'All items',
        'In stock',
        'Low stock',
        'Deals',
        'Organic',
        'Out of stock',
      ];

  bool get _hasActiveHomeFilters {
    return selectedHomeCategory != 'All' ||
        selectedHomeNutrient != 'All' ||
        selectedHomeFilter != 'All items';
  }

  List<String> _homeCategoryOptions(List<Product> products) {
    final values = <String>{'All'};

    for (final product in products) {
      final category = product.category.trim();
      if (category.isNotEmpty) values.add(category);
    }

    final output = values.toList();
    output.sort((a, b) {
      if (a == 'All') return -1;
      if (b == 'All') return 1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });

    return output;
  }

  bool _homeProductMatchesFilters(Product product) {
    final category = product.category.trim().toLowerCase();
    final selectedCategory = selectedHomeCategory.trim().toLowerCase();
    final selectedFilter = selectedHomeFilter.trim().toLowerCase();

    final matchesCategory = selectedHomeCategory == 'All' ||
        category == selectedCategory ||
        product.name.trim().toLowerCase().contains(selectedCategory);

    final matchesNutrient = selectedHomeNutrient == 'All' ||
        _homeProductNutrientLevel(product, selectedHomeNutrient) > 0;

    final matchesFilter = selectedFilter == 'all items' ||
        (selectedFilter == 'in stock' && product.canAddToCart) ||
        (selectedFilter == 'low stock' && product.isLowStock) ||
        (selectedFilter == 'deals' && product.hasActiveDiscount) ||
        (selectedFilter == 'organic' && product.isOrganic) ||
        (selectedFilter == 'out of stock' && product.isOutOfStock);

    return matchesCategory && matchesNutrient && matchesFilter;
  }

  int _homeFilterRankScore(Product product) {
    var score = 0;

    if (selectedHomeNutrient != 'All') {
      score += _homeProductNutrientLevel(product, selectedHomeNutrient) * 1200;
      if (product.nutritionVerified) score += 180;
    }

    if (product.canAddToCart) score += 120;
    if (product.hasActiveDiscount) score += 70;
    if (product.isOrganic) score += 30;
    if (product.isLowStock) score -= 20;
    if (product.isOutOfStock) score -= 500;

    return score;
  }

  List<Product> _homeSearchResults(List<Product> products) {
    final query = homeSearchQuery.trim();
    final hasQuery = query.isNotEmpty;

    if (!hasQuery && !_hasActiveHomeFilters) return const <Product>[];

    final output = products.where((product) {
      final matchesSearch =
          !hasQuery || _homeProductMatchesSearch(product, query);
      final matchesFilters = _homeProductMatchesFilters(product);
      return matchesSearch && matchesFilters;
    }).toList();

    output.sort((a, b) {
      if (hasQuery) {
        final scoreCompare = _homeSearchRankScore(b, query).compareTo(
          _homeSearchRankScore(a, query),
        );
        if (scoreCompare != 0) return scoreCompare;
      }

      final filterCompare = _homeFilterRankScore(b).compareTo(
        _homeFilterRankScore(a),
      );
      if (filterCompare != 0) return filterCompare;

      if (a.canAddToCart != b.canAddToCart) {
        return a.canAddToCart ? -1 : 1;
      }

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return output;
  }

  void _clearHomeSearch() {
    if (homeSearchController.text.isEmpty && homeSearchQuery.isEmpty) return;

    homeSearchController.clear();
    setState(() => homeSearchQuery = '');
    homeSearchFocusNode.requestFocus();
  }

  void _resetHomeSearchAndFilters() {
    homeSearchController.clear();
    setState(() {
      homeSearchQuery = '';
      selectedHomeCategory = 'All';
      selectedHomeNutrient = 'All';
      selectedHomeFilter = 'All items';
    });
    homeSearchFocusNode.requestFocus();
  }

  Future<void> _showHomeFilterSheet(List<Product> products) async {
    final categories = _homeCategoryOptions(products);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
                selected: selected,
                label: Text(label),
                onSelected: (_) {
                  onTap();
                  sheetSetState(() {});
                },
                selectedColor: color,
                backgroundColor: FarmColors.primarySoft.withOpacity(0.64),
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
                    color: selected ? color : color.withOpacity(0.13),
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
                              title: 'Home filters',
                              subtitle:
                                  'Filter fresh results without leaving Home.',
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
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((category) {
                          return sheetChoice(
                            label: category,
                            selected: selectedHomeCategory == category,
                            onTap: () {
                              setState(() => selectedHomeCategory = category);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Nutrient focus',
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
                        children: _homeNutrientFilterOptions.map((nutrient) {
                          return sheetChoice(
                            label: nutrient,
                            selected: selectedHomeNutrient == nutrient,
                            onTap: () {
                              setState(() => selectedHomeNutrient = nutrient);
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
                        children: _homeFilterOptions.map((filter) {
                          final isOutOfStock = filter == 'Out of stock';
                          final isDeal = filter == 'Deals';
                          final color = isOutOfStock
                              ? FarmColors.danger
                              : isDeal
                                  ? FarmColors.warning
                                  : FarmColors.green;

                          return sheetChoice(
                            label: filter,
                            selected: selectedHomeFilter == filter,
                            color: color,
                            onTap: () {
                              setState(() => selectedHomeFilter = filter);
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
                                  selectedHomeCategory = 'All';
                                  selectedHomeNutrient = 'All';
                                  selectedHomeFilter = 'All items';
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
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                homeSearchFocusNode.unfocus();
                              },
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

  Widget _eliteHomeSearchEntry(List<Product> products) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: 54,
        padding: const EdgeInsets.fromLTRB(13, 6, 8, 6),
        decoration: BoxDecoration(
          color: FarmColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: homeSearchFocusNode.hasFocus ||
                    homeSearchQuery.isNotEmpty ||
                    _hasActiveHomeFilters
                ? FarmColors.green.withOpacity(0.32)
                : FarmColors.green.withOpacity(0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: FarmColors.shadow.withOpacity(0.085),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: FarmColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: FarmColors.green.withOpacity(0.10),
                ),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: FarmColors.green,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: homeSearchController,
                focusNode: homeSearchFocusNode,
                textInputAction: TextInputAction.search,
                cursorColor: FarmColors.green,
                style: const TextStyle(
                  color: FarmColors.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.05,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Search fresh produce, farms, or nutrients...',
                  hintStyle: TextStyle(
                    color: FarmColors.mutedText.withOpacity(0.88),
                    fontSize: 13.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.05,
                  ),
                ),
                onChanged: (value) {
                  setState(() => homeSearchQuery = value);
                },
                onSubmitted: (value) {
                  homeSearchFocusNode.unfocus();
                  unawaited(HpjSmartLocalStore.rememberRecentSearch(value));
                },
              ),
            ),
            if (homeSearchQuery.trim().isNotEmpty || _hasActiveHomeFilters) ...[
              const SizedBox(width: 4),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: _resetHomeSearchAndFilters,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: FarmColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: FarmColors.green,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _showHomeFilterSheet(products),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _hasActiveHomeFilters
                            ? FarmColors.primaryDark
                            : FarmColors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: FarmColors.green.withOpacity(0.16),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                    if (_hasActiveHomeFilters)
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: FarmColors.warning,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
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
    );
  }

  Widget _homeSearchEmptyState(String query) {
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
              shape: BoxShape.circle,
              border: Border.all(color: FarmColors.green.withOpacity(0.10)),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: FarmColors.green,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No matching fresh items yet',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Try another word like avocado, egg, fruit, fiber, or vitamin C.',
                  style: TextStyle(
                    color: FarmColors.mutedText.withOpacity(0.92),
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

  Widget _homeSearchResultsSection(List<Product> results) {
    final query = homeSearchQuery.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        SectionHeader(
          title: query.isEmpty ? 'Filtered fresh picks' : 'Search results',
          subtitle: results.isEmpty
              ? 'No matches for “$query”'
              : '${results.length} matching fresh ${results.length == 1 ? 'item' : 'items'}',
          actionLabel: 'Clear',
          onAction: _resetHomeSearchAndFilters,
        ),
        const SizedBox(height: 12),
        if (results.isEmpty)
          _homeSearchEmptyState(query)
        else
          productRail(
            products: results,
            maxItems: 12,
          ),
        const SizedBox(height: 14),
        FarmCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: FarmColors.lightGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: FarmColors.green.withOpacity(0.10)),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: FarmColors.green,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Use the top filter button to refine results by category, nutrient, stock, deals, or organic items.',
                  style: TextStyle(
                    color: FarmColors.mutedText.withOpacity(0.94),
                    fontWeight: FontWeight.w700,
                    height: 1.28,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () => _showHomeFilterSheet(cachedHomeProducts),
                child: const Text('Filter'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget loadingRail() {
    return const ProductRailSkeleton();
  }

  FarmOrder? _findActiveHomeOrder(List<FarmOrder> orders) {
    const finishedStatuses = {
      'completed',
      'delivered',
      'cancelled',
      'canceled',
      'rejected',
    };

    for (final order in orders) {
      final status = order.status.trim().toLowerCase();

      if (!finishedStatuses.contains(status)) {
        return order;
      }
    }

    return null;
  }

  String _activeOrderHeadline(FarmOrder order) {
    switch (order.status.trim().toLowerCase()) {
      case 'pending':
        return 'Order received';

      case 'confirmed':
        return 'Order confirmed';

      case 'preparing':
        return 'Your box is being prepared';

      case 'ready':
      case 'ready_for_pickup':
        return 'Your order is ready';

      case 'out_for_delivery':
        return 'Your order is on the way';

      default:
        return 'Track your order';
    }
  }

  Widget _activeOrderCard(FarmOrder order) {
    final status = order.status.trim().replaceAll('_', ' ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailsScreen(
                orderId: order.id,
                onAddToCart: widget.onAddToCart,
                onOpenMyBox: widget.onViewMyBox,
              ),
            ),
          );

          if (!mounted) return;

          FarmDataCache.clearOrders();

          setState(() {
            homeOrdersFuture = fetchOrders(forceRefresh: true);
          });
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F7F0),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFD6E4D5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _activeOrderHeadline(order),
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.25,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        color: FarmColors.green,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                '#${order.shortId} • ${order.formattedType}',
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Track order',
                    style: TextStyle(
                      color: FarmColors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: FarmColors.green,
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smartContinueMyBoxCard() {
    if (widget.cartItemCount <= 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6EC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FarmColors.green.withOpacity(0.14)),
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
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: FarmColors.green,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Continue your box',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.cartItemCount} ${widget.cartItemCount == 1 ? 'item is' : 'items are'} waiting. Pick up exactly where you left off.',
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 11.2,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: widget.onViewMyBox,
            icon: const Icon(Icons.arrow_forward_rounded, size: 17),
            label: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAgricultureFeedAction(
    AgricultureFeedUpdate update,
  ) async {
    switch (update.actionType) {
      case 'customer_shop':
        widget.onShopTap();
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
        if (!opened && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the source link.')),
          );
        }
        return;
      default:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userPreferences = hpjCurrentUserExperiencePreferences;

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

          final recentSource = <Product>[
            ...widget.recentlyViewedProducts,
            ...homeRecentlyViewedProducts,
          ];

          final cleanRecentlyViewed = refreshProductSnapshotsFromLatestProducts(
            savedProducts: recentSource,
            latestProducts: products,
            limit: 20,
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

              final buyAgainProducts = uniqueVisibleProducts(
                rawBuyAgainProducts,
                limit: 10,
              );

// =====================================================
//// =====================================================
// 1. CONTINUE SHOPPING
// Recently viewed gets first priority.
// =====================================================
              final recentlyViewedForHome = uniqueVisibleProducts(
                cleanRecentlyViewed,
                limit: 8,
              );

              final continueShoppingIds =
                  recentlyViewedForHome.map((product) => product.id).toSet();

// =====================================================
// 2. BUY AGAIN
// Avoid repeating Continue Shopping products.
// =====================================================
              final buyAgainForHome = uniqueVisibleProducts(
                buyAgainProducts,
                limit: 8,
                excludeIds: {
                  ...continueShoppingIds,
                },
              );

              final buyAgainIds =
                  buyAgainForHome.map((product) => product.id).toSet();
// =====================================================
// FAVORITES
// Used by your category card.
// =====================================================
              final favoritesForHome = uniqueVisibleProducts(
                cleanFavoriteProducts,
                limit: 8,
              );

              final showFavorites = favoritesForHome.isNotEmpty;

              final showBuyAgain = buyAgainForHome.isNotEmpty;

              final showRecentlyViewed = recentlyViewedForHome.isNotEmpty;

// =====================================================
// 3. RECOMMENDED FOR YOU
// Build recommendations, then remove things already
// reserved for Buy Again and Continue Shopping.
// =====================================================
              var rawRecommendedProducts = buildRecommendedForYouProducts(
                allProducts: products,
                recentlyViewedProducts: userPreferences.personalizationEnabled
                    ? cleanRecentlyViewed
                    : const <Product>[],
                buyAgainProducts: userPreferences.personalizationEnabled
                    ? buyAgainProducts
                    : const <Product>[],
                favoriteProducts: userPreferences.personalizationEnabled
                    ? cleanFavoriteProducts
                    : const <Product>[],
              );

              // Keep preference handling local to the customer screen so this
              // remains compatible with the stable recommendation helper API.
              if (userPreferences.organicPreference == 'only') {
                rawRecommendedProducts = rawRecommendedProducts
                    .where((product) => product.isOrganic)
                    .toList();
              } else if (userPreferences.organicPreference == 'prefer' ||
                  userPreferences.recommendationStyle == 'organic_first') {
                rawRecommendedProducts = List<Product>.of(rawRecommendedProducts)
                  ..sort((a, b) {
                    final organicCompare =
                        (b.isOrganic ? 1 : 0).compareTo(a.isOrganic ? 1 : 0);
                    if (organicCompare != 0) return organicCompare;
                    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                  });
              }

              if (userPreferences.recommendationStyle == 'budget_first') {
                rawRecommendedProducts = List<Product>.of(rawRecommendedProducts)
                  ..sort((a, b) {
                    final dealCompare =
                        (b.hasActiveDiscount ? 1 : 0).compareTo(
                      a.hasActiveDiscount ? 1 : 0,
                    );
                    if (dealCompare != 0) return dealCompare;
                    return a.effectivePrice.compareTo(b.effectivePrice);
                  });
              }

              final recommendedProducts = uniqueVisibleProducts(
                rawRecommendedProducts,
                limit: 8,
                excludeIds: {
                  ...buyAgainIds,
                  ...continueShoppingIds,
                },
              );

              final recommendedIds =
                  recommendedProducts.map((product) => product.id).toSet();

// =====================================================
// 4. IN SEASON NOW
// Harvested-this-week products get their own section.
// =====================================================
// =====================================================
// 4. IN SEASON NOW
// Prefer true harvested-this-week products.
// If those were already used elsewhere, still allow
// them here because this is a special seasonal section.
// =====================================================
              var inSeasonForHome = uniqueVisibleProducts(
                harvestThisWeekProducts,
                limit: 8,
                excludeIds: {
                  ...buyAgainIds,
                  ...continueShoppingIds,
                  ...recommendedIds,
                },
              );

// If seasonal products exist but were all removed
// because they appeared in another Home section,
// allow them to appear here as well.
              if (inSeasonForHome.isEmpty &&
                  harvestThisWeekProducts.isNotEmpty) {
                inSeasonForHome = uniqueVisibleProducts(
                  harvestThisWeekProducts,
                  limit: 8,
                );
              }

              final inSeasonIds =
                  inSeasonForHome.map((product) => product.id).toSet();

// =====================================================
// 5. FRESH PRODUCTS
// Fill this last so it doesn't steal products from the
// more personalized sections above.
// =====================================================
              final freshProductsForHome = uniqueVisibleProducts(
                products,
                limit: 8,
                excludeIds: {
                  ...buyAgainIds,
                  ...continueShoppingIds,
                  ...recommendedIds,
                  ...inSeasonIds,
                },
              );

              final freshIds =
                  freshProductsForHome.map((product) => product.id).toSet();

// =====================================================
// SPONSORED
// Null = no campaign, so section stays hidden.
// =====================================================

              final sponsoredCampaign = _activeSponsoredCampaign;
              final hasActiveHomeSearch =
                  homeSearchQuery.trim().isNotEmpty || _hasActiveHomeFilters;
              final homeSearchResults = hasActiveHomeSearch
                  ? _homeSearchResults(products)
                  : const <Product>[];
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
                child: Stack(
                  children: [
                    ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 88, 18, 128),
                      children: [
                        PersonalizedHomeHeader(
                          profileFuture: customerProfileFuture,
                          loyaltyFuture: loyaltySummaryFuture,
                          onCartTap: widget.onCartTap,
                          cartItemCount: widget.cartItemCount,
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<List<HomeHeroSlide>>(
                          future: homeHeroSlidesFuture,
                          builder: (context, heroSnapshot) {
                            final heroSlides =
                                heroSnapshot.data ?? defaultHomeHeroSlides();

                            return HPJHomeSwipeCarousel(
                              products: products,
                              heroSlides: heroSlides,
                              onAddProduct: _addProductToCart,
                              onViewMyBox: widget.onViewMyBox,
                              onShopTap: widget.onShopTap,
                              onDealsTap: _showDealsOnHome,
                              showMealIdeas: userPreferences.showMealIdeas,
                              showFarmStories: userPreferences.showFarmStories,
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        if (!hasActiveHomeSearch && widget.cartItemCount > 0) ...[
                          const SizedBox(height: 14),
                          _smartContinueMyBoxCard(),
                        ],
                        if (hasActiveHomeSearch)
                          _homeSearchResultsSection(homeSearchResults)
                        else ...[
// =====================================================
// ACTIVE ORDER
// =====================================================
                          FutureBuilder<List<FarmOrder>>(
                            future: homeOrdersFuture,
                            builder: (context, orderSnapshot) {
                              final activeOrder = _findActiveHomeOrder(
                                orderSnapshot.data ?? const <FarmOrder>[],
                              );

                              if (activeOrder == null) {
                                return const SizedBox.shrink();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 18),
                                child: _activeOrderCard(activeOrder),
                              );
                            },
                          ), // FutureBuilder

                          if (userPreferences.showAgricultureNews) ...[
                            const SizedBox(height: 18),
                            HpjAgricultureUpdatesSection(
                              audience: 'customer',
                              workspace: 'customer',
                              limit: 2,
                              refreshKey: agricultureFeedRefreshKey,
                              title: 'Agriculture updates',
                              subtitle:
                                  'Useful Jamaican agriculture news, opportunities and HPJ updates.',
                              showImages: userPreferences.showFeedImages,
                              onAction: _handleAgricultureFeedAction,
                            ),
                          ],

                          if (userPreferences.showFreshReels) ...[
                            const SizedBox(height: 18),
                            FreshReelFeedPreviewCard(
                              preferences: userPreferences,
                              audience: 'customer',
                              placement: freshReelPlacementCustomerFeed,
                              refreshKey: agricultureFeedRefreshKey,
                              onAddToCart: _addProductToCart,
                            ),
                          ],

                          // =====================================================
                          // SHOP BY CATEGORY
                          // =====================================================
// =====================================================
// YOUR EXISTING SHOP FRESH CARD GOES DIRECTLY BELOW
// =====================================================

                          if (categoryCards.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            SectionHeader(
                              title: 'Shop by Category',
                              subtitle: 'Browse what’s fresh',
                              actionLabel: 'View all',
                              onAction: widget.onShopTap,
                            ),
                            const SizedBox(height: 12),
                            _HPJCategorySwipeCarousel(
                              categories: categoryCards,
                              products: products,
                              favoriteProducts: favoritesForHome,
                              onCategoryTap: (categoryName) {
                                widget.onCategoryTap(categoryName);
                              },
                            ),
                          ],
// =====================================================
// RECOMMENDED FOR YOU
// =====================================================
                          if (userPreferences.showRecommendations &&
                              recommendedProducts.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            SectionHeader(
                              title: 'Recommended For You',
                              subtitle: 'Fresh picks selected for you',
                              actionLabel: 'Shop all',
                              onAction: widget.onShopTap,
                            ),
                            const SizedBox(height: 12),
                            productRail(
                              products: recommendedProducts,
                              maxItems: 8,
                            ),
                          ],
                          // Deals remain available in the Shop.
                          // Hidden on Home so product names and prices do not
                          // appear on the landing page.
                          const SizedBox(height: 18),
                          // =====================================================
// SPONSORED
// =====================================================
                          if (userPreferences.showPromotions &&
                              sponsoredCampaign != null) ...[
                            const SizedBox(height: 22),

                            _sponsoredHomeCard(
                              sponsoredCampaign,
                            ),

                            // Space before Fresh Products
                            const SizedBox(height: 18),
                          ],
                          SectionHeader(
                            title: 'Fresh Products',
                            subtitle: 'Fresh items available now',
                            actionLabel: 'Shop all',
                            onAction: widget.onShopTap,
                          ),
                          const SizedBox(height: 12),
                          snapshot.connectionState == ConnectionState.waiting &&
                                  products.isEmpty
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
                            productRail(
                              products: favoritesForHome,
                              maxItems: 8,
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
                                : productRail(
                                    products: buyAgainForHome, maxItems: 8),
                          ],
                          if (inSeasonForHome.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            SectionHeader(
                              title: 'In Season Now',
                              subtitle: 'Fresh harvest available this week',
                              actionLabel: 'Shop all',
                              onAction: widget.onShopTap,
                            ),
                            const SizedBox(height: 12),
                            productRail(
                              products: inSeasonForHome,
                              maxItems: 8,
                            ),
                          ],
                          if (showRecentlyViewed) ...[
                            const SizedBox(height: 20),
                            SectionHeader(
                              title: 'Continue Shopping',
                              subtitle: 'Pick up where you left off',
                              actionLabel: 'View all',
                              onAction: widget.onShopTap,
                            ),
                            const SizedBox(height: 12),
                            productRail(
                              products: recentlyViewedForHome,
                              maxItems: 8,
                            ),
                          ],
                          const SizedBox(height: 22),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: widget.onShopTap,
                              child: FarmCard(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Shop fresh',
                                            style: TextStyle(
                                              color: FarmColors.ink,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16.5,
                                              letterSpacing: -0.25,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Produce • Deals • Nutrients • Local farms',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: FarmColors.mutedText,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11.8,
                                              height: 1.20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: FarmColors.lightGreen,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: FarmColors.green
                                              .withOpacity(0.10),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: FarmColors.green,
                                        size: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Positioned(
                      top: 16,
                      left: 18,
                      right: 18,
                      child: SafeArea(
                        bottom: false,
                        child: _eliteHomeSearchEntry(products),
                      ),
                    ),
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

class _HPJCategorySwipeCarousel extends StatefulWidget {
  final List<PopularCategorySummary> categories;
  final List<Product> products;
  final List<Product> favoriteProducts;
  final ValueChanged<String> onCategoryTap;

  const _HPJCategorySwipeCarousel({
    required this.categories,
    required this.products,
    this.favoriteProducts = const <Product>[],
    required this.onCategoryTap,
  });

  @override
  State<_HPJCategorySwipeCarousel> createState() =>
      _HPJCategorySwipeCarouselState();
}

class _HPJCategorySwipeCarouselState extends State<_HPJCategorySwipeCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    // Each page contains multiple category cards,
    // so the page should nearly fill the available width.
    _pageController = PageController(
      viewportFraction: 0.98,
    );
  }

  List<Product> _previewProductsFor(
    PopularCategorySummary category,
  ) {
    String cleanCategory(String value) {
      final key = value
          .trim()
          .toLowerCase()
          .replaceAll('&', 'and')
          .replaceAll(RegExp(r'\s+'), ' ');

      switch (key) {
        case 'vegetable':
        case 'vegetables':
          return 'vegetables';

        case 'fruit':
        case 'fruits':
          return 'fruits';

        case 'herb':
        case 'herbs':
        case 'herbs and seasonings':
        case 'herbs & seasonings':
          return 'herbs';

        case 'ground provision':
        case 'ground provisions':
          return 'ground provisions';

        case 'egg':
        case 'eggs':
          return 'eggs';

        case 'grain':
        case 'grains':
          return 'grains';

        case 'prepared food':
        case 'prepared foods':
          return 'prepared foods';

        case 'other':
        case 'pantry':
        case 'pantry and specialty':
        case 'pantry & specialty':
          return 'other';

        default:
          return key;
      }
    }

    final targetCategory = cleanCategory(category.name);

    final result = <Product>[];
    final seenProducts = <String>{};
    final seenImages = <String>{};

    Iterable<Product> source;

    if (targetCategory == 'favorites') {
      source = widget.favoriteProducts;
    } else {
      source = widget.products.where((product) {
        final productCategory = cleanCategory(product.category);

        return productCategory == targetCategory;
      });
    }

    for (final product in source) {
      final imageUrl = cleanHostedImageUrl(product.imageUrl);

      if (imageUrl == null || imageUrl.trim().isEmpty) {
        continue;
      }

      // Avoid using the exact same product twice.
      final productKey = '${product.name.trim().toLowerCase()}|$imageUrl';

      if (!seenProducts.add(productKey)) {
        continue;
      }

      // Avoid duplicate images.
      if (!seenImages.add(imageUrl)) {
        continue;
      }

      result.add(product);

      if (result.length >= 4) {
        break;
      }
    }

    // Keep the existing preview product as a fallback.
    if (result.isEmpty) {
      final fallback = category.previewProduct;
      final fallbackUrl = cleanHostedImageUrl(fallback.imageUrl);

      if (fallbackUrl != null && fallbackUrl.trim().isNotEmpty) {
        result.add(fallback);
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final int cardsPerPage;

        if (width >= 1100) {
          cardsPerPage = 4;
        } else if (width >= 700) {
          cardsPerPage = 3;
        } else {
          cardsPerPage = 2;
        }

        final pageCount = (widget.categories.length / cardsPerPage).ceil();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 166,
              child: PageView.builder(
                controller: _pageController,
                padEnds: false,
                pageSnapping: true,
                physics: const BouncingScrollPhysics(),
                itemCount: pageCount,
                onPageChanged: (index) {
                  if (!mounted) return;

                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, pageIndex) {
                  final start = pageIndex * cardsPerPage;

                  final proposedEnd = start + cardsPerPage;

                  final end = proposedEnd > widget.categories.length
                      ? widget.categories.length
                      : proposedEnd;

                  final pageCategories = widget.categories.sublist(
                    start,
                    end,
                  );

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int slot = 0; slot < cardsPerPage; slot++) ...[
                        if (slot > 0) const SizedBox(width: 10),
                        Expanded(
                          child: slot < pageCategories.length
                              ? _HPJImageCategoryCard(
                                  category: pageCategories[slot],
                                  previewProducts: _previewProductsFor(
                                    pageCategories[slot],
                                  ),
                                  onTap: () {
                                    widget.onCategoryTap(
                                      pageCategories[slot].name,
                                    );
                                  },
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            if (pageCount > 1) ...[
              const SizedBox(height: 9),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pageCount,
                  (index) {
                    final active = index == _currentPage;

                    return AnimatedContainer(
                      duration: const Duration(
                        milliseconds: 220,
                      ),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 3,
                      ),
                      width: active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(
                                0xFF285E3D,
                              )
                            : const Color(
                                0xFFD9DED6,
                              ),
                        borderRadius: BorderRadius.circular(
                          20,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
} // closes _HPJCategorySwipeCarouselState

class _HPJImageCategoryCard extends StatelessWidget {
  final PopularCategorySummary category;
  final List<Product> previewProducts;
  final VoidCallback onTap;

  const _HPJImageCategoryCard({
    required this.category,
    required this.previewProducts,
    required this.onTap,
  });

  String get _key => category.name.trim().toLowerCase();

  String get _displayName {
    switch (_key) {
      case 'herbs':
        return 'Herbs & Seasonings';

      case 'ground provisions':
        return 'Ground Provisions';

      case 'other':
        return 'Pantry & Specialty';

      case 'prepared foods':
        return 'Prepared Foods';

      default:
        return category.name;
    }
  }

  Widget _imageTile(String? imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: FarmColors.cardSoft,
        child: imageUrl == null || imageUrl.isEmpty
            ? const SizedBox.expand()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                gaplessPlayback: true,
                cacheWidth: 300,
                filterQuality: FilterQuality.medium,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return Container(
                    color: FarmColors.cardSoft,
                  );
                },
              ),
      ),
    );
  }

  Widget _imageCollage(List<String> images) {
    if (images.isEmpty) {
      return Container(
        color: FarmColors.cardSoft,
      );
    }

    if (images.length == 1) {
      return _imageTile(images[0]);
    }

    if (images.length == 2) {
      return Row(
        children: [
          Expanded(
            child: _imageTile(images[0]),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _imageTile(images[1]),
          ),
        ],
      );
    }

    if (images.length == 3) {
      return Row(
        children: [
          Expanded(
            child: _imageTile(images[0]),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _imageTile(images[1]),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: _imageTile(images[2]),
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
          child: Row(
            children: [
              Expanded(
                child: _imageTile(images[0]),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _imageTile(images[1]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _imageTile(images[2]),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _imageTile(images[3]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = previewProducts
        .map(
          (product) => cleanHostedImageUrl(product.imageUrl),
        )
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .take(4)
        .toList();

    final count = category.availableItemCount;
    final countLabel = count == 1 ? '1 item' : '$count items';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: FarmColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: FarmColors.line.withOpacity(0.90),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      6,
                      6,
                      6,
                      0,
                    ),
                    child: _imageCollage(imageUrls),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    10,
                    8,
                    9,
                    10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FarmColors.ink,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            height: 1.04,
                            letterSpacing: -0.15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: FarmColors.primarySoft.withOpacity(0.68),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          countLabel,
                          maxLines: 1,
                          style: const TextStyle(
                            color: FarmColors.green,
                            fontSize: 9.8,
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
  String selectedShopNutrient = 'All';
  String? harvestPulseContext;
  String? harvestPulseFreshPickIdContext;
  Timer? searchDebounce;
  Set<String> persistedFavoriteIds = <String>{};
  void _applyMealIngredientSearch() {
    final query = mealIngredientShopSearchRequest.value?.trim() ?? '';
    if (query.isEmpty) return;

    setState(() {
      selectedCategory = 'All';
      selectedShopFilter = 'All items';
      selectedShopNutrient = 'All';
      searchController.text = query;
      searchController.selection = TextSelection.collapsed(
        offset: searchController.text.length,
      );
    });
  }
void _applyHarvestPulseShopRequest() {
  final request =
      harvestPulseShopRequest.value?.trim().toLowerCase() ?? '';
      final freshPickId =
    harvestPulseFreshPickId.value?.trim();

  if (request.isEmpty || !mounted) return;

  String filter;

  switch (request) {
    case 'fresh':
      filter = 'Fresh harvest';
      break;

    case 'low_stock':
      filter = 'Low stock';
      break;

    case 'deals':
      filter = 'Deals';
      break;

    default:
      filter = 'All items';
      break;
  }

  setState(() {
    selectedCategory = 'All';
    selectedShopFilter = filter;
    selectedShopNutrient = 'All';
    selectedSort = 'Featured';
    searchController.clear();
    harvestPulseFreshPickIdContext =
    freshPickId != null && freshPickId.isNotEmpty
        ? freshPickId
        : null;

    // Remember that the customer came from Harvest Pulse.
    harvestPulseContext = request;
  });

  harvestPulseShopRequest.value = null;
  harvestPulseFreshPickId.value = null;
}
Widget _harvestPulseShopBanner(int itemCount) {
  final contextType = harvestPulseContext;

  if (contextType == null || contextType.isEmpty) {
    return const SizedBox.shrink();
  }

  String title;
  String message;
  IconData icon;

  switch (contextType) {
    case 'fresh':
      title = 'Fresh harvest';
      message =
          '$itemCount ${itemCount == 1 ? 'item was' : 'items were'} harvested this week.';
      icon = Icons.eco_outlined;
      break;

    case 'low_stock':
      title = 'Moving fast';
      message =
          '$itemCount ${itemCount == 1 ? 'item is' : 'items are'} moving into limited supply.';
      icon = Icons.trending_down_rounded;
      break;

    case 'deals':
      title = 'Price opportunities';
      message =
          '$itemCount fresh ${itemCount == 1 ? 'deal is' : 'deals are'} available right now.';
      icon = Icons.local_offer_outlined;
      break;

    default:
      title = 'Marketplace pulse';
      message =
          'Showing fresh activity from across The Harvest Place Ja.';
      icon = Icons.monitor_heart_outlined;
      break;
  }

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.fromLTRB(
      14,
      13,
      10,
      13,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F8F1),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: FarmColors.green.withOpacity(0.13),
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: FarmColors.primarySoft,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: FarmColors.green,
            size: 19,
          ),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'HARVEST PULSE',
                    style: TextStyle(
                      color: FarmColors.green,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),

                  const SizedBox(width: 6),

                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: FarmColors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 3),

              Text(
                title,
                style: const TextStyle(
                  color: FarmColors.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                message,
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

        const SizedBox(width: 6),

        
      ],
    ),
  );
}

  Widget _mealIngredientReturnCard() {
    return ValueListenableBuilder<String?>(
      valueListenable: mealIngredientReturnLabel,
      builder: (context, ingredientName, _) {
        final cleanName = ingredientName?.trim() ?? '';

        if (cleanName.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FarmCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: FarmColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: FarmColors.green.withOpacity(0.14),
                    ),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_outlined,
                    color: FarmColors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Shopping for $cleanName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FarmColors.deepGreen,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back_rounded, size: 17),
                  label: const Text('Back to meal'),
                  onPressed: () {
                    mealIngredientReturnLabel.value = null;
                    mealIngredientShopSearchRequest.value = null;

                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => WeeklyMealIdeasScreen(
                          onShopTap: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
    mealIngredientShopSearchRequest.addListener(_applyMealIngredientSearch);

harvestPulseShopRequest.addListener(
  _applyHarvestPulseShopRequest,
);
WidgetsBinding.instance.addPostFrameCallback((_) {
  _applyHarvestPulseShopRequest();
});
loadProducts();
    _loadSavedFavoritesForShop();
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
          selectedShopNutrient = 'All';
          searchController.clear();
        });
      }
    }
  }

  @override
void dispose() {
  mealIngredientShopSearchRequest.removeListener(
    _applyMealIngredientSearch,
  );

  harvestPulseShopRequest.removeListener(
    _applyHarvestPulseShopRequest,
  );

  searchDebounce?.cancel();
  searchController.dispose();
  super.dispose();
}
  void _addProductToCart(Product product) {
    widget.onAddToCart(product);
    Future.microtask(() => saveCartItemForCurrentUser(product));
  }

  void _removeProductFromCart(Product product) {
    widget.onRemoveFromCart(product);
    Future.microtask(() => removeCartItemForCurrentUser(product));
  }

  bool _isFavoriteProduct(Product product) {
    final productId = product.id.trim();
    return widget.isFavorite(product) ||
        (productId.isNotEmpty && persistedFavoriteIds.contains(productId));
  }

  Future<void> _loadSavedFavoritesForShop() async {
    try {
      final ids = await fetchFavoriteProductIdsForCurrentUser();
      if (!mounted) return;
      setState(() {
        persistedFavoriteIds = ids.toSet();
      });
    } catch (error) {
      farmDebugLog('Saved favorites load skipped in shop: $error');
    }
  }

  void _toggleFavoriteProduct(Product product) {
    final productId = product.id.trim();
    if (productId.isEmpty) return;

    final nextValue = !_isFavoriteProduct(product);

    widget.onToggleFavorite(product);

    setState(() {
      if (nextValue) {
        persistedFavoriteIds.add(productId);
      } else {
        persistedFavoriteIds.remove(productId);
      }
    });

    unawaited(setFavoriteForCurrentUser(product, isFavorite: nextValue));
  }

  void _rememberViewedProduct(Product product) {
    widget.onViewed(product);

    unawaited(
      saveRecentlyViewedForCurrentUser(product),
    );
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

    if (products.any(_isFavoriteProduct)) {
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
        'Fresh harvest',
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

  List<String> get shopNutrientOptions => const [
        'All',
        'Magnesium',
        'Iron',
        'Fiber',
        'Potassium',
        'Vitamin C',
        'Protein',
        'Calcium',
        'Antioxidants',
      ];

  String _cleanNutrientKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _listHasNutrient(List<String> values, String nutrient) {
    final key = _cleanNutrientKey(nutrient);
    if (key.isEmpty) return false;

    return values.any((value) => _cleanNutrientKey(value) == key);
  }

  int _productNutrientLevel(Product product, String nutrient) {
    if (_listHasNutrient(product.nutrientStrong, nutrient)) return 3;
    if (_listHasNutrient(product.nutrientGood, nutrient)) return 2;
    if (_listHasNutrient(product.nutrientContains, nutrient)) return 1;
    return 0;
  }

  bool _productMatchesNutrient(Product product, String nutrient) {
    if (nutrient.trim().toLowerCase() == 'all') return true;
    return _productNutrientLevel(product, nutrient) > 0;
  }

  String? _nutrientFromSearchQuery(String value) {
    final clean = _cleanNutrientKey(value);
    if (clean.isEmpty) return null;

    for (final nutrient in shopNutrientOptions) {
      if (nutrient == 'All') continue;

      final nutrientKey = _cleanNutrientKey(nutrient);
      if (clean == nutrientKey || clean.contains(nutrientKey)) {
        return nutrient;
      }
    }

    if (clean == 'vit c' || clean.contains('vit c')) return 'Vitamin C';
    if (clean == 'antioxidant' || clean.contains('antioxidant')) {
      return 'Antioxidants';
    }

    return null;
  }

  String? _activeShopNutrient() {
    final searchNutrient = _nutrientFromSearchQuery(searchController.text);
    if (searchNutrient != null) return searchNutrient;

    if (selectedShopNutrient != 'All') return selectedShopNutrient;

    return null;
  }

  int _shopNutrientRankScore(Product product, String nutrient) {
    final level = _productNutrientLevel(product, nutrient);
    var score = level * 1000;

    if (product.nutritionVerified) score += 80;
    if (product.canAddToCart) score += 40;
    if (product.hasActiveDiscount) score += 10;

    return score;
  }

  String _shopDisplayNutrientName(String value) {
    switch (_cleanNutrientKey(value)) {
      case 'magnesium':
        return 'Magnesium';
      case 'iron':
        return 'Iron';
      case 'fiber':
      case 'fibre':
        return 'Fiber';
      case 'potassium':
        return 'Potassium';
      case 'vitamin c':
      case 'vit c':
        return 'Vitamin C';
      case 'protein':
        return 'Protein';
      case 'calcium':
        return 'Calcium';
      case 'antioxidant':
      case 'antioxidants':
        return 'Antioxidants';
      default:
        final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');

        return clean
            .split(' ')
            .where((word) => word.isNotEmpty)
            .map(
              (word) =>
                  '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
            )
            .join(' ');
    }
  }

  List<String> _nutrientBadgesForProduct(
    Product product, {
    String? selectedNutrient,
    int? limit = 3,
  }) {
    final badges = <String>[];
    final seenNutrients = <String>{};

    void addBadge(String level, String nutrient) {
      final cleanNutrient = _shopDisplayNutrientName(nutrient);
      final nutrientKey = _cleanNutrientKey(cleanNutrient);

      if (cleanNutrient.isEmpty || nutrientKey.isEmpty) return;
      if (!seenNutrients.add(nutrientKey)) return;

      final cleanLevel = switch (level.trim().toLowerCase()) {
        'strong' => 'Strong',
        'good' => 'Good',
        _ => 'Contains',
      };

      badges.add('$cleanLevel $cleanNutrient');
    }

    final priority = selectedNutrient == null
        ? shopNutrientOptions.where((item) => item != 'All').toList()
        : <String>[
            selectedNutrient,
            ...shopNutrientOptions.where(
              (item) => item != 'All' && item != selectedNutrient,
            ),
          ];

    for (final nutrient in priority) {
      if (_listHasNutrient(product.nutrientStrong, nutrient)) {
        addBadge('Strong', nutrient);
      } else if (_listHasNutrient(product.nutrientGood, nutrient)) {
        addBadge('Good', nutrient);
      } else if (_listHasNutrient(product.nutrientContains, nutrient)) {
        addBadge('Contains', nutrient);
      }

      if (limit != null && badges.length >= limit) {
        break;
      }
    }

    return badges;
  }

  List<Product> filteredProducts(String activeCategory) {
    final rawQuery = searchController.text.trim();
    final query = rawQuery.toLowerCase();
    final activeCategoryLower = activeCategory.toLowerCase();
    final showingFavorites = activeCategoryLower == 'favorites';
    final cleanFilter = selectedShopFilter.trim().toLowerCase();

    final searchNutrient = _nutrientFromSearchQuery(rawQuery);
    final activeNutrient = searchNutrient ??
        (selectedShopNutrient == 'All' ? null : selectedShopNutrient);

    return products.where((product) {
      final category = product.category.trim().toLowerCase();
      final name = product.name.trim().toLowerCase();
      final description = (product.description ?? '').trim().toLowerCase();
      final unit = (product.unit ?? '').trim().toLowerCase();
      final farmName =
          (product.farmName ?? product.farmerName ?? '').trim().toLowerCase();

      final matchesCategory = showingFavorites
          ? _isFavoriteProduct(product)
          : activeCategory == 'All' ||
              category == activeCategoryLower ||
              name.contains(activeCategoryLower);

      final matchesSearch = query.isEmpty ||
          searchNutrient != null ||
          name.contains(query) ||
          category.contains(query) ||
          description.contains(query) ||
          unit.contains(query) ||
          farmName.contains(query) ||
          hpjSmartProductMatchesSearch(product, rawQuery);

      final matchesNutrient = activeNutrient == null ||
          _productMatchesNutrient(product, activeNutrient);

     final matchesFilter = cleanFilter == 'all items' ||
    (cleanFilter == 'fresh harvest' &&
        product.canAddToCart &&
        product.isLocal &&
        isProductHarvestedThisWeek(product)) ||
    (cleanFilter == 'in stock' && product.canAddToCart) ||
    (cleanFilter == 'low stock' && product.isLowStock) ||
    (cleanFilter == 'deals' && product.hasActiveDiscount) ||
    (cleanFilter == 'organic' && product.isOrganic) ||
    (cleanFilter == 'out of stock' && product.isOutOfStock);

      // When the customer types in the search box, search the whole shop.
      // This prevents a selected category chip from hiding valid search results.
      if (query.isNotEmpty) {
        return matchesSearch &&
            matchesNutrient &&
            matchesFilter &&
            (!showingFavorites || _isFavoriteProduct(product));
      }

      return matchesCategory && matchesNutrient && matchesFilter;
    }).toList();
  }

  List<Product> sortedShopProducts(List<Product> source) {
    final output = List<Product>.from(source);
    final activeNutrient = _activeShopNutrient();
    final smartQuery = searchController.text.trim();

    if (smartQuery.isNotEmpty && selectedSort == 'Featured') {
      output.sort((a, b) {
        final scoreCompare = hpjSmartProductSearchScore(b, smartQuery)
            .compareTo(hpjSmartProductSearchScore(a, smartQuery));
        if (scoreCompare != 0) return scoreCompare;
        if (a.canAddToCart != b.canAddToCart) return a.canAddToCart ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return output;
    }

    if (activeNutrient != null) {
      output.sort((a, b) {
        final nutrientCompare = _shopNutrientRankScore(
          b,
          activeNutrient,
        ).compareTo(_shopNutrientRankScore(a, activeNutrient));

        if (nutrientCompare != 0) return nutrientCompare;

        if (a.canAddToCart != b.canAddToCart) {
          return a.canAddToCart ? -1 : 1;
        }

        final priceCompare = a.effectivePrice.compareTo(b.effectivePrice);
        if (priceCompare != 0) return priceCompare;

        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      return output;
      // =====================================================
// HARVEST PULSE — TODAY'S FRESH PICK FIRST
// =====================================================
if (harvestPulseContext == 'fresh' &&
    selectedSort == 'Featured' &&
    harvestPulseFreshPickIdContext != null) {
  final pickIndex = output.indexWhere(
    (product) =>
        product.id ==
        harvestPulseFreshPickIdContext,
  );

  if (pickIndex > 0) {
    final freshPick =
        output.removeAt(pickIndex);

    output.insert(0, freshPick);
  }
}
    }

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
    final activeNutrient = _activeShopNutrient();

    if (selectedCategory != 'All') parts.add(selectedCategory);
    if (activeNutrient != null) parts.add(activeNutrient);
    if (selectedShopFilter != 'All items') parts.add(selectedShopFilter);
    if (selectedSort != 'Featured' && activeNutrient == null) {
      parts.add(selectedSort);
    }

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
                              subtitle:
                                  'Choose category, nutrients, stock, and sorting',
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
                        'Shop by Nutrient',
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
                        children: shopNutrientOptions.map((nutrient) {
                          return sheetChoice(
                            label: nutrient,
                            selected: selectedShopNutrient == nutrient,
                            onTap: () {
                              setState(() {
                                selectedShopNutrient = nutrient;
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
                                  selectedShopNutrient = 'All';
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
        selectedShopNutrient != 'All' ||
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
                    onSubmitted: (value) {
                      unawaited(HpjSmartLocalStore.rememberRecentSearch(value));
                      if (mounted) setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Search products, farms, or nutrients...',
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
    selectedShopNutrient != 'All' ||
    selectedSort != 'Featured' ||
    searchController.text.trim().isNotEmpty)
  TextButton(
    onPressed: () {
      setState(() {
        harvestPulseContext = null;
        harvestPulseFreshPickIdContext = null;
        selectedCategory = 'All';
        selectedShopFilter = 'All items';
        selectedShopNutrient = 'All';
        selectedSort = 'Featured';
        searchController.clear();
      });
    },
    style: TextButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
    ),
    child: const Text('Clear'),
  ),

], // Row children
), // Row

], // Column children
), // Column
), // Container
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
    final favoriteProducts = products.where(_isFavoriteProduct).toList();
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
    final contentSections = <Widget>[
      if (harvestPulseContext != null)
        _harvestPulseShopBanner(
          availableNowProducts.length,
        ),
      if (hpjCurrentUserExperiencePreferences.showFreshReels) ...[
        FreshReelFeedPreviewCard(
          preferences: hpjCurrentUserExperiencePreferences,
          audience: 'customer',
          placement: freshReelPlacementShop,
          onAddToCart: _addProductToCart,
        ),
        const SizedBox(height: 14),
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
              const Icon(
                Icons.info_outline,
                color: FarmColors.green,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(productLoadMessage!),
              ),
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
          final activeNutrient = _activeShopNutrient();

          final shopNutrientBadges = _nutrientBadgesForProduct(
            product,
            selectedNutrient: activeNutrient,
          );

          final detailNutrientBadges = _nutrientBadgesForProduct(
            product,
            selectedNutrient: activeNutrient,
            limit: null,
          );

          return SafeShopProductTile(
            key: ValueKey(
              'shop-${product.id}-${product.name}',
            ),
            product: product,
            quantity: quantity,
            nutrientBadges: shopNutrientBadges,
            isFavorite: _isFavoriteProduct(product),
            isFreshPick:
    harvestPulseContext == 'fresh' &&
    harvestPulseFreshPickIdContext != null &&
    product.id == harvestPulseFreshPickIdContext,
            onFavorite: () => _toggleFavoriteProduct(product),
            onAdd: () => _addProductToCart(product),
            onRemove: () => _removeProductFromCart(product),
            onOpenDetails: () async {
              _rememberViewedProduct(product);

              final nutrientToFilter = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (detailContext) => ProductDetailScreen(
                    product: product,
                    quantity: quantity,
                    nutrientBadges: detailNutrientBadges,
                    onNutrientTap: (nutrient) {
                      Navigator.of(detailContext).pop(nutrient);
                    },
                    onAdd: () => _addProductToCart(product),
                    onRemove: () => _removeProductFromCart(product),
                    onAddProduct: _addProductToCart,
                    onViewed: _rememberViewedProduct,
                    onViewMyBox: widget.onViewMyBox,
                    onCheckout: widget.onCheckout,
                  ),
                ),
              );

              if (!mounted ||
                  nutrientToFilter == null ||
                  nutrientToFilter.trim().isEmpty) {
                return;
              }

              setState(() {
                selectedCategory = 'All';
                selectedShopFilter = 'All items';
                selectedShopNutrient = nutrientToFilter.trim();
                selectedSort = 'Featured';
                searchController.clear();
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Showing products with '
                    '${nutrientToFilter.trim()}.',
                  ),
                  behavior: SnackBarBehavior.floating,
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
                children: [
                  _mealIngredientReturnCard(),
                  ...contentSections,
                ],
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
  final List<String> nutrientBadges;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final bool isFreshPick;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onOpenDetails;

  const SafeShopProductTile({
    super.key,
    required this.product,
    required this.quantity,
    this.nutrientBadges = const [],
    required this.isFavorite,
    required this.onFavorite,
    this.isFreshPick = false,
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
        width: 34,
        height: 34,
        child: Material(
          color: isFavorite ? FarmColors.dangerSoft : Colors.white,
          shape: const CircleBorder(),
          elevation: isFavorite ? 0 : 1,
          shadowColor: FarmColors.shadow.withOpacity(0.10),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onFavorite,
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
              size: 18,
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
          height: 32,
          width: 32,
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
        width: fullWidth ? double.infinity : 126,
        height: 40,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: FarmColors.green.withOpacity(0.18)),
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
                    fontSize: 13,
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
          width: fullWidth ? double.infinity : 132,
          child: NotifyMeWhenReadyButton(product: product, compact: true),
        );
      }

      return SizedBox(
        width: fullWidth ? double.infinity : 116,
        height: 40,
        child: ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded, size: 17),
          label: const Text('Add'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      );
    }

    Widget imageBlock() {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 82,
            width: 82,
            decoration: BoxDecoration(
              color: FarmColors.primarySoft.withOpacity(0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FarmColors.line.withOpacity(0.70)),
            ),
            child: Center(
              child: ProductVisual(
                product: product,
                size: 64,
                showOrganicBadge: false,
              ),
            ),
          ),
          if (product.hasActiveDiscount && !product.isOutOfStock)
            Positioned(
              top: -5,
              left: -5,
              child: DiscountBadge(product: product, compact: true),
            ),
        ],
      );
    }

    Widget badges() {
      return Wrap(
        spacing: 5,
        runSpacing: 5,
        children: [
          if (isFreshPick)
  const _SmallShopChip(
    label: 'Today’s Fresh Pick',
    color: Color(0xFF725417),
    backgroundColor: Color(0xFFFFF3D8),
  ),
          if (product.isOrganic) const _SmallShopChip(label: 'Organic'),
          ProductOriginBadge(
            product: product,
            compact: true,
            includeIcon: false,
          ),
          ProductUnitChip(product: product, compact: true),
          ProductAvailabilityChip(product: product, compact: true),
          for (final badge in nutrientBadges)
            _SmallShopChip(
              label: badge,
              color: FarmColors.deepGreen,
              backgroundColor: FarmColors.primarySoft.withOpacity(0.78),
            ),
        ],
      );
    }

    Widget footer() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: muted
              ? FarmColors.cardSoft
              : FarmColors.primarySoft.withOpacity(0.58),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: FarmColors.line.withOpacity(0.65)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 235;
            final price = DiscountPriceText(
              product: product,
              compact: true,
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  price,
                  const SizedBox(height: 9),
                  primaryAction(fullWidth: true),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: price),
                const SizedBox(width: 10),
                primaryAction(fullWidth: false),
              ],
            );
          },
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: muted ? FarmColors.cardSoft : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: muted
              ? FarmColors.danger.withOpacity(0.13)
              : FarmColors.line.withOpacity(0.82),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: FarmColors.shadow.withOpacity(muted ? 0.02 : 0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onOpenDetails,
          child: Opacity(
            opacity: 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      imageBlock(),
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
                                    name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: FarmColors.ink,
                                      fontSize: 16.2,
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
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 12.1,
                                height: 1.23,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  badges(),
                  const SizedBox(height: 10),
                  footer(),
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

class FarmBoxScreen extends StatefulWidget {
  final List<Product> cart;
  final void Function(Product product) onRemoveFromCart;
  final void Function(Product product) onAddToCart;
  final VoidCallback onOrderPlaced;
  final VoidCallback onShopTap;
  final VoidCallback? onInventoryChanged;

  const FarmBoxScreen({
    super.key,
    required this.cart,
    required this.onRemoveFromCart,
    required this.onAddToCart,
    required this.onOrderPlaced,
    required this.onShopTap,
    this.onInventoryChanged,
  });

  @override
  State<FarmBoxScreen> createState() => _FarmBoxScreenState();
}

class _FarmBoxScreenState extends State<FarmBoxScreen> {
  List<CartLine>? savedCartLines;
  bool loadingSavedCart = false;

  List<Product> get cart => widget.cart;
  VoidCallback? get onInventoryChanged => widget.onInventoryChanged;

  @override
  void initState() {
    super.initState();
    _loadSavedCartIfNeeded();
  }

  @override
  void didUpdateWidget(covariant FarmBoxScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cart.isNotEmpty) {
      savedCartLines = null;
      return;
    }
    if (oldWidget.cart.length != widget.cart.length && widget.cart.isEmpty) {
      _loadSavedCartIfNeeded();
    }
  }

  Future<void> _loadSavedCartIfNeeded() async {
    if (!isLoggedIn || widget.cart.isNotEmpty || loadingSavedCart) return;

    setState(() => loadingSavedCart = true);
    try {
      final lines = await fetchSavedCartLinesForCurrentUser();
      if (!mounted || widget.cart.isNotEmpty) return;
      setState(() => savedCartLines = lines);
    } catch (error) {
      farmDebugLog('Saved farm box restore skipped: $error');
    } finally {
      if (mounted) setState(() => loadingSavedCart = false);
    }
  }

  void onAddToCart(Product product) {
    widget.onAddToCart(product);
    if (savedCartLines != null || widget.cart.isEmpty) {
      _adjustSavedLine(product, 1);
    }
    Future.microtask(() => saveCartItemForCurrentUser(product));
  }

  void onRemoveFromCart(Product product) {
    widget.onRemoveFromCart(product);
    if (savedCartLines != null || widget.cart.isEmpty) {
      _adjustSavedLine(product, -1);
    }
    Future.microtask(() => removeCartItemForCurrentUser(product));
  }

  void onOrderPlaced() {
    setState(() => savedCartLines = const <CartLine>[]);
    Future.microtask(clearSavedCartForCurrentUser);
    widget.onOrderPlaced();
  }

  void _adjustSavedLine(Product product, int delta) {
    final current = List<CartLine>.from(savedCartLines ?? const <CartLine>[]);
    final index = current.indexWhere((line) => line.product.id == product.id);

    if (index < 0) {
      if (delta > 0) {
        current.add(CartLine(product: product, quantity: 1));
      }
    } else {
      final nextQuantity = current[index].quantity + delta;
      if (nextQuantity <= 0) {
        current.removeAt(index);
      } else {
        current[index] = current[index].copyWith(quantity: nextQuantity);
      }
    }

    if (mounted) {
      setState(() => savedCartLines = current);
    }
  }

  Map<String, CartLine> get groupedCart {
    final restoredLines = savedCartLines;
    if (widget.cart.isEmpty && restoredLines != null) {
      return <String, CartLine>{
        for (final line in restoredLines)
          if (line.product.id.trim().isNotEmpty && line.quantity > 0)
            line.product.id: line,
      };
    }

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

  int get distinctItems => groupedCart.length;

  Widget _miniStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2EEDF)),
        ),
        child: Row(
          children: [
            Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDEED8)),
              ),
              child: Icon(icon, color: FarmColors.green, size: 16),
            ),
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
                      color: Color(0xFF24382A),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF667568),
                      fontWeight: FontWeight.w800,
                      fontSize: 10.4,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFEFA),
            Color(0xFFF6FBF3),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2EEDF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7E9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDDEED8)),
                ),
                child: const Icon(
                  Icons.shopping_basket_outlined,
                  color: FarmColors.green,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Farm Box',
                      style: TextStyle(
                        color: Color(0xFF24382A),
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.45,
                        height: 1.03,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      hasItems
                          ? 'Review each item, adjust quantities, share your list, then checkout.'
                          : 'Your fresh picks will stay here until you are ready to checkout.',
                      style: const TextStyle(
                        color: Color(0xFF667568),
                        fontWeight: FontWeight.w700,
                        height: 1.26,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasItems) ...[
            Row(
              children: [
                _miniStat(
                  icon: Icons.inventory_2_outlined,
                  label: 'Items',
                  value: '0',
                ),
                const SizedBox(width: 10),
                _miniStat(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Status',
                  value: 'Ready',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1FAEF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDDEED8)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFEFA),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFDDEED8)),
                    ),
                    child: const Icon(
                      Icons.spa_outlined,
                      color: FarmColors.green,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Tap Shop below to add fresh produce, pantry items, or nutrient-focused picks.',
                      style: TextStyle(
                        color: Color(0xFF24382A),
                        fontWeight: FontWeight.w800,
                        fontSize: 12.2,
                        height: 1.28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                _miniStat(
                  icon: Icons.inventory_2_outlined,
                  label: 'Items',
                  value: '$totalItems',
                ),
                const SizedBox(width: 10),
                _miniStat(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Products',
                  value: '$distinctItems',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _miniStat(
                  icon: totalSavings > 0
                      ? Icons.savings_outlined
                      : Icons.receipt_long_outlined,
                  label: totalSavings > 0 ? 'Saved' : 'Subtotal',
                  value: totalSavings > 0
                      ? formatJmd(totalSavings)
                      : formatJmd(subtotal),
                ),
                const SizedBox(width: 10),
                _miniStat(
                  icon: Icons.lock_outline,
                  label: 'Checkout',
                  value: 'Ready',
                ),
              ],
            ),
          ],
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
            constraints: const BoxConstraints(minWidth: 50),
            padding: const EdgeInsets.symmetric(horizontal: 7),
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

  Widget _selectedItemsHeader(List<CartLine> lines) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected items',
                style: TextStyle(
                  color: FarmColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.25,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Review each item before checkout.',
                style: TextStyle(
                  color: FarmColors.mutedText,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.2,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: FarmColors.primarySoft,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: FarmColors.green.withOpacity(0.10)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.touch_app_outlined,
                color: FarmColors.green,
                size: 14,
              ),
              const SizedBox(width: 5),
              Text(
                '+ / -',
                style: TextStyle(
                  color: FarmColors.green.withOpacity(0.94),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ProductVisual(product: product, size: 74),
                  ),
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: FarmColors.shadow.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        'x${line.quantity}',
                        style: const TextStyle(
                          color: FarmColors.green,
                          fontWeight: FontWeight.w900,
                          fontSize: 10.5,
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
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.16,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (farmName.isNotEmpty) ...[
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
                      const SizedBox(height: 8),
                    ] else
                      const SizedBox(height: 8),
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
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FarmColors.cardSoft,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: FarmColors.line.withOpacity(0.72)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Line total',
                        style: TextStyle(
                          color: FarmColors.mutedText,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        formatJmd(lineTotal),
                        style: const TextStyle(
                          color: FarmColors.green,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
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
                const SizedBox(width: 10),
                _quantityControl(line),
              ],
            ),
          ),
          if (!product.canAddToCart) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FarmColors.dangerSoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: FarmColors.danger.withOpacity(0.14)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, size: 16, color: FarmColors.danger),
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
            ),
          ],
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

  String _shareListText(List<CartLine> lines) {
    final buffer = StringBuffer();
    buffer.writeln('My ${AppConfig.appName} farm list:');
    buffer.writeln('');

    for (final line in lines) {
      final product = line.product;
      final unit = (product.unit ?? '').trim();
      final unitLabel = unit.isEmpty ? '' : ' • $unit';
      final lineTotal = product.effectivePrice * line.quantity;

      buffer.writeln(
        '• ${product.name} x ${line.quantity}$unitLabel — ${formatJmd(lineTotal)}',
      );
    }

    buffer.writeln('');
    buffer.writeln('Estimated subtotal: ${formatJmd(subtotal)}');

    final link = AppConfig.shareableAppLink.trim();
    if (link.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('View the market: $link');
    }

    return buffer.toString().trim();
  }

  Future<bool> _openWhatsAppText(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return false;

    final encoded = Uri.encodeComponent(cleanText);
    final appUrl = 'whatsapp://send?text=$encoded';
    final webUrl = 'https://wa.me/?text=$encoded';

    try {
      final openedApp = await openExternalShareUrl(appUrl);
      if (openedApp) return true;
    } catch (error) {
      farmDebugLog('WhatsApp app share unavailable: $error');
    }

    try {
      final openedWeb = await openExternalShareUrl(webUrl);
      if (openedWeb) return true;
    } catch (error) {
      farmDebugLog('WhatsApp web share unavailable: $error');
    }

    return false;
  }

  Future<void> _copyShareList(
    BuildContext context,
    List<CartLine> lines,
  ) async {
    if (lines.isEmpty) return;

    await Clipboard.setData(
      ClipboardData(text: _shareListText(lines)),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Farm list copied.')),
    );
  }

  Future<void> _shareListOnWhatsApp(
    BuildContext context,
    List<CartLine> lines,
  ) async {
    if (lines.isEmpty) return;

    final shareText = _shareListText(lines);
    final opened = await _openWhatsAppText(shareText);

    if (!context.mounted) return;

    if (opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening WhatsApp share...')),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: shareText));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Farm list copied. Open WhatsApp and paste it.'),
      ),
    );
  }

  Widget _emptyBoxInviteCard(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onShopTap,
      child: FarmCard(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: FarmColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(color: FarmColors.green.withOpacity(0.12)),
                boxShadow: [
                  BoxShadow(
                    color: FarmColors.green.withOpacity(0.07),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_basket_outlined,
                color: FarmColors.green,
                size: 34,
              ),
            ),
            const SizedBox(height: 17),
            const Text(
              'Your box is waiting',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FarmColors.ink,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.25,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Add fresh produce, weekly staples, or nutrient-focused picks from the Shop.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FarmColors.mutedText,
                fontWeight: FontWeight.w700,
                height: 1.32,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: FarmColors.cardSoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: FarmColors.line.withOpacity(0.82)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: FarmColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      color: FarmColors.green,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start from the Shop tab',
                          style: TextStyle(
                            color: FarmColors.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 13.4,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Search items, nutrients, farms, or build a fresh box.',
                          style: TextStyle(
                            color: FarmColors.mutedText,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: FarmColors.green,
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shareListCard(BuildContext context, List<CartLine> lines) {
    return FarmCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: FarmColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FarmColors.green.withOpacity(0.10)),
                ),
                child: const Icon(
                  Icons.ios_share_outlined,
                  color: FarmColors.green,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share My List',
                      style: TextStyle(
                        color: FarmColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Send this box by WhatsApp or copy it.',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.2,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('WhatsApp'),
                  onPressed: () => _shareListOnWhatsApp(context, lines),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copy'),
                  onPressed: () => _copyShareList(context, lines),
                ),
              ),
            ],
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
        margin: const EdgeInsets.fromLTRB(0, 8, 0, 18),
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
    final hasItems = lines.isNotEmpty;

    if (loadingSavedCart && widget.cart.isEmpty && savedCartLines == null) {
      return const FarmPage(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return FarmPage(
      child: Stack(
        children: [
          ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              18,
              18,
              18,
              hasItems ? 250 : 120,
            ),
            children: [
              _boxHeroCard(lines),
              const SizedBox(height: 18),
              if (lines.isEmpty)
                _emptyBoxInviteCard(context)
              else ...[
                _selectedItemsHeader(lines),
                const SizedBox(height: 12),
                ...lines.map(_cartLineCard),
                const SizedBox(height: 6),
                _shareListCard(context, lines),
                const SizedBox(height: 18),
              ],
            ],
          ),
          if (hasItems)
            Positioned(
              left: 18,
              right: 18,
              bottom: 0,
              child: _checkoutBar(context, lines),
            ),
        ],
      ),
    );
  }
}

class OrdersScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final void Function(Product product)? onAddToCart;
  final VoidCallback? onOpenMyBox;

  const OrdersScreen({
    super.key,
    this.onBackToHome,
    this.onAddToCart,
    this.onOpenMyBox,
  });

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
                            builder: (_) => OrderDetailsScreen(
                              orderId: order.id,
                              onAddToCart: widget.onAddToCart,
                              onOpenMyBox: widget.onOpenMyBox,
                            ),
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

class _ReorderPreviewLine {
  final OrderDetailsItem previousItem;
  final Product? product;
  final String unavailableReason;
  bool selected;

  _ReorderPreviewLine({
    required this.previousItem,
    required this.product,
    required this.unavailableReason,
    required this.selected,
  });

  bool get isAvailable => product != null && product!.canAddToCart;

  double get currentLineTotal {
    final currentProduct = product;
    if (currentProduct == null) return 0;

    final quantity = previousItem.quantity < 1 ? 1 : previousItem.quantity;

    return currentProduct.effectivePrice * quantity;
  }
}

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  final void Function(Product product)? onAddToCart;
  final VoidCallback? onOpenMyBox;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    this.onAddToCart,
    this.onOpenMyBox,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Future<OrderDetails?> _orderFuture;
  bool _loadingReorder = false;
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

  Future<String?> _fetchCustomerBoxPhotoUrl() async {
    final response = await supabase
        .from('orders')
        .select('box_photo_url')
        .eq('id', widget.orderId)
        .maybeSingle();

    final url = response?['box_photo_url']?.toString().trim();

    if (url == null || url.isEmpty) return null;

    return url;
  }

  Future<void> _openReorderPreview(
    OrderDetails order,
  ) async {
    if (_loadingReorder) return;

    final addToCart = widget.onAddToCart;

    if (addToCart == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reorder is not available from this screen right now.',
          ),
        ),
      );
      return;
    }

    setState(() => _loadingReorder = true);

    try {
      final productIds = order.items
          .map((item) => item.productId.trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (productIds.isEmpty) {
        throw Exception(
          'The products from this order could not be identified.',
        );
      }

      final response =
          await supabase.from('products').select().inFilter('id', productIds);

      final currentProducts = (response as List)
          .map(
            (row) => Product.fromSupabase(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();

      final productsById = <String, Product>{
        for (final product in currentProducts) product.id.trim(): product,
      };

      final previewLines = order.items.map((previousItem) {
        final productId = previousItem.productId.trim();
        final product = productsById[productId];

        String unavailableReason = '';

        if (product == null) {
          unavailableReason = 'No longer listed';
        } else if (product.isOutOfStock) {
          unavailableReason = 'Out of stock';
        } else if (!product.canAddToCart) {
          unavailableReason = 'Currently unavailable';
        }

        return _ReorderPreviewLine(
          previousItem: previousItem,
          product: product,
          unavailableReason: unavailableReason,
          selected: product != null && product.canAddToCart,
        );
      }).toList();

      if (!mounted) return;

      final availableLines =
          previewLines.where((line) => line.isAvailable).toList();

      if (availableLines.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'None of the products from this order are available right now.',
            ),
          ),
        );
        return;
      }

      final confirmedLines =
          await showModalBottomSheet<List<_ReorderPreviewLine>>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: FarmColors.background,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              final available =
                  previewLines.where((line) => line.isAvailable).toList();

              final unavailable =
                  previewLines.where((line) => !line.isAvailable).toList();

              final selected =
                  available.where((line) => line.selected).toList();

              final estimatedTotal = selected.fold<double>(
                0,
                (total, line) => total + line.currentLineTotal,
              );

              return FractionallySizedBox(
                heightFactor: 0.88,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    14,
                    18,
                    18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: FarmColors.line,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Reorder Review',
                        style: TextStyle(
                          color: FarmColors.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Prices and availability have been refreshed. '
                        'Review the products before adding them to My Box.',
                        style: TextStyle(
                          color: FarmColors.mutedText,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: ListView(
                          children: [
                            const Text(
                              'Available today',
                              style: TextStyle(
                                color: FarmColors.green,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...available.map((line) {
                              final product = line.product!;
                              final quantity = line.previousItem.quantity < 1
                                  ? 1
                                  : line.previousItem.quantity;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: FarmColors.card,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: FarmColors.line,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: line.selected,
                                      onChanged: (value) {
                                        setSheetState(() {
                                          line.selected = value ?? false;
                                        });
                                      },
                                    ),
                                    ProductVisual(
                                      product: product,
                                      size: 48,
                                      showOrganicBadge: false,
                                    ),
                                    const SizedBox(width: 11),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(
                                              color: FarmColors.ink,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Qty: $quantity • '
                                            '${formatJmd(product.effectivePrice)} each',
                                            style: const TextStyle(
                                              color: FarmColors.mutedText,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      formatJmd(
                                        line.currentLineTotal,
                                      ),
                                      style: const TextStyle(
                                        color: FarmColors.green,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            if (unavailable.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Unavailable today',
                                style: TextStyle(
                                  color: FarmColors.danger,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...unavailable.map(
                                (line) => Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(
                                    bottom: 9,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: FarmColors.cardSoft,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: FarmColors.line,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.block_outlined,
                                        color: FarmColors.danger,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          line.previousItem.productName,
                                          style: const TextStyle(
                                            color: FarmColors.ink,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        line.unavailableReason,
                                        style: const TextStyle(
                                          color: FarmColors.danger,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: FarmColors.primarySoft,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: FarmColors.line,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Estimated total',
                                style: TextStyle(
                                  color: FarmColors.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              formatJmd(estimatedTotal),
                              style: const TextStyle(
                                color: FarmColors.green,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.shopping_basket_outlined,
                          ),
                          label: const Text(
                            'Add Selected to My Box',
                          ),
                          onPressed: selected.isEmpty
                              ? null
                              : () {
                                  Navigator.of(sheetContext).pop(
                                    List<_ReorderPreviewLine>.from(
                                      selected,
                                    ),
                                  );
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

      if (confirmedLines == null || confirmedLines.isEmpty) {
        return;
      }

      for (final line in confirmedLines) {
        final product = line.product;

        if (product == null || !product.canAddToCart) {
          continue;
        }

        final quantity =
            line.previousItem.quantity < 1 ? 1 : line.previousItem.quantity;

        for (var count = 0; count < quantity; count++) {
          addToCart(product);
          await saveCartItemForCurrentUser(product);
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selected products were added to My Box.',
          ),
        ),
      );

      if (widget.onOpenMyBox != null) {
        widget.onOpenMyBox!.call();

        Navigator.of(context).popUntil(
          (route) => route.isFirst,
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not prepare this reorder: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingReorder = false);
      }
    }
  }

  Widget _customerBoxPhotoCard() {
    return FutureBuilder<String?>(
      future: _fetchCustomerBoxPhotoUrl(),
      builder: (context, snapshot) {
        final photoUrl = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (photoUrl == null || photoUrl.isEmpty) {
          return const SizedBox.shrink();
        }

        return FarmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.photo_camera_outlined, color: FarmColors.green),
                  SizedBox(width: 8),
                  Text(
                    'Your Box Photo',
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(18)),
                child: Image.network(
                  photoUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: FarmColors.cardSoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'Box photo could not be loaded.',
                        style: TextStyle(color: FarmColors.muted),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Photo proof of your packed fresh box.',
                style: TextStyle(
                  color: FarmColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
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

  Future<void> _downloadCustomerReceiptPdf(dynamic order) async {
    String safeText(
      Object? Function() read, {
      String fallback = 'Not available',
    }) {
      try {
        final value = read();
        if (value == null) return fallback;

        final text = value.toString().trim();
        if (text.isEmpty || text == 'null') return fallback;

        return text;
      } catch (_) {
        return fallback;
      }
    }

    String titleCase(String value) {
      final clean = value.replaceAll('_', ' ').trim();
      if (clean.isEmpty) return value;

      return clean
          .split(' ')
          .where((part) => part.trim().isNotEmpty)
          .map((part) {
        final lower = part.toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      }).join(' ');
    }

    List<dynamic> safeList(Object? Function() read) {
      try {
        final value = read();
        if (value is List) return value;
        return [];
      } catch (_) {
        return [];
      }
    }

    Object? readItemValue(dynamic item, String key) {
      try {
        if (item is Map) {
          return item[key];
        }

        switch (key) {
          case 'productName':
          case 'product_name':
            return item.productName;
          case 'name':
            return item.name;
          case 'quantity':
          case 'qty':
            return item.quantity;
          case 'formattedUnitPrice':
          case 'formatted_unit_price':
            return item.formattedUnitPrice;
          case 'unitPrice':
          case 'unit_price':
            return item.unitPrice;
          case 'price':
            return item.price;
          case 'formattedSubtotal':
          case 'formatted_subtotal':
            return item.formattedSubtotal;
          case 'subtotal':
          case 'line_total':
            return item.subtotal;
          case 'total':
            return item.total;
          default:
            return null;
        }
      } catch (_) {
        return null;
      }
    }

    String itemText(
      dynamic item,
      List<String> keys, {
      String fallback = '',
    }) {
      for (final key in keys) {
        final value = readItemValue(item, key);
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }

      return fallback;
    }

    pw.Widget infoBox({
      required String title,
      required List<String> lines,
    }) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColor.fromInt(0xFFD8E8D8)),
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF1F6B3A),
              ),
            ),
            pw.SizedBox(height: 8),
            ...lines.map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  line,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget amountRow(
      String label,
      String value, {
      bool bold = false,
      bool green = false,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: bold ? 13 : 10,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: green ? PdfColor.fromInt(0xFF1F6B3A) : PdfColors.black,
              ),
            ),
          ],
        ),
      );
    }

    try {
      final pdf = pw.Document();
      String formatReceiptDate(String rawValue) {
        final cleanValue = rawValue.trim();

        if (cleanValue.isEmpty || cleanValue.toLowerCase() == 'not available') {
          return 'Not available';
        }

        final parsedDate = DateTime.tryParse(cleanValue);

        if (parsedDate == null) {
          return cleanValue;
        }

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

        final hour12 = parsedDate.hour % 12 == 0 ? 12 : parsedDate.hour % 12;

        final minute = parsedDate.minute.toString().padLeft(2, '0');

        final period = parsedDate.hour >= 12 ? 'PM' : 'AM';

        return '${months[parsedDate.month - 1]} '
            '${parsedDate.day}, '
            '${parsedDate.year} - '
            '$hour12:$minute $period';
      }

      pw.MemoryImage? receiptLogo;

      try {
        final logoData = await rootBundle.load('lib/assets/images/logo.png');

        receiptLogo = pw.MemoryImage(
          logoData.buffer.asUint8List(
            logoData.offsetInBytes,
            logoData.lengthInBytes,
          ),
        );
      } catch (_) {
        receiptLogo = null;
      }
      final receiptOrder = await supabase
          .from('orders')
          .select('*, customers(*)')
          .eq('id', widget.orderId)
          .maybeSingle();

      final receiptItems = await supabase
          .from('order_items')
          .select('*, products(*)')
          .eq('order_id', widget.orderId);

      final shortId = safeText(() => order.shortId, fallback: widget.orderId);
      final status = safeText(() => order.status, fallback: 'Pending');
      final paymentStatus =
          safeText(() => order.paymentStatus, fallback: 'Unpaid');
      final fulfillment = safeText(
        () => order.formattedFulfillmentType,
        fallback: 'Farm Pickup',
      );
      final paymentMethod = safeText(
        () => order.formattedPaymentMethod,
        fallback: 'Payment on collection',
      );
      final total = safeText(() => order.formattedTotal, fallback: 'J\$0.00');
      final subtotal = safeText(() => order.formattedSubtotal, fallback: '');
      final deliveryFee =
          safeText(() => order.formattedDeliveryFee, fallback: '');
      final customer = receiptOrder?['customers'];

      String customerValue(List<String> keys,
          {String fallback = 'Not available'}) {
        try {
          for (final key in keys) {
            final orderValue = receiptOrder?[key];
            if (orderValue != null && orderValue.toString().trim().isNotEmpty) {
              return orderValue.toString().trim();
            }

            if (customer is Map) {
              final customerValue = customer[key];
              if (customerValue != null &&
                  customerValue.toString().trim().isNotEmpty) {
                return customerValue.toString().trim();
              }
            }
          }

          return fallback;
        } catch (_) {
          return fallback;
        }
      }

      final customerName = customerValue(
        [
          'customer_name',
          'full_name',
          'name',
          'display_name',
        ],
        fallback: 'Customer',
      );

      final customerPhone = customerValue(
        [
          'customer_phone',
          'phone',
          'phone_number',
        ],
        fallback: 'Not provided',
      );
      final createdAtRaw =
          safeText(() => order.createdAt, fallback: 'Not available');

      final createdAt = formatReceiptDate(createdAtRaw);
      final scheduledFor =
          safeText(() => order.scheduledFor, fallback: 'Not available');

      final items = receiptItems;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(34),
          build: (context) {
            return [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Company header
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.SizedBox(
                        width: 72,
                        height: 72,
                        child: receiptLogo != null
                            ? pw.Image(
                                receiptLogo!,
                                fit: pw.BoxFit.contain,
                              )
                            : pw.Container(
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  'HPJ',
                                  style: pw.TextStyle(
                                    fontSize: 20,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColor.fromInt(0xFF1F6B3A),
                                  ),
                                ),
                              ),
                      ),

                      pw.SizedBox(width: 12),

                      // Vertical divider
                      pw.Container(
                        width: 2,
                        height: 68,
                        color: PdfColor.fromInt(0xFF1F6B3A),
                      ),

                      pw.SizedBox(width: 14),

                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text(
                              'THE HARVEST PLACE JA',
                              style: pw.TextStyle(
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromInt(0xFF124D32),
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text(
                              'Mountainside, St. Elizabeth, Jamaica | Tel: 876-339-1395',
                              style: pw.TextStyle(
                                fontSize: 10.5,
                                color: PdfColor.fromInt(0xFF4B5450),
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Fresh - Local - Jamaican',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromInt(0xFF1F6B3A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 10),

                  pw.Container(
                    width: double.infinity,
                    height: 2,
                    color: PdfColor.fromInt(0xFF1F6B3A),
                  ),

                  pw.SizedBox(height: 8),

                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          'OFFICIAL CUSTOMER RECEIPT',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromInt(0xFF1F6B3A),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      pw.Text(
                        'Receipt #$shortId',
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF33443A),
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 18),

                  // Receipt information
                  // Clean green divider
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: infoBox(
                      title: 'Customer Details',
                      lines: [
                        'Name: $customerName',
                        'Phone: $customerPhone',
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: infoBox(
                      title: 'Order Details',
                      lines: [
                        'Order ID: $shortId',
                        'Order date: $createdAt',
                        'Scheduled: $scheduledFor',
                        'Fulfillment: $fulfillment',
                        'Payment method: $paymentMethod',
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 22),
              pw.Text(
                'Items Purchased',
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF1F6B3A),
                ),
              ),
              pw.SizedBox(height: 8),
              if (items.isEmpty)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColor.fromInt(0xFFD8E8D8)),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    'Item details were not available for this receipt.',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                )
              else
                pw.TableHelper.fromTextArray(
                  headers: ['Item', 'Qty', 'Unit Price', 'Subtotal'],
                  data: items.map((item) {
                    final name = itemText(
                      item,
                      ['productName', 'product_name', 'name'],
                      fallback: 'Item',
                    );

                    final qty = itemText(
                      item,
                      ['quantity', 'qty'],
                      fallback: '1',
                    );

                    final unitPrice = itemText(
                      item,
                      [
                        'formattedUnitPrice',
                        'formatted_unit_price',
                        'unitPrice',
                        'unit_price',
                        'price',
                      ],
                      fallback: '',
                    );

                    final itemSubtotal = itemText(
                      item,
                      [
                        'formattedSubtotal',
                        'formatted_subtotal',
                        'subtotal',
                        'line_total',
                        'total',
                      ],
                      fallback: '',
                    );

                    return [name, qty, unitPrice, itemSubtotal];
                  }).toList(),
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF1F6B3A),
                  ),
                  headerStyle: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  cellAlignment: pw.Alignment.centerLeft,
                  headerAlignment: pw.Alignment.centerLeft,
                  border: pw.TableBorder.all(
                    color: PdfColor.fromInt(0xFFD8E8D8),
                    width: 0.6,
                  ),
                  cellPadding: const pw.EdgeInsets.all(7),
                ),
              pw.SizedBox(height: 22),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 245,
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF8FAF7),
                    borderRadius: pw.BorderRadius.circular(10),
                    border: pw.Border.all(
                      color: PdfColor.fromInt(0xFFD8E8D8),
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      if (subtotal.isNotEmpty && subtotal != 'Not available')
                        amountRow('Subtotal', subtotal),
                      if (deliveryFee.isNotEmpty &&
                          deliveryFee != 'Not available')
                        amountRow('Delivery fee', deliveryFee),
                      pw.Divider(color: PdfColor.fromInt(0xFFD8E8D8)),
                      amountRow(
                        'Total',
                        total,
                        bold: true,
                        green: true,
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 28),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFFFFBF0),
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(
                    color: PdfColor.fromInt(0xFFE8D6A8),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Receipt Notes',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF1F6B3A),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Please keep this receipt for your records. You can view your order status, staff messages, and box photo proof inside the app under My Orders.',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColor.fromInt(0xFFD8E8D8)),
              pw.Text(
                'Thank you for supporting local farmers through The Harvest Place Ja.',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF1F6B3A),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Fresh produce. Local support. Better food for Jamaican families.',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ];
          },
        ),
      );

      final cleanShortId = shortId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'HPJ-Receipt-$cleanShortId.pdf',
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create receipt: $error'),
        ),
      );
    }
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
                const SizedBox(height: 12),
                if ((order.status.trim().toLowerCase() == 'completed' ||
                        order.status.trim().toLowerCase() == 'delivered') &&
                    widget.onAddToCart != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _loadingReorder
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.replay_rounded),
                      label: Text(
                        _loadingReorder
                            ? 'Checking Products...'
                            : 'Reorder This Order',
                      ),
                      onPressed: _loadingReorder
                          ? null
                          : () => _openReorderPreview(order),
                    ),
                  ),
                if ((order.status.trim().toLowerCase() == 'completed' ||
                        order.status.trim().toLowerCase() == 'delivered') &&
                    widget.onAddToCart != null)
                  const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Share / Save PDF Receipt'),
                  onPressed: () => _downloadCustomerReceiptPdf(order),
                ),
                const SizedBox(height: 14),
                _customerBoxPhotoCard(),
                const SizedBox(height: 12),
                CustomerOrderUpdatesCard(orderId: widget.orderId),
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
  State<FarmBoxHelperScreen> createState() => _FarmBoxHelperScreenState();
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
              FarmCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Invite friends',
                      style: TextStyle(
                        color: FarmColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Share your referral link and earn points when a new customer completes their first eligible order.',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontWeight: FontWeight.w700,
                        height: 1.32,
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.ios_share_outlined),
                      label: const Text('Open referral invite'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InviteFarmMarketScreen(),
                          ),
                        );
                      },
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
    return FutureBuilder<List<Product>>(
      future: fetchFavoriteProductsForCurrentUser(fallbackProducts: products),
      builder: (context, snapshot) {
        final savedProducts = snapshot.data ?? products;

        return ProductCollectionScreen(
          title: 'Favorites',
          subtitle: 'Saved products you love',
          products: savedProducts,
          emptyText:
              'No favorites yet. Tap the heart on products you love while shopping.',
          onShopTap: onShopTap,
        );
      },
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
    return FutureBuilder<List<Product>>(
      future: fetchRecentlyViewedProductsForCurrentUser(
        fallbackProducts: products,
      ),
      builder: (context, snapshot) {
        final savedProducts = snapshot.data ?? products;

        return ProductCollectionScreen(
          title: 'Recently Viewed',
          subtitle: 'Products you checked recently',
          products: savedProducts,
          emptyText:
              'No recently viewed products yet. Products you open will appear here.',
          onShopTap: onShopTap,
        );
      },
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

  final Set<String> selectedNotificationIds = <String>{};

  bool get isSelecting => selectedNotificationIds.isNotEmpty;
  void toggleNotificationSelection(
    FarmNotification notice,
  ) {
    if (notice.id.trim().isEmpty) return;

    setState(() {
      if (selectedNotificationIds.contains(notice.id)) {
        selectedNotificationIds.remove(notice.id);
      } else {
        selectedNotificationIds.add(notice.id);
      }
    });
  }

  void clearNotificationSelection() {
    setState(() {
      selectedNotificationIds.clear();
    });
  }

  Future<void> deleteNotificationsByIds(
    Set<String> notificationIds,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null || notificationIds.isEmpty) {
      return;
    }

    final ids = notificationIds.where((id) => id.trim().isNotEmpty).toList();

    if (ids.isEmpty) return;

    await supabase.from('notifications').delete().inFilter('id', ids);

    FarmDataCache.notifications = null;
  }

  Future<void> markSingleNotificationRead(
    FarmNotification notice,
  ) async {
    if (notice.isRead || notice.id.trim().isEmpty) {
      return;
    }

    try {
      await supabase.from('notifications').update({
        'is_read': true,
      }).eq('id', notice.id);

      FarmDataCache.notifications = null;

      if (mounted) {
        setState(() {
          refreshKey++;
        });
      }
    } catch (error) {
      farmDebugLog(
        'Could not mark notification as read: $error',
      );
    }
  }

  Future<void> deleteSelectedNotifications() async {
    if (selectedNotificationIds.isEmpty) return;

    final count = selectedNotificationIds.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            count == 1 ? 'Delete update?' : 'Delete $count updates?',
          ),
          content: const Text(
            'The selected updates will be removed from your inbox.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final ids = Set<String>.from(selectedNotificationIds);

    try {
      await deleteNotificationsByIds(ids);

      if (!mounted) return;

      setState(() {
        selectedNotificationIds.clear();
        refreshKey++;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 1 ? 'Update deleted' : '$count updates deleted',
          ),
        ),
      );
    } catch (error) {
      debugPrint(
        'DELETE NOTIFICATION ERROR: $error',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delete failed: $error',
          ),
        ),
      );
    }
  }

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

  Future<void> _openNotification(FarmNotification notice) async {
    await markSingleNotificationRead(notice);
    if (!mounted) return;

    final opened = await PushNotificationService.openFarmNotification(
      notice,
      context: context,
    );

    if (!mounted || opened) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This update does not have a direct page yet.',
        ),
      ),
    );
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
      case 'watching':
        return notice.type == 'watch' ||
            notice.type == 'price_drop' ||
            notice.type == 'farmer_demand';
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        backgroundColor: FarmColors.background,
        leading: isSelecting
            ? IconButton(
                tooltip: 'Cancel selection',
                onPressed: clearNotificationSelection,
                icon: const Icon(
                  Icons.close_rounded,
                ),
              )
            : const BackButton(),
        title: Text(
          isSelecting
              ? '${selectedNotificationIds.length} selected'
              : 'Updates',
        ),
        actions: [
          if (isSelecting)
            IconButton(
              tooltip: 'Delete selected',
              onPressed: deleteSelectedNotifications,
              icon: const Icon(
                Icons.delete_outline_rounded,
              ),
            )
          else
            IconButton(
              tooltip: 'Refresh',
              onPressed: refreshNotifications,
              icon: const Icon(
                Icons.restart_alt_rounded,
              ),
            ),
        ],
      ),
      body: FarmPage(
        child: FutureBuilder<List<FarmNotification>>(
          key: ValueKey(refreshKey),
          future: fetchFarmNotifications(
            forceRefresh: true,
          ),
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
            final watchCount = notifications
                .where((notice) =>
                    notice.type == 'watch' ||
                    notice.type == 'price_drop' ||
                    notice.type == 'farmer_demand')
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
                    watchCount: watchCount,
                    onSelected: (value) =>
                        setState(() => selectedFilter = value),
                  ),
                  const SizedBox(height: 16),
                  if (notifications.isEmpty)
                    const FarmEmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'No updates yet',
                      message:
                          'Orders, private support replies, watched products, and buyer-demand updates will appear here.',
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
                        selected: selectedNotificationIds.contains(notice.id),
                        onLongPress: () {
                          toggleNotificationSelection(notice);
                        },
                        onTap: isSelecting
                            ? () {
                                toggleNotificationSelection(notice);
                              }
                            : () => _openNotification(notice),
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
                      : 'Orders, private support, watched products, buyer demand, and stock alerts in one place.',
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
  final int watchCount;
  final ValueChanged<String> onSelected;

  const NotificationFilterBar({
    super.key,
    required this.selected,
    required this.unreadCount,
    required this.orderCount,
    required this.supportCount,
    required this.stockCount,
    required this.watchCount,
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
            value: 'watching',
            label: 'Watching',
            count: watchCount,
            icon: Icons.visibility_outlined,
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
  final VoidCallback? onLongPress;
  final bool selected;

  const FarmNotificationTile({
    super.key,
    required this.notice,
    this.onTap,
    this.onLongPress,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = farmNotificationAccent(notice);
    final unread = !notice.isRead;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      onLongPress: onLongPress,
      child: FarmCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        color: selected
            ? FarmColors.primarySoft
            : unread
                ? const Color(0xFFEAF5E7)
                : Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: selected ? FarmColors.green : accent.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? FarmColors.green : accent.withOpacity(0.22),
                ),
              ),
              child: Icon(
                selected ? Icons.check_rounded : notice.icon,
                color: selected ? Colors.white : accent,
                size: selected ? 24 : 22,
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
                          style: TextStyle(
                            color:
                                unread ? FarmColors.deepGreen : FarmColors.ink,
                            fontSize: 15.8,
                            height: 1.12,
                            fontWeight:
                                unread ? FontWeight.w900 : FontWeight.w700,
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
                      if (notice.hasOrderLink || notice.hasAction)
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
  final String initialSubject;

  const SupportScreen({
    super.key,
    this.initialSubject = '',
  });

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  int refreshKey = 0;
  bool autoOpenedComposer = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSubject.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || autoOpenedComposer) return;
        autoOpenedComposer = true;
        unawaited(openNewConversation());
      });
    }
  }

  Future<void> refreshTickets() async {
    if (mounted) setState(() => refreshKey++);
  }

  Future<void> openNewConversation() async {
    final subjectController = TextEditingController(
      text: widget.initialSubject.trim(),
    );
    final messageController = TextEditingController();
    var sending = false;

    final createdTicketId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: FarmColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> send() async {
              final subject = subjectController.text.trim();
              final message = messageController.text.trim();
              if (subject.isEmpty || message.isEmpty) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text('Choose a topic and tell us how we can help.'),
                  ),
                );
                return;
              }

              setSheetState(() => sending = true);
              try {
                final ticketId = await createSupportTicket(
                  subject: subject,
                  message: message,
                );
                if (sheetContext.mounted) {
                  Navigator.pop(sheetContext, ticketId);
                }
              } catch (error) {
                if (sheetContext.mounted) {
                  setSheetState(() => sending = false);
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Could not start private chat: ${friendlyAppError(error)}',
                      ),
                    ),
                  );
                }
              }
            }

            Widget topic(String label, IconData icon) {
              return ActionChip(
                onPressed: sending
                    ? null
                    : () => setSheetState(() => subjectController.text = label),
                avatar: Icon(icon, size: 17, color: FarmColors.green),
                label: Text(label),
                labelStyle: const TextStyle(
                  color: FarmColors.deepGreen,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
                backgroundColor: FarmColors.primarySoft,
                side: BorderSide(color: FarmColors.green.withOpacity(0.14)),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 10,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 18,
              ),
              child: SingleChildScrollView(
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
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Icon(Icons.lock_rounded, color: FarmColors.green),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Start a private chat',
                            style: TextStyle(
                              color: FarmColors.ink,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Only you and authorised HPJ staff can read this conversation.',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        topic('Order question', Icons.receipt_long_outlined),
                        topic('Delivery help', Icons.local_shipping_outlined),
                        topic('Payment help', Icons.payments_outlined),
                        topic('Farmer support', Icons.agriculture_outlined),
                        topic('Wholesale support', Icons.storefront_outlined),
                        topic('Account help', Icons.person_outline_rounded),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: subjectController,
                      textInputAction: TextInputAction.next,
                      enabled: !sending,
                      decoration: const InputDecoration(
                        labelText: 'Topic',
                        prefixIcon: Icon(Icons.subject_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: messageController,
                      minLines: 4,
                      maxLines: 7,
                      maxLength: 4000,
                      enabled: !sending,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'How can we help?',
                        hintText: 'Write your message here...',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 8),
                    PrimaryFarmButton(
                      label: sending ? 'Starting private chat...' : 'Start Chat',
                      icon: Icons.send_rounded,
                      onPressed: sending ? null : send,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    subjectController.dispose();
    messageController.dispose();

    if (!mounted || createdTicketId == null || createdTicketId.trim().isEmpty) {
      return;
    }

    setState(() => refreshKey++);
    final ticket = await fetchSupportTicket(createdTicketId);
    if (!mounted) return;

    if (ticket != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SupportConversationScreen(ticket: ticket),
        ),
      );
      if (mounted) setState(() => refreshKey++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Inbox'),
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
              const SizedBox(height: 14),
              PrimaryFarmButton(
                label: 'New Message',
                icon: Icons.chat_rounded,
                onPressed: openNewConversation,
              ),
              const SizedBox(height: 10),
              const _SupportPrivacyNote(),
              const SizedBox(height: 22),
              const SectionHeader(
                title: 'Messages',
                subtitle: 'Private conversations with HPJ',
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<SupportTicket>>(
                key: ValueKey(refreshKey),
                future: fetchMySupportTickets(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const SkeletonList(count: 3, height: 104);
                  }

                  final tickets = snapshot.data ?? const <SupportTicket>[];
                  if (tickets.isEmpty) {
                    return FarmEmptyState(
                      icon: Icons.forum_outlined,
                      title: 'No conversations yet',
                      message:
                          'Start a private chat whenever you need help with an order, payment, supply, collection, or your account.',
                      actionLabel: 'Start Chat',
                      onAction: openNewConversation,
                      compact: true,
                    );
                  }

                  return Column(
                    children: tickets
                        .map(
                          (ticket) => SupportTicketCard(
                            ticket: ticket,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SupportConversationScreen(
                                    ticket: ticket,
                                  ),
                                ),
                              );
                              if (mounted) setState(() => refreshKey++);
                            },
                          ),
                        )
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            FarmColors.primarySoft.withOpacity(0.78),
          ],
        ),
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
            height: 62,
            width: 62,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: FarmColors.green.withOpacity(0.16)),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: FarmColors.green,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'HPJ Inbox',
                        style: TextStyle(
                          color: FarmColors.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    SizedBox(width: 7),
                    Icon(Icons.verified_rounded,
                        size: 18, color: FarmColors.green),
                  ],
                ),
                SizedBox(height: 5),
                Text(
                  'Private messages between you and the HPJ team.',
                  style: TextStyle(
                    color: FarmColors.mutedText,
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

class _SupportPrivacyNote extends StatelessWidget {
  const _SupportPrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FarmColors.line),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_rounded, size: 18, color: FarmColors.green),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Private by design • Other HPJ users and unrelated staff cannot read your chat.',
              style: TextStyle(
                color: FarmColors.mutedText,
                fontSize: 12.5,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SupportTicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback? onTap;

  const SupportTicketCard({
    super.key,
    required this.ticket,
    this.onTap,
  });

  Color get statusColor {
    final status = ticket.status.trim().toLowerCase();
    if (status == 'closed' || status == 'resolved') return FarmColors.success;
    if (status == 'in_progress') return FarmColors.warning;
    return FarmColors.green;
  }

  @override
  Widget build(BuildContext context) {
    final time = ticket.lastMessageAt ?? ticket.createdAt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: ticket.hasUnreadForCustomer
                    ? FarmColors.green.withOpacity(0.42)
                    : FarmColors.line,
                width: ticket.hasUnreadForCustomer ? 1.4 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: const BoxDecoration(
                        color: FarmColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: FarmColors.green,
                      ),
                    ),
                    if (ticket.hasUnreadForCustomer)
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          height: 11,
                          width: 11,
                          decoration: BoxDecoration(
                            color: FarmColors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ticket.subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontSize: 15.5,
                                fontWeight: ticket.hasUnreadForCustomer
                                    ? FontWeight.w900
                                    : FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              ticket.formattedStatus,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        ticket.preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ticket.hasUnreadForCustomer
                              ? FarmColors.ink
                              : FarmColors.mutedText,
                          height: 1.28,
                          fontWeight: ticket.hasUnreadForCustomer
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.lock_rounded,
                            size: 13,
                            color: FarmColors.green,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Private',
                            style: TextStyle(
                              color: FarmColors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (time != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              formatCustomerDateTime(time),
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: FarmColors.mutedText,
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

class SupportConversationScreen extends StatefulWidget {
  final SupportTicket ticket;

  const SupportConversationScreen({
    super.key,
    required this.ticket,
  });

  @override
  State<SupportConversationScreen> createState() =>
      _SupportConversationScreenState();
}

class _SupportConversationScreenState extends State<SupportConversationScreen> {
  final messageController = TextEditingController();
  final scrollController = ScrollController();
  bool sending = false;
  String? lastReadMessageId;

  @override
  void initState() {
    super.initState();
    unawaited(markSupportConversationRead(widget.ticket.id));
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    final message = messageController.text.trim();
    if (message.isEmpty || sending) return;

    setState(() => sending = true);
    try {
      await sendSupportMessage(
        ticketId: widget.ticket.id,
        message: message,
      );
      messageController.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
      await createAdminNotification(
        title: 'New HPJ Inbox reply',
        message: 'Conversation #${widget.ticket.shortId} has a new user reply.',
        type: 'support',
        actionType: 'admin_support_chat',
        actionId: widget.ticket.id,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not send message: ${friendlyAppError(error)}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  void markReadIfNeeded(List<SupportMessage> messages) {
    if (messages.isEmpty) return;
    SupportMessage? latestStaff;
    for (final message in messages.reversed) {
      if (message.isFromStaff) {
        latestStaff = message;
        break;
      }
    }
    if (latestStaff == null || latestStaff.id == lastReadMessageId) return;
    lastReadMessageId = latestStaff.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(markSupportConversationRead(widget.ticket.id));
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SupportTicket?>(
      stream: watchSupportTicket(widget.ticket.id),
      initialData: widget.ticket,
      builder: (context, ticketSnapshot) {
        final ticket = ticketSnapshot.data ?? widget.ticket;
        return Scaffold(
          backgroundColor: FarmColors.background,
          appBar: AppBar(
            backgroundColor: FarmColors.background,
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'HPJ Inbox',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.verified_rounded,
                        size: 17, color: FarmColors.green),
                  ],
                ),
                Text(
                  ticket.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(14, 6, 14, 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: FarmColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: FarmColors.green.withOpacity(0.14),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_rounded,
                          size: 17, color: FarmColors.green),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Private • Only you and authorised HPJ staff can read this chat.',
                          style: TextStyle(
                            color: FarmColors.deepGreen,
                            fontSize: 11.5,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          ticket.formattedStatus,
                          style: const TextStyle(
                            color: FarmColors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (ticket.isResolved)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: FarmColors.line),
                    ),
                    child: const Text(
                      'This conversation is resolved. Send a new message if you still need help and HPJ will reopen it.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 11.5,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Expanded(
                  child: StreamBuilder<List<SupportMessage>>(
                    stream: watchSupportMessages(ticket.id),
                    builder: (context, snapshot) {
                      final messages =
                          snapshot.data ?? const <SupportMessage>[];
                      markReadIfNeeded(messages);

                      if (snapshot.connectionState == ConnectionState.waiting &&
                          messages.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (messages.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Your private conversation will appear here.',
                              style: TextStyle(
                                color: FarmColors.mutedText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      }

                      final reversed = messages.reversed.toList();
                      return ListView.builder(
                        controller: scrollController,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                        itemCount: reversed.length,
                        itemBuilder: (context, index) {
                          final message = reversed[index];
                          return _CustomerSupportBubble(
                            message: message,
                            ticket: ticket,
                          );
                        },
                      );
                    },
                  ),
                ),
                _SupportMessageComposer(
                  controller: messageController,
                  sending: sending,
                  onSend: sendMessage,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CustomerSupportBubble extends StatelessWidget {
  final SupportMessage message;
  final SupportTicket ticket;

  const _CustomerSupportBubble({
    required this.message,
    required this.ticket,
  });

  @override
  Widget build(BuildContext context) {
    final fromStaff = message.isFromStaff;
    final createdAt = message.createdAt;
    final seenByStaff = !fromStaff &&
        createdAt != null &&
        ticket.staffLastReadAt != null &&
        !createdAt.isAfter(ticket.staffLastReadAt!);

    return Align(
      alignment: fromStaff ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (fromStaff) ...[
              Container(
                height: 30,
                width: 30,
                decoration: const BoxDecoration(
                  color: FarmColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  size: 18,
                  color: FarmColors.green,
                ),
              ),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
                decoration: BoxDecoration(
                  color: fromStaff ? Colors.white : FarmColors.green,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(fromStaff ? 5 : 20),
                    bottomRight: Radius.circular(fromStaff ? 20 : 5),
                  ),
                  border:
                      fromStaff ? Border.all(color: FarmColors.line) : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.035),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: fromStaff
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
                  children: [
                    if (fromStaff)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          'HPJ Inbox',
                          style: TextStyle(
                            color: FarmColors.green,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    Text(
                      message.message,
                      style: TextStyle(
                        color: fromStaff ? FarmColors.ink : Colors.white,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      createdAt == null
                          ? (fromStaff ? 'HPJ' : 'Sent securely')
                          : fromStaff
                              ? formatCustomerDateTime(createdAt)
                              : '${formatCustomerDateTime(createdAt)} • ${seenByStaff ? 'Seen by HPJ' : 'Sent securely'}',
                      style: TextStyle(
                        color: fromStaff
                            ? FarmColors.mutedText
                            : Colors.white.withOpacity(0.78),
                        fontSize: 9.8,
                        fontWeight: FontWeight.w700,
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
  }
}

class _SupportMessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _SupportMessageComposer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: FarmColors.line.withOpacity(0.85)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !sending,
              minLines: 1,
              maxLines: 5,
              maxLength: 4000,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Message HPJ...',
                counterText: '',
                filled: true,
                fillColor: FarmColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: FarmColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: FarmColors.green,
                    width: 1.4,
                  ),
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: sending ? FarmColors.line : FarmColors.green,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: sending ? null : onSend,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: FarmColors.green,
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ),
          ),
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
        SnackBar(content: Text(friendlyAppError(error))),
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
                        'Today’s Fresh Harvest',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          color: FarmColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Choose your favourites and build your box.',
                        style: TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 12.5,
                          height: 1.25,
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
        SnackBar(content: Text(friendlyAppError(error))),
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
        SnackBar(content: Text(friendlyAppError(error))),
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

String _detailDisplayNutrientName(String value) {
  final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  final key = clean.toLowerCase();

  switch (key) {
    case 'magnesium':
      return 'Magnesium';
    case 'iron':
      return 'Iron';
    case 'fiber':
    case 'fibre':
      return 'Fiber';
    case 'potassium':
      return 'Potassium';
    case 'vitamin c':
    case 'vit c':
      return 'Vitamin C';
    case 'protein':
      return 'Protein';
    case 'calcium':
      return 'Calcium';
    case 'antioxidant':
    case 'antioxidants':
      return 'Antioxidants';
    default:
      return clean
          .split(' ')
          .where((word) => word.isNotEmpty)
          .map(
            (word) =>
                '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
          )
          .join(' ');
  }
}

String _normaliseDetailNutrientBadgeLabel(String value) {
  final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (clean.isEmpty) return '';

  final lower = clean.toLowerCase();

  String level;
  String nutrient;

  if (lower.startsWith('strong ')) {
    level = 'Strong';
    nutrient = clean.substring(7);
  } else if (lower.startsWith('good ')) {
    level = 'Good';
    nutrient = clean.substring(5);
  } else if (lower.startsWith('contains ')) {
    level = 'Contains';
    nutrient = clean.substring(9);
  } else {
    level = 'Contains';
    nutrient = clean;
  }

  final displayNutrient = _detailDisplayNutrientName(nutrient);

  if (displayNutrient.isEmpty) return '';

  return '$level $displayNutrient';
}

class _DetailNutrientBadge {
  final String level;
  final String nutrient;

  const _DetailNutrientBadge({
    required this.level,
    required this.nutrient,
  });

  String get label => '$level $nutrient';

  Color get foregroundColor {
    switch (level) {
      case 'Strong':
        return const Color(0xFF155D32);
      case 'Good':
        return const Color(0xFF2F7D4A);
      default:
        return const Color(0xFF557A5D);
    }
  }

  Color get backgroundColor {
    switch (level) {
      case 'Strong':
        return const Color(0xFFDDEFE3);
      case 'Good':
        return const Color(0xFFEAF5EC);
      default:
        return const Color(0xFFF2F7F2);
    }
  }

  Color get borderColor {
    switch (level) {
      case 'Strong':
        return const Color(0xFFA8D5B6);
      case 'Good':
        return const Color(0xFFC4E3CC);
      default:
        return const Color(0xFFD8E7DA);
    }
  }

  static _DetailNutrientBadge? tryParse(String value) {
    final clean = _normaliseDetailNutrientBadgeLabel(value);

    if (clean.isEmpty) return null;

    final firstSpace = clean.indexOf(' ');

    if (firstSpace <= 0 || firstSpace >= clean.length - 1) {
      return null;
    }

    return _DetailNutrientBadge(
      level: clean.substring(0, firstSpace),
      nutrient: clean.substring(firstSpace + 1),
    );
  }
}

class _ProductNutritionHighlightsCard extends StatefulWidget {
  final List<String> badges;
  final ValueChanged<String>? onNutrientTap;

  const _ProductNutritionHighlightsCard({
    required this.badges,
    this.onNutrientTap,
  });

  @override
  State<_ProductNutritionHighlightsCard> createState() =>
      _ProductNutritionHighlightsCardState();
}

class _ProductNutritionHighlightsCardState
    extends State<_ProductNutritionHighlightsCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};

    final nutrients = widget.badges
        .map(_DetailNutrientBadge.tryParse)
        .whereType<_DetailNutrientBadge>()
        .where((item) {
      final key = item.nutrient.trim().toLowerCase();
      return key.isNotEmpty && seen.add(key);
    }).toList();

    if (nutrients.isEmpty) {
      return const SizedBox.shrink();
    }

    final canExpand = nutrients.length > 3;

    final visibleNutrients = expanded ? nutrients : nutrients.take(3).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: FarmColors.green.withOpacity(0.12),
        ),
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
                  color: FarmColors.primarySoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: FarmColors.green.withOpacity(0.12),
                  ),
                ),
                child: const Icon(
                  Icons.eco_outlined,
                  color: FarmColors.green,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nutrition highlights',
                      style: TextStyle(
                        color: FarmColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tap a nutrient to view similar products.',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: visibleNutrients.map((item) {
              final canTap = widget.onNutrientTap != null;

              return Tooltip(
                message: canTap
                    ? 'View similar products with ${item.nutrient}'
                    : item.label,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: canTap
                        ? () => widget.onNutrientTap!(item.nutrient)
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: item.backgroundColor,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: item.borderColor,
                          width: item.level == 'Strong' ? 1.2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.eco_outlined,
                            size: 14,
                            color: item.foregroundColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.label,
                            style: TextStyle(
                              color: item.foregroundColor,
                              fontSize: 12,
                              fontWeight: item.level == 'Strong'
                                  ? FontWeight.w900
                                  : FontWeight.w800,
                            ),
                          ),
                          if (canTap) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: item.foregroundColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (canExpand) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  expanded = !expanded;
                });
              },
              icon: Icon(
                expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 18,
              ),
              label: Text(
                expanded ? 'Show less' : '+${nutrients.length - 3} more',
              ),
              style: TextButton.styleFrom(
                foregroundColor: FarmColors.green,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: FarmColors.line.withOpacity(0.75),
          ),
          const SizedBox(height: 10),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: FarmColors.mutedText,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Nutrition highlights are general product guidance and may vary by variety and serving size.',
                  style: TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 11.2,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  final int quantity;

  final List<String> nutrientBadges;
  final ValueChanged<String>? onNutrientTap;

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
    this.nutrientBadges = const <String>[],
    this.onNutrientTap,
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

  List<String> get displayNutrientBadges {
    final source = nutrientBadges.isNotEmpty
        ? nutrientBadges
        : <String>[
            ...product.nutrientStrong.map(
              (nutrient) => 'Strong $nutrient',
            ),
            ...product.nutrientGood.map(
              (nutrient) => 'Good $nutrient',
            ),
            ...product.nutrientContains.map(
              (nutrient) => 'Contains $nutrient',
            ),
          ];

    final seen = <String>{};
    final output = <String>[];

    for (final badgeLabel in source) {
      final cleanLabel = _normaliseDetailNutrientBadgeLabel(badgeLabel);

      if (cleanLabel.isEmpty) continue;

      final parsed = _DetailNutrientBadge.tryParse(cleanLabel);
      if (parsed == null) continue;

      final nutrientKey = parsed.nutrient.trim().toLowerCase();

      if (nutrientKey.isEmpty) continue;

      if (seen.add(nutrientKey)) {
        output.add(parsed.label);
      }
    }

    return output;
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

                      // Show the same nutrient information seen in Shop.

                      if (product.isOutOfStock)
                        badge(
                          label: 'Out of stock',
                          icon: Icons.block_outlined,
                          color: FarmColors.danger,
                        ),
                    ],
                  ),
                  if (displayNutrientBadges.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _ProductNutritionHighlightsCard(
                      badges: displayNutrientBadges,
                      onNutrientTap: onNutrientTap,
                    ),
                  ],
                  const SizedBox(height: 16),
                  DiscountPriceText(product: product),
                ],
              ),
            ),
            if (isLoggedIn && product.canAddToCart) ...[
              const SizedBox(height: 14),
              FarmCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: FarmColors.primarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.visibility_outlined,
                        color: FarmColors.primary,
                      ),
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Watch this product',
                            style: TextStyle(
                              color: FarmColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Get useful updates for availability and genuine price drops.',
                            style: TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 11.2,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    HpjWatchButton(
                      workspace: 'customer',
                      watchType: 'product',
                      entityKey: product.id,
                      entityName: product.name,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ],
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
  String deliveryZone = 'St. Elizabeth';
  List<DeliveryZone> deliveryZones = _defaultDeliveryZones;
  bool deliveryZonesLoading = false;
  DateTime? scheduledDate;
  TimeOfDay? scheduledTime;

  DeliveryZone? get selectedDeliveryZone {
    for (final zone in deliveryZones) {
      if (zone.displayName == deliveryZone) return zone;
    }
    if (deliveryZones.isNotEmpty) return deliveryZones.first;
    return null;
  }

  double get deliveryFee {
    if (fulfillmentType != 'delivery') return 0.0;
    final fee = selectedDeliveryZone?.deliveryFee ?? 0.0;
    return fee < 0 ? 0.0 : fee;
  }

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
    unawaited(_restoreSmartCheckoutDefaults());
    loadSavedCustomerProfile();
    loadDeliveryZones();
  }

  Future<void> _restoreSmartCheckoutDefaults() async {
    String? fulfillment =
        await HpjSmartLocalStore.readString('checkout_fulfillment');
    String? zone = await HpjSmartLocalStore.readString('checkout_zone');
    String? payment = await HpjSmartLocalStore.readString('checkout_payment');

    if ((fulfillment == null || fulfillment.isEmpty) && isLoggedIn) {
      try {
        final userId = supabase.auth.currentUser?.id;
        if (userId != null) {
          final row = await supabase
              .from('orders')
              .select('fulfillment_type,delivery_zone,payment_method')
              .eq('user_id', userId)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          if (row != null) {
            fulfillment = (row['fulfillment_type'] ?? '').toString().trim();
            zone = (row['delivery_zone'] ?? '').toString().trim();
            payment = (row['payment_method'] ?? '').toString().trim();
          }
        }
      } catch (error) {
        farmDebugLog('Recent checkout defaults unavailable: $error');
      }
    }

    if (!mounted) return;
    setState(() {
      if (fulfillment == 'delivery' || fulfillment == 'pickup') {
        _syncPaymentMethodForFulfillment(fulfillment!);
      }
      if (zone != null && zone!.isNotEmpty) {
        deliveryZone = zone!;
      }
      if (payment != null && payment!.isNotEmpty) {
        paymentMethod = payment!;
        if (!_isAllowedPaymentForCurrentFulfillment(paymentMethod)) {
          paymentMethod = fulfillmentType == 'delivery'
              ? 'bank_transfer'
              : 'cash_on_pickup';
        }
      }
    });
  }

  Future<void> _saveSmartCheckoutDefaults() async {
    await Future.wait<void>([
      HpjSmartLocalStore.writeString('checkout_fulfillment', fulfillmentType),
      HpjSmartLocalStore.writeString('checkout_zone', deliveryZone),
      HpjSmartLocalStore.writeString('checkout_payment', effectivePaymentMethod),
    ]);
  }

  Future<void> loadDeliveryZones() async {
    if (mounted) setState(() => deliveryZonesLoading = true);

    final zones = await fetchActiveDeliveryZones();
    if (!mounted) return;

    final clean = _cleanDeliveryZones(zones);
    setState(() {
      deliveryZones = clean.isEmpty ? _defaultDeliveryZones : clean;
      final currentStillExists = deliveryZones.any(
        (zone) => zone.displayName == deliveryZone,
      );
      if (!currentStillExists && deliveryZones.isNotEmpty) {
        deliveryZone = deliveryZones.first.displayName;
      }
      deliveryZonesLoading = false;
    });
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

    if (fulfillmentType == 'delivery' && selectedDeliveryZone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose an active delivery parish.'),
        ),
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

      await _saveSmartCheckoutDefaults();

// Clear the visible My Box immediately.
      widget.onOrderPlaced();

// Clear the saved Supabase cart.
      await clearSavedCartForCurrentUser();

      if (!mounted) return;

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
                      unawaited(_saveSmartCheckoutDefaults());
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
                      value: deliveryZones.any(
                        (zone) => zone.displayName == deliveryZone,
                      )
                          ? deliveryZone
                          : null,
                      items: deliveryZones
                          .where((zone) => zone.isActive)
                          .map(
                            (zone) => DropdownMenuItem(
                              value: zone.displayName,
                              child: Text(
                                '${zone.displayName} • ${formatJmd(zone.deliveryFee)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: deliveryZonesLoading
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() => deliveryZone = value);
                              unawaited(_saveSmartCheckoutDefaults());
                            },
                      decoration: InputDecoration(
                        labelText: deliveryZonesLoading
                            ? 'Loading delivery parishes...'
                            : 'Delivery parish',
                        prefixIcon: const Icon(Icons.local_shipping_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FarmColors.lightGreen,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: FarmColors.line),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.verified_outlined,
                            color: FarmColors.green,
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Delivery fee for $deliveryZone: ${formatJmd(deliveryFee)}. Admin can update active parishes and fees anytime.',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: FarmColors.green,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
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
                      unawaited(_saveSmartCheckoutDefaults());
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
              subtitle: 'Freshness, privacy, orders, and support.',
            ),
            SizedBox(height: 16),
            TrustCenterHeroCard(),
            SizedBox(height: 16),
            TrustCenterSection(
              title: 'Your order',
              subtitle: 'Simple shopping from box to checkout.',
              items: [
                TrustCenterItem(
                  icon: Icons.shopping_basket_outlined,
                  title: 'Build your box',
                  body:
                      'Browse fresh products, add available items to My Box, and review your order before checkout.',
                ),
                TrustCenterItem(
                  icon: Icons.fact_check_outlined,
                  title: 'Availability is checked',
                  body:
                      'Items are shown clearly so you can see what is available, low in stock, or out of stock before you order.',
                ),
                TrustCenterItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Track your order',
                  body:
                      'After checkout, you can follow your order status, payment status, pickup, or delivery details.',
                ),
              ],
            ),
            SizedBox(height: 16),
            TrustCenterSection(
              title: 'Freshness promise',
              subtitle: 'What you can expect from every order.',
              items: [
                TrustCenterItem(
                  icon: Icons.eco_outlined,
                  title: 'Fresh local shopping',
                  body:
                      'Shop fresh local produce, farm picks, weekly items, seasonal products, and pantry-friendly staples.',
                ),
                TrustCenterItem(
                  icon: Icons.local_shipping_outlined,
                  title: 'Clear pickup or delivery',
                  body:
                      'Checkout shows your order details and fulfillment option so you know how your items will reach you.',
                ),
                TrustCenterItem(
                  icon: Icons.support_agent_outlined,
                  title: 'Help when needed',
                  body:
                      'Contact support for delivery, pickup, payment, product, or order questions from your account.',
                ),
              ],
            ),
            SizedBox(height: 16),
            TrustCenterSection(
              title: 'Privacy & updates',
              subtitle: 'Your account information is handled with care.',
              items: [
                TrustCenterItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Your details stay private',
                  body:
                      'Your private Customer Care chats are restricted to your account and authorised HPJ Customer Care staff. Other users and unrelated staff cannot read them.',
                ),
                TrustCenterItem(
                  icon: Icons.notifications_active_outlined,
                  title: 'Useful updates only',
                  body:
                      'Order and stock updates are designed to help you stay informed without unnecessary noise.',
                ),
                TrustCenterItem(
                  icon: Icons.verified_user_outlined,
                  title: 'A safer shopping experience',
                  body:
                      'Your account keeps your orders, saved details, rewards, and support options in one secure place.',
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
    return FarmCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: FarmColors.lightGreen,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: FarmColors.green.withOpacity(0.12),
              ),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: FarmColors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shop with confidence',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Fresh products, clear checkout, order updates, and support in one place.',
                  style: TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
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


class AboutHpjScreen extends StatelessWidget {
  const AboutHpjScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('About HPJ'),
        backgroundColor: FarmColors.background,
      ),
      body: FarmPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
          children: [
            FarmCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: FarmColors.primarySoft,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: FarmColors.line),
                    ),
                    child: Image.asset(
                      'lib/assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.eco_rounded,
                        color: FarmColors.primary,
                        size: 44,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'The Harvest Place Ja',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.35,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Fresh • Local • Jamaican',
                    style: TextStyle(
                      color: FarmColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'HPJ connects customers, businesses, farmers, and our operations team through one simple fresh-produce platform.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 13.2,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const SectionHeader(
              title: 'What HPJ brings together',
              subtitle: 'One connected journey from farm supply to customer order.',
            ),
            const SizedBox(height: 10),
            const _AboutHpjRoleCard(
              icon: Icons.shopping_basket_outlined,
              title: 'Customers',
              body: 'Shop fresh Jamaican produce and follow orders from checkout to fulfilment.',
            ),
            const SizedBox(height: 10),
            const _AboutHpjRoleCard(
              icon: Icons.storefront_outlined,
              title: 'Businesses',
              body: 'Buy wholesale, plan future needs, and keep orders and invoices in one place.',
            ),
            const SizedBox(height: 10),
            const _AboutHpjRoleCard(
              icon: Icons.agriculture_outlined,
              title: 'Farmers',
              body: 'See buyer demand, update supply, follow collections, and track earnings.',
            ),
            const SizedBox(height: 14),
            FarmCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Our purpose',
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Make local food easier to discover, plan, supply, move, and buy while giving Jamaican farmers and businesses clearer demand information.',
                    style: TextStyle(
                      color: FarmColors.mutedText,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: FarmColors.primary,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppConfig.businessLocation,
                          style: const TextStyle(
                            color: FarmColors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PrimaryFarmButton(
              label: 'Contact HPJ',
              icon: Icons.support_agent_outlined,
              onPressed: () => _open(context, const ContactHpjScreen()),
            ),
            const SizedBox(height: 18),
            Text(
              'Version ${AppConfig.appVersion} (${AppConfig.appBuildNumber})',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutHpjRoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _AboutHpjRoleCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: FarmColors.primarySoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: FarmColors.primary, size: 23),
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
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 12.2,
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

class ContactHpjScreen extends StatelessWidget {
  const ContactHpjScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  Future<void> _launch(
    BuildContext context,
    String url,
    String failureMessage,
  ) async {
    final opened = await openExternalShareUrl(url);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failureMessage)),
      );
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final message = Uri.encodeComponent(
      'Hello The Harvest Place Ja, I need help with my HPJ account.',
    );
    await _launch(
      context,
      'https://wa.me/${AppConfig.supportWhatsAppNumber}?text=$message',
      'WhatsApp could not be opened on this device.',
    );
  }

  Future<void> _callHpj(BuildContext context) async {
    await _launch(
      context,
      'tel:${AppConfig.supportPhoneDial}',
      'Calling is not available on this device.',
    );
  }

  Future<void> _emailHpj(BuildContext context) async {
    final email = AppConfig.supportEmail.trim();
    if (email.isEmpty) return;
    final subject = Uri.encodeComponent('HPJ support request');
    await _launch(
      context,
      'mailto:$email?subject=$subject',
      'Email could not be opened on this device.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasEmail = AppConfig.supportEmail.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Contact HPJ'),
        backgroundColor: FarmColors.background,
      ),
      body: FarmPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: FarmColors.primary,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: FarmColors.primary.withOpacity(0.16),
                    blurRadius: 22,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: Color(0x33FFFFFF),
                    child: Icon(
                      Icons.support_agent_rounded,
                      color: Colors.white,
                      size: 29,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need help?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Chat with HPJ Customer Care or choose another contact option.',
                          style: TextStyle(
                            color: Color(0xFFE4F0E8),
                            fontSize: 12.4,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PrimaryFarmButton(
              label: 'Chat with Customer Care',
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: () => _open(
                context,
                const SupportScreen(initialSubject: 'Customer care'),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your in-app messages and HPJ replies stay saved to your account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FarmColors.mutedText,
                fontSize: 11.2,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            const SectionHeader(
              title: 'Other ways to reach us',
              subtitle: 'Choose the contact method that works best for you.',
            ),
            const SizedBox(height: 10),
            _HpjContactMethodCard(
              icon: Icons.chat_rounded,
              title: 'WhatsApp HPJ',
              subtitle: AppConfig.supportPhoneDisplay,
              onTap: () => _openWhatsApp(context),
            ),
            const SizedBox(height: 10),
            _HpjContactMethodCard(
              icon: Icons.call_outlined,
              title: 'Call HPJ',
              subtitle: AppConfig.supportPhoneDisplay,
              onTap: () => _callHpj(context),
            ),
            if (hasEmail) ...[
              const SizedBox(height: 10),
              _HpjContactMethodCard(
                icon: Icons.email_outlined,
                title: 'Email HPJ',
                subtitle: AppConfig.supportEmail,
                onTap: () => _emailHpj(context),
              ),
            ],
            const SizedBox(height: 14),
            FarmCard(
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: FarmColors.primary,
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'The Harvest Place Ja',
                          style: TextStyle(
                            color: FarmColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          AppConfig.businessLocation,
                          style: TextStyle(
                            color: FarmColors.mutedText,
                            height: 1.35,
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
    );
  }
}

class _HpjContactMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HpjContactMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: FarmColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FarmColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: FarmColors.primarySoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: FarmColors.primary, size: 22),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: FarmColors.mutedText,
                size: 13,
              ),
            ],
          ),
        ),
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
