part of harvest_place_app;

Future<List<HomeHeroSlide>> fetchAdminHomeHeroSlides() async {
  await requireAdminAccess();

  try {
    final response = await supabase
        .from('home_hero_slides')
        .select(
            'id, position, image_url, title, subtitle, is_active, updated_at')
        .order('position', ascending: true);

    final byPosition = <int, HomeHeroSlide>{};
    for (final row in response as List) {
      final slide = HomeHeroSlide.fromSupabase(Map<String, dynamic>.from(row));
      if (slide.position >= 1 && slide.position <= 3) {
        byPosition[slide.position] = slide;
      }
    }

    final defaults = defaultHomeHeroSlides();
    return List<HomeHeroSlide>.generate(3, (index) {
      final position = index + 1;
      return byPosition[position] ?? defaults[index];
    });
  } catch (error) {
    farmDebugLog('Admin hero slides unavailable: $error');
    return defaultHomeHeroSlides();
  }
}

Future<List<NotificationTarget>> fetchAdminNotificationTargets() async {
  final seen = <String>{};
  final targets = <NotificationTarget>[];

  void addTarget({String? userId, String? email}) {
    final cleanUserId = userId?.trim();
    final cleanEmail = email?.trim().toLowerCase();
    if ((cleanUserId == null || cleanUserId.isEmpty) &&
        (cleanEmail == null || cleanEmail.isEmpty)) {
      return;
    }
    final key = '${cleanUserId ?? ''}|${cleanEmail ?? ''}';
    if (!seen.add(key)) return;
    targets.add(NotificationTarget(userId: cleanUserId, userEmail: cleanEmail));
  }

  Future<void> readAdmins(String selectFields) async {
    final response = await supabase.from('admin_users').select(selectFields);
    for (final item in response as List) {
      final row = Map<String, dynamic>.from(item as Map);
      addTarget(
        userId: (row['user_id'] ?? row['id'])?.toString(),
        email: row['email']?.toString(),
      );
    }
  }

  try {
    await readAdmins('user_id, email');
  } catch (firstError) {
    try {
      await readAdmins('id, email');
    } catch (secondError) {
      try {
        await readAdmins('email');
      } catch (thirdError) {
        farmDebugLog(
          'Admin notification target lookup skipped: $firstError / $secondError / $thirdError',
        );
      }
    }
  }

  return targets;
}

Future<void> createAdminNotification({
  required String title,
  required String message,
  String type = 'admin',
  String? orderId,
}) async {
  try {
    final targets = await fetchAdminNotificationTargets();
    if (targets.isEmpty) {
      farmDebugLog(
          'Admin notification skipped because no admin target was found.');
      return;
    }

    for (final target in targets) {
      await createFarmNotification(
        title: title,
        message: message,
        type: type,
        userId: target.userId,
        userEmail: target.userEmail,
        orderId: orderId,
      );
    }
  } catch (error) {
    farmDebugLog('Admin notification skipped: $error');
  }
}

Future<List<AuditLogEntry>> fetchAdminAuditLogs({
  int limit = 50,
  String? action,
  String? tableName,
}) async {
  await requireAdminAccess();

  final response = await supabase.rpc(
    'admin_fetch_audit_logs',
    params: {
      'p_limit': limit,
      'p_action': action,
      'p_table_name': tableName,
    },
  );

  return (response as List)
      .map((item) => AuditLogEntry.fromMap(Map<String, dynamic>.from(item)))
      .toList();
}

Future<List<AdminOrder>> fetchAdminOrders() async {
  final allowed = await isCurrentUserAdminFromDatabase();
  if (!allowed) return [];

  try {
    final response = await supabase
        .from('orders')
        .select(
          'id, order_status, fulfillment_type, subtotal, delivery_fee, discount_amount, total, payment_status, payment_method, bank_reference, delivery_status, delivery_address, delivery_zone, scheduled_date, scheduled_time, notes, box_photo_url, box_photo_uploaded_at, box_photo_note, created_at, customers(full_name, phone, address), order_items(product_name, quantity, line_total)',
        )
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List)
        .map((item) => AdminOrder.fromSupabase(Map<String, dynamic>.from(item)))
        .toList();
  } catch (error) {
    farmDebugLog('Failed to fetch admin orders: $error');
    return [];
  }
}

Future<void> notifyAdminsAboutLowStockAfterCheckout(
  List<SecureCartLineQuote> checkoutLines,
) async {
  for (final line in checkoutLines) {
    final productId = line.product.id.trim();
    if (productId.isEmpty) continue;

    try {
      final product = await fetchProductById(productId);
      if (product == null) continue;
      if (!product.isAvailable || product.stockQuantity > 5) continue;

      final title = product.stockQuantity <= 0
          ? '${product.name} is out of stock'
          : '${product.name} is low in stock';
      final message = product.stockQuantity <= 0
          ? '${product.name} reached 0 in stock after a customer order.'
          : '${product.name} has only ${product.stockQuantity} left after a customer order.';

      await createAdminNotification(
        title: title,
        message: message,
        type: 'stock',
      );
    } catch (error) {
      farmDebugLog(
          'Low stock admin notification skipped for $productId: $error');
    }
  }
}

bool get isAdminUser => false;

const Set<String> _staffAdminRoles = <String>{
  'owner',
  'manager',
  'packer',
  'delivery',
  'inventory',
  'support',
};

String normalizeStaffRole(String? value) {
  final role = (value ?? '').trim().toLowerCase();
  return _staffAdminRoles.contains(role) ? role : '';
}

bool isStaffRoleActive(String? value) {
  return normalizeStaffRole(value).isNotEmpty;
}

String staffRoleDisplayLabel(String? value) {
  switch (normalizeStaffRole(value)) {
    case 'owner':
      return 'Owner';
    case 'manager':
      return 'Manager';
    case 'packer':
      return 'Packer';
    case 'delivery':
      return 'Delivery';
    case 'inventory':
      return 'Inventory';
    case 'support':
      return 'Support';
    default:
      return 'Admin';
  }
}

bool staffRoleHasFullAdminAccess(String? value) {
  final role = normalizeStaffRole(value);
  return role == 'owner' || role == 'manager';
}

bool staffRoleCanManageStaff(String? value) {
  return normalizeStaffRole(value) == 'owner';
}

bool staffRoleCanManageBusinessSettings(String? value) {
  final role = normalizeStaffRole(value);
  return role == 'owner' || role.isEmpty;
}

const List<String> staffAssignableRoles = <String>[
  'manager',
  'packer',
  'delivery',
  'inventory',
  'support',
];

String staffRoleWorkflowSummary(String? value) {
  switch (normalizeStaffRole(value)) {
    case 'owner':
      return 'Full owner access. Owner is managed manually for safety.';
    case 'manager':
      return 'Can manage daily orders, fulfillment, products, and support. Staff, payouts, delivery fees, and business settings stay owner-only.';
    case 'packer':
      return 'Can view orders and fulfillment tools for preparing and packing orders.';
    case 'delivery':
      return 'Can view delivery workflow and update delivery-related order progress.';
    case 'inventory':
      return 'Can manage product stock and review inventory reports.';
    case 'support':
      return 'Can view and respond to customer support messages.';
    default:
      return 'No staff access assigned.';
  }
}

class StaffUserAccount {
  final String id;
  final String? userId;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StaffUserAccount({
    required this.id,
    this.userId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory StaffUserAccount.fromSupabase(Map<String, dynamic> data) {
    return StaffUserAccount(
      id: (data['id'] ?? '').toString(),
      userId: data['user_id']?.toString(),
      email: (data['email'] ?? '').toString().trim().toLowerCase(),
      fullName: (data['full_name'] ?? '').toString().trim(),
      role: normalizeStaffRole(data['role']?.toString()),
      isActive: data['is_active'] == true,
      notes: data['notes']?.toString(),
      createdAt: parseProductDate(data['created_at']),
      updatedAt: parseProductDate(data['updated_at']),
    );
  }

  String get displayName {
    final clean = fullName.trim();
    if (clean.isNotEmpty) return clean;
    return email;
  }

  String get roleLabel => staffRoleDisplayLabel(role);

  String get initials {
    final source = displayName.trim().isNotEmpty ? displayName.trim() : email;
    if (source.isEmpty) return 'S';
    final parts =
        source.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return source.substring(0, 1).toUpperCase();
  }
}

Future<List<StaffUserAccount>> fetchStaffUsersForAdmin() async {
  final staffRole = await fetchCurrentStaffRole();
  if (!staffRoleCanManageStaff(staffRole)) return const <StaffUserAccount>[];

  try {
    final response = await supabase
        .from('staff_users')
        .select(
            'id, user_id, email, full_name, role, is_active, notes, created_at, updated_at')
        .order('is_active', ascending: false)
        .order('role', ascending: true)
        .order('email', ascending: true);

    return (response as List)
        .map((item) => StaffUserAccount.fromSupabase(
            Map<String, dynamic>.from(item as Map)))
        .toList();
  } catch (error) {
    farmDebugLog('Staff users lookup skipped: $error');
    return const <StaffUserAccount>[];
  }
}

Future<void> saveStaffUserForAdmin({
  String? id,
  required String email,
  String? fullName,
  required String role,
  required bool isActive,
  String? notes,
}) async {
  final staffRole = await fetchCurrentStaffRole();
  if (!staffRoleCanManageStaff(staffRole)) {
    throw Exception('Only the owner can manage staff.');
  }

  final cleanEmail = email.trim().toLowerCase();
  if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
    throw Exception('Enter a valid staff email address.');
  }

  final cleanRole = normalizeStaffRole(role);
  if (!staffAssignableRoles.contains(cleanRole)) {
    throw Exception('Choose a valid staff role.');
  }

  final cleanId = id?.trim() ?? '';
  final payload = <String, dynamic>{
    'email': cleanEmail,
    'full_name':
        fullName == null || fullName.trim().isEmpty ? null : fullName.trim(),
    'role': cleanRole,
    'is_active': isActive,
    'notes': notes == null || notes.trim().isEmpty ? null : notes.trim(),
    'updated_at': DateTime.now().toIso8601String(),
  };

  try {
    if (cleanId.isNotEmpty) {
      await supabase.from('staff_users').update(payload).eq('id', cleanId);
      return;
    }

    final existing = await supabase
        .from('staff_users')
        .select('id')
        .ilike('email', cleanEmail)
        .maybeSingle();

    if (existing != null) {
      final row = Map<String, dynamic>.from(existing as Map);
      final existingId = (row['id'] ?? '').toString();
      if (existingId.isNotEmpty) {
        await supabase.from('staff_users').update(payload).eq('id', existingId);
        return;
      }
    }

    await supabase.from('staff_users').insert(payload);
  } catch (error) {
    throw Exception(
        'Could not save staff user. Please check staff permissions.');
  }
}

Future<void> setStaffUserActiveForAdmin({
  required StaffUserAccount staff,
  required bool isActive,
}) async {
  if (normalizeStaffRole(staff.role) == 'owner') {
    throw Exception('Owner access is managed manually for safety.');
  }

  await saveStaffUserForAdmin(
    id: staff.id,
    email: staff.email,
    fullName: staff.fullName,
    role: staff.role,
    isActive: isActive,
    notes: staff.notes,
  );
}

Future<String> fetchCurrentStaffRole() async {
  final user = supabase.auth.currentUser;
  if (user == null) return '';

  try {
    final response = await supabase.rpc('current_staff_role');
    final role = normalizeStaffRole(response?.toString());
    if (role.isNotEmpty) return role;
  } catch (error) {
    farmDebugLog('Staff role RPC lookup skipped: $error');
  }

  final email = (user.email ?? '').trim().toLowerCase();
  if (email.isEmpty) return '';

  try {
    final response = await supabase
        .from('staff_users')
        .select('role, is_active')
        .ilike('email', email)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return '';

    final row = Map<String, dynamic>.from(response as Map);
    return normalizeStaffRole(row['role']?.toString());
  } catch (error) {
    farmDebugLog('Staff role direct lookup skipped: $error');
    return '';
  }
}

Future<bool> isCurrentUserAdminFromDatabase() async {
  final user = supabase.auth.currentUser;
  if (user == null) return false;

  final staffRole = await fetchCurrentStaffRole();
  if (isStaffRoleActive(staffRole)) return true;

  Object? userIdCheckError;
  Object? idCheckError;
  Object? emailCheckError;

  try {
    // Preferred secure schema: admin_users.user_id references auth.users(id).
    final response = await supabase
        .from('admin_users')
        .select('user_id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (response != null) return true;
  } catch (error) {
    userIdCheckError = error;
  }

  try {
    // Compatible secure schema: admin_users.id is the auth.users.id value.
    final response = await supabase
        .from('admin_users')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (response != null) return true;
  } catch (error) {
    idCheckError = error;
  }

  final email = (user.email ?? '').trim().toLowerCase();
  if (email.isNotEmpty) {
    try {
      // Optional compatible schema: admin_users.email stores approved admins.
      // This helps when the auth user was recreated and the auth.users(id)
      // changed, but the admin email row still exists.
      final response = await supabase
          .from('admin_users')
          .select('email')
          .ilike('email', email)
          .maybeSingle();

      if (response != null) return true;
    } catch (error) {
      emailCheckError = error;
    }
  }

  // Keep admin lookup failures out of customer-facing and developer logs.
  // This avoids printing customer email addresses or raw database errors.
  farmDebugLog(
      'Admin check completed without approval. Continuing as customer.');
  return false;
}

Future<void> requireAdminAccess() async {
  final allowed = await isCurrentUserAdminFromDatabase();
  if (!allowed) {
    throw Exception('Admin permission required.');
  }
}

Future<List<SupportTicket>> fetchAdminSupportTickets() async {
  final allowed = await isCurrentUserAdminFromDatabase();
  if (!allowed) return [];

  try {
    final response = await supabase
        .from('support_tickets')
        .select('id, email, subject, message, status, admin_reply, created_at')
        .order('created_at', ascending: false)
        .limit(100);

    return (response as List)
        .map((item) =>
            SupportTicket.fromSupabase(Map<String, dynamic>.from(item)))
        .toList();
  } catch (error) {
    farmDebugLog('Failed to fetch admin support tickets: $error');
    return [];
  }
}

class FarmerAccessGate extends StatelessWidget {
  const FarmerAccessGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FarmerProfile?>(
      future: fetchCurrentFarmerProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final profile = snapshot.data;
        if (profile == null) return const FarmerOnboardingScreen();
        return FarmerMarketplaceShell(profile: profile);
      },
    );
  }
}

class FarmerOnboardingScreen extends StatefulWidget {
  const FarmerOnboardingScreen({super.key});

  @override
  State<FarmerOnboardingScreen> createState() => _FarmerOnboardingScreenState();
}

class _FarmerOnboardingScreenState extends State<FarmerOnboardingScreen> {
  final farmNameController = TextEditingController();
  final farmerNameController = TextEditingController();
  final phoneController = TextEditingController();
  final parishController = TextEditingController();
  final addressController = TextEditingController();
  final bioController = TextEditingController();
  final payoutMethodController = TextEditingController();
  final payoutDetailsController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    farmNameController.dispose();
    farmerNameController.dispose();
    phoneController.dispose();
    parishController.dispose();
    addressController.dispose();
    bioController.dispose();
    payoutMethodController.dispose();
    payoutDetailsController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (farmNameController.text.trim().isEmpty ||
        farmerNameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        parishController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please complete farm name, farmer name, phone, and parish.')),
      );
      return;
    }
    setState(() => loading = true);
    try {
      await saveFarmerProfile(
        farmName: farmNameController.text.trim(),
        farmerName: farmerNameController.text.trim(),
        phone: phoneController.text.trim(),
        parish: parishController.text.trim(),
        address: addressController.text.trim(),
        bio: bioController.text.trim(),
        payoutMethod: payoutMethodController.text.trim(),
        payoutDetails: payoutDetailsController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Farmer profile submitted for admin approval.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const FarmerAccessGate()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save farmer profile: $error')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FarmPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
        children: [
          const Header(
            title: 'Farmer Onboarding',
            subtitle: 'Apply to sell on The Harvest Place Ja',
          ),
          const SizedBox(height: 18),
          FarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your farm marketplace profile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: farmNameController,
                    decoration: const InputDecoration(labelText: 'Farm name')),
                const SizedBox(height: 12),
                TextField(
                    controller: farmerNameController,
                    decoration:
                        const InputDecoration(labelText: 'Farmer name')),
                const SizedBox(height: 12),
                TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone')),
                const SizedBox(height: 12),
                TextField(
                    controller: parishController,
                    decoration: const InputDecoration(labelText: 'Parish')),
                const SizedBox(height: 12),
                TextField(
                    controller: addressController,
                    decoration:
                        const InputDecoration(labelText: 'Farm address')),
                const SizedBox(height: 12),
                TextField(
                    controller: bioController,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(labelText: 'Short farm bio')),
                const SizedBox(height: 12),
                TextField(
                    controller: payoutMethodController,
                    decoration:
                        const InputDecoration(labelText: 'Payout method')),
                const SizedBox(height: 12),
                TextField(
                    controller: payoutDetailsController,
                    maxLines: 2,
                    decoration:
                        const InputDecoration(labelText: 'Payout details')),
                const SizedBox(height: 16),
                PrimaryFarmButton(
                    label: loading ? 'Saving...' : 'Submit for Approval',
                    onPressed: loading ? null : submit),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FarmerMarketplaceShell extends StatefulWidget {
  final FarmerProfile profile;
  const FarmerMarketplaceShell({super.key, required this.profile});

  @override
  State<FarmerMarketplaceShell> createState() => _FarmerMarketplaceShellState();
}

class _FarmerMarketplaceShellState extends State<FarmerMarketplaceShell> {
  int selectedIndex = 0;
  int refreshKey = 0;

  void refresh() => setState(() => refreshKey++);

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final pages = [
      FarmerDashboardScreen(profile: profile, refreshKey: refreshKey),
      FarmerProductsScreen(
          profile: profile, refreshKey: refreshKey, onChanged: refresh),
      FarmerOrdersScreen(profile: profile, refreshKey: refreshKey),
      FarmerEarningsScreen(profile: profile, refreshKey: refreshKey),
      FarmerAccountScreen(profile: profile),
    ];
    final destinations = <FarmBottomOption>[
      const FarmBottomOption(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Home',
      ),
      const FarmBottomOption(
        icon: Icon(Icons.eco_outlined),
        selectedIcon: Icon(Icons.eco),
        label: 'Products',
      ),
      const FarmBottomOption(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Orders',
      ),
      const FarmBottomOption(
        icon: Icon(Icons.payments_outlined),
        selectedIcon: Icon(Icons.payments),
        label: 'Earnings',
      ),
      const FarmBottomOption(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Account',
      ),
    ];

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: FarmBottomOptionsBar(
        selectedIndex: selectedIndex,
        destinations: destinations,
        onSelected: (index) => setState(() => selectedIndex = index),
      ),
    );
  }
}

class FarmerDashboardScreen extends StatelessWidget {
  final FarmerProfile profile;
  final int refreshKey;
  const FarmerDashboardScreen(
      {super.key, required this.profile, required this.refreshKey});

  Color _statusColor(String value) {
    switch (value.trim().toLowerCase()) {
      case 'approved':
        return FarmColors.green;
      case 'rejected':
        return FarmColors.danger;
      default:
        return FarmColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FarmPage(
      child: FutureBuilder<List<Product>>(
        key: ValueKey('farmer-dashboard-$refreshKey'),
        future: fetchFarmerProducts(profile.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.expand(child: SkeletonList(count: 3));
          }

          final products = snapshot.data ?? [];
          final approvedProducts = products.where((p) => p.isApproved).length;
          final liveProducts = products.where((p) => p.canAddToCart).length;
          final lowStockProducts = products.where((p) => p.isLowStock).length;
          final outOfStockProducts =
              products.where((p) => p.isOutOfStock).length;
          final stockUnits = products.fold<int>(0, (sum, item) {
            final stock = item.stockQuantity < 0 ? 0 : item.stockQuantity;
            return sum + stock;
          });
          final statusColor = _statusColor(profile.verificationStatus);
          final profileReady = profile.farmName.trim().isNotEmpty &&
              profile.farmerName.trim().isNotEmpty &&
              profile.phone.trim().isNotEmpty &&
              profile.parish.trim().isNotEmpty &&
              profile.payoutMethod.trim().isNotEmpty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            children: [
              Header(
                title: profile.farmName,
                subtitle: 'Partner dashboard',
              ),
              const SizedBox(height: 16),
              FarmCard(
                padding: const EdgeInsets.all(18),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        FarmColors.deepGreen,
                        FarmColors.green,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.all(18),
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
                              color: Colors.white.withOpacity(0.16),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.26)),
                            ),
                            child: const Icon(Icons.agriculture_outlined,
                                color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.isApproved
                                      ? 'Ready to sell fresh harvests'
                                      : 'Approval status: ${profile.statusLabel}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  profile.isApproved
                                      ? 'Keep listings stocked, clear, and updated so customers can buy with confidence.'
                                      : 'Complete your profile and wait for admin review before products can go live.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.86),
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
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
                          _FarmerHeroPill(
                            icon: Icons.verified_outlined,
                            label: profile.statusLabel,
                          ),
                          _FarmerHeroPill(
                            icon: Icons.storefront_outlined,
                            label: '$liveProducts live',
                          ),
                          _FarmerHeroPill(
                            icon: Icons.inventory_2_outlined,
                            label: '$stockUnits units',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FarmerStatusCard(profile: profile),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.25,
                children: [
                  _FarmerMetricCard(
                    icon: Icons.eco_outlined,
                    label: 'Listings',
                    value: products.length.toString(),
                    color: FarmColors.green,
                  ),
                  _FarmerMetricCard(
                    icon: Icons.check_circle_outline,
                    label: 'Approved',
                    value: approvedProducts.toString(),
                    color: FarmColors.green,
                  ),
                  _FarmerMetricCard(
                    icon: Icons.warning_amber_outlined,
                    label: 'Low stock',
                    value: lowStockProducts.toString(),
                    color: FarmColors.warning,
                  ),
                  _FarmerMetricCard(
                    icon: Icons.remove_shopping_cart_outlined,
                    label: 'Out of stock',
                    value: outOfStockProducts.toString(),
                    color: FarmColors.danger,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _FarmerActionPlanCard(
                approved: profile.isApproved,
                profileReady: profileReady,
                productCount: products.length,
                lowStockCount: lowStockProducts,
                outOfStockCount: outOfStockProducts,
                statusColor: statusColor,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FarmerHeroPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FarmerHeroPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
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
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmerMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _FarmerMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.16)),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
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
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmerActionPlanCard extends StatelessWidget {
  final bool approved;
  final bool profileReady;
  final int productCount;
  final int lowStockCount;
  final int outOfStockCount;
  final Color statusColor;
  const _FarmerActionPlanCard({
    required this.approved,
    required this.profileReady,
    required this.productCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.statusColor,
  });

  Widget _step({
    required IconData icon,
    required String title,
    required String message,
    required bool done,
  }) {
    final color = done ? FarmColors.green : statusColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.18)),
            ),
            child: Icon(done ? Icons.check : icon, color: color, size: 18),
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
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
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
    return FarmCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Partner action plan',
            style: TextStyle(
              color: FarmColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _step(
            icon: Icons.person_outline,
            title: 'Complete farm profile',
            message: profileReady
                ? 'Profile, parish, phone, and payout method are present.'
                : 'Add phone, parish, and payout details so admin can verify your farm.',
            done: profileReady,
          ),
          _step(
            icon: Icons.verified_user_outlined,
            title: 'Get admin approval',
            message: approved
                ? 'Your farm can submit products to the marketplace.'
                : 'Admin approval is required before listings go live.',
            done: approved,
          ),
          _step(
            icon: Icons.add_business_outlined,
            title: 'Keep listings fresh',
            message: productCount > 0
                ? '$productCount product listing${productCount == 1 ? '' : 's'} created for review or sale.'
                : 'Add your first product with clear photos, price, unit, and stock.',
            done: productCount > 0,
          ),
          _step(
            icon: Icons.inventory_2_outlined,
            title: 'Protect stock quality',
            message: lowStockCount + outOfStockCount == 0
                ? 'No low-stock or out-of-stock listings need attention right now.'
                : '$lowStockCount low-stock and $outOfStockCount out-of-stock listing${lowStockCount + outOfStockCount == 1 ? '' : 's'} need review.',
            done: lowStockCount + outOfStockCount == 0,
          ),
        ],
      ),
    );
  }
}

class FarmerProductsScreen extends StatelessWidget {
  final FarmerProfile profile;
  final int refreshKey;
  final VoidCallback onChanged;
  const FarmerProductsScreen(
      {super.key,
      required this.profile,
      required this.refreshKey,
      required this.onChanged});

  Future<void> openProductForm(BuildContext context) async {
    if (!profile.isApproved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Admin must approve your farm before products can be submitted.',
          ),
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final unitController = TextEditingController(text: 'each');
    final descriptionController = TextEditingController();
    final imageController = TextEditingController();
    final originalPriceController = TextEditingController();
    final discountPriceController = TextEditingController();
    final discountPercentController = TextEditingController();
    final discountLabelController = TextEditingController();
    final estimatedReadyDateController = TextEditingController();
    final expectedStockController = TextEditingController();
    final subscribeSavePercentController = TextEditingController(text: '5');
    final dealRankController = TextEditingController(text: '10');

    String selectedCategory = productCategoryOptions.first;
    bool isOrganic = false;
    bool isLocal = true;
    bool isDiscountActive = false;
    bool readySoon = false;
    bool isDealOfDay = false;
    bool subscribeSaveEnabled = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 18,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
                ),
                decoration: const BoxDecoration(
                  color: FarmColors.cream,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Submit Product Listing',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: 'Product name'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration:
                            const InputDecoration(labelText: 'Category'),
                        items: productCategoryOptions
                            .map(
                              (category) => DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() {
                            selectedCategory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        value: isOrganic,
                        title: const Text('Organic item'),
                        subtitle: Text(
                          isOrganic
                              ? 'This item will show as organic in the shop.'
                              : 'Turn on only if this item is organic.',
                        ),
                        activeColor: FarmColors.green,
                        onChanged: (value) {
                          setSheetState(() {
                            isOrganic = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(labelText: 'Price'),
                      ),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final stockField = TextField(
                            controller: stockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Stock quantity'),
                          );

                          final originSelector = LocalProductSelector(
                            value: isLocal,
                            onChanged: (value) =>
                                setSheetState(() => isLocal = value),
                          );

                          if (constraints.maxWidth < 520) {
                            return Column(
                              children: [
                                stockField,
                                const SizedBox(height: 10),
                                originSelector,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: stockField),
                              const SizedBox(width: 9),
                              Expanded(child: originSelector),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        value: readySoon,
                        title: const Text('Ready soon item'),
                        subtitle: const Text(
                            'Let customers request a ready alert before this item is available.'),
                        activeColor: FarmColors.warning,
                        onChanged: (value) =>
                            setSheetState(() => readySoon = value),
                      ),
                      if (readySoon) ...[
                        TextField(
                          controller: estimatedReadyDateController,
                          decoration: const InputDecoration(
                              labelText: 'Estimated ready date',
                              helperText: 'Use YYYY-MM-DD'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: expectedStockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Expected quantity'),
                        ),
                        const SizedBox(height: 10),
                      ],
                      SwitchListTile(
                        value: isDiscountActive,
                        title: const Text('Discount / deal active'),
                        activeColor: FarmColors.warning,
                        onChanged: (value) =>
                            setSheetState(() => isDiscountActive = value),
                      ),
                      if (isDiscountActive) ...[
                        TextField(
                          controller: originalPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                              labelText: 'Original price'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: discountPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                              labelText: 'Discount price'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: discountPercentController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                              labelText: 'Discount percent'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: discountLabelController,
                          decoration:
                              const InputDecoration(labelText: 'Deal label'),
                        ),
                        const SizedBox(height: 10),
                      ],
                      SwitchListTile(
                        value: isDealOfDay,
                        title: const Text('Deal of the Day'),
                        subtitle: const Text(
                            'Feature this item in the customer deal section.'),
                        activeColor: FarmColors.warning,
                        onChanged: (value) =>
                            setSheetState(() => isDealOfDay = value),
                      ),
                      if (isDealOfDay) ...[
                        TextField(
                          controller: dealRankController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Deal display rank',
                            helperText: 'Lower numbers show first',
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      SwitchListTile(
                        value: subscribeSaveEnabled,
                        title: const Text('Subscribe & Save'),
                        subtitle: const Text(
                            'Let customers set up repeat orders for this item.'),
                        activeColor: FarmColors.success,
                        onChanged: (value) =>
                            setSheetState(() => subscribeSaveEnabled = value),
                      ),
                      if (subscribeSaveEnabled) ...[
                        TextField(
                          controller: subscribeSavePercentController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                              labelText: 'Subscribe & Save discount %'),
                        ),
                        const SizedBox(height: 10),
                      ],
                      TextField(
                        controller: unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          hintText: 'each, bundle, dozen, lb...',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FarmColors.cream,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: FarmColors.lightGreen),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Product Image',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            productImagePreviewFromUrl(
                              imageUrl: imageController.text,
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: imageController,
                              onChanged: (_) => setSheetState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Image URL',
                                helperText:
                                    'Paste a hosted image URL from Supabase Storage or another trusted source.',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.clear),
                                  label: const Text('Clear Image'),
                                  onPressed: () {
                                    imageController.clear();
                                    setSheetState(() {});
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                      ),
                      const SizedBox(height: 14),
                      PrimaryFarmButton(
                        label: 'Submit for Admin Approval',
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await createFarmerProduct(
                              farmer: profile,
                              name: nameController.text.trim(),
                              price: double.tryParse(
                                      priceController.text.trim()) ??
                                  0,
                              stockQuantity:
                                  int.tryParse(stockController.text.trim()) ??
                                      0,
                              category: selectedCategory,
                              isOrganic: isOrganic,
                              isLocal: isLocal,
                              unit: unitController.text.trim(),
                              imageUrl: imageController.text.trim().isEmpty
                                  ? null
                                  : imageController.text.trim(),
                              description: descriptionController.text.trim(),
                              isDiscountActive: isDiscountActive,
                              originalPrice: double.tryParse(
                                  originalPriceController.text.trim()),
                              discountPrice: double.tryParse(
                                  discountPriceController.text.trim()),
                              discountPercent: double.tryParse(
                                  discountPercentController.text.trim()),
                              discountLabel:
                                  discountLabelController.text.trim().isEmpty
                                      ? null
                                      : discountLabelController.text.trim(),
                              readySoon: readySoon,
                              estimatedReadyDate: estimatedReadyDateController
                                      .text
                                      .trim()
                                      .isEmpty
                                  ? null
                                  : estimatedReadyDateController.text.trim(),
                              expectedStockQuantity: int.tryParse(
                                  expectedStockController.text.trim()),
                              isDealOfDay: isDealOfDay,
                              dealRank:
                                  int.tryParse(dealRankController.text.trim()),
                              subscribeSaveEnabled: subscribeSaveEnabled,
                              subscribeSaveDiscountPercent: double.tryParse(
                                  subscribeSavePercentController.text.trim()),
                            );

                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Product submitted for admin approval.'),
                                ),
                              );
                            }

                            onChanged();
                          } catch (error) {
                            if (sheetContext.mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    error
                                        .toString()
                                        .replaceFirst('Exception: ', ''),
                                  ),
                                ),
                              );
                            }
                          }
                        },
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

    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    unitController.dispose();
    descriptionController.dispose();
    imageController.dispose();
    originalPriceController.dispose();
    discountPriceController.dispose();
    discountPercentController.dispose();
    discountLabelController.dispose();
    estimatedReadyDateController.dispose();
    expectedStockController.dispose();
    subscribeSavePercentController.dispose();
    dealRankController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FarmPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
        children: [
          Header(
              title: 'My Products', subtitle: '${profile.farmName} listings'),
          const SizedBox(height: 16),
          FarmerStatusCard(profile: profile),
          const SizedBox(height: 14),
          PrimaryFarmButton(
              label: '+ Add Product',
              onPressed: () => openProductForm(context)),
          const SizedBox(height: 16),
          FutureBuilder<List<Product>>(
            key: ValueKey('farmer-products-$refreshKey'),
            future: fetchFarmerProducts(profile.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                    height: 420, child: SkeletonList(count: 3));
              }
              final products = snapshot.data ?? [];
              if (products.isEmpty) {
                return const FarmEmptyState(
                  icon: Icons.eco_outlined,
                  title: 'No products yet',
                  message:
                      'Approved farmers can submit listings for admin approval.',
                );
              }
              return Column(
                children: products
                    .map((product) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FarmerProductListingCard(product: product),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class FarmerOrdersScreen extends StatelessWidget {
  final FarmerProfile profile;
  final int refreshKey;
  const FarmerOrdersScreen(
      {super.key, required this.profile, required this.refreshKey});

  @override
  Widget build(BuildContext context) {
    return FarmPage(
      child: FutureBuilder<List<FarmerOrderSummary>>(
        key: ValueKey('farmer-orders-$refreshKey'),
        future: fetchFarmerOrderSummaries(profile.id),
        builder: (context, snapshot) {
          final orders = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
            children: [
              const Header(
                  title: 'Farmer Orders',
                  subtitle: 'Orders containing your farm products'),
              const SizedBox(height: 16),
              if (orders.isEmpty)
                const FarmEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No farmer orders yet',
                  message:
                      'Orders containing your products will appear here once the marketplace columns are enabled.',
                )
              else
                ...orders.take(20).map((order) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FarmCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order #${order.shortOrderId}',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(order.productName,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Text(
                                'Qty ${order.quantity} • Line J\$${order.lineTotal.toStringAsFixed(2)} • Earn J\$${order.farmerEarningAmount.toStringAsFixed(2)}'),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 8, children: const [
                              Chip(label: Text('Received')),
                              Chip(label: Text('Preparing')),
                              Chip(label: Text('Ready')),
                              Chip(label: Text('Completed')),
                            ]),
                          ],
                        ),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class FarmerEarningsScreen extends StatelessWidget {
  final FarmerProfile profile;
  final int refreshKey;
  const FarmerEarningsScreen(
      {super.key, required this.profile, required this.refreshKey});

  @override
  Widget build(BuildContext context) {
    return FarmPage(
      child: FutureBuilder<List<FarmerPayout>>(
        key: ValueKey('farmer-payouts-$refreshKey'),
        future: fetchFarmerPayouts(farmerId: profile.id),
        builder: (context, snapshot) {
          final payouts = snapshot.data ?? [];
          final pending = payouts
              .where((p) => p.payoutStatus == 'pending')
              .fold<double>(0, (sum, p) => sum + p.netAmount);
          final released = payouts
              .where((p) => p.payoutStatus == 'released')
              .fold<double>(0, (sum, p) => sum + p.netAmount);
          final held = payouts
              .where((p) => p.payoutStatus == 'held')
              .fold<double>(0, (sum, p) => sum + p.netAmount);
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
            children: [
              const Header(
                  title: 'Earnings',
                  subtitle: 'Admin-controlled farmer payouts'),
              const SizedBox(height: 16),
              Wrap(spacing: 10, runSpacing: 10, children: [
                MarketplaceStatCard(
                    icon: Icons.pending_actions,
                    label: 'Pending',
                    value: 'J\$${pending.toStringAsFixed(2)}'),
                MarketplaceStatCard(
                    icon: Icons.verified,
                    label: 'Released',
                    value: 'J\$${released.toStringAsFixed(2)}'),
                MarketplaceStatCard(
                    icon: Icons.pause_circle_outline,
                    label: 'Held',
                    value: 'J\$${held.toStringAsFixed(2)}'),
              ]),
              const SizedBox(height: 16),
              if (payouts.isEmpty)
                const FarmEmptyState(
                  icon: Icons.payments_outlined,
                  title: 'No payouts yet',
                  message:
                      'Payouts appear after customer orders are paid and admin prepares farmer releases.',
                )
              else
                ...payouts.map((payout) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PayoutCard(payout: payout),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class FarmerAccountScreen extends StatelessWidget {
  final FarmerProfile profile;
  const FarmerAccountScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return FarmPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
        children: [
          const Header(
              title: 'Farmer Account', subtitle: 'Marketplace profile'),
          const SizedBox(height: 16),
          FarmerStatusCard(profile: profile),
          const SizedBox(height: 16),
          FarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TraceRow(
                    icon: Icons.person_outline,
                    title: 'Farmer',
                    value: profile.farmerName),
                TraceRow(
                    icon: Icons.phone_outlined,
                    title: 'Phone',
                    value: profile.phone),
                TraceRow(
                    icon: Icons.location_on_outlined,
                    title: 'Parish',
                    value: profile.parish),
                TraceRow(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Payout method',
                    value: profile.payoutMethod.isEmpty
                        ? 'Not provided'
                        : profile.payoutMethod),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryFarmButton(
            label: 'Sign Out',
            onPressed: () async {
              await clearPrivateSessionStateForGuestBrowsing();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainNavigation()),
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class FarmerStatusCard extends StatelessWidget {
  final FarmerProfile profile;
  const FarmerStatusCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final color = profile.isApproved
        ? FarmColors.green
        : profile.verificationStatus == 'rejected'
            ? FarmColors.danger
            : FarmColors.warning;
    return FarmCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: FarmColors.lightGreen,
            child: Icon(Icons.agriculture_outlined, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.farmName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${profile.farmerName} • ${profile.parish}',
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Chip(
                    label: Text(profile.statusLabel),
                    labelStyle:
                        TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FarmerProductListingCard extends StatelessWidget {
  final Product product;
  const FarmerProductListingCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductVisual(product: product, size: 64),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                    product.description?.trim().isEmpty == false
                        ? product.description!.trim()
                        : 'Fresh farm listing.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  Chip(
                      label:
                          DiscountPriceText(product: product, compact: true)),
                  Chip(label: Text(product.category)),
                  if (product.isOrganic) const Chip(label: Text('Organic')),
                  Chip(label: Text('Stock: ${product.stockQuantity}')),
                  Chip(label: Text(_friendlyStatus(product.approvalStatus))),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Hidden from the main admin tab bar to keep daily admin work focused.
class AdminAuditLogsScreen extends StatelessWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Logs')),
      body: const AdminAuditLogsTab(),
    );
  }
}

class AdminAuditLogsTab extends StatefulWidget {
  final int refreshKey;

  const AdminAuditLogsTab({super.key, this.refreshKey = 0});

  @override
  State<AdminAuditLogsTab> createState() => _AdminAuditLogsTabState();
}

class _AdminAuditLogsTabState extends State<AdminAuditLogsTab> {
  late Future<List<AuditLogEntry>> _future;
  String? _actionFilter;
  String? _tableFilter;

  @override
  void initState() {
    super.initState();
    _future = _loadLogs();
  }

  @override
  void didUpdateWidget(covariant AdminAuditLogsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) {
      _refresh();
    }
  }

  Future<List<AuditLogEntry>> _loadLogs() {
    return fetchAdminAuditLogs(
      limit: 75,
      action: _actionFilter,
      tableName: _tableFilter,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadLogs();
    });
    await _future;
  }

  void _setFilters({String? action, String? tableName}) {
    setState(() {
      _actionFilter = action;
      _tableFilter = tableName;
      _future = _loadLogs();
    });
  }

  Widget _filterChip({
    required String label,
    String? action,
    String? tableName,
  }) {
    final selected = _actionFilter == action && _tableFilter == tableName;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _setFilters(action: action, tableName: tableName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<AuditLogEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Header(
                  title: 'Audit Logs',
                  subtitle: 'Admin activity history',
                ),
                const SizedBox(height: 12),
                FarmCard(
                  child: Text(
                    friendlyAppError(snapshot.error!),
                    style: const TextStyle(
                      color: FarmColors.error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            );
          }

          final logs = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Header(
                title: 'Audit Logs',
                subtitle: 'Order, product, coupon and admin activity history',
              ),
              const SizedBox(height: 12),
              FarmCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _filterChip(label: 'All'),
                        _filterChip(
                          label: 'Orders',
                          tableName: 'orders',
                        ),
                        _filterChip(
                          label: 'Products',
                          tableName: 'products',
                        ),
                        _filterChip(
                          label: 'Product updates',
                          action: 'admin_update_product',
                        ),
                        _filterChip(
                          label: 'Order updates',
                          action: 'admin_update_order',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (logs.isEmpty)
                const FarmCard(
                  child: Text(
                    'No audit logs found yet.',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                )
              else
                ...logs.map((log) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FarmCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  avatar: const Icon(
                                    Icons.admin_panel_settings_outlined,
                                    size: 18,
                                  ),
                                  label: Text(log.formattedAction),
                                ),
                                Chip(
                                  avatar: const Icon(
                                    Icons.table_rows_outlined,
                                    size: 18,
                                  ),
                                  label: Text(log.tableName),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Record: ${log.shortRecordId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: FarmColors.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Actor: ${log.shortActorId}',
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formatCustomerDateTime(log.createdAt),
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                              ),
                            ),
                            if (log.metadata.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: FarmColors.cardSoft,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: FarmColors.line),
                                ),
                                child: SelectableText(
                                  log.metadata.entries
                                      .map((entry) =>
                                          '${entry.key}: ${entry.value}')
                                      .join('\n'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: FarmColors.mutedText,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class _AdminTabSpec {
  final Tab tab;
  final Widget child;

  const _AdminTabSpec({
    required this.tab,
    required this.child,
  });
}

List<_AdminTabSpec> _adminTabSpecsForRole({
  required String staffRole,
  required int refreshKey,
  required VoidCallback onChanged,
}) {
  final role = normalizeStaffRole(staffRole);
  final ownerAccess = role.isEmpty || role == 'owner';
  final managerAccess = role == 'manager';

  _AdminTabSpec dashboard() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.dashboard_customize_outlined),
          text: 'Dashboard',
        ),
        child: AdminDashboardOverviewTab(refreshKey: refreshKey),
      );

  _AdminTabSpec orders() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.receipt_long),
          text: 'Orders',
        ),
        child: AdminOrdersTab(
          refreshKey: refreshKey,
          onChanged: onChanged,
        ),
      );

  _AdminTabSpec fulfillment() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.local_shipping_outlined),
          text: 'Fulfillment',
        ),
        child: AdminDeliveryTab(
          refreshKey: refreshKey,
          onChanged: onChanged,
        ),
      );

  _AdminTabSpec analytics() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.analytics_outlined),
          text: 'Analytics',
        ),
        child: AdminAnalyticsTab(refreshKey: refreshKey),
      );

  _AdminTabSpec products() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.eco),
          text: 'Products',
        ),
        child: AdminProductsTab(
          refreshKey: refreshKey,
          onChanged: onChanged,
        ),
      );

  _AdminTabSpec hero() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.photo_library_outlined),
          text: 'Hero',
        ),
        child: AdminHeroSlidesTab(
          refreshKey: refreshKey,
          onChanged: onChanged,
        ),
      );

  _AdminTabSpec support() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.support_agent_outlined),
          text: 'Support',
        ),
        child: AdminSupportTab(
          refreshKey: refreshKey,
          onChanged: onChanged,
        ),
      );

  _AdminTabSpec farmers() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.agriculture_outlined),
          text: 'Farmers',
        ),
        child: AdminFarmerManagementTab(
          refreshKey: refreshKey,
          onChanged: onChanged,
        ),
      );

  _AdminTabSpec payouts() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.payments_outlined),
          text: 'Payouts',
        ),
        child: AdminPayoutsTab(
          refreshKey: refreshKey,
          onChanged: onChanged,
        ),
      );

  _AdminTabSpec reports() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.table_chart_outlined),
          text: 'Reports',
        ),
        child: AdminReportsTab(refreshKey: refreshKey),
      );

  _AdminTabSpec reviews() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.rate_review_outlined),
          text: 'Reviews',
        ),
        child: AdminReviewsTab(refreshKey: refreshKey),
      );

  _AdminTabSpec coupons() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.confirmation_number_outlined),
          text: 'Coupons',
        ),
        child: AdminCouponsTab(
          refreshKey: refreshKey,
          onChanged: onChanged,
        ),
      );

  _AdminTabSpec staff() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.badge_outlined),
          text: 'Staff',
        ),
        child: AdminStaffTab(
          refreshKey: refreshKey,
          onChanged: onChanged,
        ),
      );

  if (ownerAccess) {
    return [
      dashboard(),
      orders(),
      fulfillment(),
      analytics(),
      products(),
      hero(),
      support(),
      farmers(),
      payouts(),
      reports(),
      reviews(),
      coupons(),
      staff(),
    ];
  }

  if (managerAccess) {
    return [
      dashboard(),
      orders(),
      fulfillment(),
      analytics(),
      products(),
      support(),
      reports(),
      reviews(),
    ];
  }

  switch (role) {
    case 'packer':
      return [
        orders(),
        fulfillment(),
      ];
    case 'delivery':
      return [
        fulfillment(),
        orders(),
      ];
    case 'inventory':
      return [
        products(),
        reports(),
      ];
    case 'support':
      return [
        support(),
      ];
    default:
      return [
        orders(),
        fulfillment(),
      ];
  }
}

class AdminDashboardScreen extends StatefulWidget {
  final VoidCallback? onHomeTap;

  const AdminDashboardScreen({super.key, this.onHomeTap});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final Future<bool> _adminAllowedFuture;
  late Future<String> _staffRoleFuture;
  int refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _adminAllowedFuture = isCurrentUserAdminFromDatabase();
    _staffRoleFuture = fetchCurrentStaffRole();
  }

  void refresh() {
    setState(() {
      refreshKey++;
      _staffRoleFuture = fetchCurrentStaffRole();
    });
  }

  void goBackHome() {
    if (widget.onHomeTap != null) {
      widget.onHomeTap!();
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _adminAllowedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final allowed = snapshot.data == true;

        if (!allowed) {
          return FarmPage(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: const [
                Header(
                  title: 'Admin Locked',
                  subtitle: 'Staff access required',
                ),
                SizedBox(height: 18),
                FarmCard(
                  child: Text(
                    'This area is only available to approved owner, manager, or staff users.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        }

        return FutureBuilder<String>(
          future: _staffRoleFuture,
          builder: (context, roleSnapshot) {
            final staffRole = normalizeStaffRole(roleSnapshot.data);
            final roleLabel = staffRoleDisplayLabel(staffRole);
            final tabs = _adminTabSpecsForRole(
              staffRole: staffRole,
              refreshKey: refreshKey,
              onChanged: refresh,
            );

            final dashboardTitle =
                staffRole.isEmpty ? 'Admin Dashboard' : '$roleLabel Dashboard';
            final dashboardSubtitle = staffRole.isEmpty
                ? 'Manage orders, products, customers, and store updates.'
                : roleLabel == 'Owner' || roleLabel == 'Manager'
                    ? 'Full access to orders, products, customers, and store updates.'
                    : 'Limited access for ${roleLabel.toLowerCase()} workflow.';

            return FarmPage(
              child: DefaultTabController(
                length: tabs.length,
                initialIndex: 0,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                      child: Header(
                        title: dashboardTitle,
                        subtitle: dashboardSubtitle,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                      child: Row(
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.home_outlined),
                            label: const Text('Back to Home'),
                            onPressed: goBackHome,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: FarmColors.lightGreen,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: FarmColors.green.withOpacity(0.18),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_user_outlined,
                                  size: 15,
                                  color: FarmColors.green,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  roleLabel,
                                  style: const TextStyle(
                                    color: FarmColors.green,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: 'Refresh admin dashboard',
                            onPressed: refresh,
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: Colors.transparent,
                      child: TabBar(
                        isScrollable: true,
                        labelColor: FarmColors.green,
                        indicatorColor: FarmColors.green,
                        tabs: tabs.map((item) => item.tab).toList(),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: tabs.map((item) => item.child).toList(),
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
  }
}

class AdminStaffTab extends StatefulWidget {
  final int refreshKey;
  final VoidCallback onChanged;

  const AdminStaffTab({
    super.key,
    required this.refreshKey,
    required this.onChanged,
  });

  @override
  State<AdminStaffTab> createState() => _AdminStaffTabState();
}

class _AdminStaffTabState extends State<AdminStaffTab> {
  late Future<List<StaffUserAccount>> _future;
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final notesController = TextEditingController();
  String selectedRole = 'packer';
  bool isActive = true;
  String? editingId;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _future = fetchStaffUsersForAdmin();
  }

  @override
  void didUpdateWidget(covariant AdminStaffTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) {
      _reload();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final future = fetchStaffUsersForAdmin();
    setState(() {
      _future = future;
    });
    await future;
  }

  void _clearForm() {
    setState(() {
      editingId = null;
      emailController.clear();
      nameController.clear();
      notesController.clear();
      selectedRole = 'packer';
      isActive = true;
    });
  }

  void _editStaff(StaffUserAccount staff) {
    if (normalizeStaffRole(staff.role) == 'owner') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Owner access is managed manually for safety.'),
        ),
      );
      return;
    }

    setState(() {
      editingId = staff.id;
      emailController.text = staff.email;
      nameController.text = staff.fullName;
      notesController.text = staff.notes ?? '';
      selectedRole =
          staffAssignableRoles.contains(staff.role) ? staff.role : 'packer';
      isActive = staff.isActive;
    });
  }

  Future<void> _saveStaff() async {
    if (saving) return;

    setState(() => saving = true);
    try {
      await saveStaffUserForAdmin(
        id: editingId,
        email: emailController.text,
        fullName: nameController.text,
        role: selectedRole,
        isActive: isActive,
        notes: notesController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              editingId == null ? 'Staff user added.' : 'Staff user updated.'),
        ),
      );
      _clearForm();
      widget.onChanged();
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _toggleActive(StaffUserAccount staff) async {
    try {
      await setStaffUserActiveForAdmin(
        staff: staff,
        isActive: !staff.isActive,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(staff.isActive
              ? 'Staff user deactivated.'
              : 'Staff user activated.'),
        ),
      );
      widget.onChanged();
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Widget _roleChip(String role, {bool active = true}) {
    final color = active ? FarmColors.green : FarmColors.mutedText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? FarmColors.lightGreen : FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Text(
        staffRoleDisplayLabel(role),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _staffCard(StaffUserAccount staff) {
    final role = normalizeStaffRole(staff.role);
    final owner = role == 'owner';
    final activeColor =
        staff.isActive ? FarmColors.green : FarmColors.mutedText;

    return FarmCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: staff.isActive
                    ? FarmColors.lightGreen
                    : FarmColors.cardSoft,
                child: Text(
                  staff.initials,
                  style: TextStyle(
                    color: activeColor,
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
                      staff.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      staff.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _roleChip(role, active: staff.isActive),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            staffRoleWorkflowSummary(role),
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: Icon(
                  staff.isActive
                      ? Icons.check_circle_outline
                      : Icons.block_outlined,
                  size: 17,
                  color: activeColor,
                ),
                label: Text(staff.isActive ? 'Active' : 'Inactive'),
              ),
              if (staff.userId == null || staff.userId!.trim().isEmpty)
                const Chip(
                  avatar: Icon(Icons.mail_outline, size: 17),
                  label: Text('Email invite ready'),
                )
              else
                const Chip(
                  avatar: Icon(Icons.verified_user_outlined, size: 17),
                  label: Text('Account linked'),
                ),
            ],
          ),
          if (!owner) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    onPressed: () => _editStaff(staff),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(
                      staff.isActive
                          ? Icons.block_outlined
                          : Icons.check_circle_outline,
                      size: 18,
                    ),
                    label: Text(staff.isActive ? 'Deactivate' : 'Activate'),
                    onPressed: () => _toggleActive(staff),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<List<StaffUserAccount>>(
        future: _future,
        builder: (context, snapshot) {
          final staff = snapshot.data ?? const <StaffUserAccount>[];
          final loading = snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
            children: [
              const Header(
                title: 'Staff Users',
                subtitle:
                    'Owner-only staff setup for safe warehouse operations.',
              ),
              const SizedBox(height: 14),
              FarmCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      editingId == null
                          ? 'Add staff member'
                          : 'Edit staff member',
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Only the owner can add, edit, activate, or deactivate staff. Do not share the owner password.',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Staff email',
                        hintText: 'worker@example.com',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                        hintText: 'Optional',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: staffAssignableRoles
                          .map(
                            (role) => DropdownMenuItem<String>(
                              value: role,
                              child: Text(staffRoleDisplayLabel(role)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => selectedRole = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isActive,
                      activeColor: FarmColors.green,
                      title: const Text('Active staff access'),
                      subtitle: Text(
                        isActive
                            ? 'This worker can sign in with the selected role.'
                            : 'This worker is blocked from staff tools.',
                      ),
                      onChanged: (value) => setState(() => isActive = value),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Optional internal note',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryFarmButton(
                            label: saving
                                ? 'Saving...'
                                : editingId == null
                                    ? 'Add Staff'
                                    : 'Save Staff',
                            onPressed: saving ? null : _saveStaff,
                          ),
                        ),
                        if (editingId != null) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.close),
                              label: const Text('Cancel'),
                              onPressed: saving ? null : _clearForm,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AdminSectionCard(
                icon: Icons.security_outlined,
                title: 'Role guide',
                subtitle: 'Recommended access for daily warehouse operations.',
                children: staffAssignableRoles
                    .map(
                      (role) => AdminActionTile(
                        icon: role == 'manager'
                            ? Icons.admin_panel_settings_outlined
                            : role == 'packer'
                                ? Icons.inventory_2_outlined
                                : role == 'delivery'
                                    ? Icons.local_shipping_outlined
                                    : role == 'inventory'
                                        ? Icons.fact_check_outlined
                                        : Icons.support_agent_outlined,
                        title: staffRoleDisplayLabel(role),
                        description: staffRoleWorkflowSummary(role),
                        color: FarmColors.green,
                        onTap: () {},
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              const Text(
                'Current staff',
                style: TextStyle(
                  color: FarmColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              if (loading)
                const SizedBox(height: 360, child: SkeletonList(count: 3))
              else if (staff.isEmpty)
                const FarmEmptyState(
                  icon: Icons.badge_outlined,
                  title: 'No staff users found',
                  message:
                      'Add a staff email above to prepare role-based access.',
                )
              else
                ...staff.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _staffCard(item),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class AdminOverviewSnapshot {
  final List<AdminOrder> orders;
  final List<Product> products;
  final List<SupportTicket> supportTickets;

  const AdminOverviewSnapshot({
    required this.orders,
    required this.products,
    required this.supportTickets,
  });

  int get todaysOrders {
    final now = DateTime.now();

    return orders.where((order) {
      final created = order.createdAt;
      if (created == null) return false;

      final local = created.toLocal();

      return local.year == now.year &&
          local.month == now.month &&
          local.day == now.day;
    }).length;
  }

  int get pendingOrders {
    return orders.where((order) {
      final status = order.status.trim().toLowerCase();
      return status == 'pending' || status == 'preparing';
    }).length;
  }

  int get unpaidPayments {
    return orders.where((order) {
      final status = order.paymentStatus.trim().toLowerCase();

      return status != 'paid' && status != 'refunded' && status != 'cancelled';
    }).length;
  }

  int get lowStockItems {
    return products.where((product) => product.isLowStock).length;
  }

  int get openSupportMessages {
    return supportTickets.where((ticket) {
      final status = ticket.status.trim().toLowerCase();

      return status == 'open' || status == 'pending' || status == 'new';
    }).length;
  }

  int get activeOrders {
    return orders.where((order) {
      final status = order.status.trim().toLowerCase();

      return status != 'completed' &&
          status != 'delivered' &&
          status != 'cancelled' &&
          status != 'canceled' &&
          status != 'rejected';
    }).length;
  }
}

Future<AdminOverviewSnapshot> fetchAdminOverviewSnapshot() async {
  Future<List<AdminOrder>> safeOrders() async {
    try {
      return await fetchAdminOrders();
    } catch (error) {
      farmDebugLog('Admin dashboard orders summary skipped: $error');
      return <AdminOrder>[];
    }
  }

  Future<List<Product>> safeProducts() async {
    try {
      return await fetchProducts();
    } catch (error) {
      farmDebugLog('Admin dashboard product summary skipped: $error');
      return <Product>[];
    }
  }

  Future<List<SupportTicket>> safeSupportTickets() async {
    try {
      return await fetchAdminSupportTickets();
    } catch (error) {
      farmDebugLog('Admin dashboard support summary skipped: $error');
      return <SupportTicket>[];
    }
  }

  final results = await Future.wait<dynamic>([
    safeOrders(),
    safeProducts(),
    safeSupportTickets(),
  ]);

  return AdminOverviewSnapshot(
    orders: results[0] as List<AdminOrder>,
    products: results[1] as List<Product>,
    supportTickets: results[2] as List<SupportTicket>,
  );
}

class AdminDashboardOverviewTab extends StatefulWidget {
  final int refreshKey;

  const AdminDashboardOverviewTab({
    super.key,
    required this.refreshKey,
  });

  @override
  State<AdminDashboardOverviewTab> createState() =>
      _AdminDashboardOverviewTabState();
}

class _AdminDashboardOverviewTabState extends State<AdminDashboardOverviewTab> {
  late Future<AdminOverviewSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchAdminOverviewSnapshot();
  }

  @override
  void didUpdateWidget(covariant AdminDashboardOverviewTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshKey != widget.refreshKey) {
      _reload();
    }
  }

  Future<void> _reload() async {
    final future = fetchAdminOverviewSnapshot();
    setState(() {
      _future = future;
    });
    await future;
  }

  void _openTab(int index) {
    DefaultTabController.of(context).animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<AdminOverviewSnapshot>(
        future: _future,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData;

          final overview = snapshot.data ??
              const AdminOverviewSnapshot(
                orders: <AdminOrder>[],
                products: <Product>[],
                supportTickets: <SupportTicket>[],
              );

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
            children: [
              AdminDashboardHero(
                loading: loading,
                todaysOrders: overview.todaysOrders,
                pendingOrders: overview.pendingOrders,
                unpaidPayments: overview.unpaidPayments,
                lowStockItems: overview.lowStockItems,
              ),
              const SizedBox(height: 16),
              AdminUrgentActionsCard(
                pendingOrders: overview.pendingOrders,
                unpaidPayments: overview.unpaidPayments,
                lowStockItems: overview.lowStockItems,
                openSupportMessages: overview.openSupportMessages,
                onOrdersTap: () => _openTab(1),
                onFulfillmentTap: () => _openTab(2),
                onProductsTap: () => _openTab(4),
                onSupportTap: () => _openTab(6),
              ),
              const SizedBox(height: 16),
              AdminSectionCard(
                icon: Icons.receipt_long_outlined,
                title: 'Orders & Fulfillment',
                subtitle: 'Track orders, payments, pickup, and delivery.',
                children: [
                  AdminActionTile(
                    icon: Icons.list_alt_rounded,
                    title: 'View orders',
                    description: 'Review all customer orders and order status.',
                    badge: overview.pendingOrders > 0
                        ? '${overview.pendingOrders} active'
                        : null,
                    color: FarmColors.green,
                    onTap: () => _openTab(1),
                  ),
                  AdminActionTile(
                    icon: Icons.local_shipping_outlined,
                    title: 'Pickup & delivery',
                    description:
                        'Prepare orders, mark ready, deliver, or complete.',
                    badge: overview.activeOrders > 0
                        ? '${overview.activeOrders} open'
                        : null,
                    color: const Color(0xFF227C88),
                    onTap: () => _openTab(2),
                  ),
                  AdminActionTile(
                    icon: Icons.payments_outlined,
                    title: 'Payment verification',
                    description: 'Check unpaid and pending payment orders.',
                    badge: overview.unpaidPayments > 0
                        ? '${overview.unpaidPayments} unpaid'
                        : null,
                    color: FarmColors.warning,
                    onTap: () => _openTab(1),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AdminSectionCard(
                icon: Icons.eco_outlined,
                title: 'Products & Inventory',
                subtitle: 'Manage stock, products, approvals, and deals.',
                children: [
                  AdminActionTile(
                    icon: Icons.inventory_2_outlined,
                    title: 'Manage products',
                    description:
                        'Edit listings, stock, availability, and status.',
                    badge: overview.lowStockItems > 0
                        ? '${overview.lowStockItems} low'
                        : null,
                    color: FarmColors.green,
                    onTap: () => _openTab(4),
                  ),
                  AdminActionTile(
                    icon: Icons.add_box_outlined,
                    title: 'Add product',
                    description: 'Create a new product and upload an image.',
                    color: FarmColors.gold,
                    onTap: () => _openTab(4),
                  ),
                  AdminActionTile(
                    icon: Icons.local_offer_outlined,
                    title: 'Deals, discounts & coupons',
                    description:
                        'Review deals, product discounts, and coupon tools.',
                    color: const Color(0xFF7D5A21),
                    onTap: () => _openTab(11),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AdminSectionCard(
                icon: Icons.people_alt_outlined,
                title: 'Customers & Messages',
                subtitle: 'Support, customer feedback, and partner reviews.',
                children: [
                  AdminActionTile(
                    icon: Icons.support_agent_outlined,
                    title: 'Support messages',
                    description:
                        'Reply to customer questions and help requests.',
                    badge: overview.openSupportMessages > 0
                        ? '${overview.openSupportMessages} open'
                        : null,
                    color: FarmColors.danger,
                    onTap: () => _openTab(6),
                  ),
                  AdminActionTile(
                    icon: Icons.rate_review_outlined,
                    title: 'Reviews & feedback',
                    description: 'Read product reviews and customer comments.',
                    color: FarmColors.green,
                    onTap: () => _openTab(10),
                  ),
                  AdminActionTile(
                    icon: Icons.agriculture_outlined,
                    title: 'Farmer partners',
                    description:
                        'Review farmer profiles, status, and approvals.',
                    color: const Color(0xFF6E7D4F),
                    onTap: () => _openTab(7),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AdminSectionCard(
                icon: Icons.query_stats_rounded,
                title: 'Sales & Reports',
                subtitle: 'Revenue, exports, payouts, and business insights.',
                children: [
                  AdminActionTile(
                    icon: Icons.analytics_outlined,
                    title: 'Analytics',
                    description:
                        'See operational trends and store performance.',
                    color: FarmColors.green,
                    onTap: () => _openTab(3),
                  ),
                  AdminActionTile(
                    icon: Icons.table_chart_outlined,
                    title: 'Reports & CSV',
                    description:
                        'Review sales summaries and export order data.',
                    color: const Color(0xFF227C88),
                    onTap: () => _openTab(9),
                  ),
                  AdminActionTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Payouts',
                    description: 'Review farmer payout records and status.',
                    color: FarmColors.gold,
                    onTap: () => _openTab(8),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AdminSectionCard(
                icon: Icons.storefront_outlined,
                title: 'Storefront & Content',
                subtitle: 'Control the customer-facing market experience.',
                children: [
                  AdminActionTile(
                    icon: Icons.photo_library_outlined,
                    title: 'Home hero images',
                    description: 'Upload and manage the home slideshow.',
                    color: FarmColors.green,
                    onTap: () => _openTab(5),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class AdminDashboardHero extends StatelessWidget {
  final bool loading;
  final int todaysOrders;
  final int pendingOrders;
  final int unpaidPayments;
  final int lowStockItems;

  const AdminDashboardHero({
    super.key,
    required this.loading,
    required this.todaysOrders,
    required this.pendingOrders,
    required this.unpaidPayments,
    required this.lowStockItems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FarmColors.deepGreen,
            FarmColors.green,
            Color(0xFF3E7B50),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: FarmColors.shadow.withOpacity(0.16),
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
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Icon(
                  Icons.dashboard_customize_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Daily command center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            loading
                ? 'Loading today’s store snapshot...'
                : 'Focus first on orders, payments, low stock, and support.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.86),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          AdminSummaryGrid(
            children: [
              AdminSummaryCard(
                title: 'Today',
                value: loading ? '...' : '$todaysOrders',
                note: 'orders',
                icon: Icons.today_outlined,
              ),
              AdminSummaryCard(
                title: 'Pending',
                value: loading ? '...' : '$pendingOrders',
                note: 'orders',
                icon: Icons.pending_actions_outlined,
              ),
              AdminSummaryCard(
                title: 'Unpaid',
                value: loading ? '...' : '$unpaidPayments',
                note: 'payments',
                icon: Icons.payments_outlined,
              ),
              AdminSummaryCard(
                title: 'Low stock',
                value: loading ? '...' : '$lowStockItems',
                note: 'items',
                icon: Icons.inventory_2_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AdminSummaryGrid extends StatelessWidget {
  final List<Widget> children;

  const AdminSummaryGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 4 : 2;
        final spacing = 10.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map(
                (child) => SizedBox(
                  width: itemWidth,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class AdminSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String note;
  final IconData icon;

  const AdminSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.note,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$title • $note',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminUrgentActionsCard extends StatelessWidget {
  final int pendingOrders;
  final int unpaidPayments;
  final int lowStockItems;
  final int openSupportMessages;
  final VoidCallback onOrdersTap;
  final VoidCallback onFulfillmentTap;
  final VoidCallback onProductsTap;
  final VoidCallback onSupportTap;

  const AdminUrgentActionsCard({
    super.key,
    required this.pendingOrders,
    required this.unpaidPayments,
    required this.lowStockItems,
    required this.openSupportMessages,
    required this.onOrdersTap,
    required this.onFulfillmentTap,
    required this.onProductsTap,
    required this.onSupportTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrgent = pendingOrders > 0 ||
        unpaidPayments > 0 ||
        lowStockItems > 0 ||
        openSupportMessages > 0;

    return FarmCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.priority_high_rounded,
                  color: FarmColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasUrgent ? 'Needs attention' : 'Store looks steady',
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hasUrgent
                ? 'Handle the most important admin work first.'
                : 'No urgent admin items are showing right now.',
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminQuickChip(
                label: 'Orders',
                count: pendingOrders,
                icon: Icons.receipt_long_outlined,
                onTap: onOrdersTap,
              ),
              AdminQuickChip(
                label: 'Payments',
                count: unpaidPayments,
                icon: Icons.payments_outlined,
                onTap: onFulfillmentTap,
              ),
              AdminQuickChip(
                label: 'Low stock',
                count: lowStockItems,
                icon: Icons.inventory_2_outlined,
                onTap: onProductsTap,
              ),
              AdminQuickChip(
                label: 'Support',
                count: openSupportMessages,
                icon: Icons.support_agent_outlined,
                onTap: onSupportTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AdminQuickChip extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  const AdminQuickChip({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = count > 0;

    return ActionChip(
      avatar: Icon(
        icon,
        size: 18,
        color: active ? Colors.white : FarmColors.green,
      ),
      label: Text(active ? '$label • $count' : label),
      labelStyle: TextStyle(
        color: active ? Colors.white : FarmColors.green,
        fontWeight: FontWeight.w900,
      ),
      backgroundColor: active ? FarmColors.green : FarmColors.lightGreen,
      side: BorderSide(
        color: active ? FarmColors.green : FarmColors.line,
      ),
      onPressed: onTap,
    );
  }
}

class AdminSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const AdminSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
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
                  color: FarmColors.lightGreen,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FarmColors.line),
                ),
                child: Icon(icon, color: FarmColors.green),
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
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class AdminActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? badge;
  final Color color;
  final VoidCallback onTap;

  const AdminActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final badgeText = badge?.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: FarmColors.cardSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FarmColors.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 22),
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
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (badgeText != null && badgeText.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color.withOpacity(0.22)),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              else
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

class AdminReportsTab extends StatefulWidget {
  final int refreshKey;

  const AdminReportsTab({super.key, required this.refreshKey});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  late Future<List<AdminOrder>> _ordersFuture;
  int _rangeDays = 0;

  @override
  void initState() {
    super.initState();
    _ordersFuture = fetchAdminOrders();
  }

  @override
  void didUpdateWidget(covariant AdminReportsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) {
      _reload();
    }
  }

  Future<void> _reload() async {
    final future = fetchAdminOrders();
    setState(() {
      _ordersFuture = future;
    });
    await future;
  }

  String _money(double value) => 'J\$${value.toStringAsFixed(2)}';

  String _rangeName() {
    if (_rangeDays == 1) return 'Today';
    if (_rangeDays == 7) return 'Last 7 days';
    if (_rangeDays == 30) return 'Last 30 days';
    return 'All orders';
  }

  List<AdminOrder> _filteredOrders(List<AdminOrder> orders) {
    if (_rangeDays <= 0) return List<AdminOrder>.from(orders);
    final now = DateTime.now();
    final start = _rangeDays == 1
        ? DateTime(now.year, now.month, now.day)
        : now.subtract(Duration(days: _rangeDays));
    return orders.where((order) {
      final created = order.createdAt;
      if (created == null) return false;
      return !created.isBefore(start);
    }).toList();
  }

  Map<String, int> _countByStatus(List<AdminOrder> orders) {
    final output = <String, int>{};
    for (final order in orders) {
      final key = order.status.trim().isEmpty ? 'pending' : order.status.trim();
      output[key] = (output[key] ?? 0) + 1;
    }
    return output;
  }

  Map<String, int> _countByPaymentMethod(List<AdminOrder> orders) {
    final output = <String, int>{};
    for (final order in orders) {
      final key = order.paymentMethod.trim().isEmpty
          ? 'cash_on_pickup'
          : order.paymentMethod.trim();
      output[key] = (output[key] ?? 0) + 1;
    }
    return output;
  }

  List<MapEntry<String, int>> _topProducts(List<AdminOrder> orders) {
    final itemCounts = <String, int>{};
    for (final order in orders) {
      for (final item in order.items) {
        final name = item.productName.trim().isEmpty
            ? 'Product'
            : item.productName.trim();
        itemCounts[name] = (itemCounts[name] ?? 0) + item.quantity;
      }
    }

    final entries = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  String _reportSummary(List<AdminOrder> orders) {
    final paidOrders =
        orders.where((order) => order.paymentStatus == 'paid').toList();
    final unpaidOrders =
        orders.where((order) => order.paymentStatus != 'paid').toList();
    final deliveryOrders =
        orders.where((order) => order.fulfillmentType == 'delivery').length;
    final pickupOrders =
        orders.where((order) => order.fulfillmentType != 'delivery').length;
    final totalRevenue =
        paidOrders.fold<double>(0, (sum, order) => sum + order.total);
    final openBalance =
        unpaidOrders.fold<double>(0, (sum, order) => sum + order.total);
    final averageOrder = orders.isEmpty
        ? 0.0
        : orders.fold<double>(0, (sum, order) => sum + order.total) /
            orders.length;
    final topItems = _topProducts(orders).take(5).toList();

    return '''
The Harvest Place Ja Business Report
Range: ${_rangeName()}

Orders: ${orders.length}
Paid Orders: ${paidOrders.length}
Unpaid / Pending Payment: ${unpaidOrders.length}
Paid Revenue: ${_money(totalRevenue)}
Open Balance: ${_money(openBalance)}
Average Order Value: ${_money(averageOrder)}
Pickup Orders: $pickupOrders
Delivery Orders: $deliveryOrders

Top Products:
${topItems.isEmpty ? 'No product sales yet.' : topItems.map((entry) => '- ${entry.key}: ${entry.value} sold').join('\n')}

Generated from Admin Reports.
''';
  }

  Future<void> _copyText(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _showReportDialog({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: SelectableText(content)),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copy'),
            onPressed: () => _copyText(context, content),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _rangeSelector() {
    Widget chip(String label, int value) {
      final selected = _rangeDays == value;
      return ChoiceChip(
        selected: selected,
        label: Text(label),
        onSelected: (_) => setState(() => _rangeDays = value),
        selectedColor: FarmColors.lightGreen,
        labelStyle: TextStyle(
          color: selected ? FarmColors.green : FarmColors.mutedText,
          fontWeight: FontWeight.w900,
        ),
        side: BorderSide(
          color:
              selected ? FarmColors.green.withOpacity(0.30) : FarmColors.line,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('All', 0),
          const SizedBox(width: 8),
          chip('Today', 1),
          const SizedBox(width: 8),
          chip('7 days', 7),
          const SizedBox(width: 8),
          chip('30 days', 30),
        ],
      ),
    );
  }

  Widget _hero({
    required List<AdminOrder> orders,
    required double revenue,
    required double openBalance,
    required double averageOrder,
  }) {
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
            Color(0xFF4F8A5B),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: FarmColors.green.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REPORTING CENTER',
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _money(revenue),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_rangeName()} • ${orders.length} order${orders.length == 1 ? '' : 's'} reviewed',
            style: TextStyle(
              color: Colors.white.withOpacity(0.86),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _heroStat('Avg order', _money(averageOrder)),
              const SizedBox(width: 10),
              _heroStat('Open', _money(openBalance)),
              const SizedBox(width: 10),
              _heroStat('Orders', '${orders.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
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
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.76),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardWidth = width < 390 ? (width - 10) / 2 : (width - 20) / 3;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: children
              .map((child) => SizedBox(width: cardWidth, child: child))
              .toList(),
        );
      },
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    Color color = FarmColors.green,
    String? note,
  }) {
    return FarmCard(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        height: 108,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.11),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 19),
                ),
                const Spacer(),
                if (note != null && note.trim().isNotEmpty)
                  Text(
                    note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 11.5,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2, right: 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 12,
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

  Widget _breakdownCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    String emptyText = 'No data yet.',
  }) {
    return FarmCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: FarmColors.lightGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: FarmColors.green, size: 19),
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
                        fontSize: 15,
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
          if (children.isEmpty)
            Text(
              emptyText,
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...children,
        ],
      ),
    );
  }

  Widget _breakdownRow({
    required String title,
    required String value,
    IconData icon = Icons.circle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 16, color: FarmColors.green),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
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

  Widget _exportPanel(List<AdminOrder> orders) {
    final csv = buildSalesCsv(orders);
    final report = _reportSummary(orders);

    return FarmCard(
      padding: const EdgeInsets.all(15),
      color: FarmColors.cardSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Export and share',
            style: TextStyle(
              color: FarmColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Copy clean CSV or a manager-ready sales summary.',
            style: TextStyle(
              color: FarmColors.mutedText,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.article_outlined),
                label: const Text('Summary'),
                onPressed: () => _showReportDialog(
                  context: context,
                  title: 'Business Summary',
                  content: report,
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copy summary'),
                onPressed: () => _copyText(context, report),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('CSV'),
                onPressed: () => _showReportDialog(
                  context: context,
                  title: 'CSV Export',
                  content: csv,
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.file_copy_outlined),
                label: const Text('Copy CSV'),
                onPressed: () => _copyText(context, csv),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recentOrderRow(AdminOrder order) {
    final paid = order.paymentStatus == 'paid';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: paid ? FarmColors.lightGreen : FarmColors.warningSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              paid ? Icons.check_rounded : Icons.schedule_rounded,
              color: paid ? FarmColors.green : FarmColors.warning,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${order.shortId} • ${order.customerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 13.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.formattedType} • ${order.formattedPaymentStatus}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 11.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            order.formattedTotal,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 12.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdminOrder>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SkeletonList(count: 4, height: 104);
        }

        final allOrders = snapshot.data ?? <AdminOrder>[];
        final orders = _filteredOrders(allOrders);
        final paidOrders =
            orders.where((order) => order.paymentStatus == 'paid').toList();
        final unpaidOrders =
            orders.where((order) => order.paymentStatus != 'paid').toList();
        final deliveryOrders = orders
            .where((order) => order.fulfillmentType == 'delivery')
            .toList();
        final pickupOrders = orders
            .where((order) => order.fulfillmentType != 'delivery')
            .toList();
        final revenue =
            paidOrders.fold<double>(0, (sum, order) => sum + order.total);
        final openBalance =
            unpaidOrders.fold<double>(0, (sum, order) => sum + order.total);
        final averageOrder = orders.isEmpty
            ? 0.0
            : orders.fold<double>(0, (sum, order) => sum + order.total) /
                orders.length;
        final totalDiscount =
            orders.fold<double>(0, (sum, order) => sum + order.discountAmount);
        final deliveryFees =
            orders.fold<double>(0, (sum, order) => sum + order.deliveryFee);
        final statusCounts = _countByStatus(orders);
        final paymentMethodCounts = _countByPaymentMethod(orders);
        final topProducts = _topProducts(orders);

        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            children: [
              const Header(
                title: 'Reports',
                subtitle: 'Sales clarity for smarter farm decisions',
              ),
              const SizedBox(height: 14),
              _rangeSelector(),
              const SizedBox(height: 14),
              _hero(
                orders: orders,
                revenue: revenue,
                openBalance: openBalance,
                averageOrder: averageOrder,
              ),
              const SizedBox(height: 18),
              _sectionHeader(
                  'Financial snapshot', 'Quick numbers for this range'),
              _metricGrid([
                _metricCard(
                  title: 'Paid revenue',
                  value: _money(revenue),
                  icon: Icons.payments_rounded,
                  note: '${paidOrders.length} paid',
                ),
                _metricCard(
                  title: 'Open balance',
                  value: _money(openBalance),
                  icon: Icons.pending_actions_rounded,
                  color: openBalance > 0 ? FarmColors.gold : FarmColors.green,
                  note: '${unpaidOrders.length} open',
                ),
                _metricCard(
                  title: 'Average order',
                  value: _money(averageOrder),
                  icon: Icons.trending_up_rounded,
                ),
                _metricCard(
                  title: 'Discounts given',
                  value: _money(totalDiscount),
                  icon: Icons.local_offer_rounded,
                  color: FarmColors.gold,
                ),
                _metricCard(
                  title: 'Delivery fees',
                  value: _money(deliveryFees),
                  icon: Icons.local_shipping_rounded,
                ),
                _metricCard(
                  title: 'Orders reviewed',
                  value: '${orders.length}',
                  icon: Icons.receipt_long_rounded,
                ),
              ]),
              const SizedBox(height: 18),
              _exportPanel(orders),
              const SizedBox(height: 18),
              _sectionHeader('Order mix', 'How customers are buying'),
              _breakdownCard(
                title: 'Fulfillment split',
                subtitle: 'Pickup compared with delivery demand',
                icon: Icons.route_rounded,
                children: [
                  _breakdownRow(
                    title: 'Farm Pickup',
                    value: '${pickupOrders.length}',
                    icon: Icons.storefront_rounded,
                  ),
                  _breakdownRow(
                    title: 'Home Delivery',
                    value: '${deliveryOrders.length}',
                    icon: Icons.local_shipping_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _breakdownCard(
                title: 'Payment methods',
                subtitle: 'Payment preferences from recent orders',
                icon: Icons.payments_rounded,
                children: paymentMethodCounts.entries
                    .map(
                      (entry) => _breakdownRow(
                        title: formatPaymentMethod(entry.key),
                        value: '${entry.value}',
                        icon: Icons.credit_card_rounded,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              _breakdownCard(
                title: 'Order status',
                subtitle: 'Operational status across this report range',
                icon: Icons.checklist_rounded,
                children: statusCounts.entries
                    .map(
                      (entry) => _breakdownRow(
                        title: _friendlyStatus(entry.key),
                        value: '${entry.value}',
                        icon: Icons.circle,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
              _sectionHeader(
                  'Product intelligence', 'What customers are choosing'),
              _breakdownCard(
                title: 'Top products',
                subtitle: 'Use this to plan harvest and stock',
                icon: Icons.local_fire_department_rounded,
                children: topProducts
                    .take(6)
                    .map(
                      (entry) => _breakdownRow(
                        title: entry.key,
                        value: '${entry.value} sold',
                        icon: Icons.eco_rounded,
                      ),
                    )
                    .toList(),
                emptyText: 'No product sales yet.',
              ),
              const SizedBox(height: 14),
              _breakdownCard(
                title: 'Recent orders',
                subtitle: 'Latest report entries for quick review',
                icon: Icons.history_rounded,
                children: orders.take(5).map(_recentOrderRow).toList(),
                emptyText: 'No orders in this range yet.',
              ),
            ],
          ),
        );
      },
    );
  }
}

class AdminAppHealthSnapshot {
  final int score;
  final int liveProducts;
  final int imageReadyProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final int activeOrders;
  final int openSupportTickets;
  final int heroSlidesReady;
  final List<AdminHealthCheck> customerChecks;
  final List<AdminHealthCheck> operationsChecks;
  final List<AdminHealthCheck> launchChecks;

  const AdminAppHealthSnapshot({
    required this.score,
    required this.liveProducts,
    required this.imageReadyProducts,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.activeOrders,
    required this.openSupportTickets,
    required this.heroSlidesReady,
    required this.customerChecks,
    required this.operationsChecks,
    required this.launchChecks,
  });
}

class AdminHealthCheck {
  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final bool ready;

  const AdminHealthCheck({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
    required this.ready,
  });
}

Future<AdminAppHealthSnapshot> buildAdminAppHealthSnapshot() async {
  await requireAdminAccess();

  List<Product> products = const <Product>[];
  List<AdminOrder> orders = const <AdminOrder>[];
  List<HomeHeroSlide> heroSlides = const <HomeHeroSlide>[];
  List<SupportTicket> supportTickets = const <SupportTicket>[];

  try {
    products = await fetchAllProducts();
  } catch (error) {
    farmDebugLog('Health products check skipped: $error');
  }

  try {
    orders = await fetchAdminOrders();
  } catch (error) {
    farmDebugLog('Health orders check skipped: $error');
  }

  try {
    heroSlides = await fetchAdminHomeHeroSlides();
  } catch (error) {
    farmDebugLog('Health hero check skipped: $error');
  }

  try {
    supportTickets = await fetchAdminSupportTickets();
  } catch (error) {
    farmDebugLog('Health support check skipped: $error');
  }

  final liveProducts = products.where((p) => p.isCustomerVisible).length;
  final imageReadyProducts = products
      .where(
          (p) => p.isCustomerVisible && cleanHostedImageUrl(p.imageUrl) != null)
      .length;
  final lowStockProducts = products.where((p) => p.isLowStock).length;
  final outOfStockProducts = products.where((p) => p.isOutOfStock).length;
  final activeOrders = orders
      .where((order) => !{
            'completed',
            'delivered',
            'cancelled',
            'rejected',
          }.contains(order.status.trim().toLowerCase()))
      .length;
  final openSupportTickets = supportTickets
      .where((ticket) =>
          !{'closed', 'resolved'}.contains(ticket.status.trim().toLowerCase()))
      .length;
  final heroSlidesReady = heroSlides
      .where((slide) => cleanHostedImageUrl(slide.imageUrl) != null)
      .take(3)
      .length;

  AdminHealthCheck ready({
    required String title,
    required String detail,
    required IconData icon,
  }) {
    return AdminHealthCheck(
      title: title,
      detail: detail,
      icon: icon,
      color: FarmColors.green,
      ready: true,
    );
  }

  AdminHealthCheck review({
    required String title,
    required String detail,
    required IconData icon,
  }) {
    return AdminHealthCheck(
      title: title,
      detail: detail,
      icon: icon,
      color: FarmColors.warning,
      ready: false,
    );
  }

  final customerChecks = <AdminHealthCheck>[
    liveProducts > 0
        ? ready(
            title: 'Shop has live products',
            detail: '$liveProducts customer-visible items are ready to browse.',
            icon: Icons.storefront_outlined,
          )
        : review(
            title: 'No live products',
            detail: 'Add at least one approved visible product before launch.',
            icon: Icons.storefront_outlined,
          ),
    imageReadyProducts >= (liveProducts * 0.70).ceil() || liveProducts <= 2
        ? ready(
            title: 'Product images look ready',
            detail:
                '$imageReadyProducts of $liveProducts visible products have images.',
            icon: Icons.image_outlined,
          )
        : review(
            title: 'Improve image coverage',
            detail:
                '$imageReadyProducts of $liveProducts visible products have images. Aim for 70%+.',
            icon: Icons.image_outlined,
          ),
    heroSlidesReady >= 3
        ? ready(
            title: 'Hero slideshow ready',
            detail: 'All 3 home hero slides have valid images.',
            icon: Icons.photo_library_outlined,
          )
        : review(
            title: 'Hero slideshow needs review',
            detail: '$heroSlidesReady of 3 hero slides have valid images.',
            icon: Icons.photo_library_outlined,
          ),
  ];

  final operationsChecks = <AdminHealthCheck>[
    activeOrders == 0
        ? ready(
            title: 'No active orders waiting',
            detail: 'Fulfillment is clear right now.',
            icon: Icons.task_alt_outlined,
          )
        : review(
            title: '$activeOrders active orders',
            detail:
                'Review fulfillment before going public or closing the day.',
            icon: Icons.local_shipping_outlined,
          ),
    lowStockProducts == 0
        ? ready(
            title: 'No low-stock warnings',
            detail: 'Inventory does not have urgent low-stock flags.',
            icon: Icons.inventory_2_outlined,
          )
        : review(
            title: '$lowStockProducts low-stock products',
            detail: 'Restock or let them sell through intentionally.',
            icon: Icons.inventory_2_outlined,
          ),
    openSupportTickets == 0
        ? ready(
            title: 'Support inbox clear',
            detail: 'No open customer support tickets need attention.',
            icon: Icons.support_agent_outlined,
          )
        : review(
            title: '$openSupportTickets support tickets',
            detail: 'Reply before launch-day promotion if possible.',
            icon: Icons.support_agent_outlined,
          ),
  ];

  final launchChecks = <AdminHealthCheck>[
    outOfStockProducts <= liveProducts
        ? ready(
            title: 'Out-of-stock display protected',
            detail:
                '$outOfStockProducts unavailable items can show without checkout risk.',
            icon: Icons.block_outlined,
          )
        : review(
            title: 'Review stock visibility',
            detail: 'Some products need visibility and stock review.',
            icon: Icons.block_outlined,
          ),
    ready(
      title: 'Checkout stock recheck active',
      detail: 'Products are verified again before order placement.',
      icon: Icons.verified_user_outlined,
    ),
    ready(
      title: 'Admin gate active',
      detail:
          'Admin screens still verify protected access before loading tools.',
      icon: Icons.admin_panel_settings_outlined,
    ),
  ];

  final allChecks = [...customerChecks, ...operationsChecks, ...launchChecks];
  final readyCount = allChecks.where((check) => check.ready).length;
  final score = allChecks.isEmpty
      ? 0
      : ((readyCount / allChecks.length) * 100).round().clamp(0, 100).toInt();

  return AdminAppHealthSnapshot(
    score: score,
    liveProducts: liveProducts,
    imageReadyProducts: imageReadyProducts,
    lowStockProducts: lowStockProducts,
    outOfStockProducts: outOfStockProducts,
    activeOrders: activeOrders,
    openSupportTickets: openSupportTickets,
    heroSlidesReady: heroSlidesReady,
    customerChecks: customerChecks,
    operationsChecks: operationsChecks,
    launchChecks: launchChecks,
  );
}

class AdminAppHealthTab extends StatefulWidget {
  final int refreshKey;

  const AdminAppHealthTab({super.key, required this.refreshKey});

  @override
  State<AdminAppHealthTab> createState() => _AdminAppHealthTabState();
}

class _AdminAppHealthTabState extends State<AdminAppHealthTab> {
  late Future<AdminAppHealthSnapshot> snapshotFuture;

  @override
  void initState() {
    super.initState();
    snapshotFuture = buildAdminAppHealthSnapshot();
  }

  @override
  void didUpdateWidget(covariant AdminAppHealthTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) {
      snapshotFuture = buildAdminAppHealthSnapshot();
    }
  }

  Future<void> refresh() async {
    final future = buildAdminAppHealthSnapshot();
    setState(() {
      snapshotFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminAppHealthSnapshot>(
      future: snapshotFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, __) => const FarmSkeletonCard(height: 118),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            children: [
              FarmEmptyState(
                icon: Icons.health_and_safety_outlined,
                title: 'Health check unavailable',
                message:
                    'Pull down to try again. If it continues, confirm your protected access and Supabase connection.',
                actionLabel: 'Retry',
                onAction: refresh,
              ),
            ],
          );
        }

        final data = snapshot.data!;

        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            children: [
              SectionHeader(
                title: 'App Health Center',
                subtitle: 'A quick operating check before launch-day traffic.',
                actionLabel: 'Refresh',
                onAction: refresh,
              ),
              const SizedBox(height: 14),
              _AdminHealthHero(snapshot: data),
              const SizedBox(height: 14),
              _AdminHealthMetricGrid(snapshot: data),
              const SizedBox(height: 18),
              _AdminHealthSection(
                title: 'Customer experience',
                checks: data.customerChecks,
              ),
              const SizedBox(height: 14),
              _AdminHealthSection(
                title: 'Operations readiness',
                checks: data.operationsChecks,
              ),
              const SizedBox(height: 14),
              _AdminHealthSection(
                title: 'Launch guardrails',
                checks: data.launchChecks,
              ),
              const SizedBox(height: 18),
              const _AdminHealthPlaybookCard(),
            ],
          ),
        );
      },
    );
  }
}

class _AdminHealthHero extends StatelessWidget {
  final AdminAppHealthSnapshot snapshot;

  const _AdminHealthHero({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final isExcellent = snapshot.score >= 90;
    final title =
        isExcellent ? 'Operating beautifully' : 'A few items need review';
    final message = isExcellent
        ? 'Your storefront, operations, and launch guardrails are in strong shape.'
        : 'Review the yellow items below to make the app feel smoother before promoting it.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
            color: FarmColors.green.withOpacity(0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Center(
              child: Text(
                '${snapshot.score}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
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
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.86),
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
}

class _AdminHealthMetricGrid extends StatelessWidget {
  final AdminAppHealthSnapshot snapshot;

  const _AdminHealthMetricGrid({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _AdminHealthMetric('Live products', snapshot.liveProducts.toString(),
          Icons.storefront_outlined),
      _AdminHealthMetric('Images ready', '${snapshot.imageReadyProducts}',
          Icons.image_outlined),
      _AdminHealthMetric('Active orders', '${snapshot.activeOrders}',
          Icons.local_shipping_outlined),
      _AdminHealthMetric('Support open', '${snapshot.openSupportTickets}',
          Icons.support_agent_outlined),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.62,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) =>
          _AdminHealthMetricCard(metric: metrics[index]),
    );
  }
}

class _AdminHealthMetric {
  final String label;
  final String value;
  final IconData icon;

  const _AdminHealthMetric(this.label, this.value, this.icon);
}

class _AdminHealthMetricCard extends StatelessWidget {
  final _AdminHealthMetric metric;

  const _AdminHealthMetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: FarmColors.lightGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(metric.icon, color: FarmColors.green, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 12,
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
}

class _AdminHealthSection extends StatelessWidget {
  final String title;
  final List<AdminHealthCheck> checks;

  const _AdminHealthSection({required this.title, required this.checks});

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
          ),
        ),
        const SizedBox(height: 10),
        ...checks.map(
          (check) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AdminHealthCheckTile(check: check),
          ),
        ),
      ],
    );
  }
}

class _AdminHealthCheckTile extends StatelessWidget {
  final AdminHealthCheck check;

  const _AdminHealthCheckTile({required this.check});

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: const EdgeInsets.all(14),
      color: check.ready ? Colors.white : FarmColors.warningSoft,
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: check.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(check.icon, color: check.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.title,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  check.detail,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            check.ready ? Icons.check_circle : Icons.info_outline,
            color: check.color,
          ),
        ],
      ),
    );
  }
}

class _AdminHealthPlaybookCard extends StatelessWidget {
  const _AdminHealthPlaybookCard();

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, color: FarmColors.gold),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Daily elite habit',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Before sharing the app link each day: review active orders, check low stock, and confirm one customer-facing action on your phone.',
            style: TextStyle(
              color: FarmColors.mutedText,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminLaunchChecklistTab extends StatefulWidget {
  final int refreshKey;
  final VoidCallback onChanged;

  const AdminLaunchChecklistTab({
    super.key,
    required this.refreshKey,
    required this.onChanged,
  });

  @override
  State<AdminLaunchChecklistTab> createState() =>
      _AdminLaunchChecklistTabState();
}

class _AdminLaunchChecklistTabState extends State<AdminLaunchChecklistTab> {
  int localRefreshKey = 0;

  void refreshChecklist() {
    setState(() => localRefreshKey++);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LaunchChecklistSnapshot>(
      key: ValueKey('${widget.refreshKey}-$localRefreshKey'),
      future: buildLaunchChecklistSnapshot(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonList(count: 4, height: 128);
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
            children: [
              const Header(
                title: 'Launch Checklist',
                subtitle: 'Final readiness before real customers',
              ),
              const SizedBox(height: 14),
              FarmCard(
                color: FarmColors.dangerSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Could not load launch checks',
                      style: TextStyle(
                        color: FarmColors.danger,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      friendlyAppError(snapshot.error ?? 'Unknown error'),
                      style: const TextStyle(color: FarmColors.danger),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: refreshChecklist,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        final data = snapshot.data!;
        final percent = (data.readinessScore * 100).round();
        final scoreColor = data.actionCount > 0
            ? FarmColors.warning
            : percent >= 90
                ? FarmColors.success
                : FarmColors.warning;

        return RefreshIndicator(
          onRefresh: () async => refreshChecklist(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
            children: [
              const Header(
                title: 'Launch Checklist',
                subtitle: 'Final readiness before real customers',
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [FarmColors.deepGreen, FarmColors.green],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: FarmColors.green.withOpacity(0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 74,
                          width: 74,
                          child: CircularProgressIndicator(
                            value: data.readinessScore,
                            strokeWidth: 8,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          '$percent%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Launch readiness',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            data.actionCount == 0
                                ? 'You are close. Review the yellow items, then complete one final phone check.'
                                : '${data.actionCount} item${data.actionCount == 1 ? '' : 's'} need action before sharing widely.',
                            style: const TextStyle(
                              color: Colors.white,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _LaunchMetricChip(
                    label: 'Ready',
                    value: '${data.readyCount}',
                    color: FarmColors.success,
                  ),
                  _LaunchMetricChip(
                    label: 'Review',
                    value: '${data.reviewCount}',
                    color: FarmColors.warning,
                  ),
                  _LaunchMetricChip(
                    label: 'Action',
                    value: '${data.actionCount}',
                    color: FarmColors.danger,
                  ),
                  _LaunchMetricChip(
                    label: 'Products',
                    value: '${data.activeProductCount}',
                    color: FarmColors.green,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...data.checks.map(
                (check) => LaunchCheckTile(check: check),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: refreshChecklist,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh checklist'),
              ),
              const SizedBox(height: 14),
              const LaunchPlaybookSection(),
            ],
          ),
        );
      },
    );
  }
}

class AdminHeroSlidesTab extends StatefulWidget {
  final int refreshKey;
  final VoidCallback onChanged;

  const AdminHeroSlidesTab({
    super.key,
    required this.refreshKey,
    required this.onChanged,
  });

  @override
  State<AdminHeroSlidesTab> createState() => _AdminHeroSlidesTabState();
}

class _AdminHeroSlidesTabState extends State<AdminHeroSlidesTab> {
  int localRefreshKey = 0;
  final Map<int, bool> uploading = <int, bool>{};

  void refreshSlides() {
    setState(() => localRefreshKey++);
    widget.onChanged();
  }

  Future<void> uploadSlideImage(int position) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final pickedImage = await pickProductImageFromDevice();
      if (pickedImage == null) return;

      setState(() => uploading[position] = true);

      final imageUrl = await uploadHomeHeroImageToStorage(
        position: position,
        image: pickedImage,
      );
      await saveHomeHeroSlideImage(position: position, imageUrl: imageUrl);

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Hero slide $position uploaded.')),
      );
      refreshSlides();
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(friendlyAppError(error)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => uploading[position] = false);
      }
    }
  }

  Widget slideCard(HomeHeroSlide slide) {
    final isUploading = uploading[slide.position] == true;
    final cleanUrl = cleanHostedImageUrl(slide.imageUrl);

    return FarmCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Home hero slide ${slide.position}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Chip(
                label: Text(slide.isActive ? 'Active' : 'Inactive'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 128,
              width: double.infinity,
              color: FarmColors.primarySoft,
              child: cleanUrl == null
                  ? const Center(
                      child: Icon(
                        Icons.photo_outlined,
                        color: FarmColors.mutedText,
                        size: 42,
                      ),
                    )
                  : Image.network(
                      cleanUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: FarmColors.mutedText,
                          size: 42,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Upload a wide image for the home screen banner. A 3:1 or 4:1 crop works best.',
            style: TextStyle(
              color: FarmColors.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: isUploading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_outlined),
                  label: Text(
                      isUploading ? 'Uploading...' : 'Upload from computer'),
                  onPressed: isUploading
                      ? null
                      : () => uploadSlideImage(slide.position),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HomeHeroSlide>>(
      key: ValueKey('${widget.refreshKey}-$localRefreshKey'),
      future: fetchAdminHomeHeroSlides(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SkeletonList();
        }

        final slides = snapshot.data ?? defaultHomeHeroSlides();

        return RefreshIndicator(
          onRefresh: () async => refreshSlides(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            children: [
              FarmCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Home Hero Slideshow',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Upload 3 banner images from your computer. Customers will see them rotate automatically on the home screen.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ...slides.map((slide) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: slideCard(slide),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class AdminOrdersTab extends StatefulWidget {
  final int refreshKey;
  final VoidCallback onChanged;

  const AdminOrdersTab({
    super.key,
    required this.refreshKey,
    required this.onChanged,
  });

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  Future<Uint8List> buildOrderSlipPdf(AdminOrder order) async {
    final pdf = pw.Document();

    final labelFormat = PdfPageFormat(
      4 * PdfPageFormat.inch,
      6 * PdfPageFormat.inch,
      marginAll: 0.16 * PdfPageFormat.inch,
    );

    final isDelivery = order.fulfillmentType == 'delivery';

    final customerName = cleanText(order.customerName);
    final customerPhone = cleanText(order.customerPhone);

    final deliveryAddress = (order.deliveryAddress ?? '').trim().isNotEmpty
        ? (order.deliveryAddress ?? '').trim()
        : (order.customerAddress ?? '').trim();

    final itemLines = order.items.map((item) {
      return '${item.productName} x${item.quantity}';
    }).toList();
    String safePdfText(String value) {
      return value
          .replaceAll('•', '-')
          .replaceAll('×', 'x')
          .replaceAll('–', '-')
          .replaceAll('—', '-')
          .replaceAll('’', "'")
          .replaceAll('“', '"')
          .replaceAll('”', '"');
    }

    pw.Widget sectionTitle(String text) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey200,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
    }

    pw.Widget infoRow(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 62,
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget statusBox(String label, String value) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 7),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey500, width: 0.8),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label.toUpperCase(),
              style: const pw.TextStyle(
                fontSize: 6.5,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: labelFormat,
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'THE HARVEST PLACE JA',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Center(
                  child: pw.Text(
                    'Fresh - Local - Jamaican',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.SizedBox(height: 7),
                pw.Container(height: 1.2, color: PdfColors.black),
                pw.SizedBox(height: 8),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'ORDER #${order.shortId}',
                            style: pw.TextStyle(
                              fontSize: 17,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            safePdfText(orderDateLabel(order)),
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 8,
                      ),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.black, width: 1),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        order.formattedPaymentStatus.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: statusBox('Fulfillment', order.formattedType),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Expanded(
                      child: statusBox('Total', money(order.total)),
                    ),
                  ],
                ),
                pw.SizedBox(height: 9),
                sectionTitle('CUSTOMER DETAILS'),
                pw.SizedBox(height: 5),
                infoRow('Name', customerName),
                infoRow('Phone', customerPhone),
                pw.SizedBox(height: 7),
                sectionTitle(
                    isDelivery ? 'DELIVERY DETAILS' : 'PICKUP DETAILS'),
                pw.SizedBox(height: 5),
                if (isDelivery) ...[
                  infoRow('Zone', cleanText(order.deliveryZone)),
                  infoRow('Address', cleanText(deliveryAddress)),
                ] else ...[
                  infoRow('Method', 'Farm Pickup'),
                ],
                infoRow('Scheduled', safePdfText(scheduledLabel(order))),
                pw.SizedBox(height: 7),
                sectionTitle('ITEMS TO PACK'),
                pw.SizedBox(height: 5),
                if (itemLines.isEmpty)
                  pw.Text(
                    'No item details found.',
                    style: const pw.TextStyle(fontSize: 9),
                  )
                else
                  ...itemLines.map(
                    (line) => pw.Container(
                      width: double.infinity,
                      margin: const pw.EdgeInsets.only(bottom: 3),
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColors.grey300,
                          width: 0.7,
                        ),
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text(
                        '- $line',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                pw.Spacer(),
                pw.Container(height: 1, color: PdfColors.black),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    'Packing / Pickup / Delivery Label',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Center(
                  child: pw.Text(
                    'Attach to customer box, bag, or delivery package.',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> printOrderSlip(BuildContext context, AdminOrder order) async {
    try {
      await Printing.layoutPdf(
        name: 'HPJ_Order_${order.shortId}.pdf',
        format: PdfPageFormat(
          4 * PdfPageFormat.inch,
          6 * PdfPageFormat.inch,
        ),
        onLayout: (_) => buildOrderSlipPdf(order),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not print order slip: $error'),
        ),
      );
    }
  }

  Future<void> shareOrderSlip(BuildContext context, AdminOrder order) async {
    try {
      final bytes = await buildOrderSlipPdf(order);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'HPJ_Order_${order.shortId}.pdf',
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not share order slip: $error'),
        ),
      );
    }
  }

  void openOrderSlipActions(BuildContext context, AdminOrder order) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              runSpacing: 10,
              children: [
                ListTile(
                  leading: const Icon(Icons.print_outlined),
                  title: const Text('Print 4×6 Order Slip'),
                  subtitle:
                      const Text('Use the Android print option or MUNBYN app.'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    printOrderSlip(context, order);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.ios_share_outlined),
                  title: const Text('Share 4×6 PDF'),
                  subtitle: const Text(
                      'Send to MUNBYN app, WhatsApp, email, or files.'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    shareOrderSlip(context, order);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String selectedFilter = 'all';
  String orderSearchQuery = '';

  static const statuses = [
    'pending',
    'preparing',
    'ready',
    'out_for_delivery',
    'delivered',
    'cancelled',
  ];

  static const paymentStatuses = [
    'unpaid',
    'paid',
    'refunded',
  ];

  String formatStatus(String status) {
    return status
        .trim()
        .split('_')
        .map((part) =>
            part.isEmpty ? part : part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  String money(double value) {
    return 'J\$${value.toStringAsFixed(0)}';
  }

  String cleanText(String? value, {String fallback = 'Not provided'}) {
    final clean = value?.trim() ?? '';
    return clean.isEmpty ? fallback : clean;
  }

  String orderDateLabel(AdminOrder order) {
    final created = order.createdAt;
    if (created == null) return 'Date unavailable';
    return formatCustomerDateTime(created);
  }

  String scheduledLabel(AdminOrder order) {
    final parts = <String>[];

    final date = order.scheduledDate?.trim() ?? '';
    final time = order.scheduledTime?.trim() ?? '';

    if (date.isNotEmpty) parts.add(date);
    if (time.isNotEmpty) parts.add(time);

    if (parts.isEmpty) return 'Not scheduled';
    return parts.join(' • ');
  }

  Color statusColor(String value) {
    switch (value.trim().toLowerCase()) {
      case 'paid':
      case 'delivered':
      case 'completed':
        return FarmColors.success;
      case 'preparing':
      case 'ready':
      case 'out_for_delivery':
        return FarmColors.green;
      case 'pending':
      case 'unpaid':
        return FarmColors.warning;
      case 'cancelled':
      case 'refunded':
      case 'rejected':
        return FarmColors.danger;
      default:
        return FarmColors.mutedText;
    }
  }

  List<AdminOrder> applyFilter(List<AdminOrder> orders) {
    switch (selectedFilter) {
      case 'pending':
      case 'preparing':
      case 'ready':
      case 'out_for_delivery':
      case 'delivered':
      case 'cancelled':
        return orders.where((order) => order.status == selectedFilter).toList();
      case 'unpaid':
        return orders.where((order) => order.paymentStatus != 'paid').toList();
      case 'paid':
        return orders.where((order) => order.paymentStatus == 'paid').toList();
      case 'refunded':
        return orders
            .where((order) => order.paymentStatus == 'refunded')
            .toList();
      default:
        return orders;
    }
  }

  List<AdminOrder> applySearch(List<AdminOrder> orders) {
    final query = orderSearchQuery.trim().toLowerCase();
    if (query.isEmpty) return orders;

    return orders.where((order) {
      final itemText = order.items
          .map((item) => '${item.productName} ${item.quantity}')
          .join(' ')
          .toLowerCase();

      final searchable = [
        order.id,
        order.shortId,
        order.customerName,
        order.customerPhone,
        order.customerAddress,
        order.deliveryAddress,
        order.deliveryZone,
        order.status,
        order.paymentStatus,
        order.paymentMethod,
        order.fulfillmentType,
        order.formattedType,
        order.formattedPaymentMethod,
        order.formattedPaymentStatus,
        orderDateLabel(order),
        scheduledLabel(order),
        itemText,
      ].join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList();
  }

  Future<void> changeOrderStatus(
      BuildContext context, AdminOrder order, String status) async {
    try {
      await updateOrderStatus(order.id, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order updated to ${formatStatus(status)}')),
        );
      }
      widget.onChanged();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update order: $error')),
        );
      }
    }
  }

  Future<void> changePaymentStatus(
      BuildContext context, AdminOrder order, String status) async {
    try {
      await updatePaymentStatus(order.id, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment marked ${formatStatus(status)}')),
        );
      }
      widget.onChanged();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update payment: $error')),
        );
      }
    }
  }

  Widget summaryTile(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: FarmColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: FarmColors.green),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: FarmColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget statusBadge(String label, String value, {IconData? icon}) {
    final color = statusColor(value);
    return Chip(
      avatar: icon == null ? null : Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
      backgroundColor: color.withOpacity(0.10),
      side: BorderSide(color: color.withOpacity(0.20)),
    );
  }

  Widget infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: FarmColors.green),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: FarmColors.ink,
                  fontSize: 13.5,
                  height: 1.25,
                ),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> captureOrderBoxPhoto(
      BuildContext context, AdminOrder order) async {
    try {
      final picker = ImagePicker();

      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (picked == null) {
        return;
      }

      final bytes = await picked.readAsBytes();

      final cleanOrderId = order.id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$cleanOrderId/$fileName';

      await supabase.storage.from('order-box-photos').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl =
          supabase.storage.from('order-box-photos').getPublicUrl(path);

      final updatedOrder = await supabase
          .from('orders')
          .update({
            'box_photo_url': publicUrl,
            'box_photo_uploaded_at': DateTime.now().toIso8601String(),
            'box_photo_uploaded_by': supabase.auth.currentUser?.id,
          })
          .eq('id', order.id)
          .select('id, box_photo_url')
          .maybeSingle();

      if (!context.mounted) return;

      final savedUrl = updatedOrder?['box_photo_url']?.toString();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedUrl == null || savedUrl.isEmpty
                ? 'Photo uploaded, but order was not updated.'
                : 'Box photo saved to order.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Box photo failed: $error'),
        ),
      );
    }
  }

  Widget orderCard(AdminOrder order) {
    final isDelivery = order.fulfillmentType == 'delivery';
    final deliveryAddress = (order.deliveryAddress ?? '').trim().isNotEmpty
        ? (order.deliveryAddress ?? '').trim()
        : (order.customerAddress ?? '').trim();

    final itemSummary = order.items.isEmpty
        ? 'No item details found.'
        : order.items
            .map((item) => '${item.productName} x${item.quantity}')
            .join(' • ');

    return FarmCard(
      padding: const EdgeInsets.all(16),
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
                      'Order #${order.shortId}',
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      orderDateLabel(order),
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              statusBadge(
                formatStatus(order.status),
                order.status,
                icon: Icons.receipt_long_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              statusBadge(
                order.formattedPaymentStatus,
                order.paymentStatus,
                icon: Icons.payments_outlined,
              ),
              statusBadge(
                order.formattedType,
                order.fulfillmentType,
                icon: isDelivery
                    ? Icons.local_shipping_outlined
                    : Icons.storefront_outlined,
              ),
              statusBadge(
                money(order.total),
                'paid',
                icon: Icons.attach_money_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FarmColors.cardSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: FarmColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoRow(
                  icon: Icons.person_outline,
                  title: 'Customer',
                  value: cleanText(order.customerName),
                ),
                infoRow(
                  icon: Icons.phone_outlined,
                  title: 'Phone',
                  value: cleanText(order.customerPhone),
                ),
                infoRow(
                  icon: Icons.payment_outlined,
                  title: 'Payment',
                  value:
                      '${order.formattedPaymentMethod} • ${order.formattedPaymentStatus}',
                ),
                if (order.paymentMethod == 'bank_transfer' &&
                    (order.bankReference ?? '').trim().isNotEmpty)
                  infoRow(
                    icon: Icons.account_balance_outlined,
                    title: 'Bank ref',
                    value: order.bankReference!.trim(),
                  ),
                infoRow(
                  icon: isDelivery
                      ? Icons.local_shipping_outlined
                      : Icons.storefront_outlined,
                  title: 'Fulfillment',
                  value: order.formattedType,
                ),
                if (isDelivery)
                  infoRow(
                    icon: Icons.map_outlined,
                    title: 'Zone',
                    value: cleanText(order.deliveryZone),
                  ),
                if (isDelivery)
                  infoRow(
                    icon: Icons.location_on_outlined,
                    title: 'Address',
                    value: cleanText(deliveryAddress),
                  ),
                infoRow(
                  icon: Icons.schedule_outlined,
                  title: 'Scheduled',
                  value: scheduledLabel(order),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Items',
            style: TextStyle(
              color: FarmColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            itemSummary,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${item.productName} x${item.quantity} — J\$${item.lineTotal.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Column(
            children: [
              DropdownButtonFormField<String>(
                value:
                    statuses.contains(order.status) ? order.status : 'pending',
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Order status',
                ),
                items: statuses
                    .map(
                      (status) => DropdownMenuItem<String>(
                        value: status,
                        child: Text(
                          formatStatus(status),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null || value == order.status) return;
                  changeOrderStatus(context, order, value);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: paymentStatuses.contains(order.paymentStatus)
                    ? order.paymentStatus
                    : 'unpaid',
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Payment',
                ),
                items: paymentStatuses
                    .map(
                      (status) => DropdownMenuItem<String>(
                        value: status,
                        child: Text(
                          formatStatus(status),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null || value == order.paymentStatus) return;
                  changePaymentStatus(context, order, value);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.print_outlined),
                label: const Text('Print 4×6 Order Slip'),
                onPressed: () => openOrderSlipActions(context, order),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Take Box Photo'),
                onPressed: () => captureOrderBoxPhoto(context, order),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.message_outlined),
                label: const Text('Message Customer'),
                onPressed: () => openOrderMessageSheet(context, order),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> openOrderMessageSheet(
    BuildContext context,
    AdminOrder order,
  ) async {
    final controller = TextEditingController();
    var sending = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> sendMessage() async {
              final message = controller.text.trim();

              if (message.isEmpty) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a message for the customer.'),
                  ),
                );
                return;
              }

              setSheetState(() => sending = true);

              try {
                await supabase.from('order_messages').insert({
                  'order_id': order.id,
                  'message': message,
                  'message_type': 'update',
                  'sender_role': 'manager',
                });

                if (Navigator.canPop(sheetContext)) {
                  Navigator.pop(sheetContext);
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message sent to customer.'),
                  ),
                );
              } catch (error) {
                setSheetState(() => sending = false);

                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(
                    content: Text('Could not send message: $error'),
                  ),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Message Customer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send an update for order #${order.shortId}.',
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      hintText: 'Example: Your order is being prepared.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(sending ? 'Sending...' : 'Send Message'),
                      onPressed: sending ? null : sendMessage,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    controller.dispose();
  }

  Widget filterChip(String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selectedFilter == value,
        label: Text(label),
        onSelected: (_) => setState(() => selectedFilter = value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdminOrder>>(
      key: ValueKey(widget.refreshKey),
      future: fetchAdminOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SkeletonList();
        }

        final orders = snapshot.data ?? [];
        final filteredOrders = applySearch(applyFilter(orders));
        final paidCount =
            orders.where((order) => order.paymentStatus == 'paid').length;
        final unpaidCount =
            orders.where((order) => order.paymentStatus != 'paid').length;
        final totalSales = orders
            .where((order) => order.paymentStatus == 'paid')
            .fold<double>(0, (sum, order) => sum + order.total);

        if (orders.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(18),
            child: FarmCard(
              child: Text(
                'No orders yet. When customers place orders, they will appear here.',
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
          children: [
            FarmCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Orders Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      summaryTile(
                        'Orders',
                        '${orders.length}',
                        Icons.receipt_long,
                      ),
                      const SizedBox(width: 8),
                      summaryTile(
                        'Unpaid',
                        '$unpaidCount',
                        Icons.pending_actions,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      summaryTile(
                        'Paid',
                        '$paidCount',
                        Icons.verified,
                      ),
                      const SizedBox(width: 8),
                      summaryTile(
                        'Paid Sales',
                        money(totalSales),
                        Icons.payments,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search orders',
                hintText: 'Name, phone, order ID, zone, item...',
              ),
              onChanged: (value) {
                setState(() {
                  orderSearchQuery = value;
                });
              },
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  filterChip('all', 'All'),
                  filterChip('pending', 'Pending'),
                  filterChip('preparing', 'Preparing'),
                  filterChip('ready', 'Ready'),
                  filterChip('out_for_delivery', 'Out for Delivery'),
                  filterChip('delivered', 'Delivered'),
                  filterChip('unpaid', 'Unpaid'),
                  filterChip('paid', 'Paid'),
                  filterChip('refunded', 'Refunded'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '${filteredOrders.length} matching order${filteredOrders.length == 1 ? '' : 's'}',
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (filteredOrders.isEmpty)
              const FarmCard(
                child: Text(
                  'No orders match this search/filter. Try another name, phone number, order ID, zone, item, or status.',
                ),
              )
            else
              ...filteredOrders.map(
                (order) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: orderCard(order),
                ),
              ),
          ],
        );
      },
    );
  }
}

class AdminAnalyticsTab extends StatelessWidget {
  final int refreshKey;

  const AdminAnalyticsTab({super.key, required this.refreshKey});

  String formatMoney(double value) => 'J\$${value.toStringAsFixed(2)}';

  Color _attentionColor(int count) {
    if (count <= 0) return FarmColors.green;
    if (count <= 3) return FarmColors.gold;
    return FarmColors.danger;
  }

  Widget _metricGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardWidth = width < 390 ? (width - 10) / 2 : (width - 20) / 3;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: children
              .map((child) => SizedBox(width: cardWidth, child: child))
              .toList(),
        );
      },
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    Color? color,
    String? note,
  }) {
    final activeColor = color ?? FarmColors.green;

    return FarmCard(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        height: 116,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: activeColor.withOpacity(0.11),
                    shape: BoxShape.circle,
                    border: Border.all(color: activeColor.withOpacity(0.16)),
                  ),
                  child: Icon(icon, color: activeColor, size: 20),
                ),
                const Spacer(),
                if (note != null && note.trim().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: activeColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: activeColor,
                        fontSize: 10.4,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.ink,
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.35,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 11.5,
                height: 1.16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryHero({
    required double totalSales,
    required int orderCount,
    required int attentionCount,
  }) {
    final color = _attentionColor(attentionCount);
    final readyText = attentionCount == 0
        ? 'Operations look smooth today.'
        : '$attentionCount item${attentionCount == 1 ? '' : 's'} need review.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FarmColors.deepGreen,
            FarmColors.green,
            FarmColors.green.withOpacity(0.88),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: FarmColors.green.withOpacity(0.18),
            blurRadius: 22,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s command view',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatMoney(totalSales),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$orderCount orders tracked • $readyText',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.86),
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.22)),
                ),
                child: Icon(
                  attentionCount == 0
                      ? Icons.verified_rounded
                      : Icons.priority_high_rounded,
                  color: attentionCount == 0 ? Colors.white : color,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _heroMiniStat('Revenue', formatMoney(totalSales)),
              const SizedBox(width: 10),
              _heroMiniStat('Orders', '$orderCount'),
              const SizedBox(width: 10),
              _heroMiniStat('Review', '$attentionCount'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMiniStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.16)),
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
                color: Colors.white.withOpacity(0.76),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attentionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required int count,
    Color? color,
  }) {
    final activeColor = color ?? _attentionColor(count);
    final isReady = count <= 0;

    return FarmCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      color: isReady ? Colors.white : activeColor.withOpacity(0.055),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: activeColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: activeColor, size: 19),
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
                    fontSize: 13.6,
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
                    fontSize: 11.5,
                    height: 1.2,
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
              color: isReady
                  ? FarmColors.primarySoft
                  : activeColor.withOpacity(0.13),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isReady ? 'Ready' : '$count',
              style: TextStyle(
                color: isReady ? FarmColors.green : activeColor,
                fontSize: 11.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.25,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 12.4,
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

  Widget _insightListCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
    required IconData icon,
    Color color = FarmColors.green,
    String emptyText = 'Nothing to show yet.',
  }) {
    return FarmCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.11),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 10),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 11.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                emptyText,
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ...children,
        ],
      ),
    );
  }

  Widget _productInsightRow(Product product, String trailingText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ProductVisual(product: product, size: 34),
          const SizedBox(width: 10),
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
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: FarmColors.warningSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              trailingText,
              style: const TextStyle(
                color: FarmColors.warning,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textInsightRow({
    required String title,
    required String value,
    IconData icon = Icons.trending_up_rounded,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: const BoxDecoration(
              color: FarmColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: FarmColors.green, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: FarmColors.green,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      key: ValueKey('analytics-$refreshKey'),
      future: Future.wait([
        fetchAdminOrders(),
        fetchAllProducts(),
        fetchFarmerProfiles(),
        fetchFarmerPayouts(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SkeletonList(count: 3, height: 108);
        }

        final orders = snapshot.data == null
            ? <AdminOrder>[]
            : List<AdminOrder>.from(snapshot.data![0] as List);
        final products = snapshot.data == null
            ? <Product>[]
            : List<Product>.from(snapshot.data![1] as List);
        final farmers = snapshot.data == null
            ? <FarmerProfile>[]
            : List<FarmerProfile>.from(snapshot.data![2] as List);
        final payouts = snapshot.data == null
            ? <FarmerPayout>[]
            : List<FarmerPayout>.from(snapshot.data![3] as List);

        final paidOrders =
            orders.where((order) => order.paymentStatus == 'paid').toList();
        final pendingOrders =
            orders.where((order) => order.status == 'pending').toList();
        final preparingOrders =
            orders.where((order) => order.status == 'preparing').toList();
        final unpaidOrders =
            orders.where((order) => order.paymentStatus != 'paid').toList();
        final totalSales =
            paidOrders.fold<double>(0, (sum, order) => sum + order.total);
        final unpaidAmount =
            unpaidOrders.fold<double>(0, (sum, order) => sum + order.total);
        final avgOrder = orders.isEmpty
            ? 0.0
            : orders.fold<double>(0, (sum, order) => sum + order.total) /
                orders.length;
        final lowStock = products
            .where((product) =>
                product.isCustomerVisible &&
                product.isAvailable &&
                product.stockQuantity <= 5)
            .toList();
        final outOfStock =
            products.where((product) => product.isOutOfStock).toList();
        final pendingProducts = products
            .where((product) => product.approvalStatus == 'pending')
            .toList();
        final activeProducts =
            products.where((product) => product.canAddToCart).length;
        final approvedFarmers = farmers
            .where((farmer) => farmer.verificationStatus == 'approved')
            .length;
        final pendingFarmers = farmers
            .where((farmer) => farmer.verificationStatus == 'pending')
            .length;
        final pendingPayouts = payouts
            .where((payout) => payout.payoutStatus == 'pending')
            .toList();
        final payoutAmount = pendingPayouts.fold<double>(
            0, (sum, payout) => sum + payout.netAmount);

        final itemSales = <String, int>{};
        for (final order in orders) {
          for (final item in order.items) {
            itemSales[item.productName] =
                (itemSales[item.productName] ?? 0) + item.quantity;
          }
        }

        final bestSellers = itemSales.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final attentionCount = pendingOrders.length +
            lowStock.length +
            pendingProducts.length +
            pendingFarmers +
            pendingPayouts.length;

        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const Header(
                title: 'Business dashboard',
                subtitle: 'A clean view of sales, stock and farm operations',
              ),
              const SizedBox(height: 14),
              _summaryHero(
                totalSales: totalSales,
                orderCount: orders.length,
                attentionCount: attentionCount,
              ),
              const SizedBox(height: 18),
              _sectionHeader('At a glance', 'The numbers that matter most'),
              _metricGrid([
                _metricCard(
                  title: 'Paid revenue',
                  value: formatMoney(totalSales),
                  icon: Icons.payments_rounded,
                  note: 'Paid',
                ),
                _metricCard(
                  title: 'Orders',
                  value: '${orders.length}',
                  icon: Icons.receipt_long_rounded,
                  note: '${pendingOrders.length} pending',
                ),
                _metricCard(
                  title: 'Average order',
                  value: formatMoney(avgOrder),
                  icon: Icons.trending_up_rounded,
                ),
                _metricCard(
                  title: 'Unpaid balance',
                  value: formatMoney(unpaidAmount),
                  icon: Icons.pending_actions_rounded,
                  color: FarmColors.gold,
                  note: '${unpaidOrders.length}',
                ),
                _metricCard(
                  title: 'Active products',
                  value: '$activeProducts',
                  icon: Icons.storefront_rounded,
                ),
                _metricCard(
                  title: 'Payouts due',
                  value: formatMoney(payoutAmount),
                  icon: Icons.account_balance_wallet_rounded,
                  color: payoutAmount > 0 ? FarmColors.gold : FarmColors.green,
                ),
              ]),
              const SizedBox(height: 18),
              _sectionHeader(
                  'Needs attention', 'Quick checks before customers notice'),
              _attentionTile(
                title: 'Pending orders',
                subtitle: pendingOrders.isEmpty
                    ? 'No waiting orders right now.'
                    : 'Review and move orders into preparation.',
                icon: Icons.hourglass_top_rounded,
                count: pendingOrders.length,
              ),
              const SizedBox(height: 10),
              _attentionTile(
                title: 'Low stock',
                subtitle: lowStock.isEmpty
                    ? 'Stock levels look healthy.'
                    : 'Restock or mark items clearly before checkout.',
                icon: Icons.inventory_2_rounded,
                count: lowStock.length,
                color: FarmColors.gold,
              ),
              const SizedBox(height: 10),
              _attentionTile(
                title: 'Product approvals',
                subtitle: pendingProducts.isEmpty
                    ? 'No products waiting for approval.'
                    : 'Approve ready items or request changes.',
                icon: Icons.approval_rounded,
                count: pendingProducts.length,
                color: FarmColors.gold,
              ),
              const SizedBox(height: 10),
              _attentionTile(
                title: 'Farmer payouts',
                subtitle: pendingPayouts.isEmpty
                    ? 'No payout action needed.'
                    : 'Confirm pending payout records.',
                icon: Icons.account_balance_rounded,
                count: pendingPayouts.length,
                color: FarmColors.gold,
              ),
              const SizedBox(height: 18),
              _insightListCard(
                title: 'Stock watch',
                subtitle: 'Items customers may need clarity on',
                icon: Icons.warning_amber_rounded,
                color: FarmColors.gold,
                children: [
                  ...lowStock.take(4).map(
                        (product) => _productInsightRow(
                          product,
                          '${product.stockQuantity} left',
                        ),
                      ),
                  ...outOfStock.take(lowStock.isEmpty ? 4 : 2).map(
                        (product) => _productInsightRow(
                          product,
                          'Out',
                        ),
                      ),
                ],
                emptyText: 'No low-stock or out-of-stock items needing review.',
              ),
              const SizedBox(height: 14),
              _insightListCard(
                title: 'Best sellers',
                subtitle: 'Use this to plan harvest and restock',
                icon: Icons.local_fire_department_rounded,
                color: FarmColors.green,
                children: bestSellers
                    .take(5)
                    .map(
                      (entry) => _textInsightRow(
                        title: entry.key,
                        value: '${entry.value} sold',
                      ),
                    )
                    .toList(),
                emptyText: 'No sales data yet.',
              ),
              const SizedBox(height: 14),
              _insightListCard(
                title: 'Farm network',
                subtitle: 'Farmer and product approvals',
                icon: Icons.agriculture_rounded,
                color: FarmColors.green,
                children: [
                  _textInsightRow(
                    title: 'Approved farmers',
                    value: '$approvedFarmers',
                    icon: Icons.verified_user_rounded,
                  ),
                  _textInsightRow(
                    title: 'Pending farmers',
                    value: '$pendingFarmers',
                    icon: Icons.person_search_rounded,
                  ),
                  _textInsightRow(
                    title: 'Pending products',
                    value: '${pendingProducts.length}',
                    icon: Icons.inventory_rounded,
                  ),
                  _textInsightRow(
                    title: 'Preparing orders',
                    value: '${preparingOrders.length}',
                    icon: Icons.restaurant_menu_rounded,
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

class AdminDeliveryTab extends StatelessWidget {
  final int refreshKey;
  final VoidCallback onChanged;

  const AdminDeliveryTab({
    super.key,
    required this.refreshKey,
    required this.onChanged,
  });

  static const deliveryStatuses = [
    'pending',
    'preparing',
    'ready_for_pickup',
    'out_for_delivery',
    'delivered',
  ];

  bool _isDone(AdminOrder order) {
    final status = order.status.trim().toLowerCase();
    final delivery = (order.deliveryStatus ?? '').trim().toLowerCase();
    return status == 'cancelled' ||
        status == 'completed' ||
        status == 'delivered' ||
        delivery == 'delivered';
  }

  String _currentStatus(AdminOrder order) {
    final raw = (order.deliveryStatus ?? '').trim();
    if (deliveryStatuses.contains(raw)) return raw;
    if (order.fulfillmentType == 'delivery') return 'pending';
    return 'ready_for_pickup';
  }

  int _stageIndex(String status, bool isDelivery) {
    final steps = isDelivery
        ? const ['pending', 'preparing', 'out_for_delivery', 'delivered']
        : const ['pending', 'preparing', 'ready_for_pickup', 'delivered'];
    final index = steps.indexOf(status);
    return index < 0 ? 0 : index;
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'delivered':
      case 'completed':
        return FarmColors.success;
      case 'out_for_delivery':
      case 'ready_for_pickup':
        return FarmColors.green;
      case 'preparing':
        return FarmColors.warning;
      default:
        return FarmColors.mutedText;
    }
  }

  Future<void> _setStatus(AdminOrder order, String status) async {
    await updateDeliveryStatus(order.id, status);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdminOrder>>(
      key: ValueKey('delivery-$refreshKey'),
      future: fetchAdminOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SkeletonList();
        }

        final allOrders = (snapshot.data ?? []).toList();
        final activeOrders = allOrders
            .where((order) => !_isDone(order))
            .toList()
          ..sort((a, b) {
            final statusCompare =
                _stageIndex(_currentStatus(a), a.fulfillmentType == 'delivery')
                    .compareTo(_stageIndex(
                        _currentStatus(b), b.fulfillmentType == 'delivery'));
            if (statusCompare != 0) return statusCompare;
            return (b.createdAt ?? DateTime(2000))
                .compareTo(a.createdAt ?? DateTime(2000));
          });
        final completedOrders = allOrders.where(_isDone).take(4).toList();
        final deliveryOrders = activeOrders
            .where((order) => order.fulfillmentType == 'delivery')
            .toList();
        final pickupOrders = activeOrders
            .where((order) => order.fulfillmentType != 'delivery')
            .toList();
        final preparingOrders = activeOrders
            .where((order) => _currentStatus(order) == 'preparing')
            .toList();
        final readyOrders = activeOrders.where((order) {
          final status = _currentStatus(order);
          return status == 'ready_for_pickup' || status == 'out_for_delivery';
        }).toList();

        return RefreshIndicator(
          onRefresh: () async => onChanged(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Header(
                      title: 'Fulfillment',
                      subtitle:
                          'Prepare pickups and deliveries with confidence',
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Refresh',
                    onPressed: onChanged,
                    icon: const Icon(Icons.restart_alt_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FutureBuilder<String>(
                future: fetchCurrentStaffRole(),
                builder: (context, staffSnapshot) {
                  final currentStaffRole =
                      normalizeStaffRole(staffSnapshot.data);
                  if (!staffRoleCanManageBusinessSettings(currentStaffRole)) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AdminDeliveryZonesManager(
                      key: ValueKey('delivery-zones-$refreshKey'),
                      onChanged: onChanged,
                    ),
                  );
                },
              ),
              const SizedBox(height: 0),
              FarmCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 46,
                          width: 46,
                          decoration: BoxDecoration(
                            color: FarmColors.primarySoft,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.route_rounded,
                            color: FarmColors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeOrders.isEmpty
                                    ? 'All clear for now'
                                    : '${activeOrders.length} active orders',
                                style: const TextStyle(
                                  color: FarmColors.ink,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                activeOrders.isEmpty
                                    ? 'New pickups and deliveries will appear here.'
                                    : 'Prioritize pending, preparing, and ready orders.',
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
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _FulfillmentMetricPill(
                          label: 'Delivery',
                          value: '${deliveryOrders.length}',
                          icon: Icons.local_shipping_outlined,
                        ),
                        _FulfillmentMetricPill(
                          label: 'Pickup',
                          value: '${pickupOrders.length}',
                          icon: Icons.storefront_outlined,
                        ),
                        _FulfillmentMetricPill(
                          label: 'Preparing',
                          value: '${preparingOrders.length}',
                          icon: Icons.restaurant_menu_rounded,
                        ),
                        _FulfillmentMetricPill(
                          label: 'Ready',
                          value: '${readyOrders.length}',
                          icon: Icons.done_outline_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _FulfillmentSectionHeader(
                title: 'Active workflow',
                subtitle: 'Tap a stage to update the customer order status',
              ),
              const SizedBox(height: 10),
              if (activeOrders.isEmpty)
                const FarmEmptyState(
                  icon: Icons.task_alt_rounded,
                  title: 'No active fulfillment tasks',
                  message:
                      'When a customer places an order, pickup and delivery steps will show here.',
                )
              else
                ...activeOrders.map(
                  (order) => _FulfillmentOrderCard(
                    order: order,
                    status: _currentStatus(order),
                    statusColor: _statusColor(_currentStatus(order)),
                    onPreparing: () => _setStatus(order, 'preparing'),
                    onReady: () => _setStatus(
                      order,
                      order.fulfillmentType == 'delivery'
                          ? 'out_for_delivery'
                          : 'ready_for_pickup',
                    ),
                    onComplete: () => _setStatus(order, 'delivered'),
                    onStatusChanged: (status) => _setStatus(order, status),
                  ),
                ),
              if (completedOrders.isNotEmpty) ...[
                const SizedBox(height: 18),
                const _FulfillmentSectionHeader(
                  title: 'Recently completed',
                  subtitle: 'Latest fulfilled orders for quick reference',
                ),
                const SizedBox(height: 10),
                ...completedOrders.map(
                  (order) => _CompletedFulfillmentTile(order: order),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class AdminDeliveryZonesManager extends StatefulWidget {
  final VoidCallback onChanged;

  const AdminDeliveryZonesManager({
    super.key,
    required this.onChanged,
  });

  @override
  State<AdminDeliveryZonesManager> createState() =>
      _AdminDeliveryZonesManagerState();
}

class _AdminDeliveryZonesManagerState extends State<AdminDeliveryZonesManager> {
  late Future<List<DeliveryZone>> zonesFuture;
  bool seeding = false;

  @override
  void initState() {
    super.initState();
    zonesFuture = fetchAdminDeliveryZones();
  }

  void _reload() {
    setState(() {
      zonesFuture = fetchAdminDeliveryZones();
    });
    widget.onChanged();
  }

  Future<void> _seedDefaults() async {
    if (seeding) return;
    setState(() => seeding = true);

    try {
      await seedDefaultDeliveryZones();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery parishes loaded.')),
      );
      _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load delivery parishes: ${friendlyAppError(error)}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => seeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: const EdgeInsets.all(18),
      child: FutureBuilder<List<DeliveryZone>>(
        future: zonesFuture,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData;
          final zones = _cleanDeliveryZones(snapshot.data ?? const []);
          final activeCount = zones.where((zone) => zone.isActive).length;
          final loadError =
              snapshot.hasError ? friendlyAppError(snapshot.error!) : '';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: FarmColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.map_outlined,
                      color: FarmColors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Areas',
                          style: TextStyle(
                            color: FarmColors.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$activeCount active parish${activeCount == 1 ? '' : 'es'}. Choose where customers can request Home Delivery and set the fee.',
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
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: seeding
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.playlist_add_check_rounded),
                      label: Text(
                        seeding ? 'Loading...' : 'Load Jamaica parishes',
                      ),
                      onPressed: seeding ? null : _seedDefaults,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    tooltip: 'Refresh delivery areas',
                    onPressed: loading ? null : _reload,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (loading)
                const SkeletonList(count: 3)
              else if (loadError.isNotEmpty)
                FarmEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Delivery areas could not load',
                  message:
                      '$loadError\n\nCheck that the delivery_zones table exists, then tap refresh.',
                )
              else if (zones.isEmpty)
                const FarmEmptyState(
                  icon: Icons.local_shipping_outlined,
                  title: 'No delivery parishes yet',
                  message:
                      'Run the Supabase SQL setup, then load the Jamaica parishes here.',
                )
              else
                ...zones.map(
                  (zone) => _AdminDeliveryZoneTile(
                    key: ValueKey('delivery-zone-${zone.id}-${zone.updatedAt}'),
                    zone: zone,
                    onChanged: _reload,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminDeliveryZoneTile extends StatefulWidget {
  final DeliveryZone zone;
  final VoidCallback onChanged;

  const _AdminDeliveryZoneTile({
    super.key,
    required this.zone,
    required this.onChanged,
  });

  @override
  State<_AdminDeliveryZoneTile> createState() => _AdminDeliveryZoneTileState();
}

class _AdminDeliveryZoneTileState extends State<_AdminDeliveryZoneTile> {
  late final TextEditingController feeController;
  late bool active;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    feeController = TextEditingController(
      text: widget.zone.deliveryFee.toStringAsFixed(0),
    );
    active = widget.zone.isActive;
  }

  @override
  void dispose() {
    feeController.dispose();
    super.dispose();
  }

  double _parseFee() {
    final clean =
        feeController.text.replaceAll('J\$', '').replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  Future<void> _save() async {
    if (saving) return;
    setState(() => saving = true);

    try {
      await upsertDeliveryZone(
        id: widget.zone.id,
        parish: widget.zone.parish,
        zoneName: widget.zone.zoneName,
        deliveryFee: _parseFee(),
        isActive: active,
        sortOrder: widget.zone.sortOrder,
        notes: widget.zone.notes,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.zone.displayName} updated.')),
      );
      widget.onChanged();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Could not save delivery area: ${friendlyAppError(error)}'),
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? FarmColors.lightGreen : FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? FarmColors.green.withOpacity(0.22) : FarmColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? FarmColors.green.withOpacity(0.12)
                      : FarmColors.mutedText.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  active
                      ? Icons.local_shipping_outlined
                      : Icons.visibility_off_outlined,
                  color: active ? FarmColors.green : FarmColors.mutedText,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.zone.displayName,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      active ? 'Visible at checkout' : 'Hidden from customers',
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: active,
                onChanged: (value) => setState(() => active = value),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: feeController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Delivery fee (JMD)',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(saving ? 'Saving' : 'Save'),
                onPressed: saving ? null : _save,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const List<String> _adminNutritionBadgeOptions = <String>[
  'Magnesium',
  'Iron',
  'Fiber',
  'Potassium',
  'Vitamin C',
  'Protein',
  'Calcium',
  'Antioxidants',
];

List<String> _cleanAdminNutritionBadges(Iterable<String> values) {
  final normalized = <String>{};
  final cleaned = <String>[];

  for (final option in _adminNutritionBadgeOptions) {
    final match = values.any(
      (value) => value.trim().toLowerCase() == option.toLowerCase(),
    );
    if (match && normalized.add(option.toLowerCase())) {
      cleaned.add(option);
    }
  }

  for (final value in values) {
    final clean = value.trim();
    if (clean.isEmpty) continue;
    if (normalized.add(clean.toLowerCase())) cleaned.add(clean);
  }

  return cleaned;
}

Future<void> updateAdminProductNutritionBadges({
  required String productId,
  required Iterable<String> nutrientStrong,
  required Iterable<String> nutrientGood,
  required Iterable<String> nutrientContains,
  required bool nutritionVerified,
  String? nutritionNote,
}) async {
  await requireAdminAccess();

  final cleanNote = (nutritionNote ?? '').trim();
  final payload = <String, dynamic>{
    'nutrient_strong': _cleanAdminNutritionBadges(nutrientStrong),
    'nutrient_good': _cleanAdminNutritionBadges(nutrientGood),
    'nutrient_contains': _cleanAdminNutritionBadges(nutrientContains),
    'nutrition_verified': nutritionVerified,
  };

  if (cleanNote.isNotEmpty) {
    payload['nutrition_notes'] = cleanNote;
  }

  await supabase.from('products').update(payload).eq('id', productId);
}

class AdminProductsTab extends StatefulWidget {
  final int refreshKey;
  final VoidCallback onChanged;

  const AdminProductsTab({
    super.key,
    required this.refreshKey,
    required this.onChanged,
  });

  @override
  State<AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<AdminProductsTab> {
  int localRefreshKey = 0;
  final TextEditingController inventorySearchController =
      TextEditingController();
  String inventoryQuery = '';
  String inventoryFilter = 'needs_attention';
  String inventorySort = 'priority';

  @override
  void dispose() {
    inventorySearchController.dispose();
    super.dispose();
  }

  void refreshProducts() {
    setState(() => localRefreshKey++);
    widget.onChanged();
  }

  String shortDescription(Product product) {
    final description = (product.description ?? '').trim();
    return description.isEmpty
        ? 'Fresh natural harvest from the farm.'
        : description;
  }

  Future<void> openProductEditor(BuildContext context,
      {Product? product}) async {
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(
      text: product == null ? '' : product.price.toStringAsFixed(2),
    );
    final stockController = TextEditingController(
      text: product == null ? '0' : product.stockQuantity.toString(),
    );
    final unitController = TextEditingController(text: product?.unit ?? 'each');
    final descriptionController =
        TextEditingController(text: product?.description ?? '');
    final imageUrlController =
        TextEditingController(text: product?.imageUrl ?? '');
    final originalPriceController = TextEditingController(
      text: product?.originalPrice == null
          ? ''
          : product!.originalPrice!.toStringAsFixed(2),
    );
    final discountPriceController = TextEditingController(
      text: product?.discountPrice == null
          ? ''
          : product!.discountPrice!.toStringAsFixed(2),
    );
    final discountPercentController = TextEditingController(
      text: product?.discountPercent == null
          ? ''
          : product!.discountPercent!.toStringAsFixed(0),
    );
    final discountLabelController =
        TextEditingController(text: product?.discountLabel ?? '');
    final estimatedReadyDateController = TextEditingController(
      text: product?.estimatedReadyDate == null
          ? ''
          : todayIsoDateFrom(product!.estimatedReadyDate!),
    );
    final expectedStockController = TextEditingController(
      text: product?.expectedStockQuantity == null
          ? ''
          : product!.expectedStockQuantity.toString(),
    );
    final dealRankController = TextEditingController(
      text: product == null ? '10' : product.dealRank.toString(),
    );

    String selectedCategory =
        normalizeProductCategory(product?.category ?? 'Vegetables');
    if (!productCategoryOptions.contains(selectedCategory) &&
        productCategoryOptions.isNotEmpty) {
      selectedCategory = productCategoryOptions.first;
    }

    String selectedProductStatus = product?.productStatus ?? 'available';
    const allowedStatuses = <String>[
      'available',
      'ready_soon',
      'out_of_stock',
      'hidden',
    ];
    if (!allowedStatuses.contains(selectedProductStatus)) {
      selectedProductStatus = 'available';
    }

    bool isOrganic = product?.isOrganic ?? false;
    bool isLocal = product?.isLocal ?? true;
    bool isAvailable = product?.isAvailable ?? true;
    bool isDiscountActive = product?.isDiscountActive ?? false;
    bool readySoon =
        product?.isReadySoon ?? selectedProductStatus == 'ready_soon';
    bool isDealOfDay = product?.isDealOfDay ?? false;
    final selectedStrongNutrients = <String>{
      ..._cleanAdminNutritionBadges(
          product?.nutrientStrong ?? const <String>[]),
    };
    final selectedGoodNutrients = <String>{
      ..._cleanAdminNutritionBadges(product?.nutrientGood ?? const <String>[]),
    };
    final selectedContainsNutrients = <String>{
      ..._cleanAdminNutritionBadges(
          product?.nutrientContains ?? const <String>[]),
    };
    final nutritionNoteController = TextEditingController();
    bool nutritionVerified = product?.nutritionVerified ?? false;
    bool saving = false;
    bool uploadingImage = false;

    Future<void> disposeControllers() async {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nameController.dispose();
        priceController.dispose();
        stockController.dispose();
        unitController.dispose();
        descriptionController.dispose();
        imageUrlController.dispose();
        originalPriceController.dispose();
        discountPriceController.dispose();
        discountPercentController.dispose();
        discountLabelController.dispose();
        estimatedReadyDateController.dispose();
        expectedStockController.dispose();
        dealRankController.dispose();
        nutritionNoteController.dispose();
      });
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> uploadImageFromComputer() async {
              try {
                setDialogState(() => uploadingImage = true);
                final pickedImage = await pickProductImageFromDevice();
                if (pickedImage == null) {
                  if (dialogContext.mounted) {
                    setDialogState(() => uploadingImage = false);
                  }
                  return;
                }

                final imageUrl = await uploadProductImageToStorage(pickedImage);
                imageUrlController.text = imageUrl;

                if (dialogContext.mounted) {
                  setDialogState(() => uploadingImage = false);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Product image uploaded.')),
                  );
                }
              } catch (error) {
                if (dialogContext.mounted) {
                  setDialogState(() => uploadingImage = false);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        error.toString().replaceFirst('Exception: ', ''),
                      ),
                    ),
                  );
                }
              }
            }

            Future<void> saveProduct() async {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text.trim());
              final stock = int.tryParse(stockController.text.trim()) ?? 0;
              final unit = unitController.text.trim();
              final description = descriptionController.text.trim();
              final imageUrl = imageUrlController.text.trim();
              final originalPrice =
                  double.tryParse(originalPriceController.text.trim());
              final discountPrice =
                  double.tryParse(discountPriceController.text.trim());
              final discountPercent =
                  double.tryParse(discountPercentController.text.trim());
              final discountLabel = discountLabelController.text.trim();
              final estimatedReadyDate =
                  estimatedReadyDateController.text.trim();
              final expectedStock =
                  int.tryParse(expectedStockController.text.trim());
              final dealRank = int.tryParse(dealRankController.text.trim());
              final status = readySoon ? 'ready_soon' : selectedProductStatus;

              if (name.isEmpty || price == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Enter product name and a valid price.'),
                  ),
                );
                return;
              }

              setDialogState(() => saving = true);

              try {
                if (product == null) {
                  await createProduct(
                    name: name,
                    price: price,
                    stockQuantity: stock,
                    isAvailable: isAvailable,
                    category: selectedCategory,
                    isOrganic: isOrganic,
                    isLocal: isLocal,
                    description: description.isEmpty ? null : description,
                    unit: unit.isEmpty ? null : unit,
                    imageUrl: imageUrl.isEmpty ? null : imageUrl,
                    isDiscountActive: isDiscountActive,
                    originalPrice: originalPrice,
                    discountPrice: discountPrice,
                    discountPercent: discountPercent,
                    discountLabel: discountLabel.isEmpty ? null : discountLabel,
                    discountStartsAt: null,
                    discountEndsAt: null,
                    productStatus: status,
                    readySoon: readySoon,
                    estimatedReadyDate:
                        estimatedReadyDate.isEmpty ? null : estimatedReadyDate,
                    expectedStockQuantity: expectedStock,
                    isDealOfDay: isDealOfDay,
                    dealRank: dealRank,
                    subscribeSaveEnabled:
                        product?.subscribeSaveEnabled ?? false,
                    subscribeSaveDiscountPercent:
                        product?.subscribeSaveDiscountPercent,
                    nutrientStrong: selectedStrongNutrients.toList(),
                    nutrientGood: selectedGoodNutrients.toList(),
                    nutrientContains: selectedContainsNutrients.toList(),
                    nutritionVerified: nutritionVerified,
                    nutritionNotes: nutritionNoteController.text.trim().isEmpty
                        ? null
                        : nutritionNoteController.text.trim(),
                  );
                } else {
                  await updateProductDetails(
                    productId: product.id,
                    name: name,
                    price: price,
                    stockQuantity: stock,
                    isAvailable: isAvailable,
                    category: selectedCategory,
                    isOrganic: isOrganic,
                    isLocal: isLocal,
                    description: description.isEmpty ? null : description,
                    unit: unit.isEmpty ? null : unit,
                    imageUrl: imageUrl.isEmpty ? null : imageUrl,
                    isDiscountActive: isDiscountActive,
                    originalPrice: originalPrice,
                    discountPrice: discountPrice,
                    discountPercent: discountPercent,
                    discountLabel: discountLabel.isEmpty ? null : discountLabel,
                    discountStartsAt: null,
                    discountEndsAt: null,
                    productStatus: status,
                    readySoon: readySoon,
                    estimatedReadyDate:
                        estimatedReadyDate.isEmpty ? null : estimatedReadyDate,
                    expectedStockQuantity: expectedStock,
                    isDealOfDay: isDealOfDay,
                    dealRank: dealRank,
                    subscribeSaveEnabled: product.subscribeSaveEnabled,
                    subscribeSaveDiscountPercent:
                        product.subscribeSaveDiscountPercent,
                  );

                  await updateAdminProductNutritionBadges(
                    productId: product.id,
                    nutrientStrong: selectedStrongNutrients,
                    nutrientGood: selectedGoodNutrients,
                    nutrientContains: selectedContainsNutrients,
                    nutritionVerified: nutritionVerified,
                    nutritionNote: nutritionNoteController.text,
                  );
                }

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }

                if (mounted) {
                  FarmDataCache.clearProducts();
                  refreshProducts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        product == null
                            ? 'Product added successfully.'
                            : 'Product updated successfully.',
                      ),
                    ),
                  );
                }
              } catch (error) {
                if (dialogContext.mounted) {
                  setDialogState(() => saving = false);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        error.toString().replaceFirst('Exception: ', ''),
                      ),
                    ),
                  );
                }
              }
            }

            Widget sectionTitle(String text) {
              return Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: FarmColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            }

            Widget productChoiceSelector({
              required String title,
              required String helper,
              required bool value,
              required String trueLabel,
              required String falseLabel,
              required IconData trueIcon,
              required IconData falseIcon,
              required ValueChanged<bool> onChanged,
            }) {
              Widget option({
                required bool optionValue,
                required String label,
                required IconData icon,
              }) {
                final selected = value == optionValue;
                final color =
                    optionValue ? FarmColors.green : FarmColors.warning;

                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: saving ? null : () => onChanged(optionValue),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? color.withOpacity(0.38)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 15,
                            color: selected ? color : FarmColors.mutedText,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selected ? color : FarmColors.mutedText,
                                fontWeight: FontWeight.w900,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: (value ? FarmColors.green : FarmColors.warning)
                              .withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          value ? trueLabel : falseLabel,
                          style: TextStyle(
                            color:
                                value ? FarmColors.green : FarmColors.warning,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    helper,
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: FarmColors.cardSoft,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: FarmColors.line),
                    ),
                    child: Row(
                      children: [
                        option(
                          optionValue: true,
                          label: trueLabel,
                          icon: trueIcon,
                        ),
                        option(
                          optionValue: false,
                          label: falseLabel,
                          icon: falseIcon,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            void setNutrientLevel(String nutrient, String level) {
              setDialogState(() {
                final wasStrong = selectedStrongNutrients.contains(nutrient);
                final wasGood = selectedGoodNutrients.contains(nutrient);
                final wasContains =
                    selectedContainsNutrients.contains(nutrient);

                selectedStrongNutrients.remove(nutrient);
                selectedGoodNutrients.remove(nutrient);
                selectedContainsNutrients.remove(nutrient);

                if (level == 'strong' && !wasStrong) {
                  selectedStrongNutrients.add(nutrient);
                } else if (level == 'good' && !wasGood) {
                  selectedGoodNutrients.add(nutrient);
                } else if (level == 'contains' && !wasContains) {
                  selectedContainsNutrients.add(nutrient);
                }
              });
            }

            Widget nutritionLevelGroup({
              required String title,
              required String helper,
              required String level,
              required Set<String> selectedValues,
              required Color color,
            }) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.055),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withOpacity(0.16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      helper,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        fontSize: 11.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: _adminNutritionBadgeOptions.map((nutrient) {
                        final selected = selectedValues.contains(nutrient);
                        return FilterChip(
                          selected: selected,
                          label: Text(nutrient),
                          onSelected: saving
                              ? null
                              : (_) => setNutrientLevel(nutrient, level),
                          selectedColor: color.withOpacity(0.16),
                          checkmarkColor: color,
                          backgroundColor: FarmColors.card,
                          labelStyle: TextStyle(
                            color: selected ? color : FarmColors.mutedText,
                            fontWeight: FontWeight.w900,
                            fontSize: 11.8,
                          ),
                          side: BorderSide(
                            color: selected
                                ? color.withOpacity(0.35)
                                : FarmColors.line,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }

            Widget nutritionPreview() {
              final badges = <String>[
                ...selectedStrongNutrients.map((item) => 'Strong $item'),
                ...selectedGoodNutrients.map((item) => 'Good $item'),
                ...selectedContainsNutrients.map((item) => 'Contains $item'),
              ];

              if (badges.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FarmColors.cardSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: FarmColors.line),
                  ),
                  child: const Text(
                    'No nutrient badges selected yet.',
                    style: TextStyle(
                      color: FarmColors.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }

              return Wrap(
                spacing: 7,
                runSpacing: 7,
                children: badges
                    .map(
                      (badge) => Chip(
                        avatar: const Icon(
                          Icons.health_and_safety_outlined,
                          size: 16,
                          color: FarmColors.green,
                        ),
                        label: Text(badge),
                        backgroundColor: FarmColors.primarySoft,
                        labelStyle: const TextStyle(
                          color: FarmColors.green,
                          fontWeight: FontWeight.w900,
                          fontSize: 11.5,
                        ),
                      ),
                    )
                    .toList(),
              );
            }

            Widget nutritionSaveLaterNotice() {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FarmColors.warning.withOpacity(0.075),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: FarmColors.warning.withOpacity(0.18)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: FarmColors.warning,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Save the product first, then edit it to add nutrition badges. This protects the normal add-product flow.',
                        style: TextStyle(
                          color: FarmColors.mutedText,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 18,
              ),
              titlePadding: const EdgeInsets.fromLTRB(18, 16, 8, 8),
              contentPadding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              actionsPadding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      product == null ? 'Add Product' : 'Edit Product',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed:
                        saving ? null : () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product != null) ...[
                        Row(
                          children: [
                            ProductVisual(product: product, size: 54),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      sectionTitle('Basic details'),
                      TextField(
                        controller: nameController,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Product name',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: priceController,
                              enabled: !saving,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Price',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: stockController,
                              enabled: !saving,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Stock',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration:
                            const InputDecoration(labelText: 'Category'),
                        items: productCategoryOptions
                            .map(
                              (category) => DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value == null) return;
                                setDialogState(() => selectedCategory = value);
                              },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedProductStatus,
                        decoration:
                            const InputDecoration(labelText: 'Product status'),
                        items: const [
                          DropdownMenuItem(
                            value: 'available',
                            child: Text('Available'),
                          ),
                          DropdownMenuItem(
                            value: 'ready_soon',
                            child: Text('Ready Soon'),
                          ),
                          DropdownMenuItem(
                            value: 'out_of_stock',
                            child: Text('Out of Stock'),
                          ),
                          DropdownMenuItem(
                            value: 'hidden',
                            child: Text('Hidden'),
                          ),
                        ],
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value == null) return;
                                setDialogState(() {
                                  selectedProductStatus = value;
                                  readySoon = value == 'ready_soon';
                                  if (value == 'hidden') isAvailable = false;
                                  if (readySoon) isAvailable = false;
                                });
                              },
                      ),
                      const SizedBox(height: 10),
                      LocalProductSelector(
                        value: isLocal,
                        enabled: !saving,
                        onChanged: (value) =>
                            setDialogState(() => isLocal = value),
                      ),
                      const SizedBox(height: 12),
                      productChoiceSelector(
                        title: 'Organic status',
                        helper:
                            'Use Organic only for items confirmed by the supplier or farm.',
                        value: isOrganic,
                        trueLabel: 'Organic',
                        falseLabel: 'Standard',
                        trueIcon: Icons.eco_outlined,
                        falseIcon: Icons.spa_outlined,
                        onChanged: (value) =>
                            setDialogState(() => isOrganic = value),
                      ),
                      sectionTitle('Nutrition badges'),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FarmColors.primarySoft.withOpacity(0.42),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: FarmColors.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Customer badge preview',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            nutritionPreview(),
                            const SizedBox(height: 10),
                            SwitchListTile(
                              value: nutritionVerified,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Nutrition verified'),
                              subtitle: const Text(
                                'Use only for simple food nutrient badges, not medical claims.',
                              ),
                              activeColor: FarmColors.green,
                              onChanged: saving
                                  ? null
                                  : (value) => setDialogState(
                                        () => nutritionVerified = value,
                                      ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      nutritionLevelGroup(
                        title: 'Strong source of',
                        helper: 'Use for the clearest nutrient strengths.',
                        level: 'strong',
                        selectedValues: selectedStrongNutrients,
                        color: FarmColors.green,
                      ),
                      nutritionLevelGroup(
                        title: 'Good source of',
                        helper: 'Use for helpful but less dominant nutrients.',
                        level: 'good',
                        selectedValues: selectedGoodNutrients,
                        color: FarmColors.primary,
                      ),
                      nutritionLevelGroup(
                        title: 'Contains',
                        helper:
                            'Use when the item contains the nutrient but should not be highlighted strongly.',
                        level: 'contains',
                        selectedValues: selectedContainsNutrients,
                        color: FarmColors.warning,
                      ),
                      TextField(
                        controller: nutritionNoteController,
                        enabled: !saving,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Nutrition note optional',
                          helperText: product == null
                              ? 'Optional note saved with the new product.'
                              : 'Leave blank to keep any existing note.',
                        ),
                      ),
                      sectionTitle('Options'),
                      SwitchListTile(
                        value: isAvailable,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Visible in shop'),
                        activeColor: FarmColors.green,
                        onChanged: saving
                            ? null
                            : (value) =>
                                setDialogState(() => isAvailable = value),
                      ),
                      SwitchListTile(
                        value: readySoon,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Ready soon'),
                        activeColor: FarmColors.warning,
                        onChanged: saving
                            ? null
                            : (value) {
                                setDialogState(() {
                                  readySoon = value;
                                  selectedProductStatus =
                                      value ? 'ready_soon' : 'available';
                                  if (value) isAvailable = false;
                                });
                              },
                      ),
                      SwitchListTile(
                        value: isDealOfDay,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Sale / deal'),
                        activeColor: FarmColors.warning,
                        onChanged: saving
                            ? null
                            : (value) =>
                                setDialogState(() => isDealOfDay = value),
                      ),
                      SwitchListTile(
                        value: isDiscountActive,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Discount active'),
                        activeColor: FarmColors.warning,
                        onChanged: saving
                            ? null
                            : (value) => setDialogState(
                                  () => isDiscountActive = value,
                                ),
                      ),
                      if (isDiscountActive || isDealOfDay) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: discountPercentController,
                                enabled: !saving,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Discount %',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: discountPriceController,
                                enabled: !saving,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Sale price',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: discountLabelController,
                          enabled: !saving,
                          decoration: const InputDecoration(
                            labelText: 'Sale label',
                            hintText: 'Fresh market special',
                          ),
                        ),
                      ],
                      if (readySoon) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: estimatedReadyDateController,
                                enabled: !saving,
                                decoration: const InputDecoration(
                                  labelText: 'Ready date',
                                  hintText: 'YYYY-MM-DD',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: expectedStockController,
                                enabled: !saving,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Expected stock',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      sectionTitle('Image and notes'),
                      TextField(
                        controller: imageUrlController,
                        enabled: !saving && !uploadingImage,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            icon: uploadingImage
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.upload_file),
                            label: Text(
                              uploadingImage ? 'Uploading...' : 'Upload image',
                            ),
                            onPressed: saving || uploadingImage
                                ? null
                                : uploadImageFromComputer,
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear image'),
                            onPressed: saving || uploadingImage
                                ? null
                                : () {
                                    imageUrlController.clear();
                                    setDialogState(() {});
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: unitController,
                        enabled: !saving,
                        decoration: const InputDecoration(labelText: 'Unit'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descriptionController,
                        enabled: !saving,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      saving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  icon: saving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(saving ? 'Saving...' : 'Save'),
                  onPressed: saving ? null : saveProduct,
                ),
              ],
            );
          },
        );
      },
    );

    await disposeControllers();
  }

  Future<void> openRestockDialog(BuildContext context, Product product) async {
    final amountController = TextEditingController(text: '10');

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Restock ${product.name}'),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount to add'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: FarmColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final amount = int.tryParse(amountController.text.trim()) ?? 0;
                if (amount <= 0) return;
                try {
                  await restockProduct(product.id, amount);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${product.name} restocked')),
                    );
                    refreshProducts();
                  }
                } catch (error) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not restock: $error')),
                    );
                  }
                }
              },
              child: const Text('Restock'),
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      amountController.dispose();
    });
  }

  Future<void> openReuseThisWeekDialog(
      BuildContext context, Product product) async {
    final stockController = TextEditingController(
      text: product.stockQuantity > 0 ? product.stockQuantity.toString() : '10',
    );

    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text('Reuse ${product.name} recently harvested'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This will move the item into Recently Harvested and make it visible in the shop.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: stockController,
                    enabled: !saving,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'New stock quantity',
                      helperText:
                          'Set how many are available recently harvested.',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  icon: saving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.event_repeat_outlined),
                  label: Text(saving ? 'Saving...' : 'Mark Recently Harvested'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FarmColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          final stock =
                              int.tryParse(stockController.text.trim()) ?? 0;
                          if (stock < 0) return;

                          setDialogState(() => saving = true);

                          try {
                            await reuseProductThisWeek(
                              productId: product.id,
                              stockQuantity: stock,
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${product.name} added to Recently Harvested',
                                  ),
                                ),
                              );
                              refreshProducts();
                            }
                          } catch (error) {
                            if (dialogContext.mounted) {
                              setDialogState(() => saving = false);
                            }

                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not reuse item. Please check permission and try again.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      stockController.dispose();
    });
  }

  Future<void> toggleAvailability(Product product) async {
    try {
      await updateProductAvailability(product.id, !product.isAvailable);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(product.isAvailable
                ? '${product.name} hidden from shop'
                : '${product.name} is visible in shop'),
          ),
        );
        refreshProducts();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update product: $error')),
        );
      }
    }
  }

  List<Product> _applyInventoryFilters(List<Product> products) {
    final query = inventoryQuery.trim().toLowerCase();
    final filtered = products.where((product) {
      final searchable = [
        product.name,
        product.category,
        product.unit ?? '',
        product.description ?? '',
        product.farmName ?? '',
        product.farmerName ?? '',
        product.parish ?? '',
        product.approvalStatus,
        product.productStatus,
      ].join(' ').toLowerCase();

      if (query.isNotEmpty && !searchable.contains(query)) {
        return false;
      }

      switch (inventoryFilter) {
        case 'needs_attention':
          return product.stockQuantity <= 5 ||
              product.isOutOfStock ||
              product.isHidden ||
              product.approvalStatus.trim().toLowerCase() != 'approved' ||
              product.isReadySoon;
        case 'in_stock':
          return product.canAddToCart;
        case 'low_stock':
          return product.isLowStock;
        case 'out_of_stock':
          return product.isOutOfStock || product.stockQuantity <= 0;
        case 'hidden':
          return product.isHidden || !product.isAvailable;
        case 'deals':
          return product.hasActiveDiscount || product.showAsDealOfDay;
        case 'organic':
          return product.isOrganic;
        default:
          return true;
      }
    }).toList();

    int priority(Product product) {
      var score = 0;
      if (product.approvalStatus.trim().toLowerCase() != 'approved')
        score -= 80;
      if (product.isOutOfStock || product.stockQuantity <= 0) score -= 60;
      if (product.isLowStock) score -= 40;
      if (product.isHidden || !product.isAvailable) score -= 30;
      if (product.isReadySoon) score -= 20;
      if (product.hasActiveDiscount || product.showAsDealOfDay) score += 12;
      if (isProductHarvestedThisWeek(product)) score += 8;
      return score;
    }

    switch (inventorySort) {
      case 'name':
        filtered.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'stock_low':
        filtered.sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
        break;
      case 'stock_high':
        filtered.sort((a, b) => b.stockQuantity.compareTo(a.stockQuantity));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        break;
      case 'newest':
        filtered.sort((a, b) {
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
        break;
      default:
        filtered.sort((a, b) => priority(a).compareTo(priority(b)));
    }

    return filtered;
  }

  String _inventoryStatusLabel(Product product) {
    if (product.approvalStatus.trim().toLowerCase() != 'approved') {
      return _friendlyStatus(product.approvalStatus);
    }
    if (product.isHidden || !product.isAvailable) return 'Hidden';
    if (product.isReadySoon) return 'Ready soon';
    if (product.isOutOfStock || product.stockQuantity <= 0)
      return 'Out of stock';
    if (product.isLowStock) return product.lowStockLabel;
    return 'Live';
  }

  Color _inventoryStatusColor(Product product) {
    if (product.approvalStatus.trim().toLowerCase() != 'approved') {
      return FarmColors.warning;
    }
    if (product.isHidden || !product.isAvailable) return FarmColors.mutedText;
    if (product.isReadySoon) return FarmColors.warning;
    if (product.isOutOfStock || product.stockQuantity <= 0)
      return FarmColors.danger;
    if (product.isLowStock) return FarmColors.warning;
    return FarmColors.success;
  }

  Widget _inventoryPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: icon == null
          ? null
          : Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : FarmColors.green,
            ),
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? Colors.white : FarmColors.ink,
        fontWeight: FontWeight.w900,
      ),
      selectedColor: FarmColors.primary,
      backgroundColor: FarmColors.card,
      side: BorderSide(
        color: selected ? FarmColors.primary : FarmColors.line,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }

  Widget _inventoryStatCard({
    required String label,
    required String value,
    required IconData icon,
    Color color = FarmColors.green,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.11),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.17)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.82),
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inventorySummaryCard(List<Product> products) {
    final live = products.where((product) => product.canAddToCart).length;
    final lowStock = products.where((product) => product.isLowStock).length;
    final outOfStock = products
        .where((product) => product.isOutOfStock || product.stockQuantity <= 0)
        .length;
    final hidden = products
        .where((product) => product.isHidden || !product.isAvailable)
        .length;
    final review = products
        .where((product) =>
            product.approvalStatus.trim().toLowerCase() != 'approved')
        .length;
    final needsAttention = lowStock + outOfStock + hidden + review;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FarmColors.primaryDark, FarmColors.primary],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: FarmColors.shadow.withOpacity(0.13),
            blurRadius: 22,
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
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(18),
                ),
                child:
                    const Icon(Icons.inventory_2_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inventory command center',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      needsAttention == 0
                          ? 'All products look ready for customers.'
                          : '$needsAttention item${needsAttention == 1 ? '' : 's'} need attention before peak shopping.',
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
          const SizedBox(height: 16),
          Row(
            children: [
              _inventoryStatCard(
                label: 'Live',
                value: '$live',
                icon: Icons.storefront_outlined,
              ),
              const SizedBox(width: 10),
              _inventoryStatCard(
                label: 'Low',
                value: '$lowStock',
                icon: Icons.local_fire_department_outlined,
              ),
              const SizedBox(width: 10),
              _inventoryStatCard(
                label: 'Out',
                value: '$outOfStock',
                icon: Icons.remove_shopping_cart_outlined,
              ),
              const SizedBox(width: 10),
              _inventoryStatCard(
                label: 'Hidden',
                value: '$hidden',
                icon: Icons.visibility_off_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _productOpsCard(Product product) {
    final statusColor = _inventoryStatusColor(product);
    final unit = (product.unit ?? '').trim();
    final farm = (product.farmName ?? product.farmerName ?? '').trim();

    return FarmCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ProductVisual(product: product, size: 58),
                  if (product.showAsDealOfDay || product.hasActiveDiscount)
                    Positioned(
                      right: -4,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: FarmColors.warning,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Deal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.11),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: statusColor.withOpacity(0.22)),
                          ),
                          child: Text(
                            _inventoryStatusLabel(product),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      farm.isEmpty ? shortDescription(product) : farm,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _MiniInfoPill(
                          label: product.formattedEffectivePrice,
                          icon: Icons.sell_outlined,
                          color: FarmColors.green,
                        ),
                        _MiniInfoPill(
                          label: '${product.stockQuantity} in stock',
                          icon: Icons.inventory_2_outlined,
                          color: product.stockQuantity <= 0
                              ? FarmColors.danger
                              : product.isLowStock
                                  ? FarmColors.warning
                                  : FarmColors.green,
                        ),
                        _MiniInfoPill(
                          label: product.category,
                          icon: Icons.category_outlined,
                          color: FarmColors.mutedText,
                        ),
                        if (unit.isNotEmpty)
                          _MiniInfoPill(
                            label: unit,
                            icon: Icons.straighten_outlined,
                            color: FarmColors.mutedText,
                          ),
                        _MiniInfoPill(
                          label: product.originLabel,
                          icon: productOriginIcon(product),
                          color: productOriginColor(product),
                        ),
                        if (product.isOrganic)
                          const _MiniInfoPill(
                            label: 'Organic',
                            icon: Icons.eco_outlined,
                            color: FarmColors.green,
                          ),
                        if (product.nutrientStrong.isNotEmpty ||
                            product.nutrientGood.isNotEmpty ||
                            product.nutrientContains.isNotEmpty)
                          _MiniInfoPill(
                            label: product.nutritionVerified
                                ? 'Nutrition verified'
                                : 'Nutrition tags',
                            icon: Icons.health_and_safety_outlined,
                            color: product.nutritionVerified
                                ? FarmColors.green
                                : FarmColors.warning,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FarmColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => openProductEditor(context, product: product),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Restock'),
                onPressed: () => openRestockDialog(context, product),
              ),
              OutlinedButton.icon(
                icon: Icon(product.isAvailable
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                label: Text(product.isAvailable ? 'Hide' : 'Show'),
                onPressed: () => toggleAvailability(product),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.event_repeat_outlined),
                label: const Text('Harvested'),
                onPressed: () => openReuseThisWeekDialog(context, product),
              ),
              if (product.approvalStatus != 'approved')
                OutlinedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Approve'),
                  onPressed: () async {
                    await updateProductApproval(product.id, 'approved');
                    refreshProducts();
                  },
                ),
              if (product.approvalStatus != 'rejected')
                OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Reject'),
                  onPressed: () async {
                    await updateProductApproval(product.id, 'rejected');
                    refreshProducts();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      key: ValueKey('${widget.refreshKey}-$localRefreshKey'),
      future: fetchAllProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SkeletonList();
        }

        final products = snapshot.data ?? [];
        final visibleProducts = _applyInventoryFilters(products);

        Future<void> refreshNow() async {
          refreshProducts();
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }

        return RefreshIndicator(
          onRefresh: refreshNow,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 128),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Header(
                      title: 'Inventory',
                      subtitle: 'Keep products launch-ready and easy to shop',
                    ),
                  ),
                  const SizedBox(width: 9),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FarmColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => openProductEditor(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _inventorySummaryCard(products),
              const SizedBox(height: 14),
              FarmCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: inventorySearchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        labelText: 'Search inventory',
                        hintText: 'Name, category, unit, farm or parish',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: inventoryQuery.trim().isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  inventorySearchController.clear();
                                  setState(() => inventoryQuery = '');
                                },
                              ),
                      ),
                      onChanged: (value) =>
                          setState(() => inventoryQuery = value),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _inventoryPill(
                            label: 'Needs attention',
                            icon: Icons.priority_high_outlined,
                            selected: inventoryFilter == 'needs_attention',
                            onTap: () => setState(
                                () => inventoryFilter = 'needs_attention'),
                          ),
                          const SizedBox(width: 8),
                          _inventoryPill(
                            label: 'All',
                            icon: Icons.grid_view_outlined,
                            selected: inventoryFilter == 'all',
                            onTap: () =>
                                setState(() => inventoryFilter = 'all'),
                          ),
                          const SizedBox(width: 8),
                          _inventoryPill(
                            label: 'In stock',
                            icon: Icons.check_circle_outline,
                            selected: inventoryFilter == 'in_stock',
                            onTap: () =>
                                setState(() => inventoryFilter = 'in_stock'),
                          ),
                          const SizedBox(width: 8),
                          _inventoryPill(
                            label: 'Low stock',
                            icon: Icons.local_fire_department_outlined,
                            selected: inventoryFilter == 'low_stock',
                            onTap: () =>
                                setState(() => inventoryFilter = 'low_stock'),
                          ),
                          const SizedBox(width: 8),
                          _inventoryPill(
                            label: 'Out',
                            icon: Icons.remove_shopping_cart_outlined,
                            selected: inventoryFilter == 'out_of_stock',
                            onTap: () => setState(
                                () => inventoryFilter = 'out_of_stock'),
                          ),
                          const SizedBox(width: 8),
                          _inventoryPill(
                            label: 'Hidden',
                            icon: Icons.visibility_off_outlined,
                            selected: inventoryFilter == 'hidden',
                            onTap: () =>
                                setState(() => inventoryFilter = 'hidden'),
                          ),
                          const SizedBox(width: 8),
                          _inventoryPill(
                            label: 'Deals',
                            icon: Icons.local_offer_outlined,
                            selected: inventoryFilter == 'deals',
                            onTap: () =>
                                setState(() => inventoryFilter = 'deals'),
                          ),
                          const SizedBox(width: 8),
                          _inventoryPill(
                            label: 'Organic',
                            icon: Icons.eco_outlined,
                            selected: inventoryFilter == 'organic',
                            onTap: () =>
                                setState(() => inventoryFilter = 'organic'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${visibleProducts.length} of ${products.length} products',
                            style: const TextStyle(
                              color: FarmColors.mutedText,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 156,
                          child: DropdownButtonFormField<String>(
                            value: inventorySort,
                            decoration: const InputDecoration(
                              labelText: 'Sort',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'priority', child: Text('Priority')),
                              DropdownMenuItem(
                                  value: 'name', child: Text('A-Z')),
                              DropdownMenuItem(
                                  value: 'stock_low', child: Text('Stock low')),
                              DropdownMenuItem(
                                  value: 'stock_high',
                                  child: Text('Stock high')),
                              DropdownMenuItem(
                                  value: 'price_high',
                                  child: Text('Price high')),
                              DropdownMenuItem(
                                  value: 'newest', child: Text('Newest')),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => inventorySort = value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (products.isEmpty)
                FarmCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 38, color: FarmColors.green),
                      const SizedBox(height: 12),
                      const Text(
                        'No products yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Add your first farm product and it will appear here for admin review.',
                        style: TextStyle(color: FarmColors.mutedText),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add product'),
                        onPressed: () => openProductEditor(context),
                      ),
                    ],
                  ),
                )
              else if (visibleProducts.isEmpty)
                FarmCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.search_off_outlined,
                          size: 38, color: FarmColors.mutedText),
                      const SizedBox(height: 12),
                      const Text(
                        'No matching products',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Try another search term or clear the current filter.',
                        style: TextStyle(color: FarmColors.mutedText),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh_outlined),
                        label: const Text('Show all products'),
                        onPressed: () {
                          inventorySearchController.clear();
                          setState(() {
                            inventoryQuery = '';
                            inventoryFilter = 'all';
                            inventorySort = 'priority';
                          });
                        },
                      ),
                    ],
                  ),
                )
              else
                ...visibleProducts.map(_productOpsCard),
            ],
          ),
        );
      },
    );
  }
}

class AdminReviewsTab extends StatelessWidget {
  final int refreshKey;
  const AdminReviewsTab({super.key, required this.refreshKey});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductReview>>(
      key: ValueKey('admin-reviews-$refreshKey'),
      future: fetchProductReviews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SkeletonList(count: 4, height: 112);
        }
        final reviews = snapshot.data ?? const <ProductReview>[];
        final count = reviews.length;
        final average = count == 0
            ? 0.0
            : reviews.fold<double>(0, (sum, review) => sum + review.rating) /
                count;
        final needsAttention =
            reviews.where((review) => review.rating <= 3).length;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
          children: [
            const Header(
              title: 'Customer voice',
              subtitle: 'Reviews & feedback',
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: FarmColors.deepGreen,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: FarmColors.shadow.withOpacity(0.16),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Review health',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    count == 0
                        ? 'Customer reviews will help improve products and trust.'
                        : '${average.toStringAsFixed(1)} average rating across $count reviews.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.78),
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ReviewAdminMetric(
                          label: 'Reviews',
                          value: count.toString(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ReviewAdminMetric(
                          label: 'Average',
                          value: count == 0 ? '—' : average.toStringAsFixed(1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ReviewAdminMetric(
                          label: 'Review',
                          value: needsAttention.toString(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (reviews.isEmpty)
              const FarmEmptyState(
                icon: Icons.reviews_outlined,
                title: 'No customer reviews yet',
                message:
                    'Reviews will appear here after shoppers leave product feedback.',
              )
            else
              ...reviews.take(50).map((review) => ReviewCard(review: review)),
          ],
        );
      },
    );
  }
}

class ReviewAdminMetric extends StatelessWidget {
  final String label;
  final String value;

  const ReviewAdminMetric({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
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
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminSupportTab extends StatelessWidget {
  final int refreshKey;
  final VoidCallback onChanged;

  const AdminSupportTab(
      {super.key, required this.refreshKey, required this.onChanged});

  Future<void> replyToTicket(BuildContext context, SupportTicket ticket) async {
    final replyController =
        TextEditingController(text: ticket.adminReply ?? '');
    String selectedStatus = ticket.status;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Support #${ticket.shortId}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket.subject,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(ticket.message),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'open', child: Text('Open')),
                        DropdownMenuItem(
                            value: 'in_progress', child: Text('In progress')),
                        DropdownMenuItem(
                            value: 'closed', child: Text('Closed')),
                      ],
                      onChanged: (value) => setDialogState(
                          () => selectedStatus = value ?? 'open'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: replyController,
                      maxLines: 4,
                      decoration:
                          const InputDecoration(labelText: 'Farm reply'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: FarmColors.primary,
                      foregroundColor: Colors.white),
                  onPressed: () async {
                    try {
                      await updateSupportTicket(
                        ticketId: ticket.id,
                        status: selectedStatus,
                        adminReply: replyController.text.trim().isEmpty
                            ? null
                            : replyController.text.trim(),
                      );
                      if (context.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Support ticket updated')));
                      }
                      onChanged();
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'Could not update support ticket: $error')));
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SupportTicket>>(
      key: ValueKey('support-$refreshKey'),
      future: fetchAdminSupportTickets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SkeletonList();
        }
        final tickets = snapshot.data ?? [];
        if (tickets.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(18),
            child: FarmCard(child: Text('No support tickets yet.')),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: tickets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final ticket = tickets[index];
            return FarmCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text(ticket.subject,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 17))),
                      Chip(
                          label: Text(ticket.formattedStatus),
                          backgroundColor: FarmColors.lightGreen),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(ticket.email),
                  const SizedBox(height: 8),
                  Text(ticket.message),
                  if ((ticket.adminReply ?? '').isNotEmpty) ...[
                    const Divider(),
                    Text('Reply: ${ticket.adminReply}'),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.reply),
                      label: const Text('Reply / Update'),
                      onPressed: () => replyToTicket(context, ticket),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class AdminCouponsTab extends StatefulWidget {
  final int refreshKey;
  final VoidCallback onChanged;

  const AdminCouponsTab({
    super.key,
    required this.refreshKey,
    required this.onChanged,
  });

  @override
  State<AdminCouponsTab> createState() => _AdminCouponsTabState();
}

class _AdminCouponsTabState extends State<AdminCouponsTab> {
  Future<void> openCouponCreator(BuildContext context) async {
    final codeController = TextEditingController();
    final valueController = TextEditingController();
    final minimumController = TextEditingController();
    String discountType = 'fixed';
    bool isActive = true;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveCoupon() async {
              final code = codeController.text.trim().toUpperCase();
              final value = double.tryParse(valueController.text.trim());
              final minimumText = minimumController.text.trim();
              final minimum =
                  minimumText.isEmpty ? null : double.tryParse(minimumText);

              if (code.isEmpty || value == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Enter coupon code and valid discount value.'),
                  ),
                );
                return;
              }

              setDialogState(() => saving = true);
              try {
                await createCoupon(
                  code: code,
                  discountType: discountType,
                  discountValue: value,
                  minimumOrder: minimum,
                  isActive: isActive,
                );
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coupon created')),
                  );
                }
                widget.onChanged();
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not create coupon: $error')),
                  );
                }
              } finally {
                if (context.mounted) setDialogState(() => saving = false);
              }
            }

            return AlertDialog(
              title: const Text('Create Coupon'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Code, for example FARM10',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: discountType,
                      decoration:
                          const InputDecoration(labelText: 'Discount type'),
                      items: const [
                        DropdownMenuItem(
                            value: 'fixed', child: Text('Fixed amount')),
                        DropdownMenuItem(
                            value: 'percent', child: Text('Percentage')),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => discountType = value ?? 'fixed'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: valueController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: discountType == 'percent'
                            ? 'Percent value, for example 10'
                            : 'Fixed value, for example 500',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: minimumController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Minimum order amount optional',
                      ),
                    ),
                    SwitchListTile(
                      value: isActive,
                      activeColor: FarmColors.green,
                      title: const Text('Active'),
                      onChanged: (value) =>
                          setDialogState(() => isActive = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving ? null : saveCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FarmColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(saving ? 'Saving...' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Coupon>>(
      key: ValueKey('coupons-${widget.refreshKey}'),
      future: fetchCoupons(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SkeletonList();
        }

        final coupons = snapshot.data ?? [];
        final activeCount = coupons.where((coupon) => coupon.isActive).length;

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            FarmCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Coupon Management',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('${coupons.length} coupons • $activeCount active'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Create Coupon'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FarmColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => openCouponCreator(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (coupons.isEmpty)
              const FarmCard(child: Text('No coupons created yet.'))
            else
              ...coupons.map(
                (coupon) => FarmCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: FarmColors.lightGreen,
                        child: Icon(Icons.confirmation_number_outlined,
                            color: FarmColors.green),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              coupon.code,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(coupon.label),
                            if ((coupon.minimumOrder ?? 0) > 0)
                              Text(
                                  'Minimum: J\$${coupon.minimumOrder!.toStringAsFixed(2)}'),
                          ],
                        ),
                      ),
                      Switch(
                        value: coupon.isActive,
                        activeColor: FarmColors.green,
                        onChanged: coupon.id.isEmpty
                            ? null
                            : (value) async {
                                try {
                                  await updateCouponAvailability(
                                      coupon.id, value);
                                  widget.onChanged();
                                } catch (error) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Could not update coupon: $error'),
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class AdminFarmerManagementTab extends StatelessWidget {
  final int refreshKey;
  final VoidCallback onChanged;
  const AdminFarmerManagementTab(
      {super.key, required this.refreshKey, required this.onChanged});

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return FarmColors.green;
      case 'rejected':
        return FarmColors.danger;
      default:
        return FarmColors.warning;
    }
  }

  int _statusPriority(FarmerProfile farmer) {
    switch (farmer.verificationStatus.trim().toLowerCase()) {
      case 'pending':
        return 0;
      case 'rejected':
        return 1;
      case 'approved':
        return 2;
      default:
        return 3;
    }
  }

  Future<void> setStatus(
      BuildContext context, FarmerProfile farmer, String status) async {
    try {
      await updateFarmerVerification(farmer.id, status);
      onChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${farmer.farmName} marked ${_friendlyStatus(status)}.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Farmer update failed: $error')));
      }
    }
  }

  Widget _summaryCard({
    required int total,
    required int approved,
    required int pending,
    required int rejected,
  }) {
    return FarmCard(
      padding: const EdgeInsets.all(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [FarmColors.deepGreen, FarmColors.green],
          ),
          borderRadius: BorderRadius.circular(24),
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
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.24)),
                  ),
                  child:
                      const Icon(Icons.handshake_outlined, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Farmer partner network',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pending > 0
                            ? '$pending farmer application${pending == 1 ? '' : 's'} need review before products go live.'
                            : 'Farmer applications are under control. Keep approved farms ready for fresh listings.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.86),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _AdminFarmerSummaryPill(label: '$total farmers'),
                _AdminFarmerSummaryPill(label: '$approved approved'),
                _AdminFarmerSummaryPill(label: '$pending pending'),
                if (rejected > 0)
                  _AdminFarmerSummaryPill(label: '$rejected rejected'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _farmerCard(BuildContext context, FarmerProfile farmer) {
    final color = _statusColor(farmer.verificationStatus);
    final hasPayout = farmer.payoutMethod.trim().isNotEmpty;
    final hasPhone = farmer.phone.trim().isNotEmpty;
    final readyText = farmer.isApproved
        ? 'Approved marketplace partner'
        : farmer.verificationStatus == 'rejected'
            ? 'Rejected application'
            : 'Needs admin review';

    return FarmCard(
      padding: const EdgeInsets.all(16),
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
                  color: color.withOpacity(0.10),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.20)),
                ),
                child: Icon(Icons.agriculture_outlined, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farmer.farmName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: FarmColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${farmer.farmerName} • ${farmer.parish}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                backgroundColor: color.withOpacity(0.10),
                label: Text(
                  farmer.statusLabel,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          if (farmer.bio.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              farmer.bio,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.ink,
                fontWeight: FontWeight.w600,
                height: 1.28,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FarmColors.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: FarmColors.line),
            ),
            child: Column(
              children: [
                TraceRow(
                  icon: Icons.verified_user_outlined,
                  title: 'Review status',
                  value: readyText,
                ),
                TraceRow(
                  icon: Icons.phone_outlined,
                  title: 'Phone',
                  value: hasPhone ? farmer.phone : 'Missing phone',
                ),
                TraceRow(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Payout',
                  value:
                      hasPayout ? farmer.payoutMethod : 'Payout method missing',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Approve'),
                onPressed:
                    farmer.verificationStatus.trim().toLowerCase() == 'approved'
                        ? null
                        : () => setStatus(context, farmer, 'approved'),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.pause_circle_outline, size: 18),
                label: const Text('Pending'),
                onPressed:
                    farmer.verificationStatus.trim().toLowerCase() == 'pending'
                        ? null
                        : () => setStatus(context, farmer, 'pending'),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Reject'),
                onPressed:
                    farmer.verificationStatus.trim().toLowerCase() == 'rejected'
                        ? null
                        : () => setStatus(context, farmer, 'rejected'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FarmerProfile>>(
      key: ValueKey('admin-farmers-$refreshKey'),
      future: fetchFarmerProfiles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.expand(child: SkeletonList(count: 3));
        }
        final farmers = snapshot.data ?? [];
        final approved = farmers.where((f) => f.isApproved).length;
        final pending = farmers
            .where(
                (f) => f.verificationStatus.trim().toLowerCase() == 'pending')
            .length;
        final rejected = farmers
            .where(
                (f) => f.verificationStatus.trim().toLowerCase() == 'rejected')
            .length;
        final ordered = [...farmers]..sort((a, b) {
            final statusCompare =
                _statusPriority(a).compareTo(_statusPriority(b));
            if (statusCompare != 0) return statusCompare;
            return a.farmName.toLowerCase().compareTo(b.farmName.toLowerCase());
          });

        return RefreshIndicator(
          onRefresh: () async => onChanged(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            children: [
              const Header(
                title: 'Farmer partners',
                subtitle: 'Approve farms and protect marketplace quality',
              ),
              const SizedBox(height: 16),
              _summaryCard(
                total: farmers.length,
                approved: approved,
                pending: pending,
                rejected: rejected,
              ),
              const SizedBox(height: 16),
              if (farmers.isEmpty)
                const FarmEmptyState(
                  icon: Icons.agriculture_outlined,
                  title: 'No farmer applications',
                  message:
                      'Farmer applications will appear here after users register as farmers and complete onboarding.',
                )
              else ...[
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Applications and partners',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: FarmColors.ink,
                        ),
                      ),
                    ),
                    Chip(label: Text('${ordered.length} total')),
                  ],
                ),
                const SizedBox(height: 10),
                ...ordered.map((farmer) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _farmerCard(context, farmer),
                    )),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AdminFarmerSummaryPill extends StatelessWidget {
  final String label;
  const _AdminFarmerSummaryPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class AdminPayoutsTab extends StatelessWidget {
  final int refreshKey;
  final VoidCallback onChanged;
  const AdminPayoutsTab(
      {super.key, required this.refreshKey, required this.onChanged});

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'released':
        return FarmColors.green;
      case 'held':
        return FarmColors.warning;
      case 'disputed':
        return FarmColors.danger;
      default:
        return FarmColors.gold;
    }
  }

  int _statusPriority(FarmerPayout payout) {
    switch (payout.payoutStatus.trim().toLowerCase()) {
      case 'pending':
        return 0;
      case 'held':
        return 1;
      case 'disputed':
        return 2;
      case 'released':
        return 3;
      default:
        return 4;
    }
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _payoutMetric({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 19),
            const SizedBox(height: 9),
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
            const SizedBox(height: 3),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.78),
                fontSize: 10.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _payoutSummaryCard({
    required double pending,
    required double released,
    required double held,
    required int pendingCount,
    required int totalCount,
  }) {
    final reviewText = pendingCount == 0
        ? 'No payout releases waiting right now.'
        : '$pendingCount payout ${pendingCount == 1 ? 'record needs' : 'records need'} review before release.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF214B31),
            Color(0xFF2F6B45),
            Color(0xFF4F8A5B),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: FarmColors.green.withOpacity(0.18),
            blurRadius: 22,
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
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Icon(Icons.payments_outlined,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payout control center',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reviewText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 12.5,
                        height: 1.28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusPill(totalCount == 0 ? 'Setup' : 'Live', Colors.white),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _payoutMetric(
                icon: Icons.pending_actions_outlined,
                title: 'Pending',
                value: formatJmd(pending),
                color: FarmColors.gold,
              ),
              const SizedBox(width: 10),
              _payoutMetric(
                icon: Icons.verified_outlined,
                title: 'Released',
                value: formatJmd(released),
                color: FarmColors.green,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _payoutMetric(
                icon: Icons.pause_circle_outline,
                title: 'Held',
                value: formatJmd(held),
                color: FarmColors.warning,
              ),
              const SizedBox(width: 10),
              _payoutMetric(
                icon: Icons.receipt_long_outlined,
                title: 'Records',
                value: '$totalCount',
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _payoutGuideCard(int pendingCount) {
    return FarmCard(
      padding: const EdgeInsets.all(16),
      color: pendingCount > 0 ? FarmColors.accentSoft : FarmColors.primarySoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            pendingCount > 0
                ? Icons.task_alt_outlined
                : Icons.verified_user_outlined,
            color: pendingCount > 0 ? FarmColors.warning : FarmColors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pendingCount > 0
                      ? 'Review before release'
                      : 'Payouts are under control',
                  style: TextStyle(
                    color: pendingCount > 0
                        ? FarmColors.warning
                        : FarmColors.green,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pendingCount > 0
                      ? 'Confirm the order was completed and payment is safe before releasing farmer earnings.'
                      : 'New payout rows will appear here after paid marketplace order items are ready to release.',
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

  Widget _elitePayoutCard(BuildContext context, FarmerPayout payout) {
    final status = payout.payoutStatus.trim().toLowerCase();
    final statusColor = _statusColor(status);
    final shortOrder = payout.orderId.trim().isEmpty
        ? 'No order'
        : '#${shortIdLabel(payout.orderId)}';
    final method = payout.payoutMethod.trim().isEmpty
        ? 'Method not set'
        : _friendlyStatus(payout.payoutMethod);
    final reference = payout.payoutReference.trim().isEmpty
        ? 'No reference yet'
        : payout.payoutReference.trim();

    return FarmCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withOpacity(0.18)),
                ),
                child: Icon(Icons.account_balance_wallet_outlined,
                    color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shortOrder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: FarmColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Created ${formatCustomerDateTime(payout.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusPill(_friendlyStatus(status), statusColor),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: FarmColors.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: FarmColors.line),
            ),
            child: Column(
              children: [
                TraceRow(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Gross sale',
                  value: formatJmd(payout.grossAmount),
                ),
                TraceRow(
                  icon: Icons.savings_outlined,
                  title: 'Platform share',
                  value: formatJmd(payout.commissionAmount),
                ),
                TraceRow(
                  icon: Icons.payments_outlined,
                  title: 'Farmer payout',
                  value: formatJmd(payout.netAmount),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.account_balance_outlined, size: 16),
                label: Text(method),
              ),
              Chip(
                avatar: const Icon(Icons.tag_outlined, size: 16),
                label: Text(reference),
              ),
            ],
          ),
          if (onChanged != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: status == 'released'
                      ? null
                      : () async {
                          await updateFarmerPayoutStatus(
                              payoutId: payout.id, status: 'released');
                          onChanged.call();
                        },
                  icon: const Icon(Icons.verified_outlined, size: 18),
                  label: const Text('Release'),
                ),
                OutlinedButton.icon(
                  onPressed: status == 'held'
                      ? null
                      : () async {
                          await updateFarmerPayoutStatus(
                              payoutId: payout.id, status: 'held');
                          onChanged.call();
                        },
                  icon: const Icon(Icons.pause_circle_outline, size: 18),
                  label: const Text('Hold'),
                ),
                OutlinedButton.icon(
                  onPressed: status == 'disputed'
                      ? null
                      : () async {
                          await updateFarmerPayoutStatus(
                              payoutId: payout.id, status: 'disputed');
                          onChanged.call();
                        },
                  icon: const Icon(Icons.report_problem_outlined, size: 18),
                  label: const Text('Dispute'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FarmerPayout>>(
      key: ValueKey('admin-payouts-$refreshKey'),
      future: fetchFarmerPayouts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.expand(child: SkeletonList(count: 3));
        }
        final payouts = snapshot.data ?? [];
        final pendingPayouts = payouts
            .where((p) => p.payoutStatus.trim().toLowerCase() == 'pending')
            .toList();
        final releasedPayouts = payouts
            .where((p) => p.payoutStatus.trim().toLowerCase() == 'released')
            .toList();
        final heldPayouts = payouts
            .where((p) => p.payoutStatus.trim().toLowerCase() == 'held')
            .toList();
        final pending =
            pendingPayouts.fold<double>(0, (sum, p) => sum + p.netAmount);
        final released =
            releasedPayouts.fold<double>(0, (sum, p) => sum + p.netAmount);
        final held = heldPayouts.fold<double>(0, (sum, p) => sum + p.netAmount);
        final ordered = [...payouts]..sort((a, b) {
            final statusCompare =
                _statusPriority(a).compareTo(_statusPriority(b));
            if (statusCompare != 0) return statusCompare;
            final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });

        return RefreshIndicator(
          onRefresh: () async => onChanged(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            children: [
              const Header(
                title: 'Farmer payouts',
                subtitle: 'Release earnings with confidence',
              ),
              const SizedBox(height: 16),
              _payoutSummaryCard(
                pending: pending,
                released: released,
                held: held,
                pendingCount: pendingPayouts.length,
                totalCount: payouts.length,
              ),
              const SizedBox(height: 14),
              _payoutGuideCard(pendingPayouts.length),
              const SizedBox(height: 16),
              if (payouts.isEmpty)
                const FarmEmptyState(
                  icon: Icons.payments_outlined,
                  title: 'No farmer payouts yet',
                  message:
                      'Payout records will appear here after marketplace order item payout rows are created.',
                )
              else ...[
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Payout queue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: FarmColors.ink,
                        ),
                      ),
                    ),
                    _statusPill('${ordered.length} records', FarmColors.green),
                  ],
                ),
                const SizedBox(height: 10),
                ...ordered.map(
                  (payout) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _elitePayoutCard(context, payout),
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
